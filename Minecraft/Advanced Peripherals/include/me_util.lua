--[[
	ME Bridge Utility library by PavelKom.
	Version: 0.7b
	Wrapped ME Bridge
	https://advancedperipherals.netlify.app/peripherals/me_bridge/
	ToDo: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.SIDES = getset.SIDES
this_library.DEFAULT_PERIPHERAL = nil
this_library.DEFAULT_COUNT = 1000
this_library.DEFAULT_BATCH = 1
-- Operators <,>,== etc.
this_library.OP = {
	'LT', 'LE', 'EQ', 'NE', 'GE', 'GT', 
}
for k,v in pairs(this_library.OP) do
	this_library.OP[v] = v
	this_library.OP[k] = nil
end
setmetatable(this_library.OP, {__index = getset.GETTER_TO_UPPER(this_library.OP.LT)})
local OP_LAMBDA = {
	LT = function(a,b) return a <  b end,
	LE = function(a,b) return a <= b end,
	EQ = function(a,b) return a == b end,
	NE = function(a,b) return a ~= b end,
	GE = function(a,b) return a >= b end,
	GT = function(a,b) return a >  b end,
}
setmetatable(OP_LAMBDA, {__index = getset.GETTER_TO_UPPER(OP_LAMBDA.LT)})

this_library.TASKRESULT = {
	[1]= 'start crafting',
	[0] = 'no materials',
	[-1] = 'conditions not met',
	[-2] = 'already crafting',
	[-3] = 'excess'
}
setmetatable(this_library.TASKRESULT, {__index = this_library.TASKRESULT[1]})

-- Events
function this_library.waitCcraftingEvent()
	--event, success, message
	return os.pullEvent("crafting")
end
function this_library.waitCraftingEx(func)
	--[[
	Create semi-infinite loop for crafting event listener
	func - callback function. Must have arguments:
		table = {
			event,
			success,
			message
		}
		And return true, else stop loop 
	]]
	if func == nil then
		error('me_util.waitCraftingEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent("crafting")})
	end
end

-- Peripheral
function this_library:MEBridge(name)
	local def_type = 'meBridge'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to ME Bridge '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.tasks = {}
	ret.addTaskRaw = function(item, count, fingerprint, nbt, batch, isFluid, triggers, isOR)
		ret.tasks[#ret.tasks+1] = this_library:CraftTask(item, count, fingerprint, nbt, batch, isFluid, triggers, isOR)
	end
	ret.addTask = function(task)
		ret.tasks[#ret.tasks+1] = task
	end
	ret.eraseTask = function(item)
		local i = 1
		while i < #ret.tasks do
			if ret.tasks[i].item == item then
				table.remove(ret.tasks, i)
			else
				i = i + 1
			end
		end
	end
	ret.clearTasks = function()
		while #ret.tasks > 0 do
			table.remove(ret.tasks, 1)
		end
	end
	ret.runTaks = function(callback)
		for _, task in pairs(ret.tasks) do
			task.craft(ret, _, _, callback)
		end
	end
	ret.runTask = function(index, callback)
		if ret.tasks[i] == nil then return false, 0 end
		return ret.tasks[i].craft(ret, _, _, callback)
	end
	
	ret.__getter = {
		craftableItems = function() return ret.object.listCraftableItems() end,
		craftableFluids = function() return ret.object.listCraftableFluid() end,
		items = function() return ret.object.listItems() end,
		fluids = function() return ret.object.listFluid() end,
		gases = function() return ret.object.listGas() end,
		cells = function() return ret.object.listCells() end,
		totalItems = function() return ret.object.getTotalItemStorage() end,
		totalFluids = function() return ret.object.getTotalFluidStorage() end,
		usedItems = function() return ret.object.getUsedItemStorage() end,
		usedFluids = function() return ret.object.getUsedFluidStorage() end,
		availableItems = function() return ret.object.getAvailableItemStorage() end,
		availableFluids = function() return ret.object.getAvailableFluidStorage() end,
		energy = function() return ret.object.getEnergyStorage() end,
		maxEnergy = function() return ret.object.getMaxEnergyStorage() end,
		usageEnergy = function() return ret.object.getEnergyUsage() end,
		cpus = function() return ret.object.getCraftingCPUs() end
	}
	
	ret.__getter.craftable = ret.__getter.craftableItems
	ret.__getter.craftables2 = ret.__getter.craftableFluids
	ret.__getter.total = ret.__getter.totalItems
	ret.__getter.total2 = ret.__getter.totalFluids
	ret.__getter.used = ret.__getter.usedItems
	ret.__getter.used2 = ret.__getter.usedFluids
	ret.__getter.available = ret.__getter.availableItems
	ret.__getter.available2 = ret.__getter.availableFluids
	
	ret.craftItem = function(item, craftingCpu) return ret.object.craftItem(item, craftingCpu) end
	ret.craftItem2 = function(name, count, nbt, craftingCpu)
		return ret.object.craftItem({name=name, count=count or 1, nbt=nbt}, craftingCpu)
	end
	ret.craftItem3 = function(fingerprint, count, craftingCpu)
		return ret.object.craftItem({fingerprint=fingerprint, count=count or 1}, craftingCpu)
	end
	
	ret.craftFluid = function(fluid, craftingCpu) return ret.object.craftFluid(fluid, craftingCpu) end
	ret.craftFluid2 = function(name, count, nbt, craftingCpu)
		return ret.object.craftFluid({name=name, count=count or 1, nbt=nbt}, craftingCpu)
	end
	ret.craftFluid3 = function(fingerprint, count, craftingCpu)
		return ret.object.craftFluid({fingerprint=fingerprint, count=count or 1}, craftingCpu)
	end
	
	ret.getItem = function(item) return ret.object.getItem(item) end
	ret.getItem2 = function(name, nbt) return ret.object.getItem({name=name, nbt=nbt}) end
	ret.getItem3 = function(fingerprint) return ret.object.getItem({fingerprint=fingerprint}) end
	
	ret.importItem = function(item, direction) return ret.object.importItem(item, this_library.SIDES[direction]) end
	ret.importItem2 = function(name, nbt, count, direction) return ret.object.importItem({name=name, nbt=nbt, count=count or 1}, this_library.SIDES[direction]) end
	ret.importItem3 = function(fingerprint, count, direction) return ret.object.importItem({fingerprint=fingerprint, count=count or 1}, this_library.SIDES[direction]) end
	
	ret.exportItem = function(item, direction) return ret.object.exportItem(item, this_library.SIDES[direction]) end
	ret.exportItem2 = function(name, nbt, count, direction) return ret.object.exportItem({name=name, nbt=nbt, count=count or 1}, this_library.SIDES[direction]) end
	ret.exportItem3 = function(fingerprint, count, direction) return ret.object.exportItem({fingerprint=fingerprint, count=count or 1}, this_library.SIDES[direction]) end
	
	ret.importItemFromPeripheral = function(item, container) return ret.object.importItemFromPeripheral(item, container) end
	ret.importItemFromPeripheral2 = function(name, nbt, count, container)
		return ret.object.importItemFromPeripheral({name=name, nbt=nbt, count=count or 1}, container)
	end
	ret.importItemFromPeripheral3 = function(fingerprint, count, container)
		return ret.object.importItemFromPeripheral({fingerprint=fingerprint, count=count or 1}, container)
	end
	
	ret.exportItemToPeripheral = function(item, container) return ret.object.exportItemToPeripheral(item, container) end
	ret.exportItemToPeripheral2 = function(name, nbt, count, container)
		return ret.object.exportItemToPeripheral({name=name, nbt=nbt, count=count or 1}, container)
	end
	ret.exportItemToPeripheral3 = function(fingerprint, count, container)
		return ret.object.exportItemToPeripheral({fingerprint=fingerprint, count=count or 1}, container)
	end
	
	ret.isItemCrafting = function(item, craftingCpu) return ret.object.isItemCrafting(item, craftingCpu) end
	ret.isItemCrafting2 = function(name, nbt, craftingCpu) return ret.object.isItemCrafting({name=name, nbt=nbt}, craftingCpu) end
	ret.isItemCrafting3 = function(fingerprint, craftingCpu) return ret.object.isItemCrafting({fingerprint=fingerprint}, craftingCpu) end
	
	ret.isItemCraftable = function(item, craftingCpu) return ret.object.isItemCraftable(item, craftingCpu) end
	ret.isItemCraftable2 = function(name, nbt, craftingCpu) return ret.object.isItemCraftable({name=name, nbt=nbt}, craftingCpu) end
	ret.isItemCraftable3 = function(fingerprint, craftingCpu) return ret.object.isItemCraftable({fingerprint=fingerprint}, craftingCpu)   end
	
	ret.__setter = {}
	
	ret.update = function()
		ret.object = peripheral.wrap(ret.name)
		if not ret.object then error("Can't connect to ME Bridge '"..name.."'") end
	end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("ME Bridge '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

-- Create Tasks
function this_library:CraftTask(item, count, fingerprint, nbt, batch, isFluid, triggers, isOR)
	if item == nil and fingerprint == nil then error("Can't create task, item not specific") end
	local ret = {
		item=item, fingerprint=fingerprint,
		count=count or this_library.DEFAULT_COUNT,
		nbt=nbt, isFluid=isFluid,
		batch=batch or this_library.DEFAULT_BATCH,
		triggers=triggers or this_library:Triggers(item, fingerprint, count, nbt, _, isOR)
	}
	ret.test = function(interface, isOR)
		return ret.triggers.test(interface, isOR)
	end
	ret.craft = function(interface, isOR, force_batch, callback)
		local result, amount
		local item = interface.getItem({item=item, nbt=nbt, fingerprint=fingerprint})
		if item and item.count and item.count >= ret.count then
			result, amount = false, -3
		elseif not ret.isFluid then
			result, amount = ret.craftItem(interface, isOR, force_batch)
		else
			result, amount = ret.craftFluid(interface, isOR, force_batch)
		end
		if callback and type(callback) == 'function' then
			callback({result=result, item=ret.item, nbt=nbt, fingerprint=ret.fingerprint, amount=amount})
		end
		return result, amount
	end
	ret.craftItem = function(interface, isOR, force_batch)
		if not ret.test(interface, isOR) then return false, -1 end
		if interface.isItemCrafting({item=item, nbt=nbt, fingerprint=fingerprint}) then return false, -2 end
		batch = ret.batch or force_batch
		local result = interface.craftItem({item=item, nbt=nbt, fingerprint=fingerprint, count=batch})
		while batch > 1 and not result and force_batch == nil do
			batch = math.ceil(batch/10)
			result = interface.craftItem({item=item, nbt=nbt, fingerprint=fingerprint, count=batch})
		end
		return result, batch
	end
	ret.craftFluid = function(interface, isOR, force_batch)
		if not ret.test(interface, isOR) then return false, -1 end
		if interface.isItemCrafting({item=item, fingerprint=fingerprint}) then return false, -2 end
		batch = ret.batch or force_batch
		local result = interface.craftFluid({item=item, nbt=nbt, fingerprint=fingerprint, count=batch})
		while batch > 0.001 and not result and force_batch == nil do
			batch = math.ceil((batch/10)*1000)/1000
			result = interface.craftFluid({item=item, nbt=nbt, fingerprint=fingerprint, count=batch})
		end
		return result, batch
	end
	ret.json = function()
		return {
			item=ret.item, fingerprint=ret.fingerprint,
			count=ret.count,
			nbt=ret.nbt, isFluid=ret.isFluid,
			batch=ret.batch,
			triggers=ret.triggers.json()
		}
	end
	
	return ret
end

-- Trigger list
function this_library:Triggers(item, fingerprint, count, nbt, trigger_arr, isOR)
	local ret = {__trgs={}, isOR=isOR}
	if item ~= nil or fingerprint ~= nil then
		ret.__trgs[#ret.__trgs+1] = this_library:Trigger(item, fingerprint, count, nbt)
	end
	ret.add = function(item, fingerprint, count, nbt, operator)
		ret.__trgs[#ret.__trgs+1] = this_library:Trigger(item, fingerprint, count, nbt, operator)
		return ret.__trgs[#ret.__trgs]
	end
	ret.clear = function()
		while #ret.__trgs > 0 do table.remove(ret.__trgs, 1) end
	end
	ret.erase = function(item)
		local i = 1
		while i < #ret.__trgs do
			if ret.__trgs[i].item == item then
				table.remove(ret.__trgs, i)
			else
				i = i + 1
			end
		end
	end
	ret.erase2 = function(fingerprint)
		local i = 1
		while i < #ret.__trgs do
			if ret.__trgs[i].fingerprint == fingerprint then
				table.remove(ret.__trgs, i)
			else
				i = i + 1
			end
		end
	end
	ret.test = function(interface, isOR)
		isOR = isOR or ret.isOR
		if interface == nil then return false end
		for _, t in pairs(ret.__trgs) do
			test = t.test(interface)
			if isOR and test then
				return true
			elseif not isOR and not test then
				return false
			end
		end
		return isOR and false or true
	end
	ret.json = function()
		local result = {isOR=ret.isOR, triggers={}}
		for _, v in pairs(ret.__trgs) do
			result.triggers[#result.triggers+1] = v.json()
		end
		return result
	end

	return ret
end

-- Trigger
function this_library:Trigger(item, fingerprint, count, nbt, operator)
	local ret = {item=item, fingerprint=fingerprint, count=count, nbt=nbt, operator=operator or this_library.OP.LT}
	ret.test = function(interface)
		if interface == nil then return false end
		local item = interface.getFl({item=item, nbt=nbt, fingerprint=fingerprint})
		if item == nil or item.count == nil then
			if ret.count > 0 and (ret.operator == this_library.OP.LT or 
				ret.operator == this_library.OP.LE or 
				ret.operator == this_library.OP.NE) then
				return true
			elseif ret.count == 0 and (ret.operator == this_library.OP.EQ or 
				ret.operator == this_library.OP.GE) then
				return true
			else return false end
		else
			return OP_LAMBDA[ret.operator](item.count, ret.count)
		end
	end
	ret.json = function()
		return {item=ret.item, fingerprint=ret.fingerprint, count=ret.count, nbt=ret.nbt, operator=ret.operator}
	end
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:MEBridge()
	end
end

function taskFromJson(json)
	if type(json) == 'string' then
		json = textutils.unserializeJSON(json)
	end
	return this_library:CraftTask(
		item=json.item, fingerprint=json.fingerprint,
		count=json.count,
		nbt=json.nbt, isFluid=json.isFluid,
		batch=json.batch,
		triggers=triggersFromJson(json.triggers)
	)
end
function triggersFromJson(json)
	if type(json) == 'string' then
		json = textutils.unserializeJSON(json)
	end
	local trg = this_library:Triggers(_,_,_,_,_, json.isOR)
	for _, v in pairs(json.triggers) do
		trg.__trgs[#trg.__trgs+1] = triggerFromJson(v)
	end
	return result
end
function triggerFromJson(json)
	if type(json) == 'string' then
		json = textutils.unserializeJSON(json)
	end
	return this_library:Trigger(json.item, json.fingerprint, json.count, json.nbt, json.operator)
end




return this_library
