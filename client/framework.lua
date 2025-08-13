local Framework = {}

-- Detect which framework is running
if GetResourceState('es_extended') == 'started' then
    Framework.ESX = exports.es_extended:getSharedObject()
elseif GetResourceState('qb-core') == 'started' then
    Framework.QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('ox_core') == 'started' then
    Framework.Ox = require '@ox_core.lib.init'
elseif GetResourceState('qbx_core') == 'started' then
    Framework.QBX = exports['qbx_core']
else
    error('No compatible framework resource is started on the server.')
end

-- Core functions
function Framework.bridgeNotify(msg, type, duration)
    if Framework.ESX then
        Framework.ESX.ShowNotification(msg, type, duration)
    elseif Framework.QBCore then
        Framework.QBCore.Functions.Notify(msg, 'primary', duration)
    elseif Framework.Ox then
        lib.notify({ description = msg, type = type, duration = duration })
    elseif Framework.QBX then
        Framework.QBX:Notify(msg, 'primary', duration)
    end
end

function Framework.GetPlayerGroups()
    if Framework.ESX then
        return PlayerData.job.name, false
    elseif Framework.QBCore or Framework.QBX then
        local Player = Framework.QBCore and Framework.QBCore.Functions.GetPlayerData() or Framework.QBX:GetPlayerData()
        return Player.job.name, Player.gang.name
    elseif Framework.Ox then
        return Framework.Ox.GetPlayer().get('activeGroup'), false
    end
end

function Framework.GetPlayerGroupInfo(job)
    if Framework.ESX then
        local playerData = Framework.ESX.GetPlayerData()
        return {
            name = playerData.job.name,
            grade = playerData.job.grade,
            label = playerData.job.label
        }
    elseif Framework.QBCore or Framework.QBX then
        local Player = Framework.QBCore and Framework.QBCore.Functions.GetPlayerData() or Framework.QBX:GetPlayerData()
        if job then
            return {
                name = Player.job.name,
                grade = Player.job.grade.level,
                label = Player.job.label
            }
        else
            return {
                name = Player.gang.name,
                grade = Player.gang.grade.level,
                label = Player.gang.label
            }
        end
    elseif Framework.Ox then
        local activeGroup = Framework.Ox.GetPlayer().get('activeGroup')
        return {
            name = activeGroup,
            grade = Framework.Ox.GetPlayer().getGroup(activeGroup),
            label = Framework.Ox.GetGroup(activeGroup).label
        }
    end
end

function Framework.GetSex()
    if Framework.ESX then
        local playerData = Framework.ESX.GetPlayerData()
        return playerData.sex == 'Male' and 1 or 2
    elseif Framework.QBCore then
        local Player = Framework.QBCore.Functions.GetPlayerData()
        return Player.charinfo.gender
    elseif Framework.Ox then
        return Framework.Ox.GetPlayer().get('gender') == 'male' and 1 or 2
    elseif Framework.QBX then
        local Player = Framework.QBX:GetPlayerData()
        return Player.charinfo.gender
    end
end

function Framework.IsDead()
    if Framework.ESX then
        return isDead
    elseif Framework.QBCore then
        return Framework.QBCore.Functions.GetPlayerData().metadata.isdead
    elseif Framework.Ox then
        return isDead
    elseif Framework.QBX then
        return Framework.QBX:GetPlayerData().metadata.isdead
    end
end

-- Improved version of GetConvertedClothes based on the working code
local function GetConvertedClothes(oldClothes)
    local clothes = {
        mask = {item = oldClothes.mask_1 or 0, texture = oldClothes.mask_2 or 0},
        arms = {item = oldClothes.arms or 0, texture = 0},
        tshirt = {item = oldClothes.tshirt_1 or 0, texture = oldClothes.tshirt_2 or 0},
        torso = {item = oldClothes.torso_1 or 0, texture = oldClothes.torso_2 or 0},
        torso2 = {item = oldClothes.decals_1 or 0, texture = oldClothes.decals_2 or 0},
        pants = {item = oldClothes.pants_1 or 0, texture = oldClothes.pants_2 or 0},
        shoes = {item = oldClothes.shoes_1 or 0, texture = oldClothes.shoes_2 or 0},
        bag = {item = oldClothes.bags_1 or 0, texture = oldClothes.bags_2 or 0},
        hat = {item = oldClothes.helmet_1 or -1, texture = oldClothes.helmet_2 or 0},
        glass = {item = oldClothes.glasses_1 or 0, texture = oldClothes.glasses_2 or 0},
        ear = {item = oldClothes.ears_1 or 0, texture = oldClothes.ears_2 or 0},
        watch = {item = oldClothes.watches_1 or 0, texture = oldClothes.watches_2 or 0},
        bracelet = {item = oldClothes.bracelets_1 or 0, texture = oldClothes.bracelets_2 or 0},
        accessory = {item = oldClothes.chain_1 or 0, texture = oldClothes.chain_2 or 0},
        vest = {item = oldClothes.bproof_1 or 0, texture = oldClothes.bproof_2 or 0}
    }
    
    return {
        outfitData = clothes,
        model = GetEntityModel(PlayerPedId())
    }
end

function Framework.SetOutfit(outfit)
    if Framework.ESX then
        if outfit then
            Framework.ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('skinchanger:loadClothes', skin, outfit)
            end)
        else
            Framework.ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
        end
    elseif Framework.QBCore then
        if outfit then
            local converted = GetConvertedClothes(outfit)
            TriggerEvent('qb-clothing:client:loadOutfit', converted)
        else
            TriggerServerEvent("qb-clothes:loadPlayerSkin")
        end
    elseif Framework.QBX then
        if outfit then
            local converted = GetConvertedClothes(outfit)
            exports['qb-clothing']:setOutfit(converted)
        else
            TriggerServerEvent("qb-clothes:loadPlayerSkin")
        end
    elseif Framework.Ox then
        -- OX Core implementation
        if outfit then
            local ped = PlayerPedId()
            for component, data in pairs(GetConvertedClothes(outfit).outfitData) do
                SetPedComponentVariation(ped, Config.Components[component], data.item, data.texture, 0)
            end
        else
            TriggerServerEvent('ox_appearance:loadOutfit', 'default')
        end
    end
end
-- Public surface
local TufanFramework = {
    bridgeNotify = Framework.bridgeNotify,
    GetPlayerGroups = Framework.GetPlayerGroups,
    GetPlayerGroupInfo = Framework.GetPlayerGroupInfo,
    GetSex = Framework.GetSex,
    IsDead = Framework.IsDead,
    SetOutfit = Framework.SetOutfit
}

-- Exports for other resources (client-side)
exports('bridgeNotify', Framework.bridgeNotify)
exports('GetPlayerGroups', Framework.GetPlayerGroups)
exports('GetPlayerGroupInfo', Framework.GetPlayerGroupInfo)
exports('GetSex', Framework.GetSex)
exports('IsDead', Framework.IsDead)
exports('SetOutfit', Framework.SetOutfit)

-- Return module
return TufanFramework