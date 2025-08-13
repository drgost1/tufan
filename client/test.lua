-- Examples of how to use the Tufan framework exports

-- Basic notification
exports['tufan']:bridgeNotify('Hello World!', 'info', 3000)

-- Get player's job and gang
local job, gang = exports['tufan']:GetPlayerGroups()
print('Job:', job, 'Gang:', gang)

-- Get detailed job information
local jobInfo = exports['tufan']:GetPlayerGroupInfo(true) -- true for job, false for gang
print('Job Name:', jobInfo.name)
print('Job Grade:', jobInfo.grade)
print('Job Label:', jobInfo.label)

-- Get player's gender/sex
local sex = exports['tufan']:GetSex()
print('Player Sex:', sex == 1 and 'Male' or 'Female')

-- Check if player is dead
local isDead = exports['tufan']:IsDead()
print('Player is Dead:', isDead)

-- Set player outfit
