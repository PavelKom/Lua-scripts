--[[
	Geo Scanner Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Geo Scanner
	https://advancedperipherals.netlify.app/peripherals/geo_scanner/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
Peripheral.default = nil

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'geoScanner', 'Geo Scanner', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		fuel = function() return self.object.getFuelLevel() end,
		maxFuel = function() return self.object.getMaxFuelLevel() end,
		cooldown = function() return self.object.getScanCooldown() end,
		analyze = function() return self.object.chunkAnalyze() end,
		fuelRate = function() return self.object.getFuelConsumptionRate() end,
	}
	self.__getter.max = self.__getter.maxFuel
	self.__setter = {fuelRate = function(value) return self.object.setFuelConsumptionRate(value) end,}
	self.cost = function(radius) return self.object.cost(radius) end
	self.scan = function(radius) return self.object.scan(radius) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Current block: '%s'", self.type, self.name, self.block)
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
lib.GeoScanner=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if Peripheral.default == nil then
		Peripheral()
	end
end

function lib.getFuel()
	testDefaultPeripheral()
	return Peripheral.default.fuel
end
function lib.getMaxFuel()
	testDefaultPeripheral()
	return Peripheral.default.maxFuel
end
function lib.cost(radius)
	testDefaultPeripheral()
	return Peripheral.default.cost(radius)
end
function lib.scan(radius)
	testDefaultPeripheral()
	return Peripheral.default.scan(radius)
end
function lib.getCooldown()
	testDefaultPeripheral()
	return Peripheral.default.cooldown
end
function lib.analyze()
	testDefaultPeripheral()
	return Peripheral.default.analyze
end

return lib
	