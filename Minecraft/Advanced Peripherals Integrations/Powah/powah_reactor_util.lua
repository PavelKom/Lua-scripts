--[[
	Reactor library by PavelKom.
	ONLY FOR 1.19.2 VERSION
	Version: 0.1
	Wrapped Reactor
	https://docs.advanced-peripherals.de/integrations/powah/reactor/
	TODO: Add manual
]]
getset = require 'getset_util'

if _MC_VERSION and _MC_MINOR ~= 19 and _MC_BUILD ~= 2 then
	error("Powah Reactor peripheral only for Minecraft 1.19.2")
end

local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Reactor')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		energy = function() return self.object.getEnergy() end,
		max = function() return self.object.getMaxEnergy() end,
		burning = function() return self.object.isBurning() end,
		fuel = function() return self.object.getFuel() end,
		carbon = function() return self.object.getCarbon() end,
		redstone = function() return self.object.getRedstone() end,
		temp = function() return self.object.getTemperature() end,
		inv_uraninite = function() return self.object.getInventoryUraninite() end,
		inv_redstone = function() return self.object.getInventoryRedstone() end,
		inv_carbon = function() return self.object.getInventoryCarbon() end,
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
		__type = "Reactor",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Reactor=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="uraniniteReactor",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Reactor",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
