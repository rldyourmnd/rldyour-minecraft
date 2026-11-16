#!/usr/bin/env python3
"""Install verified client artifacts without importing worlds or account stores."""
import fnmatch
import hashlib
import json
import pathlib
import re
import stat
import sys
import urllib.request
import uuid
import zipfile


def environment(path):
    values = {}
    for line in pathlib.Path(path).read_text().splitlines():
        if line and not line.startswith("#"):
            key, value = line.split("=", 1)
            values[key] = value.strip('"')
    return values


def safe_path(name):
    path = pathlib.PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or "\\" in name or ":" in name:
        raise ValueError("Unsafe archive path")
    if not path.parts or path.parts[0] not in ("mods", "config"):
        raise ValueError("Unexpected archive input")
    return path


def file_hash(path, algorithm="sha256"):
    with pathlib.Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def install(archive, expected, settings, policy, artifacts):
    root = pathlib.Path(settings["DATA_DIRECTORY"]).resolve()
    if not root.is_dir() or not root.is_mount():
        raise ValueError("The dedicated data filesystem must be mounted")
    if file_hash(archive) != expected:
        raise ValueError("Input bundle hash mismatch")
    marker = root / ".pack-receipt.json"
    if (root / "world").exists() and not marker.exists():
        raise ValueError("Existing world without installation receipt; preserved")
    with zipfile.ZipFile(archive) as bundle:
        records = json.loads(bundle.read("files.json"))
        names = [record["path"] for record in records]
        if len(names) != len(set(names)) or len(bundle.namelist()) != len(set(bundle.namelist())):
            raise ValueError("Duplicate input paths")
        if set(bundle.namelist()) != set(names) | {"files.json"}:
            raise ValueError("Bundle and file manifest differ")
        selected = []
        for record in records:
            relative = safe_path(record["path"])
            entry = bundle.getinfo(record["path"])
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise ValueError("Symlink archive entry")
            content = bundle.read(entry)
            if len(content) != record["bytes"] or hashlib.sha256(content).hexdigest() != record["sha256"]:
                raise ValueError("Input member hash mismatch: " + record["path"])
            excluded = relative.parts[0] == "mods" and any(
                fnmatch.fnmatch(relative.name, pattern) for pattern in policy["excludeMods"]
            )
            if not excluded:
                selected.append(record)
        if marker.exists():
            old = json.loads(marker.read_text())
            if old["archiveSha256"] != expected:
                raise ValueError("Different installed pack; preserved")
            for record in selected:
                if record["path"].startswith("mods/") and file_hash(root / record["path"]) != record["sha256"]:
                    raise ValueError("Installed mod drift: " + record["path"])
            return old
        for record in selected:
            target = root / record["path"]
            if not target.resolve().is_relative_to(root) or target.is_symlink():
                raise ValueError("Destination escapes data filesystem")
            if target.exists() and file_hash(target) != record["sha256"]:
                raise ValueError("Existing file differs; preserved: " + record["path"])
        for record in selected:
            target = root / record["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.exists():
                target.write_bytes(bundle.read(record["path"]))
            if file_hash(target) != record["sha256"]:
                raise ValueError("Installed member hash mismatch")
    operator = settings["OWNER_OPERATOR"]
    if not re.fullmatch(r"[A-Za-z0-9_]{3,16}", operator):
        raise ValueError("Invalid operator name")
    offline = uuid.UUID(bytes=hashlib.md5(("OfflinePlayer:" + operator).encode()).digest(), version=3)
    ops = root / "ops.json"
    operators = [{"uuid": str(offline), "name": operator, "level": 4, "bypassesPlayerLimit": False}]
    if ops.is_symlink() or (ops.exists() and json.loads(ops.read_text()) != operators):
        raise ValueError("Different operator data; preserved")
    if not ops.exists():
        ops.write_text(json.dumps(operators, indent=2) + "\n")
    package = root / ".packages/forge-installer.jar"
    package.parent.mkdir(exist_ok=True)
    forge = artifacts["forgeInstaller"]
    if not package.exists():
        part = package.with_suffix(".part")
        request = urllib.request.Request(forge["url"], headers={"User-Agent": "MinecraftServerInstaller/1.0"})
        with urllib.request.urlopen(request, timeout=60) as response, part.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
        if file_hash(part, "sha1") != forge["sha1"]:
            raise ValueError("Forge publisher hash mismatch")
        part.replace(package)
    if file_hash(package, "sha1") != forge["sha1"]:
        raise ValueError("Existing Forge installer differs")
    receipt = {"archiveSha256": expected,
               "modJars": sum(x["path"].startswith("mods/") and x["path"].endswith(".jar") for x in selected),
               "files": selected, "operatorUuid": str(offline)}
    marker.write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


if __name__ == "__main__":
    archive_path, digest, env_path, policy_path, artifacts_path = sys.argv[1:]
    result = install(archive_path, digest, environment(env_path),
                     json.loads(pathlib.Path(policy_path).read_text()),
                     json.loads(pathlib.Path(artifacts_path).read_text()))
    print(json.dumps({"modJars": result["modJars"], "files": len(result["files"]),
                      "archiveSha256": result["archiveSha256"]}))
