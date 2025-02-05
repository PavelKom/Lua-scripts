--[[
	Trigger utility for ME and RS Bridges
	Author: PavelKom
	Version: 0.2
]]

local epf = require 'epf'
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
	[-4] = 'item not craftable',
	[-5] = 'excees'
}
setmetatable(lib.TASKRESULT, {__index = lib.TASKRESULT[1]})

-- Operator names
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
--			  00| 01| 10| 11
AND='AND',	-- 0|  0|  0|  1
OR='OR',	-- 0|  1|  1|  1
NAND='NAND',-- 1|  1|  1|  0
NOR='NOR',	-- 1|  0|  0|  0
XOR='XOR',	-- 0|  1|  1|  0
XNOR='XNOR',-- 1|  0|  0|  1
}
setmetatable(lib.LOGIC_GATE, {__index = getset.GETTER_TO_UPPER(lib.LOGIC_GATE.AND)})
local function _stubA(a) return false end
local lazyA = {
	AND = function(a)
		if not a then return true, false end
		return nil
	end,
	OR = function(a)
		if a then return true, true end
		return nil
	end,
	NAND = _stubA,
	NOR = function(a)
		if a then return true, false end
		return nil
	end,
	XOR = _stubA,
	XNOR = _stubA,
}

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

--[[
	TriggerGroup(OP)
	|			|
	Trigger	OP	Trigger OP Trigger ...
	
	TriggerGroup(OP)
	|				|
	TriggerGroup OP	TriggerGroup
	
	Task
	|
	TriggerGroup
	
	Task
	|
	Trigger
]]
local Trigger = {}
function Trigger:new(item1, math_op1, const1, op, item2, math_op2, const2)
	expect(1, item1, "table", "nil")
	expect(2, math_op1, "string", "nil")
	expect(3, const1, "number", "nil")
	expect(4, op, "string", "nil")
	expect(5, item2, "table", "nil")
	expect(6, math_op2, "string", "nil")
	expect(7, const2, "number", "nil")
	
	local t = {
		A=item1,
		opA=math_op1 or lib.MATH.MUL,
		cA=const1 or 1,
		
		op=op or lib.OP.LT,
		
		B=item2,
		opB=math_op2 or lib.MATH.MUL,
		cB=const2 or lib.DEFAULT_AMOUNT
	}
	t.test = function(bridge) return Trigger.test(t, bridge) end
	
	return setmetatable(t, Trigger)
end
function Trigger.test(self, bridge)
	local a = self.cA
	if self.A then
		a = MATH_LAMBDA[self.opA](bridge.getItem(self.A), a)
	end
	local b = self.cB
	if self.B then
		b = MATH_LAMBDA[self.opB](bridge.getItem(self.B), b)
	end
	return OP_LAMBDA[self.op](a, b)
end
function Trigger.toJson(self)
	return textutils.serializeJSON(Trigger.export(self))
end
function Trigger.fromJson(tbl)
	if tbl == nil then return nil end
	local _tbl = tbl
	if type(_tbl) == 'string' then
		_tbl = textutils.unserializeJSON(_tbl)
	end
	return Trigger:new(	tbl.A,tbl.opA,tbl.cA,
						tbl.op,
						tbl.B,tbl.opB,tbl.cB)
end
function Trigger.export(self)
	return {
		A=self.A,
		opA=self.opA,
		cA=self.cA,
		op=self.op,
		B=self.B,
		opB=self.opB,
		cB=self.cB,
		type="Trigger",
	}
end
lib.Trigger = setmetatable(Trigger,{
	__tostring = function(self)
		if Trigger == self then return "Trigger constructor" end
		return Trigger.toJson(self)
	end,
	__subtype='Trigger',
	__name = "utility",
	__call = Trigger.new,
})

local TriggerGroup = {}
function TriggerGroup:new(op, ...)
	expect(1, op, "string", "nil")
	local t = {op=op, t={...}}
	t.op = op or lib.LOGIC_GATE.AND
	t.test = function(bridge)
		TriggerGroup(t, bridge)
	end
	return setmetatable(t, TriggerGroup)
end
function TriggerGroup.test(self, bridge)
	local A, B, res1, res2
	for k,v in pairs(self.t) do
		B = v.test(bridge)
		if A == nil then
			A = B
		else
			A = LOGIC_LAMBDA[self.op](A,B)
		end
		res1, res2 = lazyA[self.op](A)
		if res1 then return res2 end
	end
	return A
end
function TriggerGroup.toJson(self)
	return textutils.serializeJSON(TriggerGroup.export(self))
end
function TriggerGroup.fromJson(tbl)
	if tbl == nil then return nil end
	local _tbl = tbl
	if type(_tbl) == 'string' then
		_tbl = textutils.unserializeJSON(_tbl)
	end
	local t = TriggerGroup(_tbl.op)
	for _,v in pairs(_tbl.t) do
		if v.type == 'TriggerGroup' then
			t.t[#t.t+1] = Trigger.fromJson(v)
		elseif v.type == 'Trigger' then
			t.t[#t.t+1] = Trigger.fromJson(v)
		end
	end
	return t
end
function TriggerGroup.export(self)
	local t = {}
	for _,v in pairs(self.t) do
		t[#t+1] = v.export()
	end
	return {op=self.op,t=t,type="TriggerGroup"}
end
lib.TriggerGroup = setmetatable(TriggerGroup,{
	__tostring = function(self)
		if TriggerGroup == self then return "TriggerGroup constructor" end
		return self.toJson(self)
	end,
	__subtype='TriggerGroup',
	__name = "utility",
	__call = TriggerGroup.new
})
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
local Task = {}
function Task:new(item, isFluid, amount, batch, trigger)
	expect(1, item, "table", "string")
	expect(2, isFluid, "boolean", "nil")
	expect(3, amount, "number", "nil")
	expect(4, batch, "number", "nil")
	expect(5, trigger, "Trigger", "TriggerGroup", "nil")
	
	item = _parse(item)
	amount = amount or lib.DEFAULT_AMOUNT
	local task = {
		item=item,
		isFluid=isFluid or false,
		amount=amount,
		batch=batch or 1,
		trigger=trigger or Trigger(item,_,_,_,_,_,amount)
	}
	self.test = function(bridge) return Task.test(self, bridge) end
	self.craft = function(bridge, callback) return Task.craft(self, bridge, callback) end
	
	return setmetatable(task, Task)
end
function Task.test(self, bridge)
	return self.trigger.test(bridge)
end
function Task.craft(self, bridge, callback)
	expect(3, callback, "function", "nil")
	if not bridge.isItemCraftable(self.item) then
		if callback then callback(-4, self, bridge) end
		return -4
	elseif bridge.isItemCrafting(self.item) then -- Item already crafting
		if callback then callback(-2, self, bridge) end
		return -2
	elseif not self.trigger.test(bridge) then-- Conditions not met
		if callback then callback(-1, self, bridge) end
		return -1
	end
	local result = 0
	if self.isFluid then
		result = Task.craftFluid(self, bridge)
	else
		result = Task.craftItem(self, bridge)
	end
	if callback then
		callback(result, self, bridge)
	end
	return result
end
function Task.craftFluid(self, bridge)
	local t = tabl.copy(self.item)
	t.count = self.batch
	local result = bridge.craftItem(t)
	while t.count > 1 and not result do
		t.count = math.ceil(t.count/10)
		result = bridge.craftItem(t)
	end
	if result then return t.count end
	return 0
end
function Task.craftFluid(self, bridge)
	local t = tabl.copy(self.item)
	t.count = self.batch
	local result = bridge.craftFluid(t)
	while t.count > 0.001 and not result do
		t.count = math.ceil((t.count/10)*1000)/1000
		result = bridge.craftFluid(t)
	end
	if result then return t.count end
	return 0
end
function Task.toJson(self)
	return textutils.serializeJSON(Task.export(self))
end
function Task.export(self)
	return {
		item=self.item,
		isFluid=self.isFluid,
		amount=self.amount,
		batch=self.batch,
		trigger=self.trigger.export(),
		type="Task"
	}
end
function Task.fromJson(tbl)
	if tbl == nil then return nil end
	local _tbl = tbl
	if type(_tbl) == 'string' then
		_tbl = textutils.unserializeJSON(_tbl)
	end
	local t = Task(
		_tbl.item,
		_tbl.isFluid,
		_tbl.amount,
		_tbl.batch)
	if _tbl.trigger.type == 'TriggerGroup' then
		t.trigger = TriggerGroup.fromJson(_tbl.trigger)
	elseif _tbl.trigger.type == 'Trigger' then
		t.trigger = Trigger.fromJson(_tbl.trigger)
	end
	return t
end

lib.Task = setmetatable(Task,{
	__tostring = function(self)
		if Task == self then return "Task constructor" end
		return self.toJson(self)
	end,
	__subtype='Task',
	__name = "utility",
	__call = Task.new
})

return lib
