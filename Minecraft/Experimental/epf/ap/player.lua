--[[
	Player Detector peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/player_detector/
]]
local epf = require 'epf'
local Overload = require "epf.overload"
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local Peripheral = {}


-- Overloads for isPlayer(s)In(Range/Cubic/Coords)
function Peripheral.__isInRange_1(self, radius)
	return self.isPlayersInRange(radius)
end
function Peripheral.__isInRange_2(self, radius, username)
	return self.isPlayerInRange(radius, username)
end

function Peripheral.__isInCubic_1(self, pos)
	return self.isPlayersInCubic({
		w=pos.w or pos.x or pos[1],
		h=pos.h or pos.y or pos[2],
		d=pos.d or pos.z or pos[3],
	})
end
function Peripheral.__isInCubic_2(self, pos, username)
	return self.isPlayerInCubic(
	{
		w=pos.w or pos.x or pos[1],
		h=pos.h or pos.y or pos[2],
		d=pos.d or pos.z or pos[3],
	}, username)
end
function Peripheral.__isInCubic_1(self, w,h,d)
	return self.isPlayersInCubic({w=w,h=h,d=d})
end
function Peripheral.__isInCubic_2(self, w,h,d, username)
	return self.isPlayerInCubic({w=w,h=h,d=d}, username)
end

function Peripheral.__isInCoords_1(self, pos1, pos2)
	return self.isPlayersInCoords({
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	},{
		x=pos2.x or pos2[1],
		y=pos2.y or pos2[2],
		z=pos2.z or pos2[3],
	})
end
function Peripheral.__isInCoords_2(self, pos1, pos2, username)
	return self.isPlayerInCoords({
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	},{
		x=pos2.x or pos2[1],
		y=pos2.y or pos2[2],
		z=pos2.z or pos2[3],
	}, username)
end
function Peripheral.__isInCoords_3(self, pos1, pos2, isWHD)
	if not isWHD then return Peripheral.__isInCoords_1(self, pos1, pos2) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__isInCoords_1(self, a,{
		x=a.x+(pos2.x or pos2.w or pos2[1] or 0),
		y=a.y+(pos2.y or pos2.h or pos2[2] or 0),
		z=a.z+(pos2.z or pos2.d or pos2[3] or 0),
	})
end
function Peripheral.__isInCoords_4(self, pos1, pos2, isWHD, username)
	if not isWHD then return Peripheral.__isInCoords_2(self, pos1, pos2, username) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__isInCoords_2(self, a,{
		x=a.x+(pos2.x or pos2.w or pos2[1] or 0),
		y=a.y+(pos2.y or pos2.h or pos2[2] or 0),
		z=a.z+(pos2.z or pos2.d or pos2[3] or 0),
	}, username)
end
function Peripheral.__isInCoords_5(self, pos1, x2, y2, z2)
	return Peripheral.__isInCoords_1(self, pos1,{x=x2,y=y2,z=z2})
end
function Peripheral.__isInCoords_6(self, pos1, x2, y2, z2, username)
	return Peripheral.__isInCoords_2(self, pos1,{x=x2,y=y2,z=z2}, username)
end
function Peripheral.__isInCoords_7(self, pos1, x2, y2, z2, isWHD)
	if not isWHD then return Peripheral.__isInCoords_5(self, pos1, x2, y2, z2) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__isInCoords_1(self, a,{x=a.x+x2,y=a.y+y2,z=a.z+z2})
end
function Peripheral.__isInCoords_8(self, pos1, x2, y2, z2, isWHD, username)
	if not isWHD then return Peripheral.__isInCoords_6(self, pos1, x2, y2, z2, username) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__isInCoords_2(self, a,{x=a.x+x2,y=a.y+y2,z=a.z+z2}, username)
end
function Peripheral.__isInCoords_9(self, x1, x1, z1, x2, y2, z2)
	return Peripheral.__isInCoords_1(self, {x1, x1, z1}, {x2, y2, z2})
end
function Peripheral.__isInCoords_10(self, pos1, x2, y2, z2, username)
	return Peripheral.__isInCoords_2(self, {x1, x1, z1}, {x2, y2, z2}, username)
end
function Peripheral.__isInCoords_11(self, x1, x1, z1, x2, y2, z2, isWHD)
	return Peripheral.__isInCoords_3(self, {x1, x1, z1}, {x2, y2, z2}, isWHD)
end
function Peripheral.__isInCoords_12(self, pos1, x2, y2, z2, isWHD, username)
	return Peripheral.__isInCoords_4(self, {x1, x1, z1}, {x2, y2, z2}, isWHD, username)
end

local isIn = Overload()
Overload.reg(isIn, eripheral.__isInRange_1, {},0)
Overload.reg(isIn, eripheral.__isInRange_2, {},0,"")

Overload.reg(isIn, eripheral.__isInCubic_1, {},{})
Overload.reg(isIn, eripheral.__isInCubic_2, {},{},"")
Overload.reg(isIn, eripheral.__isInCubic_3, {},0,0,0)
Overload.reg(isIn, eripheral.__isInCubic_4, {},0,0,0,"")

Overload.reg(isIn, eripheral.__isInCoords_1, {},{},{})
Overload.reg(isIn, eripheral.__isInCoords_2, {},{},{},"")
Overload.reg(isIn, eripheral.__isInCoords_3, {},{},{},true)
Overload.reg(isIn, eripheral.__isInCoords_4, {},{},{},true,"")
Overload.reg(isIn, eripheral.__isInCoords_5, {},{},0,0,0)
Overload.reg(isIn, eripheral.__isInCoords_6, {},{},0,0,0,"")
Overload.reg(isIn, eripheral.__isInCoords_7, {},{},0,0,0,true)
Overload.reg(isIn, eripheral.__isInCoords_8, {},{},0,0,0,true,"")
Overload.reg(isIn, eripheral.__isInCoords_9, {},0,0,0,0,0,0)
Overload.reg(isIn, eripheral.__isInCoords_10, {},0,0,0,0,0,0,"")
Overload.reg(isIn, eripheral.__isInCoords_11, {},0,0,0,0,0,0,true)
Overload.reg(isIn, eripheral.__isInCoords_12, {},0,0,0,0,0,0,true,"")

-- Overloads for getPlayer(s)In(Range/Cubic/Coords)
function Peripheral.__getInRange_1(self, radius)
	return self.getPlayersInRange(radius)
end
function Peripheral.__getInRange_2(self, radius, username)
	return self.getPlayerInRange(radius, username)
end

function Peripheral.__getInCubic_1(self, pos)
	return self.getPlayersInCubic({
		w=pos.w or pos.x or pos[1],
		h=pos.h or pos.y or pos[2],
		d=pos.d or pos.z or pos[3],
	})
end
function Peripheral.__getInCubic_2(self, pos, username)
	return self.getPlayerInCubic(
	{
		w=pos.w or pos.x or pos[1],
		h=pos.h or pos.y or pos[2],
		d=pos.d or pos.z or pos[3],
	}, username)
end
function Peripheral.__getInCubic_1(self, w,h,d)
	return self.getPlayersInCubic({w=w,h=h,d=d})
end
function Peripheral.__getInCubic_2(self, w,h,d, username)
	return self.getPlayerInCubic({w=w,h=h,d=d}, username)
end

function Peripheral.__getInCoords_1(self, pos1, pos2)
	return self.getPlayersInCoords({
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	},{
		x=pos2.x or pos2[1],
		y=pos2.y or pos2[2],
		z=pos2.z or pos2[3],
	})
end
function Peripheral.__getInCoords_2(self, pos1, pos2, username)
	return self.getPlayerInCoords({
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	},{
		x=pos2.x or pos2[1],
		y=pos2.y or pos2[2],
		z=pos2.z or pos2[3],
	}, username)
end
function Peripheral.__getInCoords_3(self, pos1, pos2, getWHD)
	if not getWHD then return Peripheral.__getInCoords_1(self, pos1, pos2) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__getInCoords_1(self, a,{
		x=a.x+(pos2.x or pos2.w or pos2[1] or 0),
		y=a.y+(pos2.y or pos2.h or pos2[2] or 0),
		z=a.z+(pos2.z or pos2.d or pos2[3] or 0),
	})
end
function Peripheral.__getInCoords_4(self, pos1, pos2, getWHD, username)
	if not getWHD then return Peripheral.__getInCoords_2(self, pos1, pos2, username) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__getInCoords_2(self, a,{
		x=a.x+(pos2.x or pos2.w or pos2[1] or 0),
		y=a.y+(pos2.y or pos2.h or pos2[2] or 0),
		z=a.z+(pos2.z or pos2.d or pos2[3] or 0),
	}, username)
end
function Peripheral.__getInCoords_5(self, pos1, x2, y2, z2)
	return Peripheral.__getInCoords_1(self, pos1,{x=x2,y=y2,z=z2})
end
function Peripheral.__getInCoords_6(self, pos1, x2, y2, z2, username)
	return Peripheral.__getInCoords_2(self, pos1,{x=x2,y=y2,z=z2}, username)
end
function Peripheral.__getInCoords_7(self, pos1, x2, y2, z2, getWHD)
	if not getWHD then return Peripheral.__getInCoords_5(self, pos1, x2, y2, z2) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__getInCoords_1(self, a,{x=a.x+x2,y=a.y+y2,z=a.z+z2})
end
function Peripheral.__getInCoords_8(self, pos1, x2, y2, z2, getWHD, username)
	if not getWHD then return Peripheral.__getInCoords_6(self, pos1, x2, y2, z2, username) end
	local a = {
		x=pos1.x or pos1[1],
		y=pos1.y or pos1[2],
		z=pos1.z or pos1[3],
	}
	return Peripheral.__getInCoords_2(self, a,{x=a.x+x2,y=a.y+y2,z=a.z+z2}, username)
end
function Peripheral.__getInCoords_9(self, x1, x1, z1, x2, y2, z2)
	return Peripheral.__getInCoords_1(self, {x1, x1, z1}, {x2, y2, z2})
end
function Peripheral.__getInCoords_10(self, pos1, x2, y2, z2, username)
	return Peripheral.__getInCoords_2(self, {x1, x1, z1}, {x2, y2, z2}, username)
end
function Peripheral.__getInCoords_11(self, x1, x1, z1, x2, y2, z2, getWHD)
	return Peripheral.__getInCoords_3(self, {x1, x1, z1}, {x2, y2, z2}, getWHD)
end
function Peripheral.__getInCoords_12(self, pos1, x2, y2, z2, getWHD, username)
	return Peripheral.__getInCoords_4(self, {x1, x1, z1}, {x2, y2, z2}, getWHD, username)
end

local getIn = Overload()
Overload.reg(getIn, eripheral.__getInRange_1, {},0)
Overload.reg(getIn, eripheral.__getInRange_2, {},0,"")

Overload.reg(getIn, eripheral.__getInCubic_1, {},{})
Overload.reg(getIn, eripheral.__getInCubic_2, {},{},"")
Overload.reg(getIn, eripheral.__getInCubic_3, {},0,0,0)
Overload.reg(getIn, eripheral.__getInCubic_4, {},0,0,0,"")

Overload.reg(getIn, eripheral.__getInCoords_1, {},{},{})
Overload.reg(getIn, eripheral.__getInCoords_2, {},{},{},"")
Overload.reg(getIn, eripheral.__getInCoords_3, {},{},{},true)
Overload.reg(getIn, eripheral.__getInCoords_4, {},{},{},true,"")
Overload.reg(getIn, eripheral.__getInCoords_5, {},{},0,0,0)
Overload.reg(getIn, eripheral.__getInCoords_6, {},{},0,0,0,"")
Overload.reg(getIn, eripheral.__getInCoords_7, {},{},0,0,0,true)
Overload.reg(getIn, eripheral.__getInCoords_8, {},{},0,0,0,true,"")
Overload.reg(getIn, eripheral.__getInCoords_9, {},0,0,0,0,0,0)
Overload.reg(getIn, eripheral.__getInCoords_10, {},0,0,0,0,0,0,"")
Overload.reg(getIn, eripheral.__getInCoords_11, {},0,0,0,0,0,0,true)
Overload.reg(getIn, eripheral.__getInCoords_12, {},0,0,0,0,0,0,true,"")

function Peripheral.__init(self)
	self.__getter = {
		online = function() return self.getOnlinePlayers() end
	}
	self.getPos = self.getPlayerPos
	
	-- Overloaded functions
	self.isIn = function(...)
		return isIn(self, ...)
	end
	self.getIn = function(...)
		return getIn(self, ...)
	end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "playerDetector", "Player Detector")

local lib = {}
lib.PlayerDetector = Peripheral

function lib.help()
	local text = {
		"Player Detector library. Contains:\n",
		"PlayerDetector",
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
	__subtype="PlayerDetector",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Player Detector (Advanced Peripherals)"
	end,
})

return lib
