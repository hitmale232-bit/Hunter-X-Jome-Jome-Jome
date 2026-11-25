"""Check 1: every manifest file on disk == exported bytes.
Check 2: `rojo build` output has exactly the synced scripts, same names/classes/Disabled/source."""
import json
import os
import sys
import xml.etree.ElementTree as ET

export = json.load(open(sys.argv[1], encoding="utf-8"))
root = sys.argv[2]
built = sys.argv[3]
manifest = json.load(open(os.path.join(root, "docs", "script-manifest.json"), encoding="utf-8"))
by_path = {".".join(x["n"] for x in it["path"]): it for it in export}

# 1. disk bytes
bad = 0
seen_paths = {}
for m in manifest:
    data = open(os.path.join(root, m["file"]), "rb").read()
    rp = m["robloxPath"]
    seen_paths[rp] = seen_paths.get(rp, 0) + 1
    # duplicates share a robloxPath: compare against any export item with the same bytes
    cands = [it for it in export if ".".join(x["n"] for x in it["path"]) == rp]
    if not any(it["source"].encode("utf-8", errors="surrogateescape") == data for it in cands):
        bad += 1
        print("DISK MISMATCH", m["file"])
print("check 1: %d files, %d mismatches, export items %d" % (len(manifest), bad, len(export)))

# 2. rojo build
tree = ET.parse(built).getroot()
SCRIPTS = {"Script", "LocalScript", "ModuleScript"}
found = {}


def walk(el, path):
    for item in el.findall("Item"):
        props = item.find("Properties")
        name = None
        src = None
        disabled = False
        for p in props:
            if p.get("name") == "Name":
                name = p.text or ""
            elif p.get("name") == "Source":
                src = p.text or ""
            elif p.get("name") == "Disabled":
                disabled = (p.text == "true")
        cls = item.get("class")
        here = path + [name]
        if cls in SCRIPTS:
            key = ".".join(here)
            if key in found:
                print("DUPLICATE IN BUILD", key)
            found[key] = (cls, src, disabled)
        walk(item, here)


walk(tree, [])
synced = [m for m in manifest if m["synced"]]
norm = lambda s: s.replace("\r\n", "\n").replace("\r", "\n")  # noqa: E731 (XML parsers fold CR)
errs = 0
for m in synced:
    it = by_path[m["robloxPath"]]
    got = found.pop(m["robloxPath"], None)
    if got is None:
        errs += 1
        print("MISSING FROM BUILD", m["robloxPath"])
        continue
    cls, src, disabled = got
    if cls != it["class"] or disabled != it["disabled"] or norm(src) != norm(it["source"]):
        errs += 1
        print("BUILD MISMATCH", m["robloxPath"], cls, it["class"], disabled, it["disabled"])
for extra in found:
    errs += 1
    print("EXTRA IN BUILD", extra)
print("check 2: %d synced scripts compared, %d problems" % (len(synced), errs))
