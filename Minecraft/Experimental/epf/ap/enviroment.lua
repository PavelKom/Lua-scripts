--[[
	Environment Detector peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/environment_detector/
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Biome(%s) Time(%f) Rain(%s) Thunder(%s) Slime Chunk(%s)", subtype(self), peripheral.getName(self), self.biome, self.time, tostring(self.rain), tostring(self.thunder), tostring(self.slime))
end
function Peripheral.__init(self)
	self.__getter = {
		biome = function() return self.getBiome() end,
		blockLight = function() return self.getBlockLightLevel() end,
		dayLight = function() return self.getDayLightLevel() end,
		skyLight = function() return self.getSkyLightLevel() end,
		dimName = function() return self.getDimensionName() end,
		dimPaN = function() return self.getDimensionPaN() end,
		dimProvider = function() return self.getDimensionProvider() end,
		moonId = function() return self.getMoonId() end,
		moonName = function() return self.getMoonName() end,
		time = function() return self.getTime() end,
		radiation = function() return self.getRadiation() end,
		radiationRaw = function() return self.getRadiationRaw() end,
		rain = function() return self.isRaining() end,
		sunny = function() return self.isSunny() end,
		thunder = function() return self.isThunder() end,
		slimes = function() return self.isSlimeChunk() end,
		dims = function() return self.listDimensions() end,
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
	self.isDim = function(dimension) return self.isDimension(dimension) end
	self.isMoon = function(moonPhaseId) return self.isMoon(moonPhaseId) end
	self.scan = function(range) return self.scanEntities() end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "environmentDetector", "Environment Detector")

local lib = {}
lib.EnvironmentDetector = Peripheral

function lib.help()
	local text = {
		"Environment Detector library. Contains:\n",
		"EnvironmentDetector",
		"([name]) - Peripheral wrapper\n",
	}
	local c = {
		colors.red,
	}
	if term.isColor() then
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		term.setBackgroundColor(colors.black)
		for i=1, #text do
			term.setTextColor(i % 2 == 1 and colors.white or c[i/2])
			term.write(text[i])
			if i % 2 == 1 then
				local x,y = term.getCursorPos()
				term.setCursorPos(1,y+1)
			end
		end
		term.setBackgroundColor(bg)
		term.setTextColor(fg)
	else
		print(table.concat(text))
	end
end

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="EnvironmentDetector",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Environment Detector (Advanced Peripherals)"
	end,
})

return lib
