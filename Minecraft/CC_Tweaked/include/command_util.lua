--[[
	Command Block Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Command Block
	https://tweaked.cc/peripheral/command.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__objs = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'command', 'Command Block', Peripheral)
	if wrapped ~= nil then return wrapped end
	ret.__getter = {command = function() return self.object.getCommand() end,}
	self.__setter = {command = function(value) self.object.setCommand(value) end,}
	self.run =  function() return self.object.runCommand() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", self.type, self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	Peripheral.__objs[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__objs[_name] = nil end
end
lib.CommandBlock=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

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
