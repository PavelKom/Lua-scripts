--[[
	Monitor Utility library by PavelKom.
	Version: 0.9
	Wrapped Monitor
	https://tweaked.cc/peripheral/monitor.html
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

function this_library:Monitor(name)
	local def_type = 'monitor'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Monitor '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end

	ret.pos = {}
	setmetatable(ret.pos, {
		__call = function(self, x_tbl, y)
			if type(x_tbl) == 'table' then
				ret.object.setCursorPos(x_tbl[1] or x_tbl.x or 1, x_tbl[2] or x_tbl.y or 1)
			elseif x_tbl ~= nil and y ~= nil then
				ret.object.setCursorPos(x_tbl, y)
			elseif x_tbl ~= nil and y == nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(x_tbl, _y)
			elseif x_tbl == nil and y ~= nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, y)
			end
			return ret.object.getCursorPos()
		end,
		__index = function(self, index)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				return _x
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				return _y
			elseif string.lower(tostring(index)) == 'xy' then
				return ret.object.getCursorPos()
			end
		end,
		__newindex = function(self, index, value)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(value, _y)
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, value)
			elseif string.lower(tostring(index)) == 'xy' then
				ret.object.setCursorPos(value[1] or value.x or 1, value[2] or value.y or 1)
			end
		end,
	})
	
	ret.__getter = {
		scale = function() return ret.object.getTextScale() end,
		blink = function() return ret.object.getCursorBlink() end,
		bg = function() return ret.object.getBackgroundColor() end,
		fg = function() return ret.object.getTextColor() end,
	
		size = function() return {ret.object.getSize()} end,
		rows = function() return ret.size[2] end,
		columns = function() return ret.size[1] end,
		color = function() return ret.object.isColor() end,
		
		row = function() return self.pos.y end,
		col = function() return self.pos.x end,
		
		x = function() return ret.pos.x end,
		y = function() return ret.pos.y end,
		xy = function() return {ret.pos.xy} end,
	}
	ret.__getter.cols = ret.__getter.columns
	ret.__getter.colour = ret.__getter.color
	ret.__setter = {
		scale = function(value) return ret.object.setTextScale(value) end,
		blink = function(value) return ret.object.setCursorBlink(value) end,
		bg = function(value) return ret.object.setBackgroundColor(value) end,
		fg = function(value) return ret.object.setTextColor(value) end,
		
		x = function(value) ret.pos.x = value end,
		y = function(value) ret.pos.y = value end,
		xy = function(value) ret.pos.xy = value end,
	}
	
	ret.scroll = function (y) ret.object.scroll(y) end
	ret.write = function (text) ret.object.write(text) end
	ret.print = function(test, new_x) -- wite text + '\n' + " "*new_x
		ret.write(text)
		ret.pos(new_x or 1, ret.pos.y + 1)
	end
	ret.blit = function (text, textColour, backgroundColour) ret.object.blit(text, textColour, backgroundColour) end
	
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
						local _r, _g, _b = ret.object.getPaletteColor(k) -- RGB. Allow changing only one or two channels
						ret.object.setPaletteColour(k, v[1] or v.r or _r, v[2] or v.g or _g, v[3] or v.b or _b)
					else
						ret.object.setPaletteColour(k, v) -- Hex
					end
				end
			elseif type(color_tbl) == 'string' then 
				if #color_tbl == 1 then -- 'e'
					local _r, _g, _b = ret.object.getPaletteColor(colors.fromBlit(color_tbl))
					ret.object.setPaletteColour(colors.fromBlit(color_tbl), r or _r, g or _g, b or _b)
					return r or _r, g or _g, b or _b
				else -- 'red'
					local _r, _g, _b = ret.object.getPaletteColor(colors[color_tbl])
					ret.object.setPaletteColour(colors[color_tbl], r or _r, g or _g, b or _b)
					return r or _r, g or _g, b or _b
				end
			else -- colors.red
				if not r and not g and not b then return  end
				local _r, _g, _b = ret.object.getPaletteColor(index)
				ret.object.setPaletteColour(color_tbl, r or _r, g or _g, b or _b)
				return r or _r, g or _g, b or _b
			end
		end,
		__index = function(self, index)
			if type(index) == 'string' then
				if #index == 1 then return colors.packRGB(ret.object.getPaletteColor(colors.fromBlit(color_tbl))) end
				return colors.packRGB(ret.object.getPaletteColor(colors[color_tbl]))
			end
			return colors.packRGB(ret.object.getPaletteColor(index)) -- RGB to Hex
		end,
		__newindex = function(self, index, value) -- value is Hex or {rgb}
			if type(value) == 'table' then
				local _r, _g, _b = ret.object.getPaletteColor(value) -- RGB. Allow changing only one or two channels
				ret.object.setPaletteColour(index, value[1] or value.r or _r, value[2] or value.g or _g, value[3] or value.b or _b)
			else
				ret.object.setPaletteColour(index, value)
			end
		end,
		__pairs = function(self)
			local key, value
			local i = 0
			return function()
				if i > 15 then return nil, nil end
				key = math.pow(2,i)
				value = {ret.object.getPaletteColor(key)} -- rgb
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
	ret.getPos = function() return ret.object.getCursorPos() end
	ret.setPos = function(x, y) ret.object.setCursorPos(x, y) end
	ret.clearLine = function() ret.object.clearLine() end
	ret.clear = function() ret.object.clear() end
	ret.update = function() ret.object.update() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Monitor '%s' Size: %ix%i Colors: %s", self.name, self.cols, self.rows, self.color)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end



return this_library
