"""Run Flutter analysis from an ASCII path, working around SDK Unicode LSP framing.

Copies only source/configuration; preserves external dependency paths and makes
no changes to the real project or Flutter SDK. No dependency download is needed.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
from urllib.parse import urljoin


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flutter", default=shutil.which("flutter") or "flutter")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1] / "apps/mobile"
    package_config = source / ".dart_tool/package_config.json"
    if not package_config.exists():
        parser.error("Run flutter pub get in apps/mobile first")
    with tempfile.TemporaryDirectory(prefix="trustmarket-mobile-analysis-", dir="/tmp") as directory:
        target = Path(directory)
        sources = [name for name in ("lib", "test", "integration_test") if (source / name).is_dir()]
        for name in sources:
            shutil.copytree(source / name, target / name)
        for name in ("pubspec.yaml", "pubspec.lock", "analysis_options.yaml"):
            shutil.copy2(source / name, target / name)
        config = json.loads(package_config.read_text())
        for package in config["packages"]:
            package["rootUri"] = target.as_uri() + "/" if package["name"] == "trustmarket_mobile" else urljoin(package_config.parent.as_uri() + "/", package["rootUri"])
        (target / ".dart_tool").mkdir()
        (target / ".dart_tool/package_config.json").write_text(json.dumps(config))
        return subprocess.run([args.flutter, "analyze", "--no-pub", *sources], cwd=target).returncode


if __name__ == "__main__":
    raise SystemExit(main())
