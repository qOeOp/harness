from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse

from lib_extract import fetch_url, html_to_markdownish, to_json, truncate_text


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fetch one URL and convert it to markdown-ish text.")
    parser.add_argument("url", help="URL to fetch.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--max-chars", type=int, default=12000, help="Maximum content characters to print.")
    parser.add_argument("--timeout", type=int, default=20, help="Network timeout in seconds.")
    parser.add_argument("--insecure", action="store_true", help="Disable TLS certificate verification.")
    return parser.parse_args()


def build_payload(args: argparse.Namespace) -> dict:
    fetched = fetch_url(args.url, timeout=args.timeout, insecure=args.insecure)
    if fetched["content_type"] == "text/html":
        parsed = html_to_markdownish(fetched["text"])
        body = parsed["text"]
        title = parsed["title"]
    else:
        body = fetched["text"]
        title = ""

    body = truncate_text(body, args.max_chars)
    return {
        "url": fetched["url"],
        "final_url": fetched["final_url"],
        "status": fetched["status"],
        "content_type": fetched["content_type"],
        "retrieved_at": fetched["retrieved_at"],
        "truncated": fetched["truncated"] or len(body) >= args.max_chars,
        "title": title,
        "content": body,
    }


def to_markdown(payload: dict) -> str:
    title = payload["title"] or payload["final_url"]
    return "\n".join(
        [
            "# URL Extract",
            "",
            f"- URL: {payload['url']}",
            f"- Final URL: {payload['final_url']}",
            f"- Status: {payload['status']}",
            f"- Content-Type: {payload['content_type']}",
            f"- Retrieved at: {payload['retrieved_at']}",
            f"- Title: {title}",
            f"- Truncated: {'yes' if payload['truncated'] else 'no'}",
            "",
            "## Content",
            "",
            payload["content"],
        ]
    )


def main() -> int:
    args = parse_args()
    payload = build_payload(args)
    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
