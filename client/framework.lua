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
function Framework.Notify(msg, type, duration)
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
-- Public surface
local TufanFramework = {
    Notify = Framework.Notify,
    GetPlayerGroups = Framework.GetPlayerGroups,
    GetPlayerGroupInfo = Framework.GetPlayerGroupInfo,
    GetSex = Framework.GetSex,
    IsDead = Framework.IsDead
}

-- Exports for other resources (client-side)
exports('Notify', Framework.Notify)
exports('GetPlayerGroups', Framework.GetPlayerGroups)
exports('GetPlayerGroupInfo', Framework.GetPlayerGroupInfo)
exports('GetSex', Framework.GetSex)
exports('IsDead', Framework.IsDead)

-- Return module
return TufanFramework