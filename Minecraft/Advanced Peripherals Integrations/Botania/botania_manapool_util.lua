--[[
	Mana Pool Utility library by PavelKom.
	Version: 0.1
	Wrapped Mana Pool
	https://docs.advanced-peripherals.de/integrations/botania/pool/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'manaPool', 'ManaPool', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		mana = function() return self.object.getMana() end,
		max = function() return self.object.getMaxMana() end,
		needed = function() return self.object.getManaNeeded() end,
		empty = function() return self.object.isEmpty() end,
		full = function() return self.object.isFull() end,
		canCharge = function() return self.object.canChargeItem() end,
		hasItems = function() return self.object.hasItems() end,
		items = function() return self.object.getItems() end,
	}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Mana: %.2f//%.2f", type(self), self.name, self.mana, self.max)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Mana Pool"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.ManaPool=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
