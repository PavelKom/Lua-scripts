--[[
	Speedometer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.1
	
]]
local epf = require 'lib.epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Speed: %i", subtype(self), peripheral.getName(self), self.speed)
end
function Peripheral.__init(self)
	self.__getter = {
		speed = function() return self.getSpeed() end,
	    abs = function() return math.abs(self.getSpeed()) end,
	    dir = function() return self.getSpeed() >= 0 and 1 or -1 end,
	}
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_Speedometer", "Speedometer")

local lib = {}
lib.Speedometer = Peripheral

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
