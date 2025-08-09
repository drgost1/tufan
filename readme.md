

# Documentation: Tufan Core Utilities

`Tufan` is a core utility resource designed to provide essential, standalone functionalities for FiveM servers. Its primary feature is a powerful **Universal Targeting** system that allows other resources to work with either **ox_target** or **qb-target** without any code changes.

This documentation explains how to leverage the functions provided by `tufan` in your own scripts.

**GitHub Repository:** [drgost1/tufan](https://github.com/drgost1/tufan)

---

### Features

*   **Universal Targeting:** A complete compatibility layer for `ox_target` and `qb-target`. Write your code once, and it runs on both.
*   **Automatic Detection:** The script automatically detects which targeting system is active on server startup.
*   **Localization:** Comes with pre-built localization for English (`en`) and Turkish (`tr`).
*   **Version Checking:** A server-side script checks for new versions on GitHub to ensure you're always up-to-date.

### Dependencies

*   [ox_lib](https://github.com/overextended/ox_lib) (Required for the version checker, localization, and auto-detection to function correctly).
*   **One** of the following target systems must be installed and running:
    *   [ox_target](https://github.com/overextended/ox_target)
    *   [qb-target](https://github.com/qbcore-framework/qb-target)

---

### Installation

1.  Clone or download the `tufan` repository from GitHub.
2.  Place the `tufan` folder into your server's `resources` directory.
3.  Ensure `tufan` is started in your `server.cfg` or `resources.cfg`. Make sure it starts **after** its dependencies.
    ```cfg
    ensure ox_lib
    ensure tufan
    ```

### Using Tufan in Your Own Resource

To use the targeting functions in another resource (e.g., `my_heist`), you must add `tufan` as a dependency in that resource's `fxmanifest.lua`. This ensures `tufan` loads before your script does.

```lua
-- in your other resource's fxmanifest.lua (e.g., my_heist/fxmanifest.lua)

-- This tells the server to load 'tufan' before this script starts.
dependencies {
    'tufan'
}

client_scripts {
    'client/main.lua' -- Your script that will call the functions.
}
```

---

## How to Use Targeting Functions

All targeting functions are called from your client scripts using the `exports` global, referencing the `tufan` resource.

```lua
-- The basic format for calling a function is:
-- exports['tufan']:FunctionName(arguments)

-- Example:
exports['tufan']:AddBoxZone({ ... })
```

---

## Zone Targeting Functions

### AddBoxZone
Creates a box-shaped interaction zone.

*   **Arguments:** `data` (`table`)
*   **Example:**
    ```lua
    exports['tufan']:AddBoxZone({
        name = 'heist_getaway_van',
        coords = vector3(100.0, 200.0, 75.0),
        size = vec3(3.0, 5.0, 3.0),
        rotation = 45.0,
        debug = false,
        options = {
            {
                label = 'Stash the Goods',
                icon = 'fas fa-box',
                onSelect = function()
                    print('The goods have been stashed!')
                end
            }
        }
    })
    ```

### AddCircleZone
Creates a circular interaction zone.

*   **Arguments:** `data` (`table`)
*   **Example:**
    ```lua
    exports['tufan']:AddCircleZone({
        name = 'drug_deal_spot',
        coords = vector3(110.0, 210.0, 75.0),
        radius = 5.0,
        options = {
            {
                label = 'Wait for Contact',
                icon = 'fas fa-user-secret',
                onSelect = function()
                    print('You wait nervously...')
                end
            }
        }
    })
    ```

### RemoveZone
Removes any interaction zone by its unique name.

*   **Arguments:** `name` (`string`)
*   **Example:**
    ```lua
    exports['tufan']:RemoveZone('heist_getaway_van')
    ```

### AddPolyZone
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Creates a zone with a custom polygon shape.

---

## Entity, Model & Bone Targeting

### AddLocalEntity / AddEntityTarget
Adds interaction options to a specific entity (ped, vehicle, or object).

*   **Arguments:** `entity` (`number`), `options` (`table`)
*   **Example:**
    ```lua
    local targetPed = GetPlayerPed(-1) -- Target yourself for this example
    exports['tufan']:AddLocalEntity(targetPed, {
        {
            label = 'Check Pockets',
            icon = 'fas fa-hand-paper',
            onSelect = function(data)
                print('You pat down entity ' .. data.entity)
            end
        }
    })
    ```

### RemoveLocalEntity / RemoveEntityTarget
Removes interaction options from a specific entity.

*   **Arguments:** `entity` (`number`), `labels` (`string` or `table`, optional)

### AddModel / AddModelTarget
Adds interaction options to all entities of a given model.

*   **Arguments:** `model` (`string`|`number`|`table`), `options` (`table`)
*   **Example:**
    ```lua
    exports['tufan']:AddModel('prop_atm_01', {
        {
            label = 'Use ATM',
            icon = 'fas fa-credit-card',
            onSelect = function() print('ATM UI would open here.') end
        }
    })
    ```

### SetBoneTarget / AddTargetBone
Adds interaction options to a specific bone (or bones) of an entity.

*   **Arguments:** `entity` (`number`), `bones` (`table`)
*   **Example:**
    ```lua
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if vehicle then
        exports['tufan']:SetBoneTarget(vehicle, {
            ['wheel_lf'] = {
                {
                    label = 'Check Tire Pressure',
                    icon = 'fas fa-tire',
                    onSelect = function() print('This tire seems fine.') end
                }
            }
        })
    end
    ```

### RemoveBoneTarget
Removes interaction options from an entity's bone(s).

*   **Arguments:** `entity` (`number`), `bones` (`string` or `table`)

---

## Utility Functions

### IsTargeting
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Returns `true` if the player is currently aiming at any valid target.

### GetNearbyEntities
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Returns a table of nearby targeted entities.