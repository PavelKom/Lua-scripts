--[[
	Energy Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Energy Detector
	https://advancedperipherals.netlify.app/peripherals/energy_detector/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'energyDetector', 'Energy Detector', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		rate = function() return self.object.getTransferRate() end,
		limit = function() return self.object.getTransferRateLimit() end,
	}
	self.__setter = {
		limit = function(val)
			if type(val) ~= 'number' then error("Invalid value type for EnergyDetector.limit") end
			self.object.setTransferRateLimit(val)
		end,
	}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Rate: %i Limit: %i", self.type, self.name, self.rate, self.limit)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	Peripheral.__items[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.EnergyDetector=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.getRate()
	testDefaultPeripheral()
	return Peripheral.default.flow
end
function lib.getLimit()
	testDefaultPeripheral()
	return Peripheral.default.limit
end
function lib.setLimit(value)
	testDefaultPeripheral()
	Peripheral.default.limit = value
end

return lib

