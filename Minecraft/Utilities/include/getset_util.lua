--[[
	GetSet Utility library by PavelKom.
	Version: 0.5
	Easy access to getter and setter function without calling.
	Fields staring with __ is private (like in Python)
	Example:
	
	getset = require 'getset_util'
	
	function lib:TestClassObject()
		local self = {__a = 5, __b = 7, __c = 9, test = function() print('test') end, d = 7}
		...
		self.__getter = {
			a = function() return self.__a end,
			b  = function() return self.__b end,
			__e = function() return true end
		}
		self.__setter = {
			a = function(value) self.__a = value end,
			c = function(value) self.__c = value end
		}
		...
		setmetatable(self, {
			__index = getset.GETTER,
			__newindex = getset.SETTER,
			__pairs = getset.PAIRS,
			__ipairs = getset.IPAIRS,})
		return self
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

patches = require 'patches'
local lib = {}

-- Not working
lib.CALLER = function(func)
	return function(_,...) func(...) end
end
lib.CUSTOM_TYPE = function(name)
	return function(self) return name end
end

lib.VALIDATE_PERIPHERAL = function(name, peripheral_table, peripheral_name)
	local _t = subtype(peripheral_table)
	if name ~= nil and (name == "" or name == _t or type(name) ~= 'string') then name = nil end
	if name and peripheral_table.__items[name] then
		return nil, peripheral_table.__items[name]
	end
	-- Wrap or find peripheral
	local object = name and peripheral.wrap(name) or peripheral.find(_t)
	if object == nil then error("Can't connect to "..peripheral_name.." '"..name or _t.."'") end
	-- If it already registered, return 
	name = peripheral.getName(object)
	if peripheral_table.__items[name] then
		return nil, peripheral_table.__items[name]
	end
	-- Test for miss-type
	_type = peripheral.getType(object)
	if _type ~= _t then error("Invalid peripheral type. Expect '".._t.."' Present '".._type.."'") end
	
	
	return {object=object, name=name, type=_type}, nil
end

lib.GETTER = function(self, index)
	if not self.__getter or not self.__getter[index] then
		error("Can't get value from '"..tostring(index).."'")
	end
	return self.__getter[index]()
end
lib.SETTER = function(self, index, value)
	if not self.__setter or not self.__setter[index] then
		error("Can't set value to '"..tostring(index).."'")
	end
	self.__setter[index](value)
end
lib.PAIRS = function(self)
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
lib.IPAIRS = function(self)
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
lib.EQ_PERIPHERAL = function(self, other)
	return self.name == other.name and self.type == other.type
end
lib.GETTER_TO_UPPER = function(default)
	return function(self, index)
		if tostring(index) == string.upper(tostring(index)) then return default end
		return self[string.upper(tostring(index))]
	end
end
lib.GETTER_TO_LOWER = function(default)
	return function(self, index)
		if tostring(index) == string.lower(tostring(index)) then return default end
		return self[string.lower(tostring(index))]
	end
end

lib.STRING_TO_BOOLEAN = {
	["true"]=true,["t"]=true,["yes"]=true,["y"]=true,
	["false"]=false,["f"]=false,["no"]=false,["n"]=false,
}
setmetatable(lib.STRING_TO_BOOLEAN, {
	__call = function(self, value)
		if type(value) == 'boolean' then
			return value
		elseif type(value) == 'string' and self[string.lower(value)] ~= nil then
			return self[string.lower(value)]
		else return nil end
	end
})


-- Relative and cardinal directions
lib.SIDES = {'right','left','front','back','top','bottom','north','south','east','west','up','down',}
-- add .RIGHT, .NORTH, ... and .SIDES.RIGHT .CARDINAL.NORTH, ...
for k,v in ipairs(lib.SIDES) do
	lib[string.upper(v)] = v
	lib.SIDES[string.upper(v)] = v
	--lib.SIDES[k] = nil
end
setmetatable(lib.SIDES, {__index = lib.GETTER_TO_UPPER(lib.SIDES.UP)})

lib.metaSide = function(getter, setter, caller, pair)
	local meta = {
	__index = function(self, side)
		return getter(lib.SIDES[side])
	end}
	if pair then
		meta.__pairs = function(self) -- Return relatives
			local i = 0
			local key, value
			return function()
				i = i + 1
				key = lib.SIDES[i]
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
				key = lib.SIDES[i]
				if i > 12 then return nil, nil end
				value = wrapper.object[pair](key)
				return key, value
			end
		end
	end
	if caller then
		meta.__call = function(self, side)
			return caller(lib.SIDES[side])
		end
	end
	if setter then
		meta.__newindex = function(self, side, value)
			setter(lib.SIDES[side], value)
		end
	end
	return setmetatable({}, meta)
end


lib.metaPos = function(getter, setter)
	local meta = {
	__index = function(self, index)
		local _x, _y = getter()
		if string.lower(tostring(index)) == 'x' or index == 1 then
			return _x
		elseif string.lower(tostring(index)) == 'y' or index == 2 then
			return _y
		elseif string.lower(tostring(index)) == 'xy' or index == 3 then
			return _x, _y
		end
	end}
	if setter then
		meta.__newindex = function(self, index, value)
			local _x, _y = getter()
			if string.lower(tostring(index)) == 'x' or index == 1 then
				setter(tonumber(value), _y)
			elseif string.lower(tostring(index)) == 'y' or index == 2 then
				setter(_x, tonumber(value))
			elseif string.lower(tostring(index)) == 'xy' or index == 3 then
				if value == nil then
					setter(1,1)
				else
					setter(tonumber(value[1]) or tonumber(value.x) or 1,
						tonumber(value[2]) or tonumber(value.y) or 1)
				end
			end
		end
		meta.__call = function(self, x_tbl, y)
			local _x, _y = getter()
			if type(x_tbl) == 'table' or (x_tbl == nil and y == nil) then
				self.xy = x_tbl
			elseif x_tbl ~= nil and y ~= nil then
				self.xy = {x_tbl, y}
			elseif x_tbl ~= nil and y == nil then
				self.x = x_tbl
			elseif x_tbl == nil and y ~= nil then
				self.y = y
			end
		end
	end
	return setmetatable({}, meta)
end

lib.metaPalette = function(getter, setter)
	local meta = {
		__index = function(self, index)
			if type(index) == 'string' then
				index = colors[index]
			end
			return colors.packRGB(getter(index))
		end,
		__pairs = function(self)
			local key, value
			local i = 0
			return function()
				if i > 15 then return nil, nil end
				key = math.pow(2,i)
				value = {getter(key)} -- 0.0-1.0 RGB
				--v = colors.absRGB(getter(key)) -- 0-255 RGB
				value[4] = colors.packRGB(table.unpack(value)) -- hex
				--value[5] = v[1], value[6] = v[2], value[7] = v[3]
				i = i + 1
				return key, value
			end
		end
	}
	meta.__ipairs = meta.__pairs
	if setter then
		meta.__newindex = function(self, index, value) -- value is Hex or {rgb}
			if type(index) == 'string' then
				index = colors[index]
			end
			if index == 0 or index == nil then error("getset.metaPalette Invalid color index") end
			if type(value) == 'table' then
				-- RGB. Allow changing only one or two channels
				local _r, _g, _b = getter(value)
				setter(index,
					value[1] or value.r or _r,
					value[2] or value.g or _g,
					value[3] or value.b or _b)
			-- Value hex number or string
			elseif type(value) == 'string' then
				setter(index, tonumber(value,16))
			else
				setter(index, value)
			end
		end
		meta.__call = function(self, color_tbl, r_hex, g, b)
			if type(color_tbl) == 'table' then -- Multicolor change
				for k, v in pairs(color_tbl) do
					self[k] = v
				end
			-- Hex string
			elseif type(r_hex) == 'string' then
				self[color_tbl] = r_hex
			else -- RGB
				self[color_tbl] = {r_hex, g, b}
			end
		end
	end
	return setmetatable({}, meta)
end

lib.printTable = function(tbl,ignore_functions, deep)
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
				lib.printTable(v, ignore_functions, deep.." ")
			end
			end
		end
	end
end



lib.GETTER2 = function(cls)
	return function(self, index)
		if self.__getter and self.__getter[index] then -- internal/class object getter
			return self.__getter[index]()
		elseif cls.__getter and cls.__getter[index] then -- external/class getter
			return cls.__getter[index](self)
		elseif cls and cls[index] then -- class method
			return cls[index](self)
		end
		error("Can't get value from '"..tostring(cls)..'().'..tostring(index).."'")
	end
end
lib.SETTER2 = function(cls)
	return function(self, index, value)
		if not self.__setter or not self.__setter[index] then
			return self.__setter[index](value)
		elseif cls.__setter and cls.__setter[index] then
			return cls.__setter[index](self,value)
		end
		error("Can't set value to '"..tostring(cls)..'().'..tostring(index).."'")
	end
end
lib.PAIRS2 = function(cls)
	return function(self)
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
				k2 = next(cls)
				while k2 do
					if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
						value[#value+1] = k2
					end
					k2 = next(cls, k2)
				end
				if #value == 0 then key = 'getter' end
			end
			if key == 'getter' then
				if self.__getter then
					k2 = next(self.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[#value+1] = k2
						end
						k2 = next(self.__getter, k2)
					end
				end
				if cls and cls.__getter then
					k2 = next(cls.__getter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[#value+1] = k2
						end
						k2 = next(cls.__getter, k2)
					end
				end
				if #value == 0 then key = 'setter' end
			end
			if key == 'setter' then
				if self.__setter then
					k2 = next(self.__setter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[#value+1] = k2
						end
						k2 = next(self.__setter, k2)
					end
				end
				if cls and cls.__setter then
					k2 = next(cls.__setter)
					while k2 do
						if string.match(tostring(k2), "__[a-zA-Z0-9_]+") == nil then
							value[#value+1] = k2
						end
						k2 = next(cls.__setter, k2)
					end
				end
				if #value == 0 then key = 'setter' end
			end
			if #value == 0 then 
				return nil, nil
			end
			return key, value
		end
	end
end
lib.IPAIRS2 = function(cls)
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
function lib.formattedTable(tbl)
	local result="{"
	for k, v in pairs(tbl) do
		if type(k) ~= 'table' and type(v) ~= 'table' then
			result = result..tostring(k).."="..tostring(v)..","
		elseif type(k) ~= 'table' and type(v) == 'table' then
			result = result..tostring(k).."="..formattedTable(v)..","
		elseif type(k) == 'table' and type(v) ~= 'table' then
			result = result..formattedTable(k).."="..tostring(v)..","
		else
			result = result..formattedTable(k).."="..formattedTable(v)..","
		end
	end
	result = result.."}"
	return result
end













return lib
