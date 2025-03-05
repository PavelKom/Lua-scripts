--[[
	ME/RS Bridge autocraft profile for standart crafting.
]]
------------------------------------------------------------------
local TriggerLib = require "epf.ap.trigger"
local Task = TriggerLib.Task
local TriggerGroup = TriggerLib.TriggerGroup
local Trigger = TriggerLib.Trigger
local expect = require "cc.expect"
local expect = expect.expect
------------------------------------------------------------------
local RESULT = {me={tasks={}}, rs={tasks={}}}
local function _parse(ntf)
	if type(ntf) == 'table' then return ntf end
	local item = {}
	if type(ntf) == 'string' then
		if tonumber(ntf,16) then item.fingerprint = ntf
		else item.name = ntf end
	elseif ntf ~= nil then
		error("Invalid item name/tag/fingerprint type")
	end
	return item
end
local function addCraft(bridge, item, isFluid, amount, batch, T)
	local tasks = RESULT[bridge].tasks
	local task = Task(item, isFluid, amount, batch, T)
	tasks[#tasks+1] = task
end
local function addCraftME(item, isFluid, amount, batch, T)
	addCraft('me', item, isFluid, amount, batch, T)
end
local ME = addCraftME
local function addCraftRS(item, isFluid, amount, batch, T)
	addCraft('me', item, isFluid, amount, batch, T)
end
local RS = addCraftRS
do
------------------------------CRAFTS------------------------------
ME('minecraft:oak_planks')
ME('minecraft:spruce_planks')
------------------------------------------------------------------
end
for bridge, tasks in pairs(TASKS) do
	for _, craft in pairs(tasks) do
		local skip = false
		for _, task in pairs(tasks) do
			if craft == task then skip = true; break end
		end
		if not skip then
			tasks[#tasks+1] = craft
		end
	end
end
return RESULT
