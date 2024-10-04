--[[
	Energy Utility library by PavelKom.
	Version: 0.9
	Wrapped Energy Detector
	https://advancedperipherals.netlify.app/peripherals/energy_detector/
	TODO: Add manual
]]

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:EnergyDetector(name)
	name = name or 'energyDetector'
	local ret = {object = peripheral.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Energy Detector '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	
	ret.__getter = {
		rate = function() return ret.object.getTransferRate() end,
		limit = function() return ret.object.getTransferRateLimit() end,
	}
	ret.__setter = {
		limit = function(val)
			if type(val) ~= 'number' then error("Invalid value type for EnergyDetector.limit") end
			ret.object.setTransferRateLimit(val)
		end,
	}
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Energy Detector '%s' Rate: %i Limit: %i", self.name, self.rate, self.limit)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:EnergyDetector()
	end
end

function this_library.getRate()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.flow
end
function this_library.getLimit()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.limit
end
function this_library.setLimit(value)
	testDefaultPeripheral()
	this_library.DEFAULT_PERIPHERAL.limit = value
end

return this_library

