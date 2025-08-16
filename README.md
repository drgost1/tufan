# Tufan Target & Framework Bridge

Unified targeting + player/framework abstraction for FiveM. Supports:
- **Frameworks:** `qb-core`, `qbx_core`, `es_extended`, `ox_core`
- **Inventory (optional):** `ox_inventory` (auto-used when running)
- **Target backends (client):** `ox_target` > `qb-target`

Everything auto-detects at runtime. Exports are defined inline (no `server_exports` list needed).

---
## Installation
1. Drop the `tufan` folder in your resources directory.
2. Ensure / start it after your framework & target resources:
   ```
   ensure ox_inventory      # (optional)
   ensure qb-core | qbx_core | es_extended | ox_core
   ensure ox_target | qb-target
   ensure tufan
   ```
3. (Optional) Set `Config.TargetSystem` before the client `target.lua` loads if you want to force a backend.

---
## Client Exports
| Export | Description |
|--------|-------------|
| `addTarget(entity, options)` | Attach interaction options to an entity (ped/object/vehicle). |
| `removeTarget(entity, name?)` | Remove all or a named option from an entity. |
| `addBoxZone(data)` | Create a 3D box zone with interaction options. |
| `removeZone(name)` | Remove a previously created zone. |
| `Notify(message, type?, duration?)` | Show a notification (auto maps to framework). |
| `GetPlayerGroups()` | Returns jobName, gangName/false. |
| `GetPlayerGroupInfo(isJob)` | Detailed info (name, label, grade) for job (true) or gang (false). |
| `GetSex()` | Returns gender (framework-specific mapping). |
| `IsDead()` | Player death state. |

### Target Option Structure
```lua
{
  label = 'Open Menu',      -- Required: display text
  icon = 'fas fa-tools',    -- Optional: Font Awesome icon (ox_target / qb-target)
  action = function(entity) -- Required: function to execute
      print('Used on', entity)
  end,
  -- Conditional visibility:
  job = 'police' or { police = 0, ambulance = 2 },
  gang = 'ballas',
  item = 'lockpick' or { 'lockpick', 'advancedlockpick' },
  -- Optional meta:
  name = 'unique_id',
  distance = 2.5,           -- Override per-option distance
  canInteract = function(entity) return true end -- Extra custom check
}
```
All `action` callbacks are automatically mapped to `onSelect` when using `ox_target`.

### addTarget
```lua
local ped = PlayerPedId()
exports.tufan:addTarget(ped, {
  {
    label = 'Greet',
    icon = 'fas fa-handshake',
    action = function(ent) print('Hello', ent) end,
    distance = 2.0
  },
  {
    label = 'Police Only Action',
    job = { police = 2 },
    action = function() print('Police grade >= 2 only') end
  }
})
```

### removeTarget
Remove all options (or a named option if backend supports):
```lua
exports.tufan:removeTarget(ped)            -- all
exports.tufan:removeTarget(ped, 'unique')  -- named (ox_target)
```

### addBoxZone
```lua
exports.tufan:addBoxZone({
  name = 'repair_zone',
  coords = vector3(-211.55, -1324.55, 30.89),
  size = vector3(3.0, 3.0, 3.0),
  rotation = 0.0,
  debug = true,
  options = {
    {
      label = 'Open Menu',
      icon = 'fas fa-wrench',
      action = function() print('Menu opened') end
    }
  }
})
```

### removeZone
```lua
exports.tufan:removeZone('repair_zone')
```

### Notify
```lua
exports.tufan:Notify('Mission started', 'success', 5000)
```
`type` falls back gracefully depending on framework (e.g., 'primary', 'success', etc.).

### Player Info Helpers
```lua
local jobName, gangName = exports.tufan:GetPlayerGroups()
local jobInfo = exports.tufan:GetPlayerGroupInfo(true)
local gangInfo = exports.tufan:GetPlayerGroupInfo(false)
local gender = exports.tufan:GetSex()
local dead = exports.tufan:IsDead()
```

---
## Server Exports
| Export | Purpose | Notes |
|--------|---------|-------|
| `GetIdentifier(playerId)` | Unique identifier/citizenid | ESX/Ox return license/identifier. |
| `GetName(playerId)` | Full name | Auto builds first/last where needed. |
| `GetJobCount(jobName)` | Active players in job | ox_core uses GlobalState counts. |
| `GetPlayers()` | List `{job, gang, source}` | Gang = false where unsupported. |
| `GetPlayerGroups(playerId)` | Raw job & gang/group | Second value false if none. |
| `GetPlayerJobInfo(playerId)` | `{name,label,grade,gradeName}` | ox_core uses group grades. |
| `GetPlayerGangInfo(playerId)` | Gang info or false | Not for ESX / ox_core. |
| `GetDob(playerId)` | Birthdate | Field name differs per framework. |
| `GetSex(playerId)` | Gender value | ox_core returns 1/2 mapping. |
| `RemoveItem(playerId,item,count)` | Remove inventory item | Prefers ox_inventory. |
| `AddItem(playerId,item,count,metadata?)` | Add item | metadata forwarded if supported. |
| `HasItem(playerId,item)` | Count of item | Returns number (0 if none). |
| `GetInventory(playerId)` | Standardized item list | Empty for ox_core w/out ox_inventory. |
| `SetJob(playerId, job, grade)` | Assign job/group | ox_core sets + activates group. |
| `RegisterUsableItem(item, cb)` | Register usable item | ox_inventory exports style if present. |
| `GetMoney(playerId, account)` | Get account balance | 'money' maps to cash. |
| `RemoveMoney(playerId, account, amount)` | Deduct funds | ox_core uses get/set fallback. |

### Usage Examples
```lua
local src = source
local cid = exports.tufan:GetIdentifier(src)
local name = exports.tufan:GetName(src)
local jobInfo = exports.tufan:GetPlayerJobInfo(src)
local gangInfo = exports.tufan:GetPlayerGangInfo(src)

print(('[tufan demo] %s (%s) job=%s grade=%s'):format(name, cid, jobInfo.name, jobInfo.gradeName))
```

Inventory & Items:
```lua
if exports.tufan:HasItem(src, 'lockpick') > 0 then
  exports.tufan:RemoveItem(src, 'lockpick', 1)
end
exports.tufan:AddItem(src, 'water', 2)

for _, item in ipairs(exports.tufan:GetInventory(src)) do
  print(item.name, item.count)
end
```

Jobs & Money:
```lua
exports.tufan:SetJob(src, 'mechanic', 2)
local cash = exports.tufan:GetMoney(src, 'money')
if cash >= 500 then
  exports.tufan:RemoveMoney(src, 'money', 500)
end
```

Register usable item:
```lua
exports.tufan:RegisterUsableItem('water', function(playerId)
  print('Player used water', playerId)
  -- hydration logic
end)
```
(When `ox_inventory` is active, callback receives `(source, event, item, inventory, slot, data)`.)

---
## Conditional Logic in Target Options
You can restrict visibility by job, gang, or required items. For multiple jobs or items supply a table. Any one item in a list satisfies the requirement.

Your validation occurs automatically inside the backend if supported; otherwise implement `canInteract`.

---
## Debugging
Set `Config.Tufan.Debug = true` (client) to log target actions and backend selection.

---
## Notes & Edge Cases
- ox_core without ox_inventory cannot return full inventory lists.
- ESX job counts: if `ESX.GetExtendedPlayers('job', job)` returns table of players, count uses `#tbl`.
- Gender mapping: some frameworks store as string, others numeric; API does not normalize beyond existing logic.
- Removing money on ox_core uses `get/set` heuristic (adjust to your economy implementation if needed).

---
## Contributing
PRs welcome: improvements for gang support on ox_core, unified money handling, or additional target backends.

---
## License
MIT (adapt as needed for your project).
