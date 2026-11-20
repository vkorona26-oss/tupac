# Tupac Hub

The script hub half of this repo. Two files, no build step, no dependencies inside the game.

| File | Role |
|---|---|
| `Exec` | loader — the file the one-liner fetches |
| `hub.lua` | the hub: UI library + modules, ~1600 lines |
| `hub.html` | landing page with a copy button |

## Use

```lua
loadstring(game:HttpGet("https://vkorona26-oss.github.io/tupac/Exec"))()
```

Backup line, same payload, no Pages dependency:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vkorona26-oss/tupac/main/Exec"))()
```

`Exec` fetches `hub.lua` from Pages, then falls back to raw and jsDelivr if Pages is down.

## Tabs

| Tab | Modules |
|---|---|
| Main | walk speed, jump power, infinite jump, noclip, anti-AFK, anti-void, reset, fly + speed |
| Visuals | player ESP, ESP names + health bars, fullbright, camera FOV |
| Teleport | waypoints (saved to disk), teleport to player, teleport to cursor |
| Misc | rejoin, server hop, join by JobId, copy JobId, copy PlaceId |
| Settings | UI transparency, notifications, menu keybind, config save/load/delete, unload |

RightShift hides the menu. Unload with the button or `getgenv().OJBHub.Unload()` —
lighting, FOV, walk/jump, fly bodies, ESP, connections and GUI all restored.

## Updating

Edit `hub.lua` here, commit, push. The loader always fetches `main`, so the change is
live for every user on their next execution. No version bump needed for a payload edit;
bump `local VERSION` in `hub.lua` when you want the menu to show it.

## Adding a module

```lua
addToggle(page, "Label", false, "flagName", function(on) ... end)
addSlider(page, "Label", 0, 100, 50, 1, "flagName", function(v) ... end)
addButton(page, "Label", THEME.Text, function() ... end)
addTextbox(page, "Label", "placeholder", "flagName", function(text) ... end)
addDropdown(page, "Label", function() return {"a","b"} end, "a", "flagName", function(v) ... end)
addKeybind(page, "Label", Enum.KeyCode.F, "flagName", function(key) ... end)
```

The flag name is the config key — saved and loaded automatically.

## Key system

Off by default. In `Exec`:

```lua
local KEY_URL = ""   -- endpoint that returns exactly "valid"
local KEY_FILE = "OJBHub/key.txt"
```

Set `KEY_URL` and the loader sends `?key=<stored>&hwid=<hwid>` before running anything.
