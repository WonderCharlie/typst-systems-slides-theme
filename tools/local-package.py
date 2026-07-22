#!/usr/bin/env python3
"""Build, install, verify, and remove the repository's Typst @local package."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid

try:
    import tomllib
except ModuleNotFoundError:
    print("local-package: Python 3.11 or newer is required (missing tomllib)", file=sys.stderr)
    raise SystemExit(2)


REPOSITORY = Path(__file__).resolve().parent.parent
MANIFEST = REPOSITORY / "typst.toml"
ALLOWLIST = REPOSITORY / "packaging" / "install-files.txt"
MARKER_NAME = ".systems-slides-template-install.json"
MARKER_SCHEMA = 1
THEME_FONT_DIR = Path("themes/systems-slides-template/assets/fonts")
TEMPLATE_FONT_DIR = Path("template/fonts")


class PackageError(RuntimeError):
    """An expected, user-facing package operation failure."""


def read_package_identity() -> tuple[str, str]:
    """Read and conservatively validate the package name and semantic version."""
    with MANIFEST.open("rb") as stream:
        data = tomllib.load(stream)
    package = data.get("package", {})
    name = package.get("name")
    version = package.get("version")
    if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name):
        raise PackageError("typst.toml contains an unsafe or missing package name")
    if not isinstance(version, str) or not re.fullmatch(
        r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?", version
    ):
        raise PackageError("typst.toml contains an unsafe or missing semantic version")
    return name, version


def read_allowlist() -> tuple[Path, ...]:
    """Return normalized repository-relative entries from the installation allowlist."""
    if not ALLOWLIST.is_file():
        raise PackageError(f"installation allowlist is missing: {ALLOWLIST}")
    entries: list[Path] = []
    for line_number, raw in enumerate(ALLOWLIST.read_text(encoding="utf-8").splitlines(), 1):
        value = raw.strip()
        if not value or value.startswith("#"):
            continue
        candidate = Path(value)
        if candidate.is_absolute() or ".." in candidate.parts or candidate == Path("."):
            raise PackageError(f"unsafe allowlist entry on line {line_number}: {value}")
        source = REPOSITORY / candidate
        if not source.exists():
            raise PackageError(f"allowlisted source does not exist: {candidate}")
        entries.append(candidate)
    if not entries:
        raise PackageError("installation allowlist is empty")
    return tuple(entries)


def reject_symlinks(path: Path, label: str) -> None:
    """Reject a symlink itself or anywhere below a directory tree."""
    if path.is_symlink():
        raise PackageError(f"{label} must not be a symbolic link: {path}")
    if path.is_dir():
        for child in path.rglob("*"):
            if child.is_symlink():
                raise PackageError(f"{label} contains a symbolic link: {child}")


def content_digest(root: Path) -> tuple[str, int]:
    """Hash every installed file except the generated ownership marker."""
    digest = hashlib.sha256()
    count = 0
    for path in sorted(root.rglob("*"), key=lambda item: item.as_posix()):
        if path.is_symlink():
            raise PackageError(f"package snapshot contains a symbolic link: {path}")
        if not path.is_file() or path == root / MARKER_NAME:
            continue
        relative = path.relative_to(root).as_posix().encode("utf-8")
        digest.update(len(relative).to_bytes(8, "big"))
        digest.update(relative)
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(chunk)
        count += 1
    return digest.hexdigest(), count


def discover_package_root() -> Path:
    """Ask the active Typst executable for its user package path."""
    typst = os.environ.get("TYPST", "typst")
    clean_environment = os.environ.copy()
    clean_environment.pop("TYPST_PACKAGE_PATH", None)
    try:
        result = subprocess.run(
            [typst, "info", "--format", "json"],
            check=True,
            text=True,
            capture_output=True,
            env=clean_environment,
        )
        info = json.loads(result.stdout)
        value = info["packages"]["package-path"]
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as exc:
        raise PackageError(f"cannot discover the Typst package path with {typst!r}: {exc}") from exc
    if not isinstance(value, str) or not value:
        raise PackageError("Typst reported an empty package path")
    return Path(value).expanduser().resolve(strict=False)


def normalize_package_root(value: str | None, *, development_default: bool) -> Path:
    """Resolve an explicit root or select the repository/system default."""
    if value:
        original = Path(value).expanduser()
        if original.is_symlink():
            raise PackageError(f"package root must not be a symbolic link: {original}")
        root = original.resolve(strict=False)
    elif development_default:
        root = (REPOSITORY / "build" / "packages").resolve(strict=False)
    else:
        root = discover_package_root()
    if root == Path("/") or root == Path.home().resolve():
        raise PackageError(f"refusing an unsafe broad package root: {root}")
    if root.exists() and not root.is_dir():
        raise PackageError(f"package root is not a directory: {root}")
    return root


def package_target(package_root: Path, name: str, version: str) -> Path:
    """Construct the exact target and reject symlinked namespace ancestors."""
    local_root = package_root / "local"
    package_parent = local_root / name
    for candidate in (local_root, package_parent):
        if candidate.is_symlink():
            raise PackageError(f"package namespace ancestor must not be a symbolic link: {candidate}")
        if candidate.exists() and not candidate.is_dir():
            raise PackageError(f"package namespace ancestor is not a directory: {candidate}")
    if package_parent.resolve(strict=False) != package_parent:
        raise PackageError(f"package namespace escapes through a symbolic link: {package_parent}")
    target = package_parent / version
    if target.parent.parent.parent != package_root:
        raise PackageError(f"resolved package target escaped its root: {target}")
    return target


def marker_payload(name: str, version: str, digest: str, files: int) -> dict[str, object]:
    """Create deterministic ownership metadata for an installed snapshot."""
    return {
        "schema": MARKER_SCHEMA,
        "name": name,
        "version": version,
        "content_sha256": digest,
        "file_count": files,
    }


def write_marker(root: Path, payload: dict[str, object]) -> None:
    """Write the deterministic package ownership marker."""
    (root / MARKER_NAME).write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def read_marker(target: Path, name: str, version: str) -> dict[str, object]:
    """Validate that an existing exact target is owned by this installer."""
    if target.is_symlink():
        raise PackageError(f"installed package target must not be a symbolic link: {target}")
    if not target.is_dir():
        raise PackageError(f"installed package target is not a directory: {target}")
    marker_path = target / MARKER_NAME
    try:
        marker = json.loads(marker_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise PackageError(f"target is not an installer-owned package: {target}") from exc
    if (
        marker.get("schema") != MARKER_SCHEMA
        or marker.get("name") != name
        or marker.get("version") != version
    ):
        raise PackageError(f"package marker identity does not match {name}:{version}: {target}")
    return marker


def copy_allowlisted_contents(destination_root: Path) -> None:
    """Copy only the declared physical package inputs into an empty directory."""
    for relative in read_allowlist():
        source = REPOSITORY / relative
        reject_symlinks(source, "allowlisted source")
        destination = destination_root / relative
        if source.is_dir():
            shutil.copytree(source, destination, copy_function=shutil.copy2)
        else:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

    # Theme fonts are owned by the Theme. A physical copy is materialized inside
    # the installed starter only because Typst and Tinymist discover fonts via
    # font paths rather than by scanning package resources automatically.
    theme_fonts = destination_root / THEME_FONT_DIR
    starter_fonts = destination_root / TEMPLATE_FONT_DIR
    if not theme_fonts.is_dir():
        raise PackageError(f"Theme font source is missing from the snapshot: {THEME_FONT_DIR}")
    if starter_fonts.exists() or starter_fonts.is_symlink():
        raise PackageError(f"starter font deployment target already exists: {TEMPLATE_FONT_DIR}")
    starter_fonts.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(theme_fonts, starter_fonts, copy_function=shutil.copy2)


def source_snapshot_digest() -> tuple[str, int]:
    """Compute the digest of the snapshot that the current checkout would install."""
    with tempfile.TemporaryDirectory(prefix="systems-slides-template-source-snapshot.") as temporary:
        root = Path(temporary)
        copy_allowlisted_contents(root)
        return content_digest(root)


def build_snapshot(target_parent: Path, name: str, version: str) -> Path:
    """Create a complete physical snapshot beside its eventual target."""
    target_parent.mkdir(parents=True, exist_ok=True)
    if target_parent.is_symlink() or not target_parent.is_dir():
        raise PackageError(f"package target parent is not a physical directory: {target_parent}")
    if target_parent.resolve(strict=False) != target_parent:
        raise PackageError(f"package target parent escapes through a symlink: {target_parent}")
    stage = Path(tempfile.mkdtemp(prefix=f".{version}.stage-", dir=str(target_parent)))
    try:
        copy_allowlisted_contents(stage)
        digest, files = content_digest(stage)
        write_marker(stage, marker_payload(name, version, digest, files))
        return stage
    except Exception:
        shutil.rmtree(stage, ignore_errors=True)
        raise


def snapshot_is_current(target: Path, marker: dict[str, object]) -> bool:
    """Return whether installed contents still match their recorded digest."""
    actual_digest, actual_files = content_digest(target)
    return (
        marker.get("content_sha256") == actual_digest
        and marker.get("file_count") == actual_files
    )


def remove_internal_stage(path: Path, expected_parent: Path, prefix: str) -> None:
    """Remove only a transaction directory created beside the exact target."""
    if path.parent != expected_parent or not path.name.startswith(prefix) or path.is_symlink():
        raise PackageError(f"refusing to remove an unexpected transaction path: {path}")
    if path.exists():
        shutil.rmtree(path)


def recover_replacement(target: Path, name: str, version: str) -> None:
    """Recover either side of an interrupted target/backup directory swap."""
    backups = sorted(target.parent.glob(f".{version}.backup-*"))
    if len(backups) > 1:
        raise PackageError(f"multiple interrupted replacement backups require review: {target.parent}")
    if not backups:
        return
    backup = backups[0]
    read_marker(backup, name, version)
    if target.exists() or target.is_symlink():
        target_marker = read_marker(target, name, version)
        if not snapshot_is_current(target, target_marker):
            raise PackageError(
                f"cannot recover replacement because the active target is modified: {target}"
            )
        remove_internal_stage(backup, target.parent, f".{version}.backup-")
    else:
        backup.rename(target)


@contextmanager
def package_transaction(target: Path, name: str, version: str):
    """Serialize mutations and repair a crash between the two replacement renames."""
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.parent.is_symlink() or target.parent.resolve(strict=False) != target.parent:
        raise PackageError(f"package transaction parent is not physical: {target.parent}")
    flags = os.O_RDONLY
    if hasattr(os, "O_DIRECTORY"):
        flags |= os.O_DIRECTORY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(target.parent, flags)
    try:
        if not stat.S_ISDIR(os.fstat(descriptor).st_mode):
            raise PackageError(f"package transaction parent is not a directory: {target.parent}")
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        legacy_lock = target.parent / f".{version}.install.lock"
        if legacy_lock.exists() or legacy_lock.is_symlink():
            if legacy_lock.is_symlink() or not legacy_lock.is_file() or legacy_lock.stat().st_size:
                raise PackageError(f"unexpected legacy transaction lock: {legacy_lock}")
            legacy_lock.unlink()
        recover_replacement(target, name, version)
        try:
            yield
        finally:
            fcntl.flock(descriptor, fcntl.LOCK_UN)
    finally:
        os.close(descriptor)


def place_snapshot(package_root: Path, *, replace: bool) -> Path:
    """Install a new snapshot, idempotently reuse it, or explicitly replace it."""
    name, version = read_package_identity()
    target = package_target(package_root, name, version)
    with package_transaction(target, name, version):
        stage = build_snapshot(target.parent, name, version)
        try:
            new_marker = read_marker(stage, name, version)
            if not target.exists() and not target.is_symlink():
                stage.rename(target)
                print(f"installed @local/{name}:{version} -> {target}")
                return target

            current_marker = read_marker(target, name, version)
            try:
                current_ok = snapshot_is_current(target, current_marker)
            except PackageError:
                current_ok = False
            same = current_ok and (
                current_marker.get("content_sha256") == new_marker.get("content_sha256")
                and current_marker.get("file_count") == new_marker.get("file_count")
            )
            if same:
                remove_internal_stage(stage, target.parent, f".{version}.stage-")
                print(f"already installed @local/{name}:{version} -> {target}")
                return target
            if not replace:
                state = "modified" if not current_ok else "different"
                raise PackageError(
                    f"refusing to overwrite {state} content for @local/{name}:{version}; "
                    "use the explicit reinstall command"
                )

            backup = target.with_name(f".{version}.backup-{uuid.uuid4().hex}")
            if backup.exists() or backup.is_symlink():
                raise PackageError(f"unexpected replacement backup already exists: {backup}")
            target.rename(backup)
            try:
                stage.rename(target)
            except Exception:
                backup.rename(target)
                raise
            remove_internal_stage(backup, target.parent, f".{version}.backup-")
            print(f"reinstalled @local/{name}:{version} -> {target}")
            return target
        finally:
            if stage.exists():
                remove_internal_stage(stage, target.parent, f".{version}.stage-")


def check_install(package_root: Path) -> Path:
    """Validate ownership, integrity, and freshness against the current checkout."""
    name, version = read_package_identity()
    target = package_target(package_root, name, version)
    backups = sorted(target.parent.glob(f".{version}.backup-*")) if target.parent.exists() else []
    if backups:
        raise PackageError(
            f"an interrupted replacement requires the explicit reinstall command: {backups[0]}"
        )
    marker = read_marker(target, name, version)
    if not snapshot_is_current(target, marker):
        raise PackageError(f"installed package content does not match its marker: {target}")
    expected_digest, expected_files = source_snapshot_digest()
    if (
        marker.get("content_sha256") != expected_digest
        or marker.get("file_count") != expected_files
    ):
        raise PackageError(
            f"installed package is valid but stale relative to the current checkout: {target}; "
            "run install for a new version or the explicit reinstall command"
        )
    print(f"verified @local/{name}:{version} -> {target}")
    return target


def uninstall(package_root: Path) -> None:
    """Remove only the exact marker-owned version directory, never its parents."""
    name, version = read_package_identity()
    target = package_target(package_root, name, version)
    with package_transaction(target, name, version):
        marker = read_marker(target, name, version)
        if not snapshot_is_current(target, marker):
            raise PackageError(
                f"refusing to uninstall modified package content: {target}; "
                "run the explicit reinstall command first"
            )
        if target.parent.parent.parent != package_root or target.name != version:
            raise PackageError(f"refusing to uninstall an unexpected target: {target}")
        shutil.rmtree(target)
    print(f"uninstalled @local/{name}:{version} -> {target}")


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line interface shared by Make and isolated tests."""
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    for command in ("package", "install", "reinstall", "path", "check", "uninstall"):
        subparser = subparsers.add_parser(command)
        subparser.add_argument(
            "--package-root",
            help="override the Typst package root (the parent of local/)",
        )
        if command in ("package", "install"):
            subparser.add_argument(
                "--replace",
                action="store_true",
                help="replace a marker-owned different snapshot",
            )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Execute one safe local package lifecycle operation."""
    args = build_parser().parse_args(argv)
    development_default = args.command == "package"
    root = normalize_package_root(args.package_root, development_default=development_default)
    name, version = read_package_identity()
    if args.command == "path":
        print(f"path: {package_target(root, name, version)}")
        print(f"package: @local/{name}:{version}")
    elif args.command in ("package", "install"):
        place_snapshot(root, replace=args.replace)
    elif args.command == "reinstall":
        place_snapshot(root, replace=True)
    elif args.command == "check":
        check_install(root)
    elif args.command == "uninstall":
        uninstall(root)
    else:  # pragma: no cover - argparse guarantees the command set.
        raise PackageError(f"unsupported command: {args.command}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PackageError as error:
        print(f"local-package: {error}", file=sys.stderr)
        raise SystemExit(2)
