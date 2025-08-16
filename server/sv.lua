



-- Do NOT add a parameter to the handler unless you pass it from the client.
-- The implicit global 'source' inside the callback is the player's id.
RegisterNetEvent('tt', function()
    local src = source
    local cid = exports.tufan:GetIdentifier(src)
    local name = exports.tufan:GetName(src)
    local jobInfo = exports.tufan:GetPlayerJobInfo(src)
    local gangInfo = exports.tufan:GetPlayerGangInfo(src)
    local uid = GetIdentifier(src)

    print('Player ID:', cid)
    print('Player Name:', name)
    print('Player Job Info:', json.encode(jobInfo))
    print('Player Gang Info:', json.encode(gangInfo))
    print('Player License:', uid)
end)

-- Example client side trigger (run after spawn):
-- TriggerServerEvent('test')