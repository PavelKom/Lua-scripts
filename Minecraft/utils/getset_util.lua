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
	local key, value, k2
	local names = {'method','getter','setter',}
	return function()
		key = next(names, key)
		if key == 'method' then
			k2 = next(self)
			value = {}
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self, k2)
			end
		elseif key == 'getter' and self.__getter then
			k2 = next(self.__getter)
			value = {}
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self.__getter, k2)
			end
		elseif key == 'setter' and self.__setter then
			k2 = next(self.__setter)
			value = {}
			while k2 do
				if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
					value[#value+1] = k2
				end
				k2 = next(self.__setter, k2)
			end
		else
			value = nil
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

return this_library
