--[[
	ME/RS Bridge autocraft profile for Chemlib and Alchemistry mods
]]
----------------------------- CONFIG -----------------------------
local MONITOR_NAME = nil
local AMOUNT_CRAFT = 10000
local AMOUNT_MATERIAL = 1000
local AMOUNT_EXCESS = 200000
local BATCH = 64
--local MAIN_MATERIAL_LOOP = {[2]=true,[4]=true,[8]=true}
------------------------------------------------------------------
local input = {...}
local async_craft = input[1]
local DEBUG = input[3]
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
local cfg_path = script_path().."elements.json"
if not fs.exists(cfg_path) then error("Can't load elements.json") end
local element_cfg
do
	local f = io.open(cfg_path)
	element_cfg = textutils.unserialiseJSON(f:read("*a"))
	f:close()
end

local TriggerLib = require "epf.ap.trigger"
local Task = TriggerLib.Task
local TriggerGroup = TriggerLib.TriggerGroup
local Trigger = TriggerLib.Trigger

local Monitor = require "epf.cc.monitor"
local monitor = Monitor(MONITOR_NAME)

local RESULT = {me={tasks={}}, rs={tasks={}}}
for _, element in pairs(element_cfg.elements) do
	monitor.pos(element.x, element.y)
	monitor.bg = element.color and colors[element.color] or colors.red
	monitor.write(element.abbreviation)
	
	if element.atomic_number then
		local t = TriggerGroup(nil, Trigger({name=element.name},nil,nil,nil,nil,nil, AMOUNT_CRAFT))
		--if not MAIN_MATERIAL_LOOP[element.atomic_number] then
			for _, req in pairs(element.required or {}) do
				t.t[#t.t+1] = Trigger({name=req},nil,nil,TriggerLib.OP.GE,nil,nil, AMOUNT_MATERIAL)
			end
		--end
		local task = Task({name=element.name}, false, AMOUNT_CRAFT, BATCH, t)
		task.x = element.x
		task.y = element.y
		task.label = element.abbreviation
		if element.bridge == 'me' then RESULT.me.tasks[#RESULT.me.tasks+1] = task
		else RESULT.rs.tasks[#RESULT.rs.tasks+1] = task end
	end
end

local color_table = {
	[1] = colors.yellow,
	[0] = colors.red,
	[-1] = colors.pink,
	[-2] = colors.yellow,
	[-3] = colors.purple,
	[-4] = colors.cyan,
	[-5] = colors.green
}
--setmetatable(color_table, {__index = color_table[1]})
local function callback(res, task, bridge)
	local _i = bridge.getItem(task.item)
	local _c = color_table[res] or colors.yellow
	if _i then if _i.amount >= AMOUNT_EXCESS then _c = colors.lime
	elseif _i.amount >= AMOUNT_CRAFT then _c = colors.green
	end end
	monitor.pos(task.x, task.y)
	monitor.bg = _c
	monitor.write(task.label)
	if DEBUG and res > 0 then print(res, task.item.name or task.item.fingerprint) end
	if res > 0 then sleep(0); async_craft(task, bridge, callback) end
end
if #RESULT.me.tasks > 0 then RESULT.me.callback = callback end
if #RESULT.rs.tasks > 0 then RESULT.rs.callback = callback end

return RESULT
