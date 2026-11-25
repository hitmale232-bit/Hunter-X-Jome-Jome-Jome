"""Write the exported scripts as a Rojo tree (synced services) + a read-only snapshot (Workspace/ServerStorage).

Rules (see the repo README):
- Script -> Name.server.luau, LocalScript -> Name.client.luau, ModuleScript -> Name.luau
- a script with ANY children -> Name/init.*.luau + init.meta.json {ignoreUnknownInstances: true}
  so Rojo never deletes the Animations / Parts / Frames that live under it in Studio
- every folder/GUI directory gets init.meta.json {ignoreUnknownInstances: true} (+ className for GUIs)
- Disabled scripts carry {"properties": {"Disabled": true}}
- names Windows can't store (":" etc.) -> nested .project.json with the real name, source in src/_renamed/
- source bytes are written exactly as Studio had them (no line-ending changes)
"""
import collections
import json
import os
import re
import sys

items = json.load(open(sys.argv[1], encoding="utf-8"))
ROOT = sys.argv[2]
SYNCED = {"ServerScriptService", "ReplicatedStorage", "ReplicatedFirst", "StarterPlayer", "StarterGui"}
SNAPSHOT = {"Workspace", "ServerStorage"}
SCRIPT_CLASSES = ("Script", "LocalScript", "ModuleScript")
GUI_CLASSES = {"ScreenGui", "SurfaceGui", "BillboardGui"}
PROJECT_NODES = {"ServerScriptService", "ReplicatedStorage", "ReplicatedFirst", "StarterPlayer", "StarterGui",
                 "StarterPlayerScripts", "StarterCharacterScripts", "Workspace", "ServerStorage"}
BAD = re.compile(r'[<>:"/\\|?*\x00-\x1f%]')
RESERVED = {"con", "prn", "aux", "nul"} | {"com%d" % i for i in range(1, 10)} | {"lpt%d" % i for i in range(1, 10)}

written = set()  # lowercased paths, to catch Windows case collisions
stats = collections.Counter()


def safe(name):
    """Encode a Roblox name as a Windows-safe file name (only used where it differs)."""
    if name == "":
        return "(empty name)"
    out = BAD.sub(lambda m: "%%%02X" % ord(m.group(0)), name)
    if out.startswith(" "):
        out = "%20" + out[1:]
    if out.endswith(" ") or out.endswith("."):
        out = out[:-1] + "%%%02X" % ord(out[-1])
    return out


def needs_rename(name):
    return (
        safe(name) != name
        or name.lower() in RESERVED
        or name.lower() == "init"
        or re.search(r"\.(server|client|meta|model|project)$", name, re.I) is not None
    )


def put(path, data, mode="wb"):
    key = os.path.normcase(os.path.abspath(path))
    if key in written:
        sys.exit("COLLISION: " + path)
    written.add(key)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, mode) as f:
        f.write(data)


def put_json(path, obj):
    put(path, (json.dumps(obj, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))


def suffix(cls):
    return {"Script": ".server.luau", "LocalScript": ".client.luau", "ModuleScript": ".luau"}[cls]


def raw(it):
    return it["source"].encode("utf-8", errors="surrogateescape")


# Which paths have script descendants / children at all (by name path).
key_of = lambda p: tuple(x["n"] for x in p)  # noqa: E731
has_children = set()
for it in items:
    p = it["path"]
    for d in range(1, len(p)):
        has_children.add(key_of(p[:d]))
    ch = it["children"] if isinstance(it["children"], dict) else {}
    if ch:
        has_children.add(key_of(p))

# Duplicate full name-paths (two Models called "Model" each holding "Script", etc.).
dupes = collections.Counter(key_of(it["path"]) for it in items)
dup_seen = collections.Counter()

dir_meta_done = set()

# A synced folder holding two same-named scripts, or a name Windows can't store, can't be synced safely:
# Rojo would pair the wrong twin. Its nearest Folder ancestor stays Studio-only (parent ignores unknowns)
# and its scripts go to the read-only snapshot instead.
UNSYNC = set()
UNSYNC_LEAF = set()  # a single childless script whose own name no file can hold (e.g. an empty name)
for it in items:
    p = it["path"]
    if p[0]["n"] not in SYNCED:
        continue
    k = key_of(p)
    if dupes[k] == 1 and needs_rename(p[-1]["n"]) and k not in has_children \
            and not any(needs_rename(x["n"]) for x in p[:-1]):
        UNSYNC_LEAF.add(k)
        continue
    if dupes[k] > 1 or any(needs_rename(x["n"]) for x in p):
        for d in range(len(p) - 1, 0, -1):
            if p[d]["c"] == "Folder":
                UNSYNC.add(key_of(p[: d + 1]))
                break
        else:
            sys.exit("no Folder to leave unsynced for " + "/".join(k))
print("left unsynced (Studio-only folders):", sorted("/".join(u) for u in UNSYNC))
print("left unsynced (single scripts):", sorted("/".join(u) for u in UNSYNC_LEAF))


def is_synced(p):
    if p[0]["n"] not in SYNCED:
        return False
    k = key_of(p)
    if k in UNSYNC_LEAF:
        return False
    return not any(k[: len(u)] == u for u in UNSYNC)


def ensure_dirs(base, parts, synced):
    """Create directories for non-script ancestors with their init.meta.json."""
    cur = base
    for x in parts:
        name = x["n"]
        cur = os.path.join(cur, safe(name) if not synced else name)
        key = os.path.normcase(cur)
        if key in dir_meta_done:
            continue
        dir_meta_done.add(key)
        if x["c"] in SCRIPT_CLASSES:
            continue  # the script itself writes its own init file + meta
        if x["c"] in PROJECT_NODES:
            continue  # services: their class + ignoreUnknownInstances come from default.project.json
        if synced:
            if needs_rename(name):
                sys.exit("synced folder with a name Rojo can't store: %r" % name)
            meta = {"ignoreUnknownInstances": True}
            if x["c"] != "Folder":
                if x["c"] not in GUI_CLASSES:
                    sys.exit("synced container of class %s at %s needs a decision" % (x["c"], cur))
                meta = {"className": x["c"], "ignoreUnknownInstances": True}
            put_json(os.path.join(cur, "init.meta.json"), meta)
            stats["folders"] += 1
    return cur


renamed_dir = os.path.join(ROOT, "src", "_renamed")
manifest = []
for it in items:
    p = it["path"]
    svc = p[0]["n"]
    cls = it["class"]
    if cls not in SCRIPT_CLASSES:
        sys.exit("unexpected class " + cls)
    synced = is_synced(p)
    if synced:
        base = os.path.join(ROOT, "src")
    elif svc in SNAPSHOT or svc in SYNCED:
        base = os.path.join(ROOT, "place-scripts")
    else:
        sys.exit("script in unplanned service " + svc)

    parent_dir = ensure_dirs(base, p[:-1], synced)
    name = p[-1]["n"]
    k = key_of(p)
    tag = ""
    if dupes[k] > 1:
        if synced:
            sys.exit("duplicate synced path " + "/".join(k))
        dup_seen[k] += 1
        tag = " ~%d" % dup_seen[k]

    meta = {}
    if it["disabled"]:
        meta["properties"] = {"Disabled": True}
    if it.get("runContext") not in (None, "Legacy"):
        meta.setdefault("properties", {})["RunContext"] = it["runContext"]
    at = it["attributes"] if isinstance(it["attributes"], dict) else {}
    if at and synced:
        sys.exit("attributes on synced script need a decision: " + "/".join(k))
    if it["tags"] and synced:
        sys.exit("tags on synced script need a decision: " + "/".join(k))

    as_dir = k in has_children
    if synced and needs_rename(name):
        if as_dir:
            sys.exit("renamed script with children needs a decision: " + "/".join(k))
        fname = safe(name).replace("%", "_")
        src_path = os.path.join(renamed_dir, fname + suffix(cls))
        put(src_path, raw(it))
        proj = {"name": name, "tree": {"$path": os.path.relpath(src_path, parent_dir).replace("\\", "/")}}
        if meta:
            sys.exit("renamed script with meta needs a decision")
        put_json(os.path.join(parent_dir, fname + ".project.json"), proj)
        stats["renamed"] += 1
        out = src_path
    elif as_dir:
        d = os.path.join(parent_dir, (name if synced else safe(name)) + tag)
        out = os.path.join(d, "init" + suffix(cls))
        put(out, raw(it))
        if synced:
            meta["ignoreUnknownInstances"] = True
        if meta:
            put_json(os.path.join(d, "init.meta.json"), meta)
        dir_meta_done.add(os.path.normcase(d))
        stats["script dirs"] += 1
    else:
        stem = (name if synced else safe(name)) + tag
        out = os.path.join(parent_dir, stem + suffix(cls))
        put(out, raw(it))
        if meta:
            put_json(os.path.join(parent_dir, stem + ".meta.json"), meta)
        stats["script files"] += 1
    stats["synced" if synced else "snapshot"] += 1
    manifest.append({
        "robloxPath": ".".join(k),
        "class": cls,
        "file": os.path.relpath(out, ROOT).replace("\\", "/"),
        "synced": synced,
        "disabled": it["disabled"],
        "bytes": len(raw(it)),
        **({"attributes": at} if at else {}),
        **({"tags": it["tags"]} if it["tags"] else {}),
    })

put_json(os.path.join(ROOT, "docs", "script-manifest.json"), manifest)
print(dict(stats))
stray = []
for dp, dn, fn in os.walk(ROOT):
    if ".git" in dp.split(os.sep):
        continue
    for f in fn:
        full = os.path.normcase(os.path.abspath(os.path.join(dp, f)))
        if full not in written and (os.sep + "src" + os.sep in full or os.sep + "place-scripts" + os.sep in full):
            stray.append(full)
print("stray files not written by this run:", stray)
