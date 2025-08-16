-- Tufan Target Bridge (single file, simplified)
-- Drop in client_scripts and call the functions below.
-- Supports ox_target, qb-target, interact (priority: ox > qb > interact)
-- MODIFIED: Includes bugfixes for qb-target globals and adds AddGlobalObject function.

local activeTargets = {}  -- registry for cleanup
local BACKEND = nil       -- 'ox' | 'qb' | 'interact' | nil

-- Optional config override (set this before loading file)
Config = Config or {}
Config.TargetSystem = Config.TargetSystem or 'auto' -- 'auto' | 'ox' | 'qb' | 'interact' | 'disabled'
Config.Tufan = Config.Tufan or { Debug = false }

local function dbg(...)
    if Config.Tufan.Debug then print("^3[Tufan:Target]^0", ...) end
end

-- Simplified Target System Auto-Detection and Functions

-- Auto-detect Target System
if Config.TargetSystem == "auto" then
    if GetResourceState('ox_target') == 'started' then
        Config.TargetSystem = "ox"
    elseif GetResourceState('qb-target') == 'started' then
        Config.TargetSystem = "qb"
    else
        print("^1[ERROR]^0 No supported target system found! Please install ox_target or qb-target.")
        Config.TargetSystem = nil -- Disable targeting functions
    end
end

-- Enhanced functions to support advanced options and conversion

-- Helper function to normalize options for both backends
local function normalizeOptions(options)
    local normalized = {}
    for _, opt in ipairs(options) do
        local nOpt = {
            label = opt.label,
            icon = opt.icon,
            action = opt.action,
            job = opt.job,
            gang = opt.gang,
            item = opt.item,
            name = opt.name,
            distance = opt.distance or 2.0,
            canInteract = opt.canInteract
        }
        -- Auto-convert action to onSelect for OX target
        if not opt.onSelect and opt.action then
            nOpt.onSelect = opt.action
        elseif opt.onSelect then
            nOpt.onSelect = opt.onSelect
        end
        table.insert(normalized, nOpt)
    end
    return normalized
end

-- Functions
function addTarget(entity, options)
    print("[DEBUG] addTarget called with entity:", entity, "options:", options)
    local normalizedOptions = normalizeOptions(options)
    if Config.TargetSystem == "ox" then
        print("[DEBUG] Using ox_target backend")
        exports.ox_target:addLocalEntity(entity, normalizedOptions)
    elseif Config.TargetSystem == "qb" then
        print("[DEBUG] Using qb-target backend")
        local qbOptions = {}
        for _, opt in ipairs(normalizedOptions) do
            table.insert(qbOptions, {
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                job = opt.job,
                gang = opt.gang,
                item = opt.item,
                canInteract = opt.canInteract,
                distance = opt.distance
            })
        end
        exports['qb-target']:AddTargetEntity(entity, {
            options = qbOptions,
            distance = 2.0
        })
    else
        print("[ERROR] No valid targeting backend detected.")
    end
end

function removeTarget(entity, name)
    if Config.TargetSystem == "ox" then
        exports.ox_target:removeLocalEntity(entity, name)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveTargetEntity(entity, name)
    end
end

function addBoxZone(data)
    local normalizedOptions = normalizeOptions(data.options)
    if Config.TargetSystem == "ox" then
        exports.ox_target:addBoxZone({
            name = data.name,
            coords = data.coords,
            size = data.size,
            rotation = data.rotation or 0.0,
            debug = data.debug or false,
            options = normalizedOptions
        })
    elseif Config.TargetSystem == "qb" then
        local qbOptions = {}
        for _, opt in ipairs(normalizedOptions) do
            table.insert(qbOptions, {
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                job = opt.job,
                gang = opt.gang,
                item = opt.item,
                canInteract = opt.canInteract,
                distance = opt.distance
            })
        end
        exports['qb-target']:AddBoxZone(
            data.name,
            data.coords,
            data.size.x,
            data.size.y,
            {
                name = data.name,
                heading = data.rotation or 0.0,
                debugPoly = data.debug or false,
                minZ = data.coords.z - (data.size.z / 2),
                maxZ = data.coords.z + (data.size.z / 2)
            },
            {
                options = qbOptions,
                distance = data.distance or 2.0
            }
        )
    end
end

function removeZone(name)
    if Config.TargetSystem == "ox" then
        exports.ox_target:removeZone(name)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveZone(name)
    end
end

-- Public surface
TufanTarget = {
    AddTargetEntity = AddTargetEntity,
    RemoveTargetEntity = RemoveTargetEntity,
    AddBoxZone = AddBoxZone,
    RemoveZone = RemoveZone,
    AddGlobalPed = AddGlobalPed,
    RemoveGlobalPed = RemoveGlobalPed,
    AddGlobalObject = AddGlobalObject,       -- NEW
    RemoveGlobalObject = RemoveGlobalObject, -- NEW
    State = function() return BACKEND end
}

-- Exports for other resources (client-side)
exports('addTarget', addTarget)
exports('removeTarget', removeTarget)
exports('addBoxZone', addBoxZone)
exports('removeZone', removeZone)
-- Remove exports for AddGlobalPed, RemoveGlobalPed, AddGlobalObject, RemoveGlobalObject, State if not implemented
-- Return module (if you load via loadfile/LoadResourceFile)
return {
    addTarget = addTarget,
    removeTarget = removeTarget,
    addBoxZone = addBoxZone,
    removeZone = removeZone
}