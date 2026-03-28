from __future__ import annotations

import os
import shutil
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

from lib_runtime_paths import default_research_support_dir

sys.dont_write_bytecode = True


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


def user_home_dir() -> Path:
    explicit_home = os.environ.get("HARNESS_RESEARCH_LOCAL_BROWSER_HOME", "").strip()
    if explicit_home:
        return Path(explicit_home).expanduser()

    if not sys.platform.startswith("win32"):
        try:
            import pwd

            return Path(pwd.getpwuid(os.getuid()).pw_dir)
        except Exception:
            pass

    return Path.home()


def local_browser_roots() -> dict[str, dict[str, Path]]:
    home_dir = user_home_dir()
    local_appdata = os.environ.get("LOCALAPPDATA", "")
    return {
        "darwin": {
            "chrome": home_dir / "Library/Application Support/Google/Chrome",
            "edge": home_dir / "Library/Application Support/Microsoft Edge",
            "chromium": home_dir / "Library/Application Support/Chromium",
        },
        "linux": {
            "chrome": home_dir / ".config/google-chrome",
            "edge": home_dir / ".config/microsoft-edge",
            "chromium": home_dir / ".config/chromium",
        },
        "win32": {
            "chrome": Path(local_appdata) / "Google/Chrome/User Data",
            "edge": Path(local_appdata) / "Microsoft/Edge/User Data",
            "chromium": Path(local_appdata) / "Chromium/User Data",
        },
    }


def browser_root(browser_name: str) -> Path:
    roots = local_browser_roots().get(platform_key(), {})
    if browser_name not in roots:
        raise SystemExit(f"unsupported local browser '{browser_name}' on platform '{platform_key()}'")
    return roots[browser_name]


def discover_local_profiles() -> list[dict]:
    discovered: list[dict] = []
    roots = local_browser_roots().get(platform_key(), {})
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
    snapshot_dir = os.environ.get("HARNESS_RESEARCH_BROWSER_SNAPSHOT_DIR", "").strip()
    snapshot_root_parent = Path(snapshot_dir).expanduser() if snapshot_dir else default_research_support_dir("browser-snapshots")
    temp_dir_kwargs = {"prefix": f"harness-{browser_name}-{profile_directory.lower()}-"}
    if snapshot_root_parent is not None:
        snapshot_root_parent.mkdir(parents=True, exist_ok=True)
        temp_dir_kwargs["dir"] = str(snapshot_root_parent)
    temp_dir = tempfile.TemporaryDirectory(**temp_dir_kwargs)
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
