--[[
	Inventory Manager Utility library by PavelKom.
	Version: 0.9
	Wrapped Inventory Manager
	https://advancedperipherals.netlify.app/peripherals/inventory_manager/
	ToDo: Add manual
]]

local this_library = {}
-- Sides and cardinal directions
this_library.SIDES = {'right''left','front','back','top','bottom',}
this_library.CARDINAL = {'north','south','east','west','up','down',}
this_library.SLOTS = {BOOTS=100, LEGGINGS=101, CHESTPLATE=102, HELMET=103}

-- add .RIGHT, .NORTH, ... and .SIDES.RIGHT .CARDINAL.NORTH, ...
for k,v in ipairs(this_library.SIDES) do
	this_library[string.upper(v)] = v
	this_library.SIDES[string.upper(v)] = v
end
for k,v in ipairs(this_library.CARDINAL) do
	this_library[string.upper(v)] = v
	this_library.CARDINAL[string.upper(v)] = v
end

this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:InventoryManager(name)
	name = name or 'inventoryManager'
	local ret = {object = peripheral.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Inventory Manager '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	
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
	
	ret.addItemToPlayer = function(direction, item) return ret.object.addItemToPlayer(direction, item) end
	ret.addItem = ret.addItemToPlayer
	ret.add = ret.addItemToPlayer
	
	ret.removeItemFromPlayer = function(direction, item) return ret.object.removeItemFromPlayer(direction, item) end
	ret.removeItem = ret.removeItemFromPlayer
	ret.remove = ret.removeItemFromPlayer
	
	ret.isWearing = function(slot)
		if slot == nil then
			return ret.object.isPlayerEquipped()
		else
			return ret.object.isWearing(slot)
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
