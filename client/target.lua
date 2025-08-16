-- Tufan Target Bridge
-- Supports ox_target & qb-target (auto-priority: ox > qb). Minimal, cleaned version.
-- Added interact backend (auto-priority: ox > qb > interact)

-- Optional config override (set this before loading file)
Config = Config or {}
Config.TargetSystem = Config.TargetSystem or 'auto' -- 'auto' | 'ox' | 'qb' | 'interact' | 'disabled'
Config.Tufan = Config.Tufan or { Debug = false }

local function dbg(...)
    if Config.Tufan.Debug then print("^3[Tufan:Target]^0", ...) end
end

-- Storage for interact ids so we can remove them later
local interactEntities = {}
local interactZones = {}

-- Auto-detect Target System
if Config.TargetSystem == "auto" then
    if GetResourceState('ox_target') == 'started' then
        Config.TargetSystem = "ox"
    elseif GetResourceState('qb-target') == 'started' then
        Config.TargetSystem = "qb"
    elseif GetResourceState('interact') == 'started' then
        Config.TargetSystem = "interact"
    else
        print("^1[ERROR]^0 No supported target system found! (ox_target / qb-target / interact)")
        Config.TargetSystem = nil -- Disable targeting functions
    end
end

-- Helper: normalize option shape & add onSelect for ox_target
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
    if not Config.TargetSystem then return end
    dbg('addTarget entity', entity)
    local normalizedOptions = normalizeOptions(options)
    if Config.TargetSystem == "ox" then
        dbg('backend ox')
        exports.ox_target:addLocalEntity(entity, normalizedOptions)
    elseif Config.TargetSystem == "qb" then
        dbg('backend qb')
        local qbOptions = {}
        for _, opt in ipairs(normalizedOptions) do
            -- Build unified canInteract for qb-target if job/gang/item filters provided
            local optCan = opt.canInteract
            if (opt.job or opt.gang or opt.item) then
                optCan = function(ent)
                    if opt.canInteract and opt.canInteract(ent) == false then return false end
                    local playerData
                    if GetResourceState('qb-core') == 'started' then
                        local qb = exports['qb-core']:GetCoreObject()
                        playerData = qb and qb.Functions.GetPlayerData() or LocalPlayer.state.PlayerData
                    else
                        playerData = LocalPlayer.state.PlayerData
                    end
                    if not playerData then return false end
                    if opt.job then
                        if type(opt.job) == 'string' then
                            if playerData.job.name ~= opt.job then return false end
                        elseif type(opt.job) == 'table' then
                            local minGrade = opt.job[playerData.job.name]
                            if minGrade and (playerData.job.grade.level or playerData.job.grade) < minGrade then return false end
                            if not minGrade and not opt.job[playerData.job.name] then return false end
                        end
                    end
                    if opt.gang then
                        if type(opt.gang) == 'string' then
                            if playerData.gang.name ~= opt.gang then return false end
                        elseif type(opt.gang) == 'table' then
                            local minG = opt.gang[playerData.gang.name]
                            if minG and (playerData.gang.grade.level or playerData.gang.grade) < minG then return false end
                            if not minG and not opt.gang[playerData.gang.name] then return false end
                        end
                    end
                    if opt.item then
                        local items = type(opt.item) == 'table' and opt.item or { opt.item }
                        local found = false
                        for i=1,#items do
                            if exports.tufan and exports.tufan:HasItem(items[i]) > 0 then
                                found = true
                                break
                            end
                        end
                        if not found then return false end
                    end
                    return true
                end
            end
            table.insert(qbOptions, {
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                job = opt.job,
                gang = opt.gang,
                item = opt.item,
                canInteract = optCan,
                distance = opt.distance
            })
        end
        exports['qb-target']:AddTargetEntity(entity, {
            options = qbOptions,
            distance = 2.0
        })
    elseif Config.TargetSystem == "interact" then
        dbg('backend interact')
        -- Wrap each option's canInteract to include job/gang/item filters similar to qb branch
        for _, opt in ipairs(normalizedOptions) do
            local baseCan = opt.canInteract
            if (opt.job or opt.gang or opt.item) then
                opt.canInteract = function(ent, coords, args)
                    if baseCan and baseCan(ent, coords, args) == false then return false end
                    local playerData
                    if GetResourceState('qb-core') == 'started' then
                        local qb = exports['qb-core']:GetCoreObject()
                        playerData = qb and qb.Functions.GetPlayerData()
                    end
                    -- If no playerData (different framework) skip strict checks except items
                    if playerData then
                        if opt.job then
                            if type(opt.job) == 'string' then
                                if playerData.job.name ~= opt.job then return false end
                            elseif type(opt.job) == 'table' then
                                local minGrade = opt.job[playerData.job.name]
                                if not minGrade then return false end
                                local grade = playerData.job.grade.level or playerData.job.grade or 0
                                if grade < minGrade then return false end
                            end
                        end
                        if opt.gang then
                            if type(opt.gang) == 'string' then
                                if playerData.gang.name ~= opt.gang then return false end
                            elseif type(opt.gang) == 'table' then
                                local minG = opt.gang[playerData.gang.name]
                                if not minG then return false end
                                local gGrade = playerData.gang.grade.level or playerData.gang.grade or 0
                                if gGrade < minG then return false end
                            end
                        end
                    end
                    if opt.item then
                        local items = type(opt.item) == 'table' and opt.item or { opt.item }
                        local found = false
                        for i=1,#items do
                            if exports.tufan and exports.tufan:HasItem(items[i]) > 0 then
                                found = true
                                break
                            end
                        end
                        if not found then return false end
                    end
                    return true
                end
            end
        end
        -- Choose distances: detection radius = max option distance + 2, interact = min distance
        local maxDist, minDist = 0, 999
        for _, opt in ipairs(normalizedOptions) do
            local d = opt.distance or 2.0
            if d > maxDist then maxDist = d end
            if d < minDist then minDist = d end
        end
        local id = ('tufan_ent_%s'):format(entity)
        exports.interact:AddLocalEntityInteraction({
            entity = entity,
            id = id,
            name = id,
            distance = math.max(4.0, maxDist + 2.0),
            interactDst = minDist,
            options = normalizedOptions
        })
        interactEntities[entity] = id
    else
    dbg('no valid targeting backend (addTarget ignored)')
    end
end

function removeTarget(entity, name)
    if Config.TargetSystem == "ox" then
        exports.ox_target:removeLocalEntity(entity, name)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveTargetEntity(entity, name)
    elseif Config.TargetSystem == "interact" then
        local id = name or interactEntities[entity]
        if id then
            exports.interact:RemoveLocalEntityInteraction(entity, id)
            if not name then interactEntities[entity] = nil end
        end
    end
end

function addBoxZone(data)
    if not Config.TargetSystem then return end
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
            local optCan = opt.canInteract
            if (opt.job or opt.gang or opt.item) then
                optCan = function(ent)
                    if opt.canInteract and opt.canInteract(ent) == false then return false end
                    local playerData
                    if GetResourceState('qb-core') == 'started' then
                        local qb = exports['qb-core']:GetCoreObject()
                        playerData = qb and qb.Functions.GetPlayerData() or LocalPlayer.state.PlayerData
                    else
                        playerData = LocalPlayer.state.PlayerData
                    end
                    if not playerData then return false end
                    if opt.job then
                        if type(opt.job) == 'string' then
                            if playerData.job.name ~= opt.job then return false end
                        elseif type(opt.job) == 'table' then
                            local minGrade = opt.job[playerData.job.name]
                            if minGrade and (playerData.job.grade.level or playerData.job.grade) < minGrade then return false end
                            if not minGrade and not opt.job[playerData.job.name] then return false end
                        end
                    end
                    if opt.gang then
                        if type(opt.gang) == 'string' then
                            if playerData.gang.name ~= opt.gang then return false end
                        elseif type(opt.gang) == 'table' then
                            local minG = opt.gang[playerData.gang.name]
                            if minG and (playerData.gang.grade.level or playerData.gang.grade) < minG then return false end
                            if not minG and not opt.gang[playerData.gang.name] then return false end
                        end
                    end
                    if opt.item then
                        local items = type(opt.item) == 'table' and opt.item or { opt.item }
                        local found = false
                        for i=1,#items do
                            if exports.tufan and exports.tufan:HasItem(items[i]) > 0 then
                                found = true
                                break
                            end
                        end
                        if not found then return false end
                    end
                    return true
                end
            end
            table.insert(qbOptions, {
                icon = opt.icon,
                label = opt.label,
                action = opt.action,
                job = opt.job,
                gang = opt.gang,
                item = opt.item,
                canInteract = optCan,
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
    elseif Config.TargetSystem == "interact" then
        -- Interact does not support 3D box volume natively; approximate with center point.
        -- Use largest side as detection distance.
        local size = data.size or vec3(2.0,2.0,2.0)
        local biggest = math.max(size.x or 2.0, size.y or 2.0, size.z or 2.0)
        local maxDist, minDist = 0, 999
        for _, opt in ipairs(normalizedOptions) do
            local d = opt.distance or 2.0
            if d > maxDist then maxDist = d end
            if d < minDist then minDist = d end
        end
        local id = data.name or ('tufan_zone_'..math.random(10000,99999))
        exports.interact:AddInteraction({
            id = id,
            name = id,
            coords = data.coords,
            distance = math.max(biggest + 2.0, maxDist + 2.0),
            interactDst = minDist,
            options = normalizedOptions
        })
        interactZones[id] = true
    end
end

function removeZone(name)
    if Config.TargetSystem == "ox" then
        exports.ox_target:removeZone(name)
    elseif Config.TargetSystem == "qb" then
        exports['qb-target']:RemoveZone(name)
    elseif Config.TargetSystem == "interact" then
        local id = name
        if interactZones[id] then
            exports.interact:RemoveInteraction(id)
            interactZones[id] = nil
        end
    end
end

-- (Legacy TufanTarget table removed)

-- Exports for other resources (client-side)
exports('addTarget', addTarget)
exports('removeTarget', removeTarget)
exports('addBoxZone', addBoxZone)
exports('removeZone', removeZone)
-- No module return needed (exports are sufficient)