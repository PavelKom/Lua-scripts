--[[
	Redstone Integrator Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Redstone Integrator
	https://advancedperipherals.netlify.app/peripherals/redstone_integrator/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
lib.SIDES = getset.SIDES

function outputParser(tbl)
	return function(side, value)
		if getset.STRING_TO_BOOLEAN(value) ~= nil then
			tbl.setOutput(side, getset.STRING_TO_BOOLEAN(value))
		else
			tbl.setAnalogOutput(side, tonumber(value))
		end
	end
end

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Redstone Integrator')
	if wrapped ~= nil then return wrapped end
	
	self.getInput = function(side) return self.object.getInput(lib.SIDES[side]) end
	self.getAnalogInput = function(side) return self.object.getAnalogInput(lib.SIDES[side]) end
	self.getOutput = function(side) return self.object.getOutput(lib.SIDES[side]) end
	self.getAnalogOutput = function(side) return self.object.getAnalogOutput(lib.SIDES[side]) end
	self.setOutput = function(side, powered) return self.object.setOutput(lib.SIDES[side], powered) end
	self.setAnalogOutput = function(side, powered) return self.object.setAnalogOutput(lib.SIDES[side], powered) end
	
	self.input = getset.metaSide({}, self.getInput, _, self.getAnalogInput, self.getAnalogInput)
	
	self.output = getset.metaSide({}, self.getOutput, outputParser(self), self.getAnalogOutput, self.getAnalogOutput)
	
	self.__getter = {}
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name, self.block)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Redstone Integrator",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.RedstoneIntegrator=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="redstoneIntegrator",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="RedstoneIntegrator",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.getInput(side)
	testDefaultPeripheral()
	return Peripheral.default.getInput(side)
end
function lib.getOutput(side)
	testDefaultPeripheral()
	return Peripheral.default.getOutput(side)
end
function lib.getAnalogInput(side)
	testDefaultPeripheral()
	return Peripheral.default.getAnalogInput(side)
end
function lib.getAnalogOutput(side)
	testDefaultPeripheral()
	return Peripheral.default.getAnalogOutput(side)
end
function lib.setOutput(side, powered)
	testDefaultPeripheral()
	return Peripheral.default.setOutput(side, powered)
end
function lib.setAnalogOutput(side, powered)
	testDefaultPeripheral()
	return Peripheral.default.setAnalogOutput(side, powered)
end

return lib
