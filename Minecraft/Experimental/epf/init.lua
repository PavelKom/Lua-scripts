--[[
Extended Peripherals Framework
Author: PavelKom
Version 2.3.1
	
Library for extending wrapped peripheral by adding get/set properties and other.

All methods started with __ (double underscore) is hide for pairs and ipairs. By default.

For example see example.lua

@changed 2.1b Added pos sub-table.
@changed 2.2 Added pallete sub-table. Tested: pos and palette subtables.
@changed 2.3 Added side sub-table, text splitting methods, instrument names. Tested.
]]

-- Patches
require "lib.patches"

-- You can set this library as global API by createing setting
--[[ Define setting
settings.define("_EPF_GLOBAL", {
    description = "Add Extended Peripherals Framework to global table on startup",
    default = true,
    type = "boolean",
})

]]
if settings.get("_EPF_GLOBAL", false) and _G.epf then
	return _G.epf
end

local expect = dofile("rom/modules/main/cc/expect.lua").expect

local epf = {}

settings.define("_EPF_TAB", {
    description = "Tabulate length",
    default = 1,
    type = "number",
})

--[[
	Getter metamethod. With static.
	local a = Test()
	print(a.b) -> Test.__getter.b(a) -- Get property
	a.c() -> Test.c(a) -- Call method
	print(Test.b) -> Test.__getter.b(nil)
	print(Test.c) -> Test.c(nil)
	
	@tparam table cls Class constructor
	@treturn function Property getter metamethod
]]
function epf.GETTER2(cls)
	return function(self, index)
		if self ~= cls then -- Get property | call static method
			if self.__getter and self.__getter[index] then -- internal/class object getter
				return self.__getter[index]()
			elseif cls.__getter and cls.__getter[index] then -- external/class getter
				return cls.__getter[index](self)
			elseif cls and cls[index] then -- class method
				return cls[index](self)
			end
			error("Can't get value from '"..tostring(self)..'().'..tostring(index).."'")
		else
			if self.__getter and self.__getter[index] then -- external/class getter
				return self.__getter[index](nil)
			elseif self and self[index] then -- class method
				return self[index](nil)
			end
			error("Can't get value from '"..tostring(cls)..'().'..tostring(index).."'")
		end
	end
end

--[[
	Setter metamethod. With static.
	local a = Test()
	a.b = 7 -> Test.__setter.b(a, 7)
	Test.c = 12 -> Test.__setter.c(nil, 12) -- For static values
	
	@tparam table cls Class constructor
	@treturn function Property setter metamethod
]]
function epf.SETTER2(cls)
	return function(self, index, value)
		if self ~= cls then -- Set property
			if self.__setter and self.__setter[index] then
				return self.__setter[index](value)
			elseif cls.__setter and cls.__setter[index] then
				return cls.__setter[index](self, value)
			end
		else
			if self.__setter and self.__setter[index] then
				return self.__setter[index](nil, value)
			end
		end
		error("Can't set value to '"..tostring(cls)..'().'..tostring(index).."'")
	end
end

--[[
	Iterator for pairs(). Return methods, getters, setters with static.
	Return tables with names of
		1: {{object},{static}} methods
		2: {{object},{static}} getters
		3: {{object},{static}} setters
	@tparam table cls Class constructor
	@treturn function Object iterator
]]
function epf.PAIRS2(cls)
	return function(self)
		local key, value, k2, k3
		local names = {'method','getter','setter',}
		return function()
			k3, key = next(names, k3)
			if key == nil then 
				return nil, nil
			end
			value = {{},{}} -- { {object}, {static} }
			if key == 'method' then
				k2 = next(self)
				while k2 do
					if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
						value[1][#value[1]+1] = tostring(k2)
					end
					k2 = next(self, k2)
				end
				k2 = next(cls)
				while k2 do
					if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
						value[2][#value[2]+1] = k2
					end
					k2 = next(cls, k2)
				end
			end
			if key == 'getter' then
				if self.__getter then
					k2 = next(self.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[1][#value[1]+1] = k2
						end
						k2 = next(self.__getter, k2)
					end
				end
				if cls and cls.__getter then
					k2 = next(cls.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[2][#value[2]+1] = k2
						end
						k2 = next(cls.__getter, k2)
					end
				end
			end
			if key == 'setter' then
				if self.__setter then
					k2 = next(self.__setter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[1][#value[1]+1] = k2
						end
						k2 = next(self.__setter, k2)
					end
				end
				if cls and cls.__setter then
					k2 = next(cls.__setter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[2][#value[2]+1] = k2
						end
						k2 = next(cls.__setter, k2)
					end
				end
			end
			return key, value
		end
	end
end

--[[
	Iterator for pairs(). Return methods, getters, setters with static.
	Return table with names of methods, getters and setters. UNSORTED!!!
	@tparam table cls Class constructor
	@treturn function Object iterator
]]
function epf.IPAIRS2(cls)
	return function(self)
		local key, value, k2, v2
		local keys = {}
		k2, v2 = next(self)
		while k2 do
			if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
				keys[k2] = v2
			end
			k2, v2 = next(self, k2)
		end
		k2, v2 = next(cls)
		while k2 do
			if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
				keys[k2] = v2
			end
			k2, v2 = next(cls, k2)
		end
		if self.__getter then
			k2, v2 = next(self.__getter)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil and keys[k2] == nil then
					keys[k2] = self.__getter[k2]
				end
				k2, v2 = next(self.__getter, k2)
			end
			k2, v2 = next(self.__getter)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil and keys[k2] == nil then
					keys[k2] = self.__getter[k2]
				end
				k2, v2 = next(self.__getter, k2)
			end
		end
		if self.__setter then
			k2, v2 = next(self.__setter)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil and keys[k2] == nil then
					keys[k2] = self.__setter[k2]
				end
				k2, v2 = next(self.__setter, k2)
			end
		end
		return function()
			key, value = next(keys, key)
			return key, value
		end
	end
end

--[[
	Equality metamethod
	@tparam table self First object
	@tparam table other Second object
	@treturn boolean Equality result
]]
function epf.EQUAL(self, other)
	return	custype(self) == custype(other) and -- both peripherals or wrappers
			subtype(self) == subtype(other) and -- same peripheral type (Modem)
			self.type == other.type and -- same peripheral name (modem)
			peripheral.getName(self) == peripheral.getName(other) -- same name (modem_0)
end

--[[
	Default tostring for wrappers.
	@tparam table self Wrapper
	@treturn string tostring() result
]]
function epf.WRAPPER_STR(self)
	return string.format("Peripheral wrapper for %s (%s)", subtype(self), self.type)
end

--[[
	Metamethod for uppering the case of keys (attempt at case insensitivity)
	self.aBc -> self.ABC
	@param default Default value
	@treturn function __index metametod
]]
epf.GETTER_TO_UPPER = function(default)
	return function(self, index)
		if tostring(index) == string.upper(tostring(index)) then return default end
		return self[string.upper(tostring(index))]
	end
end
--[[
	Metamethod for lowering the case of keys (attempt at case insensitivity)
	self.aBc -> self.abc
	@param default Default value
	@treturn function __index metametod
]]
epf.GETTER_TO_LOWER = function(default)
	return function(self, index)
		if tostring(index) == string.lower(tostring(index)) then return default end
		return self[string.lower(tostring(index))]
	end
end
--[[
	Metamethod for __call, return true if argument founded as key (using with getters)
	@tparam table self Table for meta
	@treturn boolean Index in table
]]
epf.CALL_INSIDE = function(self, arg)
	return rawget(self, arg) ~= nil
end
--[[
	Metamethod for __call, return value if argument founded as key (using with getters)
	@tparam table self Table for meta
	@return Value
]]
epf.CALL_INSIDE_VAL = function(self, arg)
	return rawget(self, arg)
end
--[[
	Metamethod for __call, return key if argument founded as key (using with getters)
	@tparam table self Table for meta
	@return Key
]]
epf.CALL_INSIDE_KEY = function(self, arg)
	return rawget(self, arg) and arg or nil
end

--[[
	Proxy-table for converting 'yes','no',... to boolean
]]
epf.STRING_TO_BOOLEAN = {}
for k,v in pairs{true, "true", "t", "yes", "y", 1, "1"} do
	epf.STRING_TO_BOOLEAN[v] = true
end
for k,v in pairs{false, "false", "f", "no", "n", 0, "0"} do
	epf.STRING_TO_BOOLEAN[v] = false
end
setmetatable(epf.STRING_TO_BOOLEAN, {
	__call = function(self, value)
		if type(value) == 'boolean' then
			return value
		elseif type(value) == 'string' and self[string.lower(value)] ~= nil then
			return self[string.lower(value)]
		else return nil end
	end
})

--[[
	Fix wrapper table.
	Note: Call this function at the end of your work with configuring your peripheral wrapper.
	@tparam table|nil tbl Peripheral wrapper table or nil
	@tparam string|nil _type Peripheral type (ex: modem)
	@tparam string|nil _name Peripheral name (ex: Modem)
	@treturn table Fixed wrapper table
]]
function epf.wrapperFixer(tbl, _type, _name)
	if type(tbl) ~= 'table' then tbl = {} end

	-- Example: type == 'modem', __subtype == 'Modem'
	tbl.type = tbl.type or _type or error("Peripheral type not specific")
	tbl.__subtype = tbl.__subtype or _name or error("Peripheral type not specific")

	local _m = getmetatable(tbl) or {}
	_m.__call = _m.__call
	if not tbl.new then
		tbl.new = epf.simpleNew(tbl)
	end
	if not _m.__call then
		if tbl.new then _m.__call = function(self,...) return tbl.new(...) end
		else _m.__call = function(self,...) return epf.simpleNew(tbl) end
		end
	end
	_m.__name= "peripheral wrapper"
	_m.__subtype= _m.__subtype or tbl.__subtype
	_m.__eq= _m.__eq or tbl.__eq or epf.EQUAL
	_m.__tostring = _m.__tostring or tbl.__tostring or epf.WRAPPER_STR
	
	return setmetatable(tbl, _m)
end

--[[
	Constructor for tbl.new(name). Analog of __new__ in Python.
	May call the tbl.__init(obj) function to post-initialize the class object. Analog of __init__ in Python.
	@tparam table|nil tbl Peripheral wrapper table
	@treturn table Fixed wrapper table
]]
function epf.simpleNew(tbl)
	assert(type(tbl) == 'table', "Peripheral (or wrapper) not specific")
	return function(name)
		local self = name and peripheral.wrap(name) or peripheral.find(tbl.type)
		assert(self, string.format("Peripheral '%s' not founded", name and name or tbl.type))
		assert(peripheral.hasType(self, tbl.type), string.format("Peripheral '%s' does not contain '%s' among its types", name, tbl.type))
		name = name or peripheral.getName(self)
		-- Get wrapped peripheral if it already registered
		if tbl.__names and tbl.__names[name] then
			return tbl.__names[name]
		end
		
		self.__getter = {}
		self.__setter = {}
		local _m = getmetatable(self)
		
		-- Pre initialise
		if type(tbl.__init) == 'function' then
			self = tbl.__init(self)
		end
	
		-- Generate metamethods for class on first load.
		-- To protect against re-creation of identical functions
		if not tbl.__metas then
			tbl.__metas = {}
			tbl.__metas.__index = epf.GETTER2(tbl)
			tbl.__metas.__newindex = epf.SETTER2(tbl)
			tbl.__metas.__pairs = epf.PAIRS2(tbl)
			tbl.__metas.__ipairs = epf.IPAIRS2(tbl)
			tbl.__metas.__tostring = function(self) return subtype(self).." '"..(name or type(self)).."'" end
		end
		
		_m.__index = tbl.__metas.__index
		_m.__newindex = tbl.__metas.__newindex
		_m.__pairs = tbl.__metas.__pairs
		_m.__ipairs = tbl.__metas.__ipairs
		_m.__tostring = tbl.__str or tbl.__metas.__tostring -- tbl.__str -- tostring for objects
		_m.__call = tbl.__call or nil -- Caller for object.  Test.__call(obj)
		_m.__eq = tbl.__eq or epf.EQUAL
		_m.__subtype = tbl.__subtype
		_m.__super = tbl -- For getting wrapper
		
		-- Post initialise
		if type(tbl.__init_post) == 'function' then
			self = tbl.__init_post(self)
		end
		
		-- Register wrapped peripheral for avoiding re-initialise
		tbl.__names = tbl.__names or {}
		tbl.__names[name] = self
		
		return setmetatable(self, _m)
	end
end

--[[
	Add subtable for manipulating nD positions.
	Getter and setters must return/require array of values like ... , NOT TABLE!!!
	Example:
	GET VALUE
		pos.x -- return 'x' coordinate
		pos[1] -- error
		pos['1'] -- allowed, but '10','11',... is not!
		Fox hexademical: pos['0123456789abcdef']
		pos.xy -- return {x,y}
	SET VALUE
		pos.x = 7
		pos.xy = {1,2} -- By index
		pos.xy = {x=1,y=2} -- By name
		pos() -- Reset to (1,1,...)
		pos(1,2) -- == pos.xy = {1,2}
		pos(_,2) -- == pos.y = 2
		pos({1,2}) -- == pos.xy = {1,2}
		pos({x=1,y=2}) -- == pos.xy = {x=1,y=2}
		Note: pos.xy = {1,2,x=3,y=4} -- xy={3,4} Names have higher priority than indexes
	ITERATE
		for k,v in pairs(pos) do -- Iterate by name
			print(tostring(k).."="..tostring(v)) -- x=1 y=2 ...
		end
		for k,v in ipairs(pos) do -- Iterate by index
			print(tostring(k).."="..tostring(v)) -- 1=1 2=2 ...
		end
	
	@tparam table tbl Wrapped peripheral or Peripheral wrapper
	@tparam function getter Coordinate getter function.
	@tparam function|nil setter Coordinate setter function
	@tparam[opt={'x','y'}] {string,...} keys Coordinate names. Must be unique!
	@tparam[opt=nil] table cfg Config array-like table. Allowed configs: 'static'
	@treturn table pos sub-table for nD movement
]]
function epf.subtablePos(tbl, getter, setter, keys, cfg)
	expect(1, tbl, "peripheral", 'peripheral wrapper', 'table')
	expect(2, getter, "function")
	expect(3, setter, "function", "nil")
	expect(4, keys, "table", "nil")
	expect(5, cfg, "table", "nil")
	--assert(type(tbl) == 'table', "Peripheral wrapper not specific")
	--assert(type(getter) == 'function', "Position getter not specific")
	--assert(setter == nil or type(setter) == 'function',
	--	"Position setter not nil/function")
	
	-- Create pos sub-table
	local pos = {__keys = keys  or {'x', 'y'}, __cur_obj=nil}
	pos.__reverse = {}
	for k,v in pairs(pos.__keys) do
		pos.__reverse[v] = k
	end
	local _m = {
		__super=tbl, -- Connect to tbl
		__len=function(self) return #self.__keys end,
	}
	local _cfg = {}
	for k,v in pairs(cfg or {}) do _cfg[v] = k end
	-- Create functions from scrap
	
	-- Convert index to array
	local index_table = [[local _ti = {}
	if type(index) == 'string' then
		_ti = string.split(index)
	elseif type(index) == 'number'
		then _ti[#_ti+1] = self.__keys[index] or error('Invalid position index'..tostring(index))
	elseif type(index) == 'table' then
		_ti = {table.unpack(index)}
	end]]
	
	-- Check call is static
	local _static = _cfg.static and "self.__cur_obj" or ""
	
	-- Getter
	local _getter = string.format([[local _pos={...}
	local getter=_pos[1]
	local setter=_pos[2]
	return function(self, index)
		%s
		local _r = {}
		local _p = {getter(%s)}
		for _, v2 in pairs(_ti) do
			for k,v in pairs(_p) do
				if self.__keys[k] == v2 then
					_r[#_r+1] = v
					break
				end
			end
		end
		if #_r == 1 then
			_r = _r[1]
		end
		return _r
	end]],index_table,_static)
	
	-- Ipairs. Iterate coordinates by position
	local _ipairs = string.format([[, function(self)
		local _pos = {getter(%s)}
		--REPLACEMEFORPAIRS--
		local key, value
		return function()
			key, value = next(_pos, key)
			if key == nil then return nil, nil end
			return key, value
		end
	end]], _static)
	-- Quickfix for pairs
	local _pairs = string.replace(_ipairs, "--REPLACEMEFORPAIRS--",
	[[for k,v in pairs(_pos) do
		if type(k) == 'number' then
			_pos[ self.__keys[k] ] = v
			_pos[k] = nil
		end
	end]])
	local _setter, _caller = "", ""
	if setter then -- Add setter and caller
		_setter=string.format([[, function(self, index, value)
			%s
			if type(value) ~= 'table' then
				value = {value}
			end
			local _p = {getter(%s)}
			local _i = 1
			for k,v in pairs(_p) do
				for _,v in pairs(_ti) do
					if self.__keys[k] == v then
						_p[k] = value[v] or value[_i] or _p[k]
						_i = _i + 1
					end
				end
			end
			setter(%stable.unpack(_p))
		end]], index_table, _static, _cfg.static and "self.__cur_obj, " or "")
		
		_caller=[[, function(self, ...)
			local _arg = {...}
			local index = ''
			if #_arg == 0 then
				for k,v in ipairs(self.__keys) do
					_arg[k] = 1
					index = index..v
				end
			elseif type(_arg[1]) == 'table' then
				_arg=_arg[1]
				for k,v in ipairs(self.__keys) do
					if _arg[k] or _arg[v] then
						_arg[k] = _arg[k] or _arg[v]
						_arg[v] = nil
						index = index..v
					end
				end
			else
				for k=1,#_arg do
					index = index..self.__keys[k]
				end
			end
			self[index] = _arg
		end]]
	end
	
	local buffer = _getter.._ipairs.._pairs.._setter.._caller
	local _f, err = load(buffer)
	if not _f then error(err) end
	_m.__index,_m.__ipairs,_m.__pairs,_m.__newindex,_m.__call = _f(getter, setter)
	
	_m.__tostring = function(self)
		return string.format("%iD getter/setter", #self)
	end
	
	return setmetatable(pos, _m)
end

local colorNames = {
'white','orange','magenta','lightBlue',
'yellow','lime','pink','gray',
'lightGray','cyan','purple','blue',
'brown','green','red','black'
}

--[[
	Add subtable for manipulating color palette.
	@tparam table tbl Wrapped peripheral or Peripheral wrapper
	@tparam function getter Palette color getter function.
	@tparam function|nil setter Palette color setter function
	@tparam[opt=nil] {string,...} static pos table is static ( call getter and setter with 'self' arg)
	@treturn table palette sub-table for working with color palette
]]
function epf.subtablePalette(tbl, getter, setter, cfg)
	expect(1, tbl, "peripheral", 'peripheral wrapper', 'table')
	expect(2, getter, "function")
	expect(3, setter, "function", "nil")
	expect(4, cfg, "table", "nil")
	
	--assert(type(getter) == 'function', "Palette getter not specific")
	--assert(setter == nil or type(setter) == 'function',
	--	"Palette setter not nil/function")
	
	-- Create pos sub-table
	local palette = {__cur_obj=nil}
	
	local _m = {
		__super=tbl, -- Connect to tbl
	}
	
	local _cfg = {}
	for k,v in pairs(cfg or {}) do _cfg[v] = k end
	-- Create functions from scrap
	
	-- Check index is string
	local index_string = [[local _index = index
	if type(_index) == 'string' then
		_index = colors[string.lower(tostring(index))] or colours[string.lower(tostring(index))]
	end
	assert(not not _index, 'Invalid colorname for palette subtable'..index)]]
	
	-- Check call is static
	local _static = _cfg.static and "self.__cur_obj, " or ""
	
	local _return = "local res = {getter(".._static.."_index)};"
	if _cfg.hex then _return=_return.."res.hex=colors.packRGB(getter(".._static.."_index));" end
	if _cfg.named then _return=_return.."res.r,res.g,res.b=getter(".._static.."_index);" end
	if _cfg.abs then _return=_return.."res[-1],res[-2],res[-3]=colors.absRGB(getter(".._static.."_index));" end
	if _cfg.abs_named then _return=_return.."res._r,res._g,res._b=colors.absRGB(getter(".._static.."_index));" end
	if _cfg.no_def and (_cfg.hex or _cfg.named or _cfg.abs or _cfg.abs_named) then
		_return=_return.."res[1]=nil;res[2]=nil;res[3]=nil;"
	end
	
	-- Getter
	local _getter = string.format([[local _pal={...}
	local getter=_pal[1]
	local setter=_pal[2]
	colorNames=_pal[3]
	return function(self, index)
		%s
		%s
		return res
	end]], index_string, _return)
	local _ipairs = string.format([[, function(self)
		local i, key, value = 0
		return function()
			if i > 15 then return nil,nil end
			key = 2^i
			value={getter(%s key)}
			i=i+1
			return key,value
		end
	end]],_static)
	local _pairs = string.replace(_ipairs, 'return key,value', 'return colorNames[i], value')
	local _setter, _caller = "", ""
	if setter then
		_setter = string.format([[, function(self, index, value)
		%s
		if type(value) == 'table' then
			local _r,_g,_b = getter(%s _index)
			setter(%s _index,
				value[1] or value.r or _r,
				value[2] or value.g or _r,
				value[3] or value.b or _r
			)
		elseif type(value) == 'string' then
			setter(%s _index, tonumber(value,16))
		else
			setter(%s _index, value)
		end
	end]], index_string, _static,_static,_static,_static)
		_caller = [[, function(self, color_tbl, r_hex, g, b)
		if type(color_tbl) == 'table' then
			for k,v in pairs(color_tbl) do
				self[k]=v
			end
		elseif type(r_hex) == 'string' then
			self[color_tbl] = r_hex
		else
			self[color_tbl] = {r_hex, g, b}
		end
	end]]
	end
	
	local buffer = _getter.._ipairs.._pairs.._setter.._caller
	local _f, err = load(buffer)
	if not _f then error('[PALETTE] '..err) end
	_m.__index,_m.__ipairs,_m.__pairs,_m.__newindex,_m.__call = _f(getter, setter, colorNames)
	
	return setmetatable(palette, _m)
end


-- Relative and cardinal directions
epf.SIDES = {'front','right','back','left','top','bottom','south','west','north','east','up','down',}
-- add .RIGHT, .NORTH, ... and .SIDES.RIGHT .CARDINAL.NORTH, ...
for k,v in ipairs(epf.SIDES) do
	epf[v] = v
	epf.SIDES[v] = v
end
-- epf.SIDES.UP -> epf.SIDES.up
setmetatable(epf.SIDES, {__index = epf.GETTER_TO_LOWER(epf.SIDES.up)})

--[[
	Convert cardinal direction to relative
	
	@tparam string|int side Cardinal direction
	@tparam string|int front Cardinal direction what equal as front side
	@treturn string Relative direction
]]
function epf.cardinalToRelative(side, front)
	expect(1, side, "string", "int")
	expect(2, front, "string", "int")
	side = epf.SIDES[side]
	front = epf.SIDES[front]
	-- Side already relative
	for _,v in pairs{'right','left','front','back','top','bottom'} do
		if side == v then return side end
	end
	-- Up and down to top and bottom
	if side == 'up' then return 'top'
	elseif side == 'down' then return 'bottom'
	end
	local f, i, k
	for _f=7, 10 do
		k = epf.SIDES[_f]
		if k == front then
			f = _f-1
			break
		end
	end
	for i=7,10 do
		if epf.SIDES[i] == side then
			k = (i-f) % 4
			if k == 0 then k = 4 end
			return epf.SIDES[k]
		end
	end
	
	error("Can't convert cardinal direction to relative")
end
--[[
	Create transforation table for converting cardinal direction to relative
	@tparam string|int front Cardinal direction what equal as front side
	@treturn string Relative direction
]]
function epf.cardinalToRelativeEx(front)
	expect(1, front, "string", "int")
	front = epf.SIDES[front]
	if front ~= 'south' and front ~= 'west' and front ~= 'north' and front ~= 'east' then
		error("[epf.cardinalToRelativeEx] Front direction must be cardinal")
	end
	local tbl = {}
	-- Add relatives itself
	for i=1,6 do
		tbl[epf.SIDES[i]] = epf.SIDES[i]
	end 
	tbl.up =   'top'
	tbl.down = 'bottom'
	
	local f, j, k
	for _f=7, 10 do
		k = epf.SIDES[_f]
		if k == front then
			f = _f - 1
			break
		end
	end
	for i=7,10 do
		k = (i-f) % 4
		if k == 0 then k = 4 end
		tbl[epf.SIDES[i]] = epf.SIDES[k]
	end
	
	return setmetatable(tbl, {
	__index == function(self, index)
		return rawget(self,string.lower(index)) or 'front'
	end,
	})
end

--[[
	Add subtable for side-relatives getters/setters.
	
	Configs:
		static - getter/setter/... called from Wrapper, not from object
		pack - getter return more than one result, pack it. Same for setter and others.
		unpack - if 'pack' and getter can return one result, unpack it.
	
	@tparam table tbl Wrapped peripheral or Peripheral wrapper
	@tparam function getter Side getter function.
	@tparam function|nil setter Side setter function
	@tparam[opt=nil] table cfg Config array-like table. Allowed configs: 'static','pack','unpack'
	@treturn table pos sub-table for nD movement
]]
function epf.subtableSide(tbl, getter, setter, caller, pair, cfg)
	expect(1, tbl, "peripheral", 'peripheral wrapper', 'table')
	expect(2, getter, "function")
	expect(3, setter, "function", "nil")
	expect(4, caller, "function", "nil")
	expect(5, pair, "function", "nil")
	expect(6, cfg, "table", "nil")
	--[[assert(type(getter) == 'function', "Side getter not specific")
	assert(setter == nil or type(setter) == 'function',
		"Side setter not nil/function")
	assert(caller == nil or type(caller) == 'function',
		"Side caller not nil/function")
	assert(pair == nil or type(pair) == 'function',
		"Side pair not nil/function")
	assert(cfg == nil or type(cfg) == 'table',
		"Side cfg not nil/table")
	]]
	-- Create pos side-table
	local side = {__cur_obj=nil}
	
	local _m = {
		__super=tbl, -- Connect to tbl
	}
	local _cfg = {}
	for k,v in pairs(cfg or {}) do _cfg[v] = k end
	-- Create functions from scrap
	
	-- Check call is static
	local _static = _cfg.static and "self.__cur_obj, " or ""
	
	-- Getter
	local _getter = string.format([[local _side={...}
	local getter=_side[1]
	local setter=_side[2]
	local caller=_side[3]
	local pair=_side[4]
	local sides=_side[5]
	return function(self, index)
		local _r = %sgetter(%s sides[index])%s%s
		return _r
		
	end]],_cfg.pack and "{" or "", _static, _cfg.pack and "}" or "",_cfg.unpack and "\nif #_r == 1 then _r = _r[1] end\n" or "")
	local _pairs, _ipairs = "", ""
	if pair then
		-- Return relatives
		_pairs = string.format([[, function(self)
	local i,j=0,6
	local key,value
	return function()
		i=i+1
		key=sides[i]
		if i>j then return nil,nil end
		value = %spair(%s key)%s
		return key, value
	end
	end]],_cfg.pack and "{" or "", _static, _cfg.pack and "}" or "")
		-- Return cardinals
		_ipairs = string.replace(_pairs, 'i,j=0,6', 'i,j=6,12')
	end
	local _setter = ""
	if setter then
		_setter = string.format([[, function(self, index, value)%s
		setter(%s sides[index], %svalue%s)
		end]], _cfg.unpack and "\nif type(value) ~= 'table' then value={value} end\n" or "", _static, _cfg.pack and "table.unpack(" or "",_cfg.pack and ")" or "")
	end
	local _caller = ""
	if caller then
		_caller = string.format([[, function(self, index, ...)
			return caller(%s sides[index], ...)
		end]], _static)
	end
	
	local buffer = _getter.._ipairs.._pairs.._setter.._caller
	local _f, err = load(buffer)
	if not _f then error('[SIDE] '..err) end
	_m.__index,_m.__ipairs,_m.__pairs,_m.__newindex,_m.__call = _f(getter, setter, caller, pair, epf.SIDES)
	
	return setmetatable(side, _m)
end

--[[
	Replace '\r\n', '\r' to '\n'
	@tparam string text String for fixing
	@tparam[opt=false] boolean remove_empty Remove empty strings
	@treturn string Fixed string
]]
function epf.fixString(text, remove_empty)
	expect(1, text, "string")
	-- Replace CR-LF to LF
	if string.find(text, "\r") then
		text = string.gsub(text, "\r\n", "\n")
		text = string.gsub(text, "\r", "\n")
	end
	while remove_empty and string.find(text, "\n\n") do
		text = string.gsub(text, "\n\n", "\n")
	end
	return text
end

--[[
	Replace \t to array of spaces
	@tparam string text String for fixing
	@tparam[opt=nil] number custom_len Remove empty strings
	@treturn string Fixed string Alignment step length
]]
function epf.fixTab(text, custom_len)
	expect(1, text, "string")
	expect(2, custom_len, "number", "nil")
	custom_len = math.max(1, custom_len or settings.get("_EPF_TAB", 1))
	local t = text:find('\t')
	while t do
		t = (t-1) % custom_len
		if t == 0 then t = custom_len end
		text = text:gsub('\t', (" "):rep(t), 1)
		t = text:find('\t')
	end
	return text
end

--[[
	Cut text by length
	@tparam string text String for cutting
	@treturn number Length for cutting
	@tparam[opt=false] boolean fixed String already fixed
	@treturn string First string
	@treturn string Second string
]]
function epf.iterLine(text, length, fixed)
	expect(1, text, "string")
	expect(2, length, "number")
	expect(3,fixed, "boolean", "nil")
	if not fixed then text = epf.fixTab(epf.fixString(text)) end
	local t = string.sub(text, 1,length)
	return t, text:sub(length+1)
end

--[[
	Cut text by length and '\n'
	@tparam string text String for cutting
	@treturn number Length for cutting
	@tparam[opt=false] boolean fixed String already fixed
	@treturn string First string
	@treturn string Second string
]]
function epf.iterLineEx(text, length, fixed)
	expect(1, text, "string")
	expect(2, length, "number")
	expect(3,fixed, "boolean", "nil")
	if not fixed then text = epf.fixTab(epf.fixString(text)) end
	local t = string.sub(text, 1,length+1) -- Check \n in end of line
	local i = string.find(t, "\n")
	if i then 
		t = string.sub(text, 1,i-1)
		return t, text:sub(i+1)
	else
		return string.sub(text, 1,length), string.sub(text,length+1)
	end
end

--[[
	Split text by '\n' and length
	@tparam string text String for splitting
	@treturn number Length for splitting
	@tparam[opt=false] boolean fixed String already fixed
	@treturn table Splitted string
]]
function epf.splitText(text, length, fixed)
	expect(1, text, "string")
	expect(2, length, "number")
	expect(3,fixed, "boolean", "nil")
	if not fixed then text = epf.fixTab(epf.fixString(text, length)) end
	local spl = {}
	while #text > 0 do
		spl[#spl+1], text = epf.iterLineEx(text, length, true)
	end
	return spl
end

--[[
	Table with instrument names. For speaker
]]
epf.INSTRUMENTS = {"harp", "basedrum", "snare", "hat", "bass", "flute", "bell", "guitar", "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling"}
for k,v in pairs(epf.INSTRUMENTS) do
	epf.INSTRUMENTS[v] = v
end
setmetatable(epf.INSTRUMENTS, {
	__index = epf.GETTER_TO_LOWER(epf.INSTRUMENTS.bass)})

--[[
	Table with color tags for /say command
]]
epf.CHATCOLORS = {
	BLACK = '&0',DARK_BLUE = '&1',DARK_GREEN = '&2',DARK_AQUA = '&3',
	DARK_RED = '&4',DARK_PURPLE = '&5',GOLD = '&6',GRAY = '&7',
	DARK_GRAY = '&8',BLUE = '&9',GREEN = '&a',AQUA = '&b',
	RED = '&c',LIGHT_PURPLE = '&d',YELLOW = '&e',WHITE = '&f',
	
	OBFUSCATED = '&k',BOLD = '&l',STRIKETHROUGH = '&m',
	UNDERLINE = '&n',ITALIC = '&o',
	RESET = '&r',
}
for k, v in pairs(epf.CHATCOLORS) do
	if epf.CHATCOLORS[string.upper(v)] == nil then epf.CHATCOLORS[string.upper(v)] = v end
	v2 = string.upper(string.gsub(v ,"&", ""))
	if epf.CHATCOLORS[v2] == nil then epf.CHATCOLORS[v2] = v end
end
epf.CHATCOLORS.GREY = epf.CHATCOLORS.GRAY
epf.CHATCOLORS.DARK_GREY = epf.CHATCOLORS.DARK_GRAY
epf.CHATCOLORS.GLITCH = epf.CHATCOLORS.OBFUSCATED
epf.CHATCOLORS.UNDER = epf.CHATCOLORS.UNDERLINE
epf.CHATCOLORS.STRIKE = epf.CHATCOLORS.STRIKETHROUGH
setmetatable(epf.CHATCOLORS, {
	__index = epf.GETTER_TO_UPPER(epf.CHATCOLORS.RESET)
})
--[[
	Create color/style-formatted text for message
]]
function epf.colorText(text, color, effect, resetToDefault)
	return string.format("%s%s%s%s", color and epf.CHATCOLORS[color] or '', effect and epf.CHATCOLORS[effect] or '', text, resetToDefault and epf.CHATCOLORS.RESET or '')
end

if settings.get("_EPF_GLOBAL", false) and not _G.epf then
	_G.epf = epf
end

return epf
