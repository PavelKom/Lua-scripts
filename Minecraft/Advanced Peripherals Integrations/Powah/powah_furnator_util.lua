--[[
	Furnator library by PavelKom.
	ONLY FOR 1.19.2 VERSION
	Version: 0.1
	Wrapped Furnator
	https://docs.advanced-peripherals.de/integrations/powah/furnator/
	TODO: Add manual
]]
getset = require 'getset_util'

if _MC_VERSION and _MC_MINOR ~= 19 and _MC_BUILD ~= 2 then
	error("Powah Furnator peripheral only for Minecraft 1.19.2")
end

local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Furnator')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		energy = function() return self.object.getEnergy() end,
		max = function() return self.object.getMaxEnergy() end,
		burning = function() return self.object.isBurning() end,
		carbon = function() return self.object.getCarbon() end,
		items = function() return self.object.getInventory() end,
	}
	self.__setter = {}
	self.getName = function() return self.object.getName() end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Furnator",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Furnator=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="furnator",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Furnator",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
