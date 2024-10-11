--[[
	Chemlib Autocraft by PavelKom v0.6b

	Autocrafting chemical elements from the chemlib mod using reactors from Alchemistry and ME-RS Bridges
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

local mon = monitor_util:Monitor()
local me = me_util:MEBridge()
local ref = rs_util:RSBridge()

f = io.open('elements.json', 'r')
local elements = textutils.unserializeJSON(f:read('*a'))
f:close()
--[[
abbreviation
atomic_number
group
name
period
required
x
y
color
]]
local tasks = {}
for i, element in ipairs(elements) do
	element.status = element.color and colors[element.color] or colors.red
	element.color = nil
	drawElementOnMonitor(element.abbreviation, element.x, element.y, element.color)
	if element.atomic_number and element.atomic_number > 0 then
		local triggers = me_util:Triggers(element.name, _, ITEM_MAX)
		if element.required then
			for _, req in pairs(element.required) do
				triggers.add(req, _, math.ceil(ITEM_MAX / 10), _, me_util.OP.GE)
			end
		end
		tasks[element.name] = me_util:CraftTask(element.name, ITEM_MAX, _, _, ITEM_BATCH, _, triggers, _)
		elements[element.name] = element
	end
	elements[i] = nil
end

for k, v in ipairs(tasks) do
	if me.isItemCraftable2(k) then
		me.addTask(v)
	elseif ref.isItemCraftable2(k) then
		ref.addTask(v)
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

