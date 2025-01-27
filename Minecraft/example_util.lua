--[[
	Example for wrapping peripherals
	Version: VERSION
	Wrapped PERIPHERAL_NAME
	LINK_TO_INFO
	TODO: TODO_LIST
]]
getset = require 'getset_util' -- Load getset library

local lib = {} -- Init this library for return

local Peripheral = {}
Peripheral.__items = {} -- To avoid re-initialization of the same peripheral
function Peripheral:new(name)
	-- PERIPHERAL_TYPE - like 'monitor' or 'modem'. For peripheral.find
	-- EXAMPLE_PERIPHERAL - Visual name, like 'Monitor' or 'Modem'
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'PERIPHERAL_TYPE', 'EXAMPLE_PERIPHERAL', Peripheral)
	if wrapped ~= nil then return wrapped end -- If peripheral already register, return it

	-- Place for metatables like pos, palette, input, output, etc.

	self.__getter = {} -- Add getters
	self.__setter = {} -- Add setters

	-- Place for methods and aliases

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, -- Bind getter and setter
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS, -- Bind pairs and ipairs
		__tostring = function(self) -- result of tostring()
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "EXAMPLE_PERIPHERAL" -- result of type()
	})
	Peripheral.__items[self.name] = self -- Register peripheral
	if not Peripheral.default then Peripheral.default = self end -- Register default peripheral
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.EXAMPLE_PERIPHERAL=setmetatable(Peripheral,{__call=Peripheral.new}) -- Peripheral() same as Peripheral:new()
lib=setmetatable(lib,{__call=Peripheral.new}) -- If this library contain only one peripheral, lib() same as Peripheral:new()

function testDefaultPeripheral() -- For non-initialization calls
	if not Peripheral.default then
		Peripheral()
	end
end
--[[ Non-initialization call. Use it only if you have ONE peripheral of the current type.
function lib.doJob(...)
	testDefaultPeripheral()
	Peripheral.default.doJob(...)
end
]]
return lib

--[[ Example:
local Per = require "yourperipheral_util"
local expect = require "cc.expect" -- import AFTER patches, getset or peripheral lib for type()

p = Per()
p.doJob(1,2,3,4)
]]
