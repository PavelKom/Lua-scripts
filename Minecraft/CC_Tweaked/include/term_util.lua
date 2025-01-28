--[[
	Terminal Utility library by PavelKom.
	Version: 0.9.5
	Simplified work with the terminal
	https://tweaked.cc/module/term.html
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
Terminal = {}
Peripheral.__items = {}
Terminal.new = function()
	if Peripheral.default then return Peripheral.default end
	local self = {}
	self.pos = getset.metaPos(term.getCursorPos, term.setCursorPos)
	self.palette = getset.metaPalette(term.getPaletteColor, term.setPaletteColor)
	
	self.__getter = {
		blink = function() return term.getCursorBlink() end,
		bg = function() return term.getBackgroundColor() end,
		fg = function() return term.getTextColor() end,
	
		size = function() return {term.getSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		color = function() return term.isColor() end,
		
		row = function() return self.pos.y end,
		col = function() return self.pos.x end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return {self.pos.xy} end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.colour = self.__getter.color
	self.__setter = {
		blink = function(value) return term.setCursorBlink(value) end,
		bg = function(value) return term.setBackgroundColor(value) end,
		fg = function(value) return term.setTextColor(value) end,
		
		x = function(value) self.pos.x = value end,
		y = function(value) self.pos.y = value end,
		xy = function(value) self.pos.xy = value end,
	}
	
	self.scroll = function (y) term.scroll(y) end
	self.write = function (text) term.write(text) end
	self.print = function(test, new_x) -- wite text + '\n' + " "*new_x
		self.write(text)
		self.pos(new_x or 1, self.pos.y + 1)
	end
	self.blit = function (text, textColour, backgroundColour) term.blit(text, textColour, backgroundColour) end
	
	self.nextLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y + 1
	end
	self.prevLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y - 1
	end
	self.getPos = function() return term.getCursorPos() end
	self.setPos = function(x, y) term.setCursorPos(x, y) end
	self.clearLine = function() term.clearLine() end
	self.clear = function() term.clear() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Terminal. Size: %ix%i Colors: %s", self.cols, self.rows, self.color)
		end,
		__type = "Terminal",
		__subtype = "utility",
	})
	if not Peripheral.default then Peripheral.default = self end
	return self
end
lib.Terminal=setmetatable(Terminal,{__call=Terminal.new,__type = "utility",__subtype="wrapper",})
lib.Term=setmetatable(Terminal,{__call=Terminal.new,__type = "utility",__subtype="wrapper",})
lib=setmetatable(lib,{__call=Terminal.new,__type = "library",__subtype="Terminal",})

return lib
