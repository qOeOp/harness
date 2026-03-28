from __future__ import annotations

import os
from pathlib import Path


def find_materialized_consumer_runtime_root(start_dir: str | Path | None = None) -> Path | None:
    current = Path(start_dir or os.getcwd()).resolve()
    search_roots = [current, *current.parents]

    for candidate in search_roots:
        if (candidate / ".harness" / "manifest.toml").is_file():
            return candidate

    return None


def runtime_support_root(start_dir: str | Path | None = None) -> Path | None:
    runtime_root = find_materialized_consumer_runtime_root(start_dir=start_dir)
    if runtime_root is None:
        return None
    return runtime_root / ".harness" / "runtime"


def research_support_root(start_dir: str | Path | None = None) -> Path | None:
    support_root = runtime_support_root(start_dir=start_dir)
    if support_root is None:
        return None
    return support_root / "research"


def default_research_support_dir(*parts: str, start_dir: str | Path | None = None) -> Path | None:
    root = research_support_root(start_dir=start_dir)
    if root is None:
        return None
    path = root
    for part in parts:
        path = path / part
    return path


__all__ = [
    "default_research_support_dir",
    "find_materialized_consumer_runtime_root",
    "research_support_root",
    "runtime_support_root",
]
