# Hunter X Jome: code audit (2026-11-25)

Read-only audit of every script in the place (376 scripts, about 37,000 lines). Nothing in the game was changed.
Items marked ✔ were re-checked by hand against the code. The rest come from four parallel code reviews that read
the files; none of it was play-tested.

## The game in numbers

| | |
|---|---|
| Scripts | 376: 223 synced by Rojo (`src/`), 153 Studio-only (`place-scripts/`) |
| Lines of code | ~30,000 in `src/` (≈7,000 of them Roblox's PlayerModule fork), ~6,900 in `place-scripts/` |
| Map | 27,689 parts (338 unanchored), 270 lights, `Workspace.Map` alone has 29,000 instances |
| Networking | 42 RemoteEvents, 7 RemoteFunctions, 56 Bindables; effects use `FireAllClients` 222 times |
| Settings | StreamingEnabled **off**, TextChatService chat, HttpService on, character appearance off |
| Saving | custom module named "ProfileService" (not the real library), DataStore `Main-<token>`, key = UserId, rollbacks in DataStore `Rollback` |
| Old APIs | few: 13 bare `wait(` and 42 lowercase `:connect(` (mostly in old tools); `spawn`/`delay` already use `task.` |

How it fits together:
- **Server:** `ServerScriptService.ServerHandlers` runs the game (CombatSystem, CharacterHandler,
  PlayerHandler, GameManager for saving, ModerationLoader for admin). `ServerResources.Modules` holds the logic
  (about 60 ability modules in `AbilityService`, plus curses, skills, stats and data).
- **Client:** `StarterPlayerScripts.ClientHandlers` turns key presses into the `RequestAbility` remote. Weapon and
  skill tools (cloned from `ServerStorage.Tools`) have their own `Trigger` remotes.
- **Hits** are decided **on the server** (HitboxService distance/cone checks), which is good. **Stuns, ragdoll and
  slow-downs** are applied only on the client.

## Fix these first

1. **Leaving while your data loads can wipe your character.** ✔ (critical)
   - `ProfileService/init.luau:232-235` puts a profile filled with *defaults* into the cache before the save is read.
     A failed read is retried every frame forever (`:179-186`).
   - `GameManager/init.server.luau:58-72` saves whatever is cached one second after a player leaves.
   - A player who leaves while DataStores are slow gets blank defaults written over their real save.
   - Fix: cache the profile only after a successful read, never save a profile that didn't load, and retry
     with backoff, then kick.
2. **Saves have no safety net.** ✔ (high) No pcall or retry around any save (`GameManager:52-56`). The shutdown loop
   saves one player at a time, so one error stops it for everyone after that player. The 60-second autosave is
   commented out (`GameManager:123-135`). A server crash loses every session, and dropped items or transferred money
   get duplicated.
   Fix: pcall + retry each save, save in parallel on shutdown, re-enable autosave.
3. **Two servers can hold the same player.** (high) The session lock is only in memory and is checked through
   MessagingService with a 2 s wait (`SessionLocking.luau`, `PlayerHandler:52-60`). Messages can be late or lost,
   and saves overwrite blindly. Losing a race means lost progress or duplicated items.
   Fix: store the lock (server JobId + time) inside the save, or move to the real ProfileStore.
4. **Anyone can use skills they don't own.** ✔ (high) `AbilityService/init.luau:31-33` is
   `not requiredSkill or (requiredSkill or ...)`, which is always true. Exploiters can fire `RequestAbility` for
   Infusion, the clan-locked Eight Gates, or Adjust Aura "Full Release", and the client's `skipChannel` flag skips
   Full Release's vulnerable wind-up.
   Fix: `return requiredSkill == nil or SkillUtils:HasSkill(character, requiredSkill)`, check the release forms,
   ignore client `skipChannel`.
5. **Money transfer accepts NaN and works from anywhere.** ✔ (high) `InteractionManager.server.luau:9-57` only checks
   `amount > 10000` and `< 100`. NaN passes both and is then added to the target's Money.
   - `model` comes from the client, so passing your own character satisfies the "near an ATM" check.
   - The sender is charged before the target's profile is checked.
   - Fix: reject NaN/non-integers, require a real ATM model, check the target first.
6. **Every combat hit counts as "destructive".** ✔ (high) `CombatUtils:TakeDamage(character, damage, soft, destructive)`,
   but `CombatSystem.server.luau:98,114,153` pass the attacker as the 4th argument. One jab sets `Mortality = true` and
   skips the kneel phase, so a player who then disconnects is wiped for combat logging instead of warned.
   Lethal Blow, Skewer, Dragon Claw and Triple Kick pass the attacker as `soft`, so they can never knock anyone out.
   Check whether the friend meant this.
7. **A loop that never ends, started on every spawn.** ✔ (high) `CharacterHandler.server.luau:244-253`
   (`while task.wait(.1)`). It keeps running after death and after the player leaves, so busy servers pile up threads.
   Fix: stop when `player.Character ~= character`.

## Before you publish your copy: things that belong to your friend

- **Admins are your friend's staff.** ✔ `ModerationLoader/init.server.luau:9-71` hard-codes 22 usernames (ranks 1-6).
  You are not on it, and every one of them would be an admin in your game (`wipe`, `ban` = universe ban, `addmoney`).
  - The lookups call `GetUserIdFromNameAsync` with no pcall on every command. One renamed account breaks ranks for
    everyone below it.
  - Line 37 has a slur in a comment. Remove it before the code goes anywhere public.
  - Fix: a short table of your own UserIds.
- **Five usernames get secret boosts.** ✔ `AttributeCalculator.luau:67-77` and `StatusLibrary.luau:55,69-90` give
  `s_l6r`, `d3xluxe`, `xutfii`, `nyxworks` and `Topoftheworld178` up to 2.1× damage, 2× HP/energy and no
  enhancement strain.
- **Discord webhooks** ✔ in `WebhookLibrary.luau:6-11` posted to your friend's Discord channels, with their secret
  tokens in the URLs. **Done:** removed from the repo on 2026-11-25. Logging is off, and the library returns without
  sending. The place in Studio still has the old file until Rojo syncs it and you publish.
- **Gamepass IDs** `240756307` (`DataFunctions/init.luau:82`, `ProgressionService.luau:83`) and `1576586121`
  (`DialogSets/Fitz Andmore.luau:29-30`) are most likely your friend's passes. Players in your copy would be asked to
  buy their pass.
- **Robux:** all 6 gamepass scripts in `RobuxStuff/Gamepass` are Disabled. The dev product "Last Wind" is
  `print("Hello world!")`, and there is **no ProcessReceipt anywhere**: anyone who buys a dev product pays and gets
  nothing. The `UserOwnsGamePassAsync` calls have no pcall.

## Security (server trusts the client)

| Severity | Where | Problem | Fix |
|---|---|---|---|
| high | `place-scripts/.../Tools/Skills/Infusion` and `Hotspring/Script.server.luau:4-5` | No check that the sender owns the tool: anyone can drain another player's Hue or stun them by firing *their* tool's Trigger | `if player ~= Players:GetPlayerFromCharacter(tool.Parent) then return end` |
| medium | `AbilityService/Dash.luau:23-53` | Client flag `highSpeed` turns off the anti-teleport check (`SlingshotBypass`) 75% of the time; dash works while stunned | Grant the bypass only for server moves; check stun on the server |
| medium | `CharacterHandler.server.luau:281-310` | Anti-teleport allows ~25× walk speed; stun/ragdoll are client-only | Tighter threshold; server-side movement locks |
| medium | `Tools/Templates/Weapon/CombatServer.server.luau:42-64` | `tech` not whitelisted (`"x"` = free Heavy attack with 0 energy); "Aerial" not checked to be airborne (hyper armor + 2× hitbox on the ground) | Whitelist; check Freefall on the server |
| medium | `SkillLibrary.luau:136` | Empty Requirements returns true before the `Locked` check: clan-locked skills (Eight Gates, Black Flash) can be taught to anyone | Check Locked/Clan first |
| medium | `returnRegistry.server.luau:7-9` | Client-chosen name into `WaitForChild` with no timeout: spam parks server threads forever | Type-check; `FindFirstChild` |
| medium | `vaultGetType.server.luau:3-14` | Sets `VaultType` on any Instance the client passes (e.g. turn an enemy's Vault weapon to 0.1× damage) | Check the tool is in the caller's character |
| low | `CharacterHandler.server.luau:349` | `... or "There"` is always true: every chat line gives Education XP (chat bots farm stats) | Fix the condition, add a cooldown |
| low | `Tools/Misc/Medical Kit/Script.server.luau:22` vs `:123` | Cooldown key "First Aid" vs "First-Aid": heals stack | One key |
| low | `PlayerHandler.server.luau:35` | Ban lookup on join has no pcall: a DataStore hiccup leaves the player with no data | pcall; kick on failure |

**Backdoors:** none found. The only outside code is `Tools/Misc/trinkets/Famous Guitar/Script.server.luau:154`
`require(191816425)` (an old gear module). Normal play never reaches it, but an admin could give it. Delete it.
The search found no `loadstring`, `getfenv`, encoded strings, `InsertService` or outside HTTP calls in any script.
The free-model Cutlass's `OldLinkedSource` attribute is harmless.

## Data and economy (other findings)

- `ProfileService/init.luau:99`: `if rawdata[name] then` treats a saved `false` as missing. `CombatPity` resets to
  true on every load, so a repeat combat-logger is never wiped. Fix: `~= nil`.
- `CharacterHandler.server.luau:181-190`: the inventory is rebuilt only when a tool enters or leaves the character.
  Tools put straight into the Backpack (shop purchase, treasure) are not saved if you leave without equipping
  anything. The money is gone and so is the weapon.
- `Commands.luau:520-525`: `:restore` on a player with no rollback snapshot resets them to defaults (the empty `{}`
  isn't seen as "no data").
- `PlayerHandler.server.luau:99-105`: disconnect clears the wrong table, so every join leaves a Heartbeat running
  for the life of the server.
- `EconomyService` and `Classes/ExamService` are never required (dead). EconomyService would loop forever if wired
  up.
- `ServerScriptService/Script` (Disabled) rewrites every save key if someone turns it on. Delete it, and the
  Disabled `ReplicatedStorage/Script` too.

## Combat bugs

- `Triple Kick.luau:70-93` calls a method that doesn't exist (`BattleExperience`), so kicks 2 and 3 never happen.
- `CombatSystem.server.luau:65-73`: a parried heavy still guard-breaks the parrier. Line 168 lowers the damage of a
  second attacker *after* the damage was dealt, so it only cuts XP.
- `Knee Release`, `Raging Jolt`, `Plunge`: damage multipliers stack on a shared variable, so the 2nd target takes
  squared damage, and 0 if the first target parried.
- `CurseUtils/Vault.luau:12`: one module-wide damage multiplier shared by every Vault user. Release mode deals
  damage twice (`:131`, `:134`).
- `Lethal Blow.luau:123-126` + `DeathModule.luau:19`: can execute players inside i-frames or under a spawn
  ForceField.
- Names that don't match, so the effect never happens: Dash's "Invulnerability" vs "Invulnerable", Knee Release
  i-frames in the wrong folder, Eight Gates checks "Leaves", Malevolent/Restless/Underdog look up the skill cache by
  player instead of character.
- Abilities have no cleanup if they error. Example: Air Strike against a body with no root part leaves the attacker
  hovering with a stuck cooldown until respawn.

## Performance

- Every effect and sound goes to **every** player (`FireAllClients` ×222). Hotspring alone sends about 700
  broadcasts per use (`Hotspring/init.luau:40-43`). `StatusLibrary.luau:290` fires a bindable every frame for every
  player not using it. Send effects only to players nearby.
- `CharacterHandler.server.luau:257-341` decodes JSON and scans all players every frame for every player
  (N² per frame). Recompute on change, or 1-4 times a second.
- `Workspace/Map/Barbershop/Barberpole/SpinScript`: a server loop moves 2 parts every frame. Spin it on the client.
- StreamingEnabled is off with ~28,000 parts. Worth testing on a phone.

## Broken or dead code (safe to clean up later)

- Skills that error or do nothing: Emulate, Mental Limit Break and Psychological Limit Break (wrong argument order,
  module missing); Reverse Curse Technique (empty); Spiritual Pressure (never given); " Disrupting Fang" (name
  starts with a space); Perfect Release (sends "Full Release"). The Hotspring tool can never switch off or reach
  "Sauna".
- `Workspace/BUDDY/Script`: an old copy of the TreasureSpawner dialog. It keys rewards by character, so dying resets
  them (unlimited Money Stacks). Its 10% "Generic" dialog roll errors and leaves the player unable to talk to NPCs
  until they respawn (the same bug is in `TreasureSpawner/Script`).
- `TreasureSpawner/init.server.luau:167`: the NPCs' idle-animation script makes the code think a dialog script
  exists, so Jason Jason, Zacz and Hazel never talk.
- `Workspace/Model` (the free-model Cutlass) deals raw damage that skips blocking, and leaks Animation objects.
  Delete it.
- About 45 Studio-only scripts never run: AbilityService `very old` (24), `archived` (3), `_broken` (3), `_wip` (6),
  HUDHandler (Disabled), the Famous Guitar copies.
- `CurseUtils` has a module with an **empty name**. It runs on every hit by accident: uncursed weapons look up the
  curse `""`. Harmless now; guard it with `curse ~= ""`.

## Not checked

Nothing was run in Studio. Not verified: how the engine stores NaN in an IntValue, whether "every hit is destructive"
is intended, the shop price attributes (buy/sell arbitrage), the PlayerModule fork, most GUI scripts and skill-tool
LocalScripts, and whether asset 191816425 still loads.
