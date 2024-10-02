--[[
	Energy Utility library by PavelKom.
	Version: 0.1
	Wrapped Energy Detector
	https://advancedperipherals.netlify.app/peripherals/energy_detector/
]]

local energy_util = {}
energy_util.DEFAULT_ENERGY_DETECTOR = nil

function energy_util:EnergyDetector(name)
	name = name or 'energyDetector'
	local ret = {object = peripherals.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Energy Detector '"..name.."'") end
	ret.name = name
	
	ret._rate_get = function() return ret.object.getTransferRate() end
	ret._limit_get = function() return ret.object.getTransferRateLimit() end
	ret._limit_set = function(val)
		if type(val) ~= 'number' then error("Invalid value type for EnergyDetector.limit.") end
		ret.object.setTransferRateLimit(val)
	end
	ret.__public_keys = {name=true,
		rate=true,
		limit=true}
	
	setmetatable(ret, {
		-- getter
		__index = function(self, method)
			if string.sub(tostring(method),1,1) == "_" then return self._nil end
			return self["_"..tostring(method).."_get"]()
		end,
		-- setter
		__newindex = function(self, method, value)
			if string.sub(tostring(method),1,1) == "_" then return self._nil end
			return self["_"..tostring(method).."_set"](value)
		end,
		__tostring = function(self)
			return string.format("Energy Detector '%s' Rate: %i Limit: %i", self.name, self.rate, self.limit)
		end,
		__pairs = function(self)
			local key, value = next(self)
			local cached_kv = nil
			cached_kv = key
			return function()
				key, value = next(self, cached_kv)
				local _key = nil
				while key and not self.__public_keys[key] do
					if type(key) == 'string' and (isGetter(key) or isSetter(key)) then
						_key = key
						key = cutGetSet(key)
						value = self[key]
					else
						key, value = next(self, _key or key)
						_key = nil
					end
				end
				cached_kv = _key or key
				return key, value
			end
		end
	})
	
	return ret
end
function isGetter(key)
	local a = string.find(key,"_")
	return string.match(key, "_[a-zA-Z0-9_]+_get") ~= nil
end
function isSetter(key)
	local a = string.find(key,"_")
	return string.match(key, "_[a-zA-Z0-9_]+_set") ~= nil
end
function cutGetSet(key)
	return string.sub(key, 2, #key-4)
end

function testDefaultPeripheral()
	if energy_util.DEFAULT_ENERGY_DETECTOR == nil then
		energy_util.DEFAULT_ENERGY_DETECTOR = energy_util:EnergyDetector()
	end
end

function energy_util.getRate()
	testDefaultPeripheral()
	return energy_util.DEFAULT_ENERGY_DETECTOR.flow
end
function energy_util.getLimit()
	testDefaultPeripheral()
	return energy_util.DEFAULT_ENERGY_DETECTOR.limit
end
function energy_util.setLimit(value)
	testDefaultPeripheral()
	energy_util.DEFAULT_ENERGY_DETECTOR.limit = value
end

return energy_util

