--[[
	GetSet Utility library by PavelKom.
	Version: 0.1
	Easy access to getter and setter function without calling.
	Fields staring with __ is private (like in Python)
	Example:
	
	getset = require 'getset_util'
	
	function lib:TestClassObject()
		local ret = {__a = 5, __b = 7, __c = 9, test = function() print('test') end, d = 7}
		...
		ret.__getter = {
			a = function() return ret.__a end,
			b  = function() return ret.__b end,
			__e = function() return true end
		}
		ret.__setter = {
			a = function(value) ret.__a = value end,
			c = function(value) ret.__c = value end
		}
		...
		setmetatable(ret, {
			__index = getset.GETTER,
			__newindex = getset.SETTER,
			__pairs = getset.PAIRS,
			__ipairs = getset.IPAIRS,})
		return ret
	end
	
	test = lib:TestClassObject()
	print(test.a) -- 5      Same as print(test.__getter.a()) value
	test.a = 7 -- Same as test.__setter.a(1)
	print(test.a) -- 1
	print(test.b) -- 7
	print(test.c) -- Throw error, 'c' only for setting
	test.b = 2 -- Throw error, 'b' only for getting
	test.c = 3 -- 'c' now = 3
	
	for k,v in pairs(test) do
		-- {
		'method'={'test', 'd'}, - List of methods. It's ignoring __<name> fields
		'getter'={a,b}, , - List of getters. It's ignoring __<name> fields
		'setter'={a,c}, - List of setters. It's ignoring __<name> fields
		}
	end
	for k,v in ipairs(test) do
		-- {
		{test, function}, -- 'method'
		{d, number}, -- 'method'
		{a, function}, -- 'getter'
		{b, function}, -- 'getter'
		{c, function} -- 'setter'
		}
	end
	
]]


local this_library = {}


this_library.GETTER = function(self, index)
	if not self.__getter or not self.__getter[index] then
		error("Can't get value from '"..tostring(index).."'")
	end
	return self.__getter[index]()
end
this_library.SETTER = function(self, index, value)
	if not self.__setter or not self.__setter[index] then
		error("Can't set value to '"..tostring(index).."'")
	end
	self.__setter[index](value)
end
this_library.PAIRS = function(self)
	local key, value, k2, k3
	local names = {'method','getter','setter',}
	return function()
		k3, key = next(names, k3)
		value = {}
		if key == 'method' then
			k2 = next(self)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self, k2)
			end
			if #value == 0 then key = 'getter' end
		end
		if key == 'getter' and self.__getter then
			k2 = next(self.__getter)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self.__getter, k2)
			end
			if #value == 0 then key = 'setter' end
		end
		if key == 'setter' and self.__setter then
			k2 = next(self.__setter)
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self.__setter, k2)
			end
		end
		if #value == 0 then 
			return nil, nil
		end
		return key, value
	end
end
this_library.IPAIRS = function(self)
	local key, value, k2, v2
	local keys = {}
	k2, v2 = next(self)
	while k2 do
		if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
			keys[k2] = v2
		end
		k2, v2 = next(self, k2)
	end
	if self.__getter then
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
this_library.EQ_PERIPHERAL = function(self, other)
	return self.name == other.name and self.type == other.type
end
function this_library.GETTER_TO_UPPER(default)
	return function(self, index)
		if tostring(index) == string.upper(tostring(index)) then return default end
		return self[string.upper(tostring(index))]
	end
end
function this_library.GETTER_TO_LOWER(default)
	return function(self, index)
		if tostring(index) == string.lower(tostring(index)) then return default end
		return self[string.lower(tostring(index))]
	end
end

this_library.STRING_TO_BOOLEAN = { ["true"]=true, ["false"]=false }
setmetatable(this_library.STRING_TO_BOOLEAN, {
	__call = function(self, value)
		if type(value) == 'boolean' then
			return value
		elseif type(value) == 'string' and self[string.lower(value)] ~= nil then
			return self[string.lower(value)]
		else return nil end
	end
})


-- Relative and cardinal directions
this_library.SIDES = {'right','left','front','back','top','bottom','north','south','east','west','up','down',}
-- add .RIGHT, .NORTH, ... and .SIDES.RIGHT .CARDINAL.NORTH, ...
for k,v in ipairs(this_library.SIDES) do
	this_library[string.upper(v)] = v
	this_library.SIDES[string.upper(v)] = v
	--this_library.SIDES[k] = nil
end
setmetatable(this_library.SIDES, {__index = this_library.GETTER_TO_UPPER(this_library.SIDES.UP)})

function this_library.metaSide(tbl, getter, setter, caller, pair)
	local meta = {
	__index = function(self, side) return getter(this_library.SIDES[side]) end}
	if pair then
		meta.__pairs = function(self) -- Return relatives
			local i = 0
			local key, value
			return function()
				i = i + 1
				key = this_library.SIDES[i]
				if i > 6 then return nil, nil end
				value = pair(key)
				return key, value
			end
		end
		meta.__ipairs = function(self) -- Return cardinals
			local i = 6
			local key, value
			return function()
				i = i + 1
				key = this_library.SIDES[i]
				if i > 12 then return nil, nil end
				value = pair(key)
				return key, value
			end
		end
	end
	if caller then
		meta.__call = function(self, side) return caller(this_library.SIDES[side]) end
	end
	if setter then
		meta.__newindex = function(self, side, value)
			setter(this_library.SIDES[side], value)
		end
	end
	return setmetatable(tbl, meta)
end

function this_library.printTable(tbl,ignore_functions, deep)
	if type(tbl) ~= 'table' then
		print(tbl)
	else
		deep = deep or ""
		for k, v in pairs(tbl) do
			if not ignore_functions or (ignore_functions and type(v) ~= 'function') then
			if type(v) ~= 'table' then
				print(string.format("%s%s:%s    %s", deep,tostring(k), tostring(v), type(v)))
			else
				print(string.format("%s%s:",deep,tostring(k)))
				this_library.printTable(v, ignore_functions, deep.." ")
			end
			end
		end
	end
end

return this_library
