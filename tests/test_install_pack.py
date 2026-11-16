import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location("pack", pathlib.Path(__file__).parents[1] / "scripts/install_pack.py")
pack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pack)


class InputTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = pathlib.Path(self.temp.name)
        self.root = self.base / "data"
        self.root.mkdir()
        self.settings = {"DATA_DIRECTORY": str(self.root), "OWNER_OPERATOR": "TestOwner"}
        self.policy = {"excludeMods": ["Client.jar"]}
        self.forge = b"verified installer"
        self.artifacts = {"forgeInstaller": {"url": "https://invalid.example/unused",
                                            "sha1": hashlib.sha1(self.forge).hexdigest()}}

    def bundle(self, contents=None, corrupt=False):
        contents = contents or {"mods/Server.jar": b"server", "mods/Client.jar": b"client", "config/a.cfg": b"setting"}
        target = self.base / "input.zip"
        records = [{"path": name, "sha256": hashlib.sha256(value).hexdigest(), "bytes": len(value)}
                   for name, value in contents.items()]
        if corrupt:
            records[0]["sha256"] = "0" * 64
        with zipfile.ZipFile(target, "w") as archive:
            for name, value in contents.items():
                archive.writestr(name, value)
            archive.writestr("files.json", json.dumps(records))
        return target, pack.file_hash(target)

    def apply(self, archive, digest):
        with patch.object(pathlib.Path, "is_mount", return_value=True):
            return pack.install(archive, digest, self.settings, self.policy, self.artifacts)

    def test_install_and_rerun_preserve_generated_configuration(self):
        package = self.root / ".packages"
        package.mkdir()
        (package / "forge-installer.jar").write_bytes(self.forge)
        archive, digest = self.bundle()
        result = self.apply(archive, digest)
        self.assertEqual(result["modJars"], 1)
        self.assertFalse((self.root / "mods/Client.jar").exists())
        (self.root / "config/a.cfg").write_text("server-generated value")
        self.assertEqual(self.apply(archive, digest), result)
        self.assertEqual((self.root / "config/a.cfg").read_text(), "server-generated value")

    def test_archive_hash_rejection_writes_nothing(self):
        archive, _ = self.bundle()
        with self.assertRaisesRegex(ValueError, "bundle hash"):
            self.apply(archive, "0" * 64)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_corrupt_member_rejection_writes_nothing(self):
        archive, digest = self.bundle(corrupt=True)
        with self.assertRaisesRegex(ValueError, "member hash"):
            self.apply(archive, digest)
        self.assertEqual(list(self.root.iterdir()), [])

    def test_traversal_rejection_writes_nothing(self):
        archive, digest = self.bundle({"mods/../../escape.jar": b"bad"})
        with self.assertRaisesRegex(ValueError, "Unsafe archive"):
            self.apply(archive, digest)
        self.assertFalse((self.base / "escape.jar").exists())
        self.assertEqual(list(self.root.iterdir()), [])

    def test_symlink_destination_rejection_preserves_outside_data(self):
        outside = self.base / "outside"
        outside.mkdir()
        (self.root / "mods").symlink_to(outside, target_is_directory=True)
        archive, digest = self.bundle()
        with self.assertRaisesRegex(ValueError, "Destination escapes"):
            self.apply(archive, digest)
        self.assertEqual(list(outside.iterdir()), [])

    def test_unknown_world_is_preserved(self):
        world = self.root / "world"
        world.mkdir()
        (world / "level.dat").write_bytes(b"owner data")
        archive, digest = self.bundle()
        with self.assertRaisesRegex(ValueError, "Existing world"):
            self.apply(archive, digest)
        self.assertEqual((world / "level.dat").read_bytes(), b"owner data")
        self.assertEqual(list(self.root.iterdir()), [world])
