--[[
	Player Detector Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Player Detector
	https://advancedperipherals.netlify.app/peripherals/player_detector/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}

-- Events
function lib.waitPlayerClickEvent()
	--event, username, device
	return os.pullEvent("playerClick")
end
function lib.waitPlayerClickEventEx(func)
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
		error('lib.waitChatEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerClick")})
	end
end

function lib.waitPlayerJoinvent()
	--event, username, dimension
	return os.pullEvent("playerJoin")
end
function lib.waitPlayerJoinEventEx(func)
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

function lib.waitPlayerLeaveEvent()
	--event, username, dimension
	return os.pullEvent("playerLeave")
end
function lib.waitPlayerLeaveEventEx(func)
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

function lib.waitPlayerChangedDimensionEvent()
	--event, username, fromDim, toDim
	return os.pullEvent("playerChangedDimension")
end
function lib.waitPlayerChangedDimensionEventEx(func)
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

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'playerDetector', 'Player Detector', Peripheral)
	if wrapped ~= nil then return wrapped end
	self.__getter = {
		online = function() return self.object.getOnlinePlayers() end
	}
	self.__setter = {}
	
	self.getOnlinePlayers = self.__getter.online
	self.getOnline = self.__getter.online
	
	self.getPlayerPos = function(username) return self.object.getPlayerPos(username) end
	self.playerPos = self.getPlayerPos
	self.player = self.getPlayerPos
	
	self.inRange = function(range) return self.object.getPlayersInRange(range) end
	
	self.inCords = function(posOne, posTwo) return self.object.getPlayersInCoords(posOne, posTwo) end
	self.inC.ords2 = function(x1,y1,z1, x2,y2,z2) return self.object.getPlayersInCoords({x=x1, y=y1, z=z1}, {x=x2, y=y2, z=z2}) end
	
	self.inCubic = function(whd) return self.object.getPlayersInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d) end
	self.inCubic2 = function(w, h, d) return self.object.getPlayersInCubic(w, h, d) end
	
	self.isInRange = function(range, username)
		if username ~= nil then
			return self.object.isPlayerInRange(range, username)
		else
			return self.object.isPlayersInRange(range)
		end
	end
	self.isInCords = function(posOne, posTwo, username)
		if username ~= nil then
			return self.object.isPlayerInRange(posOne, posTwo, username)
		else
			return self.object.isPlayersInCoords(posOne, posTwo)
		end
	end
	self.isInCords2 = function(x1,y1,z1, x2,y2,z2, username) return self.isInCords({x=x1, y=y1, z=z1}, {x=x2, y=y2, z=z2}, username) end
	
	self.isInCubic = function(whd, username)
		if username ~= nil then
			return self.object.isPlayerInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d, username)
		else
			return self.object.isPlayersInCubic(whd.x or whd.w, whd.y or whd.h, whd.z or whd.d)
		end
	end
	self.isInCubic2 = function(w, h, d, username) return self.isInCubic({w=w, h=h, d=d}, username) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", self.type, self.name, self.rate, self.limit)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	Peripheral.__items[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.PlayerDetector=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.getPlayerPos(username)
	testDefaultPeripheral()
	return Peripheral.default.playerPos(username)
end
function lib.online()
	testDefaultPeripheral()
	return Peripheral.default.online
end
function lib.inRange(range)
	testDefaultPeripheral()
	return Peripheral.default.inRange(range)
end
function lib.inCords(posOne, posTwo)
	testDefaultPeripheral()
	return Peripheral.default.inCords(posOne, posTwo)
end
function lib.inCords2(x1,y1,z1, x2,y2,z2)
	testDefaultPeripheral()
	return Peripheral.default.inCords2(x1,y1,z1, x2,y2,z2)
end
function lib.inCubic(whd)
	testDefaultPeripheral()
	return Peripheral.default.inCubic(whd)
end
function lib.inCubic2(w, h, d)
	testDefaultPeripheral()
	return Peripheral.default.inCubic2(w, h, d)
end
function lib.isInRange(range, username)
	testDefaultPeripheral()
	return Peripheral.default.isInRange(range, username)
end
function lib.isInCords(posOne, posTwo, username)
	testDefaultPeripheral()
	return Peripheral.default.isInCords(posOne, posTwo, username)
end
function lib.isInCords2(x1,y1,z1, x2,y2,z2, username)
	testDefaultPeripheral()
	return Peripheral.default.isInCords2(x1,y1,z1, x2,y2,z2, username)
end
function lib.isInCubic(whd, username)
	testDefaultPeripheral()
	return Peripheral.default.isInCubic(whd, username)
end
function lib.isInCubic2(w, h, d, username)
	testDefaultPeripheral()
	return Peripheral.default.isInCubic2(w, h, d, username)
end

return lib
