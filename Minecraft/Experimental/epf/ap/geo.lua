--[[
	Geo Scanner peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/geo_scanner/
]]
local epf = require 'epf'

local Peripheral = {}
function Peripheral.__init(self)
	self.__getter = {
		fuel = function() return self.getFuelLevel() end,
		maxFuel = function() return self.getMaxFuelLevel() end,
		cooldown = function() return self.getScanCooldown() end,
		analyze = function() return self.chunkAnalyze() end,
		fuelRate = function() return self.getFuelConsumptionRate() end,
	}
	self.__getter.max = self.__getter.maxFuel
	self.__setter = {
		fuelRate = function(value)
			return self.setFuelConsumptionRate(value)
		end,
	}
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "geoScanner", "Geo Scanner")

local lib = {}
lib.GeoScanner = Peripheral

function lib.help()
	local text = {
		"Geo Scanner library. Contains:\n",
		"GeoScanner",
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
	__subtype="GeoScanner",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Geo Scanner (Advanced Peripherals)"
	end,
})

return lib
