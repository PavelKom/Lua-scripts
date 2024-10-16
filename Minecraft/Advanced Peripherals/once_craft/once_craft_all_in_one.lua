--[[
	Once Crafting All In One by PavelKom v0.3b
	Constructor/Daemon program for creating/running one-time crafts.
]]
----------------
-----CONFIG-----
----------------
-- Delay between tasks
local delay1 = 1
-- Delay between tasks queue
local delay2 = 10





--------------------------
-----IMPORT LIBRARIES-----
--------------------------
require "include/patches"
local rs_util = require "include/rs_util"
local me_util = require "include/me_util"
local term_util = require "include/term_util"
local event_util = require "include/event_util"
local T = term_util:Terminal()
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field
local random = math.random
------------------------
-----INITIALIZATION-----
------------------------
local DIR_PATH = 'once_dir'
if not fs.exists(DIR_PATH) then
	fs.makeDir(DIR_PATH)
end
local me, ref
local function initBridge1()
	me = me_util:MEBridge()
end
local function initBridge2()
	ref = rs_util:RSBridge()
end
pcall(initBridge1) -- Try load MEBridge
pcall(initBridge2) --		   RSBridge
if not me and not ref then
	error("[ONCE_CRAFT_DAEMON] Can't connect to MEBridge and RSBridge. At least one is required.")
end
-------------------
-----GENERATOR-----
-------------------
-- https://gist.github.com/jrus/3197011
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end
local function getRS_ME(key)
	if key == nil then return 0 end
	if tonumber(key) ~= nil then
		if tonumber(key) > 0 then
			return 1
		elseif tonumber(key) < 0 then
			return -1
		else
			return 0
		end
	elseif string.lower(key) == "me" then
		return 1
	elseif string.lower(key) == "rs" then
		return -1
	else
		return 0
	end
end
local function generateTask(item_or_fingerprint, count, isFluid, nbt, bridge)
	expect(1, item_or_fingerprint, 'string')
	expect(3, count, 'string', 'number')
	expect(4, isFluid, 'string', 'number', 'boolean', 'nil')
	expect(5, nbt, 'string', 'nil')
	expect(6, bridge, 'string', 'number', 'nil')
	if tonumber(count) == nil then
		error("[ONCE_CRAFT] Invalid count parameter")
	end
	local s = #isFluid > 0 and string.lower(isFluid[1]) or ''
	if s == 'y' or s == 't' or s == '1' then
		isFluid = true
	else
		isFluid = false
	end
	local item, fingerprint
	if string.find(item_or_fingerprint, ":") == nil then
		fingerprint = item_or_fingerprint
	else
		item = item_or_fingerprint
	end
	if type(isFluid) == 'string' and #isFluid == 0 then isFluid = nil end
	if type(nbt) == 'string' and #nbt == 0 then nbt = nil end
	local data = {item=item, fingerprint=fingerprint, count=tonumber(count),isFluid=isFluid, nbt=nbt, bridge=getRS_ME(bridge)}
	
	local filename = uuid()
	local filepath = DIR_PATH..'/'..filename
	local f = io.open(filepath, 'w')
	f:write(textutils.serializeJSON(data))
	f:close()
	term.print("New once-time task added as "..filename)
end
----------------
-----DAEMON-----
----------------
local USE_ME = 1
local USE_RS = -1
local USE_ANY = 0
local queue_size = 0
local current_error = ''
local function runOnceTasks()
	local files = fs.list(DIR_PATH)
	queue_size = #files
	current_error = ''
	for _, path in pairs(files) do
		if not fs.isDir(DIR_PATH..'/'..path) then
			runOnceTask(path)
			sleep(delay1)
		end
	end
end
local function runOnceTask(path)
	-- Run task
	local data = readTaskFile(path)
	if not data then return end
	if data.bridge == USE_ME and not me then -- Force craft in MEBridge, but bridge not valid
		current_error = "[ONCE_CRAFT_DAEMON] Can't connect to MEBridge for task "..path
	elseif data.bridge == USE_RS and not ref then -- Same for RSBridge
		current_error = "[ONCE_CRAFT_DAEMON] Can't connect to RSBridge for task "..path
	end
	local res, err
	if data.bridge == USE_ME then
		res, err = runOnBridge(data, me)
		if not res then current_error = err end
	elseif data.bridge == USE_RS then
		res, err = runOnBridge(data, ref)
		if not res then current_error = err end
	else
		res, err = runOnBridge(data, me)
		if not res then
			res, err = runOnBridge(data, ref)
			if not res then current_error = err end
		end
	end
	-- If count changed, update task file
	if res and data.count ~= err then
		data.count = err
		writeTaskFile(path, data)
	end
end
local function readTaskFile(path)
	-- Read task file
	local filepath = DIR_PATH..'/'..path
	if not fs.exists(filepath) then return nil end
	local f = io.open(filepath, 'r')
	local data = textutils.unserializeJSON(f:read('*a'))
	f:close()
	if data.count == 0 then
		fs.delete(filepath)
		queue_size = queue_size - 1
		return nil
	end
	return data
end
local function writeTaskFile(path, data)
	-- Update task file
	local filepath = DIR_PATH..'/'..path
	if data.count > 0 then
		local f = io.open(filepath, 'w')
		f:write(textutils.serializeJSON(data))
		f:close()
	else
		fs.delete(filepath)
		queue_size = queue_size - 1
	end
end
local function runOnBridge(data, bridge)
	local d = {item=data.item, fingerprint=data.fingerprint, nbt=data.nbt, count=data.count}
	if not bridge.isItemCraftable(d) then return false, "Item not craftable"
	elseif bridge.isItemCrafting(d) then return true, data.count -- Already crafting
	end
	local count = 0
	if data.isFluid then
		count = data.count
		local result = bridge.craftFluid({item=data.item, fingerprint=data.fingerprint, nbt=data.nbt, count=count})
		while count > 0.001 and not result do
			count = math.ceil((count/10)*1000)/1000
			result = interface.craftFluid({item=item, nbt=nbt, fingerprint=fingerprint, count=count})
		end
		if not result then count = 0 end
	else
		count = data.count
		local result = bridge.craftItem({item=data.item, fingerprint=data.fingerprint, nbt=data.nbt, count=count})
		while count > 0.001 and not result do
			count = math.ceil((count/10))
			result = interface.craftItem({item=item, nbt=nbt, fingerprint=fingerprint, count=count})
		end
		if not result then count = 0 end
	end
	return true, data.count - count
end

--------------
-----INFO-----
--------------
local info = {'Once Crafting All In One', ' by ', 'PavelKom', ' v0.1b'}
local info2 = {'Queue:', 'Last error:'}
local info3 = {'Item:name or fingerprint', 'Amount', 'Fluid?', 'NBT','Bridge(1-Me,-1-RS,0-Any)'}
local x_offset_2 = 1
local x_offset_3 = 1
local y_offset2 = 1
local y_offset3 = 1
local function initTerminal()
-- Terminal wrapped as T
T.bg = colors.black
T.clear() -- Clear screen
T.pos() -- reset position on 1,1
-- Header
T.fg = colors.cyan
T.write(info[1])
T.fg = colors.white
T.write(info[2])
T.fg = colors.red
T.write(info[3])
if string.find(info[4],'a') ~= nil then
	T.fg = colors.orange
elseif string.find(info[4],'b') ~= nil then
	T.fg = colors.yellow
else
	T.fg = colors.green
end
T.print(info[4])  -- y=2
-- Queue info
T.fg = colors.white
y_offset2 = T.y
for _, v in pairs(info2) do
	T.print(v)  -- y=4
	x_offset_2 = math.max(x_offset_2, #v)
end
x_offset_2 = x_offset_2 + 2
T.y = T.y + 1  -- y=4->5
-- Form for adding a task
y_offset3 = T.y
for _, v in pairs(info3) do
	T.print(v)  -- y=5->10
	x_offset_3 = math.max(x_offset_2, #v)
end
x_offset_3 = x_offset_3 + 2
T.pos(x_offset_3, y_offset3)
T.bg = colors.white
T.fg = colors.black
local l = T.cols - x_offset_3 + 1
for i=1, #info3 do
	T.print(string.rep(" ", l), x_offset_3)
end
T.pos(x_offset_3, y_offset3)
end
local defaults = {nil, '1', 'n', nil, '0'}
local in_form = false
local function waitForInput()
	in_form = true
	T.pos(x_offset_3, y_offset3)
	T.bg = colors.white
	T.fg = colors.black
	local data = {}
	T.blink = true
	for i=1, 5 do
		data[data+1] = read(_,_,_,defaults[i])
		T.x = x_offset_3
	end
	T.blink = false
	generateTask(table.unpack(data))
	sleep(0.1)
	in_form = false
end
local function redrawQueue()
	while true do
		while in_form do
			sleep(0.1)
		end
		T.pos(x_offset_2, y_offset2)
		T.bg = colors.white
		T.fg = colors.black
		T.print(queue_size,x_offset_2)
		T.write(current_error)
		sleep(1)
	end
end
local ENTER = 257 -- Enter key code
local function eventCallback(data)
	--key_up				number: The numerical key value of the key pressed.
	if data[2] == ENTER and not in_form then
		waitForInput()
	end
end
local function eventWrapper()
	event_util.waitEventLoopEx('key_up',eventCallback)
end
function taskDaemon()
	while true do
		runOnceTasks()
		sleep(delay2)
	end
end

initTerminal()
parallel.waitForAll(eventWrapper, redrawQueue, taskDaemon)

