from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse

from lib_extract import to_json
from lib_local_browser import discover_local_profiles


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="List discoverable local Chromium-family browser profiles.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    return parser.parse_args()


def to_markdown(data: list[dict]) -> str:
    lines = ["# Local Browser Profiles", ""]
    for item in data:
        lines.append(f"## {item['browser']}")
        lines.append("")
        lines.append(f"- Root: {item['root']}")
        lines.append(f"- Exists: {'yes' if item['exists'] else 'no'}")
        lines.append(f"- Profiles: {', '.join(item['profiles']) if item['profiles'] else 'none'}")
        lines.append("")
    return "\n".join(lines).rstrip()


def main() -> int:
    args = parse_args()
    payload = discover_local_profiles()
    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
