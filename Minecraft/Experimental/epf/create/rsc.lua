--[[
	Rotation Speed Controller peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Rotation-Speed-Controller-%28Peripheral%29
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Speed: %i", subtype(self), peripheral.getName(self), self.speed)
end
function Peripheral.__init(self)
	self.__getter = {
		speed = function() return self.getTargetSpeed() end,
	    abs = function() return math.abs(self.getTargetSpeed()) end,
	    dir = function() return self.getTargetSpeed() >= 0 and 1 or -1 end,
	}
	self.__setter = {
		speed = function(value) self.setTargetSpeed(value) end,
	    abs = function(value) -- non-negative number
			self.setTargetSpeed(math.abs(value)*self.dir)
		end,
	    dir = function(value) -- boolean or number
			if type(value) == 'boolean' then
				self.setTargetSpeed(self.abs * (value and 1 or -1))
			elseif type(value) == 'number' then
				self.setTargetSpeed(self.abs * (value >= 0 and 1 or -1))
			end
		end,
	}
	self.invert = function() return self.setTargetSpeed(-1 * self.getTargetSpeed()) end
	self.inv = self.invert
	self.reverse = self.invert
	
	self.__is_stopped = false
	self.__buf_speed = 0
	
	self.stop = function()
		if not self.__is_stopped then
			self.__buf_speed = self.speed
			self.speed = 0
			self.__is_stopped = true
		end
	end
	self.resume = function(speed)
		self.__is_stopped = false
		self.speed = speed or self.__buf_speed
	end
	self.switch = function()
		if self.__is_stopped then self.resume() else self.stop() end
	end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_RotationSpeedController", "Rotation Speed Controller")

local lib = {}
lib.RotationSpeedController = Peripheral
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__name="RotationSpeedController",
	__type="library",
	__subtype="peripheral wrapper library"
})
return lib
