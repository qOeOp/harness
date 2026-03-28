from __future__ import annotations

import json
import os
import urllib.error
import urllib.parse
import urllib.request

from lib_extract import now_iso, to_json


USER_AGENT = "harness-research/0.1 (+https://github.com)"
TAVILY_API_URL = "https://api.tavily.com/search"


def normalize_time_range(value: str | None) -> str | None:
    if value is None:
        return None

    aliases = {
        "d": "day",
        "w": "week",
        "m": "month",
        "y": "year",
    }
    normalized = aliases.get(value, value)
    return normalized


def resolve_backend(requested_backend: str) -> str:
    if requested_backend not in {"auto", "tavily", "searxng"}:
        raise SystemExit(f"unsupported search backend: {requested_backend}")

    if requested_backend == "tavily":
        if not os.environ.get("TAVILY_API_KEY"):
            raise SystemExit("TAVILY_API_KEY is required for backend=tavily")
        return "tavily"

    if requested_backend == "searxng":
        if not os.environ.get("HARNESS_RESEARCH_SEARXNG_URL"):
            raise SystemExit("HARNESS_RESEARCH_SEARXNG_URL is required for backend=searxng")
        return "searxng"

    if os.environ.get("TAVILY_API_KEY"):
        return "tavily"
    if os.environ.get("HARNESS_RESEARCH_SEARXNG_URL"):
        return "searxng"
    raise SystemExit("search backend unavailable: set TAVILY_API_KEY or HARNESS_RESEARCH_SEARXNG_URL")


def normalize_tavily_response(data: dict, *, query: str, max_results: int, time_range: str | None) -> dict:
    results = []
    for result in data.get("results", [])[:max_results]:
        snippet = result.get("content", "") or ""
        raw_content = result.get("raw_content")
        content = raw_content if isinstance(raw_content, str) and raw_content else snippet
        results.append(
            {
                "title": result.get("title", "") or "",
                "url": result.get("url", "") or "",
                "snippet": snippet,
                "content": content,
                "score": result.get("score"),
                "engine": "",
                "category": "",
                "published_date": result.get("published_date", "") or "",
            }
        )

    return {
        "backend": "tavily",
        "query": query,
        "requested_at": now_iso(),
        "result_count": len(results),
        "max_results": max_results,
        "time_range": time_range or "",
        "results": results,
        "warnings": [],
    }


def search_tavily(
    *,
    query: str,
    max_results: int,
    topic: str,
    search_depth: str,
    include_raw_content: str,
    time_range: str | None,
) -> dict:
    api_key = os.environ.get("TAVILY_API_KEY")
    if not api_key:
        raise SystemExit("TAVILY_API_KEY is required for Tavily search")

    payload = {
        "api_key": api_key,
        "query": query,
        "topic": topic,
        "search_depth": search_depth,
        "max_results": max_results,
        "include_answer": False,
        "include_raw_content": False if include_raw_content == "false" else include_raw_content,
    }
    if time_range:
        payload["time_range"] = time_range

    request = urllib.request.Request(
        TAVILY_API_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            data = json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Tavily request failed with HTTP {exc.code}: {body}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"Tavily request failed: {exc}") from exc

    return normalize_tavily_response(data, query=query, max_results=max_results, time_range=time_range)


def normalize_searxng_response(
    data: dict,
    *,
    query: str,
    max_results: int,
    time_range: str | None,
    search_url: str,
    warnings: list[str],
) -> dict:
    normalized_results = []
    for result in data.get("results", [])[:max_results]:
        engines = result.get("engines", [])
        normalized_results.append(
            {
                "title": result.get("title", "") or "",
                "url": result.get("url", "") or "",
                "snippet": result.get("content", "") or "",
                "content": result.get("content", "") or "",
                "score": result.get("score"),
                "engine": ", ".join(engines) if isinstance(engines, list) else str(engines or ""),
                "category": result.get("category", "") or "",
                "published_date": result.get("publishedDate", "") or "",
            }
        )

    return {
        "backend": "searxng",
        "query": query,
        "requested_at": now_iso(),
        "result_count": len(normalized_results),
        "max_results": max_results,
        "time_range": time_range or "",
        "search_url": search_url,
        "results": normalized_results,
        "warnings": warnings,
    }


def search_searxng(
    *,
    query: str,
    max_results: int,
    time_range: str | None,
    categories: str,
    engines: str,
    language: str,
    include_raw_content: str,
    topic: str,
    search_depth: str,
) -> dict:
    base_url = os.environ.get("HARNESS_RESEARCH_SEARXNG_URL", "").strip()
    if not base_url:
        raise SystemExit("HARNESS_RESEARCH_SEARXNG_URL is required for SearXNG search")

    warnings: list[str] = []
    if include_raw_content != "false":
        warnings.append("searxng backend returns normalized snippets only; include_raw_content was ignored")
    if topic != "general":
        warnings.append("searxng backend ignores topic; request used default instance behavior")
    if search_depth != "basic":
        warnings.append("searxng backend ignores search_depth; request used default instance behavior")

    params = {
        "q": query,
        "format": "json",
    }
    if categories:
        params["categories"] = categories
    if engines:
        params["engines"] = engines
    if language:
        params["language"] = language
    if time_range and time_range != "week":
        params["time_range"] = time_range
    elif time_range == "week":
        warnings.append("searxng backend does not support time_range=week; omitted")

    search_url = f"{base_url.rstrip('/')}/search?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(
        search_url,
        headers={
            "Accept": "application/json",
            "User-Agent": USER_AGENT,
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            data = json.load(response)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"SearXNG request failed with HTTP {exc.code}: {body}") from exc
    except urllib.error.URLError as exc:
        raise SystemExit(f"SearXNG request failed: {exc}") from exc

    return normalize_searxng_response(
        data,
        query=query,
        max_results=max_results,
        time_range=time_range,
        search_url=search_url,
        warnings=warnings,
    )


__all__ = [
    "normalize_time_range",
    "resolve_backend",
    "search_searxng",
    "search_tavily",
    "to_json",
]
