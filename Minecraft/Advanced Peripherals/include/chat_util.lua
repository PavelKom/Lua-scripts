--[[
	Chat Utility library by PavelKom.
	Version: 0.9
	Wrapped Chat Box
	https://advancedperipherals.netlify.app/peripherals/chat_box/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

this_library.CHATCOLORS = {
	BLACK = '§0',
	DARK_BLUE = '§1',
	DARK_GREEN = '§2',
	DARK_AQUA = '§3',
	DARK_RED = '§4',
	DARK_PURPLE = '§5',
	GOLD = '§6',
	GRAY = '§7',
	DARK_GRAY = '§8',
	BLUE = '§9',
	GREEN = '§a',
	AQUA = '§b',
	RED = '§c',
	LIGHT_PURPLE = '§d',
	YELLOW = '§e',
	WHITE = '§f',
	
	OBFUSCATED = '§k',
	BOLD = '§l',
	STRIKETHROUGH = '§m',
	UNDERLINE = '§n',
	ITALIC = '§o',
	RESET = '§r',
}
for k, v in pairs(this_library.CHATCOLORS) do
	if this_library.CHATCOLORS[string.upper(v)] == nil then this_library.CHATCOLORS[string.upper(v)] = v end
end

this_library.CHATCOLORS.GREY = this_library.CHATCOLORS.GRAY
this_library.CHATCOLORS.DARK_GREY = this_library.CHATCOLORS.DARK_GRAY
this_library.CHATCOLORS.GLITCH = this_library.CHATCOLORS.OBFUSCATED
this_library.CHATCOLORS.UNDER = this_library.CHATCOLORS.UNDERLINE
this_library.CHATCOLORS.STRIKE = this_library.CHATCOLORS.STRIKETHROUGH
setmetatable(this_library.CHATCOLORS, {
	__index = getset.GETTER_TO_UPPER(this_library.CHATCOLORS.RESET)
})

function this_library.colorText(text, color, effect, resetToDefault)
	return string.format("%s%s%s%s", color and this_library.CHATCOLORS[color] or '', effect and this_library.CHATCOLORS[effect] or '', text, resetToDefault and this_library.CHATCOLORS.RESET or '')
end

-- Events
function this_library.waitChatEvent()
	--event, username, message, uuid, isHidden
	return os.pullEvent("chat")
end
function this_library.waitChatEventEx(func)
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

-- Peripheral
function this_library:ChatBox(name)
	local def_type = 'chatBox'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to ChatBox '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	-- Colors (use Chat Code, like &4&l - Dark Red, Bold)
	-- https://www.digminecraft.com/lists/color_list_pc.php
	ret.msg = function(message, username, prefix, brackets, bracketColor, range)
		if username == nil then
			return ret.object.sendMessage(message, prefix, brackets, bracketColor, range)
		end
		return ret.object.sendMessageToPlayer(message, username, prefix, brackets, bracketColor, range)
	end
	ret.message = ret.msg
	ret.sendMessage = ret.msg
	
	ret.toast = function(message, title, username, prefix, brackets, bracketColor, range)
		ret.object.sendToastToPlayer(message, title, username, prefix, brackets, bracketColor, range)
	end
	ret.sendToastToPlayer = ret.toast
	
	-- Json text generator:
	-- https://minecraft.tools/en/json_text.php?json=Welcome%20to%20Minecraft%20Tools
	ret.fmsg = function(json, username, prefix, brackets, bracketColor, range)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		if username == nil then
			return ret.object.sendFormattedMessage(json, prefix, brackets, bracketColor, range)
		end
		return ret.object.sendFormattedMessageToPlayer(json, username, prefix, brackets, bracketColor, range)
	end
	ret.jmsg = ret.fmsg
	ret.fmessage = ret.fmsg
	ret.sendFormattedMessage = ret.fmsg
	ret.jmessage = ret.fmsg
	
	ret.ftoast = function(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
		if type(messageJson) == 'table' then
			messageJson = textutils.serialiseJSON(messageJson)
		end
		if type(titleJson) == 'table' then
			titleJson = textutils.serialiseJSON(titleJson)
		end
		return ret.object.sendFormattedToastToPlayer(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	end
	ret.sendFormattedToastToPlayer = ret.ftoast
	
	ret.__getter = {}
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Chat box '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:ChatBox()
	end
end

this_library.msg = function(message, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	this_library.DEFAULT_PERIPHERAL.msg(message, username, prefix, brackets, bracketColor, range)
end
this_library.message = this_library.msg
this_library.toast = function(message, title, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	this_library.DEFAULT_PERIPHERAL.toast(message, title, username, prefix, brackets, bracketColor, range)
end
this_library.fmsg = function(json, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	this_library.DEFAULT_PERIPHERAL.fmsg2(json, username, prefix, brackets, bracketColor, range)
end
this_library.jmsg = this_library.fmsg
this_library.ftoast = function(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	this_library.DEFAULT_PERIPHERAL.ftoast(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
end

return this_library

