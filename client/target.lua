--[[
================================================================================
-- Universal Targeting Compatibility Layer
--
-- Author: Gemini
-- Version: 1.0
--
-- Description:
-- A comprehensive script to provide a unified API for both 'ox_target' and
-- 'qb-target'. Write your targeting logic once and have it work everywhere.
-- This script uses the ox_target API as the standard.
--
-- Documentation Links:
-- ox_target: https://overextended.dev/ox_target/Functions/Client
-- qb-target: https://docs.qbcore.org/qbcore-documentation/qbcore-resources/qb-target
================================================================================
]]

-- Configuration table
Config = {
    TargetSystem = "auto", -- "auto", "ox", or "qb". Auto-detection is recommended.
    Debug = true,         -- Set to true for helpful debug prints in the F8 console.
    DefaultDistance = 2.5  -- Default interaction distance for QB-Target conversions.
}

-- Auto-detect the active target system
if Config.TargetSystem == "auto" then
    if GetResourceState('ox_target') == 'started' then
        Config.TargetSystem = "ox"
        if Config.Debug then print("^2[Targeting]^7 ox_target detected and enabled.") end
    elseif GetResourceState('qb-target') == 'started' then
        Config.TargetSystem = "qb"
        if Config.Debug then print("^2[Targeting]^7 qb-target detected and enabled.") end
    else
        print("^1[ERROR]^7 No supported target system found! Please install and start ox_target or qb-target.")
        Config.TargetSystem = nil -- Disable targeting to prevent errors
    end
end

--[[
================================================================================
-- Helper Functions
================================================================================
]]

--- Converts generic/ox_target style options to the qb-target format.
---@param options table The generic options table.
---@return table The qb-target compatible options table.
local function convertOptionsToQB(options)
    local qbOptions = {}
    if not options then return qbOptions end

    for _, v in ipairs(options) do
        table.insert(qbOptions, {
            icon = v.icon or 'fas fa-hand-pointer',
            label = v.label or 'Interact',
            action = v.onSelect or v.action or function()
                if Config.Debug then print("^3[Targeting]^7 'onSelect' or 'action' function not provided for an option.") end
            end,
            canInteract = v.canInteract,
            -- Map ox_target specific events to QB if possible (often handled differently)
            -- onLeave = v.onLeave (no direct equivalent in QB options)
        })
    end
    return qbOptions
end

--- Prints a warning for functions that are only supported by ox_target.
---@param funcName string The name of the function that was called.
local function printOxOnlyWarning(funcName)
    if Config.Debug then
        print(("^3[Targeting]^7 The function ^5%s^7 is only supported by ^2ox_target^7 and will do nothing on this server."):format(funcName))
    end
end

--[[
================================================================================
-- Zone Targeting Exports
================================================================================
]]

--- Adds a box-shaped interaction zone.
---@param data table Zone data: name, coords, size, options, rotation?, debug?, distance?
function AddBoxZone(data)
    if not Config.TargetSystem then return end
    if not data.name then return print("^1[ERROR]^7 AddBoxZone requires a unique 'name'.") end

    if Config.TargetSystem == "ox" then
        exports.ox_target:addBoxZone(data)
    elseif Config.TargetSystem == "qb" then
        local qbOptions = convertOptionsToQB(data.options)
        local size = data.size or vec3(1.0, 1.0, 1.0)
        local minZ = data.coords.z - (size.z / 2)
        local maxZ = data.coords.z + (size.z / 2)

        exports['qb-target']:AddBoxZone(data.name, data.coords, size.x, size.y, {
            name = data.name,
            heading = data.rotation or 0.0,
            debugPoly = data.debug or false,
            minZ = minZ,
            maxZ = maxZ
        }, {
            options = qbOptions,
            distance = data.distance or Config.DefaultDistance
        })
    end
end

--- Adds a circle-shaped interaction zone.
---@param data table Zone data: name, coords, radius, options, debug?, useZ?, distance?
function AddCircleZone(data)
    if not Config.TargetSystem then return end
    if not data.name then return print("^1[ERROR]^7 AddCircleZone requires a unique 'name'.") end

    if Config.TargetSystem == "ox" then
        exports.ox_target:addCircleZone(data)
    elseif Config.TargetSystem == "qb" then
        local qbOptions = convertOptionsToQB(data.options)
        exports['qb-target']:AddCircleZone(data.name, data.coords, data.radius, {
            name = data.name,
            debugPoly = data.debug or false,
            useZ = data.useZ or false -- qb-target uses this to check Z coord
        }, {
            options = qbOptions,
            distance = data.distance or Config.DefaultDistance
        })
    end
end

--- Adds a poly-shaped interaction zone. (ox_target ONLY)
---@param data table Zone data with points.
function AddPolyZone(data)
    if not Config.TargetSystem then return end
    if Config.TargetSystem == "ox" then
        exports.ox_target:addPolyZone(data)
    else
        printOxOnlyWarning('AddPolyZone')
    end
end

--- Removes an interaction zone by its unique name.
---@param name string The name of the zone to remove.
function RemoveZone(name)
    if not Config.TargetSystem then return end
    if not name then return print("^1[ERROR]^7 RemoveZone requires a 'name'.") end

    if Config.TargetSystem == "ox" then
        exports.ox_target:removeZone(name)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveZone(name)
    end
end

--[[
================================================================================
-- Entity, Model, and Bone Targeting
================================================================================
]]

--- Adds a target to a specific entity handle.
---@param entity number The entity handle.
---@param options table The interaction options.
function AddLocalEntity(entity, options)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:addLocalEntity(entity, options)
    elseif Config.TargetSystem == "qb" then
        local qbOptions = convertOptionsToQB(options)
        exports['qb-target']:AddTargetEntity(entity, { options = qbOptions, distance = Config.DefaultDistance })
    end
end

--- Removes a target from a specific entity handle.
---@param entity number The entity handle.
---@param labels? string | string[] The labels of the options to remove (required for qb-target).
function RemoveLocalEntity(entity, labels)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:removeLocalEntity(entity, labels)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveTargetEntity(entity, labels)
    end
end

--- Adds a target to all entities of a specific model.
---@param model any The model hash(es) or name(s).
---@param options table The interaction options.
function AddModel(model, options)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:addModel(model, options)
    elseif Config.TargetSystem == "qb" then
        local qbOptions = convertOptionsToQB(options)
        exports['qb-target']:AddTargetModel(model, { options = qbOptions, distance = Config.DefaultDistance })
    end
end

--- Removes a target from a model.
---@param model any The model hash(es) or name(s).
---@param labels? string | string[] The labels of the options to remove.
function RemoveModel(model, labels)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:removeModel(model, labels)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveTargetModel(model, labels)
    end
end

--- Adds targeting options to specific bones of an entity.
---@param entity number The entity handle.
---@param bones table A table where keys are bone names and values are option tables.
function SetBoneTarget(entity, bones)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:setBone(entity, bones)
    elseif Config.TargetSystem == "qb" then
        -- qb-target supports an array of bones with a single set of options.
        -- We will convert the ox_target format to this.
        local boneNames = {}
        local qbOptions = {}
        local hasSetOptions = false

        for bone, options in pairs(bones) do
            table.insert(boneNames, bone)
            if not hasSetOptions and options then
                qbOptions = convertOptionsToQB(options)
                hasSetOptions = true
            end
        end

        if #boneNames > 0 then
            exports['qb-target']:AddTargetBone(entity, boneNames, { options = qbOptions, distance = Config.DefaultDistance })
        end
    end
end

--- Removes targeting from specific entity bones.
---@param entity number The entity handle.
---@param bones string | string[] A single bone name or an array of bone names.
function RemoveBoneTarget(entity, bones)
    if not Config.TargetSystem then return end

    if Config.TargetSystem == "ox" then
        exports.ox_target:removeBone(entity, bones)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveTargetBone(entity, bones)
    end
end

--[[
================================================================================
-- Aliases for Common Naming Conventions
================================================================================
]]

-- Common qbcore/older script naming conventions
AddEntityTarget = AddLocalEntity
RemoveEntityTarget = RemoveLocalEntity
AddModelTarget = AddModel
RemoveModelTarget = RemoveModel
AddTargetBone = SetBoneTarget
RemoveTargetBone = RemoveBoneTarget

--[[
================================================================================
-- ox_target Specific Utility Functions
================================================================================
]]

--- Checks if the player is currently aiming at any target. (ox_target ONLY)
---@return boolean
function IsTargeting()
    if Config.TargetSystem == "ox" then
        return exports.ox_target:isTargeting()
    end
    printOxOnlyWarning('IsTargeting')
    return false
end

--- Gets nearby targeted entities. (ox_target ONLY)
---@return table
function GetNearbyEntities(...)
    if Config.TargetSystem == "ox" then
        return exports.ox_target:getNearbyEntities(...)
    end
    printOxOnlyWarning('GetNearbyEntities')
    return {}
end


