--[[
	Redstone Integrator Utility library by PavelKom.
	Version: 0.9
	Wrapped Redstone Integrator
	https://advancedperipherals.netlify.app/peripherals/redstone_integrator/
	TODO: Add manual
]]

local this_library = {}
-- Relative and cardinal directions
this_library.SIDES = {'right','left','front','back','top','bottom','north','south','east','west','up','down',}
-- add .RIGHT, .NORTH, ... and .SIDES.RIGHT .CARDINAL.NORTH, ...
for k,v in ipairs(this_library.SIDES) do
	this_library[string.upper(v)] = v
	this_library.SIDES[string.upper(v)] = v
	--this_library.SIDES[k] = nil
end
setmetatable(this_library.SIDES, {__index = getset.GETTER_TO_UPPER(this_library.SIDES.UP)})

this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:RedstoneIntegrator(name)
	name = name or 'redstoneIntegrator'
	local ret = {object = peripheral.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Redstone Integrator '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)

	ret.getInput = function(side) return ret.object.getInput(this_library.SIDES[side]) end
	ret.getOutput = function(side) return ret.object.getOutput(this_library.SIDES[side]) end
	ret.getAnalogInput = function(side) return ret.object.getAnalogInput(this_library.SIDES[side]) end
	ret.getAnalogOutput = function(side) return ret.object.getAnalogOutput(this_library.SIDES[side]) end
	ret.setOutput = function(side, powered) return ret.object.setOutput(this_library.SIDES[side], powered) end
	ret.setAnalogOutput = function(side, powered) return ret.object.setAnalogOutput(this_library.SIDES[side], powered) end
	
	ret.input = {}
	setmetatable(ret.input, {
	__call = function()
		local result = {}
		for k, v in pairs(this_library.SIDES) do
			if result[v] == nil then 
				result[v] = ret.getInput(v)
			end
		end
		return result
	end,
	__index = function(self, side) return ret.getInput(side) end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = self.getInput(key)
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
			value = self.getInput(key)
			return key, value
		end
	end,
	})
	
	ret.iInput = {}
	setmetatable(ret.iInput, {
	__call = function()
		local result = {}
		for k, v in pairs(this_library.SIDES) do
			if result[v] == nil then 
				result[v] = ret.getAnalogInput(v)
			end
		end
		return result
	end,
	__index = function(self, side) return ret.getAnalogInput(side) end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = self.getAnalogInput(key)
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
			value = self.getAnalogInput(key)
			return key, value
		end
	end,
	})
	
	ret.output = {}
	setmetatable(ret.output, {
	__call = function(side, value)
		if side ~= nil and value ~= nil then
			ret.setOutput(side, value)
		elseif side == nil and value ~= nil then
			for k, v in pairs(this_library.SIDES) do
				ret.setOutput(v, value)
			end
		elseif side ~!= nil and value == nil then
			ret.setOutput(side, not ret.getOutput(side))
		end
		local result = {}
		for k, v in pairs(this_library.SIDES) do
			if result[v] == nil then 
				result[v] = ret.getOutput(v)
			end
		end
		return result
	end,
	__index = function(self, side) return ret.getOutput(side) end},
	__newindex = function(self, side, value) return ret.setOutput(side, value) end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = self.getOutput(key)
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
			value = self.getOutput(key)
			return key, value
		end
	end,
	})
	
	ret.iOutput = {}
	setmetatable(ret.iOutput, {
	__call = function(side, value)
		if side ~= nil and value ~= nil then
			ret.setAnalogOutput(side, value)
		elseif side == nil and value ~= nil then
			for k, v in pairs(this_library.SIDES) do
				ret.setAnalogOutput(v, 15-value)
			end
		elseif side ~!= nil and value == nil then
			ret.setAnalogOutput(side, not ret.getAnalogOutput(side))
		end
		local result = {}
		for k, v in pairs(this_library.SIDES) do
			if result[v] == nil then 
				result[v] = ret.getAnalogOutput(v)
			end
		end
		return result
	end,
	__index = function(self, method) return ret.getAnalogOutput(method) end},
	__newindex = function(self, method, value) return ret.setAnalogOutput(method, value) end,
	__pairs = function(self) -- Return relatives
		local i = 0
		local key, value
		return function()
			i = i + 1
			key = this_library.SIDES[i]
			if i > 6 then return nil, nil end
			value = self.getAnalogOutput(key)
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
			value = self.getAnalogOutput(key)
			return key, value
		end
	end,
	})
	
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
