--[[
	Lua Patcher library by PavelKom.
	Version: 0.4
	Patch some broken or non-existed methods.
	
	Don't forget to add require "path.to.patches" to startup file
]]


-- Extend library path finder. package.path resets on every program start (((
if not string.find(package.path, "/src/?.lua", 1, true) then
	package.path = package.path..';/src/?.lua'
end
if not string.find(package.path, "/lib/?.lua", 1, true) then
	package.path = package.path..';/lib/?.lua'
end
if not string.find(package.path, "/include/?.lua", 1, true) then
	package.path = package.path..';/include/?.lua'
end
if _G._PATCHED_BY_PAVELKOM then return end

-- TABLE

--[[
	Patch for __ipairs
	https://stackoverflow.com/a/77354254/
	pairs(tbl) return tbl.__pairs or default pairs method.
	ipairs(tbl) NOT return tbl.__pairs BUT return default ipairs method.
]]
if not _G.raw_ipairs then
	_G.raw_ipairs = _G.ipairs
	_G.ipairs = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__ipairs then
			return metatable.__ipairs(t)
		end
		return raw_ipairs(t)
	end
end
--[[
if not _G.raw_type then -- Bad idea
	_G.raw_type = _G.type -- Copy default type function as raw_type
	_G.type = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__type then
			if type(metatable.__type) == 'function' then -- If __type is function
				return metatable.__type(t)
			else -- If type not function but callable
				local t = getmetatable(metatable.__type)
				if t and t.__call then
					return metatable.__type(t)
				end
			end
			return metatable.__type
		end
		return raw_type(t)
	end
end
]]
if not _G.custype then -- Custom type
	_G.custype = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__name then
			if type(metatable.__name) == 'function' then -- If __name is function
				return metatable.__name(t)
			else -- If type not function but callable
				local t = getmetatable(metatable.__name)
				if t and t.__call then
					return metatable.__name(t)
				end
			end
			return metatable.__name
		end
		return type(t)
	end
end
if not _G.subtype then
	_G.subtype = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__subtype then
			if type(metatable.__subtype) == 'function' then -- If __subtype is function
				return metatable.__subtype(t)
			else -- If subtype not function but callable
				local t = getmetatable(metatable.__subtype)
				if t and t.__call then
					return metatable.__subtype(t)
				end
			end
			return metatable.__subtype
		end
		return custype(t)
	end
end

if not _G.name then
	_G.name = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__name then
			if type(metatable.__name) == 'function' then -- If __name is function
				return metatable.__name(t)
			else -- If name not function but callable
				local t = getmetatable(metatable.__name)
				if t and t.__call then
					return metatable.__name(t)
				end
			end
			return metatable.__name
		end
		return type(t)
	end
end
local expect = dofile("rom/modules/main/cc/expect.lua").expect

--[[
	Patch for table library. Add deep copy function
	https://gist.github.com/tylerneylon/81333721109155b2d244

	@tparam table obj Original table
	@treturn table Copy of obj
]]
function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return setmetatable(res, getmetatable(obj))
end

--[[
	Add table equality function
	https://web.archive.org/web/20131225070434/http://snippets.luacode.org/snippets/Deep_Comparison_of_Two_Values_3
	
	@tparam table t1 First table
	@tparam table t1 Second table
	@tparam[opt=false] boolean ignore_mt Ignore metatables
	@treturn boolean Equality
]]
function table.equal(t1,t2,ignore_mt)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not table.equal(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not table.equal(v1,v2) then return false end
	end
	return true
end

-- STRING

--[[
	Patch for string library. Add split function
	https://stackoverflow.com/a/7615129/
	
	@tparam string inputstr String for splitting
	@tparam[opt="%s"] string sep Separator
	@treturn {string,...} Splitted string
]]
function string.split(inputstr, sep)
	if sep then sep = "([^"..sep.."]+)"
	else sep = "." end -- Split by char
	local t = {}
	for str in string.gmatch(inputstr, sep) do
	table.insert(t, str)
	end
	return t
end

local tab = {
{"%", "%%"}, -- !!!
{"(", "%("},
{")", "%)"},
{".", "%."},
{"+", "%+"},
{"-", "%-"},
{"*", "%*"},
{"?", "%?"},
{"[", "%["},
{"]", "%]"},
{"^", "%^"},
{"$", "%$"},
}

--[[
	Replace function for sring. WITHOUT REGEX

	@tparam string inputstr String 
	@tparam string non_pattern Search string 
	@tparam[opt=""] string repl Replace string
	@treturn string resulted string
]]
function string.replace(inputstr, non_pattern, repl)
	repl = repl or ""
	for k, v in pairs(tab) do
		local _k, _v = v[1], v[2]
		if string.find(non_pattern, _v) then
			non_pattern = string.gsub(non_pattern, _v, "%".._v)
		end
	end
	return string.gsub(inputstr, non_pattern, repl)
end


-- Create MC and CC versions for peripheral utils checks
if not _G._MC_VERSION or not _G._CC_VERSION then
	local _v = string.split(string.gsub(_HOST, "[%)%(]", ""), " ")
	--major.minor.build
	_G._CC_VERSION = _v[2]
	_G._MC_VERSION = _v[4]
	_v = string.split(_CC_VERSION, ".")
	_G._CC_MAJOR, _G._CC_MINOR, _G._CC_BUILD = tonumber(_v[1]), tonumber(_v[2]), tonumber(_v[3])
	_v = string.split(_MC_VERSION, ".")
	_G._MC_MAJOR, _G._MC_MINOR, _G._MC_BUILD = tonumber(_v[1]), tonumber(_v[2]), tonumber(_v[3])
end

-- MATH

--[[
	Clamn value between other two values
	
	@tparam number value The value to check
	@tparam[opt=0] number minimum Minimum value
	@tparam[opt=1] number maximum Maximum value
	@treturn number Clamped value
]]
function math.clamp(value, minimum, maximum)
    expect(1, value, "number")
    expect(2, minimum, "number", "nil")
    expect(3, maximum, "number", "nil")
	
	minimum = minimum or -math.huge
	maximum = maximum or math.huge
	
	return math.max(minimum, math.min(value, maximum))
end

-- COLO(U)RS

-- Add internal blit index support
for i=0, 15 do
	colors[string.format("%x",i)] = 2 ^ i
	colours[string.format("%x",i)] = 2 ^ i
end

--[[
	Convert 0-255 channel to 0.0-1.0
	
	@tparam number value Absolute value
	@treturn number Channel value
]]
function colors.norm(value) -- value: number
    expect(1, value, "number")
	return bit32.band(value, 0xFF) / 255
end

--[[
	Convert 0.0-1.0 channel to 0-255
	
	@tparam number value Channel value
	@treturn number Absolute value
]]
function colors.abs(value)
    expect(1, value, "number")
	return bit32.band(value * 255, 0xFF)
end

--[[
	Convert 0-255 rgb to 0.0-1.0
	
	@tparam number r Red absolute value
	@tparam number g Green absolute value
	@tparam number b Blue absolute value
	@treturn number Red channel value
	@treturn number Green channel value
	@treturn number Blue channel value
]]
function colors.normRGB(r,g,b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
	return -- From colors.unpackRGB (but without shifts)
		bit32.band(r, 0xFF) / 255,
		bit32.band(g, 0xFF) / 255,
		bit32.band(b, 0xFF) / 255
end

--[[
	Convert 0.0-1.0 rgb to 0-255
	
	@tparam number r Red channel value
	@tparam number g Green channel value
	@tparam number b Blue channel value
	@treturn number Red absolute value
	@treturn number Green absolute value
	@treturn number Blue absolute value
]]
function colors.absRGB(r,g,b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
	return -- From colors.packRGB (but without shifts)
        bit32.band(r * 255, 0xFF),
        bit32.band(g * 255, 0xFF),
        bit32.band(b * 255, 0xFF)
end

--[[
	Pack hex from 0-255 rgb
	
	@tparam number r Red absolute value
	@tparam number g Green absolute value
	@tparam number b Blue absolute value
	@treturn number Hex 24bit number
]]
function colors.packAbsRGB(r,g,b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
	return
        bit32.band(r, 0xFF) * 2 ^ 16 +
        bit32.band(g, 0xFF) * 2 ^ 8 +
        bit32.band(b, 0xFF)
end

--[[
	Unpack hex to 0-255 rgb
	
	@tparam number hex Hex 24bit number
	@treturn number Red absolute value
	@treturn number Green absolute value
	@treturn number Blue absolute value
]]
function colors.unpackAbsRGB(hex)
	expect(1, hex, "number")
    return
        bit32.band(bit32.rshift(hex, 16), 0xFF),
        bit32.band(bit32.rshift(hex, 8), 0xFF),
        bit32.band(hex, 0xFF)
end

colours.norm = colors.norm
colours.abs = colors.abs
colours.normRGB = colors.normRGB
colours.absRGB = colors.absRGB
colours.packAbsRGB = colors.packAbsRGB
colours.unpackAbsRGB = colors.unpackAbsRGB

--[[
-- Get patch path
-- https://stackoverflow.com/a/23535333/23563047
local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end
-- Autorun this patches for _ENV resets
shell.execute_post = shell.execute
function shell.execute(command, ...)
	print(script_path()..'patches')
	require(script_path()..'patches')
	print(package.path)
	shell.execute_post(command, ...)
end
]]
print("Now your computer patched by PavelKom :^)")

_G._PATCHED_BY_PAVELKOM = true
