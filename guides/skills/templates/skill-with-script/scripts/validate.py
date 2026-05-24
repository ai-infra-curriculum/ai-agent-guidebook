#!/usr/bin/env python3
"""
Validation script stub for skill-with-script-template.

Replace this with real validation logic. The skill body invokes it as:

    python3 scripts/validate.py --input <target_path> --discovery <discovery_json>

Contract:
- Exit 0 on success. Print structured JSON summary on stdout.
- Exit non-zero on validation failure. Print a human-readable explanation
  on stderr. The skill body surfaces this to the user.

Keep this script standalone — no external dependencies beyond the Python
stdlib unless documented in the skill's `requires.external-tools`.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate target before changes")
    parser.add_argument("--input", required=True, help="Path to the target file or directory")
    parser.add_argument("--discovery", required=True, help="Path to the discovery JSON file")
    return parser.parse_args()


def validate(target: Path, discovery: dict) -> dict:
    """Replace this with real validation logic.

    Return a dict describing the validation result. Raise an exception
    (or return a dict with status=failed) to signal validation failure.
    """
    if not target.exists():
        raise FileNotFoundError(f"Target does not exist: {target}")
    return {
        "status": "ok",
        "target": str(target),
        "discovery_keys": list(discovery.keys()),
    }


def main() -> int:
    args = parse_args()
    target = Path(args.input)
    discovery_path = Path(args.discovery)

    try:
        discovery = json.loads(discovery_path.read_text())
    except Exception as exc:
        print(f"Failed to read discovery file {discovery_path}: {exc}", file=sys.stderr)
        return 2

    try:
        result = validate(target, discovery)
    except Exception as exc:
        print(f"Validation failed: {exc}", file=sys.stderr)
        return 1

    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
