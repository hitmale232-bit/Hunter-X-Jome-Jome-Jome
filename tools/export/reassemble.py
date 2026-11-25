"""Join the BHCHUNK tool-result files, verify length + FNV-1a hash, decode every script, save one JSON."""
import base64
import glob
import json
import os
import sys

src_dir, out_path = sys.argv[1], sys.argv[2]
chunks = {}
meta = None
for p in glob.glob(os.path.join(src_dir, "mcp-Roblox_Studio-execute_luau-*.txt")):
    with open(p, "r", encoding="utf-8") as f:
        text = f.read()
    if not text.startswith("BHCHUNK "):
        continue
    header, _, body = text.partition("\n")
    _, i, n, total, h = header.split()
    key = (int(n), int(total), int(h))
    if meta is None:
        meta = key
    elif meta != key:
        sys.exit("chunks from different exports: %r vs %r" % (meta, key))
    chunks[int(i)] = body

n, total, want_hash = meta
missing = [i for i in range(1, n + 1) if i not in chunks]
if missing:
    sys.exit("missing chunks: %r" % missing)
S = "".join(chunks[i] for i in range(1, n + 1))
data = S.encode("utf-8")
if len(data) != total:
    sys.exit("length mismatch %d != %d" % (len(data), total))
# Luau numbers are doubles: the multiply rounds past 2^53, so repeat the exact same double maths here.
h = 2166136261.0
for byte in data:
    h = float(int(h) ^ byte)
    h = (h * 16777619.0) % 4294967296.0
h = int(h)
if h != want_hash:
    sys.exit("hash mismatch %d != %d" % (h, want_hash))

items = json.loads(S)
bad = 0
for it in items:
    raw = base64.b64decode(it.pop("b64"))
    if len(raw) != it["len"]:
        bad += 1
    it["source"] = raw.decode("utf-8", errors="surrogateescape")
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(items, f, ensure_ascii=False)
print("chunks=%d bytes=%d hash ok, scripts=%d, length mismatches=%d" % (n, total, len(items), bad))
