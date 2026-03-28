from __future__ import annotations

import os
import shutil
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

sys.dont_write_bytecode = True


LOCAL_BROWSER_ROOTS = {
    "darwin": {
        "chrome": Path("~/Library/Application Support/Google/Chrome").expanduser(),
        "edge": Path("~/Library/Application Support/Microsoft Edge").expanduser(),
        "chromium": Path("~/Library/Application Support/Chromium").expanduser(),
    },
    "linux": {
        "chrome": Path("~/.config/google-chrome").expanduser(),
        "edge": Path("~/.config/microsoft-edge").expanduser(),
        "chromium": Path("~/.config/chromium").expanduser(),
    },
    "win32": {
        "chrome": Path(os.environ.get("LOCALAPPDATA", "")) / "Google/Chrome/User Data",
        "edge": Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft/Edge/User Data",
        "chromium": Path(os.environ.get("LOCALAPPDATA", "")) / "Chromium/User Data",
    },
}

PROFILE_IGNORE_PATTERNS = (
    "Singleton*",
    "Lock*",
    "*.tmp",
    "Temp",
    "Cache",
    "Code Cache",
    "GPUCache",
    "ShaderCache",
    "GrShaderCache",
    "GraphiteDawnCache",
    "Crashpad",
    "Safe Browsing",
)


def platform_key() -> str:
    if sys.platform.startswith("darwin"):
        return "darwin"
    if sys.platform.startswith("linux"):
        return "linux"
    if sys.platform.startswith("win32"):
        return "win32"
    return sys.platform


def browser_root(browser_name: str) -> Path:
    roots = LOCAL_BROWSER_ROOTS.get(platform_key(), {})
    if browser_name not in roots:
        raise SystemExit(f"unsupported local browser '{browser_name}' on platform '{platform_key()}'")
    return roots[browser_name]


def discover_local_profiles() -> list[dict]:
    discovered: list[dict] = []
    roots = LOCAL_BROWSER_ROOTS.get(platform_key(), {})
    for browser_name, root in roots.items():
        profiles: list[str] = []
        if root.is_dir():
            for child in sorted(root.iterdir()):
                if child.is_dir() and (child.name == "Default" or child.name.startswith("Profile ")):
                    profiles.append(child.name)
        discovered.append(
            {
                "browser": browser_name,
                "root": str(root),
                "exists": root.is_dir(),
                "profiles": profiles,
            }
        )
    return discovered


def ensure_local_profile(browser_name: str, profile_directory: str) -> tuple[Path, Path]:
    root = browser_root(browser_name)
    if not root.is_dir():
        raise SystemExit(f"local browser root not found: {root}")

    profile_path = root / profile_directory
    if not profile_path.is_dir():
        raise SystemExit(f"local browser profile not found: {profile_path}")

    return root, profile_path


def snapshot_local_profile(browser_name: str, profile_directory: str) -> tuple[tempfile.TemporaryDirectory[str], Path]:
    source_root, source_profile = ensure_local_profile(browser_name, profile_directory)
    temp_dir = tempfile.TemporaryDirectory(prefix=f"harness-{browser_name}-{profile_directory.lower()}-")
    snapshot_root = Path(temp_dir.name)

    for name in ("Local State", "First Run", "Last Version"):
        source_path = source_root / name
        if source_path.is_file():
            shutil.copy2(source_path, snapshot_root / name)

    shutil.copytree(
        source_profile,
        snapshot_root / profile_directory,
        ignore=shutil.ignore_patterns(*PROFILE_IGNORE_PATTERNS),
        dirs_exist_ok=True,
    )

    return temp_dir, snapshot_root


@contextmanager
def local_profile_snapshot_context(browser_name: str, profile_directory: str):
    temp_dir, snapshot_root = snapshot_local_profile(browser_name, profile_directory)
    try:
        yield snapshot_root
    finally:
        temp_dir.cleanup()
