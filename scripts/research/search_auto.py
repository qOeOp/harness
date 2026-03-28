from __future__ import annotations

import argparse
import sys

sys.dont_write_bytecode = True

from lib_search import normalize_time_range, resolve_backend, search_searxng, search_tavily, to_json


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Search using the best available research backend.")
    parser.add_argument("query", help="Search query.")
    parser.add_argument("--backend", choices=["auto", "tavily", "searxng"], default="auto")
    parser.add_argument("--max-results", type=int, default=5, help="Maximum results to request.")
    parser.add_argument(
        "--topic",
        choices=["general", "news", "finance"],
        default="general",
        help="Tavily topic. Ignored by SearXNG.",
    )
    parser.add_argument(
        "--search-depth",
        choices=["basic", "advanced"],
        default="basic",
        help="Tavily search depth. Ignored by SearXNG.",
    )
    parser.add_argument(
        "--include-raw-content",
        choices=["false", "true", "markdown", "text"],
        default="false",
        help="Request fuller backend content when supported.",
    )
    parser.add_argument(
        "--time-range",
        choices=["day", "week", "month", "year", "d", "w", "m", "y"],
        default=None,
        help="Optional time range filter.",
    )
    parser.add_argument("--categories", default="", help="Optional SearXNG categories list.")
    parser.add_argument("--engines", default="", help="Optional SearXNG engines list.")
    parser.add_argument("--language", default="", help="Optional SearXNG language code.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    time_range = normalize_time_range(args.time_range)
    backend = resolve_backend(args.backend)

    if backend == "tavily":
        payload = search_tavily(
            query=args.query,
            max_results=args.max_results,
            topic=args.topic,
            search_depth=args.search_depth,
            include_raw_content=args.include_raw_content,
            time_range=time_range,
        )
    else:
        payload = search_searxng(
            query=args.query,
            max_results=args.max_results,
            time_range=time_range,
            categories=args.categories,
            engines=args.engines,
            language=args.language,
            include_raw_content=args.include_raw_content,
            topic=args.topic,
            search_depth=args.search_depth,
        )

    print(to_json(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
