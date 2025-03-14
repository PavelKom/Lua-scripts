--[[
	Autocraft for ME and RS Bridges
]]
----------------------------- CONFIG -----------------------------
local MODE = 3 -- 1 - ME; 2 - RS; 3 - Both
local ME_NAME = nil
local RS_NAME = nil
local DELAY = 5
------------------------------------------------------------------
local BRIDGE = require "epf.ap.bridge"
local MEBridge = BRIDGE.MEBridge
local RSBridge = BRIDGE.RSBridge
local Task = BRIDGE.Task
local DEBUG = true

local async_craft
if GUI then
	async_craft = function(task, bridge, callback)
		GUI.think(task.craft, bridge, callback)
	end
else
	local async = require "epf.async"
	async_craft = function(task, bridge, callback)
		async.think(task.craft, bridge, callback)
	end
end

local me_bridge, rs_bridge
local function prepareBridge(b)
	b.runTasks = function()
		for _, profile in pairs(b.tasks) do -- Profiles
			local callback = profile.callback
			for _, task in pairs(profile.tasks) do
				--local res = task.craft(b, callback)
				async_craft(task, b, callback)
				sleep(0)
			end
		end
	end
	return b
end
local function defaultCallback(res, task, bridge)
	if DEBUG and res > 0 then print(res, task.item.name or task.item.fingerprint) end
	if res > 0 then sleep(0); async_craft(task, bridge, defaultCallback) end
end
local function testBridges()
	local valid = {true, true, true}
	if not valid[MODE] then error("Invalid autocrafter MODE") end
	if MODE == 1 or MODE == 3 then
		local res, err = pcall(MEBridge, ME_NAME)
		if not res then error("Can't connect to ME Bridge") end
		me_bridge = prepareBridge(err)
	end
	if MODE == 2 or MODE == 3 then
		local res, err = pcall(RSBridge, RS_NAME)
		if not res then error("Can't connect to RS Bridge") end
		rs_bridge = prepareBridge(err)
	end
end
testBridges()

-- Load profiles
local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
local rel_path = script_path().."autocraft/"
for _,path in pairs(fs.list(rel_path)) do
    local p = rel_path..path
	if fs.exists(p) and not fs.isDir(p) and string.match(p, ".+%.lua") then
        local res = loadfile(p,nil,_ENV)(async_craft, defaultCallback, DEBUG) or {}
		if DEBUG then
			print(path)
			for int, tasks in pairs(res) do
				print('', int)
				for _, task in pairs(tasks.tasks) do
					print('', '', task.item.name or task.item.fingerprint)
					sleep(0)
				end
			end
		end
		if me_bridge and res.me and #res.me.tasks>0 then
			res.me.callback = res.me.callback or defaultCallback
			me_bridge.addTask(res.me)
		end
		if rs_bridge and res.rs and #res.rs.tasks>0 then
			res.rs.callback = res.rs.callback or defaultCallback
			rs_bridge.addTask(res.rs)
		end
    end
end

local function run()
	local res1, res2, err1, err2 = true, true, "", ""
	if me_bridge then
		res1, err1 = pcall(me_bridge.runTasks)
		if not res1 then print(err1) end
	end
	if rs_bridge then
		res2, err2 = pcall(rs_bridge.runTasks)
		if not res2 then print(err2) end
	end
	if not (res1 and res2) then testBridges() end
end

while true do
	run()
	sleep(DELAY)
end
