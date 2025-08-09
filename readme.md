Got it. Here is the complete documentation page, updated so that all examples use `tufan` as the resource name.

***

# Documentation: Universal Targeting for "tufan"

This documentation outlines how to use the Universal Targeting compatibility script included in the **tufan** resource. This script acts as a bridge, allowing your resource to work with either **ox_target** or **qb-target** without needing to change any code.

It automatically detects which targeting system is active on the server and routes the function calls appropriately. The API is modeled after `ox_target` for a modern and flexible developer experience.

---

### Dependencies

*   [ox_lib](https://github.com/overextended/ox_lib) (Required for auto-detection and recommended for UI features like `lib.progressCircle`)
*   **One** of the following target systems must be installed and running:
    *   [ox_target](https://github.com/overextended/ox_target)
    *   [qb-target](https://github.com/qbcore-framework/qb-target)

---

### Installation & Setup

1.  **Ensure `tufan` is started:** Make sure the `tufan` resource (which contains the universal target script) is present on your server and started in your `server.cfg` or `resources.cfg`.

2.  **Using functions in another resource:** If you want to use these functions from a *different* resource (e.g., `my_heist_script`), you must add `tufan` as a dependency in that resource's `fxmanifest.lua`.

    ```lua
    -- in your other resource's fxmanifest.lua (e.g., my_heist_script/fxmanifest.lua)

    -- This tells the server to load 'tufan' before this script starts.
    dependencies {
        'tufan'
    }

    client_scripts {
        'client/main.lua' -- your script that will call the functions
    }
    ```

3.  **Configuration (Optional):**
    You can modify the `Config` table at the top of `tufan`'s `cl_target.lua`.
    *   `Config.TargetSystem`: Set to `"auto"` by default. Can be forced to `"ox"` or `"qb"`.
    *   `Config.Debug`: Set to `true` to see debug messages and warnings in the F8 console.
    *   `Config.DefaultDistance`: Sets the default interaction distance when converting to `qb-target`.

---

## How To Use

All functions are called from your client scripts using the `exports` global, referencing the `tufan` resource.

```lua
-- The basic format for calling a function is:
-- exports.tufan:FunctionName(arguments)

-- Example:
exports.tufan:AddBoxZone({ ... })
```

---

## Zone Targeting Functions

### AddBoxZone
Creates a box-shaped interaction zone.

*   **Arguments:**
    *   `data` (`table`): A table containing the zone's properties.
        *   `name` (`string`): **Required.** A unique name for the zone.
        *   `coords` (`vector3`): The center coordinates of the zone.
        *   `size` (`vector3`): The length, width, and height of the box.
        *   `options` (`table`): A table of interaction options (see example).
        *   `rotation` (`number`, optional): The heading/rotation of the zone (0-360).
        *   `distance` (`number`, optional): The maximum distance from which the zone can be seen.
        *   `debug` (`boolean`, optional): If true, shows the zone's outline.

*   **Example:**
    ```lua
    exports.tufan:AddBoxZone({
        name = 'my_unique_box_zone',
        coords = vector3(100.0, 200.0, 75.0),
        size = vec3(2.0, 2.0, 1.5),
        rotation = 45.0,
        debug = true,
        options = {
            {
                label = 'Interact with Box',
                icon = 'fas fa-box',
                onSelect = function()
                    print('You interacted with the box zone!')
                end
            }
        }
    })
    ```

### AddCircleZone
Creates a circular interaction zone.

*   **Arguments:**
    *   `data` (`table`): A table containing the zone's properties.
        *   `name` (`string`): **Required.** A unique name for the zone.
        *   `coords` (`vector3`): The center coordinates of the zone.
        *   `radius` (`number`): The radius of the circle.
        *   `options` (`table`): A table of interaction options.
        *   `useZ` (`boolean`, optional): Set to `true` to check Z-axis.
        *   `debug` (`boolean`, optional): If true, shows the zone's outline.

*   **Example:**
    ```lua
    exports.tufan:AddCircleZone({
        name = 'my_unique_circle_zone',
        coords = vector3(110.0, 210.0, 75.0),
        radius = 3.0,
        debug = true,
        options = {
            {
                label = 'Enter Circle',
                icon = 'fas fa-circle',
                onSelect = function()
                    print('You are inside the circle zone!')
                end
            }
        }
    })
    ```

### RemoveZone
Removes any type of interaction zone by its name.

*   **Arguments:**
    *   `name` (`string`): The unique name of the zone to remove.

*   **Example:**
    ```lua
    exports.tufan:RemoveZone('my_unique_box_zone')
    ```

### AddPolyZone
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Creates a zone with a custom polygon shape.

*   **Arguments:**
    *   `data` (`table`): A table containing the zone's properties. See `ox_target` docs for details.

---

## Entity, Model & Bone Targeting

### AddLocalEntity / AddEntityTarget
Adds interaction options to a specific, spawned entity (ped, vehicle, or object).

*   **Arguments:**
    *   `entity` (`number`): The network ID of the entity.
    *   `options` (`table`): A table of interaction options.

*   **Example:**
    ```lua
    local myCar = CreateVehicle(`sultanrs`, GetEntityCoords(PlayerPedId()), 90.0, true, true)
    exports.tufan:AddLocalEntity(myCar, {
        {
            label = 'Check Engine',
            icon = 'fas fa-car-wrench',
            onSelect = function(data)
                print('The engine of entity ' .. data.entity .. ' looks fine!')
            end
        }
    })
    ```

### RemoveLocalEntity / RemoveEntityTarget
Removes interaction options from a specific entity.

*   **Arguments:**
    *   `entity` (`number`): The network ID of the entity.
    *   `labels` (`string` or `table`, optional): The label(s) of the options to remove. If nil, removes all.

*   **Example:**
    ```lua
    exports.tufan:RemoveLocalEntity(myCar, 'Check Engine')
    ```

### AddModel / AddModelTarget
Adds interaction options to all spawned entities with a given model.

*   **Arguments:**
    *   `model` (`string` or `number` or `table`): A model name, hash, or a table of names/hashes.
    *   `options` (`table`): A table of interaction options.

*   **Example:**
    ```lua
    exports.tufan:AddModel('prop_atm_01', {
        {
            label = 'Use ATM',
            icon = 'fas fa-credit-card',
            distance = 1.5,
            onSelect = function()
                print('ATM functionality would go here.')
            end
        }
    })
    ```

### SetBoneTarget
Adds interaction options to a specific bone (or bones) of an entity.

*   **Arguments:**
    *   `entity` (`number`): The network ID of the entity.
    *   `bones` (`table`): For `ox_target`, a table mapping bone names to options. For `qb-target`, a simple array of bone names. The script converts automatically.

*   **Example (Universal):**
    ```lua
    -- This format works for both systems.
    -- On QB, both bones will share the same options.
    exports.tufan:SetBoneTarget(myCar, {
        ['wheel_lf'] = {
            {
                label = 'Check Tire',
                icon = 'fas fa-tire',
                onSelect = function() print('This tire is fine.') end
            }
        },
        ['wheel_rf'] = {
            {
                label = 'Check Tire',
                icon = 'fas fa-tire',
                onSelect = function() print('This tire is fine.') end
            }
        }
    })
    ```

### RemoveBoneTarget
Removes interaction options from an entity's bone(s).

*   **Arguments:**
    *   `entity` (`number`): The network ID of the entity.
    *   `bones` (`string` or `table`): A single bone name or a table of bone names to clear.

---

## Utility Functions

### IsTargeting
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Returns `true` if the player is currently aiming at any valid target.

### GetNearbyEntities
<span style="color:orange; font-weight:bold;">(ox_target ONLY)</span> Returns a table of nearby targeted entities.