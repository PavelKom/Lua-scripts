--[[
	Computer Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Computer
	https://tweaked.cc/peripheral/computer.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Computer')
	if wrapped ~= nil then return wrapped end
	self.__getter = {
		isOn = function() return self.object.isOn() end,
		label = function() return self.object.getLabel() end,
		id = function() return self.object.getID() end,
	}
	self.__setter = {}
	
	self.turnOn = function() self.object.turnOn() end
	self.on = self.turnOn
	self.shutdown = function() self.object.shutdown() end
	self.off = self. shutdown
	self.reboot = function() self.object.reboot() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' ID|Label: %i|'%s' Powered: %s", type(self), self.name, self.id, self.label, self.isOn)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Computer",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Computer=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="computer",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Computer",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end


return lib
