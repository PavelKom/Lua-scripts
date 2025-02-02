--[[
	Train Station peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Display-Link-%28Peripheral%29
]]
local epf = require 'epf'
local expect = require 'cc.expect'
local expect, field, range = expect.expect, expect.field, expect.range

local lib = {}

local Peripheral = {}
local Schedule = {}

function Peripheral.__init(self)
	self.__getter = {
		mode = function() return self.isInAssemblyMode() end,
		name = function() return pcall(self.getStationName) end,
		present = function()
			local result, err = pcall(self.isTrainPresent)
			return result and err or false
		end,
		imminent = function()
			local result, err = pcall(self.isTrainImminent)
			return result and err or false
		end,
		enroute = function()
			local result, err = pcall(self.isTrainEnroute)
			return result and err or false
		end,
		train = function()
			local result, err = pcall(self.getTrainName)
			return result and err or nil
		end,
		hasSchedule = function()
			local result, err = pcall(self.hasSchedule)
			return result and err or false
		end,
		schedule = function() return Schedule.fromStation(self) end
	}
	
	self.__setter = {
		mode = function(assemblyMode) return pcall(self.setAssemblyMode,assemblyMode) end,
		name = function(name) return pcall(self.setStationName,name) end,
		train = function(name) return pcall(self.setTrainName,name) end,
		schedule = function(schedule)
			if type(schedule) == 'table' then
				return pcall(self.setSchedule,schedule)
			elseif type(schedule) == 'Schedule' then
				schedule.toStation(self)
			end
		end,
	}
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_Station", "Train Station")

--[[
Train station schedule data.
Instructions, conditions.
Methods for correcting incorrect data and adding missing data.
Note: on Minecraft 1.19.2, an incorrect schedule could lead to a world crash, after which only a backup could help.
On newer versions, this error has not occurred (yet).
]]
lib.INSTRUCTION_NAMES = {
-- Create
destination = "create:destination",
rename = "create:rename",
throttle = "create:throttle",
-- Create Railways Navigator
travel_section = "createrailwaysnavigator:travel_section",
reset_timings = "createrailwaysnavigator:reset_timings",
-- Create Steam 'n' Rails
redstone_link = "railways:redstone_link",
waypoint_destination = "railways:waypoint_destination",
}
lib.CONDITION_NAMES = {
delay = "create:delay",
time = "create:time_of_day",
fluid = "create:fluid_threshold",
item = "create:item_threshold",
redstone = "create:redstone_link",
player = "create:player_count",
idle = "create:idle",
unloaded = "create:unloaded",
powered = "create:powered",
-- Create Crafts & Additions
energy = "createaddition:energy_threshold",
-- Create Railways Navigator
dynamic = "createrailwaysnavigator:dynamic_delay",
separation = "createrailwaysnavigator:train_separation",
-- Create Steam 'n' Rails
loaded = "railways:loaded",
}
-- Default data for item, fluid and redstone link
local DEFAULT_ITEM = {id="minecraft:air",count=1}
local DEFAULT_FLUID = {id="minecraft:air",count=1}
local DEFAULT_REDSTONE_LINK = {{id="minecraft:air",count=1},{id="minecraft:air",count=1}}
setmetatable(DEFAULT_ITEM, {__tostring = serializeJSON})
setmetatable(DEFAULT_FLUID, {__tostring = serializeJSON})
setmetatable(DEFAULT_REDSTONE_LINK, {__tostring = serializeJSON})

-- Warn message if require
local function warn2(no_warn, ...)
	if no_warn then return end
	print(...)
end
-- Check data (name, type, range)
local function VALUE_NIL_VALIDATE(no_warn, info, tbl, name, default, _type, _min, _max)
	if type(tbl) ~= 'table' then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data type is %s (expect table). Generating new data.", info, type(tbl)))
		tbl = {}
	end
	if name and tbl[name] == nil then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data[%s] is missing. Setting default value (%s)", info, tostring(name), tostring(default)))
		tbl[name] = default
	elseif _type and type(tbl[name]) ~= _type then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data.%s data type is %s (expect %s). Setting default value (%s)", info, tostring(name), type(tbl[name]), _type, tostring(default)))
		tbl[name] = default
	elseif type(tbl[name]) == 'number' and (_min ~= nil or _max ~= nil) then
		local result, err = pcall(range, tbl[name], _min, _max)
		if not result then
			warn2(no_warn, string.format("[Create.Schedule] '%s' data.%s% (%f) is outside of the allowed range (%f...%f). Setting default value (%s)",
					info, tostring(name), tbl[name], _min or -math.huge, _max or math.huge, tostring(default)))
			tbl[name] = default
		end
	end
	return tbl
end

-- Read schedule instruction/condition data and validate it
lib.SCHEDULE_DATA_VALIDATE = {
-- INSTRUCTIONS
["create:destination"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:destination", tbl, 'text', '*', 'string')
	return tbl
end,
["create:rename"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:rename", tbl, 'text', 'INVALID_SCHEDULE_NAME', 'string')
	return tbl
end,
["create:throttle"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:throttle", tbl, 'value', 5, 'number')
	return tbl
end,
-- Create Railways Navigator
["createrailwaysnavigator:travel_section"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:travel_section", tbl, 'usable', true, 'boolean')
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:travel_section", tbl, 'include_previous_station', true, 'false')
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:travel_section", tbl, 'train_group', "", 'string')
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:travel_section", tbl, 'train_line', "", 'string')
	return tbl
end,
["createrailwaysnavigator:reset_timings"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:reset_timings", tbl)
	return tbl
end,
-- Create Steam 'n' Rails
["railways:redstone_link"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "railways:redstone_link", tbl, 'frequency', DEFAULT_REDSTONE_LINK, 'table')
	tbl.frequency[1].count = 1
	tbl.frequency[2].count = 1
	VALUE_NIL_VALIDATE(no_warn, "railways:redstone_link", tbl, 'power', 15, 'number', 0, 15)
	return tbl
end,
["railways:waypoint_destination"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "railways:waypoint_destination", tbl, 'text', "*", 'string')
	return tbl
end,


-- CONDITIONS
["create:delay"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:delay", tbl, 'value', 5, 'number')
	VALUE_NIL_VALIDATE(no_warn, "create:delay", tbl, 'time_unit', 1, 'number', 0, 2)
	return tbl
end,
["create:time_of_day"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:time_of_day", tbl, 'hour', 6, 'number', 0, 23)
	VALUE_NIL_VALIDATE(no_warn, "create:time_of_day", tbl, 'minute', 0, 'number', 0, 59)
	VALUE_NIL_VALIDATE(no_warn, "create:time_of_day", tbl, 'rotation', 0, 'number', 0, 9)
	return tbl
end,
["create:fluid_threshold"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:fluid_threshold", tbl, 'bucket', DEFAULT_FLUID, 'table')
	tbl.bucket.count = 1
	tbl.threshold = tonumber(tbl.threshold) or 0
	VALUE_NIL_VALIDATE(no_warn, "create:fluid_threshold", tbl, 'threshold', 1, 'number', 1)
	VALUE_NIL_VALIDATE(no_warn, "create:fluid_threshold", tbl, 'operator', 0, 'number', 0, 2)
	tbl.measure = 0 -- Only 0 allowed for fluids
	return tbl
end,
["create:item_threshold"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'item', DEFAULT_ITEM, 'table')
	tbl.item.count = 1
	tbl.threshold = tonumber(tbl.threshold) or 0
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'threshold', 1, 'string', 1)
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'operator', 0, 'number', 0, 2)
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'measure', 0, 'number', 0, 1)
	return tbl
end,
["create:redstone_link"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:redstone_link", tbl, 'frequency', DEFAULT_REDSTONE_LINK, 'table')
	tbl.frequency[1].count = 1
	tbl.frequency[2].count = 1
	VALUE_NIL_VALIDATE(no_warn, "create:redstone_link", tbl, 'inverted', 0, 'number', 0, 1)
	return tbl
end,
["create:player_count"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:player_count", tbl, 'count', 0, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "create:player_count", tbl, 'exact', 0, 'number', 0, 1)
	return tbl
end,
["create:idle"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:idle", tbl, 'value', 5, 'number')
	VALUE_NIL_VALIDATE(no_warn, "create:idle", tbl, 'time_unit', 1, 'number', 0, 2)
	return tbl
end,
["create:unloaded"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:unloaded", tbl)
	return tbl
end,
["create:powered"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:powered", tbl)
	return tbl
end,

-- Create Crafts & Additions
["createaddition:energy_threshold"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "createaddition:energy_threshold", tbl, 'threshold', 10, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "createaddition:energy_threshold", tbl, 'operator', 0, 'number', 0, 2)
	tbl.measure = 0 -- Only 0 allowed for energy (kFE)
	return tbl
end,

-- Create Railways Navigator
["createrailwaysnavigator:dynamic_delay"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:dynamic_delay", tbl, 'min', 0, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:dynamic_delay", tbl, 'value', 0, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:dynamic_delay", tbl, 'time_unit', 0, 'number', 0, 2)
	return tbl
end,
["createrailwaysnavigator:train_separation"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:train_separation", tbl, 'value', 0, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:train_separation", tbl, 'ticks', 0, 'number', 0)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:train_separation", tbl, 'time_unit', 0, 'number', 0, 2)
	VALUE_NIL_VALIDATE(no_warn, "createrailwaysnavigator:train_separation", tbl, 'train_filter', false, 'boolean')
	return tbl
end,

["railways:loaded"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "railways:loaded", tbl)
	return tbl
end,
}

for k, v in pairs(lib.INSTRUCTION_NAMES) do -- Bind destination as create:destination
	lib.SCHEDULE_DATA_VALIDATE[k] = lib.SCHEDULE_DATA_VALIDATE[v]
	lib.INSTRUCTION_NAMES[v] = v
end
for k, v in pairs(lib.CONDITION_NAMES) do
	lib.SCHEDULE_DATA_VALIDATE[k] = lib.SCHEDULE_DATA_VALIDATE[v]
	lib.CONDITION_NAMES[v] = v
end

setmetatable(lib.INSTRUCTION_NAMES, {__index = epf.GETTER_TO_LOWER(lib.INSTRUCTION_NAMES.throttle)})
setmetatable(lib.CONDITION_NAMES, {__index = epf.GETTER_TO_LOWER(lib.CONDITION_NAMES.idle)})
setmetatable(lib.SCHEDULE_DATA_VALIDATE, {__index = epf.GETTER_TO_LOWER(nil)})

-- Conditions only for destination
local IS_NEED_CONDITIONS = function(instruction_tbl)
	if instruction_tbl.id and instruction_tbl.id == "create:destination" then return true end
	return false
end

-- Recursive data validation
local SCHEDULE_BLOCKS_VALIDATE = {}
--[[function SCHEDULE_BLOCKS_VALIDATE.INSTRUCTION(dict, no_warm)
	expect(1, dict, 'table', 'nil')
	dict = dict or {}
	return lib.SCHEDULE_DATA_VALIDATE[lib.INSTRUCTION_NAMES[dict.id] ](
	{id=lib.INSTRUCTION_NAMES[dict.id],data=dict.data}, no_warn)
end

]]

local function fix_threshold(schedule)
  for _,entry in pairs(schedule.entries) do-- List of entries
    for _, condition_group in pairs(entry.conditions) do -- List of condition groups
      for _, condition in pairs(condition_group) do -- List of conditions
        if condition.id == "create:item_threshold" or
           condition.id == "create:fluid_threshold" then
          condition.data.threshold = tostring(condition.data.threshold)
        end
      end
    end
  end
  return schedule
end
SCHEDULE_BLOCKS_VALIDATE = {
	SCHEDULE = function(dict, no_warn)
		expect(1, dict, 'table', 'nil')
		dict = dict or {}
		dict.cyclic = SCHEDULE_BLOCKS_VALIDATE.CYCLIC(dict.cyclic, no_warn)
		dict.entries = SCHEDULE_BLOCKS_VALIDATE.ENTRIES(dict.entries, no_warn)
		return dict
	end,
	CYCLIC = function(val, no_warn)
		return not not val
	end,
	ENTRIES = function(arr, no_warn)
		expect(1, arr, 'table', 'nil')
		arr = arr or {}
		local _arr = {}
		for _, v in pairs(arr) do
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.ENTRY(v, no_warn)
		end
		if #_arr == 0 then
			warn2(no_warn, "[Create.Schedule] schedule.entries is empty. Repair.")
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.ENTRY({}, no_warn)
		end
		return _arr
	end,
	ENTRY = function(dict, no_warn)
		expect(1, dict, 'table', 'nil')
		dict = dict or {}
		dict.instruction = SCHEDULE_BLOCKS_VALIDATE.INSTRUCTION(dict.instruction, no_warn)
		if IS_NEED_CONDITIONS(dict.instruction) then
			dict.conditions = SCHEDULE_BLOCKS_VALIDATE.CONDITIONS(dict.conditions, no_warn)
		else
			dict.conditions = nil
		end
		return dict
	end,
	INSTRUCTION = function(dict, no_warn)
		expect(1, dict, 'table', 'nil')
		dict = dict or {}
		dict.id = lib.INSTRUCTION_NAMES[dict.id]
		dict.data = lib.SCHEDULE_DATA_VALIDATE[dict.id](dict.data, no_warn)
		return dict
	end,
	CONDITIONS = function(arr, no_warn)
		expect(1, arr, 'table', 'nil')
		arr = arr or {}
		local _arr = {}
		for _, v in pairs(arr) do
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.CONDITION_GROUP(v, no_warn)
		end
		if #_arr == 0 then
			warn2(no_warn, "[Create.Schedule] schedule.entries[].conditions is empty. Repair.")
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.CONDITION_GROUP({}, no_warn)
		end
		return _arr
	end,
	CONDITION_GROUP = function(arr, no_warn)
		expect(1, arr, 'table', 'nil')
		arr = arr or {}
		local _arr = {}
		for _, v in pairs(arr) do
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.CONDITION(v, no_warn)
		end
		if #_arr == 0 then
			warn2(no_warn, "[Create.Schedule] schedule.entries[].conditions[] is empty. Repair.")
			_arr[#_arr+1] = SCHEDULE_BLOCKS_VALIDATE.CONDITION({}, no_warn)
		end
		return _arr
	end,
	CONDITION = function(dict, no_warn)
		expect(1, dict, 'table', 'nil')
		dict = dict or {}
		dict.id = lib.CONDITION_NAMES[dict.id]
		dict.data = lib.SCHEDULE_DATA_VALIDATE[dict.id](dict.data, no_warn)
		return dict
	end,
}

function Schedule.new(data)
	local self = {schedule = data or {}}
	-- Validate schedule
	self.validate = function(no_warn) -- Fix broken parts of schedule
		self.schedule = SCHEDULE_BLOCKS_VALIDATE.SCHEDULE(self.schedule, no_warn)
	end
	
	-- Create schedule blocks
	self.createEntry = function(instruction, conditions, no_warn)
		return SCHEDULE_BLOCKS_VALIDATE.ENTRY({instruction=instruction,conditions=conditions}, no_warn)
	end
	self.createInstruction = function(id, data, no_warn) -- Id types:  'create:destination', 'destination', lib.INSTRUCTION_NAMES.DESTINATION
		return SCHEDULE_BLOCKS_VALIDATE.INSTRUCTION({id=id,data=data}, no_warn)
	end
	self.createConditions = function(data, no_warn) -- data is array-like table with condition groups
		return SCHEDULE_BLOCKS_VALIDATE.CONDITIONS(data, no_warn)
	end
	self.createConditionGroup = function(data, no_warn) -- data is array-like table with conditions
		return SCHEDULE_BLOCKS_VALIDATE.CONDITION_GROUP(data, no_warn)
	end
	self.createCondition = function(id, data, no_warn) -- Id types:  'create:delay', 'delay', lib.CONDITION_NAMES.DELAY
		return SCHEDULE_BLOCKS_VALIDATE.CONDITION({id=id,data=data}, no_warn)
	end
	
	-- Add blocks
	self.addEntry = function(instruction, conditions, no_warn)
		local entry = SCHEDULE_BLOCKS_VALIDATE.ENTRY({instruction=instruction,conditions=conditions}, no_warn)
		self.schedule.entries[#self.schedule.entries] = entry
	end
	self.addConditionGroup = function(entry_id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		local group = SCHEDULE_BLOCKS_VALIDATE.CONDITION_GROUP(data, no_warn)
		local index = #self.schedule.entries[entry_id]+1
		self.schedule.entries[entry_id][index] = group
	end
	self.addCondition = function(entry_id, group_id, id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		group_id = tonumber(group_id) or #self.schedule.entries[entry_id]
		range(group_id, 1, #self.schedule.entries[entry_id])
		local cond = SCHEDULE_BLOCKS_VALIDATE.CONDITION({id=id,data=data}, no_warn)
		local index = #self.schedule.entries[entry_id][group_id]+1
		self.schedule.entries[entry_id][group_id][index] = cond
	end
	
	-- Set blocks
	self.setEntries = function(data, no_warn)
		self.schedule.entries = ENTRIES(data, no_warn)
	end
	self.setEntry = function(entry_id, instruction, conditions, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		local entry = SCHEDULE_BLOCKS_VALIDATE.ENTRY({instruction=instruction,conditions=conditions}, no_warn)
		self.schedule.entries[entry_id] = entry
	end
	self.setInstruction = function(entry_id, id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		local instruction = SCHEDULE_BLOCKS_VALIDATE.INSTRUCTION({id=id,data=data}, no_warn)
		self.schedule.entries[entry_id].instruction = instruction
	end
	self.setConditions = function(entry_id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		local conditions = SCHEDULE_BLOCKS_VALIDATE.CONDITIONS(data, no_warn)
		self.schedule.entries[entry_id].conditions = conditions
	end
	self.setConditionGroup = function(entry_id, group_id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		group_id = tonumber(group_id) or #self.schedule.entries[entry_id]
		range(group_id, 1, #self.schedule.entries[entry_id])
		local group = SCHEDULE_BLOCKS_VALIDATE.CONDITION_GROUP(data, no_warn)
		self.schedule.entries[entry_id][group_id] = group
	end
	self.setCondition = function(entry_id, group_id, cond_id, id, data, no_warn)
		entry_id = tonumber(entry_id) or #self.schedule.entries
		range(entry_id, 1, #self.schedule.entries)
		group_id = tonumber(group_id) or #self.schedule.entries[entry_id]
		range(group_id, 1, #self.schedule.entries[entry_id])
		cond_id = tonumber(cond_id) or #self.schedule.entries[entry_id][group_id]
		range(cond_id, 1, #self.schedule.entries[entry_id][group_id])
		local condition = SCHEDULE_BLOCKS_VALIDATE.CONDITION({id=id,data=data}, no_warn)
		self.schedule.entries[entry_id][group_id][cond_id] = condition
	end
	
	self.toStation = function(station)
		Schedule.toStation(self, station)
	end
	self.toJson = function()
		return Schedule.toJson(self)
	end
	
	self.validate(true)
	
	setmetatable(self, {
		__tostring = function(self)
			return string.format("%s %s", type(self), Schedule.toJson(self))
		end,
		__type = "Schedule",
		--__subtype = "utility",
	})

	return self
end
function Schedule.fromStation(station)
	local result, err = pcall(peripheral.call, peripheral.getName(station), 'getSchedule')
	if result then
		return Schedule(err)
	else
		return nil
	end
end
function Schedule.toStation(schedule, station)
	local tbl
	if type(schedule) == 'Schedule' then
		tbl = schedule.schedule
	else
		tbl = schedule
	end
	tbl = fix_threshold(tbl)
	local result, err = pcall(peripheral.call, peripheral.getName(station), 'setSchedule', tbl)
	if not result then print(err) end
end
function Schedule.toJson(schedule)
	if schedule == nil then return textutils.serializeJSON(Schedule().schedule) end
	return textutils.serializeJSON(schedule.schedule)
end
function Schedule.fromJson(tbl)
	if tbl == nil then return Schedule() end
	if type(tbl) == 'string' then
		tbl = textutils.unserializeJSON(tbl)
	end
	return Schedule(tbl)
end

lib.TrainStation = Peripheral
lib.Schedule = setmetatable(Schedule, {__call=function(self, ...) return Schedule.new(...) end,})
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__name="TrainStation",
	__type="library",
	__subtype="peripheral wrapper library"
})
return lib
