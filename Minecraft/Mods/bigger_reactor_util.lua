--[[
	Bigger Reactor Utility library by PavelKom.
	Version: 0.6
	Wrapped Reactor, Turbine and Heat Exchanger from Bigger Reactor mod
	https://biggerseries.net/biggerreactors/CCintegration.md
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}

-- Peripheralы
function this_library:Reactor(name)
	local def_type = 'BiggerReactors_Reactor'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Reactor '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	ret.__getter = {
		active = function() return ret.object.active() end,
		ambientTemp = function() return ret.object.ambientTemperature() end,
		api = function() return ret.object.apiVersion() end,
		
		passive_cooling = function() return ret.object.battery() ~= nil end,
		maxEnergy = function()
			return ret.passive_cooling and ret.object.battery().capacity() or -1
		end,
		energyProduced = function()
			return ret.passive_cooling and ret.object.battery().producedLastTick() or -1
		end,
		energy = function()
			return ret.passive_cooling and ret.object.battery().stored() or -1
		end,
		
		casingTemp = function() return ret.object.casingTemperature() end,
		connected = function() return ret.object.connected() end,
		rods = function() return ret.object.controlRodCount() end,
		
		active_cooling = function() return ret.object.coolantTank() ~= nil end,
		maxCoolant = function()
			return ret.active_cooling and ret.object.battery().capacity() or -1
		end,
		coldCoolant = function()
			return ret.active_cooling and ret.object.battery().coldFluidAmount() or -1
		end,
		hotCoolant = function()
			return ret.active_cooling and ret.object.battery().hotFluidAmount() or -1
		end,
		maxCoolant = function()
			return ret.active_cooling and ret.object.battery().capacity() or -1
		end,
		maxTransitioned = function()
			return ret.active_cooling and ret.object.battery().maxTransitionedLastTick() or -1
		end,
		transitioned = function()
			return ret.active_cooling and ret.object.battery().transitionedLastTick() or -1
		end,
		
		fuel = function() return ret.object.fuelTank().fuel() end,
		burned = function() return ret.object.fuelTank().burnedLastTick() end,
		maxFuel = function() return ret.object.fuelTank().capacity() end,
		reactivity = function() return ret.object.fuelTank().fuelReactivity() end,
		reactant = function() return ret.object.fuelTank().totalReactant() end,
		waste = function() return ret.object.fuelTank().waste() end,
		
		fuelTemp = function() return ret.object.fuelTemperature() end,
		stackTemp = function() return ret.object.stackTemperature() end,
	}
	ret.__setter = {
		active = function(value) return ret.object.setActive(value) end,
		allRodLevel = function(value) return ret.object.setAllControlRodLevels(value) end,
	}
	ret.__rod = {
		__num=-1,
		__getter={
			index = function() return ret.object.getControlRod(__num).index() end,
			level = function() return ret.object.getControlRod(__num).level() end,
			name = function() return ret.object.getControlRod(__num).name() end,
			valid = function() return ret.object.getControlRod(__num).valid() end,
		},
		__setter={
			level = function(value) return ret.object.getControlRod(__num).setLevel(value) end,
			name = function(value) return ret.object.getControlRod(__num).setName(value) end,
		},
	}
	setmetatable(ret.__rod, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__call = function(self, index)
			local tbl = table.copy(ret.__rod)
			tbl.__num = index
			return tbl
		end,
	})
	
	ret.rod = {}
	setmetatable(ret.rod, {
		__index = function(self, index)
			return ret.__rod(index)
		end,
		__newindex = function(self, index) end,
		__len = function(self) return ret.object.controlRodCount() end,
	})
	
	ret.dump = function() ret.object.dump() end
	ret.eject = function() ret.object.ejectWaste() end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Reactor '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function this_library:Turbine(name)
	local def_type = 'BiggerReactors_Turbine'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Turbine '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	ret.__getter = {
		active = function() return ret.object.active() end,
		api = function() return ret.object.apiVersion() end,
		
		maxEnergy = function() return ret.object.battery().capacity() end,
		energyProduced = function() return ret.object.battery().producedLastTick() end,
		energy = function() return ret.object.battery().stored() end,
		
		coil = function() return ret.object.coilEngaged() end,
		connected = function() return ret.object.connected() end,
		
		flow = function() return ret.object.fluidTank().flowLastTick() end,
		flowMax = function() return ret.object.fluidTank().flowRateLimit() end,
		flowNomimal = function() return ret.object.fluidTank().nominalFlowRate() end,
		
		hotCoolant = function() return ret.object.fluidTank().input().amount() end,
		hotMax = function() return ret.object.fluidTank().input().maxAmount() end,
		hotName = function() return ret.object.fluidTank().input().name() end,
		
		coldCoolant = function() return ret.object.fluidTank().output().amount() end,
		coldMax = function() return ret.object.fluidTank().output().maxAmount() end,
		coldName = function() return ret.object.fluidTank().output().name() end,
		
		rpm = function() return ret.object.fluidTank().rotor().RPM() end,
		efficiency = function() return ret.object.fluidTank().rotor().efficiencyLastTick() end,
	}
	
	ret.__setter = {
		flowNomimal = function(value) return ret.object.fluidTank().setNominalFlowRate(value) end,
		coil = function(value) return ret.object.setCoilEngaged(value) end,
	}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Turbine '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function this_library:HeatExchanger(name)
	local def_type = 'BiggerReactors_Heat-Exchanger'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Heat Exchanger '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	ret.__getter = {
		api = function() return ret.object.apiVersion() end,
		
		ambientRFKT = function() return ret.object.ambientInternalRFKT() end,
		evaporatorIRFKT = function() return ret.object.evaporatorInternalRFKT() end,
		condensorERFKT = function() return ret.object.condensorEvaporatorRFKT() end,
		condensorIRFKT = function() return ret.object.condensorInternalRFKT() end,
		ambientTemp = function() return ret.object.ambientTemperature() end,
		connected = function() return ret.object.connected() end,
		
		-- .internalEnvironment()
		envRfPerK = function() return ret.object.internalEnvironment().rfPerKelvin() end,
		envTemp = function() return ret.object.internalEnvironment().temperature() end,
		
		--.condenser()
		condRfPerK = function() return ret.object.condenser().rfPerKelvin() end,
		condTemp = function() return ret.object.condenser().temperature() end,
		condEnergy = function() return ret.object.condenser().transitionedEnergy() end,
		condTransitioned = function() return ret.object.condenser().transitionedLastTick() end,
		condMax = function() return ret.object.condenser().maxTransitionedLastTick() end,
		condHotAmount = function() return ret.object.condenser().input().amount() end,
		condHotMax = function() return ret.object.condenser().input().maxAmount() end,
		condHotName = function() return ret.object.condenser().input().name() end,
		condColdAmount = function() return ret.object.condenser().output().amount() end,
		condColdMax = function() return ret.object.condenser().output().maxAmount() end,
		condColdName = function() return ret.object.condenser().output().name() end,
		
		--.evaporator()
		evapMax = function() return ret.object.evaporator().maxTransitionedLastTick() end,
		evapRfPerK = function() return ret.object.evaporator().rfPerKelvin() end,
		evapTemp = function() return ret.object.evaporator().temperature() end,
		evapEnergy = function() return ret.object.evaporator().transitionedEnergy() end,
		evapTransitioned = function() return ret.object.evaporator().transitionedLastTick() end,
		evapColdAmount = function() return ret.object.evaporator().input().amount() end,
		evapColdMax = function() return ret.object.evaporator().input().maxAmount() end,
		evapColdName = function() return ret.object.evaporator().input().name() end,
		evapHotAmount = function() return ret.object.evaporator().output().amount() end,
		evapHotMax = function() return ret.object.evaporator().output().maxAmount() end,
		evapHotName = function() return ret.object.evaporator().output().name() end,
	}
	ret.__setter = {}
	ret.dumpCond = function() ret.object.condenser().dump() end
	ret.evapCond = function() ret.object.evaporator().dump() end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Heat Exchanger '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

return this_library
	