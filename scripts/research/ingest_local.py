from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import pathlib
import subprocess

from lib_extract import html_to_markdownish, to_json, truncate_text


TEXT_SUFFIXES = {
    ".csv",
    ".json",
    ".log",
    ".markdown",
    ".md",
    ".rst",
    ".txt",
    ".xml",
    ".yaml",
    ".yml",
}
HTML_SUFFIXES = {".htm", ".html"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest a local document into markdown-ish text.")
    parser.add_argument("path", help="Path to a local file.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--max-chars", type=int, default=12000, help="Maximum content characters to print.")
    return parser.parse_args()


def read_with_markitdown(path: pathlib.Path) -> str | None:
    try:
        result = subprocess.run(
            ["markitdown", str(path)],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None
    except subprocess.CalledProcessError:
        return None

    return result.stdout.strip()


def load_content(path: pathlib.Path) -> tuple[str, str]:
    suffix = path.suffix.lower()
    if suffix in TEXT_SUFFIXES:
        return "text", path.read_text(encoding="utf-8", errors="replace")

    if suffix in HTML_SUFFIXES:
        parsed = html_to_markdownish(path.read_text(encoding="utf-8", errors="replace"))
        return "html", parsed["text"]

    markdown = read_with_markitdown(path)
    if markdown is not None:
        return "markitdown", markdown

    raise SystemExit(
        "Unsupported file type without markitdown installed. "
        "Install markitdown for rich document formats such as pdf/docx/pptx/xlsx."
    )


def to_markdown(payload: dict) -> str:
    return "\n".join(
        [
            "# Local Ingest",
            "",
            f"- Path: {payload['path']}",
            f"- Mode: {payload['mode']}",
            f"- Truncated: {'yes' if payload['truncated'] else 'no'}",
            "",
            "## Content",
            "",
            payload["content"],
        ]
    )


def main() -> int:
    args = parse_args()
    path = pathlib.Path(args.path)
    if not path.is_file():
        raise SystemExit(f"file not found: {path}")

    mode, content = load_content(path)
    content = truncate_text(content, args.max_chars)
    payload = {
        "path": str(path),
        "mode": mode,
        "truncated": len(content) >= args.max_chars,
        "content": content,
    }

    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
