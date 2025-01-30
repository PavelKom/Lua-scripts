--[[
	Stressometer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.0
	
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self) -- tostring for objects
	return string.format("%s '%s' Stress: %i/%i (%.1f%%)", subtype(self), self.name, self.stress, self.max, self.use * 100)
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
Peripheral.new = epf.simpleNew(Peripheral) -- Add default new()
Peripheral = epf.wrapperFixer(tbl, "Create_Stressometer", "Stressometer") -- Validate wrapper

local lib = {} -- Create library
lib.Stressometer = Peripheral -- Add alias to library
-- Add information about library
lib = setmetatable(lib, __call=Peripheral.__call, __type="library", __subtype="peripheral wrapper library")

-- Now lib(...) == lib.Stressometer(...) == Peripheral(...) == Peripheral.new(...)
-- Note: If library contain more than one wrapper, don't add Peripheral() as __call to library!

return lib
