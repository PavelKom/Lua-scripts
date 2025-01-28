--[[
	Mana Spreader Utility library by PavelKom.
	Version: 0.1
	Wrapped Mana Spreader
	https://docs.advanced-peripherals.de/integrations/botania/spreader/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'ManaSpreader')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		mana = function() return self.object.getMana() end,
		max = function() return self.object.getMaxMana() end,
		empty = function() return self.object.isEmpty() end,
		full = function() return self.object.isFull() end,
		variant = function() return self.object.getVariant() end,
		bounding = function() return self.object.getBounding() end,
		hasLens = function() return self.object.hasLens() end,
		lens = function() return self.object.getLens() end,
	}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Mana: %.2f//%.2f", type(self), self.name, self.mana, self.max)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Mana Spreader",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.ManaSpreader=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="manaSpreader",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="ManaSpreader",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
