--[[
	Trigger Utility library by PavelKom.
	Version: 0.7b
	Triggers for RS and ME Bridges.
]]
local getset = require 'getset_util'
local expect_ = require "cc.expect"
local expect = expect_.expect

local lib = {}
lib.DEFAULT_AMOUNT = 1000

lib.TASKRESULT = {
	[1]= 'start crafting',
	[0] = 'no materials',
	[-1] = 'conditions not met',
	[-2] = 'already crafting',
	[-3] = 'invalid task',
	[-4] = 'item not craftable'
}
setmetatable(lib.TASKRESULT, {__index = lib.TASKRESULT[1]})

lib.OP = {
LT = 'LT',
LE = 'LE',
EQ = 'EQ',
NE = 'NE',
GE = 'GE',
GT = 'GT',
}
setmetatable(lib.OP, {__index = getset.GETTER_TO_UPPER(lib.OP.LT)})
local OP_LAMBDA = {
LT = function(a,b) return a <  b end,
LE = function(a,b) return a <= b end,
EQ = function(a,b) return a == b end,
NE = function(a,b) return a ~= b end,
GE = function(a,b) return a >= b end,
GT = function(a,b) return a >  b end,
}
setmetatable(OP_LAMBDA, {__index = getset.GETTER_TO_UPPER(OP_LAMBDA.LT)})
lib.MATH = {
MUL = 'MUL',
DIV = 'DIV',
ADD = 'ADD',
SUB = 'SUB',
ABS = 'ABS',
NEG = 'NEG',
POW = 'POW',
MOD = 'MOD',
}
setmetatable(lib.MATH, {__index = getset.GETTER_TO_UPPER(lib.MATH.MUL)})
local MATH_LAMBDA = {
MUL = function(a,b) return a * b end,
DIV = function(a,b) return a / b end,
ADD = function(a,b) return a + b end,
SUB = function(a,b) return a - b end,
ABS = function(a,b) return math.abs(a) end,
NEG = function(a,b) return 0 - a end,
POW = function(a,b) return a ^ b end,
MOD = function(a,b) return a % b end,
}
setmetatable(MATH_LAMBDA, {__index = getset.GETTER_TO_UPPER(MATH_LAMBDA.MUL)})
lib.LOGIC_GATE = {
AND='AND',
OR='OR',
NAND='NAND',
NOR='NOR',
XOR='XOR',
XNOR='XNOR',
}
setmetatable(lib.LOGIC_GATE, {__index = getset.GETTER_TO_UPPER(lib.LOGIC_GATE.AND)})
local LOGIC_LAMBDA = {
AND  = function(a,b) return a and b end,
OR   = function(a,b) return a or b end,
NAND = function(a,b) return not (a and b) end,
NOR  = function(a,b) return not (a or b) end,
XOR  = function(a,b) return not (not a == not b) end,
XNOR = function(a,b) return not a == not b end,
}
setmetatable(LOGIC_LAMBDA, {__index = getset.GETTER_TO_UPPER(LOGIC_LAMBDA.AND)})

local TO_STRING_LAMBDA = {
LT = function(a,b) return string.format("%s < %s", a,b) end,
LE = function(a,b) return string.format("%s <= %s", a,b) end,
EQ = function(a,b) return string.format("%s == %s", a,b) end,
NE = function(a,b) return string.format("%s ~= %s", a,b) end,
GE = function(a,b) return string.format("%s >= %s", a,b) end,
GT = function(a,b) return string.format("%s > %s", a,b) end,
MUL = function(a,b) return string.format("%s * %s", a,b) end,
DIV = function(a,b) return string.format("%s / %s", a,b) end,
ADD = function(a,b) return string.format("%s + %s", a,b) end,
SUB = function(a,b) return string.format("%s - %s", a,b) end,
ABS = function(a,b) return string.format("|%s|", a) end,
NEG = function(a,b) return string.format("0 - %s", a) end,
POW = function(a,b) return string.format("%s ^ %s", a,b) end,
MOD = function(a,b) return string.format("%s %% %s", a,b) end,
}

--lib.ITEM_TYPE = {'ITEM', 'FLUID', 'GAS', 'CONSTANT'}

local Trigger = {}

	-- item1 = {name, fingerprint, nbt}
	-- math_op1
	-- const1
	
	-- op
	
	-- item2 = {name, fingerprint, nbt} or nil
	-- math_op2
	-- const2
	
	-- logic
	
	-- trigger
	
	-- T1 = get(item1)[+-*/]const1 [~=<>] get(item2)[+-*/]const2
	-- T2 = trigger.test()
	-- T = T1[and/or]T2
function Trigger:new(item1, math_op1, const1, op, item2, math_op2, const2, logic, trigger)
	expect(1, item1, "table", "nil")
	expect(2, math_op1, "string", "nil")
	expect(3, const1, "number", "nil")
	expect(4, op, "string", "nil")
	expect(5, item2, "table", "nil")
	expect(6, math_op2, "string", "nil")
	expect(7, const2, "number", "nil")
	expect(8, logic, "string", "nil")
	expect(9, trigger, "Trigger", "table", "nil")
	local self = {
		item1=item1,
		math_op1=math_op1 or lib.MATH.MUL,
		const1=const1 or 1,
		
		op=op or lib.OP.LT,
		
		item2=item2,
		math_op2=math_op2 or lib.MATH.MUL,
		const2=const2 or lib.DEFAULT_AMOUNT,
		logic=logic or lib.LOGIC_GATE.AND, -- T1 and/or T2
		trigger=trigger, -- Other trigger or constant
	}
	
	self.test = function(bridge)
		local amount1 = self.const1
		if self.item1 ~= nil then -- Get item1 in bridge
			amount1 = MATH_LAMBDA[self.math_op1](bridge.object.getItem(self.item1), amount1)
		end
		local amount2 = self.const2
		if self.item2 ~= nil then
			amount2 = MATH_LAMBDA[self.math_op2](bridge.object.getItem(self.item2), amount2)
		end
		
		local result = OP_LAMBDA[self.op](amount1, amount2)
		if self.trigger ~= nil then
			result = LOGIC_LAMBDA[self.logic](result, self.trigger.test(bridge))
		end
		return result
	end
	self.toJson = function()
		return Trigger.toJson(self)
	end
	
	setmetatable(self, {
	__tostring = function(self)
		return textutils.serializeJSON(Trigger.toJson(self))
	end,
	__type='Trigger',})
	return self
end
function Trigger.fromJson(tbl)
	if tbl == nil then return nil end
	if type(tbl) == 'string' then
		tbl = textutils.unserializeJSON(tbl)
	end
	return Trigger:new(
		tbl.item1,
		tbl.math_op1,
		tbl.const1,
		tbl.op,
		tbl.item2,
		tbl.math_op2,
		tbl.const2,
		tbl.logic,
		Trigger.fromJson(tbl.trigger)
	)
end
function Trigger.toJson(trigger)
	if trigger == nil then return nil end
	return {
	item1=trigger.item1,
	math_op1=trigger.math_op1,
	const1=trigger.const1,
	op=trigger.op,
	item2=trigger.item2,
	math_op2=trigger.math_op2,
	const2=trigger.const2,
	logic=trigger.logic,
	trigger=Trigger.toJson(trigger.trigger)
	}
end
lib.Trigger=setmetatable(Trigger,{__call=Trigger.new})
--lib=setmetatable(lib,{__call=Trigger.new})

--[[Examples: Trigger(item1, math_op1, const1, op, item2, math_op2, const2, logic, trigger)
t = Trigger({name='minecraft:cobblestone'}})
	'minecraft:cobblestone'*1 < 1000
	
t = Trigger({name='minecraft:furnace',_,_,_,{name='minecraft:cobblestone'},_,8)
	'minecraft:furnace'*1 < 'minecraft:cobblestone'*8
	
t = Trigger({name='minecraft:charcoal'})
	'minecraft:charcoal'*1 < 1000
t2 = Trigger({name='minecraft:oak_log'}, _,_, lib.OP.GE)
	'minecraft:oak_log'*1 > 1000

t.trigger = t2
	('minecraft:charcoal'*1 < 1000) and ('minecraft:oak_log'*1 > 1000)
	
task = CraftTask('minecraft:charcoal',_,_,_,t2)

]]


local CraftTask = {}
function CraftTask:new(item, isFluid, amount, batch, trigger)
	expect(1, item, "table", "string")
	expect(2, isFluid, "boolean", "nil")
	expect(3, amount, "number", "nil")
	expect(4, batch, "number", "nil")
	expect(5, trigger, "Trigger", "table", "nil")
	
	if type(item) == 'string' then
		item = {name=item}
	end
	amount = amount or lib.DEFAULT_AMOUNT
	batch = batch or amount
	if trigger == nil then
		trigger = Trigger(item,_,_,_,_,_,amount)
	end
	local self = {item=item, isFluid=isFluid or false, amount=amount,batch=batch,trigger=trigger} 
	
	self.test = function(bridge)
		return self.trigger.test(bridge)
	end
	self.craft = function(bridge, callback)
		
		expect(2, callback, "function", "nil")
		if not bridge.isItemCraftable(self.item) then
			if callback then
				callback(-4, self.item)
			end
			return -4
		end
		if bridge.isItemCrafting(self.item) then -- Item already crafting
			if callback then
				callback(-2, self.item)
			end
			return -2
		end
		local result = self.trigger.test(bridge)
		if not result then -- Conditions not met
			if callback then
				callback(-1, self.item)
			end
			return -1
		end
		local result = 0
		if self.isFluid then
			result = self.craftFluid(bridge)
		else
			result = self.craftItem(bridge)
		end
		if callback then
			callback(result, self.item)
		end
		return result
	end
	self.craftItem = function(bridge)
		local t = {name=self.item.name, nbt=self.item.nbt, fingerprint=self.item.fingerprint, count=self.batch}
		local result = bridge.craftItem(t)
		while t.count > 1 and not result do
			t.count = math.ceil(t.count/10)
			result = interface.craftItem(t)
		end
		if result then return t.count end -- Start crafting
		return 0 -- No materials
	end
	self.craftFluid = function(bridge)
		local t = {name=self.item.name, nbt=self.item.nbt, fingerprint=self.item.fingerprint, count=self.batch}
		local result = bridge.craftItem(t)
		while t.count > 0.001 and not result do
			t.count = math.ceil((t.count/10)*1000)/1000
			result = interface.craftFluid(t)
		end
		if result then return t.count end
		return 0
	end
	self.toJson = function()
		return CraftTask.toJson(self)
	end
	
	setmetatable(self, {
	__tostring = function(self)
		return textutils.serializeJSON(CraftTask.toJson(self))
	end,
	__type='CraftTask'})
	return self
end
function CraftTask.fromJson(tbl)
	if tbl == nil then return nil end
	if type(tbl) == 'string' then
		tbl = textutils.unserializeJSON(tbl)
	end
	return CraftTask:new(
		tbl.item,
		tbl.isFluid,
		tbl.amount,
		tbl.batch,
		Trigger.fromJson(tbl.trigger)
	)
end
function CraftTask.toJson(task)
	if task == nil then return nil end
	return {
	item=task.item,
	isFluid=task.isFluid,
	amount=task.amount,
	batch=task.batch,
	trigger=Trigger.toJson(task.trigger)
	}
end
lib.CraftTask=setmetatable(CraftTask,{__call=CraftTask.new})


return lib
