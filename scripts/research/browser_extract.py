from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import os
import re
from contextlib import nullcontext

from lib_extract import now_iso, to_json, truncate_text
from lib_local_browser import local_profile_snapshot_context

try:
    from playwright.sync_api import Error as PlaywrightError
    from playwright.sync_api import sync_playwright
except Exception as exc:  # pragma: no cover - runtime dependency check
    raise SystemExit(f"Playwright is required for browser extraction: {exc}") from exc


DEFAULT_SELECTORS = [
    "article",
    "main article",
    "main",
    "[role='main']",
    "body",
]
DEFAULT_BROWSER_ARGS = [
    "--disable-blink-features=AutomationControlled",
]
DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render one URL in a headless browser and extract text.")
    parser.add_argument("url", help="URL to fetch.")
    parser.add_argument("--format", choices=["markdown", "json"], default="markdown")
    parser.add_argument("--max-chars", type=int, default=12000, help="Maximum content characters to print.")
    parser.add_argument("--timeout", type=int, default=30, help="Navigation timeout in seconds.")
    parser.add_argument(
        "--wait-until",
        choices=["domcontentloaded", "load", "networkidle"],
        default="domcontentloaded",
        help="Playwright navigation readiness target.",
    )
    parser.add_argument(
        "--settle-ms",
        type=int,
        default=1500,
        help="Extra wait after navigation for client-side rendering.",
    )
    parser.add_argument(
        "--selector",
        default="",
        help="Optional CSS selector to extract instead of auto-detection.",
    )
    parser.add_argument(
        "--storage-state",
        default="",
        help="Optional Playwright storage state JSON for authenticated headless runs.",
    )
    parser.add_argument(
        "--user-data-dir",
        default="",
        help="Optional browser profile directory for authenticated persistent headless runs.",
    )
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


def normalize_text(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def detect_warning(title: str, body: str) -> str:
    if not body.strip():
        return "rendered page returned no visible text; the site may still be blocking scripted access"
    lowered = body.lower()
    signals = [
        "don’t miss what’s happening",
        "people on x are the first to know",
        "log in\nsign up",
    ]
    if title == "X" and any(signal in lowered for signal in signals):
        return "rendered page looks like a public landing/login wall rather than the target content"
    return ""


def resolve_auth_config(args: argparse.Namespace) -> dict:
    storage_state = args.storage_state or os.environ.get("HARNESS_RESEARCH_BROWSER_STORAGE_STATE", "")
    user_data_dir = args.user_data_dir or os.environ.get("HARNESS_RESEARCH_BROWSER_USER_DATA_DIR", "")
    channel = args.channel or os.environ.get("HARNESS_RESEARCH_BROWSER_CHANNEL", "")
    local_browser = args.local_browser or os.environ.get("HARNESS_RESEARCH_BROWSER_LOCAL_BROWSER", "")
    profile_directory = args.profile_directory or os.environ.get("HARNESS_RESEARCH_BROWSER_PROFILE_DIRECTORY", "")

    if sum(bool(value) for value in (storage_state, user_data_dir, local_browser)) > 1:
        raise SystemExit("use only one auth source: --storage-state, --user-data-dir, or --local-browser")

    if storage_state and not os.path.isfile(storage_state):
        raise SystemExit(f"storage state file not found: {storage_state}")

    if user_data_dir and not os.path.isdir(user_data_dir):
        raise SystemExit(f"user data directory not found: {user_data_dir}")

    if not channel:
        channel = "chrome"

    if local_browser and not profile_directory:
        profile_directory = "Default"

    if storage_state:
        return {
            "mode": "storage-state",
            "storage_state": storage_state,
            "user_data_dir": "",
            "channel": "",
            "local_browser": "",
            "profile_directory": "",
        }

    if user_data_dir:
        return {
            "mode": "persistent-profile",
            "storage_state": "",
            "user_data_dir": user_data_dir,
            "channel": channel,
            "local_browser": "",
            "profile_directory": "",
        }

    if local_browser:
        return {
            "mode": "local-browser-copy",
            "storage_state": "",
            "user_data_dir": "",
            "channel": "msedge" if local_browser == "edge" else ("chromium" if local_browser == "chromium" else "chrome"),
            "local_browser": local_browser,
            "profile_directory": profile_directory,
        }

    return {
        "mode": "anonymous",
        "storage_state": "",
        "user_data_dir": "",
        "channel": "",
        "local_browser": "",
        "profile_directory": "",
    }


def pick_rendered_text(page, selector: str) -> tuple[str, str]:
    if selector:
        handle = page.query_selector(selector)
        if handle is None:
            raise SystemExit(f"selector not found: {selector}")
        text = normalize_text(handle.inner_text())
        if not text:
            raise SystemExit(f"selector matched but returned empty text: {selector}")
        return selector, text

    result = page.evaluate(
        """
        (selectors) => {
          const candidates = [];
          const seen = new Set();

          for (const selector of selectors) {
            for (const node of document.querySelectorAll(selector)) {
              if (seen.has(node)) {
                continue;
              }
              seen.add(node);
              const text = (node.innerText || "").trim();
              if (!text) {
                continue;
              }
              candidates.push({ selector, text });
            }
          }

          if (!candidates.length) {
            return {
              selector: "body",
              text: (document.body && document.body.innerText ? document.body.innerText : "").trim(),
            };
          }

          const richCandidate = candidates.find((candidate) => candidate.text.length >= 400);
          if (richCandidate) {
            return richCandidate;
          }

          return candidates.reduce((best, candidate) =>
            candidate.text.length > best.text.length ? candidate : best
          );
        }
        """,
        DEFAULT_SELECTORS,
    )
    return result["selector"], normalize_text(result["text"])


def pick_rendered_text_with_retry(page, selector: str) -> tuple[str, str]:
    last_error = None
    for _ in range(2):
        try:
            return pick_rendered_text(page, selector)
        except PlaywrightError as exc:
            last_error = exc
            page.wait_for_load_state("domcontentloaded")
            page.wait_for_timeout(1000)
    if last_error is not None:
        raise last_error
    raise SystemExit("failed to extract rendered text")


def build_payload(args: argparse.Namespace) -> dict:
    auth = resolve_auth_config(args)
    snapshot_context = nullcontext()
    snapshot_root = None

    if auth["mode"] == "local-browser-copy":
        snapshot_context = local_profile_snapshot_context(auth["local_browser"], auth["profile_directory"])

    with snapshot_context as snapshot_data, sync_playwright() as playwright:
        if snapshot_data is not None:
            snapshot_root = snapshot_data
        if auth["mode"] == "persistent-profile":
            context = playwright.chromium.launch_persistent_context(
                auth["user_data_dir"],
                headless=True,
                channel=auth["channel"],
                args=DEFAULT_BROWSER_ARGS,
                user_agent=DEFAULT_USER_AGENT,
                viewport={"width": 1280, "height": 720},
                locale="en-US",
                extra_http_headers={"Accept-Language": "en-US,en;q=0.9"},
            )
            browser = None
        elif auth["mode"] == "local-browser-copy":
            assert snapshot_root is not None
            context = playwright.chromium.launch_persistent_context(
                str(snapshot_root),
                headless=True,
                channel=auth["channel"],
                args=[*DEFAULT_BROWSER_ARGS, f"--profile-directory={auth['profile_directory']}"],
                user_agent=DEFAULT_USER_AGENT,
                viewport={"width": 1280, "height": 720},
                locale="en-US",
                extra_http_headers={"Accept-Language": "en-US,en;q=0.9"},
            )
            browser = None
        else:
            browser = playwright.chromium.launch(headless=True, args=DEFAULT_BROWSER_ARGS)
            context_kwargs = {
                "user_agent": DEFAULT_USER_AGENT,
                "viewport": {"width": 1280, "height": 720},
                "locale": "en-US",
                "extra_http_headers": {"Accept-Language": "en-US,en;q=0.9"},
            }
            if auth["mode"] == "storage-state":
                context_kwargs["storage_state"] = auth["storage_state"]
            context = browser.new_context(**context_kwargs)

        page = context.pages[0] if context.pages else context.new_page()
        page.add_init_script(
            """
            Object.defineProperty(navigator, 'webdriver', {
              get: () => undefined
            });
            """
        )
        response = page.goto(args.url, wait_until=args.wait_until, timeout=args.timeout * 1000)
        if args.settle_ms > 0:
            page.wait_for_timeout(args.settle_ms)
        selector_used, body = pick_rendered_text_with_retry(page, args.selector)
        was_truncated = len(body) > args.max_chars
        body = truncate_text(body, args.max_chars)
        final_url = page.url
        title = page.title()
        status = response.status if response is not None else None
        content_type = response.header_value("content-type") if response is not None else ""
        warning = detect_warning(title, body)
        context.close()
        if browser is not None:
            browser.close()

    return {
        "url": args.url,
        "final_url": final_url,
        "status": status,
        "content_type": content_type or "text/html",
        "retrieved_at": now_iso(),
        "truncated": was_truncated,
        "title": title,
        "content": body,
        "route": "browser",
        "renderer": "playwright-chromium-headless",
        "selector": selector_used,
        "wait_until": args.wait_until,
        "warning": warning,
        "auth_mode": auth["mode"],
        "local_browser": auth["local_browser"],
        "profile_directory": auth["profile_directory"],
    }


def to_markdown(payload: dict) -> str:
    title = payload["title"] or payload["final_url"]
    status = payload["status"] if payload["status"] is not None else "unknown"
    return "\n".join(
        [
            "# Browser Extract",
            "",
            f"- URL: {payload['url']}",
            f"- Final URL: {payload['final_url']}",
            f"- Status: {status}",
            f"- Content-Type: {payload['content_type']}",
            f"- Retrieved at: {payload['retrieved_at']}",
            f"- Title: {title}",
            f"- Route: {payload['route']}",
            f"- Renderer: {payload['renderer']}",
            f"- Selector: {payload['selector']}",
            f"- Wait-until: {payload['wait_until']}",
            f"- Auth mode: {payload['auth_mode']}",
            f"- Local browser: {payload['local_browser'] or 'n/a'}",
            f"- Profile directory: {payload['profile_directory'] or 'n/a'}",
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
    try:
        payload = build_payload(args)
    except PlaywrightError as exc:
        print(f"browser extraction failed: {exc}", file=sys.stderr)
        return 1

    if args.format == "json":
        print(to_json(payload))
    else:
        print(to_markdown(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
