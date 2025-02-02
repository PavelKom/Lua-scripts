--[[
	Computer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/computer.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' ID|Label: %i|'%s' Powered: %s", subtype(self), peripheral.getName(self), self.id, self.label, self.isOn)
end
function Peripheral.__init(self)
	self.__getter = {
		isOn = function() return self.isOn() end,
		label = function() return self.getLabel() end,
		id = function() return self.getID() end,
	}
	self.__setter = {}
	
	self.on = self.turnOn
	self.off = self. shutdown
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "computer", "Computer")

local lib = {}
lib.Computer = Peripheral

function lib.help()
	local text = {
		"Computer library. Contains:\n",
		"Computer",
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
	__type="library",
	__name="Computer",
	__subtype="peripheral wrapper library",
	__tostring=function(self)
		return "EPF-library for Computer (CC:Tweaked)"
	end,
})

return lib
