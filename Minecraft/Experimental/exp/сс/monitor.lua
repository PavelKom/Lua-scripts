--[[
	Monitor peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.1b
	https://tweaked.cc/peripheral/monitor.html
]]
local epf = require 'lib.epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Size: %ix%i Colors: %s", subtype(self), peripheral.getName(self), self.size, self.color)
end
function Peripheral.__pos_getter(self)
	return self.getCursorPos()
end
function Peripheral.__pos_setter(self, ...)
	self.setCursorPos(...)
end
Peripheral.__pos = epf.subtablePos(Peripheral,
	Peripheral.__pos_getter, Peripheral.__pos_setter, _, true)
function Peripheral.pos(self)
	Peripheral.__pos.__cur_obj = self -- On getting .pos return static pos but set current object as target
	return Peripheral.__pos
end
-- TODO: Add palette

function Peripheral.__init(self)
	self.__getter = {
		scale = function() return self.getTextScale() end,
		blink = function() return self.getCursorBlink() end,
		bg = function() return self.getBackgroundColor() end,
		fg = function() return self.getTextColor() end,
	
		size = function() return self.getSize() end,
		rows = function()
			local _s = {self.getSize()}
			return _s[2]
		end,
		columns = function()
			local _s = {self.getSize()}
			return _s[1]
		end,
		color = function() return self.isColor() end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return self.pos.xy end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.colour = self.__getter.color
	self.__setter = {
		scale = function(value) return self.setTextScale(value) end,
		blink = function(value) return self.setCursorBlink(value) end,
		bg = function(value) return self.setBackgroundColor(value) end,
		fg = function(value) return self.setTextColor(value) end,
		
		x = function(value) self.pos.x = value end,
		y = function(value) self.pos.y = value end,
		xy = function(value) self.pos.xy = value end,
	}
	self.print = function(text, new_x) -- write text + '\n' + " "*new_x
		self.write(text)
		self.setCursorPos(new_x or 1, self.pos.y + 1)
	end
	
	self.nextLine = function()
		local _p = {self.getCursorPos()}
		self.setCursorPos(1, _p[2]+1)
	end
	self.prevLine = function()
		local _p = {self.getCursorPos()}
		self.setCursorPos(1, _p[2]-1)
	end
	
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "monitor", "Monitor")

local lib = {}
lib.Monitor = Peripheral

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
