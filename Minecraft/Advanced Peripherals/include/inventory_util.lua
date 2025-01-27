--[[
	Inventory Manager Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Inventory Manager
	https://advancedperipherals.netlify.app/peripherals/inventory_manager/
	ToDo: Add manual
]]
getset = require 'getset_util'
local lib = {}
lib.SIDES = getset.SIDES

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'inventoryManager', 'Inventory Manager', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		armor = function() return self.object.getArmor() end,
		items = function() return self.object.getItems() end,
		owner = function() return self.object.getOwner() end,
		hand = function() return self.object.getItemInHand() end,
		hand2 = function() return self.object.getItemInOffHand() end,
		free = function() return self.object.getFreeSlot() end,
		space = function() return self.object.isSpaceAvailable() end,
		empty = function() return self.object.getEmptySpace() end
	}
	self.__setter = {}
	
	--1.92.x version
	--self.addItemToPlayer = function(direction, count, toSlot, item) return self.object.addItemToPlayer(direction, count, toSlot, item) end
	self.addItemToPlayer = function(direction, name, fromSlot, toSlot, count, fingerprint, tag, nbt, components)
		return self.object.addItemToPlayer(direction, {
			name=name, -- Item name like 'minecraft:cobbleston', '#wood' or nil
			components=components, tag=tag, nbt=nbt,
			fingerprint=fingerprint,
			fromSlot=fromSlot,
			toSlot=toSlot,
			count=count})
	end
	self.addItem = self.addItemToPlayer
	self.add = self.addItemToPlayer
	self.addItemToPlayer2 = function(direction, item)
		return self.object.addItemToPlayer(direction, item)
	end
	self.addItem2 = self.addItemToPlayer2
	self.add2 = self.addItemToPlayer2
	
	--1.92.x version
	--self.removeItemFromPlayer = function(direction, count, toSlot, item) return self.object.removeItemFromPlayer(direction, count, toSlot, item) end
	self.removeItemFromPlayer = function(direction, name, fromSlot, toSlot, count, fingerprint, tag, nbt, components)
		return self.object.removeItemFromPlayer(direction, {
			name=name, -- Item name like 'minecraft:cobbleston', '#wood' or nil
			components=components, tag=tag, nbt=nbt,
			fingerprint=fingerprint,
			fromSlot=fromSlot,
			toSlot=toSlot,
			count=count})
	end
	self.removeItem = self.removeItemFromPlayer
	self.remove = self.removeItemFromPlayer
	self.removeItemFromPlayer2 = function(direction, item)
		return self.object.removeItemFromPlayer(direction, item)
	end
	self.removeItem2 = self.removeItemFromPlayer2
	self.remove2 = self.removeItemFromPlayer2
	
	self.isWearing = function(slot)
		if slot == nil then
			return self.object.isPlayerEquipped()
		else
			return self.object.isWearing(slot) -- Always return false ???
		end
	end
	self.__getter.offHand = self.__getter.hand2
	self.getHand = function(offHand)
		if offHand then return self.hand2 end
		return self.hand
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Owner: %s", self.type, self.name, self.owner)
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
lib.InventoryManager=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if Peripheral.default == nil then
		Peripheral()
	end
end

function lib.addItem(direction, name, fromSlot, toSlot, count, components, fingerprint)
	testDefaultPeripheral()
	return Peripheral.default.addItem(direction, name, fromSlot, toSlot, count, components, fingerprint)
end
function lib.removeItem(direction, name, fromSlot, toSlot, count, components, fingerprint)
	testDefaultPeripheral()
	return Peripheral.default.removeItem(direction, name, fromSlot, toSlot, count, components, fingerprint)
end
function lib.getArmor()
	testDefaultPeripheral()
	return Peripheral.default.armor
end
function lib.getItems()
	testDefaultPeripheral()
	return Peripheral.default.items
end
function lib.getOwner()
	testDefaultPeripheral()
	return Peripheral.default.owner
end
function lib.isWearing(slot)
	testDefaultPeripheral()
	return Peripheral.default.isWearing(slot)
end
function lib.getHand(secondary)
	testDefaultPeripheral()
	return Peripheral.default.getHand(secondary)
end
function lib.getFreeSlot()
	testDefaultPeripheral()
	return Peripheral.default.getFreeSlot()
end
function lib.isSpaceAvailable()
	testDefaultPeripheral()
	return Peripheral.default.isSpaceAvailable()
end
function lib.getEmptySpace()
	testDefaultPeripheral()
	return Peripheral.default.getEmptySpace()
end


return lib
