--[[
	Lua Patcher library by PavelKom.
	Version: 0.1
	Patch some broken or non-existed methods
]]

--[[
	Patch for __ipairs
	https://stackoverflow.com/a/77354254/
	pairs(tbl) return tbl.__pairs or default pairs method.
	ipairs(tbl) NOT return tbl.__pairs BUT return default ipairs method.
]]
local raw_ipairs = ipairs
ipairs = function(t)
    local metatable = getmetatable(t)
    if metatable and metatable.__ipairs then
        return metatable.__ipairs(t)
    end
    return raw_ipairs(t)
end

--[[
	Patch for string library. Add split function
	https://stackoverflow.com/a/7615129/

	string.split(inputstr: string[, sep: string])
]]
--[[ OLD VERSION
function string.split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end]]

function string.split(inputstr, sep)
	sep=sep or '%s'
	local t = {}
	for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
		table.insert(t,field)
		if s == "" then
			return t
		end
	end
end

--[[
	Patch for table library. Add copy function
	https://gist.github.com/tylerneylon/81333721109155b2d244

	table.copy(t: table)
]]
--[[
function table.copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end
]]

function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return res
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
		if v2 == nil or not deepcompare(v1,v2) then return false end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not deepcompare(v1,v2) then return false end
	end
	return true
end





