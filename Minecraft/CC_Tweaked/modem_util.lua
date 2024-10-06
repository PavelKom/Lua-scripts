--[[
	Modem Utility library by PavelKom.
	Version: 0.9
	Wrapped Drive
	https://tweaked.cc/peripheral/modem.html
	TODO: Add manual
]]

getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil
-- Events
function this_library.waitModemMessageEvent()
	--event, side, channel, reply, message, distance
	return os.pullEvent("modem_message")
end
function this_library.waitModemMessageEventEx(func)
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

-- Peripheral
function this_library:Modem(name)
	local def_type = 'modem'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Modem '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		wireless = function() return ret.object.isWireless() end,
		namesRemote = function() return ret.object.getNamesRemote() end,
		nameLocal = function() return ret.object.getNameLocal() end,
	}
	ret.open = function(channel) return pcall(ret.object.open,channel) end
	ret.isOpen = function(channel)
		local res, err = pcall(ret.object.isOpen,channel)
		return res and err or res, err
	end
	ret.close = function(channel) 
		if channel then return pcall(ret.object.close,channel) end
		ret.object.closeAll()
	end
	ret.transmit = function(channel, replyChannel, payload) return pcall(ret.object.transmit,channel, replyChannel, payload) end
	ret.isPresent = function(name) return ret.object.isPresentRemote(name) end
	ret.getType = function(name) return ret.object.getTypeRemote(name) end
	ret.hasType = function(name, _type) return ret.object.hasTypeRemote(name, _type) end
	ret.methods = function(name) return ret.object.getMethodsRemote(name) end
	ret.call = function(remoteName, method, ...) return ret.object.callRemote(remoteName, method, ...) end
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Modem '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end


return this_library
