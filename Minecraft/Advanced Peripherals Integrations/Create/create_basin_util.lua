--[[
	Basin Utility library by PavelKom.
	Version: 0.1
	Wrapped Basin
	https://docs.advanced-peripherals.de/integrations/create/basin/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Basin')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		input = function() return self.object.getInputFluids() end,
		output = function() return self.object.getOutputFluids() end,
		filter = function() return self.object.getFilter() end,
		items = function() return self.object.getInventory() end,
	}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Basin",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Basin=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="basin",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Basin",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
