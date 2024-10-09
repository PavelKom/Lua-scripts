--[[
	Inventory Manager Utility library by PavelKom.
	Version: 0.9
	Wrapped Inventory Manager
	https://advancedperipherals.netlify.app/peripherals/inventory_manager/
	ToDo: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.SIDES = getset.SIDES

this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:InventoryManager(name)
	local def_type = 'inventoryManager'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Inventory Manager '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		armor = function() return ret.object.getArmor() end,
		items = function() return ret.object.getItems() end,
		owner = function() return ret.object.getOwner() end,
		hand = function() return ret.object.getItemInHand() end,
		hand2 = function() return ret.object.getItemInOffHand() end,
		free = function() return ret.object.getFreeSlot() end,
		space = function() return ret.object.isSpaceAvailable() end,
		empty = function() return ret.object.getEmptySpace() end
	}
	ret.__setter = {}
	
	ret.addItemToPlayer = function(direction, count, toSlot, item) return ret.object.addItemToPlayer(direction, count, toSlot, item) end
	ret.addItem = ret.addItemToPlayer
	ret.add = ret.addItemToPlayer
	
	ret.removeItemFromPlayer = function(direction, count, toSlot, item) return ret.object.removeItemFromPlayer(direction, count, toSlot, item) end
	ret.removeItem = ret.removeItemFromPlayer
	ret.remove = ret.removeItemFromPlayer
	
	ret.isWearing = function(slot)
		if slot == nil then
			return ret.object.isPlayerEquipped()
		else
			return ret.object.isWearing(slot) -- Always return false ???
		end
	end
	ret.__getter.offHand = ret.__getter.hand2
	ret.getHand = function(offHand)
		if offHand then return ret.hand2 end
		return ret.hand
	end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Inventory Manager '%s' Owner: %i", self.name, self.owner)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:InventoryManager()
	end
end

function this_library.addItem(direction, item)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.addItem(direction, item)
end
function this_library.removeItem(direction, item)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.removeItem(direction, item)
end
function this_library.getArmor()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.armor
end
function this_library.getItems()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.items
end
function this_library.getOwner()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.owner
end
function this_library.isWearing(slot)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isWearing(slot)
end
function this_library.getHand(secondary)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getHand(secondary)
end
function this_library.getFreeSlot()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getFreeSlot()
end
function this_library.isSpaceAvailable()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isSpaceAvailable()
end
function this_library.getEmptySpace()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.getEmptySpace()
end


return this_library
