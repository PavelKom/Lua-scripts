--[[
	Chemlib Autocraft by PavelKom v0.5b

	Autocarving chemical elements from the chemlib mod using reactors from Alchemistry and ME-RS Bridges
	Config elements.json is based on
	https://github.com/SmashingMods/ChemLib/blob/9d42c5b4ec148a1497a04c79eee32b5216a2d30e/src/main/resources/data/chemlib/elements.json
	
	Main element used: Carbon (from Coal, Charcoal or Diamonds)
	The main element is obtained from the Dissolver
	Elements with atomic numbers 1-7 are obtained from the Fission Reactor
		Start crafting only if amount of required element >= 1000
		required  products
		V		  V
		Si(14) -> 2N(7)
	The remaining elements are obtained from the Fusion Reactor
		Start crafting only if amount of required element >= 1000
										 main element >= 1000
		required main element
		V		 V
		Ti(22) + C(6) -> Ni(28)
						 ^
						 product
	
	chemlib_import.py - Python script for reconfigurate elements.json
]]
require "include/patches"

rs_util = require "include/rs_util"
me_util = require "include/me_util"
monitor_util = require "include/monitor_util"

local mon = monitor_util:Monitor()
local me = me_util:MEBridge()
local ref = rs_util:RSBridge()

f = io.open('elements.json', 'r')
local elements_raw = textutils.unserializeJSON(f:read('*a'))
f:close()

local x_offset = 0
local y_offset = 0

local ITEM_MAX = 10000
local ITEM_BATCH = 1 -- Amount of Fusion Chambers
local MAIN_ITEM_NUMBER = 6 -- Carbon
local DELAY = 10

local COLOR_RESULT = {
	['start crafting'] = colors.yellow,
	['no materials'] = colors.red,
	['conditions not met'] = colors.red,
	['already crafting'] = colors.yellow,
	['excess'] = colors.green,
}

local elements = {}
local tasks = {}
-- 57-71 - lanthanoid
-- 89-103 - actinoid
for k,v in pairs(elements_raw) do
	local item = 'chemlib:'..v.name
	local tbl = {x=v.x, y=v.y, index=v.atomic_number, label=v.abbreviation}
	local triggers = me_util:Triggers(item, _, ITEM_MAX)
	if v.required then
		for _, req in pairs(v.required) do
			triggers.add('chemlib:'..req, _, math.ceil(ITEM_MAX / 10), _, me_util.OP.GE)
		end
	end
	tasks[v.atomic_number] = me_util:CraftTask(item, ITEM_MAX, _, _, ITEM_BATCH, _, triggers, _)
	
	elements[item] = tbl
end
elements_raw = nil -- Clear memory

for k, v in ipairs(elements) do
	if me.isItemCraftable2(k) then
		me.addTask(tasks[v.index])
	elseif ref.isItemCraftable2(k) then
		ref.addTask(tasks[v.index])
	else
		print("Can't craft", k)
	end
end
tasks = nil -- Clear memory

function CraftCallback(data)
	--callback({result=result, item=ret.item, nbt=nbt, fingerprint=ret.fingerprint, amount=amount})
	if elements[data.item].status ~= COLOR_RESULT[me_util.TASKRESULT[amount]] then
		elements[data.item].status = COLOR_RESULT[me_util.TASKRESULT[amount]]
		drawElementOnMonitor(elements[data.item].label,
			elements[data.item].x, elements[data.item].y,
			elements[data.item].status
		)
	end
end
function drawElementOnMonitor(label, x, y, color)
	mon.pos(x,y)
	mon.bg = color
	ret.write(label)
end

-- Start autocrafting
while true do
	local res, err = pcall(me.runTaks, CraftCallback)
	-- If ME Network not valid or changed
	if not res then
		peinr(err)
		pcall(me.update)
	end
	local res, err = pcall(ref.runTaks, CraftCallback)
	-- Same for RS Network
	if not res then
		peinr(err)
		pcall(ref.update)
	end
	sleep(DELAY)
end

