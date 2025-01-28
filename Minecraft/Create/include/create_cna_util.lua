--[[
	Create: Crafts & Additions Utility library by PavelKom.
	Version: 0.1
	Wrapped peripherals from Create: Crafts & Additions
	https://advancedperipherals.netlify.app/peripherals/chat_box/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
lib.SIDES = getset.SIDES



function sideMetaTbl2(get)
	return {
		__index = function(self, side)  -- tbl[{a,b}]
			local a,b = table.unpack(side)
			return get(lib.SIDES[a], b)
		end,
	}
end


-- Peripherals
local ElectricMotor = {}
ElectricMotor.__items = {}
function ElectricMotor:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, ElectricMotor, 'Electric Motor')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		speed = function() return self.object.getSpeed() end,
	    abs = function() return math.abs(self.object.getSpeed()) end,
	    dir = function() return self.object.getSpeed() >= 0 and 1 or -1 end,
		extract = function() return self.object.getMaxExtract() end,
		energy = function() return self.object.getEnergyConsumption() end,
		stress = function() return self.object.getStressCapacity() end,
		insert = function() return self.object.getMaxInsert() end,
	}
	self.__setter = {
		speed = function(value) self.object.setSpeed(value) end,
	    abs = function(value) -- non-negative number
			self.object.setSpeed(math.abs(value)*self.dir)
		end,
	    dir = function(value) -- boolean or number
			if type(value) == 'boolean' then
				self.object.setSpeed(self.abs * (value and 1 or -1))
			elseif type(value) == 'number' then
				self.object.setSpeed(self.abs * (value >= 0 and 1 or -1))
			end
		end,
	}
	
	self.translate = function(blocks, rpm) return self.object.translate(blocks, rpm) end
	self.stop = function() self.object.stop() end
	self.rotate = function(degrees, rpm) self.object.rotate(degrees, rpm) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Electric Motor",
		__subtype = "peripheral",
	})
	ElectricMotor.__items[self.name] = self
	if not ElectricMotor.default then ElectricMotor.default = self end
	return self
end
ElectricMotor.delete = function(name)
	if name then ElectricMotor.__items[name] = nil end
end
lib.ElectricMotor=setmetatable(ElectricMotor,{__call=ElectricMotor.new,__type = "peripheral",__subtype="electric_motor",})


local Accumulator = {}
Accumulator.__items = {}
function Accumulator:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Accumulator, 'Accumulator')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		energy = function() return self.object.getEnergy() end,
		cap = function() return self.object.getCapacity() end,
		percent = function() return self.object.getPercent() end,
		height = function() return self.object.getHeight() end,
		extract = function() return self.object.getMaxExtract() end,
		insert = function() return self.object.getMaxInsert() end,
		width = function() return self.object.getWidth() end,
		cap2 = function()
			return self.cap / (math.pow(self.w,2)*self.h)
		end
	}
	self.__getter.maxEnergy = self.__getter.cap
	self.__getter.max = self.__getter.cap
	self.__getter.h = self.__getter.height
	self.__getter.w = self.__getter.width
	self.__getter.cap_per_block = self.__getter.cap2
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Energy: %i/%i Size:%ix%ix%i FE/block: %i", type(self), self.name, self.energy, self.max, self.w, self.w, self.h, self.cap2)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Accumulator",
		__subtype = "peripheral",
	})
	Accumulator.__items[self.name] = self
	if not Accumulator.default then Accumulator.default = self end
	return self
end
Accumulator.delete = function(name)
	if name then Accumulator.__items[name] = nil end
end
lib.Accumulator=setmetatable(Accumulator,{__call=Accumulator.new,__type = "peripheral",__subtype="modular_accumulator",})


local PEI = {}
PEI.__items = {}
function PEI:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, PEI, 'Portable Energy Interface')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		energy = function() return self.object.getEnergy() end,
		cap = function() return self.object.getCapacity() end,
		extract = function() return self.object.getMaxExtract() end,
		insert = function() return self.object.getMaxInsert() end,
		isConnected = function() return self.object.isConnected() end,
		percent = function() return self._get() / self._cap() end,
	}
	self.__getter.maxEnergy = self.__getter.cap
	self.__getter.max = self.__getter.cap
	self.__getter.connected = self.__getter.isConnected
	self.__getter.con = self.__getter.isConnected
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Energy: %i/%i Connected: %s", type(self), self.name, self.energy, self.max, self.isConnected)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Portable Energy Interface",
		__subtype = "peripheral",
	})
	PEI.__items[self.name] = self
	if not PEI.default then PEI.default = self end
	return self
end
PEI.delete = function(name)
	if name then PEI.__items[name] = nil end
end
lib.PEI=setmetatable(PEI,{__call=PEI.new,__type = "peripheral",__subtype="portable_energy_interface",})

local RedstoneRelay = {}
RedstoneRelay.__items = {}
function RedstoneRelay:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, RedstoneRelay, 'Redstone Relay')
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		extract = function() return self.object.getMaxExtract() end,
		insert = function() return self.object.getMaxInsert() end,
		isPowered = function() return self.object.isPowered() end,
		throughput = function() return self.object.getThroughput() end,
	}
	self.__getter.pow = self.__getter.isPowered

	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Power:%s Throughput: %i IO:%i|%i", type(self), self.name, self.isPowered, self.throughput, self.insert, self.extract)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Redstone Relay",
		__subtype = "peripheral",
	})
	RedstoneRelay.__items[self.name] = self
	if not RedstoneRelay.default then RedstoneRelay.default = self end
	return self
end
RedstoneRelay.delete = function(name)
	if name then RedstoneRelay.__items[name] = nil end
end
lib.RedstoneRelay=setmetatable(RedstoneRelay,{__call=RedstoneRelay.new,__type = "peripheral",__subtype="redstone_relay",})


local DigitalAdapter = {}
DigitalAdapter.__items = {}
function DigitalAdapter:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, DigitalAdapter, 'Redstone Relay')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		max_speed = function() return self.object.getKineticTopSpeed end,
	}
	self.__setter = {}
	
	-- Rotational Speed Controller
	self.controller = {}
	self.controller.speed = getset.metaSide(self.object.getTargetSpeed, self.object.setTargetSpeed, _, self.object.getTargetSpeed)
	
	-- Stress and Speed Gauges
	self.gauge = {}
	self.gauge.stress = getset.metaSide(self.object.getKineticStress, _, _, self.object.getKineticStress)
	self.gauge.cap = getset.metaSide(self.object.getKineticCapacity, _, _, self.object.getKineticCapacity)
	self.gauge.speed = getset.metaSide(self.object.getKineticSpeed, _, _, self.object.getKineticSpeed)
	self.max_speed 

	-- Pulley
	self.pulley = getset.metaSide(self.object.getPulleyDistance, _, _, self.object.getPulleyDistance)

	-- Elevators
	self.getFloor = function(side) return self.object.getElevatorFloor(lib.SIDES[side]) end
	self.gotoFloor = function(side, index) return self.object.gotoElevatorFloor(lib.SIDES[side], index) end
	self.getFloors = function(side) return self.object.getElevatorFloors(lib.SIDES[side]) end
	self.getFloorName = function(side, index) return self.object.getElevatorFloorName(lib.SIDES[side], index) end
	
	-- Piston
	self.piston = getset.metaSide(self.object.getPistonDistance, _, _, self.object.getPistonDistance)
	
	-- Bearing
	self.bearing = getset.metaSide(self.object.getBearingAngle, _, _, self.object.getBearingAngle)
	
	-- Display Link
	self.display = {
		clear = function() self.object.clear() end,
		clearLine = function() self.object.clearLine() end,
		print = function(text) self.object.print(text) end,
		__getter = {
			line = function() return self.object.getLine() end,
			maxLines = function() return self.object.getMaxLines() end,
		},
		__setter = {
			line = function(ln) return self.object.setLine(ln) end,
		},
	}
	
	setmetatable(self.display, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
	})
	
	
	
	self.durAngle = function(degrees, rpm)
		return self.object.getDurationAngle(degrees, rpm)
	end
	self.durDistance = function(blocks, rpm)
		return self.object.getDurationDistance(blocks, rpm)
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Digital Adapter",
		__subtype = "peripheral",
	})
	DigitalAdapter.__items[self.name] = self
	if not DigitalAdapter.default then DigitalAdapter.default = self end
	return self
end
DigitalAdapter.delete = function(name)
	if name then DigitalAdapter.__items[name] = nil end
end
lib.DigitalAdapter=setmetatable(DigitalAdapter,{__call=DigitalAdapter.new,__type = "peripheral",__subtype="digital_adapter",})


return lib
