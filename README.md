# Hunter X Jome

Roblox place **Hunter X Jome** (place 109628873472847, universe 10778971765), a copy of a friend's game.
This repo holds the game's **code**. The map, models, GUIs and other parts stay in the Roblox place.

> The code was lent to you by a friend: keep the GitHub repo **private**.

## What's in here

| Folder | What it is | Synced into Studio by Rojo? |
|---|---|---|
| `src/ServerScriptService` | server scripts and modules | **yes** |
| `src/ReplicatedStorage` | shared modules | **yes** |
| `src/ReplicatedFirst` | the loading script | **yes** |
| `src/StarterPlayer` | client scripts, PlayerModule fork, character `Health` script | **yes** |
| `src/StarterGui` | the scripts inside the 6 GUIs (HUD, Notebook, ...) | **yes** (only the scripts, not the frames) |
| `place-scripts/` | copies of the 153 scripts that live **inside** Workspace / ServerStorage models and tools | **no**: read-only copies, see `place-scripts/README.md` |
| `docs/` | audit report, `script-manifest.json` (every script, its Roblox path and file) | no |
| `tools/export/` | how the code was copied out of Studio (to refresh `place-scripts/`) | no |

File names follow Rojo's rules:

| File | Becomes in Studio |
|---|---|
| `Name.server.luau` | Script |
| `Name.client.luau` | LocalScript |
| `Name.luau` | ModuleScript |
| `Name/init.server.luau` (or `init.client.luau`, `init.luau`) | a script that has children; the other files in `Name/` are its children |
| `init.meta.json` / `Name.meta.json` | settings for that folder or script (Disabled, GUI class, "keep Studio-only children") |

## Connect Rojo (first time)

1. Open a terminal in this folder and run `aftman install` once (installs Rojo 7.7.1 and Selene from `aftman.toml`).
2. Run `rojo serve`. It listens on port **34874** (Redline uses 34872, Jome X Jome 34873, so the three never clash).
3. In Studio, open **Hunter X Jome**, open the Rojo plugin, set the port to **34874**, press **Connect**.
4. Rojo shows what it would change before applying anything. The files were checked against the place on 2026-11-25
   (all 223 synced scripts identical). Since then, exactly **one** script was changed on purpose:
   `ServerResources.Modules.WebhookLibrary` (Discord webhook URLs removed, see below). So the first connect should list
   that one change and nothing else. Accept it, then **publish the place** so the old URLs are gone from Roblox too.
   If Rojo lists other changes you did not make, press **Abort** and check: someone edited the place in Studio after
   that date.

## Rules that keep the place safe

- **Code in `src/`: edit in VS Code, not in Studio.** Rojo only copies files into Studio. An edit made in Studio's
  script editor to a synced script is overwritten the next time that file changes or Rojo reconnects.
- **Everything else: edit in Studio and publish the place as usual.** Frames, RemoteEvents, Animations, Parts, models,
  Workspace and ServerStorage are not in the files. Every folder in `src/` is marked "ignore unknown instances", so
  Rojo never deletes them.
- **New script:** make the file in the right `src/` folder with the right ending (`.server.luau`, `.client.luau`, `.luau`).
- **Deleting a file deletes that script in Studio** while Rojo is connected.
- Roblox names that Windows can't use as file names stay Studio-only. Right now that is:
  - `ServerScriptService.ServerResources.Modules.AbilityService.very old` (holds two modules both named `Triple Kick` and one named `Hue: Cloaking`)
  - the unnamed module inside `ServerScriptService.ServerResources.Modules.CurseUtils`

  Copies of them are in `place-scripts/`. Rojo leaves them alone in Studio.
- Never put webhook URLs, API keys or passwords in `src/`. Anything in `src/` goes to GitHub. The original Discord
  webhooks (admin log + kill log) were removed from `WebhookLibrary.luau`, so Discord logging is off until you
  wire up your own webhooks from somewhere that stays out of git (for example attributes on a ServerStorage object).
- 35 scripts use Windows (CRLF) line endings. `.gitattributes` keeps every `.luau` file byte-for-byte, so Rojo
  doesn't rewrite them.

## Put it on GitHub

1. On github.com: **New repository** → name it (e.g. `hunter-x-jome`) → **Private** → do **not** add a README → Create.
2. In this folder:

```powershell
git remote add origin https://github.com/<your-account>/hunter-x-jome.git
```

```powershell
git push -u origin main
```

## Lint (optional)

`selene src` lists likely bugs. The existing code was written without a linter, so expect many warnings at first.
