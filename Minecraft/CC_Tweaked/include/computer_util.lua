--[[
	Computer Utility library by PavelKom.
	Version: 0.9
	Wrapped Computer
	https://tweaked.cc/peripheral/computer.html
	TODO: Add manual
]]

getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:Computer(name)
	local def_type = 'computer'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Computer '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		isOn = function() return ret.object.isOn() end,
		label = function() return ret.object.getLabel() end,
		id = function() return ret.object.getID() end,
	}
	
	ret.turnOn = function() ret.object.turnOn() end
	ret.on = ret.turnOn
	ret.shutdown = function() ret.object.shutdown() end
	ret.off = ret. shutdown
	ret.reboot = function() ret.object.reboot() end

	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Computer '%s' ID|Label: %i|'%s' Powered: %s", self.name, self.id, self.label, self.isOn)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end


return this_library
