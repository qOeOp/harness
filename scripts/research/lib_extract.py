from __future__ import annotations

import datetime as _dt
import email.utils
import hashlib
import json
import os
import pathlib
import re
import ssl
import sys
import time
import urllib.parse
import urllib.error
import urllib.request
from html.parser import HTMLParser
from typing import Iterable

sys.dont_write_bytecode = True


USER_AGENT = "harness-research/0.1 (+https://github.com)"
MAX_FETCH_BYTES = 2_000_000
DEFAULT_HTTP_RETRIES = 2
DEFAULT_MAX_RETRY_AFTER_SECONDS = 15
TRANSIENT_HTTP_STATUS_CODES = {408, 429, 500, 502, 503, 504}


def now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).replace(microsecond=0).isoformat()


def build_ssl_context(insecure: bool = False) -> ssl.SSLContext:
    if insecure:
        return ssl._create_unverified_context()

    try:
        import certifi  # type: ignore
    except Exception:
        return ssl.create_default_context()

    return ssl.create_default_context(cafile=certifi.where())


def env_truthy(name: str) -> bool:
    value = os.environ.get(name, "").strip().lower()
    return value in {"1", "true", "yes", "on"}


def cache_root() -> pathlib.Path | None:
    if env_truthy("HARNESS_RESEARCH_DISABLE_HTTP_CACHE"):
        return None

    configured = os.environ.get("HARNESS_RESEARCH_HTTP_CACHE_DIR", "").strip()
    if configured:
        return pathlib.Path(configured).expanduser()

    xdg_cache_home = os.environ.get("XDG_CACHE_HOME", "").strip()
    if xdg_cache_home:
        return pathlib.Path(xdg_cache_home).expanduser() / "harness" / "research" / "http-cache"

    return pathlib.Path.home() / ".cache" / "harness" / "research" / "http-cache"


def cache_paths(url: str) -> tuple[pathlib.Path, pathlib.Path] | tuple[None, None]:
    root = cache_root()
    if root is None:
        return None, None

    key = hashlib.sha256(url.encode("utf-8")).hexdigest()
    return root / f"{key}.json", root / f"{key}.body.txt"


def load_cached_response(url: str) -> dict | None:
    meta_path, body_path = cache_paths(url)
    if meta_path is None or body_path is None or not meta_path.is_file() or not body_path.is_file():
        return None

    try:
        metadata = json.loads(meta_path.read_text(encoding="utf-8"))
        body = body_path.read_text(encoding="utf-8")
    except Exception:
        return None

    metadata["text"] = body
    return metadata


def store_cached_response(payload: dict) -> None:
    cache_control = str(payload.get("cache_control", "")).lower()
    if "no-store" in cache_control:
        return

    meta_path, body_path = cache_paths(str(payload["url"]))
    if meta_path is None or body_path is None:
        return

    meta_path.parent.mkdir(parents=True, exist_ok=True)
    metadata = {key: value for key, value in payload.items() if key != "text"}
    meta_path.write_text(to_json(metadata), encoding="utf-8")
    body_path.write_text(str(payload["text"]), encoding="utf-8")


def parse_retry_after(header_value: str) -> float | None:
    value = header_value.strip()
    if not value:
        return None

    if value.isdigit():
        return max(0.0, float(value))

    try:
        parsed = email.utils.parsedate_to_datetime(value)
    except (TypeError, ValueError, IndexError):
        return None

    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=_dt.timezone.utc)
    delta = (parsed - _dt.datetime.now(_dt.timezone.utc)).total_seconds()
    return max(0.0, delta)


def parse_max_retry_after() -> float:
    raw_value = os.environ.get("HARNESS_RESEARCH_HTTP_MAX_RETRY_AFTER", "").strip()
    if not raw_value:
        return float(DEFAULT_MAX_RETRY_AFTER_SECONDS)

    try:
        return max(0.0, float(raw_value))
    except ValueError:
        return float(DEFAULT_MAX_RETRY_AFTER_SECONDS)


def parse_retry_budget() -> int:
    raw_value = os.environ.get("HARNESS_RESEARCH_HTTP_RETRIES", "").strip()
    if not raw_value:
        return DEFAULT_HTTP_RETRIES

    try:
        return max(0, int(raw_value))
    except ValueError:
        return DEFAULT_HTTP_RETRIES


def build_request_headers(cached: dict | None) -> dict[str, str]:
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": (
            "text/html,application/xhtml+xml,application/rss+xml,application/atom+xml,"
            "application/json,text/plain;q=0.9,*/*;q=0.8"
        ),
        "Accept-Language": "en-US,en;q=0.9",
    }

    if not cached:
        return headers

    etag = str(cached.get("etag", "")).strip()
    last_modified = str(cached.get("last_modified", "")).strip()
    if etag:
        headers["If-None-Match"] = etag
    if last_modified:
        headers["If-Modified-Since"] = last_modified
    return headers


def decode_response_body(raw_bytes: bytes, headers) -> tuple[str, str]:
    charset = headers.get_content_charset() or "utf-8"
    try:
        text = raw_bytes.decode(charset, errors="replace")
    except LookupError:
        charset = "utf-8"
        text = raw_bytes.decode(charset, errors="replace")
    return charset, text


def response_cache_headers(headers) -> dict[str, str]:
    return {
        "etag": headers.get("ETag", ""),
        "last_modified": headers.get("Last-Modified", ""),
        "cache_control": headers.get("Cache-Control", ""),
        "retry_after": headers.get("Retry-After", ""),
    }


def build_response_payload(url: str, response, max_bytes: int, *, cached: dict | None, attempt: int) -> dict:
    raw_bytes = response.read(max_bytes + 1)
    truncated = len(raw_bytes) > max_bytes
    raw_bytes = raw_bytes[:max_bytes]
    charset, text = decode_response_body(raw_bytes, response.headers)
    cache_headers = response_cache_headers(response.headers)
    cache_status = "miss"
    if cache_root() is None:
        cache_status = "disabled"
    elif cached is not None and (cache_headers["etag"] or cache_headers["last_modified"]):
        cache_status = "refreshed"

    return {
        "url": url,
        "final_url": response.geturl(),
        "status": getattr(response, "status", None),
        "origin_status": getattr(response, "status", None),
        "content_type": response.headers.get_content_type(),
        "charset": charset,
        "retrieved_at": now_iso(),
        "truncated": truncated,
        "text": text,
        "etag": cache_headers["etag"],
        "last_modified": cache_headers["last_modified"],
        "cache_control": cache_headers["cache_control"],
        "retry_after": cache_headers["retry_after"],
        "cache_status": cache_status,
        "served_from_cache": False,
        "attempts": attempt,
    }


def build_revalidated_payload(url: str, cached: dict, *, attempt: int) -> dict:
    return {
        **cached,
        "url": url,
        "status": cached.get("status"),
        "origin_status": 304,
        "retrieved_at": now_iso(),
        "cache_status": "revalidated",
        "served_from_cache": True,
        "attempts": attempt,
        "retry_after": "",
    }


def compute_retry_delay(attempt: int, retry_after_header: str) -> float | None:
    retry_after_seconds = parse_retry_after(retry_after_header)
    max_retry_after = parse_max_retry_after()
    if retry_after_seconds is not None:
        return min(retry_after_seconds, max_retry_after)

    return min(float(2 ** (attempt - 1)), max_retry_after)


def should_retry_http_error(exc: urllib.error.HTTPError) -> bool:
    return exc.code in TRANSIENT_HTTP_STATUS_CODES


def fetch_url(url: str, timeout: int = 20, max_bytes: int = MAX_FETCH_BYTES, insecure: bool = False) -> dict:
    cached = load_cached_response(url)
    headers = build_request_headers(cached)
    request = urllib.request.Request(url, headers=headers)
    max_retries = parse_retry_budget()
    ssl_context = build_ssl_context(insecure=insecure)

    for attempt in range(1, max_retries + 2):
        try:
            with urllib.request.urlopen(request, timeout=timeout, context=ssl_context) as response:
                payload = build_response_payload(url, response, max_bytes, cached=cached, attempt=attempt)
                if cache_root() is not None:
                    store_cached_response(payload)
                return payload
        except urllib.error.HTTPError as exc:
            if exc.code == 304 and cached is not None:
                return build_revalidated_payload(url, cached, attempt=attempt)

            if should_retry_http_error(exc) and attempt <= max_retries:
                delay = compute_retry_delay(attempt, exc.headers.get("Retry-After", ""))
                if delay is not None and delay > 0:
                    time.sleep(delay)
                continue
            raise
        except urllib.error.URLError:
            if attempt <= max_retries:
                delay = compute_retry_delay(attempt, "")
                if delay is not None and delay > 0:
                    time.sleep(delay)
                continue
            raise


def truncate_text(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 1].rstrip() + "…"


def compact_whitespace(text: str) -> str:
    return re.sub(r"[ \t\r\f\v]+", " ", text.strip())


class MarkdownishHTMLParser(HTMLParser):
    BLOCK_TAGS = {
        "article",
        "blockquote",
        "div",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "li",
        "main",
        "ol",
        "p",
        "pre",
        "section",
        "table",
        "tr",
        "ul",
    }
    SKIP_TAGS = {"script", "style", "noscript", "svg"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.links: list[str] = []
        self.skip_depth = 0
        self.capture_title = False
        self.title_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in self.SKIP_TAGS:
            self.skip_depth += 1
            return

        if self.skip_depth:
            return

        if tag == "title":
            self.capture_title = True
            return

        if tag in self.BLOCK_TAGS:
            self.parts.append("\n\n")

        if tag == "li":
            self.parts.append("- ")

        if tag == "br":
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in self.SKIP_TAGS:
            if self.skip_depth:
                self.skip_depth -= 1
            return

        if self.skip_depth:
            return

        if tag == "title":
            self.capture_title = False
            return

        if tag in self.BLOCK_TAGS:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if self.skip_depth:
            return

        cleaned = compact_whitespace(data)
        if not cleaned:
            return

        if self.capture_title:
            self.title_parts.append(cleaned)

        self.parts.append(cleaned)

    @property
    def title(self) -> str:
        return compact_whitespace(" ".join(self.title_parts))

    def markdownish_text(self) -> str:
        text = "".join(self.parts)
        text = re.sub(r"\n{3,}", "\n\n", text)
        return text.strip()


class LinkParser(HTMLParser):
    def __init__(self, base_url: str) -> None:
        super().__init__(convert_charrefs=True)
        self.base_url = base_url
        self.links: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag != "a":
            return

        href = None
        for key, value in attrs:
            if key == "href":
                href = value
                break

        if not href:
            return

        resolved = urllib.parse.urljoin(self.base_url, href)
        parsed = urllib.parse.urlparse(resolved)
        if parsed.scheme not in {"http", "https"}:
            return

        normalized = parsed._replace(fragment="").geturl()
        self.links.append(normalized)


def html_to_markdownish(html_text: str) -> dict:
    parser = MarkdownishHTMLParser()
    parser.feed(html_text)
    return {
        "title": parser.title,
        "text": parser.markdownish_text(),
    }


def extract_links(html_text: str, base_url: str) -> list[str]:
    parser = LinkParser(base_url)
    parser.feed(html_text)
    return dedupe_preserve_order(parser.links)


def dedupe_preserve_order(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        ordered.append(value)
    return ordered


def to_json(data: object) -> str:
    return json.dumps(data, ensure_ascii=True, indent=2, sort_keys=True)
