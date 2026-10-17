#!/usr/bin/env python3
"""Safely extract ORBvoc.txt from the ORB-SLAM vocabulary tarball."""

from __future__ import annotations

import argparse
import hashlib
import tarfile
from pathlib import Path, PurePosixPath


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def extract(archive: Path, destination: Path) -> tuple[str, str]:
    with tarfile.open(archive, "r:gz") as tar:
        files = []
        for member in tar.getmembers():
            name = PurePosixPath(member.name)
            if name.is_absolute() or not name.parts or ".." in name.parts:
                raise ValueError(f"词袋归档含不安全路径：{member.name}")
            if member.isdir():
                continue
            if not member.isfile() or name.name != "ORBvoc.txt":
                raise ValueError(f"词袋归档含非预期成员：{member.name}")
            files.append(member)
        if len(files) != 1:
            raise ValueError(f"词袋归档必须恰有一个 ORBvoc.txt，实际为 {len(files)}")
        if destination.exists():
            raise FileExistsError(f"拒绝覆盖已有词袋：{destination}")

        destination.parent.mkdir(parents=True, exist_ok=True)
        member = files[0]
        source = tar.extractfile(member)
        if source is None:
            raise ValueError("无法读取 ORBvoc.txt")
        with source, destination.open("xb") as output:
            while block := source.read(1024 * 1024):
                output.write(block)
    return sha256(archive), sha256(destination)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not args.archive.is_file():
        raise FileNotFoundError(args.archive)
    archive_hash, vocab_hash = extract(args.archive, args.output)
    print(f"archive_sha256={archive_hash}")
    print(f"vocabulary={args.output}")
    print(f"vocabulary_sha256={vocab_hash}")
    print(f"vocabulary_bytes={args.output.stat().st_size}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"extract_vocabulary.py: {error}", file=__import__("sys").stderr)
        raise SystemExit(2)
