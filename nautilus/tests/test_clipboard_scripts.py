#!/usr/bin/env python3
"""Command-level tests for the Nautilus clipboard scripts."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
import urllib.parse
from pathlib import Path

SCRIPTS = Path(__file__).parents[1] / ".local/share/nautilus/scripts"


class NautilusClipboardTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "log"
        self.payload = self.root / "payload"
        self.destination = self.root / "folder with spaces"
        self.destination.mkdir()

        self._tool("notify-send", "#!/bin/sh\nexit 0\n")
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "TEST_LOG": str(self.log),
            "TEST_PAYLOAD": str(self.payload),
        }

    def _tool(self, name: str, body: str) -> None:
        path = self.bin / name
        path.write_text(body)
        path.chmod(0o755)

    def test_copy_converts_jpeg_and_publishes_png_through_dms(self) -> None:
        image = self.root / "photo.jpg"
        image.write_bytes(b"jpeg bytes")
        self._tool("file", "#!/bin/sh\nprintf image/jpeg\n")
        self._tool("magick", '#!/bin/sh\nprintf converted:; cat "$1"\n')
        self._tool(
            "dms",
            '#!/bin/sh\nprintf "%s\\n" "$*" >"$TEST_LOG"\ncat >"$TEST_PAYLOAD"\n',
        )

        result = subprocess.run(
            [SCRIPTS / "Copy image contents", image],
            env=self.env,
            capture_output=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text(), "clipboard copy --type image/png\n")
        self.assertEqual(self.payload.read_bytes(), b"converted:jpeg bytes")

    def test_paste_converts_chrome_jpeg_offer_to_png_file(self) -> None:
        self._tool(
            "wl-paste",
            """#!/bin/sh
if [ "$1" = --list-types ]; then
  printf 'text/html\\nimage/jpeg\\n'
else
  printf 'jpeg clipboard bytes'
fi
""",
        )
        self._tool("magick", "#!/bin/sh\nprintf 'png:%s' \"$(cat)\"\n")
        self._tool("date", "#!/bin/sh\nprintf 2026-08-27_12-34-56\n")
        uri = "file://" + urllib.parse.quote(str(self.destination))

        result = subprocess.run(
            [SCRIPTS / "Paste clipboard image"],
            env=self.env | {"NAUTILUS_SCRIPT_CURRENT_URI": uri},
            capture_output=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        output = self.destination / "clipboard-image-2026-08-27_12-34-56.png"
        self.assertEqual(output.read_bytes(), b"png:jpeg clipboard bytes")

    def test_paste_prefers_png_when_chrome_offers_multiple_images(self) -> None:
        self._tool(
            "wl-paste",
            """#!/bin/sh
if [ "$1" = --list-types ]; then
  printf 'image/jpeg\\nimage/png\\ntext/html\\n'
else
  printf '%s\\n' "$*" > "$TEST_LOG"
  printf 'png clipboard bytes'
fi
""",
        )
        self._tool("magick", "#!/bin/sh\nexit 99\n")
        self._tool("date", "#!/bin/sh\nprintf 2026-08-27_12-34-56\n")
        uri = "file://" + urllib.parse.quote(str(self.destination))

        result = subprocess.run(
            [SCRIPTS / "Paste clipboard image"],
            env=self.env | {"NAUTILUS_SCRIPT_CURRENT_URI": uri},
            capture_output=True,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.log.read_text(), "--type image/png\n")
        output = self.destination / "clipboard-image-2026-08-27_12-34-56.png"
        self.assertEqual(output.read_bytes(), b"png clipboard bytes")


if __name__ == "__main__":
    unittest.main()
