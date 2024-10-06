--[[
	Redstone Integrator Utility library by PavelKom.
	Version: 0.9
	Wrapped Redstone Integrator
	https://advancedperipherals.netlify.app/peripherals/redstone_integrator/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.SIDES = getset.SIDES

this_library.DEFAULT_PERIPHERAL = nil

function outputParser(tbl)
	return function(side, value)
		if getset.STRING_TO_BOOLEAN(value) ~= nil then
			tbl.setOutput(side, getset.STRING_TO_BOOLEAN(value))
		else
			tbl.setAnalogOutput(side, tonumber(value))
		end
	end
end

-- Peripheral
function this_library:RedstoneIntegrator(name)
	local def_type = 'redstoneIntegrator'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Redstone Integrator '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.getInput = function(side) return ret.object.getInput(this_library.SIDES[side]) end
	ret.getAnalogInput = function(side) return ret.object.getAnalogInput(this_library.SIDES[side]) end
	ret.getOutput = function(side) return ret.object.getOutput(this_library.SIDES[side]) end
	ret.getAnalogOutput = function(side) return ret.object.getAnalogOutput(this_library.SIDES[side]) end
	ret.setOutput = function(side, powered) return ret.object.setOutput(this_library.SIDES[side], powered) end
	ret.setAnalogOutput = function(side, powered) return ret.object.setAnalogOutput(this_library.SIDES[side], powered) end
	
	ret.input = {}
	getset.metaSide(ret.input, ret.getInput, _, ret.getAnalogInput, ret.getAnalogInput)
	--[[
	setmetatable(ret.input, {
	__call = function(self, side) return ret.getAnalogInput(this_library.SIDES[side]) end,
	__index = function(self, side) return ret.getInput(this_library.SIDES[side]) end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = ret.getAnalogInput(key)
			return key, value
		end
	end,
	__ipairs = function(self) -- Return cardinals
		local i = 6
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 12 then return nil, nil end
			value = ret.getAnalogInput(key)
			return key, value
		end
	end,
	})]]
	
	ret.output = {}
	getset.metaSide(ret.output, ret.getOutput, outputParser(ret), ret.getAnalogOutput, ret.getAnalogOutput)
	--[[
	setmetatable(ret.output, {
	__call = function(self, side) return ret.getAnalogOutput(this_library.SIDES[side]) end,
	__index = function(self, side) return ret.getOutput(this_library.SIDES[side]) end,
	__newindex = function(self, side, value)
		if getset.STRING_TO_BOOLEAN(value) ~= nil then
			ret.setOutput(this_library.SIDES[side], getset.STRING_TO_BOOLEAN(value))
		else
			ret.setAnalogOutput(this_library.SIDES[side], tonumber(value))
		end
	end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = ret.getAnalogOutput(key)
			return key, value
		end
	end,
	__ipairs = function(self) -- Return cardinals
		local i = 6
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 12 then return nil, nil end
			value = ret.getAnalogOutput(key)
			return key, value
		end
	end,
	})]]
	ret.__getter = {}
	ret.__setter = {}
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Redstone Integrator '%s'", self.name, self.block)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:RedstoneIntegrator()
	end
end

function this_library.getInput(side)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getInput(side)
end
function this_library.getOutput(side)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getOutput(side)
end
function this_library.getAnalogInput(side)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getAnalogInput(side)
end
function this_library.getAnalogOutput(side)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getAnalogOutput(side)
end
function this_library.setOutput(side, powered)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.setOutput(side, powered)
end
function this_library.setAnalogOutput(side, powered)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.setAnalogOutput(side, powered)
end

return this_library
