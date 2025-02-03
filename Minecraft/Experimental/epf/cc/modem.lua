--[[
	Modem peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/modem.html
]]
local epf = require 'epf'

local Peripheral = {}
function Peripheral.__init(self)
	self.__getter = {
		wireless = function() return self.isWireless() end,
	}
	if not self.isWireless() then
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

function lib.help()
	local text = {
		"Modem library. Contains:\n",
		"Modem",
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
	__name="library",
	__subtype="Modem",
	__tostring=function(self)
		return "EPF-library for Modem (CC:Tweaked)"
	end,
})

return lib
