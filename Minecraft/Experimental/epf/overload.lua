--[[
	API for creating overloaded functions
	Author: PavelKom
	Version: 0.1
	
	Example:
	-- Creating overloaded function
	local overloadedFunc = Overload()
	
	--Register overloads
	Overload.reg(overloadedFunc,
		function(a) print("1 argument", a) end,
		0 -- Array of arguments, used their types
	)
	Overload.reg(overloadedFunc,
		function(a, b) print("2 arguments", a, b) end,
		0,0
	)
	Overload.reg(overloadedFunc,
		{}, -- No arguments
		function() print("No arguments") end
	)
	-- Register default call (if no overloads)
	Overload.regDefault(overloadedFunc,
		function(...) print("Many argumnets", ...) end
	)
	
	-- call
	overloadedFunc() -- "No arguments"
	overloadedFunc(1) -- "1 argument 1"
	overloadedFunc(1,2,3) -- "Many argumnets 1 2 3"
]]
-- You can change type to your custom type getter
local _type = type

local Overload = {__keys={}}
-- Metamethods for arguments
function Overload.__arg__eq(self, other)
	if #self ~= #other then return false end
	for k,v in pairs(self) do
		if  not other[k] or
			_type(v) ~= _type(other[k]) then
			return false
		end
	end
	return true
end
function Overload.__arg__len(self)
	local i, k = -1, nil
	repeat
		k, _ = next(self, k)
		i = i + 1
	until k == nil
	return i
end
Overload.__arg__meta = {
	__len=Overload.__arg__len,
	__eq=Overload.__arg__eq
}

-- Metamethods for overloaded function
function Overload.__func__index(self, index)
	if type(index) == 'table' then
		--local i = OverLoad.__pack(index)
		for k,v in pairs(self) do
			if k == index then return v end
		end
	end
	return self.__default
end
function Overload.__func__call(self, ...)
	local a = Overload.__pack(...) -- pack arguments
	local f = self[a] -- get function or default function
	if f then return f(...) end -- call it
	error("Unknown overload types")
end
Overload.__func__meta = {
	__index=Overload.__func__index,
	__call=Overload.__func__call,
}

-- Pack arguments
function Overload.__pack(...)
	return setmetatable({...}, Overload.__arg__meta)
end

-- Create new overloaded function
function Overload.new(self, tbl, default)
	tbl = tbl or {}
	tbl.__default = default
	return setmetatable(tbl,Overload.__func__meta)
end
-- Register overload
-- Overload.reg(tbl, func, 1,2,3) -- func(a:number, b:number, c:number)
function Overload.reg(tbl_func, func, ...)
	local a, isNew = Overload.__pack(...), true
	-- Check if argument array already registered
	for _,v in pairs(Overload.__keys) do
		if v == a then
			a = v
			isNew = false
			break
		end
	end
	if isNew then Overload.__keys[#Overload.__keys+1] = a end
	if tbl_func[a] and tbl_func[a] ~= tbl_func.__default then error("Overload already registered") end 
	tbl_func[a] = func
	return tbl_func
end
Overload = setmetatable(Overload,{__call=Overload.new})

-- Tests
--[[
local function _def(...) print('default', ...) end
local function arg1(a) print(1, a) end
local A = Overload({},_def)
Overload.reg(A, arg1, 0)
A(12) -- "1 12"
A() -- "default"
A(1,2,3) -- "default 1 2 3"
A({1}) -- "default table: <address>"
]]

return Overload
