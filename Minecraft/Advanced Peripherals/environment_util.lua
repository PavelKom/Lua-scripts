--[[
	Environment Detector Utility library by PavelKom.
	Version: 0.9
	Wrapped Environment Detector
	https://advancedperipherals.netlify.app/peripherals/environment_detector/
	TODO: Add manual
]]

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:EnvironmentDetector(name)
	name = name or 'environmentDetector'
	local ret = {object = peripheral.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Environment Detector '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	
	ret.__getter = {
		biome = function() return ret.object.getBiome() end,
		blockLight = function() return ret.object.getBlockLightLevel() end,
		dayLight = function() return ret.object.getDayLightLevel() end,
		skyLight = function() return ret.object.getSkyLightLevel() end,
		dimName = function() return ret.object.getDimensionName() end,
		dimPaN = function() return ret.object.getDimensionPaN() end,
		dimProvider = function() return ret.object.getDimensionProvider() end,
		moonId = function() return ret.object.getMoonId() end,
		moonName = function() return ret.object.getMoonName() end,
		time = function() return ret.object.getTime() end,
		radiation = function() return ret.object.getRadiation() end,
		radiationRaw = function() return ret.object.getRadiationRaw() end,
		rain = function() return ret.object.isRaining() end,
		sunny = function() return ret.object.isSunny() end,
		thunder = function() return ret.object.isThunder() end,
		slimes = function() return ret.object.isSlimeChunk() end,
		dims = function() return ret.object.listDimensions() end,
	}
	ret.__getter.moonPhase = ret.__getter.moonId
	ret.__getter.rad = ret.__getter._radiation
	ret.__getter.radRaw = ret.__getter.radiationRaw
	ret.__getter.rad2 = ret.__getter.radiationRaw
	ret.isRaining = ret.__getter.rain
	ret.isSunny = ret.__getter.sunny
	ret.isThunder = ret.__getter.thunder
	ret.isSlimeChunk = ret.__getter.slimes
	ret.isDim = function(dimension) return ret.object.isDimension(dimension) end
	ret.isMoon = function(moonPhaseId) return ret.object.isMoon(moonPhaseId) end
	ret.scanEntities = function(range) return ret.object.scanEntities() end
	ret.scan = ret.scanEntities
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Environment Detector '%s' Biome(%s) Time(%f) Rain(%s) Thunder(%s) Slime Chunk(%s)", self.name, self.biome, self.time, tostring(self.rain), tostring(self.thunder), tostring(self.slime))
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:EnvironmentDetector()
	end
end

function this_library.getBiome()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.biome
end
function this_library.getBlockLight()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.blockLight
end
function this_library.getDayLight()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.dayLight
end
function this_library.getSkyLight()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.skyLight
end
function this_library.getDimName()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.dimName
end
function this_library.getDimPaN()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.dimPaN
end
function this_library.getDimProvider()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.dimProvider
end
function this_library.getMoonId()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.moonId
end
function this_library.getMoonPhase()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.moonPhase
end
function this_library.getMoonName()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.moonName
end
function this_library.getTime()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.time
end
function this_library.getRadiation()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.radiation
end
function this_library.getRadiationRaw()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.radiationRaw
end
function this_library.isDim(dimension)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isDim(dimension)
end
function this_library.isMoon(moonPhaseId)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isMoon(moonPhaseId)
end
function this_library.isRaining()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.rain
end
function this_library.isSunny()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.sunny
end
function this_library.isThunder()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.thunder
end
function this_library.isSlimeChunk()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.slimes
end
function this_library.getListDimensions()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.dims
end
function this_library.scanEntities(range)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.scanEntities(range)
end

return this_library
