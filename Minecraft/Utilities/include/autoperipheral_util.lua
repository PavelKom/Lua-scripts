--[[
	Autoperipheral utility by PavelKom
	Version: 0.1
	Automatically wrap peripherals based on their name
]]

local getset = require "getset_util"
local expect = require "cc.expect"
local expect = expect.expect

local lib = {}

lib.libraries = {}
lib.peripherals = {}
lib.utilities = {}

-- Register libraries, peripherals and utilities
lib.load_libraries = function(path)
	local paths = fs.find(path)
	for _, p in pairs(paths) do
		local l = require(p)
		if type(l) == 'library' and lib.libraries[subtype(l)] == nil then
			for k, v in pairs(l) do
				if type(v) == 'peripheral' and lib.peripherals[k] == nil then
					lib.peripherals[subtype(v)] = v
				elseif type(v) == 'utility' and lib.utilities[k] == nil then
					lib.utilities[subtype(v)] = v
				end
			end
			lib.libraries[subtype(l)] = l
		end
	end
end
lib.reset_libraries = function()
	lib.libraries = {}
	lib.peripherals = {}
	lib.utilities = {}
end
lib.auto_wrap = function(name)
	expect(1, name, "string")
	if Inventory.test(name) == 0 then
		return Inventory(name)
	elseif FluidStorage.test(name) == 0 then
		return FluidStorage(name)
	elseif EnergyStorage.test(name) == 0 then
		return EnergyStorage(name)
	end
	local t = peripheral.getType(name)or error("Can't find peripheral with name '"..name.."'")
	if lib.peripherals[t] == nil then
		local p = lib.as_general(name)
		if not p then
			error("Can't find peripheral with type '"..t.."' and name '"..name.."'")
		end
		return p
	end
	return lib.peripherals[t](name)
end
lib.test_network = function()
	local names = peripheral.getNames()
	print("Start testing all peripherals in wired network")
	for _, name in pairs(names) do
		local res, err = pcall(lib.auto_wrap, name)
		print(name)
		if not res then
			print("ERROR: "..err)
		else
			print("TYPE: "..type(err))
		end
	end
	print("End of testing peripherals")
end

-- Inventory. Non-specific inventory, like minecraft:chest, minecraft:barrel and others
-- https://tweaked.cc/generic_peripheral/inventory.html
local Inventory = {}
Inventory.__items = {}
function Inventory:new(name)
	expect(1, name, "string")
	local test = Inventory.test(name)
	if test == -1 then
		error("Can't connect to Inventory '"..name.."'")
	elseif test > 0 then
		error("Peripheral '"..name.."' not Inventory")
	end
	if Inventory.__items[name] then
		return nil, Inventory.__items[name]
	end
	local object = peripheral.wrap(name)

	local self = {object=object, name=name, type=peripheral.getType(object)}
	
	self.__getter = {
		size = function() return self.object.size() end,
		list = function() return self.object.list() end,
	}
	self.__setter = {}
	self.getItemDetail = function(slot) return self.object.getItemDetail(slot) end
	self.getItemLimit = function(slot) return self.object.getItemLimit(slot) end
	self.pushItems = function(toName, fromSlot, limit, toSlot)
		if subtype(toName) == 'peripheral' then
			toName = toName.name
		end
		return self.object.pushItems(toName, fromSlot, limit, toSlot)
	end
	self.pullItems = function(fromName, fromSlot, limit, toSlot)
		if subtype(fromName) == 'peripheral' then
			fromName = fromName.name
		end
		return self.object.pullItems(fromName, fromSlot, limit, toSlot)
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Size: %i", type(self), self.name, self.size)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Inventory",
		__subtype = "peripheral",
	})
	Inventory.__items[self.name] = self
	if not Inventory.default then Inventory.default = self end
	return self
end
function Inventory.test(name)
	expect(1, name, "string")
	local m = peripheral.getMethods(name)
	if not m then return -1 end
	local n = table.copy(Inventory.__methods)
	local changed = true
	while changed do
		changed = false
		for i=#m, 1, -1 do
			for j=#n, 1, -1 do
				if m[i] == n[j] then
					table.remove(m,i)
					table.remove(n,j)
					changed = true
					break
				end
			end
		end
	end
	return math.max(#m, #n)
end
Inventory.__methods = {'size', 'list', 'getItemDetail', 'getItemLimit', 'pushItems', 'pullItems'}
lib.Inventory=setmetatable(Inventory,{__call=Inventory.new,__type = "peripheral",__subtype="inventory",})

-- Fluid Storage. Non-specific fluid storage
-- https://tweaked.cc/generic_peripheral/fluid_storage.html
local FluidStorage = {}
FluidStorage.__items = {}
function FluidStorage:new(name)
	expect(1, name, "string")
	local test = FluidStorage.test(name)
	if test == -1 then
		error("Can't connect to FluidStorage '"..name.."'")
	elseif test > 0 then
		error("Peripheral '"..name.."' not FluidStorage")
	end
	if FluidStorage.__items[name] then
		return nil, FluidStorage.__items[name]
	end
	local object = peripheral.wrap(name)

	local self = {object=object, name=name, type=peripheral.getType(object)}
	
	self.__getter = {
		tanks = function() return self.object.tanks() end,
	}
	self.__setter = {}
	self.pushFluid = function(toName, limit, fluidName)
		if subtype(toName) == 'peripheral' then
			toName = toName.name
		end
		return self.object.pushFluid(toName, limit, fluidName)
	end
	self.pullFluid = function(fromName, limit, fluidName)
		if subtype(fromName) == 'peripheral' then
			fromName = fromName.name
		end
		return self.object.pullFluid(fromName, limit, fluidName)
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "FluidStorage",
		__subtype = "peripheral",
	})
	FluidStorage.__items[self.name] = self
	if not FluidStorage.default then FluidStorage.default = self end
	return self
end
function FluidStorage.test(name)
	expect(1, name, "string")
	local m = peripheral.getMethods(name)
	if not m then return -1 end
	local n = table.copy(FluidStorage.__methods)
	local changed = true
	while changed do
		changed = false
		for i=#m, 1, -1 do
			for j=#n, 1, -1 do
				if m[i] == n[j] then
					table.remove(m,i)
					table.remove(n,j)
					changed = true
					break
				end
			end
		end
	end
	return math.max(#m, #n)
end
FluidStorage.__methods = {'tanks', 'pushFluid', 'pullFluid'}
lib.FluidStorage=setmetatable(FluidStorage,{__call=FluidStorage.new,__type = "peripheral",__subtype="fluid_storage",})

-- Energy Storage. Non-specific FE storage
-- https://tweaked.cc/generic_peripheral/energy_storage.html
local EnergyStorage = {}
EnergyStorage.__items = {}
function EnergyStorage:new(name)
	expect(1, name, "string")
	local test = EnergyStorage.test(name)
	if test == -1 then
		error("Can't connect to EnergyStorage '"..name.."'")
	elseif test > 0 then
		error("Peripheral '"..name.."' not EnergyStorage")
	end
	if EnergyStorage.__items[name] then
		return nil, EnergyStorage.__items[name]
	end
	local object = peripheral.wrap(name)

	local self = {object=object, name=name, type=peripheral.getType(object)}
	
	self.__getter = {
		energy = function() return self.object.getEnergy() end,
		capacity = function() return self.object.getEnergyCapacity() end,
	}
	self.__getter.cap = self.__getter.capacity
	self.__getter.max = self.__getter.capacity
	self.__setter = {}
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Energy %i/%i", type(self), self.name, self.energy, self.cap)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "EnergyStorage",
		__subtype = "peripheral",
	})
	EnergyStorage.__items[self.name] = self
	if not EnergyStorage.default then EnergyStorage.default = self end
	return self
end
function EnergyStorage.test(name)
	expect(1, name, "string")
	local m = peripheral.getMethods(name)
	if not m then return -1 end
	local n = table.copy(EnergyStorage.__methods)
	local changed = true
	while changed do
		changed = false
		for i=#m, 1, -1 do
			for j=#n, 1, -1 do
				if m[i] == n[j] then
					table.remove(m,i)
					table.remove(n,j)
					changed = true
					break
				end
			end
		end
	end
	return math.max(#m, #n)
end
EnergyStorage.__methods = {'getEnergy', 'getEnergyCapacity'}
lib.EnergyStorage=setmetatable(EnergyStorage,{__call=EnergyStorage.new,__type = "peripheral",__subtype="energy_storage",})









lib.load_libraries("*.lua")
lib.load_libraries("include/*.lua")
lib.load_libraries("lib/*.lua")
return lib
