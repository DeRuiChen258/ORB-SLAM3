#!/usr/bin/env python3
"""Safely inspect TUM fr1/desk and create a verified RGB/depth association."""

from __future__ import annotations

import argparse
import hashlib
import math
import statistics
import tarfile
import time
from pathlib import Path, PurePosixPath

import numpy as np
from PIL import Image


DEFAULT_URL = (
    "https://vision.in.tum.de/rgbd/dataset/freiburg1/"
    "rgbd_dataset_freiburg1_desk.tgz"
)
DEFAULT_SEQUENCE = "rgbd_dataset_freiburg1_desk"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def safe_extract(archive: Path, destination: Path) -> Path:
    """Extract regular files/directories under one expected top-level folder."""
    with tarfile.open(archive, "r:gz") as tar:
        members = tar.getmembers()
        if not members:
            raise ValueError("数据归档为空")

        roots: set[str] = set()
        for member in members:
            name = PurePosixPath(member.name)
            if name.is_absolute() or not name.parts or ".." in name.parts:
                raise ValueError(f"归档含不安全路径：{member.name}")
            if not (member.isdir() or member.isfile()):
                raise ValueError(f"归档含非普通文件成员：{member.name}")
            roots.add(name.parts[0])
        if roots != {DEFAULT_SEQUENCE}:
            raise ValueError(f"归档根目录异常：{sorted(roots)}")

        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            raise FileExistsError(f"拒绝覆盖已有解压目录：{destination}")

        staging = destination.parent / f".{destination.name}.extract.{time.time_ns()}"
        staging.mkdir()
        for member in members:
            relative = PurePosixPath(member.name).parts[1:]
            if not relative:
                continue
            target = staging.joinpath(*relative)
            if staging not in target.parents and target != staging:
                raise ValueError(f"归档路径越界：{member.name}")
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            source = tar.extractfile(member)
            if source is None:
                raise ValueError(f"无法读取归档成员：{member.name}")
            with source, target.open("xb") as output:
                while block := source.read(1024 * 1024):
                    output.write(block)

        validate_sequence(staging)
        staging.rename(destination)
    return destination


def validate_sequence(sequence: Path) -> None:
    required = ("rgb.txt", "depth.txt", "groundtruth.txt", "rgb", "depth")
    missing = [name for name in required if not (sequence / name).exists()]
    if missing:
        raise ValueError(f"数据目录缺少必要内容：{', '.join(missing)}")


def read_timestamps(path: Path, sequence: Path) -> list[tuple[float, str]]:
    rows: list[tuple[float, str]] = []
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if len(fields) < 2:
            raise ValueError(f"{path}:{line_number} 列数不足")
        timestamp = float(fields[0])
        image_path = PurePosixPath(fields[1])
        if not math.isfinite(timestamp) or image_path.is_absolute() or ".." in image_path.parts:
            raise ValueError(f"{path}:{line_number} 时间戳或路径无效")
        if not (sequence.joinpath(*image_path.parts)).is_file():
            raise ValueError(f"{path}:{line_number} 图像不存在：{fields[1]}")
        rows.append((timestamp, image_path.as_posix()))
    if not rows:
        raise ValueError(f"没有读到时间戳：{path}")
    if any(rows[i][0] >= rows[i + 1][0] for i in range(len(rows) - 1)):
        raise ValueError(f"时间戳未严格递增：{path}")
    return rows


def parse_association(path: Path, sequence: Path, tolerance: float):
    rows: list[tuple[float, str, float, str]] = []
    seen_rgb: set[str] = set()
    seen_depth: set[str] = set()
    for line_number, line in enumerate(path.read_text().splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split()
        if len(fields) != 4:
            raise ValueError(f"{path}:{line_number} 必须为四列")
        rgb_time, rgb_name, depth_time, depth_name = fields
        rgb_stamp, depth_stamp = float(rgb_time), float(depth_time)
        rgb_rel, depth_rel = PurePosixPath(rgb_name), PurePosixPath(depth_name)
        if not (math.isfinite(rgb_stamp) and math.isfinite(depth_stamp)):
            raise ValueError(f"{path}:{line_number} 时间戳非有限")
        for rel in (rgb_rel, depth_rel):
            if rel.is_absolute() or ".." in rel.parts:
                raise ValueError(f"{path}:{line_number} 图像路径越界")
            if not sequence.joinpath(*rel.parts).is_file():
                raise ValueError(f"{path}:{line_number} 图像不存在：{rel}")
        if rgb_name in seen_rgb or depth_name in seen_depth:
            raise ValueError(f"{path}:{line_number} 重用了 RGB/depth 图像")
        if abs(rgb_stamp - depth_stamp) > tolerance:
            raise ValueError(f"{path}:{line_number} 时间差超过 {tolerance:.3f}s")
        if rows and rgb_stamp <= rows[-1][0]:
            raise ValueError(f"{path}:{line_number} RGB 时间戳未递增")
        seen_rgb.add(rgb_name)
        seen_depth.add(depth_name)
        rows.append((rgb_stamp, rgb_name, depth_stamp, depth_name))
    if not rows:
        raise ValueError(f"association 文件为空：{path}")
    return rows


def associate(rgb_rows, depth_rows, tolerance: float):
    candidates = []
    for rgb_index, (rgb_stamp, _) in enumerate(rgb_rows):
        for depth_index, (depth_stamp, _) in enumerate(depth_rows):
            difference = abs(rgb_stamp - depth_stamp)
            if difference <= tolerance:
                candidates.append((difference, rgb_index, depth_index))
    candidates.sort()

    used_rgb: set[int] = set()
    used_depth: set[int] = set()
    matched = []
    for difference, rgb_index, depth_index in candidates:
        if rgb_index in used_rgb or depth_index in used_depth:
            continue
        used_rgb.add(rgb_index)
        used_depth.add(depth_index)
        rgb_stamp, rgb_name = rgb_rows[rgb_index]
        depth_stamp, depth_name = depth_rows[depth_index]
        matched.append((rgb_stamp, rgb_name, depth_stamp, depth_name, difference))
    matched.sort(key=lambda row: row[0])
    if not matched:
        raise ValueError(f"在 {tolerance:.3f}s 内没有 RGB/depth 配对")
    return matched


def image_summary(path: Path):
    with Image.open(path) as image:
        summary = {"size": image.size, "mode": image.mode, "format": image.format}
        pixels = np.asarray(image)
    if path.parent.name == "depth":
        valid = pixels[pixels > 0]
        summary["valid_raw_range"] = (
            (int(valid.min()), int(valid.max())) if valid.size else None
        )
    return summary


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sequence", type=Path, help="已解压的数据集目录")
    parser.add_argument("--archive", type=Path, help="TUM 官方 tgz 归档（可选）")
    parser.add_argument("--extract-to", type=Path, help="安全解压目标目录")
    parser.add_argument("--association-out", type=Path, required=True)
    parser.add_argument("--candidate-association", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--max-delta", type=float, default=0.02)
    parser.add_argument("--depth-factor", type=float, default=5000.0)
    parser.add_argument("--url", default=DEFAULT_URL)
    args = parser.parse_args()

    sequence = args.sequence
    archive_hash = "未提供归档"
    if args.archive:
        if not args.archive.is_file():
            raise FileNotFoundError(args.archive)
        archive_hash = sha256(args.archive)
        target = args.extract_to or args.archive.parent.parent / DEFAULT_SEQUENCE
        if target.exists():
            validate_sequence(target)
            sequence = target
        else:
            sequence = safe_extract(args.archive, target)
    if sequence is None:
        raise ValueError("必须传入 --sequence 或 --archive")
    sequence = sequence.resolve()
    validate_sequence(sequence)

    rgb_rows = read_timestamps(sequence / "rgb.txt", sequence)
    depth_rows = read_timestamps(sequence / "depth.txt", sequence)
    association_out = args.association_out
    association_out.parent.mkdir(parents=True, exist_ok=True)

    source = "按时间戳最近邻生成"
    differences: list[float]
    if association_out.exists():
        pairs = parse_association(association_out, sequence, args.max_delta)
        source = f"复用已有文件 {association_out}"
        differences = [abs(row[0] - row[2]) for row in pairs]
    else:
        pairs = None
        if args.candidate_association and args.candidate_association.is_file():
            try:
                pairs = parse_association(
                    args.candidate_association, sequence, args.max_delta
                )
                source = f"复用仓库 association {args.candidate_association}"
            except (ValueError, OSError):
                pairs = None
        if pairs is None:
            generated = associate(rgb_rows, depth_rows, args.max_delta)
            pairs = [row[:4] for row in generated]
            differences = [row[4] for row in generated]
            source = "按 RGB/depth 时间戳做唯一最近邻匹配"
        else:
            differences = [abs(row[0] - row[2]) for row in pairs]
        content = "".join(
            f"{rt:.6f} {rgb} {dt:.6f} {depth}\n"
            for rt, rgb, dt, depth in pairs
        )
        with association_out.open("x") as output:
            output.write(content)

    # Validate the final file, including every referenced image.
    pairs = parse_association(association_out, sequence, args.max_delta)
    sample_indices = sorted({0, len(pairs) // 2, len(pairs) - 1})
    sampled = []
    for index in sample_indices:
        row = pairs[index]
        rgb_path = sequence / row[1]
        depth_path = sequence / row[3]
        rgb_info = image_summary(rgb_path)
        depth_info = image_summary(depth_path)
        if rgb_info["size"] != depth_info["size"]:
            raise ValueError(
                f"RGB/depth 分辨率不一致：{row[1]} {rgb_info['size']} vs "
                f"{row[3]} {depth_info['size']}"
            )
        sampled.append((row, rgb_info, depth_info))
    width, height = sampled[0][1]["size"]
    if any(info["size"] != (width, height) for _, info, _ in sampled):
        raise ValueError("抽查 RGB 图像分辨率不一致")
    depth_ranges = [
        info["valid_raw_range"]
        for _, _, info in sampled
        if info["valid_raw_range"] is not None
    ]
    if depth_ranges:
        depth_min = min(value[0] for value in depth_ranges)
        depth_max = max(value[1] for value in depth_ranges)
    else:
        depth_min, depth_max = 0, 0
    gt_rows = sum(
        1
        for line in (sequence / "groundtruth.txt").read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )
    differences = [abs(row[0] - row[2]) for row in pairs]
    report = f"""# TUM fr1/desk 数据准备报告

## 输入

- 来源 URL：{args.url}
- 序列目录：`{sequence}`
- 归档 SHA-256：`{archive_hash}`
- association 生成/复用方式：{source}
- 最大时间差阈值：{args.max_delta:.3f} s

## 数据检查

- RGB 时间戳条目：{len(rgb_rows)}；范围 `{rgb_rows[0][0]:.6f}` 至 `{rgb_rows[-1][0]:.6f}`
- Depth 时间戳条目：{len(depth_rows)}；范围 `{depth_rows[0][0]:.6f}` 至 `{depth_rows[-1][0]:.6f}`
- Ground-truth 条目：{gt_rows}
- 首/中/末抽查 RGB 与 Depth：{', '.join(f"`{row[1]}` / `{row[3]}`" for row, _, _ in sampled)}
- 抽样 RGB 图像：{width}×{height}；抽查 RGB/Depth 分辨率配对一致
- Depth 抽样格式 / mode：{', '.join(sorted({f"{info['format']} / {info['mode']}" for _, _, info in sampled}))}
- Depth 非零原始值范围（首/中/末抽样）：{depth_min} 至 {depth_max}
- Depth 换算因子：{args.depth_factor:g}；抽查有效深度约 {depth_min / args.depth_factor:.3f} 至 {depth_max / args.depth_factor:.3f} m

## Association

- 文件：`{association_out}`
- 配对数：{len(pairs)}；RGB 丢弃 {len(rgb_rows) - len(pairs)}；Depth 丢弃 {len(depth_rows) - len(pairs)}
- 实际时间差：median {statistics.median(differences):.6f} s，max {max(differences):.6f} s
- 四列及引用图像：逐行检查通过
- Depth map factor 与设置：本次使用 {args.depth_factor:g}，对应 TUM PNG 的原始深度单位
"""
    args.report.parent.mkdir(parents=True, exist_ok=True)
    if args.report.exists():
        raise FileExistsError(f"拒绝覆盖已有报告：{args.report}")
    args.report.write_text(report)
    print(f"sequence={sequence}")
    print(f"association={association_out} ({len(pairs)} pairs)")
    print(f"report={args.report}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"prepare_tum.py: {error}", file=__import__("sys").stderr)
        raise SystemExit(2)
