-- Unified Server Framework Bridge
-- Auto-detects qb-core, qbx_core, es_extended, ox_core (+ ox_inventory if running)
-- Exposes consistent API via inline exports (no fxmanifest server_exports needed)

local tufan = tufan or {}

local hasQBCore      = GetResourceState('qb-core') == 'started'
local hasQBXCore     = GetResourceState('qbx_core') == 'started'
local hasESX         = GetResourceState('es_extended') == 'started'
local hasOxCore      = GetResourceState('ox_core') == 'started'
local hasOxInventory = GetResourceState('ox_inventory') == 'started'

local ACTIVE = nil

if hasOxCore then
	ACTIVE = 'ox_core'
elseif hasQBXCore then
	ACTIVE = 'qbx_core'
elseif hasQBCore then
	ACTIVE = 'qb-core'
elseif hasESX then
	ACTIVE = 'es_extended'
end

if not ACTIVE then
	print('^1[tufan] No supported framework detected (qb-core / qbx_core / es_extended / ox_core). Server functions will not work.^0')
	return
end

print(('^2[tufan] Detected framework: %s (ox_inventory: %s)^0'):format(ACTIVE, hasOxInventory and 'yes' or 'no'))

-- Cache framework objects
local QBCore, QBX, ESX, Ox
if ACTIVE == 'qb-core' then
	QBCore = exports['qb-core']:GetCoreObject()
elseif ACTIVE == 'qbx_core' then
	QBX = exports['qbx_core']
elseif ACTIVE == 'es_extended' then
	ESX = exports['es_extended']:getSharedObject()
elseif ACTIVE == 'ox_core' then
	Ox = require '@ox_core.lib.init'
end

-- Helper getters per framework
local function getPlayer(src)
	if ACTIVE == 'qb-core' then
		return QBCore.Functions.GetPlayer(src)
	elseif ACTIVE == 'qbx_core' then
		return QBX:GetPlayer(src)
	elseif ACTIVE == 'es_extended' then
		return ESX.GetPlayerFromId(src)
	elseif ACTIVE == 'ox_core' then
		return Ox.GetPlayer(src)
	end
end

-- Identifier
function GetIdentifier(src)
	local p = getPlayer(src)
	if not p then
		-- Optional debug
		-- print(('^1[tufan] GetIdentifier: no player for source %s^0'):format(src))
		return nil
	end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.PlayerData.citizenid
	elseif ACTIVE == 'es_extended' then
		return p.getIdentifier()
	elseif ACTIVE == 'ox_core' then
		return p.getIdentifier()
	end
end
exports('GetIdentifier', GetIdentifier)

-- Name (First + Last)
function GetName(src)
	local p = getPlayer(src)
	if not p then
		-- print(('^1[tufan] GetName: no player for source %s^0'):format(src))
		return nil
	end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		local ci = p.PlayerData.charinfo
		return (ci.firstname or ci.firstName or '') .. ' ' .. (ci.lastname or ci.lastName or '')
	elseif ACTIVE == 'es_extended' then
		return p.getName()
	elseif ACTIVE == 'ox_core' then
		return p.get('firstName') .. ' ' .. p.get('lastName')
	end
end
exports('GetName', GetName)

-- Job Count
function GetJobCount(job)
	if ACTIVE == 'qb-core' then
		local amount = 0
		for _, v in pairs(QBCore.Functions.GetQBPlayers()) do
			if v and v.PlayerData.job.name == job then amount = amount + 1 end
		end
		return amount
	elseif ACTIVE == 'qbx_core' then
		local amount = 0
		for _, v in pairs(QBX:GetQBPlayers()) do
			if v and v.PlayerData.job.name == job then amount = amount + 1 end
		end
		return amount
	elseif ACTIVE == 'es_extended' then
		local players = ESX.GetExtendedPlayers('job', job)
		return type(players) == 'table' and #players or 0
	elseif ACTIVE == 'ox_core' then
		return GlobalState[job .. ':activeCount'] or 0
	end
	return 0
end
exports('GetJobCount', GetJobCount)

-- List players (job, gang/group, source)
function GetPlayers()
	local formatted = {}
	if ACTIVE == 'qb-core' then
		for _, v in pairs(QBCore.Functions.GetQBPlayers()) do
			formatted[#formatted+1] = { job = v.PlayerData.job.name, gang = v.PlayerData.gang.name, source = v.PlayerData.source }
		end
	elseif ACTIVE == 'qbx_core' then
		for _, v in pairs(QBX:GetQBPlayers()) do
			formatted[#formatted+1] = { job = v.PlayerData.job.name, gang = v.PlayerData.gang.name, source = v.PlayerData.source }
		end
	elseif ACTIVE == 'es_extended' then
		for _, v in pairs(ESX.GetExtendedPlayers()) do
			formatted[#formatted+1] = { job = v.getJob().name, gang = false, source = v.source }
		end
	elseif ACTIVE == 'ox_core' then
		for _, v in pairs(Ox.GetPlayers()) do
			formatted[#formatted+1] = { job = v.get('activeGroup'), gang = false, source = v.source }
		end
	end
	return formatted
end
exports('GetPlayers', GetPlayers)

-- Job + Gang/Group raw objects
function GetPlayerGroups(src)
	local p = getPlayer(src)
	if not p then return nil, nil end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.PlayerData.job, p.PlayerData.gang
	elseif ACTIVE == 'es_extended' then
		return p.getJob(), false
	elseif ACTIVE == 'ox_core' then
		return p.get('activeGroup'), false
	end
end
exports('GetPlayerGroups', GetPlayerGroups)

-- Job Info
function GetPlayerJobInfo(src)
	local p = getPlayer(src)
	if not p then return nil end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		local job = p.PlayerData.job
		return { name = job.name, label = job.label, grade = job.grade, gradeName = job.grade.name }
	elseif ACTIVE == 'es_extended' then
		local job = p.getJob()
		return { name = job.name, label = job.label, grade = job.grade, gradeName = job.grade_label }
	elseif ACTIVE == 'ox_core' then
		local activeGroup = p.get('activeGroup')
		local grp = Ox.GetGroup(activeGroup)
		local grade = p.getGroup(activeGroup)
		return { name = grp.name, label = grp.label, grade = grade, gradeName = grp.grades[grade] }
	end
end
exports('GetPlayerJobInfo', GetPlayerJobInfo)

-- Gang Info (only qb/qbx). ox_core & ESX return false
function GetPlayerGangInfo(src)
	local p = getPlayer(src)
	if not p then return nil end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		local gang = p.PlayerData.gang
		return { name = gang.name, label = gang.label, grade = gang.grade, gradeName = gang.grade.name }
	elseif ACTIVE == 'es_extended' or ACTIVE == 'ox_core' then
		return false
	end
end
exports('GetPlayerGangInfo', GetPlayerGangInfo)

-- Date of Birth
function GetDob(src)
	local p = getPlayer(src)
	if not p then return nil end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.PlayerData.charinfo.birthdate
	elseif ACTIVE == 'es_extended' then
		return p.variables and p.variables.dateofbirth or p.get('dateofbirth')
	elseif ACTIVE == 'ox_core' then
		return p.get('dateOfBirth')
	end
end
exports('GetDob', GetDob)

-- Sex/Gender (standardize to original value where possible; ox_core maps male->1 female/non_binary->2 for legacy usage)
function GetSex(src)
	local p = getPlayer(src)
	if not p then return nil end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.PlayerData.charinfo.gender
	elseif ACTIVE == 'es_extended' then
		return p.variables and p.variables.sex or p.get('sex')
	elseif ACTIVE == 'ox_core' then
		local g = p.get('gender')
		if g == 'male' then return 1 else return 2 end
	end
end
exports('GetSex', GetSex)

-- Inventory Operations (prefer ox_inventory if running)
function RemoveItem(src, item, count)
	count = count or 1
	if hasOxInventory then
		return exports.ox_inventory:RemoveItem(src, item, count)
	end
	local p = getPlayer(src)
	if not p then return false end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.Functions.RemoveItem(item, count)
	elseif ACTIVE == 'es_extended' then
		return p.removeInventoryItem(item, count)
	elseif ACTIVE == 'ox_core' then
		return false -- native removal only via ox_inventory when available
	end
end
exports('RemoveItem', RemoveItem)

function AddItem(src, item, count, metadata)
	count = count or 1
	if hasOxInventory then
		return exports.ox_inventory:AddItem(src, item, count, metadata)
	end
	local p = getPlayer(src)
	if not p then return false end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.Functions.AddItem(item, count, false, metadata)
	elseif ACTIVE == 'es_extended' then
		return p.addInventoryItem(item, count, metadata)
	elseif ACTIVE == 'ox_core' then
		return false
	end
end
exports('AddItem', AddItem)

function HasItem(src, item)
	if hasOxInventory then
		return exports.ox_inventory:GetItemCount(src, item)
	end
	local p = getPlayer(src)
	if not p then return 0 end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		local it = p.Functions.GetItemByName(item)
		return (it and (it.count or it.amount)) or 0
	elseif ACTIVE == 'es_extended' then
		local it = p.getInventoryItem(item)
		if not it then return 0 end
		return it.count or it.amount or it.quantity or 0
	elseif ACTIVE == 'ox_core' then
		return 0
	end
end
exports('HasItem', HasItem)

function GetInventory(src)
	if hasOxInventory then
		local list = {}
		local data = exports.ox_inventory:GetInventoryItems(src)
		for i = 1, #data do
			local it = data[i]
			list[#list+1] = { name = it.name, label = it.label, count = it.count, weight = it.weight, metadata = it.metadata }
		end
		return list
	end
	local p = getPlayer(src)
	if not p then return {} end
	local list = {}
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		for _, it in pairs(p.PlayerData.items or {}) do
			list[#list+1] = { name = it.name, label = it.label, count = it.amount or it.count, weight = it.weight, metadata = it.info }
		end
	elseif ACTIVE == 'es_extended' then
		local inv = p.getInventory()
		for i = 1, #inv do
			local it = inv[i]
			list[#list+1] = { name = it.name, label = it.label, count = it.amount or it.count or it.quantity, weight = it.weight, metadata = it.info }
		end
	elseif ACTIVE == 'ox_core' then
		-- Without ox_inventory we can't reliably enumerate (ox_core doesn't expose items natively here)
	end
	return list
end
exports('GetInventory', GetInventory)

-- Job Set
function SetJob(src, job, grade)
	job = tostring(job)
	grade = tonumber(grade) or 0
	local p = getPlayer(src)
	if not p then return false end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		return p.Functions.SetJob(job, grade)
	elseif ACTIVE == 'es_extended' then
		return p.setJob(job, grade)
	elseif ACTIVE == 'ox_core' then
		p.setGroup(job, grade)
		return p.setActiveGroup(job)
	end
end
exports('SetJob', SetJob)

-- Register usable item
function RegisterUsableItem(item, cb)
	if hasOxInventory then
		-- ox_inventory style: export the item name as an event
		exports(item, function(event, invItem, inventory, slot, data)
			cb(inventory.source, event, invItem, inventory, slot, data)
		end)
		return true
	end
	if ACTIVE == 'qb-core' then
		QBCore.Functions.CreateUseableItem(item, cb)
	elseif ACTIVE == 'qbx_core' then
		QBX:CreateUseableItem(item, cb)
	elseif ACTIVE == 'es_extended' then
		ESX.RegisterUsableItem(item, cb)
	elseif ACTIVE == 'ox_core' then
		-- Without ox_inventory there is no native item use registration here
		return false
	end
	return true
end
exports('RegisterUsableItem', RegisterUsableItem)

-- Money getters/removers
function GetMoney(src, account)
	local p = getPlayer(src)
	if not p then return 0 end
	account = account == 'money' and 'cash' or account -- compatibility (money -> cash)
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		if account == 'cash' then return p.PlayerData.money.cash else return p.PlayerData.money.bank end
	elseif ACTIVE == 'es_extended' then
		local acc = p.getAccount(account)
		return acc and acc.money or 0
	elseif ACTIVE == 'ox_core' then
		-- ox_core stores money as accounts, use player.get
		return p.get(account) or 0
	end
end
exports('GetMoney', GetMoney)

function RemoveMoney(src, account, amount)
	amount = tonumber(amount) or 0
	local p = getPlayer(src)
	if not p or amount <= 0 then return false end
	if ACTIVE == 'qb-core' or ACTIVE == 'qbx_core' then
		local acc = account == 'money' and 'cash' or account
		return p.Functions.RemoveMoney(acc, amount)
	elseif ACTIVE == 'es_extended' then
		if account == 'money' or account == 'cash' then
			p.removeMoney(amount)
		else
			p.removeAccountMoney(account, amount)
		end
		return true
	elseif ACTIVE == 'ox_core' then
		-- ox_core uses add/remove via set perhaps; if ox_inventory wallet not present, we assume standard accounts exist
		local current = p.get(account)
		if type(current) == 'number' and current >= amount then
			p.set(account, current - amount)
			return true
		end
		return false
	end
end
exports('RemoveMoney', RemoveMoney)

-- (Optional) Provide a table export aggregator if needed elsewhere internally
tufan.framework = ACTIVE

