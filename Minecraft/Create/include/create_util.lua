--[[
	Create Utility library by PavelKom.
	Version: 0.5
	Wrapped peripherals from Create mod
	https://github.com/Creators-of-Create/Create/wiki/ComputerCraft-Integration
	TODO: Add manual
]]
local getset = require 'getset_util'
local expect = require 'cc.expect'
local expect, field, range = expect.expect, expect.field, expect.range

local lib = {}

-- Speedometer
local Speedometer = {}
Speedometer.__items = {}
function Speedometer:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_Speedometer', 'Speedometer', Speedometer)
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		speed = function() return self.object.getSpeed() end,
	    abs = function() return math.abs(self.object.getSpeed()) end,
	    dir = function() return self.object.getSpeed() >= 0 and 1 or -1 end,
	}
	self.__setter = {}

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Speed: %i", type(self), self.name, self.speed)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Speedometer"
	})
	Speedometer.__items[self.name] = self
	if not Speedometer.default then Speedometer.default = self end
	return self
end
Speedometer.delete = function(name)
	if name then Speedometer.__items[_name] = nil end
end
lib.Speedometer=setmetatable(Speedometer,{__call=Speedometer.new})

-- Stressometer
local Stressometer = {}
Stressometer.__items = {}
function Stressometer:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_Stressometer', 'Stressometer', Stressometer)
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		stress = function() return self.object.getStress() end,
		cap = function() return self.object.getStressCapacity() end,
		use = function()
			if self.object.getStressCapacity() == 0 then return 1.0 end
			return self.object.getStress() / self.object.getStressCapacity()
		end,
		free = function() return self.object.getStressCapacity() - self.object.getStress() end,
		is_overload = function() return self.object.getStressCapacity() < self.object.getStress() end,
	}
	self.__getter.max = self.__getter.cap
	self.__getter.overload = self.__getter.is_overload
	self.__setter = {}

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Stress: %i/%i (%.1f%%)", type(self), self.name, self.stress, self.max, self.use * 100)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Stressometer"
	})
	Stressometer.__items[self.name] = self
	if not Stressometer.default then Stressometer.default = self end
	return self
end
Stressometer.delete = function(name)
	if name then Stressometer.__items[_name] = nil end
end
lib.Stressometer=setmetatable(Stressometer,{__call=Stressometer.new})

-- Rotation Speed Controller
local RotationSpeedController = {}
RotationSpeedController.__items = {}
function RotationSpeedController:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_RotationSpeedController', 'Rotation Speed Controller', RotationSpeedController)
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		speed = function() return self.object.getTargetSpeed() end,
	    abs = function() return math.abs(self.object.getTargetSpeed()) end,
	    dir = function() return self.object.getTargetSpeed() >= 0 and 1 or -1 end,
	}
	self.__setter = {
		speed = function(value) self.object.setTargetSpeed(value) end,
	    abs = function(value) -- non-negative number
			self.object.setTargetSpeed(math.abs(value)*self.dir)
		end,
	    dir = function(value) -- boolean or number
			if type(value) == 'boolean' then
				self.object.setTargetSpeed(self.abs * (value and 1 or -1))
			elseif type(value) == 'number' then
				self.object.setTargetSpeed(self.abs * (value >= 0 and 1 or -1))
			end
		end,
	}
	self.invert = function() return self.object.setTargetSpeed(-1 * self.object.getTargetSpeed()) end
	self.inv = self.invert
	self.reverse = self.invert
	
	self.__is_stopped = false
	self.__buf_speed = 0
	
	self.stop = function()
		if not self.__is_stopped then
			self.__buf_speed = self.speed
			self.speed = 0
			self.__is_stopped = true
		end
	end
	self.resume = function(speed)
		self.__is_stopped = false
		self.speed = speed or self.__buf_speed
	end
	self.switch = function()
		if self.__is_stopped then self.resume() else self.stop() end
	end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Speed: %i", type(self), self.name, self.speed)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Rotation Speed Controller"
	})
	RotationSpeedController.__items[self.name] = self
	if not RotationSpeedController.default then RotationSpeedController.default = self end
	return self
end
RotationSpeedController.delete = function(name)
	if name then RotationSpeedController.__items[_name] = nil end
end
lib.RotationSpeedController=setmetatable(RotationSpeedController,{__call=RotationSpeedController.new})

-- Display Link
local DisplayLink = {}
DisplayLink.__items = {}
function DisplayLink:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_DisplayLink', 'Display Link', DisplayLink)
	if wrapped ~= nil then return wrapped end

	self.pos = getset.metaPos(self.object.getCursorPos, self.object.setCursorPos)
	
	self.__getter = {
		size = function() return {self.object.getSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		color = function() return self.object.isColor() end
		
		row = function() return self.pos.y end,
		column = function() return self.pos.x end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return {self.pos.xy} end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.col = self.__getter.column
	self.__getter.colour = self.__getter.color
	
	self.__setter = {}
	
	self.nextLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y + 1
	end
	self.prevLine = function()
		self.pos.x = 1
		self.pos.y = self.pos.y - 1
	end
	self.getPos = function() return self.object.getCursorPos() end
	self.setPos = function(x, y) self.object.setCursorPos(x, y) end
	self.write = function (text) self.object.write(text) end
	self.print = self.write
	self.clearLine = function() self.object.clearLine() end
	self.clear = function() self.object.clear() end
	self.update = function(reload)
		if reload then
			self.object = peripheral.wrap(self.name)
			if self.object == nil error("[DisplayLink.update] Can't update peripheral object") end
			self.pos = getset.metaPos(self, self.object.getCursorPos, self.object.setCursorPos)
		end
		self.object.update()
	end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Size: %ix%i Colors: %s", type(self), self.name, table.unpack(self.size), self.color)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Display Link"
	})
	DisplayLink.__items[self.name] = self
	if not DisplayLink.default then DisplayLink.default = self end
	return self
end
DisplayLink.delete = function(name)
	if name then DisplayLink.__items[_name] = nil end
end
lib.DisplayLink=setmetatable(DisplayLink,{__call=DisplayLink.new})

-- Sequenced Gearshift
local SequencedGearshift = {}
SequencedGearshift.__items = {}
function SequencedGearshift:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_SequencedGearshift', 'Sequenced Gearshift', SequencedGearshift)
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		isRunning = function() return self.object.isRunning() end,
	}
	self.isRun = self.isRunning
	
	self.rotate = function(angle, modifier) self.object.rotate(angle, modifier) end
	self.move = function(distance, modifier) self.object.move(distance, modifier) end

	self.__setter = {}

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name, table.unpack(self.size), self.color)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Sequenced Gearshift"
	})
	SequencedGearshift.__items[self.name] = self
	if not SequencedGearshift.default then SequencedGearshift.default = self end
	return self
end
SequencedGearshift.delete = function(name)
	if name then SequencedGearshift.__items[_name] = nil end
end
lib.SequencedGearshift=setmetatable(SequencedGearshift,{__call=SequencedGearshift.new})


-- Sequenced Gearshift
local TrainStation = {}
TrainStation.__items = {}
function TrainStation:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'Create_Station', 'Train Station', TrainStation)
	if wrapped ~= nil then return wrapped end

	self.__getter = {
		mode = function() return self.object.isInAssemblyMode() end,
		station = function() return pcall(self.object.getStationName) end,
		present = function()
			local result, err = pcall(self.object.isTrainPresent)
			return result and err or false
		end,
		imminent = function()
			local result, err = pcall(self.object.isTrainImminent)
			return result and err or false
		end,
		enroute = function()
			local result, err = pcall(self.object.isTrainEnroute)
			return result and err or false
		end,
		train = function()
			local result, err = pcall(self.object.getTrainName)
			return result and err or nil
		end,
		hasSchedule = function()
			local result, err = pcall(self.object.hasSchedule)
			return result and err or false
		end,
		schedule = function() return Schedule(self) end
	}
	
	self.__ssetter = {
		mode = function(assemblyMode) return pcall(self.object.setAssemblyMode,assemblyMode) end,
		station = function(name) return pcall(self.object.setStationName,name) end,
		train = function(name) return pcall(self.object.setTrainName,name) end,
		schedule = function(schedule) return pcall(self.object.setSchedule,schedule.toStation()) end,
	}
	
	
	self.assemble = function() return pcall(self.object.assemble) end
	self.disassemble = function() return pcall(self.object.disassemble) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name, table.unpack(self.size), self.color)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Train Station"
	})
	TrainStation.__items[self.name] = self
	if not TrainStation.default then TrainStation.default = self end
	return self
end
TrainStation.delete = function(name)
	if name then TrainStation.__items[_name] = nil end
end
lib.TrainStation=setmetatable(TrainStation,{__call=TrainStation.new})

lib.INSTRUCTIONS = {
DESTINATION = "create:destination",
RENAME = "create:rename",
THROTTLE = "create:throttle",
}
setmetatable(lib.INSTRUCTIONS, {__index = getset.GETTER_TO_UPPER(lib.INSTRUCTIONS.DESTINATION)})

lib.CONDITIONS = {
DELAY = "create:delay",
TIME = "create:time_of_day",
FLUID = "create:fluid_threshold",
ITEM = "create:item_threshold",
REDSTONE = "create:redstone_link",
PLAYER = "create:player_count",
IDLE = "create:idle",
UNLOADED = "create:unloaded",
POWERED = "create:powered"
}
setmetatable(lib.CONDITIONS, {__index = getset.GETTER_TO_UPPER(lib.CONDITIONS.IDLE)})

local function TABLE_NIL_VALIDATOR(info, tbl)
	if tbl == nil then
		warn("[Create.Schedule] 'create:destination' data is nil. Generating new data.")
		tbl = {}
	end
	return tbl
end
local function VALUE_NIL_VALIDATOR(info, tbl, name, default)
	if tbl[name] == nil then
		warn(string.format("[Create.Schedule] '%s' data.%s% is nil. Setting default value (%s)", info, tostring(name), tostring(default))
		tbl[name] = default
	end
	return tbl
end

lib.SCHEDULE_DATA_VALIDATE = {
-- INSTRUCTIONS
["create:destination"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:destination", tbl)
	field(tbl, "text", "string", "nil")
	VALUE_NIL_VALIDATOR("create:destination", tbl, 'text', '*')
	return tbl
end,
["create:rename"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:rename", tbl)
	field(tbl, "text", "string", "nil")
	VALUE_NIL_VALIDATOR("create:rename", tbl, 'text', 'INVALID_SCHEDULE_NAME')
	return tbl
end,
["create:throttle"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:throttle", tbl)
	field(tbl, "value", "number", "nil")
	VALUE_NIL_VALIDATOR("create:throttle", tbl, 'value', 5)
	return tbl
end,

-- CONDITIONS
["create:delay"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:delay", tbl)
	field(tbl, "value", "number", "nil")
	VALUE_NIL_VALIDATOR("create:delay", tbl, 'value', 5)
	field(tbl, "time_unit", "number", "nil")
	if tbl.time_unit ~= nil then
		range(tbl.time_unit, 0, 2)
	else
		VALUE_NIL_VALIDATOR("create:delay", tbl, 'time_unit', 1)
	end
	return tbl
end,
["create:time_of_day"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:time_of_day", tbl)
	field(tbl, "hour", "number", "nil")
	if tbl.hour ~= nil then
		range(tbl.hour, 0, 23)
	else
		VALUE_NIL_VALIDATOR("create:time_of_day", tbl, 'hour', 6)
	end
	field(tbl, "minute", "number", "nil")
	if tbl.minute ~= nil then
		range(tbl.minute, 0, 59)
	else
		VALUE_NIL_VALIDATOR("create:time_of_day", tbl, 'minute', 0)
	end
	field(tbl, "rotation", "number", "nil")
	if tbl.rotation ~= nil then
		range(tbl.rotation, 0, 9)
	else
		VALUE_NIL_VALIDATOR("create:time_of_day", tbl, 'rotation', 0)
	end
	return tbl
end,
["create:fluid_threshold"] = function(tbl)
	expect(1, tbl, "table", "nil")
	TABLE_NIL_VALIDATOR("create:fluid_threshold", tbl)
	field(tbl, "bucket", "number", "nil")
	VALUE_NIL_VALIDATOR("create:fluid_threshold", tbl, 'bucket', 1)
	field(tbl, "threshold", "number", "nil")
	if tbl.threshold ~= nil then
		range(tbl.threshold, 1)
	else
		VALUE_NIL_VALIDATOR("create:fluid_threshold", tbl, 'threshold', 1)
	end
	field(tbl, "operator", "number", "nil")
	if tbl.operator ~= nil then
		range(tbl.rotation, 0, 2)
	else
		VALUE_NIL_VALIDATOR("create:fluid_threshold", tbl, 'operator', 0)
	end
	tbl.measure = 0 -- Only 0 allowed for fluids
	return tbl
end, -- TODO
ITEM = "create:item_threshold",
REDSTONE = "create:redstone_link",
PLAYER = "create:player_count",
IDLE = "create:idle",
UNLOADED = "create:unloaded",
POWERED = "create:powered"

}
setmetatable(lib.INSTRUCTIONS_VALIDATE, {__index = getset.GETTER_TO_LOWER(lib.INSTRUCTIONS_VALIDATE["create:destination"])})


local Schedule = {}
function Schedule:new()
	self.schedule = {
		cyclic = false,
		entries = {},
	}

	self.addEntry = function(instruction, conditions)
	
	
	end
	self.addConditionGroup = function(entry, conds)
	
	
	end
	self.addCondition = function(entry, group, condition)
	
	
	end
	self.createInstruction = function(id, data)
		id = id or "create:destination"
		data = validate_schedule_data(id, data)
		return {id=id, data=data}
	end

end
function Schedule.fromStation(name)
	local result, self = pcall(peripheral.call, station.object, 'getSchedule')
	
	local self = Schedule()
	
	return self
end



-- DEPRECATED (old API)

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
		error(string.format("[lib]Schedule: invalid id '%s'",id))
	end
	data = fix_data[id](data)
	for k, v in pairs(id_data_tbls[id]) do
		data[k] = data[k] or v
	end
	
	return data
end
lib.ScheduleOperator = {
	__call = function(val) return lib.ScheduleOperator[num] end,
	[0] = 0, ['0'] = 0, GREATER = 0,
	[1] = 1, ['1'] = 1, LESS = 1,
	[2] = 2, ['2'] = 2, EQUAL = 2
}
lib.ScheduleTimeUnit = {
	__call = function(val) return lib.ScheduleTimeUnit[num] end,
	[0] = 0, ['0'] = 0, TICK = 0,
	[1] = 1, ['1'] = 1, SECONDS = 1,
	[2] = 2, ['2'] = 2, MINUTES = 2
}
lib.ScheduleMeasure = {
	__call = function(val) return lib.ScheduleTimeUnit[num] end,
	[0] = 0, ['0'] = 0, ITEM = 0,
	[1] = 1, ['1'] = 1, STACK = 1,
}
lib.SchedulePlayerCount = {
	__call = function(val) return lib.SchedulePlayerCount[num] end,
	[0] = 0, ['0'] = 0, EXACT = 0,
	[1] = 1, ['1'] = 1, GREATER = 1,
}
function lib:Schedule(station)
	local result, self = pcall(peripheral.call, station.object, 'getSchedule')
	if not result then return nil end
	self.addEntry = function(instruction, conditions)
		instruction = instruction or self.createInstruction()
		conditions = conditions or {self.createConditionGroup()}
		self.entries[#self.entries+1] = {instruction=instruction, conditions=conditions}
	end
	self.addConditionGroup = function(entry, conds)
		entry = entry or #self.entries
		index = #self.entries[entry].conditions+1
		self.entries[entry].conditions[index] = self.createConditionGroup(conds)
	end
	self.addCondition = function(entry, group, condition)
		entry = entry or #self.entries
		group = group or #self.entries[entry].conditions
		cond = #self.entries[entry].conditions[group]+1
		condition = condition or self.createCondition()
		self.entries[entry].conditions[group][cond] = condition
	end
	self.createInstruction = function(id, data)
		id = id or "create:destination"
		data = validate_schedule_data(id, data)
		return {id=id, data=data}
	end
	self.createCondition = {
		__call = function(id, data)
		id = id or "create:delay"
		data = validate_schedule_data(id, data)
		return {id=id, data=data}
		end,
		delay = function(value, time_unit)
			return {id='create:delay', data={value=tonumber(value or 60),time_unit=lib.ScheduleTimeUnit(time_unit)}}
		end,
		time = function(hour, minute, rotation)
			return {id='create:time_of_day', data={hour=tonumber(hour or 6), minute=tonumber(minute or 0), rotation=tonumber(rotation or 0)}}
		end,
		fluid = function(bucket, threshold, operator)
			if type(bucket) ~= 'table' then
				bucket = {id = tostring(bucket or "minecraft:air"), count = 1}
			end
			return {id='create:fluid_threshold',
					data={bucket=bucket,threshold=tonumber(threshold or 0),operator=lib.ScheduleOperator(operator),measure=0}}
		end,
		item = function(item, threshold, operator, measure)
			if type(item) ~= 'table' then
				item = {id = tostring(item or "minecraft:air"), count = 1, measure=tonumber(measure or 0)}
			end
			return {id='create:item_threshold',
					data={item=item,threshold=tonumber(threshold or 0),operator=lib.ScheduleOperator(operator),measure=lib.ScheduleMeasure(measure)}}
		end,
		energy = function(threshold, operator) -- For Create: Crafts and Additions
			return {id='create:energy_threshold',
					data={item=item,threshold=tonumber(threshold or 0),operator=lib.ScheduleOperator(operator),measure=0}}
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
					data={count=tonumber(count or 0),operator=lib.SchedulePlayerCount(operator)}}
		end,
		idle = function(value, time_unit)
			return {id='create:idle', data={value=tonumber(value or 60),time_unit=lib.ScheduleTimeUnit(time_unit)}}
		end,
		unloaded = function() return {id='create:unloaded'} end,
		powered = function() return {id='create:powered'} end
	}
	self.createConditionGroup = function(conditions)
		conditions = conditions or {self.createCondition()}
		return conditions
	end
	self.getConditions = function(entry)
		entry = entry or #self.entries
		return self.entries[entry].conditions
	end
	self.getConditionGroup = function(entry, group)
		entry = entry or #self.entries
		group = group or #self.entries[entry].conditions
		return self.entries[entry].conditions[group]
	end
	self.getCondition = function(entry, group, cond)
		entry = entry or #self.entries
		group = group or #self.entries[entry].conditions
		cond = cond or #self.entries[entry].conditions[group]
		return self.entries[entry].conditions[group][cond]
	end
	self.removeEntry = function(entry)
		entry = entry or #self.entries
		table.remove(self.entries, entry)
		if #self.entries == 0 then
			self.addEntry()
		end
	end
	self.removeConditionGroup = function(entry, group)
		entry = entry or #self.entries
		group = group or #self.entries[entry].conditions
		table.remove(self.entries[entry].conditions, group)
		if #self.entries[entry].conditions == 0 then
			self.addConditionGroup()
		end
	end
	self.removeCondition = function(entry, group, cond)
		entry = entry or #self.entries
		group = group or #self.entries[entry].conditions
		cond = cond or #self.entries[entry].conditions[group]
		table.remove (self.entries[entry].conditions[group], cond)
		if #self.entries[entry].conditions[group] == 0 then
			table.remove(self.entries[entry].conditions,group)
		end
		if #self.entries[entry].conditions == 0 then
			self.addConditionGroup()
		end
	end
	
	setmetatable(self, {
	__tostring = function(self)
		return string.format('Schedule(%s) Entries: %i', tostring(self.cyclic), #self.entries)
	end,
    __len = function(self) return #self.entries end
	})
	return self
end

return lib
