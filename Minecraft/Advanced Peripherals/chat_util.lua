--[[
	Chat Utility library by PavelKom.
	Version: 0.1
	Wrapped Chat Box
	https://advancedperipherals.netlify.app/peripherals/chat_box/
]]

local chat_util = {}
chat_util.DEFAULT_CHATBOX = nil

function chat_util.waitChatEvent()
	--event, username, message, uuid, isHidden
	return os.pullEvent("chat")
end
function chat_util.waitChatEventEx(func)
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

function chat_util:ChatBox(name)
	name = name or 'chatBox'
	local ret = {object = peripherals.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to ChatBox '"..name.."'") end
	ret.name = name
	
	ret.msg = function(message, prefix, brackets, bracketColor, range)
		return ret.object.sendMessage(message, prefix, brackets, bracketColor, range)
	end
	ret.message = ret.msg
	ret.sendMessage = ret.msg
	
	ret.msg2 = function(message, username, prefix, brackets, bracketColor, range)
		return ret.object.sendMessageToPlayer(message, username, prefix, brackets, bracketColor, range)
	end
	ret.message2 = ret.msg2
	ret.sendMessageToPlayer = ret.msg2
	
	ret.toast = function(message, title, username, prefix, brackets, bracketColor, range)
		ret.object.sendToastToPlayer(message, title, username, prefix, brackets, bracketColor, range)
	end
	ret.sendToastToPlayer = ret.toast
	
	-- Json text generator:
	-- https://minecraft.tools/en/json_text.php?json=Welcome%20to%20Minecraft%20Tools
	ret.fmsg = function(json, prefix, brackets, bracketColor, range)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		return ret.object.sendFormattedMessage(json, prefix, brackets, bracketColor, range)
	end
	ret.sendFormattedMessage = ret.fmsg
	
	ret.fmsg2 = function(json, username, prefix, brackets, bracketColor, range)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		return ret.object.sendFormattedMessageToPlayer(json, username, prefix, brackets, bracketColor, range)
	end
	ret.sendFormattedMessageToPlayer = ret.fmsg2
	
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
	
	ret.__public_keys = {name=true,
		msg=true, message=true, sendMessage=true,
		msg2=true, message2=true, sendMessageToPlayer=true,
		toast=true, sendToastToPlayer=true,
		fmsg=true, sendFormattedMessage=true,
		fmsg2=true, sendFormattedMessageToPlayer=true,
		ftoast=true, sendFormattedToastToPlayer=true}
	
	setmetatable(ret, {
		-- getter
		__index = function(self, method)
			if string.sub(tostring(method),1,1) == "_" then return self._nil end
			return self["_"..tostring(method).."_get"]()
		end,
		-- setter
		__newindex = function(self, method, value)
			if string.sub(tostring(method),1,1) == "_" then return self._nil end
			return self["_"..tostring(method).."_set"](value)
		end,
		__tostring = function(self)
			return string.format("Chat box '%s'", self.name)
		end,
		__pairs = function(self)
			local key, value = next(self)
			local cached_kv = nil
			cached_kv = key
			return function()
				key, value = next(self, cached_kv)
				local _key = nil
				while key and not self.__public_keys[key] do
					if type(key) == 'string' and (isGetter(key) or isSetter(key)) then
						_key = key
						key = cutGetSet(key)
						value = self[key]
					else
						key, value = next(self, _key or key)
						_key = nil
					end
				end
				cached_kv = _key or key
				return key, value
			end
		end
	})
	
	return ret
end
function isGetter(key)
	local a = string.find(key,"_")
	return string.match(key, "_[a-zA-Z0-9_]+_get") ~= nil
end
function isSetter(key)
	local a = string.find(key,"_")
	return string.match(key, "_[a-zA-Z0-9_]+_set") ~= nil
end
function cutGetSet(key)
	return string.sub(key, 2, #key-4)
end

function testDefaultPeripheral()
	if chat_util.DEFAULT_CHATBOX == nil then
		chat_util.DEFAULT_CHATBOX = chat_util:ChatBox()
	end
end

chat_util.msg = function(message, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	if username == nil or username == '' then
		chat_util.DEFAULT_CHATBOX.msg(message, prefix, brackets, bracketColor, range)
	else
		chat_util.DEFAULT_CHATBOX.msg2(message, username, prefix, brackets, bracketColor, range)
	end
end
chat_util.message = chat_util.msg
chat_util.toast = function(message, title, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	chat_util.DEFAULT_CHATBOX.toast(message, title, username, prefix, brackets, bracketColor, range)
end
chat_util.fmsg = function(json, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	if username == nil or username == '' then
		chat_util.DEFAULT_CHATBOX.fmsg(json, prefix, brackets, bracketColor, range)
	else
		chat_util.DEFAULT_CHATBOX.fmsg2(json, username, prefix, brackets, bracketColor, range)
	end
end
chat_util.jmsg = chat_util.fmsg
chat_util.ftoast = function(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	testDefaultPeripheral()
	chat_util.DEFAULT_CHATBOX.ftoast(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
end

return chat_util

