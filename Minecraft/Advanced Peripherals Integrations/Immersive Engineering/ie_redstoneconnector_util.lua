--[[
	Redstone Wire Connector Utility library by PavelKom.
	Version: 0.1
	Wrapped Redstone Wire Connector
	https://docs.advanced-peripherals.de/integrations/immersive_engineering/connector/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'redstoneConnector', 'Redstone Wire Connector', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		channel = function() return self.object.getRedstoneChannel() end,
		output = function() return self.object.getOutput() end,
		isInput = function() return self.object.isInputMode() end,
	}
	self.__setter = {
		channel = function(color) return self.object.setRedstoneChannel(color) end,
	}
	self.getRedstoneForChannel = function(color) return self.object.getRedstoneForChannel(color) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Redstone Wire Connector"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.RedstoneWireConnector=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
