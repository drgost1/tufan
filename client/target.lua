-- Tufan Target Bridge (single file, simplified)
-- Drop in client_scripts and call the functions below.
-- Supports ox_target, qb-target, interact (priority: ox > qb > interact)

local activeTargets = {}  -- registry for cleanup
local BACKEND = nil       -- 'ox' | 'qb' | 'interact' | nil

-- Optional config override (set this before loading file)
Config = Config or {}
Config.TargetSystem = Config.TargetSystem or 'auto' -- 'auto' | 'ox' | 'qb' | 'interact' | 'disabled'
Config.Tufan = Config.Tufan or { Debug = false }

local function dbg(...)
    if Config.Tufan.Debug then print("^3[Tufan:Target]^0", ...) end
end

local function active(res)
    local st = GetResourceState(res)
    return st == 'started' or st == 'starting'
end

local function detectBackend()
    if Config.TargetSystem == 'disabled' then return nil end
    if Config.TargetSystem == 'ox' or (Config.TargetSystem == 'auto' and active('ox_target')) then return 'ox' end
    if Config.TargetSystem == 'qb' or (Config.TargetSystem == 'auto' and active('qb-target')) then return 'qb' end
    if Config.TargetSystem == 'interact' or (Config.TargetSystem == 'auto' and active('interact')) then return 'interact' end
    return nil
end

-- Convert helpers (accepts either { options = {...}, distance = X } or just { ... } array)
local function getOptionsArray(params)
    if not params then return {} end
    if params.options and type(params.options) == 'table' then return params.options end
    if type(params[1]) == 'table' then return params end
    return {}
end

local function convertToOx(params)
    local opts = getOptionsArray(params)
    local dist = params and params.distance or nil
    local out = {}
    for i, v in ipairs(opts) do
        local o = {}
        o.label = v.label
        o.icon = v.icon
        o.name = v.name or v.label or ('tufan_opt_' .. i)
        o.onSelect = v.onSelect or v.action
        o.distance = v.distance or dist
        o.canInteract = v.canInteract
        -- Map job/gang/groups to ox groups
        o.groups = v.groups or v.job or v.gang
        o.items = v.items
        o.bones = v.bones
        o.qtarget = true -- marker that it was mapped
        out[i] = o
    end
    return out
end

local function convertToQB(params)
    local opts = getOptionsArray(params)
    local out = {}
    for i, v in ipairs(opts) do
        out[i] = {
            icon = v.icon or 'fas fa-circle',
            label = v.label or ('Action ' .. i),
            action = v.action or v.onSelect,
            canInteract = v.canInteract,
            item = v.item or v.items,
            job = v.job,
            gang = v.gang,
            distance = v.distance or params.distance or 2.0,
            name = v.name or ('tufan_opt_' .. i)
        }
    end
    return { options = out, distance = params.distance or 2.0 }
end

local function convertToInteract(params)
    local opts = getOptionsArray(params)
    local out = {}
    for i, v in ipairs(opts) do
        out[i] = {
            icon = v.icon,
            label = v.label or ('Action ' .. i),
            action = v.action or v.onSelect,
            canInteract = v.canInteract,
            name = v.name or ('tufan_opt_' .. i),
            groups = v.groups or v.job or v.gang
        }
    end
    return out
end

-- Resolve current backend (and keep watching)
CreateThread(function()
    local prev = nil
    while true do
        BACKEND = detectBackend()
        if prev ~= BACKEND then
            dbg(("Backend: %s -> %s"):format(tostring(prev), tostring(BACKEND)))
            if not BACKEND then
                print("^1[Tufan:Target]^0 No supported target found (ox_target / qb-target / interact).")
            end
            prev = BACKEND
        end
        Wait(3000)
    end
end)

-- Cleanup on resource stop (removes only entries added by that resource)
local function resourceStopped(resource)
    for key, t in pairs(activeTargets) do
        if t.invokingResource == resource then
            if t.backend == 'ox' then
                if t.type == 'zone' and t.id then
                    exports.ox_target:removeZone(t.id)
                elseif t.type == 'entity' and t.entity and DoesEntityExist(t.entity) then
                    exports.ox_target:removeLocalEntity(t.entity)
                elseif t.type == 'globalPed' then
                    -- ox_target expects list of option names
                    local names = {}
                    if t.options then
                        for i, op in ipairs(t.options) do names[i] = op.name or op.label end
                    end
                    exports.ox_target:removeGlobalPed(names)
                end

            elseif t.backend == 'qb' then
                if t.type == 'zone' and t.id then
                    exports['qb-target']:RemoveZone(t.id)
                elseif t.type == 'entity' and t.entity and DoesEntityExist(t.entity) then
                    exports['qb-target']:RemoveTargetEntity(t.entity)
                elseif t.type == 'globalPed' then
                    -- qb-target removes by label list (type 1 = ped)
                    local labels = {}
                    if t.options and t.options.options then
                        for i, op in ipairs(t.options.options) do labels[i] = op.label end
                    end
                    exports['qb-target']:RemoveGlobalType(1, labels)
                elseif t.type == 'globalObject' then
                    local labels = {}
                    if t.options and t.options.options then
                        for i, op in ipairs(t.options.options) do labels[i] = op.label end
                    end
                    exports['qb-target']:RemoveGlobalType(3, labels)
                end

            elseif t.backend == 'interact' then
                if t.type == 'zone' and t.id then
                    exports.interact:RemoveInteraction(t.id)
                elseif t.type == 'entity' and t.entity and t.id then
                    exports.interact:RemoveLocalEntityInteraction(t.entity, t.id)
                elseif t.type == 'globalPed' and t.id then
                    exports.interact:RemoveGlobalPlayerInteraction(t.id)
                end
            end
            activeTargets[key] = nil
        end
    end
end

AddEventHandler('onResourceStop', resourceStopped)

-- ======================
-- Simplified public API
-- ======================

local function AddTargetEntity(entity, params)
    local backend = BACKEND
    if not backend then return false, 'No target backend available' end
    local inv = GetInvokingResource()

    if backend == 'ox' then
        exports.ox_target:addLocalEntity(entity, convertToOx(params or {}))
        activeTargets[entity] = { backend = 'ox', type = 'entity', entity = entity, invokingResource = inv }
        return true
    elseif backend == 'qb' then
        exports['qb-target']:AddTargetEntity(entity, convertToQB(params or {}))
        activeTargets[entity] = { backend = 'qb', type = 'entity', entity = entity, invokingResource = inv }
        return true
    elseif backend == 'interact' then
        -- Not supported by upstream interact yet
        return false, 'AddTargetEntity not supported for interact'
    end
    return false, 'Unsupported backend'
end

local function RemoveTargetEntity(entity)
    local t = activeTargets[entity]
    if not t then
        -- Try best-effort removal using current backend
        if BACKEND == 'ox' then
            if DoesEntityExist(entity) then exports.ox_target:removeLocalEntity(entity) end
            return true
        elseif BACKEND == 'qb' then
            if DoesEntityExist(entity) then exports['qb-target']:RemoveTargetEntity(entity) end
            return true
        elseif BACKEND == 'interact' then
            -- Requires id; cannot reliably remove
            return false, 'Interact removal needs id; not tracked'
        end
        return false, 'No backend'
    end

    if t.backend == 'ox' then
        if DoesEntityExist(entity) then exports.ox_target:removeLocalEntity(entity) end
    elseif t.backend == 'qb' then
        if DoesEntityExist(entity) then exports['qb-target']:RemoveTargetEntity(entity) end
    elseif t.backend == 'interact' then
        if t.id then exports.interact:RemoveLocalEntityInteraction(entity, t.id) end
    end
    activeTargets[entity] = nil
    return true
end

-- name: string; coords: vector3 or vec3 or vec4; size: vector3 {x,y,z}; params: { options={...}, distance, rotation, debug }
local function AddBoxZone(name, coords, size, params)
    local backend = BACKEND
    if not backend then return false, 'No target backend available' end
    params = params or {}
    local inv = GetInvokingResource()

    if backend == 'ox' then
        local id = exports.ox_target:addBoxZone({
            coords = coords,
            size = size,
            rotation = params.rotation or 0.0,
            debug = params.debug or false,
            options = convertToOx(params)
        })
        if Config.Tufan.Debug then print('^3[Tufan:Target]^0 OX Zone Id:', id) end
        activeTargets[name] = { backend = 'ox', type = 'zone', id = id, invokingResource = inv }
        return true
    elseif backend == 'qb' then
        local len = size.x or size[1]
        local wid = size.y or size[2]
        local hei = size.z or size[3] or 2.0
        local minZ = (coords.z or 0.0) - math.max(1.0, hei / 2.0)
        local maxZ = (coords.z or 0.0) + math.max(1.0, hei / 2.0)
        exports['qb-target']:AddBoxZone(name, coords, len, wid, {
            name = name,
            debugPoly = params.debug or false,
            minZ = params.minZ or minZ,
            maxZ = params.maxZ or maxZ,
            heading = params.rotation or coords.w or 0.0
        }, convertToQB(params))
        activeTargets[name] = { backend = 'qb', type = 'zone', id = name, invokingResource = inv }
        return true
    elseif backend == 'interact' then
        exports.interact:AddInteraction({
            coords = coords,
            distance = params.distance or 2.0,
            interactDst = params.distance or 2.0,
            id = name,
            options = convertToInteract(params)
        })
        activeTargets[name] = { backend = 'interact', type = 'zone', id = name, invokingResource = inv }
        return true
    end
    return false, 'Unsupported backend'
end

local function RemoveZone(name)
    local t = activeTargets[name]
    if not t then
        -- Best-effort using current backend
        if BACKEND == 'ox' then
            return false, 'Unknown zone id for ox_target'
        elseif BACKEND == 'qb' then
            exports['qb-target']:RemoveZone(name)
            return true
        elseif BACKEND == 'interact' then
            exports.interact:RemoveInteraction(name)
            return true
        end
        return false, 'No backend'
    end

    if t.backend == 'ox' then
        if t.id then exports.ox_target:removeZone(t.id) end
    elseif t.backend == 'qb' then
        exports['qb-target']:RemoveZone(t.id)
    elseif t.backend == 'interact' then
        exports.interact:RemoveInteraction(t.id)
    end
    activeTargets[name] = nil
    return true
end

local function AddGlobalPed(name, options)
    local backend = BACKEND
    if not backend then return false, 'No target backend available' end
    options = options or {}
    local inv = GetInvokingResource()

    if backend == 'ox' then
        local oxOpts = convertToOx({ options = options })
        exports.ox_target:addGlobalPed(oxOpts)
        activeTargets[name] = { backend = 'ox', type = 'globalPed', id = name, options = oxOpts, invokingResource = inv }
        return true
    elseif backend == 'qb' then
        local qbParams = { options = convertToQB({ options = options }).options }
        exports['qb-target']:AddGlobalPed(qbParams)
        activeTargets[name] = { backend = 'qb', type = 'globalPed', id = name, options = qbParams, invokingResource = inv }
        return true
    elseif backend == 'interact' then
        local iaOpts = convertToInteract({ options = options })
        exports.interact:addGlobalPlayerInteraction({ id = name, options = iaOpts })
        activeTargets[name] = { backend = 'interact', type = 'globalPed', id = name, options = iaOpts, invokingResource = inv }
        return true
    end
    return false, 'Unsupported backend'
end

local function RemoveGlobalPed(name)
    local t = activeTargets[name]
    if not t then
        return false, 'Global ped not tracked'
    end

    if t.backend == 'ox' then
        local names = {}
        if t.options then
            for i, op in ipairs(t.options) do names[i] = op.name or op.label end
        end
        exports.ox_target:removeGlobalPed(names)
    elseif t.backend == 'qb' then
        local labels = {}
        if t.options and t.options.options then
            for i, op in ipairs(t.options.options) do labels[i] = op.label end
        end
        exports['qb-target']:RemoveGlobalType(1, labels)
    elseif t.backend == 'interact' then
        exports.interact:RemoveGlobalPlayerInteraction(t.id)
    end

    activeTargets[name] = nil
    return true
end

-- Public surface
TufanTarget = {
    AddTargetEntity = AddTargetEntity,
    RemoveTargetEntity = RemoveTargetEntity,
    AddBoxZone = AddBoxZone,
    RemoveZone = RemoveZone,
    AddGlobalPed = AddGlobalPed,
    RemoveGlobalPed = RemoveGlobalPed,
    State = function() return BACKEND end
}

-- Back-compat global helpers
function addTarget(entity, params) return AddTargetEntity(entity, params) end
function removeTarget(entity) return RemoveTargetEntity(entity) end
function addBoxZone(name, coords, size, params) return AddBoxZone(name, coords, size, params) end
function removeZone(name) return RemoveZone(name) end

-- Exports for other resources (client-side)
exports('AddTargetEntity', AddTargetEntity)
exports('RemoveTargetEntity', RemoveTargetEntity)
exports('AddBoxZone', AddBoxZone)
exports('RemoveZone', RemoveZone)
exports('AddGlobalPed', AddGlobalPed)
exports('RemoveGlobalPed', RemoveGlobalPed)
exports('State', function() return BACKEND end)
-- Return module (if you load via loadfile/LoadResourceFile)
return TufanTarget