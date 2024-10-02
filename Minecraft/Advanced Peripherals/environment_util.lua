--[[
	Environment Detector Utility library by PavelKom.
	Version: 0.1
	Wrapped Environment Detector
	https://advancedperipherals.netlify.app/peripherals/environment_detector/
]]

local environment_util = {}
environment_util.DEFAULT_ENVIROMENT_DETECTOR = nil

function environment_util:EnvironmentDetector(name)
	name = name or 'environmentDetector'
	local ret = {object = peripherals.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Environment Detector '"..name.."'") end
	ret.name = name
	
	ret._biome_get = function() return ret.object.getBiome() end
	ret._blockLight_get = function() return ret.object.getBlockLightLevel() end
	ret._dayLight_get = function() return ret.object.getDayLightLevel() end
	ret._skyLight_get = function() return ret.object.getSkyLightLevel() end
	ret._dimName_get = function() return ret.object.getDimensionName() end
	ret._dimPaN_get = function() return ret.object.getDimensionPaN() end
	ret._dimProvider_get = function() return ret.object.getDimensionProvider() end
	ret._moonId_get = function() return ret.object.getMoonId() end
	ret._moonPhase_get = ret._moonId_get
	ret._moonName_get = function() return ret.object.getMoonName() end
	ret._time_get = function() return ret.object.getTime() end
	ret._radiation_get = function() return ret.object.getRadiation() end
	ret._rad_get = ret._radiation_get
	ret._radiationRaw_get = function() return ret.object.getRadiationRaw() end
	ret._radRaw_get = ret._radiationRaw_get
	ret._rad2_get = ret._radiationRaw_get
	ret.isDim = function(dimension) return ret.object.isDimension(dimension) end
	ret.isMoon = function(moonPhaseId) return ret.object.isMoon(moonPhaseId) end
	ret.isRaining = function() return isRaining() end
	ret._rain_get = ret.isRaining
	ret.isSunny = function() return ret.object.isSunny() end
	ret._sunny_get = ret.isSunny
	ret.isThunder = function() return ret.object.isThunder() end
	ret._thunder_get = ret.isThunder
	ret.isSlimeChunk = function() return ret.object.isSlimeChunk() end
	ret._slimes_get = ret.isSlimeChunk
	ret._listDimensions_get = function() return ret.object.listDimensions() end
	ret._dims_get = ret.listDimensions
	ret.scanEntities = function(range) return ret.object.scanEntities() end
	ret.scan = ret.scanEntities
	
	
	ret.__public_keys = {name=true,
		biome=true,
		blockLight=true, dayLight=true, skyLight=true,
		dimName=true, dimPaN=true, dimProvider=true,
		moonId=true, moonPhase=true, moonName=true,
		time=true,
		radiation=true, rad=true,
		radiationRaw=true, radRaw=true, rad2=true,
		isDim=true,
		isMoon=true,
		isRaining=true, rain=true,
		isSunny=true, sunny=true,
		isThunder=true, thunder=true,
		isSlimeChunk=true, slimes=true,
		listDimensions=true, dims=true,
		scanEntities=true,scan=true,
		}
	
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
	if environment_util.DEFAULT_ENVIROMENT_DETECTOR == nil then
		environment_util.DEFAULT_ENVIROMENT_DETECTOR = environment_util:EnvironmentDetector()
	end
end

function environment_util.getBiome()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.biome
end
function environment_util.getBlockLight()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.blockLight
end
function environment_util.getDayLight()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.dayLight
end
function environment_util.getSkyLight()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.skyLight
end
function environment_util.getDimName()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.dimName
end
function environment_util.getDimPaN()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.dimPaN
end
function environment_util.getDimProvider()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.dimProvider
end
function environment_util.getMoonId()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.moonId
end
function environment_util.getMoonPhase()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.moonPhase
end
function environment_util.getMoonName()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.moonName
end
function environment_util.getTime()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.time
end
function environment_util.getRadiation()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.radiation
end
function environment_util.getRadiationRaw()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.radiationRaw
end
function environment_util.isDim(dimension)
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.isDim(dimension)
end
function environment_util.isMoon(moonPhaseId)
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.isMoon(moonPhaseId)
end
function environment_util.isRaining()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.rain
end
function environment_util.isSunny()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.sunny
end
function environment_util.isThunder()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.thunder
end
function environment_util.isSlimeChunk()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.slimes
end
function environment_util.getListDimensions()
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.listDimensions
end
function environment_util.scanEntities(range)
	testDefaultPeripheral()
	return environment_util.DEFAULT_ENVIROMENT_DETECTOR.scanEntities(range)
end

return environment_util
