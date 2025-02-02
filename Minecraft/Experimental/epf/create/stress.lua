--[[
	Stressometer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Stressometer-%28Peripheral%29
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self) -- tostring for objects
	return string.format("%s '%s' Stress: %i/%i (%.1f%%)", subtype(self), peripheral.getName(self), self.stress, self.max, self.use * 100)
end
function Peripheral.__init(self) -- Add getters, setters and subtables (like pos for managing cursor position)
	self.__getter = {
		stress = function() -- stress as read-only property
			return self.getStress()
		end,
		capacity = function()
			return self.getStressCapacity() -- capacity
		end,
		use = function() -- stress/capacity
			if self.getStressCapacity() == 0 then return 1.0 end
			return self.getStress() / self.getStressCapacity()
		end,
		free = function() -- capacity - stress
			return self.getStressCapacity() - self.getStress()
		end,
		is_overload = function() -- network is overload
			return self.getStressCapacity() < self.getStress()
		end,
	}
	-- Aliases
	self.__getter.cap = self.__getter.capacity
	self.__getter.max = self.__getter.capacity
	self.__getter.overload = self.__getter.is_overload
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_Stressometer", "Stressometer")

local lib = {}
lib.Stressometer = Peripheral
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__name="Stressometer",
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
