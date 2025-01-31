--[[
Extended Peripheral Framework
Author: PavelKom
Version 2.1b
	
Library for extanding wrapped peripheral by adding get/set properties and other.

All methods started with __ (double underscore) is hide for pairs and ipairs. By default.

Example Stressometer from Create mod:

local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self) -- tostring for objects
	return string.format("%s '%s' Stress: %i/%i (%.1f%%)", subtype(self), self.name, self.stress, self.max, self.use * 100)
end
function Peripheral.__init(self) -- Add getters, setters and subtables (like pos for managing cursor position)
	self.__getter = {
		stress = function() -- stress as read-only property
			return self.getStress()
		end,
		capacity = function()
			return self.getStressCapacity() -- capacity
		end,
		use = function() -- stress/capacity
			if self.getStressCapacity() == 0 then return 1.0 end
			return self.getStress() / self.getStressCapacity()
		end,
		free = function() -- capacity - stress
			return self.getStressCapacity() - self.getStress()
		end,
		is_overload = function() -- network is overload
			return self.getStressCapacity() < self.getStress()
		end,
	}
	-- Aliases
	self.__getter.cap = self.__getter.capacity
	self.__getter.max = self.__getter.capacity
	self.__getter.overload = self.__getter.is_overload
	
	return self
end
Peripheral.new = epf.simpleNew(Peripheral) -- Add default new()
Peripheral = epf.wrapperFixer(tbl, "Create_Stressometer", "Stressometer") -- Validate wrapper

local lib = {} -- Create library
lib.Stressometer = Peripheral -- Add alias to library
-- Add information about library
lib = setmetatable(lib, __call=Peripheral.__call, __type="library", __subtype="peripheral wrapper library")

-- Now lib(...) == lib.Stressometer(...) == Peripheral(...) == Peripheral.new(...)
-- Note: If library contain more than one wrapper, don't add Peripheral() as __call to library!

return lib


@changed 2.1b Added pos sub-table
]]

-- Patches
require "lib.patches"

-- You can set this library as global API by createing setting
--[[ Define setting
settings.define("_EFP_GLOBAL", {
    description = "Add Extended Peripheral Framework to global table on startup",
    default = true,
    type = "boolean",
})

]]
if settings.get("_EFP_GLOBAL", false) and _G.epf then
	return _G.epf
end
	

local epf = {}

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
			if not self.__setter or not self.__setter[index] then
				return self.__setter[index](value)
			elseif cls.__setter and cls.__setter[index] then
				return cls.__setter[index](self, value)
			end
		else
			if not self.__setter or not self.__setter[index] then
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
						value[1][#value+1] = tostring(k2)
					end
					k2 = next(self, k2)
				end
				k2 = next(cls)
				while k2 do
					if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
						value[2][#value+1] = k2
					end
					k2 = next(cls, k2)
				end
			end
			if key == 'getter' then
				if self.__getter then
					k2 = next(self.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[1][#value+1] = k2
						end
						k2 = next(self.__getter, k2)
					end
				end
				if cls and cls.__getter then
					k2 = next(cls.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[2][#value+1] = k2
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
							value[1][#value+1] = k2
						end
						k2 = next(self.__setter, k2)
					end
				end
				if cls and cls.__setter then
					k2 = next(cls.__setter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[2][#value+1] = k2
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
	return	type(self) == type(other) and -- both peripherals or wrappers
			subtype(self) == subtype(other) and -- same peripheral type (Modem)
			self.type == other.type and -- same peripheral name (modem)
			self.name == other.name -- same name (modem_0)
end

--[[
	Default tostring for wrappers.
	@tparam table Wrapper
	@treturn string tostring() result
]]
function epf.WRAPPER_STR(self)
	return string.format("Peripheral wrapper for %s (%s)", subtype(self), self.type)
end

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
	tbl.__type = "peripheral wrapper"
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
	_m.__type= _m.__type or tbl.__type
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
	assert(tbl, "Peripheral wrapper not specific")
	return function(name)
		local self = name and peripheral.wrap(name) or peripheral.find(tbl.type)
		assert(self, string.format("Peripheral '%s' not founded", name and name or tbl.type))
		name = name or peripheral.getName(self)
		-- Get wrapped peripheral if it already registered
		if tbl.__names and tbl.__names[name] then
			return tbl.__names[name]
		end
		
		self.__getter = {}
		self.__setter = {}
		local _m = getmetatable(self)
	
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
		_m.__type = "peripheral"
		_m.__eq = tbl.__eq or epf.EQUAL
		_m.__subtype = tbl.__subtype
		_m.__super = tbl -- For getting wrapper
		
		-- Post initialise
		if type(tbl.__init) == 'function' then
			self = tbl.__init(self)
		end
		
		-- Register wrapped peripheral for avoiding re-initialise
		tbl.__names = tbl.__names or {}
		tbl.__names[name] = self
		
		return self
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
	@tparam[opt=false] boolean static pos table is static ( call getter and setter with 'self' arg)
	@treturn table pos sub-table for 
]]
function epf.subtablePos(tbl, getter, setter, keys, static)
	assert(tbl, "Peripheral wrapper not specific")
	assert(type(getter) == 'function', "Position getter not specific")
	assert(setter == nil or type(setter) == 'function',
		"Position setter not nil/function")
	
	-- Create pos sub-table
	local pos = {__keys = keys  or {'x', 'y'}, __cur_obj=nil}
	local _m = {
		__super=tbl, -- Connect to tbl
	}
	-- For avoiding re-creating pos-table for every object
	-- STATIC
	if static then
		-- obj = Test()
		-- obj.pos.x -> Test.pos_getter(self,'x') return self.getter().x end
		_m.__index = function(self, index)
			local _p = {getter(self.__cur_obj)} -- {x,y,z,...}. 
			local _r = {}
			for k,v in pairs(_p) do -- pos.xyz
				if string.find(index, self.__keys[k]) then
					_r[#_r+1] = v
				end
			end
			if #_r == 1 then _r = _r[1] end -- pos.x
			return _r
		end
		-- Iterate coordinates by name
		_m.__pairs = function(self)
			local _pos = {getter(self.__cur_obj)} -- {x,y,z,...}
			for k,v in pairs(_pos) do --{'x'=x,'y'=y,...}
				_pos[self.__keys[k]] = v
				_pos[k] = nil
			end
			local key, value
			return function()
				key, value = next(_pos, key)
				return key, value
			end
		end
		-- Iterate coordinates by position
		_m.__ipairs = function(self)
			local _pos = {getter(self.__cur_obj)} -- {x,y,z,...}
			local key, value
			return function()
				key, value = next(_pos, key)
				return key, value
			end
		end
		if setter then
			_m.__newindex = function(self, index, value)
				if type('value') ~= 'table' then value = {value} end
				local _p = {getter(self.__cur_obj)}
				local _i = 1
				for k,v in pairs(_p) do
					if string.find(index, self.__keys[k]) then
						_p[k] = value[self.__keys[k]] or value[_i] or _p[k] -- Change values for specific keys
						_i = _i + 1
					end
				end
				setter(self.__cur_obj, table.unpack(_p))
			end
		end
	else -- NON-STATIC
		-- obj = Test()
		-- obj.pos.x -> getter().x
		_m.__index = function(self, index)
			local _p = {getter()} -- {x,y,z,...}. 
			local _r = {}
			for k,v in pairs(_p) do -- pos.xyz
				if string.find(index, self.__keys[k]) then
					_r[#_r+1] = v
				end
			end
			if #_r == 1 then _r = _r[1] end -- pos.x
			return _r
		end
		_m.__pairs = function(self)
			local _pos = {getter()} -- {x,y,z,...}
			for k,v in pairs(_pos) do --{'x'=x,'y'=y,...}
				_pos[self.__keys[k]] = v
				_pos[k] = nil
			end
			local key, value
			return function()
				key, value = next(_pos, key)
				return key, value
			end
		end
		_m.__ipairs = function(self)
			local _pos = {getter()} -- {x,y,z,...}
			local key, value
			return function()
				key, value = next(_pos, key)
				return key, value
			end
		end
		if setter then
			_m.__newindex = function(self, index, value)
				if type('value') ~= 'table' then value = {value} end
				local _p = {getter()}
				local _i = 1
				for k,v in pairs(_p) do
					if string.find(index, self.__keys[k]) then
						_p[k] = value[self.__keys[k]] or value[_i] or _p[k] -- Change values for specific keys
						_i = _i + 1
					end
				end
				setter(table.unpack(_p))
			end
		end
	end
	if setter then
		_m.__call = function(self, ...)
			local _arg = {...}
			local index = ""
			if #_arg == 0 then -- pos() == pos(1,1,1,...)
				for k,v in ipairs(self.__keys) do
					_arg[k] = 1
					index = index..v
				end
			elseif type(_arg[1]) == 'table' then -- pos({'x'=7,'y'=2})
				for k,v in ipairs(self.__keys) do
					if _arg[k] or _arg[v] then -- [1]=7 or 'x'=7
						_arg[k] = _arg[k] or _arg[v] -- [1] = [1] or ['x']
						_arg[v] = nil -- ['x']=nil
						index = index..v
					end
				end
			else -- pos(7,2)
				for k,v in pairs(_arg) do
					index = index..self.__keys[k]
				end
			end
			self[index] = _arg
		end
	end
end





if settings.get("_EFP_GLOBAL", false) and not _G.epf then
	_G.epf = epf
end

return epf
