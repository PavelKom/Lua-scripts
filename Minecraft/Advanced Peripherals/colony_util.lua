--[[
	Colony Integrator Utility library by PavelKom.
	Version: 0.6
	Wrapped Colony Integrator
	https://advancedperipherals.netlify.app/peripherals/colony_integrator/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:ColonyIntegrator(name)
	local def_type = 'colonyIntegrator'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Colony Integrator '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		citizens = function() return ret.object.getCitizens() end,
		visitors = function() return ret.object.getVisitors() end,
		buildings = function() return ret.object.getBuildings() end,
		research = function() return ret.object.getResearch() end,
		requests = function() return ret.object.getRequests() end,
		orders = function() return ret.object.getWorkOrders() end,
		colonyID = function() return ret.object.getColonyID() end,
		colonyName = function() return ret.object.getColonyName() end,
		colonyStyle = function() return ret.object.getColonyStyle() end,
		location = function() return ret.object.getLocation() end,
		happiness = function() return ret.object.getHappiness() end,
		isActive = function() return ret.object.isActive() end,
		isUnderAttack = function() return ret.object.isUnderAttack() end,
		isInColony = function() return ret.object.isInColony() end,
		num = function() return ret.object.amountOfCitizens() end,
		max = function() return ret.object.maxOfCitizens() end,
		graves = function() return ret.object.amountOfGraves() end,
		sites = function() return ret.object.amountOfConstructionSites() end,
	}
	ret.__getter.id = ret.__getter.colonyID
	ret.__getter.style = ret.__getter.colonyStyle
	ret.__getter.loc = ret.__getter.location
	ret.__getter.pos = ret.__getter.location
	ret.__getter.happy = ret.__getter.happiness
	ret.__getter.attacked = ret.__getter.isUnderAttack
	ret.__getter.inside = ret.__getter.isInColony
	
	ret.ordersResources = function(workOrderId) return ret.object.getWorkOrderResources(workOrderId) end
	ret.builderResources = function(position) return ret.object.getBuilderResources(position) end
	ret.isWithin = function(position) return ret.object.isWithin(position) end
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Colony Integrator '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:ColonyIntegrator()
	end
end

return this_library
