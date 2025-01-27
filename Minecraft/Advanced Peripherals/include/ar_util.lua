--[[
	AR Controller Utility library by PavelKom.
	Version: 0.9.5
	Wrapped AR Controller
	https://advancedperipherals.netlify.app/peripherals/ar_controller/
	Temporary unavaliable (AR Googles is disabled by mod creators)
]]
getset = require 'getset_util'

local lib = {}
-- Align
lib.ALIGN = {LEFT=0, CENTER=1, RIGHT=2, [0]=0,[1]=1,[2]=2}
setmetatable(lib.ALIGN, {__index = lib.GETTER_TO_UPPER(lib.ALIGN.LEFT)})

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'arController', 'ARController', Peripheral)
	if wrapped ~= nil then return wrapped end
	self.__ids = {}
	setmetatable(self.__ids, {
		__call = function(self, arg)
			local result = {}
			for k, v in pairs(self) do
				if v == arg then result[k] = v end
			end
			return result
		end
	})
	self.__getter = {
		ids = function()
			local result = {}
			for k, v in pairs(self.__ids) do result[k] = v end
			return result
		end,
	}
	
	self.clear = function(id)
		if id == nil then
			self.object.clear()
		else
			self.object.clearElement(id)
			self.__ids[id] = nil
		end
	end
	self.hLine = function(id, minX, maxX, y, color)
		if id == nil then
			self.object.horizontalLine(minX, maxX, y, color)
		else
			self.object.horizontalLineWithId(id, minX, maxX, y, color)
			self.__ids[id] = 'hLine'
		end
	end
	self.vLine = function(id, x, minY, maxY, color)
		if id == nil then
			self.object.verticalLine(x, minY, maxY, color)
		else
			self.object.verticalLineWithId(id, x, minY, maxY, color)
			self.__ids[id] = 'vLine'
		end
	end
	-- NEED test
	self.rect = function(id, minX, minY, maxX, maxY, color)
		if id == nil then
			self.hLine(_,minX, maxX, minY, color)
			self.hLine(_,minX, maxX, maxY, color)
			self.vLine(_,minX, minY, maxY, color)
			self.vLine(_,maxX, minY, maxY, color)
		else
			self.hLine(id..'_A',minX, maxX, minY, color)
			self.hLine(id..'_B',minX, maxX, maxY, color)
			self.vLine(id..'_C',minX, minY, maxY, color)
			self.vLine(id..'_D',maxX, minY, maxY, color)
			self.__ids[id] = 'rect'
		end
	end
	self.drawString = function(id, text, x, y, color, align)
		if id == nil then
			if lib.ALIGN[align] == lib.ALIGN.LEFT then
				self.object.drawString(text, x, y, color)
			elseif lib.ALIGN[align] == lib.ALIGN.CENTER then
				self.object.drawCenteredString(text, x, y, color)
			else
				self.object.drawRightboundString(text, x, y, color)
			end
		else
			if lib.ALIGN[align] == lib.ALIGN.LEFT then
				self.object.drawStringWithId(id, text, x, y, color)
				self.__ids[id] = 'stringLeft'
			elseif lib.ALIGN[align] == lib.ALIGN.CENTER then
				self.object.drawCenteredStringWithId(id, text, x, y, color)
				self.__ids[id] = 'stringCenter'
			else
				self.object.drawRightboundStringWithId(id, text, x, y, color)
				self.__ids[id] = 'stringRight'
			end
		end
	end
	self.drawIcon = function(id, itemId, x, y)
		if id == nil then
			self.object.drawItemIcon(itemId, x, y)
		else
			self.object.drawItemIconWithId(id, itemId, x, y)
		end
	end
	self.drawCircle = function(id, x, y, radius, color)
		if id == nil then
			self.object.drawCircle(x, y, radius, color)
		else
			self.object.drawCircleWithId(id, x, y, radius, color)
		end
	end
	self.fill = function(id, minX, minY, maxX, maxY, color)
		if id == nil then
			self.object.fill(minX, minY, maxX, maxY, color)
		else
			self.object.fillWithId(id, minX, minY, maxX, maxY, color)
		end
	end
	self.fillCircle = function(id, x, y, radius, color)
		if id == nil then
			self.object.fillCircle(x, y, radius, color)
		else
			self.object.fillCircleWithId(id, x, y, radius, color)
		end
	end
	self.fillGradient = function(id, minX, minY, maxX, maxY, colorFrom, colorTo)
		if id == nil then
			self.object.fillGradient(minX, minY, maxX, maxY, colorFrom, colorTo)
		else
			self.object.fillGradientWithId(id, minX, minY, maxX, maxY, colorFrom, colorTo)
		end
	end
	self.isRelative = function()
		return self.object.isRelativeMode()
	end
	self.setRelative = function(enabled,virtualScreenWidth,virtualScreenHeight)
		return self.object.setRelativeMode(enabled, virtualScreenWidth, virtualScreenHeight)
	end
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getseta.IPAIRS,
		__tostring = function(self)
			local rel = self.isRelative
			return string.format("%s '%s' RelativeMode: %s", self.type, self.name, tostring(rel))
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
lib.ARController=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.clear(id)
	testDefaultPeripheral()
	return Peripheral.default.clear(id)
end
function lib.hLine(id, minX, maxX, y, color)
	testDefaultPeripheral()
	return Peripheral.default.hLine(id, minX, maxX, y, color)
end
function lib.vLine(id, x, minY, maxY, color)
	testDefaultPeripheral()
	return Peripheral.default.vLine(id, x, minY, maxY, color)
end
function lib.drawString(id, text, x, y, color, align)
	testDefaultPeripheral()
	return Peripheral.default.drawString(id, text, x, y, color, align)
end
function lib.drawIcon(id, itemId, x, y)
	testDefaultPeripheral()
	return Peripheral.default.drawIcon(id, itemId, x, y)
end
function lib.drawCircle(id, x, y, radius, color)
	testDefaultPeripheral()
	return Peripheral.default.drawCircle(id, x, y, radius, color)
end
function lib.fill(id, minX, minY, maxX, maxY, color)
	testDefaultPeripheral()
	return Peripheral.default.fill(id, minX, minY, maxX, maxY, color)
end
function lib.fillCircle(id, x, y, radius, color)
	testDefaultPeripheral()
	return Peripheral.default.fillCircle(id, x, y, radius, color)
end
function lib.fillGradient(id, minX, minY, maxX, maxY, colorFrom, colorTo)
	testDefaultPeripheral()
	return Peripheral.default.fillGradient(id, minX, minY, maxX, maxY, colorFrom, colorTo)
end
function lib.isRelative()
	testDefaultPeripheral()
	return Peripheral.default.isRelative()
end
function lib.setRelative(enabled,virtualScreenWidth,virtualScreenHeight)
	testDefaultPeripheral()
	return Peripheral.default.setRelative(enabled,virtualScreenWidth,virtualScreenHeight)
end


return lib
