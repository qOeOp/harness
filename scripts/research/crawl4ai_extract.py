from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import asyncio
import os
from contextlib import nullcontext

from lib_extract import now_iso, to_json, truncate_text
from lib_local_browser import local_profile_snapshot_context

try:
    from crawl4ai import AsyncWebCrawler, BrowserConfig, CacheMode, CrawlerRunConfig
except Exception:
    try:
        from crawl4ai import AsyncWebCrawler
        from crawl4ai.async_configs import BrowserConfig, CrawlerRunConfig
        from crawl4ai.cache_context import CacheMode
    except Exception as exc:  # pragma: no cover - runtime dependency check
        raise SystemExit(f"Crawl4AI is required for this route: {exc}") from exc

try:
    from crawl4ai.content_filter_strategy import PruningContentFilter
    from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
except Exception:  # pragma: no cover - optional fit-markdown support
    PruningContentFilter = None
    DefaultMarkdownGenerator = None


DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render one URL with Crawl4AI and extract markdown.")
    parser.add_argument("url", help="URL to fetch.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--max-chars", type=int, default=12000, help="Maximum content characters to print.")
    parser.add_argument("--page-timeout", type=int, default=45000, help="Page timeout in milliseconds.")
    parser.add_argument("--wait-for", default="", help='Optional wait condition, for example "css:main" or "js:() => true".')
    parser.add_argument("--css-selector", default="", help="Optional CSS selector to scope extraction.")
    parser.add_argument("--js-code", action="append", default=[], help="Optional JavaScript snippet to execute before extraction.")
    parser.add_argument(
        "--cache-mode",
        choices=["enabled", "disabled", "read_only", "write_only", "bypass"],
        default="bypass",
        help="Crawl4AI cache mode. Defaults to bypass for fresher research runs.",
    )
    parser.add_argument("--delay-before-return-html", type=float, default=1.5, help="Extra delay before capture in seconds.")
    parser.add_argument("--scan-full-page", action="store_true", help="Scroll through the page before extraction.")
    parser.add_argument("--fit-markdown", action="store_true", help="Use Crawl4AI pruning-based fit markdown when available.")
    parser.add_argument("--word-count-threshold", type=int, default=10, help="Minimum word count threshold for content blocks.")
    parser.add_argument("--simulate-user", action="store_true", help="Enable Crawl4AI simulate_user mode.")
    parser.add_argument("--override-navigator", action="store_true", help="Enable Crawl4AI override_navigator mode.")
    parser.add_argument("--magic", action="store_true", help="Enable Crawl4AI magic mode.")
    parser.add_argument("--user-data-dir", default="", help="Optional persistent browser profile directory.")
    parser.add_argument(
        "--channel",
        choices=["chromium", "chrome", "msedge"],
        default="",
        help="Optional browser channel to use with --user-data-dir.",
    )
    parser.add_argument(
        "--local-browser",
        choices=["chrome", "edge", "chromium"],
        default="",
        help="Copy a local Chromium-family browser profile into a temporary headless snapshot.",
    )
    parser.add_argument(
        "--profile-directory",
        default="",
        help="Profile directory name for --local-browser, for example Default or Profile 1.",
    )
    return parser.parse_args()


def resolve_auth_config(args: argparse.Namespace) -> dict:
    user_data_dir = args.user_data_dir or os.environ.get("HARNESS_RESEARCH_BROWSER_USER_DATA_DIR", "")
    channel = args.channel or os.environ.get("HARNESS_RESEARCH_BROWSER_CHANNEL", "")
    local_browser = args.local_browser or os.environ.get("HARNESS_RESEARCH_BROWSER_LOCAL_BROWSER", "")
    profile_directory = args.profile_directory or os.environ.get("HARNESS_RESEARCH_BROWSER_PROFILE_DIRECTORY", "")
    storage_state = os.environ.get("HARNESS_RESEARCH_BROWSER_STORAGE_STATE", "")

    if args.user_data_dir and args.local_browser:
        raise SystemExit("use only one auth source: --user-data-dir or --local-browser")

    if user_data_dir and local_browser:
        raise SystemExit("use only one auth source: --user-data-dir or --local-browser")

    if user_data_dir and not os.path.isdir(user_data_dir):
        raise SystemExit(f"user data directory not found: {user_data_dir}")

    if not channel:
        channel = "chrome"

    if local_browser and not profile_directory:
        profile_directory = "Default"

    if storage_state and not user_data_dir and not local_browser:
        raise SystemExit("crawl4ai route does not yet support storage-state auth; use --user-data-dir or --local-browser")

    if user_data_dir:
        return {
            "mode": "persistent-profile",
            "user_data_dir": user_data_dir,
            "channel": channel,
            "local_browser": "",
            "profile_directory": "",
        }

    if local_browser:
        return {
            "mode": "local-browser-copy",
            "user_data_dir": "",
            "channel": "msedge" if local_browser == "edge" else ("chromium" if local_browser == "chromium" else "chrome"),
            "local_browser": local_browser,
            "profile_directory": profile_directory,
        }

    return {
        "mode": "anonymous",
        "user_data_dir": "",
        "channel": "",
        "local_browser": "",
        "profile_directory": "",
    }


def resolve_cache_mode(value: str):
    mapping = {
        "enabled": getattr(CacheMode, "ENABLED"),
        "disabled": getattr(CacheMode, "DISABLED"),
        "read_only": getattr(CacheMode, "READ_ONLY"),
        "write_only": getattr(CacheMode, "WRITE_ONLY"),
        "bypass": getattr(CacheMode, "BYPASS"),
    }
    return mapping[value]


def build_browser_config(auth: dict) -> BrowserConfig:
    config_kwargs = {
        "browser_type": "chromium",
        "headless": True,
        "verbose": False,
        "user_agent": DEFAULT_USER_AGENT,
        "headers": {"Accept-Language": "en-US,en;q=0.9"},
    }

    if auth["mode"] == "persistent-profile":
        config_kwargs.update(
            {
                "use_managed_browser": True,
                "use_persistent_context": True,
                "user_data_dir": auth["user_data_dir"],
                "chrome_channel": auth["channel"],
            }
        )
    elif auth["mode"] == "local-browser-copy":
        config_kwargs.update(
            {
                "use_managed_browser": True,
                "use_persistent_context": True,
                "user_data_dir": auth["user_data_dir"],
                "chrome_channel": auth["channel"],
            }
        )

    return BrowserConfig(**config_kwargs)


def build_markdown_generator(args: argparse.Namespace):
    if not args.fit_markdown:
        return None
    if DefaultMarkdownGenerator is None or PruningContentFilter is None:
        raise SystemExit("fit-markdown requested, but Crawl4AI markdown extras are unavailable in this installation")

    return DefaultMarkdownGenerator(
        content_filter=PruningContentFilter(threshold=args.word_count_threshold)
    )


def extract_markdown_content(result, prefer_fit_markdown: bool) -> str:
    markdown = getattr(result, "markdown", "")
    if isinstance(markdown, str):
        return markdown

    candidate_order = ["fit_markdown", "raw_markdown", "markdown"] if prefer_fit_markdown else ["raw_markdown", "fit_markdown", "markdown"]
    for attribute in candidate_order:
        value = getattr(markdown, attribute, None)
        if isinstance(value, str) and value.strip():
            return value

    if isinstance(markdown, dict):
        for key in candidate_order:
            value = markdown.get(key)
            if isinstance(value, str) and value.strip():
                return value

    for attribute in ("cleaned_html", "html"):
        value = getattr(result, attribute, None)
        if isinstance(value, str) and value.strip():
            return value

    return ""


def detect_warning(payload: dict) -> str:
    if not payload["success"]:
        return payload["error_message"] or "crawl4ai run failed"
    if not payload["content"].strip():
        return "crawl4ai returned empty extracted content"
    if payload["title"] == "X":
        lowered = payload["content"].lower()
        if "don’t miss what’s happening" in lowered or "people on x are the first to know" in lowered:
            return "rendered page looks like a public landing/login wall rather than the target content"
    return ""


async def run_crawl(args: argparse.Namespace) -> dict:
    auth = resolve_auth_config(args)
    snapshot_context = nullcontext()

    if auth["mode"] == "local-browser-copy":
        snapshot_context = local_profile_snapshot_context(auth["local_browser"], auth["profile_directory"])

    with snapshot_context as snapshot_root:
        if snapshot_root is not None:
            auth = {
                **auth,
                "user_data_dir": str(snapshot_root),
            }

        browser_config = build_browser_config(auth)
        markdown_generator = build_markdown_generator(args)
        run_config_kwargs = {
            "cache_mode": resolve_cache_mode(args.cache_mode),
            "word_count_threshold": args.word_count_threshold,
            "page_timeout": args.page_timeout,
            "delay_before_return_html": args.delay_before_return_html,
            "scan_full_page": args.scan_full_page,
            "simulate_user": args.simulate_user,
            "override_navigator": args.override_navigator,
            "magic": args.magic,
        }
        if args.wait_for:
            run_config_kwargs["wait_for"] = args.wait_for
        if args.css_selector:
            run_config_kwargs["css_selector"] = args.css_selector
        if args.js_code:
            run_config_kwargs["js_code"] = args.js_code if len(args.js_code) > 1 else args.js_code[0]
        if markdown_generator is not None:
            run_config_kwargs["markdown_generator"] = markdown_generator

        run_config = CrawlerRunConfig(**run_config_kwargs)

        async with AsyncWebCrawler(config=browser_config) as crawler:
            result = await crawler.arun(url=args.url, config=run_config)

    content = extract_markdown_content(result, args.fit_markdown)
    truncated = len(content) > args.max_chars
    content = truncate_text(content, args.max_chars)
    payload = {
        "url": args.url,
        "final_url": getattr(result, "url", args.url),
        "status": getattr(result, "status_code", None),
        "content_type": "text/markdown",
        "retrieved_at": now_iso(),
        "truncated": truncated,
        "title": getattr(result, "metadata", {}).get("title", "") if isinstance(getattr(result, "metadata", {}), dict) else "",
        "content": content,
        "route": "crawl4ai",
        "renderer": "crawl4ai-headless",
        "success": bool(getattr(result, "success", False)),
        "error_message": getattr(result, "error_message", ""),
        "cache_mode": args.cache_mode,
        "auth_mode": auth["mode"],
        "local_browser": auth["local_browser"],
        "profile_directory": auth["profile_directory"],
        "wait_for": args.wait_for,
        "css_selector": args.css_selector,
        "fit_markdown": args.fit_markdown,
    }
    payload["warning"] = detect_warning(payload)
    return payload


def to_markdown(payload: dict) -> str:
    status = payload["status"] if payload["status"] is not None else "unknown"
    title = payload["title"] or payload["final_url"]
    return "\n".join(
        [
            "# Crawl4AI Extract",
            "",
            f"- URL: {payload['url']}",
            f"- Final URL: {payload['final_url']}",
            f"- Status: {status}",
            f"- Content-Type: {payload['content_type']}",
            f"- Retrieved at: {payload['retrieved_at']}",
            f"- Title: {title}",
            f"- Route: {payload['route']}",
            f"- Renderer: {payload['renderer']}",
            f"- Success: {'yes' if payload['success'] else 'no'}",
            f"- Cache mode: {payload['cache_mode']}",
            f"- Auth mode: {payload['auth_mode']}",
            f"- Local browser: {payload['local_browser'] or 'n/a'}",
            f"- Profile directory: {payload['profile_directory'] or 'n/a'}",
            f"- Wait-for: {payload['wait_for'] or 'n/a'}",
            f"- CSS selector: {payload['css_selector'] or 'n/a'}",
            f"- Fit markdown: {'yes' if payload['fit_markdown'] else 'no'}",
            f"- Truncated: {'yes' if payload['truncated'] else 'no'}",
            f"- Warning: {payload['warning'] or 'none'}",
            "",
            "## Content",
            "",
            payload["content"],
        ]
    )


def main() -> int:
    args = parse_args()
    payload = asyncio.run(run_crawl(args))
    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
