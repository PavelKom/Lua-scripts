--[[
	AR Controller Utility library by PavelKom.
	Version: 0.9
	Wrapped AR Controller
	https://advancedperipherals.netlify.app/peripherals/ar_controller/
	Temporary unavaliable (AR Googles is disabled by mod creators)
]]
getset = require 'getset_util'

local this_library = {}
-- Align
this_library.ALIGN = {LEFT=0, CENTER=1, RIGHT=2, [0]=0,[1]=1,[2]=2}
setmetatable(this_library.ALIGN, {__index = function(self, index)
	if string.upper(index) == index then return self.LEFT end
	return self[string.upper(index)]
end})
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:ARController(name)
	local def_type = 'arController'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to AR Controller '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__ids = {}
	setmetatable(ret.__ids, {
		__call = function(self, arg)
			local result = {}
			for k, v in pairs(self) do
				if v == arg then result[k] = v end
			end
			return result
		end
	})
	ret.__getter = {}
	ret.__getter.ids = function()
		local result = {}
		for k, v in pairs(ret.__ids) do result[k] = v end
		return result
	end
	
	ret.clear = function(id)
		if id == nil then
			ret.object.clear()
		else
			ret.object.clearElement(id)
			ret.__ids[id] = nil
		end
	end
	ret.hLine = function(id, minX, maxX, y, color)
		if id == nil then
			ret.object.horizontalLine(minX, maxX, y, color)
		else
			ret.object.horizontalLineWithId(id, minX, maxX, y, color)
			ret.__ids[id] = 'hLine'
		end
	end
	ret.vLine = function(id, x, minY, maxY, color)
		if id == nil then
			ret.object.verticalLine(x, minY, maxY, color)
		else
			ret.object.verticalLineWithId(id, x, minY, maxY, color)
			ret.__ids[id] = 'vLine'
		end
	end
	-- NEED test
	ret.rect = function(id, minX, minY, maxX, maxY, color)
		if id == nil then
			ret.hLine(_,minX, maxX, minY, color)
			ret.hLine(_,minX, maxX, maxY, color)
			ret.vLine(_,minX, minY, maxY, color)
			ret.vLine(_,maxX, minY, maxY, color)
		else
			ret.hLine(id..'_A',minX, maxX, minY, color)
			ret.hLine(id..'_B',minX, maxX, maxY, color)
			ret.vLine(id..'_C',minX, minY, maxY, color)
			ret.vLine(id..'_D',maxX, minY, maxY, color)
			ret.__ids[id] = 'rect'
		end
	end
	ret.drawString = function(id, text, x, y, color, align)
		if id == nil then
			if this_library.ALIGN[align] == this_library.ALIGN.LEFT then
				ret.object.drawString(text, x, y, color)
			elseif this_library.ALIGN[align] == this_library.ALIGN.CENTER then
				ret.object.drawCenteredString(text, x, y, color)
			else
				ret.object.drawRightboundString(text, x, y, color)
			end
		else
			if this_library.ALIGN[align] == this_library.ALIGN.LEFT then
				ret.object.drawStringWithId(id, text, x, y, color)
				ret.__ids[id] = 'stringLeft'
			elseif this_library.ALIGN[align] == this_library.ALIGN.CENTER then
				ret.object.drawCenteredStringWithId(id, text, x, y, color)
				ret.__ids[id] = 'stringCenter'
			else
				ret.object.drawRightboundStringWithId(id, text, x, y, color)
				ret.__ids[id] = 'stringRight'
			end
		end
	end
	ret.drawIcon = function(id, itemId, x, y)
		if id == nil then
			ret.object.drawItemIcon(itemId, x, y)
		else
			ret.object.drawItemIconWithId(id, itemId, x, y)
		end
	end
	ret.drawCircle = function(id, x, y, radius, color)
		if id == nil then
			ret.object.drawCircle(x, y, radius, color)
		else
			ret.object.drawCircleWithId(id, x, y, radius, color)
		end
	end
	ret.fill = function(id, minX, minY, maxX, maxY, color)
		if id == nil then
			ret.object.fill(minX, minY, maxX, maxY, color)
		else
			ret.object.fillWithId(id, minX, minY, maxX, maxY, color)
		end
	end
	ret.fillCircle = function(id, x, y, radius, color)
		if id == nil then
			ret.object.fillCircle(x, y, radius, color)
		else
			ret.object.fillCircleWithId(id, x, y, radius, color)
		end
	end
	ret.fillGradient = function(id, minX, minY, maxX, maxY, colorFrom, colorTo)
		if id == nil then
			ret.object.fillGradient(minX, minY, maxX, maxY, colorFrom, colorTo)
		else
			ret.object.fillGradientWithId(id, minX, minY, maxX, maxY, colorFrom, colorTo)
		end
	end
	ret.isRelative = function()
		return ret.object.isRelativeMode()
	end
	ret.setRelative = function(enabled,virtualScreenWidth,virtualScreenHeight)
		return ret.object.setRelativeMode(enabled, virtualScreenWidth, virtualScreenHeight)
	end
	
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getseta.IPAIRS,
		__tostring = function(self)
			local rel = self.isRelative
			return string.format("AR Controller '%s' RelativeMode: %s", self.name, tostring(rel))
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:ARController()
	end
end

function this_library.clear(id)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.clear(id)
end
function this_library.hLine(id, minX, maxX, y, color)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.hLine(id, minX, maxX, y, color)
end
function this_library.vLine(id, x, minY, maxY, color)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.vLine(id, x, minY, maxY, color)
end
function this_library.drawString(id, text, x, y, color, align)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.drawString(id, text, x, y, color, align)
end
function this_library.drawIcon(id, itemId, x, y)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.drawIcon(id, itemId, x, y)
end
function this_library.drawCircle(id, x, y, radius, color)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.drawCircle(id, x, y, radius, color)
end
function this_library.fill(id, minX, minY, maxX, maxY, color)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.fill(id, minX, minY, maxX, maxY, color)
end
function this_library.fillCircle(id, x, y, radius, color)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.fillCircle(id, x, y, radius, color)
end
function this_library.fillGradient(id, minX, minY, maxX, maxY, colorFrom, colorTo)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.fillGradient(id, minX, minY, maxX, maxY, colorFrom, colorTo)
end
function this_library.isRelative()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isRelative()
end
function this_library.setRelative(enabled,virtualScreenWidth,virtualScreenHeight)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.setRelative(enabled,virtualScreenWidth,virtualScreenHeight)
end


return this_library
