--[[
	Once Crafting Task Constructor by PavelKom v0.8b
	Constructor program for creating one-time crafts.
	once_craft - for i/o mode
		mod:item or fingerprint	  int for items, float for fluids
			         V				V
	once_craft <item/fingerprint> <count> [isFluid] [nbt] [RS/ME]
											^				^
										bool, y/n, nil		forced bridge
	< 0		- RSBridge
	nil, 0	- any bridge
	> 0		- MEBridge
]]

require "include/patches"

local rs_util = require "include/rs_util"
local me_util = require "include/me_util"
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local random = math.random
local DIR_PATH = 'once_dir'
if not fs.exists(DIR_PATH) then
	fs.makeDir(DIR_PATH)
end

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
	if s == 'y' or s == 't' or s == '1' then isFluid = true else isFluid = false end
	else isFluid = 0 end
	local item, fingerprint
	if string.find(item_or_fingerprint, ":") == nil then
		fingerprint = item_or_fingerprint
	else
		item = item_or_fingerprint
	end
	if type(isFluid) == 'string' and #isFluid == 0 then isFluid = nil end
	local data = {item=item, fingerprint=fingerprint, count=tonumber(count),isFluid=isFluid, nbt=nbt, bridge=getRS_ME(bridge)}
	
	local filename = uuid()
	local filepath = DIR_PATH..'/'..
	local f = io.open(filepath, 'w')
	f:write(textutils.serializeJSON(data))
	f:close()
	term.print("New once-time task added as "..filename)
end

local input = {...}
if #input == 0 then
	drawConsole()
	return
end
generateTask(table.unpack(input))

function drawConsole()
	term.clear()
	term.setCursorPos(1,1)
	term.write("Enter the item:name or fingerprint: ")
	local item_or_fingerprint = read()
	term.write("Enter amount (integer for items, float for fluids): ")
	local count = read()
	term.write("Is fluid (y/n): ")
	local isFluid = read()
	term.write("nbt tags: ")
	local nbt = read()
	term.write("Select Bridge (1-ME, -1RS, 0-Any): ")
	local bridge = read()
	generateTask(item_or_fingerprint, count, isFluid, nbt, bridge)
end