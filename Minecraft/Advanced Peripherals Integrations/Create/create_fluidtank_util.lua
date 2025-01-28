--[[
	Fluid Tank Utility library by PavelKom.
	Version: 0.1
	Wrapped Fluid Tank
	https://docs.advanced-peripherals.de/integrations/create/fluidtank/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Fluid Tank')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		info = function() return self.object.getInfo() end,
	}
	self.__getter.capacity = function() return self.info.capacity end
	self.__getter.amount = function() return self.info.amount end
	self.__getter.fluid = function() return self.info.fluid end
	self.__getter.boiler = function() return self.info.isBoiler end
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Fluid Tank",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.FluidTank=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="fluidTank",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="FluidTank",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
