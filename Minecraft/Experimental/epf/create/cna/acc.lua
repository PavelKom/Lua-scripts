--[[
	Accumulator (Create: Crafts & Additions) peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Rotation-Speed-Controller-%28Peripheral%29
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Energy: %i/%i", subtype(self), peripheral.getName(self), self.energy, self.cap)
end
function Peripheral.__init(self)
	self.__getter = {
		energy = function() return self.getEnergy() end,
		cap = function() return self.getCapacity() end,
		percent = function() return self.getPercent() end,
		height = function() return self.getHeight() end,
		extract = function() return self.getMaxExtract() end,
		insert = function() return self.getMaxInsert() end,
		width = function() return self.getWidth() end,
		cap2 = function()
			return self.getCapacity() / (math.pow(self.getWidth(),2)*self.getHeight())
		end
	}
	self.__getter.maxEnergy = self.__getter.cap
	self.__getter.max = self.__getter.cap
	self.__getter.h = self.__getter.height
	self.__getter.w = self.__getter.width
	self.__getter.capPerBlock = self.__getter.cap2
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "modular_accumulator", "Accumulator")

local lib = {}
lib.Accumulator = Peripheral
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="Accumulator",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Accumulator (Create: Crafts & Additions)"
	end,
})
return lib
