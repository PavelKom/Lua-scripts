--[[
	Player Detector Utility library by PavelKom.
	Version: 0.9
	Wrapped Player Detector
	https://advancedperipherals.netlify.app/peripherals/player_detector/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Events
function this_library.waitPlayerClickEvent()
	--event, username, device
	return os.pullEvent("playerClick")
end
function this_library.waitPlayerClickEventEx(func)
	--[[
	Create semi-infinite loop for playerClick event listener
	func - callback function. Must have arguments:
		table = {
			event,
			username,
			device
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('this_library.waitChatEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerClick")})
	end
end

function this_library.waitPlayerJoinvent()
	--event, username, dimension
	return os.pullEvent("playerJoin")
end
function this_library.waitPlayerJoinEventEx(func)
	--[[
	Create semi-infinite loop for playerJoin event listener
	func - callback function. Must have arguments:
		table = {
			event,
			username,
			dimension
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('player_util.waitPlayerJoinEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerJoin")})
	end
end

function this_library.waitPlayerLeaveEvent()
	--event, username, dimension
	return os.pullEvent("playerLeave")
end
function this_library.waitPlayerLeaveEventEx(func)
	--[[
	Create semi-infinite loop for playerLeave event listener
	func - callback function. Must have arguments:
		table = {
			event,
			username,
			dimension
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('player_util.waitPlayerLeaveEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerLeave")})
	end
end

function this_library.waitPlayerChangedDimensionEvent()
	--event, username, fromDim, toDim
	return os.pullEvent("playerChangedDimension")
end
function this_library.waitPlayerChangedDimensionEventEx(func)
	--[[
	Create semi-infinite loop for playerChangedDimension event listener
	func - callback function. Must have arguments:
		table = {
			event,
			username,
			fromDim,
			toDim
		}
		And return true. Else stop loop 
	]]
	if func == nil then
		error('player_util.waitPlayerChangedDimensionEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerChangedDimension")})
	end
end

-- Peripheral
function this_library:PlayerDetector(name)
	local def_type = 'playerDetector'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Player Detector '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		online = function() return ret.object.getOnlinePlayers() end
	}
	ret.__setter = {}
	
	ret.getOnlinePlayers = ret.__getter.online
	ret.getOnline = ret.__getter.online
	
	ret.getPlayerPos = function(username) return ret.object.getPlayerPos(username) end
	ret.playerPos = ret.getPlayerPos
	ret.player = ret.getPlayerPos
	
	ret.inRange = function(range) return ret.object.getPlayersInRange(range) end
	
	ret.inCords = function(posOne, posTwo) return ret.object.getPlayersInCoords(posOne, posTwo) end
	ret.inCords2 = function(x1,y1,z1, x2,y2,z2) return ret.object.getPlayersInCoords({x=x1, y=y1, z=z1}, {x=x2, y=y2, z=z2}) end
	
	ret.inCubic = function(whd) return ret.object.getPlayersInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d) end
	ret.inCubic2 = function(w, h, d) return ret.object.getPlayersInCubic(w, h, d) end
	
	ret.isInRange = function(range, username)
		if username ~= nil then
			return ret.object.isPlayerInRange(range, username)
		else
			return ret.object.isPlayersInRange(range)
		end
	end
	ret.isInCords = function(posOne, posTwo, username)
		if username ~= nil then
			return ret.object.isPlayerInRange(posOne, posTwo, username)
		else
			return ret.object.isPlayersInCoords(posOne, posTwo)
		end
	end
	ret.isInCords2 = function(x1,y1,z1, x2,y2,z2, username) return ret.isInCords({x=x1, y=y1, z=z1}, {x=x2, y=y2, z=z2}, username) end
	
	ret.isInCubic = function(whd, username)
		if username ~= nil then
			return ret.object.isPlayerInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d, username)
		else
			return ret.object.isPlayersInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d)
		end
	end
	ret.isInCubic2 = function(w, h, d, username) return ret.isInCubic({w=w, h=h, d=d}, username) end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Player Detector '%s'", self.name, self.rate, self.limit)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:PlayerDetector()
	end
end

function this_library.getPlayerPos(username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.playerPos(username)
end
function this_library.online()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.online
end
function this_library.inRange(range)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.inRange(range)
end
function this_library.inCords(posOne, posTwo)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.inCords(posOne, posTwo)
end
function this_library.inCords2(x1,y1,z1, x2,y2,z2)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.inCords2(x1,y1,z1, x2,y2,z2)
end
function this_library.inCubic(whd)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.inCubic(whd)
end
function this_library.inCubic2(w, h, d)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.inCubic2(w, h, d)
end
function this_library.isInRange(range, username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isInRange(range, username)
end
function this_library.isInCords(posOne, posTwo, username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isInCords(posOne, posTwo, username)
end
function this_library.isInCords2(x1,y1,z1, x2,y2,z2, username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isInCords2(x1,y1,z1, x2,y2,z2, username)
end
function this_library.isInCubic(whd, username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isInCubic(whd, username)
end
function this_library.isInCubic2(w, h, d, username)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isInCubic2(w, h, d, username)
end

return this_library
