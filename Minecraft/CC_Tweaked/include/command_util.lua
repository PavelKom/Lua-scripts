--[[
	Command Block Utility library by PavelKom.
	Version: 0.9
	Wrapped Command Block
	https://tweaked.cc/peripheral/command.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local peripheral_type = 'command'
local peripheral_name = 'Command Block'
Peripheral.__items = {}
Peripheral.new = function(name)
	-- Wrap or find peripheral
	local object = name and peripheral.wrap(name) or peripheral.find(peripheral_type)
	if object == nil then error("Can't connect to "+peripheral_name+" '"..name or peripheral_type.."'") end
	-- If it already registered, return 
	if Peripheral.__items[peripheral.getName(object)] then
		return Peripheral.__items[peripheral.getName(object)]
	end
	-- Test for miss-type
	_name = peripheral.getName(object)
	_type = peripheral.getType(object)
	if _type ~= peripheral_type then error("Invalid peripheral type. Expect '"..peripheral_type.."' Present '"..type.."'") end
	
	local self = {object=object, name=_name, type=_type}
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
	Peripheral.__items[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil
end
lib.CommandBlock=setmetatable(Peripheral,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

lib.getCmd = function()
	testDefaultPeripheral()
	return Peripheral.default.command
end
lib.setCmd = function(value)
	testDefaultPeripheral()
	Peripheral.default.command = value
end
lib.run = function(value)
	testDefaultPeripheral()
	Peripheral.default.run()
end




return lib
