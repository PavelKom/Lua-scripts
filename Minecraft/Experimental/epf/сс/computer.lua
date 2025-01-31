--[[
	Computer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.0
	https://tweaked.cc/peripheral/computer.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' ID|Label: %i|'%s' Powered: %s", subtype(self), peripheral.getName(self), self.id, self.label, self.isOn)
end
function Peripheral.__init(self)
	self.__getter = {
		isOn = function() return self.isOn() end,
		label = function() return self.getLabel() end,
		id = function() return self.getID() end,
	}
	self.__setter = {}
	
	self.on = self.turnOn
	self.off = self. shutdown
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "computer", "Computer")

local lib = {}
lib.Computer = Peripheral

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
