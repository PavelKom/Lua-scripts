--[[
	Colony Integrator peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/colony_integrator/
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Colony name: '%s' Colony style: '%s'", subtype(self), peripheral.getName(self), self.colonyName, self.colonyStyle)
end
function Peripheral.__init(self)
	self.__getter = {
		citizens = function() return self.getCitizens() end,
		visitors = function() return self.getVisitors() end,
		buildings = function() return self.getBuildings() end,
		research = function() return self.getResearch() end,
		requests = function() return self.getRequests() end,
		orders = function() return self.getWorkOrders() end,
		colonyID = function() return self.getColonyID() end,
		colonyName = function() return self.getColonyName() end,
		colonyStyle = function() return self.getColonyStyle() end,
		location = function() return self.getLocation() end,
		happiness = function() return self.getHappiness() end,
		isActive = function() return self.isActive() end,
		isUnderAttack = function() return self.isUnderAttack() end,
		isInColony = function() return self.isInColony() end,
		num = function() return self.amountOfCitizens() end,
		max = function() return self.maxOfCitizens() end,
		graves = function() return self.amountOfGraves() end,
		sites = function() return self.amountOfConstructionSites() end,
	}
	self.__getter.id = self.__getter.colonyID
	self.__getter.style = self.__getter.colonyStyle
	self.__getter.loc = self.__getter.location
	self.__getter.pos = self.__getter.location
	self.__getter.happy = self.__getter.happiness
	self.__getter.attacked = self.__getter.isUnderAttack
	self.__getter.inside = self.__getter.isInColony
	
	self.ordersResources = function(workOrderId) return self.getWorkOrderResources(workOrderId) end
	self.builderResources = function(position) return self.getBuilderResources(position) end
	
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "colonyIntegrator", "Colony Integrator")

local lib = {}
lib.ColonyIntegrator = Peripheral

function lib.help()
	local text = {
		"Colony Integrator library. Contains:\n",
		"ColonyIntegrator",
		"([name]) - Peripheral wrapper\n",
	}
	local c = {
		colors.red,
	}
	if term.isColor() then
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		term.setBackgroundColor(colors.black)
		for i=1, #text do
			term.setTextColor(i % 2 == 1 and colors.white or c[i/2])
			term.write(text[i])
			if i % 2 == 1 then
				local x,y = term.getCursorPos()
				term.setCursorPos(1,y+1)
			end
		end
		term.setBackgroundColor(bg)
		term.setTextColor(fg)
	else
		print(table.concat(text))
	end
end

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="ColonyIntegrator",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Colony Integrator (Advanced Peripherals)"
	end,
})

return lib
