--[[
	Modem Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Drive
	https://tweaked.cc/peripheral/modem.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'modem', 'Modem', Peripheral)
	if wrapped ~= nil then return wrapped end
	self.__getter = {
		wireless = function() return self.object.isWireless() end,
		namesRemote = function()
			if self.wireless then error("Modem.namesRemote allowed only for wired modems") end
			return self.object.getNamesRemote() end,
		nameLocal = function()
			if self.wireless then error("Modem.nameLocal allowed only for wired modems") end
			return self.object.getNameLocal() end,
	}
	self.open = function(channel) return pcall(self.object.open,channel) end
	self.isOpen = function(channel)
		local res, err = pcall(self.object.isOpen,channel)
		return res and err or res, err
	end
	self.close = function(channel)
		if channel then return pcall(self.object.close,channel) end
		self.object.closeAll()
	end
	self.transmit = function(channel, replyChannel, payload) return pcall(self.object.transmit,channel, replyChannel, payload) end
	self.isPresent = function(name)
		if self.wireless then error("Modem.isPresent allowed only for wired modems") end
		return self.object.isPresentRemote(name) end
	self.getType = function(name)
		if self.wireless then error("Modem.getType allowed only for wired modems") end
		return self.object.getTypeRemote(name) end
	self.hasType = function(name, _type)
		if self.wireless then error("Modem.hasType allowed only for wired modems") end
		return self.object.hasTypeRemote(name, _type) end
	self.methods = function(name)
		if self.wireless then error("Modem.methods allowed only for wired modems") end
		return self.object.getMethodsRemote(name) end
	self.call = function(remoteName, method, ...)
		if self.wireless then error("Modem.call allowed only for wired modems") end
		return self.object.callRemote(remoteName, method, ...) end
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Modem"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.Modem=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

-- Events
function lib.waitModemMessageEvent()
	--event, side, channel, reply, message, distance
	return os.pullEvent("modem_message")
end
function lib.waitModemMessageEventEx(func)
	--[[
	Create semi-infinite loop for modem_message event listener
	func - callback function. Must have arguments:
		table = {
			event,		string: The event name.
			side,		string: The side of the modem that received the message.
			channel,	number: The channel that the message was sent on.
			reply,		number: The reply channel set by the sender.
			message,	any: The message as sent by the sender.
			distance	number|nil: The distance between the sender and the receiver in blocks, or nil if the message was sent between dimensions.
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('modem_util.waitModemMessageEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("modem_message")})
	end
end

return lib
