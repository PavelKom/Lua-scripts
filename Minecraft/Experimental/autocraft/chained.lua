--[[
	ME/RS Bridge autocraft profile for chained crafting.
	Adding crafts in a chain (or as a tree).
	Each subsequent craft in the chain begins only after the previous one (or the one specified directly) is completed.
	The list of recipes is written in the CRAFTS category.
	Don't change anything outside the CRAFTS category!!!
	
	newChain('me') or newChain('rs') - new chain for ME or RS Bridge
	local c = addCraft( item[, isFluid[, amount[, batch[, T[, prev] ] ] ] ] ) - add craft to chain. Return chaining data (for tree purpose).
				item - REQUIRED. Item name/fingerprint as string or table with name/fingerprint, nbt and other.
				isFluid - Default: false. Crafted item is fluid. Boolean
				amount - Default: 1000 (as TriggerLib.DEFAULT_AMOUNT). Target amount.
				batch - Default: 1. Maximum craft batch size.
				T - Default: nil. Extra Trigger or TriggerGroup.
				prev - Default: nil. Other craft Task as parent.
]]
------------------------------------------------------------------
local TriggerLib = require "epf.ap.trigger"
local Task = TriggerLib.Task
local TriggerGroup = TriggerLib.TriggerGroup
local Trigger = TriggerLib.Trigger
local expect = require "cc.expect"
local expect = expect.expect
------------------------------------------------------------------
local CHAINS = {}
local index = nil
local tmp_data = nil
local function newChain(bridge)
	expect(1, bridge, "string", "nil")
	bridge = bridge and string.lower(bridge) or 'me'
	assert(bridge == 'rs' or bridge == 'me', "[Chained autocraft] Invalid bridge name")
	index = #CHAINS+1
	CHAINS[index] = {bridge=bridge, tasks={}}
	tmp_data = nil
end
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
local function addCraft(item, isFluid, amount, batch, T, prev)
	local tasks = CHAINS[index].tasks
	-- (item1, math_op1, const1, op, item2, math_op2, const2)
	local t1 = Trigger(_parse(item), _, _, _, _, _, amount)
	if prev then tmp_data = {prev.A, prev.cB} end
	local t2 = tmp_data and Trigger(_parse(tmp_data[1]), _, _, TriggerLib.OP.GE, _, _, tmp_data[2]) or nil
	tmp_data = {t1.A, t1.cB}
	local task = Task(item, isFluid, amount, batch, TriggerGroup(_, t1, t2, T))
	tasks[#tasks+1] = task
	return {t1.A, t1.cB}
end
do
------------------------------CRAFTS------------------------------
-- Cobblestone
newChain('me')
local c = addCraft("minecraft:cobblestone")
	addCraft("minecraft:gravel")
		addCraft("minecraft:sand")
			addCraft("minecraft:glass")
	addCraft("minecraft:stone", nil, nil, nil, nil, nil, c)
		addCraft("minecraft:stonebricks")

-- AE2 Cell components. TODO: Add 1024,... from other mods
local cell_format = "ae2:cell_component_%ik"
newChain('me')
for i=0, 4 do
	addCraft(string.format(cell_format,4^i), nil, 3, 1)
	-- cell_component_1k
		-- cell_component_4k
			-- ...
end



------------------------------------------------------------------
end
local RESULT = {me={tasks={}}, rs={tasks={}}}
for _, chain in pairs(CHAINS) do
	local bridge = chain.bridge
	local tasks = RESULT[bridge].tasks
	for _, craft in pairs(chain) do
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
