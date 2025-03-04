--[[
	Energy Storage peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/generic_peripheral/energy_storage.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Energy: %i/%i", subtype(self), peripheral.getName(self), self.energy, self.capacity)
end
function Peripheral.__init(self)
	self.__getter = {
		energy = function() return self.getEnergy() end,
		capacity = function() return self.getEnergyCapacity() end,
		full = function() return self.getEnergy() == self.getEnergyCapacity() end,
		empty = function() return self.getEnergy() == 0 end,
		filled = function() return self.getEnergy() / self.getEnergyCapacity() end,
	}
	self.__getter.cap = self.__getter.capacity
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "energy_storage", "Energy Storage")

local lib = {}
lib.EnergyStorage = Peripheral

function lib.help()
	local text = {
		"Energy Storage library. Contains:\n",
		"EnergyStorage",
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
	__subtype="EnergyStorage",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Energy Storage (CC:Tweaked)"
	end,
})

return lib
