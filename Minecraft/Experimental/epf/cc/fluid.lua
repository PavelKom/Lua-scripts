--[[
	Fluid Storage peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/generic_peripheral/fluid_storage.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Tanks: %i", subtype(self), peripheral.getName(self), #self.tanks)
end
function Peripheral.__init(self)
	self.getTanks = self.tanks
	self.tanks = nil
	self.__getter = {
		tanks = function() return self.getTanks() or {} end,
	}
	self.push = self.pushFluid
	self.pull = self.pullFluid
	
	return self
end
local function _ipairs(self)
	local tanks = self.tanks
	local key, value
	return function()
		key, value = next(tanks, key)
		if key == nil then return nil, nil end
		return key, value
	end
end
local function _len(self)
	return #self.tanks
end
function Peripheral.__init_post(self)
	local _m = getmetatable(self)
	_m.__ipairs = _ipairs
	_m.__len = _len
	return self
end

Peripheral = epf.wrapperFixer(Peripheral, "fluid_storage", "Fluid Storage")

local lib = {}
lib.FluidStorage = Peripheral

function lib.help()
	local text = {
		"Fluid Storage library. Contains:\n",
		"FluidStorage",
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
	__subtype="FluidStorage",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Fluid Storage (CC:Tweaked)"
	end,
})

return lib
