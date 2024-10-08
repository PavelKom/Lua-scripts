--[[
	Command Block Utility library by PavelKom.
	Version: 0.9
	Wrapped Command Block
	https://tweaked.cc/peripheral/command.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local DEFAULT_PERIPHERAL = nil

local peripheral_type = 'command'
local peripheral_name = 'Command Block'
local Peripheral = {}
Peripheral.new = function(name)
	local self = {}
	self.object = name and peripheral.wrap(name) or peripheral.find(peripheral_type)
	if self.object == nil then error("Can't connect to "+peripheral_name+" '"..name or peripheral_type.."'") end
	self.name = peripheral.getName(self.object)
	self.type = peripheral.getType(self.object)
	if self.type ~= peripheral_type then error("Invalid peripheral type. Expect '"..peripheral_type.."' Present '"..self.type.."'") end
	
	ret.__getter = {command = function() return self.object.getCommand() end,}
	self.__setter = {command = function(value) self.object.setCommand(value) end,}
	self.run =  function() return self.object.runCommand() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", peripheral_name, self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return self
end
lib.CommandBlock=setmetatable(Peripheral,{__call=Peripheral.new})

function testDefPer()
	if DEFAULT_PERIPHERAL == nil then
		DEFAULT_PERIPHERAL = Peripheral()
		if DEFAULT_PERIPHERAL == nil then error("Cant connect to any "..peripheral_name)
	end
end
lib.getCmd = function()
	testDefaultPeripheral()
	return DEFAULT_PERIPHERAL.command
	end
end
lib.setCmd = function(value)
	testDefaultPeripheral()
	DEFAULT_PERIPHERAL.command = value
end
lib.run = function(value)
	testDefaultPeripheral() then
	DEFAULT_PERIPHERAL.run()
end




return lib
