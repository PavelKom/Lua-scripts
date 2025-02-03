--[[
	Monitor peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/monitor.html
]]
local epf = require 'epf'

local lib = {}

-- Change this setting to true for static-calls pos and palette tables
lib.EXTERNAL_TABLES = false

local Peripheral = {}
function Peripheral.__str(self)
	return string.format("%s '%s' Size: %ix%i Colors: %s", subtype(self), peripheral.getName(self), self.rows, self.cols, tostring(self.color))
end
function Peripheral.__call(self, ...)
	self = Peripheral(peripheral.getName(self)) -- Regenerate monitor after add/remove parts
end

-- CURSOR POSITION
function Peripheral.__pos_getter(self)
	return self.getCursorPos()
end
function Peripheral.__pos_setter(self, ...)
	self.setCursorPos(...)
end
Peripheral.__pos = epf.subtablePos(Peripheral,
	Peripheral.__pos_getter, Peripheral.__pos_setter, _, {'static'})
function Peripheral.pos(self)
	rawset(Peripheral.__pos,'__cur_obj',self) -- On getting .pos return static pos but set current object as target
	return Peripheral.__pos
end

-- PALETTE
function Peripheral.__palette_getter(self, ...)
	return self.getPaletteColor(...)
end
function Peripheral.__palette_setter(self, ...)
	self.setPaletteColor(...)
end
Peripheral.__palette = epf.subtablePalette(Peripheral,
	Peripheral.__palette_getter, Peripheral.__palette_setter, {'static'})
function Peripheral.palette(self)
	rawset(Peripheral.__palette,'__cur_obj',self)
	return Peripheral.__palette
end

function Peripheral.__init(self)
	if not lib.EXTERNAL_TABLES then
		self.pos = epf.subtablePos(self,
			self.getCursorPos, self.setCursorPos)
		self.palette = epf.subtablePalette(self,
		self.getPaletteColor, self.setPaletteColor)
	end
	
	self.__getter = {
		scale = function() return self.getTextScale() end,
		blink = function() return self.getCursorBlink() end,
		bg = function() return self.getBackgroundColor() end,
		fg = function() return self.getTextColor() end,
	
		size = function() return {self.getSize()} end,
		rows = function() return ({self.getSize()})[2] end,
		columns = function() return ({self.getSize()})[1] end,
		color = function() return self.isColor() end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return self.pos.xy end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.colour = self.__getter.color
	self.__getter.row = self.__getter.y
	self.__getter.column = self.__getter.x
	self.__getter.col = self.__getter.x
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

lib.Monitor = Peripheral

function lib.help()
	local text = {
		"Monitor library. Contains:\n",
		"Monitor",
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
	__subtype="Monitor",
	__tostring=function(self)
		return "EPF-library for Monitor (CC:Tweaked)"
	end,
})

return lib
