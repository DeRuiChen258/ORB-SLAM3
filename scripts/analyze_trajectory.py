#!/usr/bin/env python3
"""Plot a TUM trajectory and optionally compute rigid-aligned RGB-D ATE."""

from __future__ import annotations

import argparse
import math
import statistics
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def read_trajectory(path: Path) -> tuple[np.ndarray, np.ndarray]:
    timestamps: list[float] = []
    positions: list[list[float]] = []
    with path.open("r", encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            fields = stripped.split()
            if len(fields) != 8:
                raise ValueError(f"{path}:{line_number}: TUM pose 必须为 8 列")
            values = [float(value) for value in fields]
            if not all(math.isfinite(value) for value in values):
                raise ValueError(f"{path}:{line_number}: 存在 NaN/Inf")
            quaternion_norm = math.sqrt(sum(value * value for value in values[4:8]))
            if quaternion_norm < 1e-12:
                raise ValueError(f"{path}:{line_number}: 四元数范数为零")
            timestamps.append(values[0])
            positions.append(values[1:4])

    if len(timestamps) < 2:
        raise ValueError(f"{path}: 有效位姿少于 2 条")
    times = np.asarray(timestamps, dtype=np.float64)
    xyz = np.asarray(positions, dtype=np.float64)
    if np.any(np.diff(times) <= 0):
        raise ValueError(f"{path}: 时间戳必须严格递增")
    return times, xyz


def associate_nearest(
    estimate_times: np.ndarray, reference_times: np.ndarray, tolerance: float
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Greedily choose unique timestamp pairs in ascending time-error order."""
    candidates: list[tuple[float, int, int]] = []
    left = 0
    for estimate_index, timestamp in enumerate(estimate_times):
        while left < len(reference_times) and reference_times[left] < timestamp - tolerance:
            left += 1
        index = left
        while index < len(reference_times) and reference_times[index] <= timestamp + tolerance:
            candidates.append(
                (abs(float(timestamp - reference_times[index])), estimate_index, index)
            )
            index += 1

    candidates.sort()
    used_estimate: set[int] = set()
    used_reference: set[int] = set()
    pairs: list[tuple[int, int, float]] = []
    for difference, estimate_index, reference_index in candidates:
        if estimate_index in used_estimate or reference_index in used_reference:
            continue
        used_estimate.add(estimate_index)
        used_reference.add(reference_index)
        pairs.append((estimate_index, reference_index, difference))

    pairs.sort(key=lambda pair: estimate_times[pair[0]])
    if not pairs:
        raise ValueError(f"{tolerance:.3f}s 容差内没有估计/真值配对")
    return (
        np.asarray([pair[0] for pair in pairs], dtype=np.int64),
        np.asarray([pair[1] for pair in pairs], dtype=np.int64),
        np.asarray([pair[2] for pair in pairs], dtype=np.float64),
    )


def align_rigid(source: np.ndarray, target: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Return row-vector rotation R and translation t for source @ R + t."""
    source_mean = source.mean(axis=0)
    target_mean = target.mean(axis=0)
    source_centered = source - source_mean
    target_centered = target - target_mean
    covariance = source_centered.T @ target_centered
    left, _, right_transpose = np.linalg.svd(covariance)
    correction = np.eye(3)
    if np.linalg.det(left @ right_transpose) < 0:
        correction[-1, -1] = -1
    rotation = left @ correction @ right_transpose
    translation = target_mean - source_mean @ rotation
    return rotation, translation


def save_plots(
    estimate: np.ndarray,
    reference: np.ndarray | None,
    output_dir: Path,
) -> tuple[Path, Path]:
    xy_path = output_dir / "camera_trajectory_xy.png"
    xyz_path = output_dir / "camera_trajectory_3d.png"
    for path in (xy_path, xyz_path):
        if path.exists():
            raise FileExistsError(f"拒绝覆盖已有结果：{path}")

    fig, axis = plt.subplots(figsize=(8, 6), constrained_layout=True)
    axis.plot(estimate[:, 0], estimate[:, 1], color="#1769aa", label="Estimate", linewidth=1.5)
    axis.scatter(*estimate[0, :2], color="#2e7d32", marker="o", label="Start", zorder=3)
    axis.scatter(*estimate[-1, :2], color="#c62828", marker="x", label="End", zorder=3)
    if reference is not None:
        axis.plot(reference[:, 0], reference[:, 1], "--", color="#ef6c00", label="Ground truth", linewidth=1.2)
    axis.set(title="Camera trajectory (top view)", xlabel="X (m)", ylabel="Y (m)")
    axis.axis("equal")
    axis.grid(True, alpha=0.3)
    axis.legend()
    fig.savefig(xy_path, dpi=180)
    plt.close(fig)

    fig = plt.figure(figsize=(9, 7), constrained_layout=True)
    axis3d = fig.add_subplot(111, projection="3d")
    axis3d.plot(*estimate.T, color="#1769aa", label="Estimate", linewidth=1.5)
    axis3d.scatter(*estimate[0], color="#2e7d32", marker="o", label="Start")
    axis3d.scatter(*estimate[-1], color="#c62828", marker="x", label="End")
    if reference is not None:
        axis3d.plot(*reference.T, "--", color="#ef6c00", label="Ground truth", linewidth=1.2)
    axis3d.set(title="Camera trajectory (3D)", xlabel="X (m)", ylabel="Y (m)", zlabel="Z (m)")
    axis3d.legend()
    axis3d.grid(True, alpha=0.3)
    fig.savefig(xyz_path, dpi=180)
    plt.close(fig)
    return xy_path, xyz_path


def quality_summary(positions: np.ndarray) -> dict[str, float | int]:
    steps = np.linalg.norm(np.diff(positions, axis=0), axis=1)
    return {
        "duplicate_positions": int(np.count_nonzero(steps < 1e-9)),
        "max_step_m": float(np.max(steps)),
        "median_step_m": float(np.median(steps)),
        "p95_step_m": float(np.percentile(steps, 95)),
        "x_range_m": float(np.ptp(positions[:, 0])),
        "y_range_m": float(np.ptp(positions[:, 1])),
        "z_range_m": float(np.ptp(positions[:, 2])),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--estimate", type=Path, required=True, help="TUM CameraTrajectory.txt")
    parser.add_argument("--ground-truth", type=Path, help="可选 TUM groundtruth.txt")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--max-delta", type=float, default=0.02)
    args = parser.parse_args()
    if args.max_delta <= 0:
        raise ValueError("--max-delta 必须大于 0")

    estimate_times, estimate_positions = read_trajectory(args.estimate)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    expected_outputs = (
        args.output_dir / "camera_trajectory_xy.png",
        args.output_dir / "camera_trajectory_3d.png",
        args.output_dir / "visualization_report.md",
    )
    for output in expected_outputs:
        if output.exists():
            raise FileExistsError(f"拒绝覆盖已有结果：{output}")

    reference_aligned = None
    ate_section = "未计算 ATE：未提供 ground-truth 文件。"
    match_summary = "未提供 ground-truth，图中只绘制估计轨迹。"
    if args.ground_truth:
        reference_times, reference_positions = read_trajectory(args.ground_truth)
        estimate_indices, reference_indices, time_errors = associate_nearest(
            estimate_times, reference_times, args.max_delta
        )
        estimate_matches = estimate_positions[estimate_indices]
        reference_matches = reference_positions[reference_indices]
        if len(estimate_matches) < 3:
            raise ValueError(f"有效配对只有 {len(estimate_matches)} 条，不能稳健估计刚体对齐")
        rotation, translation = align_rigid(estimate_matches, reference_matches)
        aligned_matches = estimate_matches @ rotation + translation
        errors = np.linalg.norm(aligned_matches - reference_matches, axis=1)
        aligned_all = estimate_positions @ rotation + translation
        reference_aligned = reference_positions
        ate_section = (
            f"- 对齐方法：SE(3) 刚体 Umeyama 对齐（不估计尺度；RGB-D 公制尺度）\n"
            f"- 时间戳策略：唯一最近邻，容差 {args.max_delta:.3f} s\n"
            f"- 有效配对数：{len(errors)} / 估计 {len(estimate_times)}，真值 {len(reference_times)}\n"
            f"- 时间差：median {statistics.median(time_errors):.6f} s，max {np.max(time_errors):.6f} s\n"
            f"- ATE RMSE：{np.sqrt(np.mean(errors ** 2)):.6f} m\n"
            f"- ATE mean / median / p95 / max：{np.mean(errors):.6f} / "
            f"{np.median(errors):.6f} / {np.percentile(errors, 95):.6f} / {np.max(errors):.6f} m"
        )
        match_summary = (
            f"估计轨迹 {len(estimate_times)} 条，真值 {len(reference_times)} 条，"
            f"匹配 {len(errors)} 条；绘图中估计轨迹按 ATE 对齐变换，真值为原始坐标。"
        )
        plotted_estimate = aligned_all
    else:
        plotted_estimate = estimate_positions

    xy_path, xyz_path = save_plots(plotted_estimate, reference_aligned, args.output_dir)
    quality = quality_summary(estimate_positions)
    report_path = args.output_dir / "visualization_report.md"
    report = f"""# 轨迹可视化与评估

## 输入与图表

- 估计轨迹：`{args.estimate.resolve()}`
- Ground truth：`{args.ground_truth.resolve() if args.ground_truth else '未提供'}`
- 位姿条目：{len(estimate_times)}；时间范围 `{estimate_times[0]:.6f}` 至 `{estimate_times[-1]:.6f}`
- XY 轨迹图：`{xy_path.name}`
- 3D 轨迹图：`{xyz_path.name}`
- 绘图配对：{match_summary}

## 轨迹质量检查

- 估计坐标范围：X {quality['x_range_m']:.6f} m，Y {quality['y_range_m']:.6f} m，Z {quality['z_range_m']:.6f} m
- 相邻位姿位移：median {quality['median_step_m']:.6f} m，p95 {quality['p95_step_m']:.6f} m，max {quality['max_step_m']:.6f} m
- 小于 1e-9 m 的重复相邻位置：{quality['duplicate_positions']}
- 输入位姿检查：8 列、有限数值、有效四元数及时间戳严格递增均通过

## ATE

{ate_section}

ATE 只描述这次单条 fr1/desk 回放的估计轨迹。该值依赖上面记录的时间戳关联和 SE(3) 对齐，不代表其他序列或导航能力。
"""
    report_path.write_text(report, encoding="utf-8")
    print(f"estimate_poses={len(estimate_times)}")
    print(f"xy_plot={xy_path}")
    print(f"3d_plot={xyz_path}")
    print(f"report={report_path}")
    if args.ground_truth:
        print(ate_section.replace("\n", " | "))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"analyze_trajectory.py: {error}", file=__import__("sys").stderr)
        raise SystemExit(2)
