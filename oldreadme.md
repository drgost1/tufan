# Tufan Target Bridge & Shared Framework

## Overview
Tufan provides a unified targeting and player framework for FiveM, supporting `qb-core`, `qbx_core`, `es_extended`, `ox_core`, and `ox_inventory`. It auto-detects your backend and exposes all major functions as exports for easy use in other resources.

---

## Target System Exports

Add interactive targets and zones to entities and the world:

```lua
-- Add a target to an entity (ped, object, etc.)
exports['tufan']:addTarget(entity, {
  {
    name = 'greet',
    label = 'Greet',
    icon = 'fas fa-handshake',
    action = function(entity) print('Hello from the ped! Entity:', entity) end,
    distance = 2.5,
  }
})

-- Remove a target from an entity
exports['tufan']:removeTarget(entity)

-- Add a box zone
exports['tufan']:addBoxZone({
  name = 'repair_zone',
  coords = vector3(-211.55, -1324.55, 30.89),
  size = vector3(3.0, 3.0, 3.0),
  rotation = 0.0,
  debug = true,
  options = {
    {
      name = 'open',
      label = 'Open Menu',
      icon = 'fas fa-tools',
      action = function() print('open') end,
      distance = 2.5,
    }
  }
})

### Option Structure
The following structure is used for defining interaction options:
```lua
      {
          label = "Option Label",      -- Text shown to player
          icon = "fas fa-icon",        -- Font Awesome icon
          action = function(entity)    -- Function to execute when selected
              -- Your code here
          end,

          -- Conditional properties:
          job = "police",             -- Required job (single job)
          job = {                     -- Multiple jobs with grades
              police = 0,             -- Job name and minimum grade
              ambulance = 2
          },
          gang = "ballas",            -- Required gang
          item = "lockpick",          -- Required item
          item = {"lockpick", "advancedlockpick"},  -- Multiple items (any one required)

          -- Optional:
          name = "unique_name",       -- Unique identifier
          distance = 2.0,             -- Interaction distance override
          canInteract = function(entity) -- Custom visibility check
              return true
          end
      }
```
  ## Exports

  ### Client-side Exports

  #### Targeting Bridge (client/target.lua)

  - `addTarget(entity, options)`
  - `removeTarget(entity)`
  - `addBoxZone(name, center, length, width, options)`
  - `removeZone(name)`


  ### Server-side Exports


  - `GetIdentifier(playerId)`
  - `GetName(playerId)`
  - `GetJobCount(jobName)`
  - `GetPlayers()`
  - `GetPlayerGroups(playerId)`
  - `GetPlayerJobInfo(playerId)`
  - `GetPlayerGangInfo(playerId)`
  - `GetDob(playerId)`
  - `GetSex(playerId)`
  - `RemoveItem(playerId, item, count)`
  - `AddItem(playerId, item, count)`
  - `HasItem(playerId, item, count)`
  - `GetInventory(playerId)`
  - `SetJob(playerId, job, grade)`
  - `RegisterUsableItem(item, callback)`
  - `GetMoney(playerId, account)`
  - `RemoveMoney(playerId, account, amount)`

-- Check if player is dead
local isDead = exports['tufan']:IsDead()
```

---

## API Reference

- `addTarget(entity, options)` — Add target options to an entity
- `removeTarget(entity)` — Remove target from an entity
- `addBoxZone(data)` — Add a box zone with options
- `removeZone(name)` — Remove a box zone
- `Notify(msg, type, duration)` — Show a notification to the player
- `GetPlayerGroups()` — Get player's job and gang/group
- `GetPlayerGroupInfo(job)` — Get detailed job or gang info
- `GetSex()` — Get player's gender
- `IsDead()` — Check if player is dead

---

## Features

- **Auto-detects framework:** Supports `qb-core`, `qbx_core`, `es_extended`, `ox_core`.
- **Unified API:** All targeting and framework functions work regardless of backend.
- **Inventory support:** Uses `ox_inventory` if available.
- **Easy exports:** All major functions are exported for use in other resources.

---

## Best Practices

- Always use the documented options style for targets.
- Use only the `action` key for compatibility; it will auto-convert for OX target.
- Use the provided exports for notifications and player info.

---

## Troubleshooting

- If you see `No such export ... in resource tufan`, make sure the function is exported in `framework.lua` or `target.lua`.
- If targets do not appear, check that your targeting backend (qb-target, ox_target) is running and detected.

---

For more advanced usage or help, contact the developer or check the source files for additional options!