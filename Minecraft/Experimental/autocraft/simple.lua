--[[
	ME/RS Bridge autocraft profile for standart crafting.

	Don't change anything outside the CRAFTS category!!!
]]
------------------------------------------------------------------
local TriggerLib = require "epf.ap.trigger"
local Task = TriggerLib.Task
local TriggerGroup = TriggerLib.TriggerGroup
local Trigger = TriggerLib.Trigger
local expect = require "cc.expect"
local expect = expect.expect
------------------------------------------------------------------
local TASKS = {me={},rs={}}
local function addCraft(bridge, item, isFluid, amount, batch, T)
	local tasks = TASKS[bridge]
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
local RESULT = {me={tasks={}}, rs={tasks={}}}
for bridge, tasks in pairs(TASKS) do
	for _, craft in pairs(tasks) do
		local skip = false
		for _, task in pairs(RESULT[bridge].tasks) do
			if craft == task then skip = true; break end
		end
		if not skip then
			RESULT[bridge].tasks[ #RESULT[bridge].tasks+1 ] = craft
		end
	end
end
return RESULT
