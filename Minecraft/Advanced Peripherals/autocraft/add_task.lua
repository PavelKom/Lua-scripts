--[[
	Add CraftTask to Autocraft by PavelKom v0.3b
	Add CraftTask for ME and RS Bridges.
	Crafting tasks are taken from JSON files:
	<DIR_PATH>/me.json	- tasks for ME Bridge
	<DIR_PATH>/rs.json	- tasks for RS Bridge
	<DIR_PATH>/any.json	- bridge auto detection
	For start autocraft run autocraft.lua or add it to startup file
]]

require "include/patches"
local rs_util = require "include/rs_util"
local me_util = require "include/me_util"

settings.define("AutoCraftAddTask.Bridge",{
	description = "Selected Bridge: 0 - any, 1 - Me, -1 - RS",
	default = 0,
	type = "number",
})

local CURRENT_BRIDGE = settings.get("AutoCraftAddTask.Bridge")

local DIR_PATH = 'tasks'
local TASK_FILES = {[1]=DIR_PATH.."/me.json", [-1]=DIR_PATH.."/rs.json", [0]=DIR_PATH.."/any.json"}

local input = {...}
if #input == 0 then
	print("Use 'add_task -h' for help")
	return
end
local arg1 = string.lower(input[1])
if arg1 == '-h' then
	-- CraftTask(name, count, fingerprint, nbt, batch, isFluid, triggers, isOR)
	--print("add_task <string mod:item or fingerprint> <number or _ amount> <string or _ nbt> <number or _ batch> <boolean or _ isFluid> <boolean or _ isOR>")
	print("add_task -h   - Show help")
	print("add_task -i   - Interactive mode")
	print("add_task -me  - Select current config to MEBridge config")
	print("add_task -rs  - Select current config to RSBridge config")
	print("add_task -any - Select current config to any bridge config")
elseif arg1 == '-i' then
	interactive()
elseif arg1 == '-me' then
	setBridge('1')
elseif arg1 == '-rs' then
	setBridge('-1')
elseif arg1 == '-any' then
	setBridge('0')
else
	local item = input[1]
	local name, fingerprint = toNameFingerprint(item)
	local count = tonumber(input[2])
	local nbt = input[3] or ''
	if #nbt == 0 then nbt = nil end
	local batch = tonumber(input[4])
	local isFluid = string.lower(input[5] or '')
	if #isFluid > 0 and (isFluid[1] == 'y' or isFluid[1] == 't') then
		isFluid = nil
	else
		isFluid = false
	end
	local isOR = string.lower(input[6] or '')
	if #isOR > 0 and (isOR[1] == 'y' or isOR[1] == 't') then
		isOR = true
	else
		isOR = false
	end
	
	addTaskToConfig(name, count, fingerprint, nbt, batch, isFluid, isOR)
end

local function toNameFingerprint(item_or_fingerprint)
	local item, fingerprint
	if string.find(item_or_fingerprint, ":") == nil then
		fingerprint = item_or_fingerprint
	else
		item = item_or_fingerprint
	end
	return item, fingerprint
end
local function setBridge(val)
	if #val == 0 then return
	elseif string.lower(val)[1] == 'm' or tonumber(val) > 0 then
		settings.set("AutoCraftAddTask.Bridge", 1)
		CURRENT_BRIDGE = 1
	elseif string.lower(val)[1] == 'r' or tonumber(val) < 0 then
		settings.set("AutoCraftAddTask.Bridge", -1)
		CURRENT_BRIDGE = -1
	elseif string.lower(val)[1] == 'a' then
		settings.set("AutoCraftAddTask.Bridge", 0)
		CURRENT_BRIDGE = 0
	end
end
local function addTaskToConfig(name, count, fingerprint, nbt, batch, isFluid, isOR)
	local f = io.open(TASK_FILES[CURRENT_BRIDGE], 'r')
	local data = textutils.unserializeJSON(f:read('*a'))
	f:close()
	data[#data+1] = me_util:CraftTask(name, count, fingerprint, nbt, batch, isFluid, _, isOR).json()
	f = io.open(TASK_FILES[CURRENT_BRIDGE], 'w')
	f:write(textutils.serializeJSON(data))
	f:close()
end

local function interactive()
	print("Select Bridge [0 - any, 1 - Me, -1 - RS] or omit for default:")
	setBridge(read())
	print("Print item:name or FINGERPRINT:")
	local item = tonumber(read())
	print("Print amount or omit for setting default value:")
	local count = tonumber(read())
	print("Print NBT tags or omit:")
	local nbt = read()
	if #nbt == 0 then
		nbt = nil
	end
	print("Print batch or omit for setting default value:")
	local batch = tonumber(read())
	print("Is fluid? (y/n) or omit:")
	local isFluid = string.lower(read())
	if #isFluid > 0 and (isFluid[1] == 'y' or isFluid[1] == 't') then
		isFluid = nil
	else
		isFluid = false
	end
	print("Use OR Triggers logic? (y/n) or omit:")
	local isOR = string.lower(read())
	if #isOR > 0 and (isOR[1] == 'y' or isOR[1] == 't') then
		isOR = true
	else
		isOR = false
	end
	local name, fingerprint = toNameFingerprint(item)
	addTaskToConfig(name, count, fingerprint, nbt, batch, isFluid, isOR)
end

