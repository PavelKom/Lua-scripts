--[[
	Monitor Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Monitor
	https://tweaked.cc/peripheral/monitor.html
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Monitor')
	if wrapped ~= nil then return wrapped end
	
	self.pos = getset.metaPos(self.object.getCursorPos, self.object.setCursorPos)
	self.palette = getset.metaPalette(self.object.getPaletteColor, self.object.setPaletteColor)
	
	self.__getter = {
		scale = function() return self.object.getTextScale() end,
		blink = function() return self.object.getCursorBlink() end,
		bg = function() return self.object.getBackgroundColor() end,
		fg = function() return self.object.getTextColor() end,
	
		size = function() return {self.object.getSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		color = function() return self.object.isColor() end,
		
		row = function() return self.pos.y end,
		col = function() return self.pos.x end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return {self.pos.xy} end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.colour = self.__getter.color
	self.__setter = {
		scale = function(value) return self.object.setTextScale(value) end,
		blink = function(value) return self.object.setCursorBlink(value) end,
		bg = function(value) return self.object.setBackgroundColor(value) end,
		fg = function(value) return self.object.setTextColor(value) end,
		
		x = function(value) self.pos.x = value end,
		y = function(value) self.pos.y = value end,
		xy = function(value) self.pos.xy = value end,
	}
	
	self.scroll = function (y) self.object.scroll(y) end
	self.write = function (text) self.object.write(text) end
	self.print = function(text, new_x) -- write text + '\n' + " "*new_x
		self.object.write(text)
		self.object.setCursorPos(new_x or 1, self.pos.y + 1)
	end
	self.blit = function (text, textColour, backgroundColour) self.object.blit(text, textColour, backgroundColour) end
	
	
	self.nextLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y + 1
	end
	self.prevLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y - 1
	end
	self.getPos = function() return self.object.getCursorPos() end
	self.setPos = function(x, y) self.object.setCursorPos(x, y) end
	self.clearLine = function() self.object.clearLine() end
	self.clear = function() self.object.clear() end
	self.update = function()
		self.object = peripheral.wrap(self.name)
		self.pos = getset.metaPos(self, self.object.getCursorPos, self.object.setCursorPos)
		self.palette = getset.metaPalette(self, self.object.getPaletteColor, self.object.setPaletteColor)
		return self.object ~= nil
	end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Size: %ix%i Colors: %s", type(self), self.name, self.cols, self.rows, self.color)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Monitor",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Monitor=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="monitor",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Monitor",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
