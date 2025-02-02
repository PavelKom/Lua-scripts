--[[
	EPF dublibrary for Create
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	
	Manager for Create peripherals
]]

local epf = require 'epf'

local lib = {}

local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)")
end
local rel_path = script_path()
for _,v in pairs(fs.list(rel_path)) do
	if v ~= "init.lua" and not fs.isDir(v) and string.match(v, ".+%.lua") then
		local p = rel_path..v:sub(1,#v-4)
		local l = require(p)
		local _m = getmetatable(l)
		if not _m.__name then
			error("[EPF.CC] Library name not specific for "..p)
		end
		lib[_m.__name] = l
	end
end

lib = setmetatable(lib, {
	__type="library",
	__subtype="peripheral wrappers manager library",
	__tostring=function(self)
		return "EPF-library for Create"
	end,
})

return lib
