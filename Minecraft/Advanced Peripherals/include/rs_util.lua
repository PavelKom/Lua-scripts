--[[
	RS Bridge Utility library by PavelKom.
	Version: 0.9
	Wrapped RS Bridge
	https://advancedperipherals.netlify.app/peripherals/me_bridge/
	ToDo: Add manual
]]
getset = require 'getset_util'
local trigger = require 'trigger_util'
local expect = require "cc.expect"
local expect, field = expect.expect, expect.field

local lib = {}
lib.Trigger = trigger.Trigger
lib.CraftTask = trigger.CraftTask
lib.SIDES = getset.SIDES

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'RS Bridge')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		craftableItems = function() return self.object.listCraftableItems() end,
		craftableFluids = function() return self.object.listCraftableFluids() end, -- ME: listCraftableFluid
		items = function() return self.object.listItems() end,
		fluids = function() return self.object.listFluids() end, -- ME: listFluid
		
		energy = function() return self.object.getEnergyStorage() end,
		maxEnergy = function() return self.object.getMaxEnergyStorage() end,
		usageEnergy = function() return self.object.getEnergyUsage() end,
		
		iMaxDiskStorage = function() return self.object.getMaxItemDiskStorage() end, -- Only RS
		fMaxDiskStorage = function() return self.object.getMaxFluidDiskStorage() end, -- Only RS
		iMaxExtStorage = function() return self.object.getMaxItemExternalStorage() end, -- Only RS
		fMaxExtStorage = function() return self.object.getMaxFluidExternalStorage() end, -- Only RS
	}
	self.__getter.craftable = self.__getter.craftableItems
	self.__getter.craftables2 = self.__getter.craftableFluid
	self.__getter.itemStorage = self.__getter.iMaxDiskStorage
	self.__getter.fluidStorage = self.__getter.fMaxDiskStorage
	self.__getter.itemStorage2 = self.__getter.iMaxExtStorage
	self.__getter.fluidStorage2 = self.__getter.fMaxExtStorage
	
	self.__setter = {}
	
	-- Craft item
	self.craftItem = function(item, craftingCpu) -- As table
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.craftItem] item table without name and fingerprint")
		end
		return self.object.craftItem(item, craftingCpu)
	end
	self.craftItem2 = function(name, count, nbt, craftingCpu) -- By name
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.craftItem({name=name, count=count or 1, nbt=nbt}, craftingCpu)
	end
	self.craftItem3 = function(fingerprint, count, craftingCpu) -- By fingerprint
		expect(1, fingerprint, "string")
		return self.object.craftItem({fingerprint=fingerprint, count=count or 1}, craftingCpu)
	end
	
	-- Craft fluid
	self.craftFluid = function(fluid, craftingCpu)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.craftFluid] item table without name and fingerprint")
		end
		return self.object.craftFluid(fluid, craftingCpu)
	end
	self.craftFluid2 = function(name, count, nbt, craftingCpu)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.craftFluid({name=name, count=count or 1, nbt=nbt}, craftingCpu)
	end
	self.craftFluid3 = function(fingerprint, count, craftingCpu)
		expect(1, fingerprint, "string")
		return self.object.craftFluid({fingerprint=fingerprint, count=count or 1}, craftingCpu)
	end
	
	
	-- Get item
	self.getItem = function(item)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.getItem] item table without name and fingerprint")
		end
		return self.object.getItem(item)
	end
	self.getItem2 = function(name, nbt)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.getItem({name=name, nbt=nbt})
	end
	self.getItem3 = function(fingerprint)
		expect(1, fingerprint, "string")
		return self.object.getItem({fingerprint=fingerprint})
	end
	
	-- Import item
	self.importItem = function(item, direction)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.importItem] item table without name and fingerprint")
		end
		return self.object.importItem(item, lib.SIDES[direction])
	end
	self.importItem2 = function(name, nbt, count, direction)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.importItem({name=name, nbt=nbt, count=count or 1}, lib.SIDES[direction])
	end
	self.importItem3 = function(fingerprint, count, direction)
		expect(1, fingerprint, "string")
		return self.object.importItem({fingerprint=fingerprint, count=count or 1}, lib.SIDES[direction])
	end
	
	-- Export item
	self.exportItem = function(item, direction)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.exportItem] item table without name and fingerprint")
		end
		return self.object.exportItem(item, lib.SIDES[direction])
	end
	self.exportItem2 = function(name, nbt, count, direction)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.exportItem({name=name, nbt=nbt, count=count or 1}, lib.SIDES[direction])
	end
	self.exportItem3 = function(fingerprint, count, direction)
		expect(1, fingerprint, "string")
		return self.object.exportItem({fingerprint=fingerprint, count=count or 1}, lib.SIDES[direction])
	end
	
	-- Import from peripheral
	self.importItemFromPeripheral = function(item, container)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.importItemFromPeripheral] item table without name and fingerprint")
		end
		return self.object.importItemFromPeripheral(item, container)
	end
	self.importItemFromPeripheral2 = function(name, nbt, count, container)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.importItemFromPeripheral({name=name, nbt=nbt, count=count or 1}, container)
	end
	self.importItemFromPeripheral3 = function(fingerprint, count, container)
		expect(1, fingerprint, "string")
		return self.object.importItemFromPeripheral({fingerprint=fingerprint, count=count or 1}, container)
	end
	
	-- Export to peripheral
	self.exportItemToPeripheral = function(item, container)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.importItemFromPeripheral] item table without name and fingerprint")
		end
		return self.object.exportItemToPeripheral(item, container)
	end
	self.exportItemToPeripheral2 = function(name, nbt, count, container)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.exportItemToPeripheral({name=name, nbt=nbt, count=count or 1}, container)
	end
	self.exportItemToPeripheral3 = function(fingerprint, count, container)
		expect(1, fingerprint, "string")
		return self.object.exportItemToPeripheral({fingerprint=fingerprint, count=count or 1}, container)
	end
	
	-- Is item crafting?
	self.isItemCrafting = function(item, craftingCpu)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.isItemCrafting] item table without name and fingerprint")
		end
		return self.object.isItemCrafting(item, craftingCpu)
	end
	self.isItemCrafting2 = function(name, nbt, craftingCpu)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.isItemCrafting({name=name, nbt=nbt}, craftingCpu)
	end
	self.isItemCrafting3 = function(fingerprint, craftingCpu)
		expect(1, fingerprint, "string")
		return self.object.isItemCrafting({fingerprint=fingerprint}, craftingCpu)
	end
	
	-- Is item craftable?
	self.isItemCraftable = function(item, craftingCpu)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.isItemCraftable] item table without name and fingerprint")
		end
		return self.object.isItemCraftable(item, craftingCpu)
	end
	self.isItemCraftable2 = function(name, nbt, craftingCpu)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.isItemCraftable({name=name, nbt=nbt}, craftingCpu)
	end
	self.isItemCraftable3 = function(fingerprint, craftingCpu)
		expect(1, fingerprint, "string")
		return self.object.isItemCraftable({fingerprint=fingerprint}, craftingCpu)
	end
	
	-- Get crafting pattern
	self.getPattern = function(item, craftingCpu)
		if item.name == nil and item.fingerprint == nil then
			error("[RSBridge.isItemCraftable] item table without name and fingerprint")
		end
		return self.object.getPattern(item, craftingCpu)
	end
	self.getPattern2 = function(name, nbt, craftingCpu)
		expect(1, name, "string")
		expect(2, nbt, "string", "nil")
		return self.object.getPattern({name=name, nbt=nbt}, craftingCpu)
	end
	self.getPattern3 = function(fingerprint, craftingCpu)
		expect(1, fingerprint, "string")
		return self.object.getPattern({fingerprint=fingerprint}, craftingCpu)
	end
	
	-- Tasks
	self.tasks = {}
	-- Add task by name, nbt, fingerprint
	self.addRawTask = function(name, amount, fingerprint, nbt, batch, isFluid, triggers)
		local item = {name=name, fingerprint=fingerprint, nbt=nbt}
		self.tasks[#self.tasks+1] = lib.CraftTask(item, isFluid, amount, batch, trigger)
	end
	-- Add task by table
	self.addTask = function(task)
		expect(1, task, "CraftTask")
		self.tasks[#self.tasks+1] = task
	end
	self.eraseTask(name, nbt, fingerprint)
		if name then
			for i=#self.tasks, 0, -1 then
				if self.tasks[i].name == name then
					table.remove(self.tasks, i)
				end
			end
		end
		if nbt then
			for i=#self.tasks, 0, -1 then
				if self.tasks[i].nbt == nbt then
					table.remove(self.tasks, i)
				end
			end
		end
		if fingerprint then
			for i=#self.tasks, 0, -1 then
				if self.tasks[i].fingerprint == fingerprint then
					table.remove(self.tasks, i)
				end
			end
		end
	end
	self.clearTasks = function()
		while #self.tasks > 0 do
			table.remove(self.tasks)
		end
	end
	self.runTask = function(index, callback)
		if self.tasks[i] == nil then return -3 end
		return self.tasks[i].craft(self, callback)
	end
	self.runTasks = function(callback)
		for _, v in pairs(self.tasks) do
			v.craft(self, callback)
		end
	end
	self.loadTasksFromJson = function(tbl, clear)
		if clear then self.clearTasks() end
		if type(tbl) == 'string' then
			tbl = textutils.unserializeJSON(tbl)
		end
		for _, v in pairs(tbl) do
			self.tasks[#self.tasks+1] = lib.CraftTask.fromJson(v)
		end
	end
	self.saveTasksToJson = function()
		local tbl = {}
		for k, v in pairs(self.tasks) do
			tbl[k] = v.toJson()
		end
		return tbl
	end
	
	self.update = function()
		self.object = peripheral.wrap(self.name)
		if not self.object then error("Can't connect to RS Bridge '"..name.."'") end
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "RS Bridge",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.RSBridge=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="rsBridge",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="RSBridge",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
