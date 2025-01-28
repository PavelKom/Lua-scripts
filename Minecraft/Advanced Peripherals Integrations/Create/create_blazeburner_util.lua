--[[
	Blaze Burner Utility library by PavelKom.
	Version: 0.1
	Wrapped Blaze Burner
	https://docs.advanced-peripherals.de/integrations/create/blazeburner/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Blaze Burner')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		info = function() return self.object.getInfo() end,
	}
	self.__getter.fuel = function() return self.info.fuelType end
	self.__getter.heat = function() return self.info.heatLevel end
	self.__getter.time = function() return self.info.remainingBurnTime end
	self.__getter.creative = function() return self.info.isCreative end
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Blaze Burner",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.BlazeBurner=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="blazeBurner",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="BlazeBurner",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
