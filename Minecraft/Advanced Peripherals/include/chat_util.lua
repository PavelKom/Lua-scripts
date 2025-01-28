--[[
	Chat Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Chat Box
	https://advancedperipherals.netlify.app/peripherals/chat_box/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}

lib.CHATCOLORS = {
	BLACK = '&0',
	DARK_BLUE = '&1',
	DARK_GREEN = '&2',
	DARK_AQUA = '&3',
	DARK_RED = '&4',
	DARK_PURPLE = '&5',
	GOLD = '&6',
	GRAY = '&7',
	DARK_GRAY = '&8',
	BLUE = '&9',
	GREEN = '&a',
	AQUA = '&b',
	RED = '&c',
	LIGHT_PURPLE = '&d',
	YELLOW = '&e',
	WHITE = '&f',
	
	OBFUSCATED = '&k',
	BOLD = '&l',
	STRIKETHROUGH = '&m',
	UNDERLINE = '&n',
	ITALIC = '&o',
	RESET = '&r',
}
for k, v in pairs(lib.CHATCOLORS) do
	if lib.CHATCOLORS[string.upper(v)] == nil then lib.CHATCOLORS[string.upper(v)] = v end
	v2 = string.upper(string.gsub(v ,"&", ""))
	if lib.CHATCOLORS[v2] == nil then lib.CHATCOLORS[v2] = v end
end

lib.CHATCOLORS.GREY = lib.CHATCOLORS.GRAY
lib.CHATCOLORS.DARK_GREY = lib.CHATCOLORS.DARK_GRAY
lib.CHATCOLORS.GLITCH = lib.CHATCOLORS.OBFUSCATED
lib.CHATCOLORS.UNDER = lib.CHATCOLORS.UNDERLINE
lib.CHATCOLORS.STRIKE = lib.CHATCOLORS.STRIKETHROUGH
setmetatable(lib.CHATCOLORS, {
	__index = getset.GETTER_TO_UPPER(lib.CHATCOLORS.RESET)
})

function lib.colorText(text, color, effect, resetToDefault)
	return string.format("%s%s%s%s", color and lib.CHATCOLORS[color] or '', effect and lib.CHATCOLORS[effect] or '', text, resetToDefault and lib.CHATCOLORS.RESET or '')
end

-- Events
function lib.waitChatEvent()
	--event, username, message, uuid, isHidden
	return os.pullEvent("chat")
end
function lib.waitChatEventEx(func)
	--[[
	Create semi-infinite loop for chat event listener
	func - callback function. Must have arguments:
		table = {
			event,
			username,
			message,
			uuid,
			isHidden
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('chat_util.waitChatEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("chat")})
	end
end

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'ChatBox')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {}
	self.__setter = {}
	-- Colors (use Chat Code, like &4&l - Dark Red, Bold)
	-- https://www.digminecraft.com/lists/color_list_pc.php
	self.msg = function(message, username, prefix, brackets, bracketColor, range, hidden)
		if hidden then message = "$"..message end
		if username == nil then
			return self.object.sendMessage(message, prefix, brackets, bracketColor, range)
		elseif type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.msg(message, v, prefix, brackets, bracketColor, range)
				if not res then error(string.format("[ChatBox.message] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.object.sendMessageToPlayer(message, username, prefix, brackets, bracketColor, range)
	end
	self.message = self.msg
	self.sendMessage = self.msg
	
	self.toast = function(message, title, username, prefix, brackets, bracketColor, range)
		if type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.toast(message, title, v, prefix, brackets, bracketColor, range)
				if not res then error(string.format("[ChatBox.toast] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.object.sendToastToPlayer(message, title, username, prefix, brackets, bracketColor, range)
	end
	self.sendToastToPlayer = self.toast
	
	-- Json text generator:
	-- https://minecraft.tools/en/json_text.php?json=Welcome%20to%20Minecraft%20Tools
	self.fmsg = function(json, username, prefix, brackets, bracketColor, range)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		if username == nil then
			return self.object.sendFormattedMessage(json, prefix, brackets, bracketColor, range)
		elseif type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.fmsg(json, v, prefix, brackets, bracketColor, range)
				if not res then error(string.format("[ChatBox.fmsg] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.object.sendFormattedMessageToPlayer(json, username, prefix, brackets, bracketColor, range)
	end
	self.jmsg = self.fmsg
	self.fmessage = self.fmsg
	self.sendFormattedMessage = self.fmsg
	self.jmessage = self.fmsg
	
	self.ftoast = function(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
		if type(messageJson) == 'table' then
			messageJson = textutils.serialiseJSON(messageJson)
		end
		if type(titleJson) == 'table' then
			titleJson = textutils.serialiseJSON(titleJson)
		end
		if type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.ftoast(messageJson, titleJson, v, prefix, brackets, bracketColor, range)
				if not res then error(string.ftoast("[ChatBox.fmsg] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.object.sendFormattedToastToPlayer(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	end
	self.sendFormattedToastToPlayer = self.ftoast
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "ChatBox",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.ChatBox=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="chatBox",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="ChatBox",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

lib.msg = function(message, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	Peripheral.default.msg(message, username, prefix, brackets, bracketColor, range)
end
lib.message = lib.msg
lib.toast = function(message, title, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	Peripheral.default.toast(message, title, username, prefix, brackets, bracketColor, range)
end
lib.fmsg = function(json, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	Peripheral.default.fmsg2(json, username, prefix, brackets, bracketColor, range)
end
lib.jmsg = lib.fmsg
lib.ftoast = function(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	Peripheral.default.ftoast(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
end

return lib