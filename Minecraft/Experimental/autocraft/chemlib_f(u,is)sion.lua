--[[
	ME/RS Bridge autocraft profile for Chemlib and Alchemistry mods
]]
----------------------------- CONFIG -----------------------------
local MONITOR_NAME = nil
local AMOUNT_CRAFT = 1000
local AMOUNT_MATERIAL = 100
local BATCH = 1
------------------------------------------------------------------
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
for _, element in pairs(cfg_path.elements) do
	monitor.pos(element.x, element.y)
	monitor.bg = element.color and colors[element.color] or colors.red
	monitor.write(element.label)
	
	if element.atomic_number then
		local t = TriggerGroup(_, Trigger({name=element.name},_,_,_,_,_, AMOUNT_CRAFT))
		for _, req in pairs(element.required or {}) do
			t.t[#t.t+1] = Trigger({name=req},_,_,TriggerLib.OP.GE,_,_, AMOUNT_MATERIAL)
		end
		local task = Task({name=element.name}, false, AMOUNT_CRAFT, BATCH, t)
		task.x = element.x
		task.y = element.y
		task.label = element.label
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
setmetatable(color_table, {__index = color_table[1]})
local function callback(res, task, bridge)
	monitor.pos(task.x, task.y)
	monitor.bg = color_table[res]
	monitor.write(task.label)
end
if #RESULT.me.tasks > 0 then RESULT.me.callback = callback end
if #RESULT.rs.tasks > 0 then RESULT.rs.callback = callback end

return RESULT
