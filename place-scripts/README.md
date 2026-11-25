# place-scripts (read-only copies)

These are the scripts that live **inside** the place's models, tools and folders, where Rojo can't sync them:

- `Workspace/`: scripts inside map models, NPCs, interactables (they run when the server starts)
- `ServerStorage/`: tools, skills, dialog sets and other things the game clones out when it needs them
- `ServerScriptService/.../AbilityService/very old/` and `ServerScriptService/.../CurseUtils/(empty name).luau`:
  synced-service scripts whose names can't be file names (see the main README)

**Editing a file here changes nothing in the game.** Edit these scripts in Studio, then refresh the copies
(see `tools/export/README.md`) so git keeps their history.

Copied on **2026-11-25**. Name encoding: `%3A` = `:`, `%20` = a leading space, `(empty name)` = a script with no name,
` ~2` = the second script with the same Roblox path (e.g. the two `Todas Lou` models).
