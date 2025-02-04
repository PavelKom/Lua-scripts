--[[
	Energy Detector peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/energy_detector/
]]
local epf = require 'epf'
local expect = require "cc.expect"
local expect = expect.expect

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Rate: %i Limit: %i", subtype(self), peripheral.getName(self), self.rate, self.limit)
end
function Peripheral.__init(self)
	self.__getter = {
		rate = function() return self.getTransferRate() end,
		limit = function() return self.getTransferRateLimit() end,
	}
	self.__setter = {
		limit = function(val)
			expect(1, val, "number")
			if val < 0 then val = math.huge end -- Not tested
			self.setTransferRateLimit(val)
		end,
	}
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "energyDetector", "Energy Detector")

local lib = {}
lib.EnergyDetector = Peripheral

function lib.help()
	local text = {
		"Energy Detector library. Contains:\n",
		"EnergyDetector",
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
	__subtype="EnergyDetector",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Energy Detector (Advanced Peripherals)"
	end,
})

return lib
