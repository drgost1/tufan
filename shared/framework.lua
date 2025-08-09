framework = nil
coreObject = nil
tufan = {}
local function InitializeCoreObject()
    if GetResourceState('qb-core') == 'started' then
        coreObject = exports['qb-core']:GetCoreObject()
        framework = 'QB'
        print('Core object for QB initialized.')
    elseif GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:getSharedObject', function(obj) coreObject = obj end)
        framework = 'ESX'
        print('Core object for ESX initialized.')
    elseif GetResourceState('qbx-core') == 'started' then
        -- Adjust according to how QBX exposes its core object
        coreObject = exports['qbx_core']
        framework = 'QBX'
        print('Core object for QBX initialized.')
    else
        print('No supported framework resource is active.')
    end
end






-- Call once during resource start or initialization
CreateThread(function()
    InitializeCoreObject()
    -- You now have coreObject and framework variables to use elsewhere
end)