--[[
	Display Link peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Display-Link-%28Peripheral%29
]]
local epf = require 'epf'

local lib = {}
-- Change this setting to true for static-calls pos and palette tables
lib.EXTERNAL_TABLES = false

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Size: %ix%i Colors: %s", subtype(self), peripheral.getName(self), self.rows, self.cols, tostring(self.color))
end
function Peripheral.__call(self, ...)
	self = Peripheral(peripheral.getName(self)) -- Regenerate display link after add/remove parts
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


function Peripheral.__init(self)
	if not lib.EXTERNAL_TABLES then
		self.pos = epf.subtablePos(self,
			self.getCursorPos, self.setCursorPos)
	end
	self.__getter = {
		size = function() return {self.getSize()} end,
		rows = function() return ({self.getSize()})[2] end,
		columns = function() return ({self.getSize()})[1] end,
		color = function() return self.isColor() end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return {self.pos.xy} end,
	}
	self.__getter.row = self.__getter.y
	self.__getter.column = self.__getter.x
	self.__getter.cols = self.__getter.columns
	self.__getter.col = self.__getter.column
	self.__getter.colour = self.__getter.color
	
	self.__setter = {
		x = function(value) self.pos.x = value end,
		y = function(value) self.pos.y = value end,
		xy = function(value) self.pos.xy = value end,
	}
	
	self.nextLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y + 1
	end
	self.prevLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y - 1
	end
	self.getPos = function() return self.getCursorPos() end
	self.setPos = function(x, y) self.setCursorPos(x, y) end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_DisplayLink", "Display Link")

lib.DisplayLink = Peripheral
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="DisplayLink",
	__name="library",
})
return lib
