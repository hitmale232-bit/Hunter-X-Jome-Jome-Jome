# Copying the code out of Studio

How `src/` and `place-scripts/` were made on 2026-11-25. Use this to refresh `place-scripts/` after editing
Studio-only scripts, or to re-check that `src/` still matches the place. Ask Claude Code to do it: it needs the
Roblox Studio MCP.

1. `export_chunk.luau`: run in Studio through the MCP `execute_luau` tool once per chunk (CHUNK = 1..n).
   Each result is saved to a tool-results file.
2. `python -I reassemble.py <tool-results folder> <scripts.json>`: joins the chunks and checks the total length and
   hash, plus every script's length.
3. `python -I layout.py <scripts.json> <this repo>`: writes `src/`, `place-scripts/` and
   `docs/script-manifest.json`, and lists any files it did not write (stale ones to delete by hand).
4. `rojo build <this repo> -o check.rbxlx` then `python -I verify.py <scripts.json> <this repo> check.rbxlx`:
   checks that every file on disk equals the exported bytes, and that the Rojo build holds exactly the synced
   scripts with the same names, types, Disabled flags and code.

Why not HTTP: the Studio MCP blocks HttpService requests to localhost, so the code goes out through the
MCP's own results instead.
