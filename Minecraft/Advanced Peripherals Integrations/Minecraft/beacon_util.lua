--[[
	Beacon Utility library by PavelKom.
	Version: 0.1
	Wrapped Beacon
	https://docs.advanced-peripherals.de/integrations/minecraft/beacon/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Beacon')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		level = function() return self.object.getLevel() end,
		effect = function() return self.object.getPrimaryEffect() end,
		effect2 = function() return self.object.getSecondaryEffect() end,
	}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Level: %i Effects: '%s' | '%s'", type(self), self.name, self.level, self.effect, self.effect2)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Beacon",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Beacon=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="beacon",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Beacon",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
