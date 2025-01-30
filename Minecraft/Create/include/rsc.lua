--[[
	RotationSpeedController library by PavelKom.
	Version: 0.2 EXPERIMENTAL
	Wrapped RotationSpeedController peripheral from Create mod
	https://github.com/Creators-of-Create/Create/wiki/ComputerCraft-Integration
	TODO: Add manual
]]
local getset = require 'getset_util'

local Peripheral = {type="Create_RotationSpeedController"}
Peripheral.__getter = {}
Peripheral.__setter = {}
Peripheral.__caller = {}

function Peripheral.__getter.speed(self)
	return self.getTargetSpeed()
end
function Peripheral.__setter.speed(self, value)
	self.setTargetSpeed(value)
end

function Peripheral.new(name)
	local p = name and peripheral.wrap(name) or peripheral.find(Peripheral.type)
	if not p then error("Can't connect to '"..(name or Peripheral.type).."'") end
	if peripheral.getType(p) ~= Peripheral.type then
		error("Invalid peripheral type. Expect '"..Peripheral.type.."' get '"..peripheral.getType(p).."'")
	end
	local m = getmetatable(p)
	
	-- Add getter / caller support
	m.__index = function(self, index)
		if Peripheral.__getter[index] then
			return Peripheral.__getter[index](self)
		elseif Peripheral.__caller[index] then
			return function(...) return Peripheral.__caller[index](self,...) end
		else
			error("Can't get/call "..Peripheral.type.."."..tostring(index))
		end
	end
	-- Add setter support
	m.__newindex = function(self, index, ...)
		if Peripheral.__setter[index] then
			Peripheral.__setter[index](self, ...)
		else
			error("Can't set "..Peripheral.type.."."..tostring(index))
		end
	end
	return p
end

local lib = {}
lib.RotationSpeedController = Peripheral
lib = setmetatable(lib, {__call = function(self,...) return Peripheral.new(...) end})

return lib
