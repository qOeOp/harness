from __future__ import annotations

import datetime as _dt
import json
import re
import ssl
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from typing import Iterable


USER_AGENT = "harness-research/0.1 (+https://github.com)"
MAX_FETCH_BYTES = 2_000_000


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


def fetch_url(url: str, timeout: int = 20, max_bytes: int = MAX_FETCH_BYTES, insecure: bool = False) -> dict:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept": "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
        },
    )

    with urllib.request.urlopen(request, timeout=timeout, context=build_ssl_context(insecure=insecure)) as response:
        raw_bytes = response.read(max_bytes + 1)
        truncated = len(raw_bytes) > max_bytes
        raw_bytes = raw_bytes[:max_bytes]
        charset = response.headers.get_content_charset() or "utf-8"
        try:
            text = raw_bytes.decode(charset, errors="replace")
        except LookupError:
            text = raw_bytes.decode("utf-8", errors="replace")

        return {
            "url": url,
            "final_url": response.geturl(),
            "status": getattr(response, "status", None),
            "content_type": response.headers.get_content_type(),
            "charset": charset,
            "retrieved_at": now_iso(),
            "truncated": truncated,
            "text": text,
        }


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
