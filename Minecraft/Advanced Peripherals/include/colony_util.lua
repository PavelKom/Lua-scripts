--[[
	Colony Integrator Utility library by PavelKom.
	Version: 0.6.5
	Wrapped Colony Integrator
	https://advancedperipherals.netlify.app/peripherals/colony_integrator/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Colony Integrator')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		citizens = function() return self.object.getCitizens() end,
		visitors = function() return self.object.getVisitors() end,
		buildings = function() return self.object.getBuildings() end,
		research = function() return self.object.getResearch() end,
		requests = function() return self.object.getRequests() end,
		orders = function() return self.object.getWorkOrders() end,
		colonyID = function() return self.object.getColonyID() end,
		colonyName = function() return self.object.getColonyName() end,
		colonyStyle = function() return self.object.getColonyStyle() end,
		location = function() return self.object.getLocation() end,
		happiness = function() return self.object.getHappiness() end,
		isActive = function() return self.object.isActive() end,
		isUnderAttack = function() return self.object.isUnderAttack() end,
		isInColony = function() return self.object.isInColony() end,
		num = function() return self.object.amountOfCitizens() end,
		max = function() return self.object.maxOfCitizens() end,
		graves = function() return self.object.amountOfGraves() end,
		sites = function() return self.object.amountOfConstructionSites() end,
	}
	self.__getter.id = self.__getter.colonyID
	self.__getter.style = self.__getter.colonyStyle
	self.__getter.loc = self.__getter.location
	self.__getter.pos = self.__getter.location
	self.__getter.happy = self.__getter.happiness
	self.__getter.attacked = self.__getter.isUnderAttack
	self.__getter.inside = self.__getter.isInColony
	self.__setter = {}
	
	self.ordersResources = function(workOrderId) return self.object.getWorkOrderResources(workOrderId) end
	self.builderResources = function(position) return self.object.getBuilderResources(position) end
	self.isWithin = function(position) return self.object.isWithin(position) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Colony name: '%s' Colony style: '%s'", type(self), self.name, self.colonyName, self.colonyStyle)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Colony Integrator",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.ColonyIntegrator=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="colonyIntegrator",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="ColonyIntegrator",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
