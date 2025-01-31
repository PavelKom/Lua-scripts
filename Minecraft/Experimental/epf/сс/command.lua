--[[
	Command Block peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.0
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

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
