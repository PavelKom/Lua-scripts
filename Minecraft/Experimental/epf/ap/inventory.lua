--[[
	Inventory Manager peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/inventory_manager/
]]
local epf = require 'epf'
--[[
	Pack data to ItemFilter. ntf - name/tag/fingerprint
]]
local function _pack_item(ntf, count, fromSlot, toSlot, nbt)
	local item = {count=count, fromSlot=fromSlot, toSlot=toSlot, nbt=nbt}
	if type(ntf) == 'string' then
		if tonumber(ntf,16) then item.fingerprint = ntf
		else item.name = ntf end
	elseif ntf ~= nil then
		error("Invalid item name/tag/fingerprint type")
	end
	return item
end

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Owner: %s", subtype(self), peripheral.getName(self), self.getOwner())
end
function Peripheral.__init(self)
	self.__getter = {
		armor = function() return self.getArmor() end,
		items = function() return self.getItems() end,
		owner = function() return self.getOwner() end,
		hand = function() return self.getItemInHand() end,
		hand2 = function() return self.getItemInOffHand() end,
		free = function() return self.getFreeSlot() end,
		space = function() return self.isSpaceAvailable() end,
		empty = function() return self.getEmptySpace() end
	}
	--1.19.x version
	--self.add = function(direction, count, toSlot, item) return self.addItemToPlayer(direction, count, toSlot, item) end
	self.add = function(direction, ntf, count, fromSlot, toSlot, nbt)
		-- Package into ItemFilter
		-- https://github.com/IntelligenceModding/AdvancedPeripherals/blob/release/1.20.1/src/main/java/de/srendi/advancedperipherals/common/util/inventory/ItemFilter.java
		if type(name) == 'table' then -- Already packed
			return self.addItemToPlayer(direction,name)
		else
			return self.addItemToPlayer(direction, _pack_item(ntf, count, fromSlot, toSlot, nbt)})
		end
	end
	self.addItem = self.add
	--1.19.x version
	--self.remove = function(direction, count, toSlot, item) return self.removeItemFromPlayer(direction, count, toSlot, item) end
	self.remove = function(direction, name, count, fromSlot, toSlot, fingerprint, tag, nbt, components)
		if type(name) == 'table' then -- Already packed
			return self.removeItemFromPlayer(direction,name)
		else
			return self.removeItemFromPlayer(direction, _pack_item(ntf, count, fromSlot, toSlot, nbt))
		end
	end
	self.removeItem = self.remove
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "inventoryManager", "Inventory Manager")

local lib = {}
lib.InventoryManager = Peripheral

function lib.help()
	local text = {
		"Inventory Manager library. Contains:\n",
		"InventoryManager",
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
	__subtype="InventoryManager",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Inventory Manager (Advanced Peripherals)"
	end,
})

return lib
