#!/usr/bin/env python3
"""Validate the TOC and produce an addon-only, directly installable ZIP."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import re

root = Path(__file__).resolve().parents[1]
addon = root / "Just20Minutes"
toc = addon / "Just20Minutes.toc"
data = toc.read_text(encoding="utf-8")
assert re.search(r"^## Interface: 16001$", data, re.M)
assert re.search(r"^## Version: 1.0.0$", data, re.M)
assert "## SavedVariables: Just20MinutesDB" in data
includes = [s.strip().replace("\\", "/") for s in data.splitlines()
            if s.strip() and not s.startswith("#")]
assert includes and len(includes) == len(set(includes))
for item in includes:
    assert (addon / item).is_file(), f"Missing {item}"
    assert item.endswith(".lua"), f"Invalid TOC entry {item}"
dist = root / "dist"
dist.mkdir(exist_ok=True)
target = dist / "Just20Minutes-v1.0.0.zip"
with ZipFile(target, "w", ZIP_DEFLATED) as z:
    z.write(toc, "Just20Minutes/Just20Minutes.toc")
    for item in includes:
        z.write(addon / item, "Just20Minutes/" + item)
with ZipFile(target) as z:
    names = z.namelist()
    assert len(names) == len(includes) + 1
    assert all(n.startswith("Just20Minutes/") and ".." not in n for n in names)
    assert z.testzip() is None
print("Validated and packaged:", target, len(names), "files")
