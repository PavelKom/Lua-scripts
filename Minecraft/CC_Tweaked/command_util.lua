--[[
	Command Block Utility library by PavelKom.
	Version: 0.9
	Wrapped Command Block
	https://tweaked.cc/peripheral/command.html
	TODO: Add manual
]]

getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:CommandBlock(name)
	local def_type = 'command'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Command Block '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {command = function() return ret.object.getCommand() end,}
	ret.__setter = {command = function(value) ret.object.setCommand(value) end,}
	ret.run =  function() return ret.object.runCommand() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Command Block '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end


return this_library
