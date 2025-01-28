--[[
	Redstone Probe Utility library by PavelKom.
	ONLY FOR 1.16 VERSION
	Version: 0.1
	Wrapped Redstone Probe
	https://docs.advanced-peripherals.de/integrations/immersive_engineering/probe/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Redstone Probe')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		send = function() return self.object.getSendingChannel() end,
		receive = function() return self.object.getReceivingChannel() end,
	}
	self.__setter = {
		send = function(color) return self.object.setSendingChannel(color) end,
		receive = function(color) return self.object.setReceivingChannel(color) end,
	}
	self.getRedstoneForChannel = function(color) return self.object.getRedstoneForChannel(color) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Redstone Probe",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.RedstoneProbe=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="redstoneProbe",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="RedstoneProbe",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
