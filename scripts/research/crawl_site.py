from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import collections
import time
import urllib.parse

from lib_extract import dedupe_preserve_order, extract_links, fetch_url, html_to_markdownish, to_json, truncate_text


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Perform a bounded same-host crawl.")
    parser.add_argument("seed_url", help="Seed URL.")
    parser.add_argument("--max-pages", type=int, default=5, help="Maximum pages to fetch.")
    parser.add_argument("--max-depth", type=int, default=1, help="Maximum crawl depth.")
    parser.add_argument("--timeout", type=int, default=20, help="Network timeout in seconds.")
    parser.add_argument("--delay-seconds", type=float, default=0.0, help="Optional delay between page fetches.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--snippet-chars", type=int, default=1200, help="Maximum snippet length per page.")
    parser.add_argument("--insecure", action="store_true", help="Disable TLS certificate verification.")
    return parser.parse_args()


def same_host(url: str, seed_host: str) -> bool:
    return urllib.parse.urlparse(url).netloc == seed_host


def crawl(args: argparse.Namespace) -> dict:
    seed_host = urllib.parse.urlparse(args.seed_url).netloc
    queue = collections.deque([(args.seed_url, 0)])
    visited: set[str] = set()
    pages: list[dict] = []

    while queue and len(pages) < args.max_pages:
        current_url, depth = queue.popleft()
        if current_url in visited:
            continue

        visited.add(current_url)
        try:
            fetched = fetch_url(current_url, timeout=args.timeout, insecure=args.insecure)
        except Exception as exc:
            pages.append(
                {
                    "url": current_url,
                    "status": "error",
                    "content_type": "",
                    "retrieved_at": "",
                    "depth": depth,
                    "title": "",
                    "snippet": str(exc),
                }
            )
            continue
        page = {
            "url": fetched["final_url"],
            "status": fetched["status"],
            "content_type": fetched["content_type"],
            "retrieved_at": fetched["retrieved_at"],
            "depth": depth,
            "title": "",
            "snippet": "",
        }

        links: list[str] = []
        if fetched["content_type"] == "text/html":
            parsed = html_to_markdownish(fetched["text"])
            page["title"] = parsed["title"]
            page["snippet"] = truncate_text(parsed["text"], args.snippet_chars)
            if depth < args.max_depth:
                links = [
                    link
                    for link in extract_links(fetched["text"], fetched["final_url"])
                    if same_host(link, seed_host)
                ]
        else:
            page["snippet"] = truncate_text(fetched["text"], args.snippet_chars)

        pages.append(page)

        for link in dedupe_preserve_order(links):
            if link not in visited:
                queue.append((link, depth + 1))

        if args.delay_seconds:
            time.sleep(args.delay_seconds)

    return {
        "seed_url": args.seed_url,
        "seed_host": seed_host,
        "max_pages": args.max_pages,
        "max_depth": args.max_depth,
        "pages_fetched": len(pages),
        "pages": pages,
    }


def to_markdown(payload: dict) -> str:
    lines = [
        "# Crawl Report",
        "",
        f"- Seed URL: {payload['seed_url']}",
        f"- Host: {payload['seed_host']}",
        f"- Max pages: {payload['max_pages']}",
        f"- Max depth: {payload['max_depth']}",
        f"- Pages fetched: {payload['pages_fetched']}",
        "",
    ]

    for index, page in enumerate(payload["pages"], start=1):
        heading = page["title"] or page["url"]
        lines.extend(
            [
                f"## {index}. {heading}",
                "",
                f"- URL: {page['url']}",
                f"- Depth: {page['depth']}",
                f"- Status: {page['status']}",
                f"- Content-Type: {page['content_type']}",
                f"- Retrieved at: {page['retrieved_at']}",
                "",
                page["snippet"],
                "",
            ]
        )

    return "\n".join(lines).rstrip()


def main() -> int:
    args = parse_args()
    payload = crawl(args)
    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
