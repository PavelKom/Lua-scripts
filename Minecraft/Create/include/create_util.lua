--[[
	Create Utility library by PavelKom.
	Version: 0.1
	Wrapped peripherals from Create
	https://advancedperipherals.netlify.app/peripherals/chat_box/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_STRESSOMETER = nil

-- Peripherals
function this_library:Speedometer(name)
	local def_type = 'Create_Speedometer'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Speedometer '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		speed = function() return ret.object.getSpeed() end,
	    abs = function() return math.abs(ret.object.getSpeed()) end,
	    dir = function() return ret.object.getSpeed() >= 0 and 1 or -1 end,
	}
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speedometer '%s' Speed: %i", self.name, self.speed)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:Stressometer(name)
	local def_type = 'Create_Stressometer'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Stressometer '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		stress = function() return ret.object.getStress() end,
		cap = function() return ret.object.getStressCapacity() end,
		use = function()
			if ret.object.getStressCapacity() == 0 then return 1.0 end
			return ret.object.getStress() / ret.object.getStressCapacity()
		end,
		free = function() return ret.object.getStressCapacity() - ret.object.getStress() end,
		is_overload = function() return ret.object.getStressCapacity() < ret.object.getStress() end,
	}
	ret.__getter.max = ret.__getter.cap
	ret.__getter.overload = ret.__getter.is_overload
	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Stressometer '%s' Stress: %i/%i (%.1f%%)", self.name, self.stress, self.max, self.use * 100)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:RotationSpeedController(name)
	local def_type = 'Create_RotationSpeedController'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Rotation Speed Controller '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		speed = function() return ret.object.getTargetSpeed() end,
	    abs = function() return math.abs(ret.object.getTargetSpeed()) end,
	    dir = function() return ret.object.getTargetSpeed() >= 0 and 1 or -1 end,
	}
	ret.__setter = {
		speed = function(value) ret.object.setTargetSpeed(value) end,
	    abs = function(value) -- non-negative number
			ret.object.setTargetSpeed(math.abs(value)*ret.dir)
		end,
	    dir = function(value) -- boolean or number
			if type(value) == 'boolean' then
				ret.object.setTargetSpeed(ret.abs * (value and 1 or -1))
			elseif type(value) == 'number' then
				ret.object.setTargetSpeed(ret.abs * (value >= 0 and 1 or -1))
			end
		end,
	}
	ret.invert = function() return ret.object.setTargetSpeed(-1 * ret.object.getTargetSpeed()) end
	ret.inv = ret.invert
	ret.reverse = ret.invert
	
	ret.stop = function()
		if not ret.is_stopped then
			ret.__buf_speed = ret.speed
			ret.speed = 0
			ret.__is_stopped = true
		end
	end
	ret.resume = function(speed)
		ret.__is_stopped = false
		ret.speed = speed or ret.__buf_speed
	end
	ret.switch = function()
		if ret.__is_stopped then ret.resume() else ret.stop() end
	end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Rotation Speed Controller '%s' Speed: %i", self.name, self.speed)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:DisplayLink(name)
	local def_type = 'Create_DisplayLink'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Display Link '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.pos = {}
	setmetatable(ret.pos, {
		__call = function(self, x_tbl, y)
			if type(x_tbl) == 'table' then
				ret.object.setCursorPos(x_tbl[1] or x_tbl.x or 1, x_tbl[2] or x_tbl.y or 1)
			elseif x_tbl ~= nil and y ~= nil then
				ret.object.setCursorPos(x_tbl, y)
			elseif x_tbl ~= nil and y == nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(x_tbl, _y)
			elseif x_tbl == nil and y ~= nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, y)
			end
			return ret.object.getCursorPos()
		end,
		__index = function(self, index)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				return _x
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				return _y
			elseif string.lower(tostring(index)) == 'xy' then
				return ret.object.getCursorPos()
			end
		end,
		__newindex = function(self, index, value)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(value, _y)
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, value)
			elseif string.lower(tostring(index)) == 'xy' then
				ret.object.setCursorPos(value[1] or value.x or 1, value[2] or value.y or 1)
			end
		end,
	})
	ret.__getter = {
		size = function() return {ret.object.getSize()} end,
		rows = function() return ret.size[2] end,
		columns = function() return ret.size[1] end,
		color = function() return ret.object.isColor() end
	}
	ret.__getter.colour = ret.__getter.color
	ret.__setter = {}
	ret.nextLine = function()
		ret.pos.x = 1
		ret.pos.y = ret.pos.y + 1
	end
	ret.prevLine = function()
		ret.pos.x = 1
		ret.pos.y = ret.pos.y - 1
	end
	ret.getPos = function() return ret.object.getCursorPos() end
	ret.setPos = function(x, y) ret.object.setCursorPos(x, y) end
	ret.write = function (text) ret.object.write(text) end
	ret.print = ret.write
	ret.clearLine = function() ret.object.clearLine() end
	ret.clear = function() ret.object.clear() end
	ret.update = function() ret.object.update() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Display Link '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:SequencedGearshift(name)
	local def_type = 'Create_SequencedGearshift'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Sequenced Gearshift '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		run = function() return ret.object.isRunning() end,
	}
	ret.isRunning = ret.run
	ret.isRun = ret.run
	
	ret.rotate = function(angle, modifier) ret.object.rotate(angle, modifier) end
	ret.move = function(distance, modifier) ret.object.move(distance, modifier) end

	ret.__setter = {}
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Sequenced Gearshift '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end
function this_library:TrainStation(name)
	local def_type = 'Create_Station'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Train Station '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		mode = function() return ret.object.isInAssemblyMode() end,
		station = function() return pcall(ret.object.getStationName) end,
		present = function()
			local result, err = pcall(ret.object.isTrainPresent)
			return result and err or false
		end,
		imminent = function()
			local result, err = pcall(ret.object.isTrainImminent)
			return result and err or false
		end,
		enroute = function()
			local result, err = pcall(ret.object.isTrainEnroute)
			return result and err or false
		end,
		train = function()
			local result, err = pcall(ret.object.getTrainName)
			return result and err or false
		end,
		hasSchedule = function()
			local result, err = pcall(ret.object.hasSchedule)
			return result and err or false
		end,
		schedule = function() return this_library:Schedule(ret) end
	}
	ret.__setter = {
		mode = function(assemblyMode) return pcall(ret.object.setAssemblyMode,assemblyMode) end,
		station = function(name) return pcall(ret.object.setStationName,name) end,
		train = function(name) return pcall(ret.object.setTrainName,name) end,
		schedule = function(schedule) return pcall(ret.object.setSchedule,schedule) end,
	}
	
	ret.assemble = function() return pcall(ret.object.assemble) end
	ret.disassemble = function() return pcall(ret.object.disassemble) end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Train Station '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

local id_data_tbls = {
	-- Create
	-- Instruction
	["create:destination"] = {text='MISSING NAME'},
	["create:rename"] = {text='MISSING NAME'},
	["create:throttle"] = {value=100},
	-- Condition
	["create:delay"] = {value=60, time_unit=1},
	["create:time_of_day"] = {hour=6, minute=0, rotation=0},
	["create:fluid_threshold"] = {bucket={id='minecraft:air', count=1}, threshold=1, operator=0, measure=0},
	["create:item_threshold"] = {item={id='minecraft:air', count=1}, threshold=1, operator=0, measure=0},
	["create:redstone_link"] = {frequency={{id='minecraft:air', count=1},{id='minecraft:air', count=1}}, inverted=0},
	["create:player_count"] = {count=1, exact=1},
	["create:idle"] = {value=100, time_unit=1},
	["create:unloaded"] = {}, ["create:powered"] = {},
	
	-- Create: Crafts and Additions
	-- Condition
	["create:energy_threshold"] = {threshold=1, operator=0, measure=0}, -- measure=0 - Kfe
}
local fix_data = {
	["create:destination"] = function(data) return {text=data} end,
	["create:throttle"] = function(data) return {value=data} end,
	["create:time_of_day"] = function(data) return {hour=data} end,
	["create:player_count"] = function(data) return {count=data} end,
	["create:energy_threshold"] = function(data) return {threshold=data} end,
	["create:fluid_threshold"] = function(data)
		if type(data) ~= 'table' then
			data = {id=data or 'minecraft:air', count=1}
		end
		if data["bucket"] == nil then
			data = {bucket=data}
		end
		return data
	end,
	["create:item_threshold"] = function(data)
		if type(data) ~= 'table' then
			data = {id=data or 'minecraft:air', count=1}
		end
		if data["item"] == nil then
			data = {item=data}
		end
		return data
	end,
	["create:redstone_link"] = function(data)
		if type(data) ~= 'table' then
			val = data or 'minecraft:air'
			data = {{id=val, count=1},{id=val, count=1}}
		end
		if data["frequency"] == nil then
			data = {frequency=data}
		end
		return data
	end,
}
fix_data["create:rename"] = fix_data["create:destination"]
fix_data["create:delay"] = fix_data["create:throttle"]
fix_data["create:idle"] = fix_data["create:throttle"]
local function validate_schedule_data(id, data)
	if id_data_tbls[id] == nil then
		error(string.format("[this_library]Schedule: invalid id '%s'",id))
	end
	data = fix_data[id](data)
	for k, v in pairs(id_data_tbls[id]) do
		data[k] = data[k] or v
	end
	
	return data
end
this_library.ScheduleOperator = {
	__call = function(val) return this_library.ScheduleOperator[num] end,
	[0] = 0, ['0'] = 0, GREATER = 0,
	[1] = 1, ['1'] = 1, LESS = 1,
	[2] = 2, ['2'] = 2, EQUAL = 2
}
this_library.ScheduleTimeUnit = {
	__call = function(val) return this_library.ScheduleTimeUnit[num] end,
	[0] = 0, ['0'] = 0, TICK = 0,
	[1] = 1, ['1'] = 1, SECONDS = 1,
	[2] = 2, ['2'] = 2, MINUTES = 2
}
this_library.ScheduleMeasure = {
	__call = function(val) return this_library.ScheduleTimeUnit[num] end,
	[0] = 0, ['0'] = 0, ITEM = 0,
	[1] = 1, ['1'] = 1, STACK = 1,
}
this_library.SchedulePlayerCount = {
	__call = function(val) return this_library.SchedulePlayerCount[num] end,
	[0] = 0, ['0'] = 0, EXACT = 0,
	[1] = 1, ['1'] = 1, GREATER = 1,
}
function this_library:Schedule(station)
	local result, ret = pcall(peripheral.call, station.object, 'getSchedule')
	if not result then return nil end
	ret.addEntry = function(instruction, conditions)
		instruction = instruction or ret.createInstruction()
		conditions = conditions or {ret.createConditionGroup()}
		ret.entries[#ret.entries+1] = {instruction=instruction, conditions=conditions}
	end
	ret.addConditionGroup = function(entry, conds)
		entry = entry or #ret.entries
		index = #ret.entries[entry].conditions+1
		ret.entries[entry].conditions[index] = ret.createConditionGroup(conds)
	end
	ret.addCondition = function(entry, group, condition)
		entry = entry or #ret.entries
		group = group or #ret.entries[entry].conditions
		cond = #ret.entries[entry].conditions[group]+1
		condition = condition or ret.createCondition()
		ret.entries[entry].conditions[group][cond] = condition
	end
	ret.createInstruction = function(id, data)
		id = id or "create:destination"
		data = validate_schedule_data(id, data)
		return {id=id, data=data}
	end
	ret.createCondition = {
		__call = function(id, data)
		id = id or "create:delay"
		data = validate_schedule_data(id, data)
		return {id=id, data=data}
		end,
		delay = function(value, time_unit)
			return {id='create:delay', data={value=tonumber(value or 60),time_unit=this_library.ScheduleTimeUnit(time_unit)}}
		end,
		time = function(hour, minute, rotation)
			return {id='create:time_of_day', data={hour=tonumber(hour or 6), minute=tonumber(minute or 0), rotation=tonumber(rotation or 0)}}
		end,
		fluid = function(bucket, threshold, operator)
			if type(bucket) ~= 'table' then
				bucket = {id = tostring(bucket or "minecraft:air"), count = 1}
			end
			return {id='create:fluid_threshold',
					data={bucket=bucket,threshold=tonumber(threshold or 0),operator=this_library.ScheduleOperator(operator),measure=0}}
		end,
		item = function(item, threshold, operator, measure)
			if type(item) ~= 'table' then
				item = {id = tostring(item or "minecraft:air"), count = 1, measure=tonumber(measure or 0)}
			end
			return {id='create:item_threshold',
					data={item=item,threshold=tonumber(threshold or 0),operator=this_library.ScheduleOperator(operator),measure=this_library.ScheduleMeasure(measure)}}
		end,
		energy = function(threshold, operator) -- For Create: Crafts and Additions
			return {id='create:energy_threshold',
					data={item=item,threshold=tonumber(threshold or 0),operator=this_library.ScheduleOperator(operator),measure=0}}
		end,
		redstone = function(frequency, inverted)
			if type(frequency) ~= 'table' then
				frequency = {{id=tostring(frequency or "minecraft:air"), count=1},{id="minecraft:air", count=1}}
			end
			if type(frequency[1]) ~= 'table' then
				frequency[1] = {id=tostring(frequency[1] or "minecraft:air"), count=1}
			end
			if type(frequency[2]) ~= 'table' then
				frequency[2] = {id=tostring(frequency[2] or "minecraft:air"), count=1}
			end
			return {id='create:redstone_link',
					data={frequency=frequency, inverted=tonumber(inverted or 0)}}
		end,
		player = function(count, exact)
			return {id='create:player_count',
					data={count=tonumber(count or 0),operator=this_library.SchedulePlayerCount(operator)}}
		end,
		idle = function(value, time_unit)
			return {id='create:idle', data={value=tonumber(value or 60),time_unit=this_library.ScheduleTimeUnit(time_unit)}}
		end,
		unloaded = function() return {id='create:unloaded'} end,
		powered = function() return {id='create:powered'} end
	}
	ret.createConditionGroup = function(conditions)
		conditions = conditions or {ret.createCondition()}
		return conditions
	end
	ret.getConditions = function(entry)
		entry = entry or #ret.entries
		return ret.entries[entry].conditions
	end
	ret.getConditionGroup = function(entry, group)
		entry = entry or #ret.entries
		group = group or #ret.entries[entry].conditions
		return ret.entries[entry].conditions[group]
	end
	ret.getCondition = function(entry, group, cond)
		entry = entry or #ret.entries
		group = group or #ret.entries[entry].conditions
		cond = cond or #ret.entries[entry].conditions[group]
		return ret.entries[entry].conditions[group][cond]
	end
	ret.removeEntry = function(entry)
		entry = entry or #ret.entries
		table.remove(ret.entries, entry)
		if #ret.entries == 0 then
			ret.addEntry()
		end
	end
	ret.removeConditionGroup = function(entry, group)
		entry = entry or #ret.entries
		group = group or #ret.entries[entry].conditions
		table.remove(ret.entries[entry].conditions, group)
		if #ret.entries[entry].conditions == 0 then
			ret.addConditionGroup()
		end
	end
	ret.removeCondition = function(entry, group, cond)
		entry = entry or #ret.entries
		group = group or #ret.entries[entry].conditions
		cond = cond or #ret.entries[entry].conditions[group]
		table.remove (ret.entries[entry].conditions[group], cond)
		if #ret.entries[entry].conditions[group] == 0 then
			table.remove(ret.entries[entry].conditions,group)
		end
		if #ret.entries[entry].conditions == 0 then
			ret.addConditionGroup()
		end
	end
	
	setmetatable(ret, {
	__tostring = function(self)
		return string.format('Schedule(%s) Entries: %i', tostring(self.cyclic), #self.entries)
	end,
    __len = function(self) return #self.entries end
	})
	return ret
end

return this_library
