--[[
	Lua Patcher library by PavelKom.
	Version: 0.2
	Patch some broken or non-existed methods
]]
-- TABLE

--[[
	Patch for __ipairs
	https://stackoverflow.com/a/77354254/
	pairs(tbl) return tbl.__pairs or default pairs method.
	ipairs(tbl) NOT return tbl.__pairs BUT return default ipairs method.
]]
if not _G.raw_ipairs then
	_G.raw_ipairs = ipairs
	ipairs = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__ipairs then
			return metatable.__ipairs(t)
		end
		return raw_ipairs(t)
	end
end
if not _G.raw_type then
	_G.raw_type = type -- Copy default type function as raw_type
	type = function(t)
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
if not _G.subtype then
	_G.subtype = function(t)
		local metatable = getmetatable(t)
		if metatable and metatable.__subtype then
			if type(metatable.__subtype) == 'function' then -- If __subtype is function
				return metatable.__subtype(t)
			else -- If type not function but callable
				local t = getmetatable(metatable.__subtype)
				if t and t.__call then
					return metatable.__subtype(t)
				end
			end
			return metatable.__subtype
		end
		return type(t)
	end
end
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

--[[
	Patch for table library. Add deep copy function
	https://gist.github.com/tylerneylon/81333721109155b2d244

	table.copy(t: table)
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

	string.split(inputstr: string[, sep: string])
]]
function string.split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

local tab = {
["("] = "%(",[")"] = "%)",["."] = "%.",["%"] = "%%",["+"] = "%+",
["-"] = "%-",["*"] = "%*",["?"] = "%?",["["] = "%[",["]"] = "%]",
["^"] = "%^",["$"] = "%$",
}

function string.replace(inputstr, non_pattern, repl)
	for k, v in pairs(tab) do
		if string.find(non_pattern, v) then
			non_pattern = string.gsub(non_pattern, v, "%"..v)
		end
	end
	return string.gsub(inputstr, non_pattern, repl)
end



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

-- Clamn value between other two values
function math.clamp(value, minimum, maximum)
    expect(1, value, "number")
    expect(2, minimum, "number", "nil")
    expect(3, maximum, "number", "nil")
	
	minimum = minimum or 0
	maximum = maximum or 1
	
	return math.max(minimum, math.min(value, maximum))
end

-- COLO(U)RS

-- Add internal blit index support
for i=0, 15 do
	colors[string.format("%x",i)] = 2 ^ i
	colours[string.format("%x",i)] = 2 ^ i
end
-- Convert 0-255 channel to 0.0-1.0
function colors.norm(value) -- value: number
    expect(1, value, "number")
	return math.clamp(value,0, 255) / 255
end
-- Convert 0.0-1.0 channel to 0-255
function colors.abs(value)
    expect(1, value, "number")
	return math.clamp(value,0, 1) * 255
end
-- Convert 0-255 rgb to 0.0-1.0
function colors.normRGB(r,g,b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
	return math.clamp(r,0, 255) / 255, math.clamp(g,0, 255) / 255, math.clamp(b,0, 255) / 255
end
-- Convert 0.0-1.0 rgb to 0-255
function colors.absRGB(r,g,b)
    expect(1, r, "number")
    expect(2, g, "number")
    expect(3, b, "number")
	return math.clamp(r,0, 1) * 255, math.clamp(g,0, 1) * 255, math.clamp(b,0, 1) * 255
end
-- Get hex from 0-255 rgb
function colors.packAbsRGB(r,g,b)
	return colors.packRGB(colors.normRGB(r,g,b))
end
-- Get 0-255 rgb from hex
function colors.unpackAbsRGB(hex)
	return colors.absRGB(colors.packRGB(hex))
end

colours.norm = colors.norm
colours.abs = colors.abs
colours.normRGB = colors.normRGB
colours.absRGB = colors.absRGB
colours.packAbsRGB = colors.packAbsRGB
colours.unpackAbsRGB = colors.unpackAbsRGB
