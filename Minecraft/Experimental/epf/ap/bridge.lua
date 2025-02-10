--[[
	ME and RS Bridge peripheral wrappers
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/me_bridge/
	https://advancedperipherals.netlify.app/peripherals/rs_bridge/
]]
local epf = require 'epf'
local expect = require "cc.expect"
local expect = expect.expect
local _task = require "epf.ap.trigger"
local Task, Trigger, TriggerGroup = _task.Task, _task.Trigger, _task.TriggerGroup


local function _parse(ntf)
	if type(ntf) == 'table' then return ntf end
	local item = {}
	if type(ntf) == 'string' then
		if tonumber(ntf,16) then item.fingerprint = ntf
		else item.name = ntf end
	elseif ntf ~= nil then
		error("Invalid item name/tag/fingerprint type")
	end
	return item
end

local MEBridge = {}
function MEBridge.__init(self)
	self.__getter = {
		craftableItems = function() return self.listCraftableItems() end,
		craftableFluids = function() return self.listCraftableFluid() end, -- RS: listCraftableFluids
		
		items = function() return self.listItems() end,
		fluids = function() return self.listFluid() end, -- RS: listFluids
		gases = function() return self.listGas() end, -- Only ME
		cells = function() return self.listCells() end, -- Only ME
		
		totalItems = function() return self.getTotalItemStorage() end, -- Only ME
		totalFluids = function() return self.getTotalFluidStorage() end, -- Only ME
		usedItems = function() return self.getUsedItemStorage() end, -- Only ME
		usedFluids = function() return self.getUsedFluidStorage() end, -- Only ME
		availableItems = function() return self.getAvailableItemStorage() end, -- Only ME
		availableFluids = function() return self.getAvailableFluidStorage() end, -- Only ME
		
		energy = function() return self.getEnergyStorage() end,
		maxEnergy = function() return self.getMaxEnergyStorage() end,
		usageEnergy = function() return self.getEnergyUsage() end,
		
		cpus = function() return self.getCraftingCPUs() end
	}
	self.__getter.craftable = self.__getter.craftableItems
	self.__getter.craftableF = self.__getter.craftableFluids
	self.__getter.craftableFluid = self.__getter.craftableFluids
	self.__getter.total = self.__getter.totalItems
	self.__getter.totalF = self.__getter.totalFluids
	self.__getter.used = self.__getter.usedItems
	self.__getter.usedF = self.__getter.usedFluids
	self.__getter.available = self.__getter.availableItems
	self.__getter.availableF = self.__getter.availableFluids
	
	self._craftItem = self.craftItem
	self.craftItem = function(item, craftingCpu)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._craftItem(_parse(item), craftingCpu)
		end
		return self._craftItem(item, craftingCpu)
	end
	self._craftFluid = self.craftFluid
	self.craftFluid = function(fluid, craftingCpu)
		expect(1, fluid, "string", "table")
		if type(fluid) == 'string' then
			return self._craftFluid(_parse(fluid), craftingCpu)
		end
		return self._craftFluid(fluid, craftingCpu)
	end
	
	self._getItem = self.getItem
	self.getItem = function(item)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._getItem(_parse(item))
		end
		return self._getItem(item)
	end
	
	self._importItem = self.importItem
	self.importItem = function(item, direction)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._importItem(_parse(item), epf.SIDES[direction])
		end
		return self._importItem(item, epf.SIDES[direction])
	end
	self._exportItem = self.exportItem
	self.exportItem = function(item, direction)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._exportItem(_parse(item), epf.SIDES[direction])
		end
		return self._exportItem(item, epf.SIDES[direction])
	end
	
	self._importItemFromPeripheral = self.importItemFromPeripheral
	self.importItemFromPeripheral = function(item, container)
		expect(1, item, "string", "table")
		expect(2, container, "string", "table")
		local name = container
		if type(name) == 'table' then
			name = peripheral.getName(name)
		end
		if type(item) == 'string' then
			return self._importItemFromPeripheral(_parse(item), name)
		end
		return self._importItemFromPeripheral(item, name)
	end
	self._exportItemToPeripheral = self.exportItemToPeripheral
	self.exportItemToPeripheral = function(item, container)
		expect(1, item, "string", "table")
		expect(2, container, "string", "table")
		local name = container
		if type(name) == 'table' then
			name = peripheral.getName(name)
		end
		if type(item) == 'string' then
			return self._exportItemToPeripheral(_parse(item), name)
		end
		return self._exportItemToPeripheral(item, name)
	end
	
	self._isItemCrafting = self.isItemCrafting
	self.isItemCrafting = function(item, craftingCpu)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._isItemCrafting(_parse(item), craftingCpu)
		end
		return self._isItemCrafting(item, craftingCpu)
	end
	self._isItemCraftable = self.isItemCraftable
	self.isItemCraftable = function(item, craftingCpu)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._isItemCraftable(_parse(item), craftingCpu)
		end
		return self._isItemCraftable(item, craftingCpu)
	end
	
	self.tasks = {}
	self.addRawTask = function(name, amount, fingerprint, nbt, batch, isFluid, trigger)
		local item = {name=name, fingerprint=fingerprint, nbt=nbt}
		self.tasks[#self.tasks+1] = Task(item, isFluid, amount, batch, trigger)
	end
	self.addTask = function(task)
		self.tasks[#self.tasks+1] = task
	end
	self.eraseTask = function(name, nbt, fingerprint)
		if name then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.name == name then
					table.remove(self.tasks, i)
				end
			end
		end
		if nbt then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.nbt == nbt then
					table.remove(self.tasks, i)
				end
			end
		end
		if fingerprint then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.fingerprint == fingerprint then
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
			self.tasks[#self.tasks+1] = Task.fromJson(v)
		end
	end
	self.saveTasksToJson = function()
		local tbl = {}
		for k, v in pairs(self.tasks) do
			tbl[k] = v.toJson()
		end
		return tbl
	end
	
	return self
end
MEBridge = epf.wrapperFixer(MEBridge, "meBridge", "ME Bridge")

local RSBridge = {}
function RSBridge.__init(self)
	self.__getter = {
		craftableItems = function() return self.listCraftableItems() end,
		craftableFluids = function() return self.listCraftableFluids() end, -- ME: listCraftableFluid
		
		items = function() return self.listItems() end,
		fluids = function() return self.listFluids() end, -- ME: listFluid
		
		energy = function() return self.getEnergyStorage() end,
		maxEnergy = function() return self.getMaxEnergyStorage() end,
		usageEnergy = function() return self.getEnergyUsage() end,
		
		iMaxDiskStorage = function() return self.getMaxItemDiskStorage() end, -- Only RS
		fMaxDiskStorage = function() return self.getMaxFluidDiskStorage() end, -- Only RS
		iMaxExtStorage = function() return self.getMaxItemExternalStorage() end, -- Only RS
		fMaxExtStorage = function() return self.getMaxFluidExternalStorage() end, -- Only RS
	}
	self.__getter.craftable = self.__getter.craftableItems
	self.__getter.craftableF = self.__getter.craftableFluids
	self.__getter.craftableFluid = self.__getter.craftableFluids
	self.__getter.itemStorage = self.__getter.iMaxDiskStorage
	self.__getter.fluidStorage = self.__getter.fMaxDiskStorage
	self.__getter.itemStorageEx = self.__getter.iMaxExtStorage
	self.__getter.fluidStorageEx = self.__getter.fMaxExtStorage
	
	self._craftItem = self.craftItem
	self.craftItem = function(item, craftingCpu)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._craftItem(_parse(item), craftingCpu)
		end
		return self._craftItem(item, craftingCpu)
	end
	self._craftFluid = self.craftFluid
	self.craftFluid = function(fluid, craftingCpu)
		expect(1, fluid, "string", "table")
		if type(fluid) == 'string' then
			return self._craftFluid(_parse(fluid), craftingCpu)
		end
		return self._craftFluid(fluid, craftingCpu)
	end
	
	self._getItem = self.getItem
	self.getItem = function(item)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._getItem(_parse(item))
		end
		return self._getItem(item)
	end
	
	self._importItem = self.importItem
	self.importItem = function(item, direction)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._importItem(_parse(item), epf.SIDES[direction])
		end
		return self._importItem(item, epf.SIDES[direction])
	end
	self._exportItem = self.exportItem
	self.exportItem = function(item, direction)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._exportItem(_parse(item), epf.SIDES[direction])
		end
		return self._exportItem(item, epf.SIDES[direction])
	end
	
	self._importItemFromPeripheral = self.importItemFromPeripheral
	self.importItemFromPeripheral = function(item, container)
		expect(1, item, "string", "table")
		expect(2, container, "string", "table")
		local name = container
		if type(name) == 'table' then
			name = peripheral.getName(name)
		end
		if type(item) == 'string' then
			return self._importItemFromPeripheral(_parse(item), name)
		end
		return self._importItemFromPeripheral(item, name)
	end
	self._exportItemToPeripheral = self.exportItemToPeripheral
	self.exportItemToPeripheral = function(item, container)
		expect(1, item, "string", "table")
		expect(2, container, "string", "table")
		local name = container
		if type(name) == 'table' then
			name = peripheral.getName(name)
		end
		if type(item) == 'string' then
			return self._exportItemToPeripheral(_parse(item), name)
		end
		return self._exportItemToPeripheral(item, name)
	end
	
	self._isItemCrafting = self.isItemCrafting
	self.isItemCrafting = function(item)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._isItemCrafting(_parse(item))
		end
		return self._isItemCrafting(item)
	end
	self._isItemCraftable = self.isItemCraftable
	self.isItemCraftable = function(item)
		expect(1, item, "string", "table")
		if type(item) == 'string' then
			return self._isItemCraftable(_parse(item))
		end
		return self._isItemCraftable(item)
	end
	
	self.tasks = {}
	self.addRawTask = function(name, amount, fingerprint, nbt, batch, isFluid, trigger)
		local item = {name=name, fingerprint=fingerprint, nbt=nbt}
		self.tasks[#self.tasks+1] = Task(item, isFluid, amount, batch, trigger)
	end
	self.addTask = function(task)
		self.tasks[#self.tasks+1] = task
	end
	self.eraseTask = function(name, nbt, fingerprint)
		if name then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.name == name then
					table.remove(self.tasks, i)
				end
			end
		end
		if nbt then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.nbt == nbt then
					table.remove(self.tasks, i)
				end
			end
		end
		if fingerprint then
			for i=#self.tasks, 0, -1 do
				if self.tasks[i].item.fingerprint == fingerprint then
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
			self.tasks[#self.tasks+1] = Task.fromJson(v)
		end
	end
	self.saveTasksToJson = function()
		local tbl = {}
		for k, v in pairs(self.tasks) do
			tbl[k] = v.toJson()
		end
		return tbl
	end
	
	return self
end
RSBridge = epf.wrapperFixer(RSBridge, "rsBridge", "RS Bridge")

local lib = {}
lib.MEBridge = MEBridge
lib.RSBridge = RSBridge
lib.Task = Task
lib.Trigger = Trigger
lib.TriggerGroup = TriggerGroup

function lib.help()
	local text = {
		"ME and RS Bridge library. Contains:\n",
		"MEBridge",
		"([name]) - MEBridge wrapper\n",
		"RSBridge",
		"([name]) - RSBridge wrapper\n",
		"Task",
		"(item[, isFluid[, amount[, batch[, trigger]]]]) - Crafttask\n",
		"TriggerGroup",
		"([op,...]) - Group of crafttask triggers\n",
		"Trigger",
		"([item1[, math_op1[, const1[, op[, item2[, math_op2[, const2]]]]]]]) - Crafttask trigger\n",
	}
	local c = {
		colors.red,
		colors.blue,
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

local _m = getmetatable(MEBridge)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="ME_RS_Bridge",
	__name="library",
	__tostring=function(self)
		return "EPF-library for ME and RS Bridges (Advanced Peripherals)"
	end,
})

return lib
