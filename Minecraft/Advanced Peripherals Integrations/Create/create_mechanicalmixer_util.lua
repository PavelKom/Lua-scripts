--[[
	Mechanical Mixer Utility library by PavelKom.
	Version: 0.1
	Wrapped Mechanical Mixer
	https://docs.advanced-peripherals.de/integrations/create/mechanicalmixer/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'mechanicalMixer', 'Mechanical Mixer', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		running = function() return self.object.isRunning() end,
		basin = function() return self.object.hasBasin() end,
	}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Running: %i Basin: %i", type(self), self.name, self.running, self.basin)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Mechanical Mixer"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.MechanicalMixer=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
