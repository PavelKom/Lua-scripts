--[[
	Player Detector Utility library by PavelKom.
	Version: 0.1
	Wrapped Environment Detector
	https://advancedperipherals.netlify.app/peripherals/player_detector/
]]

local player_util = {}
player_util.DEFAULT_PLAYER_DETECTOR = nil

function player_util.waitPlayerClickEvent()
	--event, username, device
	return os.pullEvent("playerClick")
end
function player_util.waitPlayerClickEventEx(func)
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
		error('player_util.waitChatEventEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("playerClick")})
	end
end

function player_util.waitPlayerJoinvent()
	--event, username, dimension
	return os.pullEvent("playerJoin")
end
function player_util.waitPlayerJoinEventEx(func)
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

function player_util.waitPlayerLeaveEvent()
	--event, username, dimension
	return os.pullEvent("playerLeave")
end
function player_util.waitPlayerLeaveEventEx(func)
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

function player_util.waitPlayerChangedDimensionEvent()
	--event, username, fromDim, toDim
	return os.pullEvent("playerChangedDimension")
end
function player_util.waitPlayerChangedDimensionEventEx(func)
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


function player_util:EnvironmentDetector(name)
	name = name or 'playerDetector'
	local ret = {object = peripherals.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Player Detector '"..name.."'") end
	ret.name = name
	
	ret.playerPos = function(username) return ret.object.getPlayerPos(username) end
	ret.player = ret.playerPos
	ret._online_get = function() return ret.object.getOnlinePlayers() end
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
	
	ret.__public_keys = {name=true,
		playerPos=true, player=true,
	    online=true,
	    inRange=true,
	    inCords=true, inCords2=true,
	    inCubic=true, inCubic2=true,
	    isInRange=true,
	    isInCords=true, isInCords2=true,
	    isInCubic=true, isInCubic2=true,
		}
	
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
			return string.format("Energy Detector '%s' Rate: %i Limit: %i", self.name, self.rate, self.limit)
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
	if player_util.DEFAULT_PLAYER_DETECTOR == nil then
		player_util.DEFAULT_PLAYER_DETECTOR = player_util:EnvironmentDetector()
	end
end

function player_util.getPlayerPos(username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.playerPos(username)
end
function player_util.online()
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.
end
function player_util.inRange(range)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.inRange(range)
end
function player_util.inCords(posOne, posTwo)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.inCords(posOne, posTwo)
end
function player_util.inCords2(x1,y1,z1, x2,y2,z2)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.inCords2(x1,y1,z1, x2,y2,z2)
end
function player_util.inCubic(whd)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.inCubic(whd)
end
function player_util.inCubic2(w, h, d)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.inCubic2(w, h, d)
end
function player_util.isInRange(range, username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.isInRange(range, username)
end
function player_util.isInCords(posOne, posTwo, username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.isInCords(posOne, posTwo, username)
end
function player_util.isInCords2(x1,y1,z1, x2,y2,z2, username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.isInCords2(x1,y1,z1, x2,y2,z2, username)
end
function player_util.isInCubic(whd, username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.isInCubic(whd, username)
end
function player_util.isInCubic2(w, h, d, username)
	testDefaultPeripheral()
	return player_util.DEFAULT_PLAYER_DETECTOR.isInCubic2(w, h, d, username)
end

return player_util
