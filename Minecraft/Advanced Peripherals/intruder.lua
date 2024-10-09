--[[
	Intruder Alert! A RED Spy is in the base!
]]
require "include/patches"

chat_util = require "include/chat_util"
chatlib = require "include/player_util"

local chatbox = chat_util:ChatBox()
local detector = chatlib:PlayerDetector()
local delay = 10
local intruder_toast = true
local current_visitors = {}

local owners = {"<YourName>", "<YourBestFriend>"} -- Вы и остальные жители дома/базы
local friends = {"<friend1>","<friend2>",} -- Игроки, с которыми вы в хороших отношениях
local enemies = {"<enemy1>","<enemy2>",} -- Игроки, с которыми вы враждуете
local neutrals = {"<neutral1>","<neutral2>",} -- Остальные игроки, можно не указывать

-- Зона сканирования
local basePointA = {x=0,y=0,z=0}
local basePointB = {x=0,y=0,z=0}

function isOwner(player)
	for _,v in pairs(owners) do
		if v == player then return true end
	end
	return false
end
function isFriend(player)
	for _,v in pairs(friends) do
		if v == player then return true end
	end
	return false
end
function isEnemy(player)
	for _,v in pairs(enemies) do
		if v == player then return true end
	end
	return false
end
function isNeutral(player)
	for _,v in pairs(neutrals) do
		if v == player then return true end
	end
	return not (isOwner(player) or isFriend(player) or isEnemy(player))
end

function getOwnerMessage(player)
	return {
		{text = "[MSG] ", color = "blue"},
		{text = "Welcome back "},
		{text = player, color = "green"}
	}
end
function getFriendMessage(player)
	return {
		{text = "[MSG] ", color = "blue"},
		{text = "Welcome "},
		{text = player, color = "aqua"}
	}
end
function getFriendMessage2(player)
	return {
		{text = "[MSG] ", color = "blue"},
		{text = player, color = "aqua"},
		{text = " on base. Say hello to him/her."},
	}
end
function getIntruderMessage(player)
	return {
		{text = "[MSG] ", color = "blue"},
		{text = "WARNING! Intruder alert! "},
		{text = player, color = "red", bold = true},
		{text = " on base!"}
	}
end

while true do
	local players = detector.inCords(basePointA,basePointB)
	for _, player in pairs(players) do
		if not current_visitors[player] then
			current_visitors[player] = true
			if isEnemy(player) then
				local msg = getIntruderMessage(player)
				for _, owner in pairs(owners) do
					if intruder_toast then
						chatbox.ftoast(msg, {text="WARNING", color="red"}, owner)
					else
						chatbox.fmsg(msg, owner)
					end
				end
			elseif isOwner(player) then
				chatbox.fmsg(getOwnerMessage(player), player)
			else
				chatbox.fmsg(getOwnerMessage(player), player)
				local msg = getFriendMessage2(player)
				for _, owner in pairs(owners) do
					if detector.isInCords(basePointA,basePointB, owner) then
						chatbox.fmsg(msg, owner)
					end
				end	
			end
		end
	end
	sleep(delay)
end




