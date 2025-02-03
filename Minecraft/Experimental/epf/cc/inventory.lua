--[[
	Inventory peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/generic_peripheral/inventory.html
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Slots: %i", subtype(self), peripheral.getName(self), self.size)
end
function Peripheral.__init(self)
	self.getSize = self.size
	self.size = nil
	self.getList = self.list
	self.list = nil
	self.__getter = {
		size = function() return self.getSize() end,
		list = function() return self.getList() end,
	}
	self.push = self.pushItems
	self.pull = self.pullItems
	self.detail = self.getItemDetail
	self.limit = self.getItemLimit
	
	return self
end
local function _ipairs(self)
	local items = self.list
	local key, value
	return function()
		key, value = next(items, key)
		if key == nil then return nil, nil end
		return key, value
	end
end
local function _len(self)
	return self.size
end
function Peripheral.__init_post(self)
	local _m = getmetatable(self)
	_m._ipairs = _ipairs
	return self
end

Peripheral = epf.wrapperFixer(Peripheral, "inventory", "Inventory")

local lib = {}
lib.Inventory = Peripheral

function lib.help()
	local text = {
		"Inventory library. Contains:\n",
		"Inventory",
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
	__subtype="Inventory",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Inventory (CC:Tweaked)"
	end,
})

return lib
