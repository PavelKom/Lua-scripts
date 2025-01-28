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
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Speedometer, 'Speedometer')
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
		__type = "Speedometer",
		__subtype = "peripheral",
	})
	Speedometer.__items[self.name] = self
	if not Speedometer.default then Speedometer.default = self end
	return self
end
Speedometer.delete = function(name)
	if name then Speedometer.__items[name] = nil end
end
lib.Speedometer=setmetatable(Speedometer,{__call=Speedometer.new,__type = "peripheral",__subtype="Create_Speedometer",})

-- Stressometer
local Stressometer = {}
Stressometer.__items = {}
function Stressometer:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Stressometer, 'Stressometer')
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
		__type = "Stressometer",
		__subtype = "peripheral",
	})
	Stressometer.__items[self.name] = self
	if not Stressometer.default then Stressometer.default = self end
	return self
end
Stressometer.delete = function(name)
	if name then Stressometer.__items[name] = nil end
end
lib.Stressometer=setmetatable(Stressometer,{__call=Stressometer.new,__type = "peripheral",__subtype="Create_Stressometer",})

-- Rotation Speed Controller
local RotationSpeedController = {}
RotationSpeedController.__items = {}
function RotationSpeedController:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, RotationSpeedController, 'Rotation Speed Controller')
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
		__type = "Rotation Speed Controller",
		__subtype = "peripheral",
	})
	RotationSpeedController.__items[self.name] = self
	if not RotationSpeedController.default then RotationSpeedController.default = self end
	return self
end
RotationSpeedController.delete = function(name)
	if name then RotationSpeedController.__items[name] = nil end
end
lib.RotationSpeedController=setmetatable(RotationSpeedController,{__call=RotationSpeedController.new,__type = "peripheral",__subtype="Create_RotationSpeedController",})

-- Display Link
local DisplayLink = {}
DisplayLink.__items = {}
function DisplayLink:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, DisplayLink, 'Display Link')
	if wrapped ~= nil then return wrapped end

	self.pos = getset.metaPos(self.object.getCursorPos, self.object.setCursorPos)
	
	self.__getter = {
		size = function() return {self.object.getSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		color = function() return self.object.isColor() end,
		
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
			if self.object == nil then error("[DisplayLink.update] Can't update peripheral object") end
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
		__type = "Display Link",
		__subtype = "peripheral",
	})
	DisplayLink.__items[self.name] = self
	if not DisplayLink.default then DisplayLink.default = self end
	return self
end
DisplayLink.delete = function(name)
	if name then DisplayLink.__items[name] = nil end
end
lib.DisplayLink=setmetatable(DisplayLink,{__call=DisplayLink.new,__type = "peripheral",__subtype="Create_DisplayLink",})

-- Sequenced Gearshift
local SequencedGearshift = {}
SequencedGearshift.__items = {}
function SequencedGearshift:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, SequencedGearshift, 'Sequenced Gearshift')
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
		__type = "Sequenced Gearshift",
		__subtype = "peripheral",
	})
	SequencedGearshift.__items[self.name] = self
	if not SequencedGearshift.default then SequencedGearshift.default = self end
	return self
end
SequencedGearshift.delete = function(name)
	if name then SequencedGearshift.__items[name] = nil end
end
lib.SequencedGearshift=setmetatable(SequencedGearshift,{__call=SequencedGearshift.new,__type = "peripheral",__subtype="Create_SequencedGearshift",})


-- Sequenced Gearshift
local TrainStation = {}
TrainStation.__items = {}
function TrainStation:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, TrainStation, 'Train Station')
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
		schedule = function() return lib.Schedule.fromStation(self) end
	}
	
	self.__setter = {
		mode = function(assemblyMode) return pcall(self.object.setAssemblyMode,assemblyMode) end,
		station = function(name) return pcall(self.object.setStationName,name) end,
		train = function(name) return pcall(self.object.setTrainName,name) end,
		schedule = function(schedule) return pcall(self.object.setSchedule,schedule.toStation(self)) end,
	}
	
	
	self.assemble = function() return pcall(self.object.assemble) end
	self.disassemble = function() return pcall(self.object.disassemble) end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Train Station",
		__subtype = "peripheral",
	})
	TrainStation.__items[self.name] = self
	if not TrainStation.default then TrainStation.default = self end
	return self
end
TrainStation.delete = function(name)
	if name then TrainStation.__items[name] = nil end
end
lib.TrainStation=setmetatable(TrainStation,{__call=TrainStation.new,__type = "peripheral",__subtype="Create_Station",}})

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
setmetatable(lib.INSTRUCTION_NAMES, {__index = getset.GETTER_TO_LOWER(lib.INSTRUCTION_NAMES.destination)})

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
setmetatable(lib.CONDITION_NAMES, {__index = getset.GETTER_TO_LOWER(lib.CONDITION_NAMES.idle)})

local DEFAULT_ITEM = {id="minecraft:stone",count=1}
local DEFAULT_FLUID = {id="minecraft:water_bucket",count=1}
local DEFAULT_REDSTONE_LINK = {{id="minecraft:air",count=1},{id="minecraft:air",count=1}}
setmetatable(DEFAULT_ITEM, {__tostring = serializeJSON})
setmetatable(DEFAULT_FLUID, {__tostring = serializeJSON})
setmetatable(DEFAULT_REDSTONE_LINK, {__tostring = serializeJSON})

local function warn2(no_warn, ...)
	if no_warn then return end
	print(...)
end

local function VALUE_NIL_VALIDATE(no_warn, info, tbl, name, default, _type, _min, _max)
	if type(tbl) ~= 'table' then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data type is %s (expect table). Generating new data.", info, type(tbl)))
		tbl = {}
	end
	if name and tbl[name] == nil then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data[%s] is missing. Setting default value (%s)", info, tostring(name), tostring(default)))
		tbl[name] = default
	elseif _type and type(tbl[name]) ~= _type then
		warn2(no_warn, string.format("[Create.Schedule] '%s' data.%s% data type is %s (expect %s). Setting default value (%s)", info, tostring(name), type(tbl[name]), _type, tostring(default)))
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
	ALUE_NIL_VALIDATE(no_warn, "create:fluid_threshold", tbl, 'threshold', 1, 'number', 1)
	VALUE_NIL_VALIDATE(no_warn, "create:fluid_threshold", tbl, 'operator', 0, 'number', 0, 2)
	tbl.measure = 0 -- Only 0 allowed for fluids
	return tbl
end,
["create:item_threshold"] = function(tbl, no_warn)
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'item', DEFAULT_ITEM, 'table')
	tbl.item.count = 1
	VALUE_NIL_VALIDATE(no_warn, "create:item_threshold", tbl, 'threshold', 1, 'number', 1)
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
setmetatable(lib.SCHEDULE_DATA_VALIDATE, {__index = getset.GETTER_TO_LOWER(nil)})

--[[
{
	"cyclic": true, -- bool
    "entries": { -- array
		{
			"instruction": { -- dict
                "data": {
                    "text": "Track Station"
                },
                "id": "create:destination"
            },
            "conditions": { -- array
				{ -- condition group, 
					{ -- condition, dict
                        "data": {
                            "value": 5,
                            "time_unit": 1
                        },
                        "id": "create:delay"
                    },
                    {
                        "data": {
                            "rotation": 5,
                            "hour": 8,
                            "minute": 0
                        },
                        "id": "create:time_of_day"
                    },
				
				
				
				}
			}

		},
	}
}
]]

-- Conditions only for destination
local IS_NEED_CONDITIONS = function(instruction_tbl)
	if instruction_tbl.id == "create:destination" then return true end
	return false
end

local SCHEDULE_BLOCKS_VALIDATE = {}
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
		return lib.SCHEDULE_DATA_VALIDATE[lib.INSTRUCTION_NAMES[dict.id]]({id=lib.INSTRUCTION_NAMES[dict.id],data=data}, no_warn)
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
		return lib.SCHEDULE_DATA_VALIDATE[lib.CONDITION_NAMES[dict.id]]({id=lib.CONDITION_NAMES[dict.id],data=dict.data}, no_warn)
	end,
}







local Schedule = {}
function Schedule:new()
	local self = {schedule = {}}
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
		__type = "Create Train Schedule",
		__subtype = "utility",
	})

	return self
end
function Schedule.toJson(schedule)
	if schedule == nil then return "{}" end
	return textutils.serializeJSON(schedule.schedule)
end
function Schedule.fromJson(tbl)
	if tbl == nil then return Schedule() end
	if type(tbl) == 'string' then
		tbl = textutils.unserializeJSON(tbl)
	end
	local s = Schedule()
	s.schedule = tbl
	s.validate()
	return s
end

function Schedule.fromStation(station)
	local self = Schedule()
	local result, err = pcall(peripheral.call, peripheral.getName(station.object), 'getSchedule')
	if result then
		self.schedule = err
		self.validate(true)
	else
		warn2(_, "Can't load schedule from station '%s'. Reason: %s", station.name, err)
	end
	
	return self
end
function Schedule.toStation(schedule, station)
	if type(schedule) ~= "Create Train Schedule" then
		local s = Schedule()
		s.schedule = schedule
		schedule = s
	end
	schedule.validate(true)
	local result, err = pcall(peripheral.call, peripheral.getName(station.object), 'setSchedule', schedule.schedule)
	if not result then
		warn2(_, "Can't set schedule to station '%s'. Reason: %s", station.name, err)
	end
end
lib.Schedule=setmetatable(Schedule,{__call=Schedule.new,__type = "utility",__subtype="Schedule",})


return lib
