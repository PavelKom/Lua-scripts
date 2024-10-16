--[[
	Autocraft with ME/RS Bridges by PavelKom v0.5b
	Autocraft using ME and RS Bridges from Advanced Peripherals.
	Crafting tasks are taken from JSON files:
	<DIR_PATH>/me.json	- tasks for ME Bridge
	<DIR_PATH>/rs.json	- tasks for RS Bridge
	<DIR_PATH>/any.json	- bridge auto detection
	For adding tasks use add_task.lua or add manually in JSON file
]]

require "include/patches"
local rs_util = require "include/rs_util"
local me_util = require "include/me_util"
local mon_util = require "include/monitor_util"
local TASKRESULT = me_util.TASKRESULT

local ME_BRIDGE_MAIN = true
local DELAY = 10
local DIR_PATH = 'tasks'
local OMIT_WARNINGS = false
local OMIT_ERRORS = false

local rows = mon.rows
local cols = mon.cols
local me, ref
local function initBridge1()
	me = me_util:MEBridge()
end
local function initBridge2()
	ref = rs_util:RSBridge()
end
if not fs.exists(DIR_PATH) then
	fs.makeDir(DIR_PATH)
end
local TASK_FILES = {me=DIR_PATH.."/me.json", ref=DIR_PATH.."/rs.json", any=DIR_PATH.."/any.json"}
local all_tasks = {}

local COLOR_RESULT = {
	['start crafting'] = colors.yellow,
	['no materials'] = colors.red,
	['conditions not met'] = colors.red,
	['already crafting'] = colors.yellow,
	['excess'] = colors.green,
}
local function cc(tbl)
	local tbl2 = {}
	for k,v in pairs(tbl) do
		tbl2[k] = tostring(k)
	end
	return table.concat(tbl2)
end

local function loadTasks()
	local tasks = {me={}, ref={}, any={}}
	for k, file in pairs(TASK_FILES) do
		if not fs.exists(ME_DIR) then
			f = io.open(ME_DIR, 'w')
			f:write(textutils.serializeJSON( -- Create template craft task
				{me_util:CraftTask("test:item_or_fluid", 1234, "testFingerprint", "testNBT", 123, false, _, false).json(),}
			))
			f:close()
		else
			f = io.open(ME_DIR, 'r')
			local data = textutils.unserializeJSON(f:read('*a'))
			f:close()
			for _, d in pairs(data) do
				tasks[k][#tasks[k]+1] = me_util.taskFromJson(d)
				all_tasks[cc({d.name, d.nbt, d.fingerprint})] = {label=d.label, hide=d.hide, count=d.count}
			end
		end
	end
	if me then
		me.clearTasks()
		for i, v in pairs(tasks.me) do
			if me.isItemCraftable({name=v.name, nbt=v.nbt, fingerprint=v.fingerprint}) then
				me.addTask(v)
			elseif not OMIT_WARNINGS then
				print("[AUTCRAFT] Can't add task to MEBridge:", v.name, v.nbt, v.fingerprint)
			end
		end
	end
	if ref then
		ref.clearTasks()
		for i, v in pairs(tasks.ref) do
			if ref.isItemCraftable({name=v.name, nbt=v.nbt, fingerprint=v.fingerprint}) then
				ref.addTask(v)
			elseif not OMIT_WARNINGS then
				print("[AUTCRAFT] Can't add task to RSBridge:", v.name, v.nbt, v.fingerprint)
			end
		end
	end
	if ME_BRIDGE_MAIN then
		for i, v in pairs(tasks.any) do
			if tryAddTask(me, v) then
				me.addTask(v)
			elseif tryAddTask(ref, v) then
				ref.addTask(v)
			elseif not OMIT_WARNINGS then
				print("[AUTCRAFT] Can't add task to any Bridge:", v.name, v.nbt, v.fingerprint)
			end
		end
	else
		for i, v in pairs(tasks.any) do
			if tryAddTask(ref, v) then
				ref.addTask(v)
			elseif tryAddTask(me, v) then
				me.addTask(v)
			elseif not OMIT_WARNINGS then
				print("[AUTCRAFT] Can't add task to any Bridge:", v.name, v.nbt, v.fingerprint)
			end
		end
	end
end
local function tryAddTask(interface, task)
	if not interface then return false end
	if not interface.isItemCraftable({name=interface.name, nbt=interface.nbt, fingerprint=interface.fingerprint}) then
		return false
	end
	return true
end
local row = 1
local function craftCallback(data)
	-- {result=result, name=ret.name, nbt=ret.nbt, fingerprint=ret.fingerprint, amount=amount}
	-- if elements[data.item].status ~= COLOR_RESULT[me_util.TASKRESULT[data.amount]] then
	local c = cc({data.name, data.nbt, data.fingerprint})
	if not all_tasks[c] then
		return
	elseif all_tasks[c].hide then 
		return
	end
	if all_tasks[c].status ~= COLOR_RESULT[TASKRESULT[data.amount]] then
		all_tasks[c].status = COLOR_RESULT[TASKRESULT[data.amount]]
	end
	if not all_tasks[c].row then
		all_tasks[c].row = row
		row = row + 1
	end
	local t = all_tasks[c]
	local count = data.interface.getItem({item=data.item, nbt=data.nbt, fingerprint=data.fingerprint})
	if count then count = count.count end
	printOnMonitor(t.label, t.name, data.amount, count, t.count, data.result, t.row, t.status)
end
local function printOnMonitor(label, item, count, max_item, result, row, msg_color)
	row = (row - 1) % rows + 1
	mon.pos(1, row)
	mon.fg = colors.yellow
	mon.write(label or "")
	local s = string.format("%i/%i", count, max_item)
	mon.x = cols - #s + 1
	mon.fg = msg_color
	mon.write(s)
end
function main()
	pcall(initBridge1) -- Try load MEBridge
	pcall(initBridge2) --		   RSBridge
	if not me and not ref and not OMIT_ERRORS then
		error("[AUTOCRAFT] Can't connect to MEBridge and RSBridge. At least one is required.")
	end
	loadTasks()
	while true do
		local res, res2, err = true, true, ''
		if me then
			local res, err = pcall(me.runTasks,craftCallback) 
		end
		if ref then
			local res2, err = pcall(ref.runTasks,craftCallback) 
		end
		if not res or not res2 then
			pcall(initBridge1)
			pcall(initBridge2)
			loadTasks()
		end
		sleep(DELAY)
	end
end

main()



