from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request


API_URL = "https://api.tavily.com/search"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Search Tavily and print JSON results.")
    parser.add_argument("query", help="Search query.")
    parser.add_argument("--max-results", type=int, default=5, help="Maximum results to request.")
    parser.add_argument(
        "--topic",
        choices=["general", "news", "finance"],
        default="general",
        help="Tavily topic.",
    )
    parser.add_argument(
        "--search-depth",
        choices=["basic", "advanced"],
        default="basic",
        help="Search depth.",
    )
    parser.add_argument(
        "--include-raw-content",
        choices=["false", "true", "markdown", "text"],
        default="markdown",
        help="Whether to include parsed content from results.",
    )
    parser.add_argument(
        "--time-range",
        choices=["day", "week", "month", "year", "d", "w", "m", "y"],
        default=None,
        help="Optional time range filter.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    api_key = os.environ.get("TAVILY_API_KEY")
    if not api_key:
        print("TAVILY_API_KEY is required for research search.", file=sys.stderr)
        return 1

    payload = {
        "api_key": api_key,
        "query": args.query,
        "topic": args.topic,
        "search_depth": args.search_depth,
        "max_results": args.max_results,
        "include_answer": False,
        "include_raw_content": False if args.include_raw_content == "false" else args.include_raw_content,
    }
    if args.time_range:
        payload["time_range"] = args.time_range

    request = urllib.request.Request(
        API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "User-Agent": "harness-research/0.1"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            data = json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        print(f"Tavily request failed with HTTP {exc.code}", file=sys.stderr)
        print(body, file=sys.stderr)
        return 1
    except urllib.error.URLError as exc:
        print(f"Tavily request failed: {exc}", file=sys.stderr)
        return 1

    print(json.dumps(data, ensure_ascii=True, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
