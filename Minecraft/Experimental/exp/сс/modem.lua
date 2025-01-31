--[[
	Modem peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.0
	https://tweaked.cc/peripheral/modem.html
]]
local epf = require 'lib.epf'

local Peripheral = {}
function Peripheral.__init(self)
	self.__getter = {
		wireless = function() return self.isWireless() end,
	}
	if not self.isWireless() end
		self.__getter.namesRemote = function() return self.getNamesRemote() end
		self.__getter.nameLocal = function() return self.getNameLocal() end
		
		
		self.isPresent = function(name) return self.isPresentRemote(name) end
		self.getType = function(name) return self.getTypeRemote(name) end
		self.hasType = function(name, _type) return self.hasTypeRemote(name, _type) end
		self.methods = function(name) return self.getMethodsRemote(name) end
		self.call = function(remoteName, method, ...) return self.callRemote(remoteName, method, ...) end
	end
	-- Change close(): close(nil) == closeAll()
	self.close_ = self.close
	self.close = function(channel)
		if channel then return self.close_(channel) end
		self.closeAll()
	end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "modem", "Modem")

local lib = {}
lib.Modem = Peripheral

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
