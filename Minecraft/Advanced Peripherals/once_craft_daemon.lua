--[[
	Once Crafting Daemon by PavelKom v0.8b
	A demon that performs one-time crafts created by a constructor program.
]]
require "include/patches"
local rs_util = require "include/rs_util"
local me_util = require "include/me_util"

----------------
-----CONFIG-----
----------------
-- Delay between tasks
local delay1 = 1
-- Delay between tasks queue
local delay2 = 10



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
local USE_ME = 1
local USE_RS = -1
local USE_ANY = 0
local function runOnceTasks()
	local files = fs.list(DIR_PATH)
	for _, path in pairs(files) do
		if not fs.isDir(DIR_PATH..'/'..'path') then
			runOnceTask(path)
			sleep(1)
		end
	end
end
local function runOnceTask(path)
	-- Run task
	local data = readTaskFile(path)
	if not data then return end
	if data.bridge == USE_ME and not me then -- Force craft in MEBridge, but bridge not valid
		error("[ONCE_CRAFT_DAEMON] Can't connect to MEBridge for task "..path)
	elseif data.bridge == USE_RS and not ref then -- Same for RSBridge
		error("[ONCE_CRAFT_DAEMON] Can't connect to RSBridge for task "..path)
	end
	local res, err
	if data.bridge == USE_ME then
		res, err = runOnBridge(data, me)
		if not res then print(err) end
	elseif data.bridge == USE_RS then
		res, err = runOnBridge(data, ref)
		if not res then print(err) end
	else
		res, err = runOnBridge(data, me)
		if not res then
			res, err = runOnBridge(data, ref)
			if not res then print(err) end
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
	local filepath = DIR_PATH..'/'..
	if not fs.exists(filepath) then return nil end
	local f = io.open(filepath, 'r')
	local data = textutils.unserializeJSON(f:read('*a'))
	f:close()
	if data.count == 0 then
		fs.delete(filepath)
		print("[ONCE_CRAFT_DAEMON] Task done "..path)
		return nil
	end
	return data
end
local function writeTaskFile(path, data)
	-- Update task file
	local filepath = DIR_PATH..'/'..
	if data.count > 0 then
		local f = io.open(filepath, 'w')
		f:write(textutils.serializeJSON(data))
		f:close()
	else
		fs.delete(filepath)
		print("[ONCE_CRAFT_DAEMON] Task done "..path)
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
		while count > 0.001 and not result then
			count = math.ceil((count/10)*1000)/1000
			result = interface.craftFluid({item=item, nbt=nbt, fingerprint=fingerprint, count=count})
		end
		if not result then count = 0 end
	else
		count = data.count
		local result = bridge.craftItem({item=data.item, fingerprint=data.fingerprint, nbt=data.nbt, count=count})
		while count > 0.001 and not result then
			count = math.ceil((count/10))
			result = interface.craftItem({item=item, nbt=nbt, fingerprint=fingerprint, count=count})
		end
		if not result then count = 0 end
	end
	return true data.count - count
end

while true do
	local res, err = pcall(runOnceTasks)
	if not res then
		pcall(initBridge1)
		pcall(initBridge2)
		if not me and not ref then
			error("[ONCE_CRAFT_DAEMON] Can't connect to MEBridge and RSBridge. At least one is required.")
		end
	end
	sleep(10)
end









