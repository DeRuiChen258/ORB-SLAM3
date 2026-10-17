#!/usr/bin/env python3
"""Prepare the partial DCH-SLAM checkout for the RGB-D demo build."""

from __future__ import annotations

import argparse
from pathlib import Path


OPTION_NAME = "DCH_BUILD_EXTRA_EXAMPLES"
BEGIN_MARKER = "# SLAM_ORB: optional example targets begin"
END_MARKER = "# SLAM_ORB: optional example targets end"
RGBD_TARGET_ANCHOR = "target_link_libraries(rgbd_tum ${PROJECT_NAME})"


def prepare_cmake(source: Path) -> bool:
    cmake_file = source / "CMakeLists.txt"
    if not cmake_file.is_file():
        raise FileNotFoundError(f"DCH-SLAM CMakeLists.txt not found: {cmake_file}")
    if not (source / "Examples/RGB-D/rgbd_tum.cc").is_file():
        raise FileNotFoundError("DCH-SLAM RGB-D entry point is missing: Examples/RGB-D/rgbd_tum.cc")

    contents = cmake_file.read_text(encoding="utf-8")
    has_begin = BEGIN_MARKER in contents
    has_end = END_MARKER in contents
    if has_begin or has_end:
        if has_begin and has_end and contents.count(BEGIN_MARKER) == 1 and contents.count(END_MARKER) == 1:
            return False
        raise ValueError("DCH-SLAM CMakeLists.txt contains an incomplete demo patch")

    if contents.count(RGBD_TARGET_ANCHOR) != 1:
        raise ValueError("Could not uniquely locate the rgbd_tum target in DCH-SLAM CMakeLists.txt")

    opening = (
        f"{RGBD_TARGET_ANCHOR}\n\n"
        f"{BEGIN_MARKER}\n"
        f'option({OPTION_NAME} "Build additional DCH-SLAM example targets" ON)\n'
        f"if({OPTION_NAME})\n"
    )
    contents = contents.replace(RGBD_TARGET_ANCHOR, opening, 1)
    contents = contents.rstrip() + f"\n{END_MARKER}\nendif() # {OPTION_NAME}\n"
    cmake_file.write_text(contents, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path, help="DCH-SLAM source directory")
    args = parser.parse_args()

    try:
        changed = prepare_cmake(args.source)
    except (FileNotFoundError, OSError, ValueError) as exc:
        parser.error(str(exc))

    print(f"cmake_example_patch={'applied' if changed else 'already_applied'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
