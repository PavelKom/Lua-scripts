--[[
	Environment Detector Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Environment Detector
	https://advancedperipherals.netlify.app/peripherals/environment_detector/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'environmentDetector', 'Environment Detector', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		biome = function() return self.object.getBiome() end,
		blockLight = function() return self.object.getBlockLightLevel() end,
		dayLight = function() return self.object.getDayLightLevel() end,
		skyLight = function() return self.object.getSkyLightLevel() end,
		dimName = function() return self.object.getDimensionName() end,
		dimPaN = function() return self.object.getDimensionPaN() end,
		dimProvider = function() return self.object.getDimensionProvider() end,
		moonId = function() return self.object.getMoonId() end,
		moonName = function() return self.object.getMoonName() end,
		time = function() return self.object.getTime() end,
		radiation = function() return self.object.getRadiation() end,
		radiationRaw = function() return self.object.getRadiationRaw() end,
		rain = function() return self.object.isRaining() end,
		sunny = function() return self.object.isSunny() end,
		thunder = function() return self.object.isThunder() end,
		slimes = function() return self.object.isSlimeChunk() end,
		dims = function() return self.object.listDimensions() end,
	}
	self.__getter.weather = function()
		if self.sunny then return 0, 'sunny'
		elseif self.rain then return 1, 'rain'
		else return 2, 'thunder' end
	end
	self.__getter.moon = function() return {self.moonId, self.moonName} end
	self.__getter.moonPhase = self.__getter.moonId
	self.__getter.rad = self.__getter.radiation
	self.__getter.radRaw = self.__getter.radiationRaw
	self.__getter.rad2 = self.__getter.radiationRaw
	self.isRaining = self.__getter.rain
	self.isSunny = self.__getter.sunny
	self.isThunder = self.__getter.thunder
	self.isSlimeChunk = self.__getter.slimes
	self.isDim = function(dimension) return self.object.isDimension(dimension) end
	self.isMoon = function(moonPhaseId) return self.object.isMoon(moonPhaseId) end
	self.scanEntities = function(range) return self.object.scanEntities() end
	self.scan = self.scanEntities
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Biome(%s) Time(%f) Rain(%s) Thunder(%s) Slime Chunk(%s)", type(self), self.name, self.biome, self.time, tostring(self.rain), tostring(self.thunder), tostring(self.slime))
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Environment Detector"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.EnvironmentDetector=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.getBiome()
	testDefaultPeripheral()
	return Peripheral.default.biome
end
function lib.getBlockLight()
	testDefaultPeripheral()
	return Peripheral.default.blockLight
end
function lib.getDayLight()
	testDefaultPeripheral()
	return Peripheral.default.dayLight
end
function lib.getSkyLight()
	testDefaultPeripheral()
	return Peripheral.default.skyLight
end
function lib.getDimName()
	testDefaultPeripheral()
	return Peripheral.default.dimName
end
function lib.getDimPaN()
	testDefaultPeripheral()
	return Peripheral.default.dimPaN
end
function lib.getDimProvider()
	testDefaultPeripheral()
	return Peripheral.default.dimProvider
end
function lib.getMoonId()
	testDefaultPeripheral()
	return Peripheral.default.moonId
end
function lib.getMoonPhase()
	testDefaultPeripheral()
	return Peripheral.default.moonPhase
end
function lib.getMoonName()
	testDefaultPeripheral()
	return Peripheral.default.moonName
end
function lib.getTime()
	testDefaultPeripheral()
	return Peripheral.default.time
end
function lib.getRadiation()
	testDefaultPeripheral()
	return Peripheral.default.radiation
end
function lib.getRadiationRaw()
	testDefaultPeripheral()
	return Peripheral.default.radiationRaw
end
function lib.isDim(dimension)
	testDefaultPeripheral()
	return Peripheral.default.isDim(dimension)
end
function lib.isMoon(moonPhaseId)
	testDefaultPeripheral()
	return Peripheral.default.isMoon(moonPhaseId)
end
function lib.isRaining()
	testDefaultPeripheral()
	return Peripheral.default.rain
end
function lib.isSunny()
	testDefaultPeripheral()
	return Peripheral.default.sunny
end
function lib.isThunder()
	testDefaultPeripheral()
	return Peripheral.default.thunder
end
function lib.isSlimeChunk()
	testDefaultPeripheral()
	return Peripheral.default.slimes
end
function lib.getListDimensions()
	testDefaultPeripheral()
	return Peripheral.default.dims
end
function lib.scanEntities(range)
	testDefaultPeripheral()
	return Peripheral.default.scanEntities(range)
end

return lib
