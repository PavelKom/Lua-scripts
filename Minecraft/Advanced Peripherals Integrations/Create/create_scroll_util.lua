--[[
	Blocks with Scroll Value Behaviours Utility library by PavelKom.
	Version: 0.1
	Wrapped Create's Scroll
	https://docs.advanced-peripherals.de/integrations/create/scrollbehaviour/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Create Scroll')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		speed = function() return self.object.getTargetSpeed() end,
	}
	self.__setter = {
		speed = function(value) return self.object.setTargetSpeed(value) end,
	}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Create Scroll",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.CreateScroll=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="scrollBehaviourEntity",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="CreateScroll",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
