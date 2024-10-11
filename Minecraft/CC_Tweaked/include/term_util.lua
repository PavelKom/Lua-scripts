--[[
	Terminal Utility library by PavelKom.
	Version: 0.9
	Simplified work with the terminal
	https://tweaked.cc/module/term.html
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}

function this_library:Terminal()
	local ret = {}
	ret.pos = {}
	setmetatable(ret.pos, {
		__call = function(self, x_tbl, y)
			if type(x_tbl) == 'table' or (x_tbl == nil and y == nil) then
				term.setCursorPos(x_tbl[1] or x_tbl.x or 1, x_tbl[2] or x_tbl.y or 1)
			elseif x_tbl ~= nil and y ~= nil then
				term.setCursorPos(x_tbl, y)
			elseif x_tbl ~= nil and y == nil then
				local _x, _y = term.getCursorPos()
				term.setCursorPos(x_tbl, _y)
			elseif x_tbl == nil and y ~= nil then
				local _x, _y = term.getCursorPos()
				term.setCursorPos(_x, y)
			end
			return term.getCursorPos()
		end,
		__index = function(self, index)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = term.getCursorPos()
				return _x
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = term.getCursorPos()
				return _y
			elseif string.lower(tostring(index)) == 'xy' then
				return term.getCursorPos()
			end
		end,
		__newindex = function(self, index, value)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = term.getCursorPos()
				term.setCursorPos(value, _y)
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = term.getCursorPos()
				term.setCursorPos(_x, value)
			elseif string.lower(tostring(index)) == 'xy' then
				term.setCursorPos(value[1] or value.x or 1, value[2] or value.y or 1)
			end
		end,
	})
	
	ret.__getter = {
		blink = function() return term.getCursorBlink() end,
		bg = function() return term.getBackgroundColor() end,
		fg = function() return term.getTextColor() end,
	
		size = function() return {term.getSize()} end,
		rows = function() return ret.size[2] end,
		columns = function() return ret.size[1] end,
		color = function() return term.isColor() end,
		
		row = function() return ret.pos.y end,
		col = function() return ret.pos.x end,
		
		x = function() return ret.pos.x end,
		y = function() return ret.pos.y end,
		xy = function() return {ret.pos.xy} end,
	}
	ret.__getter.cols = ret.__getter.columns
	ret.__getter.colour = ret.__getter.color
	ret.__setter = {
		blink = function(value) return term.setCursorBlink(value) end,
		bg = function(value) return term.setBackgroundColor(value) end,
		fg = function(value) return term.setTextColor(value) end,
		
		x = function(value) ret.pos.x = value end,
		y = function(value) ret.pos.y = value end,
		xy = function(value) ret.pos.xy = value end,
	}
	
	ret.scroll = function (y) term.scroll(y) end
	ret.write = function (text) term.write(text) end
	ret.print = function(test, new_x) -- wite text + '\n' + " "*new_x
		ret.write(text)
		ret.pos(new_x or 1, ret.pos.y + 1)
	end
	ret.blit = function (text, textColour, backgroundColour) term.blit(text, textColour, backgroundColour) end
	
	ret.palette = {}
	local palette_meta = {
		__call = function(self, color_tbl, r, g, b) -- color_tbl is single color or table = {[key]={rgb or hex}} key - 'red', 'e' or colors.red
			if color_tbl == nil then return 
			elseif type(color_tbl) == 'table' then
				for k, v in pairs(color_tbl) do
					if type(k) == 'string' then
						if #k == 1 then -- blit
							k = colors.fromBlit(k)
						else -- name
							k = colors[k]
						end
					end
					if type(v) == 'table' then
						local _r, _g, _b = term.getPaletteColor(k) -- RGB. Allow changing only one or two channels
						term.setPaletteColour(k, v[1] or v.r or _r, v[2] or v.g or _g, v[3] or v.b or _b)
					else
						term.setPaletteColour(k, v) -- Hex
					end
				end
			elseif type(color_tbl) == 'string' then 
				if #color_tbl == 1 then -- 'e'
					local _r, _g, _b = term.getPaletteColor(colors.fromBlit(color_tbl))
					term.setPaletteColour(colors.fromBlit(color_tbl), r or _r, g or _g, b or _b)
					return r or _r, g or _g, b or _b
				else -- 'red'
					local _r, _g, _b = term.getPaletteColor(colors[color_tbl])
					term.setPaletteColour(colors[color_tbl], r or _r, g or _g, b or _b)
					return r or _r, g or _g, b or _b
				end
			else -- colors.red
				if not r and not g and not b then return  end
				local _r, _g, _b = term.getPaletteColor(index)
				term.setPaletteColour(color_tbl, r or _r, g or _g, b or _b)
				return r or _r, g or _g, b or _b
			end
		end,
		__index = function(self, index)
			if type(index) == 'string' then
				if #index == 1 then return colors.packRGB(term.getPaletteColor(colors.fromBlit(color_tbl))) end
				return colors.packRGB(term.getPaletteColor(colors[color_tbl]))
			end
			return colors.packRGB(term.getPaletteColor(index)) -- RGB to Hex
		end,
		__newindex = function(self, index, value) -- value is Hex or {rgb}
			if type(value) == 'table' then
				local _r, _g, _b = term.getPaletteColor(value) -- RGB. Allow changing only one or two channels
				term.setPaletteColour(index, value[1] or value.r or _r, value[2] or value.g or _g, value[3] or value.b or _b)
			else
				term.setPaletteColour(index, value)
			end
		end,
		__pairs = function(self)
			local key, value
			local i = 0
			return function()
				if i > 15 then return nil, nil end
				key = math.pow(2,i)
				value = {term.getPaletteColor(key)} -- rgb
				value[4] = colors.packRGB(table.unpack(value)) -- hex
				i = i + 1
				return key, value
			end
		end,
	}
	palette_meta.__ipairs = palette_meta.__pairs
	setmetatable(ret.palette, palette_meta)
	
	ret.nextLine = function()
		ret.pos.x = 1
		ret.pos.y = ret.pos.y + 1
	end
	ret.prevLine = function()
		ret.pos.x = 1
		ret.pos.y = ret.pos.y - 1
	end
	ret.getPos = function() return term.getCursorPos() end
	ret.setPos = function(x, y) term.setCursorPos(x, y) end
	ret.clearLine = function() term.clearLine() end
	ret.clear = function() term.clear() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Terminal. Size: %ix%i Colors: %s", self.cols, self.rows, self.color)
		end
	})
	return ret
end



return this_library
