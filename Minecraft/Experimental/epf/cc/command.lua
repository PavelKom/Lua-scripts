--[[
	Command Block peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/command.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Stored command: '%s'", subtype(self), peripheral.getName(self), self.command)
end
function Peripheral.__init(self)
	self.__getter = {
		command = function() return self.getCommand() end,
	}
	self.__setter = {
		command = function(value) self.setCommand(value) end
	}
	self.run =  function() return self.runCommand() end -- Alias for runCommand
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "command", "Command Block")

local lib = {}
lib.CommandBlock = Peripheral

function lib.help()
	local text = {
		"Command Block library. Contains:\n",
		"CommandBlock",
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
	__name="CommandBlock",
	__subtype="peripheral wrapper library",
	__tostring=function(self)
		return "EPF-library for Command Block (CC:Tweaked)"
	end,
})

return lib
