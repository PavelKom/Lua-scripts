--[[
	Geo Scanner Utility library by PavelKom.
	Version: 0.9
	Wrapped Geo Scanner
	https://advancedperipherals.netlify.app/peripherals/geo_scanner/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:GeoScanner(name)
	local def_type = 'geoScanner'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Geo Scanner '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		fuel = function() return ret.object.getFuelLevel() end,
		maxFuel = function() return ret.object.getMaxFuelLevel() end,
		cooldown = function() return ret.object.getScanCooldown() end,
		analyze = function() return ret.object.chunkAnalyze() end,
		fuelRate = function() return ret.object.getFuelConsumptionRate() end,
	}
	ret.__getter.max = ret.__getter.maxFuel
	ret.cost = function(radius) return ret.object.cost(radius) end
	ret.scan = function(radius) return ret.object.scan(radius) end
	
	ret.__setter = {fuelRate = function(value) return ret.object.setFuelConsumptionRate(value) end,}
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Geo Scanner '%s' Current block: '%s'", self.name, self.block)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:GeoScanner()
	end
end

function this_library.getFuel()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.fuel
end
function this_library.getMaxFuel()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.maxFuel
end
function this_library.cost(radius)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.cost(radius)
end
function this_library.scan(radius)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.scan(radius)
end
function this_library.getCooldown()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.cooldown
end
function this_library.analyze()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.analyze
end

return this_library
	