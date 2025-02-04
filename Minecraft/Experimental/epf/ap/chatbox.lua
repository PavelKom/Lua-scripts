--[[
	Chat Box peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/chat_box/
]]
local epf = require 'epf'

local Peripheral = {}
function Peripheral.__init(self)
	--[[
		Send message to player(s)
		@tparam string message Message string
		@tparam string|table|nil username Username, {Usernames} or nil to send to all
		@tparam[opt='AP'] string prefix Message prefix
		@tparam[opt='[]'] string brackets Prefix brackets '[]', '<>',...
		@tparam[opt=nil] string bracketColor Blit color name with '&' (Ex: &c - red)
		@tparam[opt=nil] number range Broadcast range
		@tparam[opt=false] boolean hidden Message is hidden (not show for players, but still run 'chat' event
		@treturn boolean|nil Message sended
		@treturn nil|string Error message
	]]
	self.msg = function(message, username, prefix, brackets, bracketColor, range, hidden)
		if hidden then message = "$"..message end
		if username == nil then
			return self.sendMessage(message, prefix, brackets, bracketColor, range)
		elseif type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.msg(message, v, prefix, brackets, bracketColor, range)
				if not res then error(string.format("[ChatBox.message] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.sendMessageToPlayer(message, username, prefix, brackets, bracketColor, range)
	end
	--[[
		Send toast to player(s).
		@tparam string message Message string
		@tparam string|table username Username, {Usernames}
		@tparam[opt='AP'] string prefix Message prefix
		@tparam[opt='[]'] string brackets Prefix brackets '[]', '<>',...
		@tparam[opt=nil] string bracketColor Blit color name with '&' (Ex: &c - red)
		@tparam[opt=nil] number range Broadcast range
		@treturn boolean|nil Toast sended
		@treturn nil|string Error message
	]]
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
		return self.sendToastToPlayer(message, title, username, prefix, brackets, bracketColor, range)
	end
	--[[
		Send formatted message to player(s). The message can be a table or a formatted JSON string.
		Json text generator:
		https://minecraft.tools/en/json_text.php?json=Welcome%20to%20Minecraft%20Tools
		@tparam string|table messageJson Json-string or table
		@tparam string|table|nil username Username, {Usernames} or nil to send to all
		@tparam[opt='AP'] string prefix Message prefix
		@tparam[opt='[]'] string brackets Prefix brackets '[]', '<>',...
		@tparam[opt=nil] string bracketColor Blit color name with '&' (Ex: &c - red)
		@tparam[opt=nil] number range Broadcast range
		@treturn boolean|nil Toast sended
		@treturn nil|string Error message
	]]
	self.fmsg = function(messageJson, username, prefix, brackets, bracketColor, range)
		if type(messageJson) == 'table' then
			messageJson = textutils.serialiseJSON(messageJson)
		end
		if username == nil then
			return self.sendFormattedMessage(messageJson, prefix, brackets, bracketColor, range)
		elseif type(username) == 'table' then
			local result = true
			for k, v in pairs(username) do
				local res, err = self.fmsg(messageJson, v, prefix, brackets, bracketColor, range)
				if not res then error(string.format("[ChatBox.fmsg] %s", err)) end
				result = result and res
			end
			return result
		end
		return self.sendFormattedMessageToPlayer(messageJson, username, prefix, brackets, bracketColor, range)
	end
	self.jmsg = self.fmsg
	self.fmessage = self.fmsg
	self.jmessage = self.fmsg
	--[[
		Send formatted toast to player(s). The message and tilte can be a table or a JSON formatted string.
		Json text generator:
		https://minecraft.tools/en/json_text.php?json=Welcome%20to%20Minecraft%20Tools
		@tparam string|table messageJson Json-string or table
		@tparam string|table titleJson Json-string or table
		@tparam string|table|nil username Username, {Usernames} or nil to send to all
		@tparam[opt='AP'] string prefix Message prefix
		@tparam[opt='[]'] string brackets Prefix brackets '[]', '<>',...
		@tparam[opt=nil] string bracketColor Blit color name with '&' (Ex: &c - red)
		@tparam[opt=nil] number range Broadcast range
		@treturn boolean|nil Toast sended
		@treturn nil|string Error message
	]]
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
		return self.sendFormattedToastToPlayer(messageJson, titleJson, username, prefix, brackets, bracketColor, range)
	end
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "chatBox", "Chat Box")

local lib = {}
lib.ChatBox = Peripheral

function lib.help()
	local text = {
		"Chat Box library. Contains:\n",
		"ChatBox",
		"([name]) - Peripheral wrapper\n",
	}
	local c = {
		colors.red,
	}
	if term.isColor() then
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		term.setBackgroundColor(colors.black)
		for i=1, #text do
			term.setTextColor(i % 2 == 1 and colors.white or c[i/2])
			term.write(text[i])
			if i % 2 == 1 then
				local x,y = term.getCursorPos()
				term.setCursorPos(1,y+1)
			end
		end
		term.setBackgroundColor(bg)
		term.setTextColor(fg)
	else
		print(table.concat(text))
	end
end

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="ChatBox",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Chat Box (Advanced Peripherals)"
	end,
})

return lib
