--[[
	Example peripheral peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.1b
	
	Example peripheral wrapper library for Extended Peripheral Framework
]]
-- Import epf API
local epf = require 'epf'

local Peripheral = {} -- Declare wrapper

--[[
	OPTIONAL
	Result of tostring() for wrapped peripheral. Metamethod.
		local monitor = Monitor()
		print(monitor) -- "Monitor 'monitor_0' Size: 20x20 Colors: 1"
	
	If not specified, standard output will be used:
		print(modem) -- "Modem 'modem_1'"
]]
function Peripheral.__str(self)
	-- subtype(self) return visual name for peripheral (Monitor)
	-- peripheral.getName(self) -- return peripheral name (monitor)
	-- Other properties / methods is optional
	return string.format("%s '%s' Size: %ix%i Colors: %s", subtype(self), peripheral.getName(self), self.size, self.color)
end
--[[
	OPTIONAL
	Initialize the wrapped peripheral immediately after creation.
	Set up getters, setters, and subtables.
]]
function Peripheral.__init(self)
	-- Add subtables
	-- self.pos = epf.subtablePos(self, self.getPos, self.setPos, {'x','y','z'})
	
	self.__getter = {
		-- prop = function() return self.getProp() end
	}
	self.__setter = {
		-- prop = function(value) return self.setProp(value) end
	}
	-- Aliases
	-- self.f = self.func
	
	return self
end
-- OPTIONAL
-- Constructor for wrapped peripherals
function Peripheral.new(name)
	local self = name and peripheral.wrap(name) or peripheral.find(Peripheral.type)
	--...
	-- For better understanding, see epf.simpleNew()
	--...
	--self = Peripheral.__init(self) - Run init function
	--...
	return self
end
-- OR let the fixer do it himself
-- REQUIRED
Peripheral = epf.wrapperFixer(Peripheral, "Create_Speedometer", "Speedometer")

--[[
You can extend .new by creating this chain:
function Peripheral._new = epf.simpleNew(Peripheral) -- Create default constructor
function Peripheral.new(name)
	local self = Peripheral._new(name)
	-- do something
	return self
end

Differences compared to the standard method:
Default: .new -> .init -> DONE
Extension: start .new -> ._new (epf.simpleNew) -> .init -> continue .new -> DONE

I don't know why you might need this, but if necessary, it can be done in this simple way
]]

-- Create library
local lib = {}
lib.Monitor = Peripheral -- Add Peripheral to library

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call, -- Calling library is equal as calling Peripheral.new()
	__type="library",
	__subtype="peripheral wrapper library"
})
--[[ Note: You can declare Peripheal.__call (without a metatable) to call wrapped peripherals as functions.
function Peripheal.__call(self, ...)
	self = Peripheal(peripheral.getName(self)) -- Regenerate monitor after add/remove parts
end
]]
return lib
