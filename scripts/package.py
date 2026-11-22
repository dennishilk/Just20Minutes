#!/usr/bin/env python3
"""Validate version/TOC consistency and create a deterministic installable ZIP."""
from pathlib import Path, PurePosixPath
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import re

root = Path(__file__).resolve().parents[1]
addon = root / "Just20Minutes"
toc = addon / "Just20Minutes.toc"
data = toc.read_text(encoding="utf-8")
assert re.search(r"^## Interface: 16001$", data, re.M)
match = re.search(r"^## Version: (\d+\.\d+\.\d+)$", data, re.M)
assert match, "TOC needs a semantic version"
version = match.group(1)
assert f'J.name, J.version = addonName, "{version}"' in (addon / "Core.lua").read_text()
assert "## SavedVariables: Just20MinutesDB" in data
assert "## X-License: MIT" in data
for readme in ("README.md", "README.de.md"):
    text = (root / readme).read_text()
    assert f"Release-v{version}-" in text and f"Just20Minutes-v{version}.zip" in text
assert f"## [{version}]" in (root / "CHANGELOG.md").read_text()
includes = [s.strip().replace("\\", "/") for s in data.splitlines()
            if s.strip() and not s.startswith("#")]
assert includes and len(includes) == len(set(includes))
for item in includes:
    path = PurePosixPath(item)
    assert not path.is_absolute() and ".." not in path.parts, f"Unsafe TOC entry: {item}"
    assert (addon / item).is_file(), f"Missing {item}"
    assert item.endswith(".lua"), f"Invalid TOC entry {item}"
assert set(includes) == {p.relative_to(addon).as_posix() for p in addon.rglob("*.lua")}
assert includes[:2] == ["Locales/enUS.lua", "Locales/deDE.lua"]
assert includes.index("Core.lua") < includes.index("Database.lua") < includes.index("Timer.lua")
files = [(toc, "Just20Minutes/Just20Minutes.toc")]
files += [(addon / item, "Just20Minutes/" + item) for item in includes]
# MIT's copyright and permission notice travel with every distribution.
files.append((root / "LICENSE", "Just20Minutes/LICENSE"))
dist = root / "dist"
dist.mkdir(exist_ok=True)
target = dist / f"Just20Minutes-v{version}.zip"
with ZipFile(target, "w", ZIP_DEFLATED) as z:
    for source, name in files:
        info = ZipInfo(name, date_time=(2026, 11, 22, 0, 0, 0))
        info.compress_type = ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, source.read_bytes())
with ZipFile(target) as z:
    names = z.namelist()
    assert len(names) == len(includes) + 2
    assert all(n.startswith("Just20Minutes/") and ".." not in n for n in names)
    assert z.read("Just20Minutes/LICENSE") == (root / "LICENSE").read_bytes()
    assert z.testzip() is None
print("Validated and packaged:", target, len(names), "files")
