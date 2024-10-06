--[[
	Create: Crafts & Additions Utility library by PavelKom.
	Version: 0.1
	Wrapped peripherals from Create: Crafts & Additions
	https://advancedperipherals.netlify.app/peripherals/chat_box/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.SIDES = getset.SIDES

function sideMeta(get)
	return {
		__index = function(self, side)
			return get(this_library.SIDES[side])
		end,
		__pairs = function(self) -- Return relatives
			local i = 0
			local key, value
			return function()
				i = i + 1
				key = this_library.SIDES[i]
				if i > 6 then return nil, nil end
				value = get(key)
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
				value = get(key)
				return key, value
			end
		end,
	}
end
function sideMeta2(get, set)
	local result = sideMeta(get)
	result.__newindex = function(self, side, value)
		set(this_library.SIDES[side], value)
	end
	return result
end
function sideMetaTbl2(get)
	return {
		__index = function(self, side)  -- tbl[{a,b}]
			local a,b = table.unpack(side)
			return get(this_library.SIDES[a], b)
		end,
	}
end

-- Peripherals
function this_library:ElectricMotor(name)
	local def_type = 'electric_motor'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Electric Motor '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		speed = function() return ret.object.getSpeed() end,
	    abs = function() return math.abs(ret.object.getSpeed()) end,
	    dir = function() return ret.object.getSpeed() >= 0 and 1 or -1 end,
		extract = function() return ret.object.getMaxExtract() end,
		energy = function() return ret.object.getEnergyConsumption() end,
		stress = function() return ret.object.getStressCapacity() end,
		insert = function() return ret.object.getMaxInsert() end,
	}
	ret.__setter = {
		speed = function(value) ret.object.setSpeed(value) end,
	    abs = function(value) -- non-negative number
			ret.object.setSpeed(math.abs(value)*ret.dir)
		end,
	    dir = function(value) -- boolean or number
			if type(value) == 'boolean' then
				ret.object.setSpeed(ret.abs * (value and 1 or -1))
			elseif type(value) == 'number' then
				ret.object.setSpeed(ret.abs * (value >= 0 and 1 or -1))
			end
		end,
	}
	
	ret.translate = function(blocks, rpm) return ret.object.translate(blocks, rpm) end
	ret.stop = function() ret.object.stop() end
	ret.rotate = function(degrees, rpm) ret.object.rotate(degrees, rpm) end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Electric Motor '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:Generator(name)
	local def_type = 'createaddition:alternator'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Generator '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		energy = function() return ret.object.getEnergy() end,
		cap = function() return ret.object.getEnergyCapacity() end,
	}
	ret.__getter.maxEnergy = ret.__getter.cap
	ret.__getter.max = ret.__getter.cap
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Generator '%s' Energy: %i/%i", self.name, self.energy, self.max)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:Accumulator(name)
	local def_type = 'modular_accumulator'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Accumulator '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		energy = function() return ret.object.getEnergy() end,
		cap = function() return ret.object.getCapacity() end,
		percent = function() return ret.object.getPercent() end,
		height = function() return ret.object.getHeight() end,
		extract = function() return ret.object.getMaxExtract() end,
		insert = function() return ret.object.getMaxInsert() end,
		width = function() return ret.object.getWidth() end,
		cap2 = function()
			return ret.cap / (math.pow(ret.w,2)*ret.h)
		end
	}
	ret.__getter.maxEnergy = ret.__getter.cap
	ret.__getter.max = ret.__getter.cap
	ret.__getter.h = ret.__getter.height
	ret.__getter.w = ret.__getter.width
	ret.__getter.cap_per_block = ret.__getter.cap2
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Accumulator '%s' Energy: %i/%i Size:%ix%ix%i FE/block: %i", self.name, self.energy, self.max, self.w, self.w, self.h, self.cap2)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:PEI(name)
	local def_type = 'portable_energy_interface'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Portable Energy Interface '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		energy = function() return ret.object.getEnergy() end,
		cap = function() return ret.object.getCapacity() end,
		extract = function() return ret.object.getMaxExtract() end,
		insert = function() return ret.object.getMaxInsert() end,
		isConnected = function() return ret.object.isConnected() end,
		percent = function() return ret._get() / ret._cap() end,
	}
	ret.__getter.maxEnergy = ret.__getter.cap
	ret.__getter.max = ret.__getter.cap
	ret.__getter.connected = ret.__getter.isConnected
	ret.__getter.con = ret.__getter.isConnected
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Portable Energy Interface '%s' Energy: %i/%i Connected: %s", self.name, self.energy, self.max, self.isConnected)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:RedstoneRelay(name)
	local def_type = 'redstone_relay'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Redstone Relay '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		extract = function() return ret.object.getMaxExtract() end,
		insert = function() return ret.object.getMaxInsert() end,
		isPowered = function() return ret.object.isPowered() end,
		throughput = function() return ret.object.getThroughput() end,
	}
	ret.__getter.pow = ret.__getter.isPowered

	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Redstone Relay '%s' Power:%s Throughput: %i IO:%i|%i", self.name, self.isPowered, self.throughput, self.insert, self.extract)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:DigitalAdapter(name)
	local def_type = 'digital_adapter'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Digital Adapter '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {}
	ret.__setter = {}
	
	-- Display Link
	ret.display = {
		clear = function() ret.object.clear() end,
		clearLine = function() ret.object.clearLine() end,
		print = function() ret.object.print() end,
		__getter = {
			line = function() return ret.object.getLine() end,
			maxLines = function() return ret.object.getMaxLines() end,
		},
		__setter = {
			line = function(ln) return ret.object.setLine(ln) end,
		},
	}
	ret.display.write = ret.display.print
	
	setmetatable(ret.display, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
	})
	
	-- Speed Controller
	ret.controller = {speed = {}}
	getset.metaSide(ret.controller.speed, ret.object.getTargetSpeed, ret.object.setTargetSpeed, _, ret.object.getTargetSpeed)
	
	-- Stress and Speed Gauges
	ret.gauge = {stress={},cap={},speed={},max={},}
	getset.metaSide(ret.gauge.stress, ret.object.getKineticStress, _, _, ret.object.getKineticStress)
	getset.metaSide(ret.gauge.cap, ret.object.getKineticCapacity, _, _, ret.object.getKineticCapacity)
	getset.metaSide(ret.gauge.speed, ret.object.getKineticSpeed, _, _, ret.object.getKineticSpeed)
	getset.metaSide(ret.gauge.max, ret.object.getKineticTopSpeed, _, _, ret.object.getKineticTopSpeed)

	-- Mechanical pulleys (Rope, Hose, or Elevator -Pulley, etc)
	ret.pulley = {}
	getset.metaSide(ret.pulley, ret.object.getPulleyDistance, _, _, ret.object.getPulleyDistance)
	ret.piston = {}
	getset.metaSide(ret.piston, ret.object.getPistonDistance, _, _, ret.object.getPistonDistance)
	ret.bearing = {}
	getset.metaSide(ret.bearing, ret.object.getBearingAngle, _, _, ret.object.getBearingAngle)
	ret.floors = {}
	-- Get/set floor. Call for #floors
	getset.metaSide(ret.floor, ret.object.getElevatorFloor, ret.object.gotoElevatorFloor, ret.object.getElevatorFloors, ret.object.getElevatorFloor)
	ret.floorName = {}
	setmetatable(ret.floorName, sideMetaTbl2(ret.object.getElevatorFloorName))
	ret.durAngle = {}
	setmetatable(ret.durAngle, sideMetaTbl2(ret.object.getDurationAngle))
	ret.durDistance = {}
	setmetatable(ret.durDistance, sideMetaTbl2(ret.object.getDurationDistance))
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Digital Adapter '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

return this_library
