--[[
Extended Peripheral Framework
Author: PavelKom
Version 2.0
	
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
]]

-- Patches
require "patches"

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
epf.GETTER2 = function(cls)
	return function(self, index)
		if self ~= cls -- Get property | call static method
			if self.__getter and self.__getter[index] then -- internal/class object getter
				return self.__getter[index]()
			elseif cls.__getter and cls.__getter[index] then -- external/class getter
				return cls.__getter[index](self)
			elseif cls and cls[index] then -- class method
				return cls[index](self)
			end
		else
			if self.__getter and self.__getter[index] then -- external/class getter
				return self.__getter[index](nil)
			elseif self and self[index] then -- class method
				return self[index](nil)
			end
		end
		error("Can't get value from '"..tostring(cls)..'().'..tostring(index).."'")
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
epf.SETTER2 = function(cls)
	return function(self, index, value)
		if self ~= cls -- Set property
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
epf.PAIRS2 = function(cls)
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
epf.IPAIRS2 = function(cls)
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

	local _m = getmetatable(tbl)
	_m.__call = _m.__call or tbl.new or epf.simpleNew(tbl)
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
			tbl.__metas.__tostring = function(self) return subtype(self).." '"..(self.name or type(self)).."'" end
		end
		
		_m.__index = tbl.__metas.__index
		_m.__newindex = tbl.__metas.__newindex
		_m.__pairs = tbl.__metas.__pairs
		_m.__ipairs = tbl.__metas.__ipairs
		_m.__tostring = tbl.__str or tbl.__metas.__tostring -- tbl.__str -- tostring for objects
		_m.__call = tbl.__call or nil -- Caller for object.  Test.__call(obj)
		_m.__type = "peripheral",
		_m.__eq = tbl.__eq or epf.EQUAL
		_m.__subtype = tbl.__subtype,
		
		-- Post initialise
		if type(tbl.__init) == function then
			self = tbl.init(self)
		end
		
		return self
	end
end

return epf
