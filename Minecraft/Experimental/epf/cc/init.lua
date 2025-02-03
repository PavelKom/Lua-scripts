--[[
	EPF dublibrary for CC:Tweaked
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	
	Manager for CC:Tweaked peripherals
]]

local epf = require 'epf'

local lib = {lib={}, p={}, u={}}

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
		lib.lib[_m.__name] = l
		for k,v in pairs(l) do
			if custype(v) == "peripheral wrapper" then
				if lib.p[k] then error("Duplicate peripheral names!")
				lib.p[k] = v
			elseif custype(v) == "peripheral wrapper" then
				if lib.u[k] then error("Duplicate utility names!")
				lib.u[k] = v
			end
		end
	end
end

lib = setmetatable(lib, {
	__name="library",
	__subtype="MOD_CCTweaked",
	__tostring=function(self)
		return "EPF-library for CC:Tweaked"
	end,
})

return lib
