#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    framework_root = repo_root / "dynamic_modules" / "framework"
    if not framework_root.exists():
        print(
            "Dynamic SS13 Modules framework is missing. "
            "Run `git submodule update --init dynamic_modules/framework`.",
            file=sys.stderr,
        )
        return 1
    sys.path.insert(0, str(framework_root))
    from dynamic_ss13_modules.cli import main as dynamic_modules_main

    return dynamic_modules_main(["--root", str(repo_root), "prepare", *sys.argv[1:]])


if __name__ == "__main__":
    raise SystemExit(main())
