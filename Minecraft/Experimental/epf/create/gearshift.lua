--[[
	Sequenced Gearshift peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://github.com/Creators-of-Create/Create/wiki/Sequenced-Gearshift-%28Peripheral%29
]]
local epf = require 'epf'
local expect = require 'cc.expect'
local expect, range = expect.expect, expect.range

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Idle: %i", subtype(self), peripheral.getName(self), self.speed)
end

function Peripheral.__init(self)
	self.__getter = {
		isRun = function() return self.isRunning() end,
	}
	self.__getter.idle = self.__getter.isRun
	self.run = function(sequence)
		expect(1, sequence, "Sequence")
		sequence.run(self)
	end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "Create_SequencedGearshift", "Sequenced Gearshift")

local function testSequence(val, mod)
	expect(1, val, "number")
	expect(2, mod, "number")
	mod = math.floor(math.clamp(mod,-2,2))
	if val < 0 then
		mod = -1 * mod
		val = -1 * val
	end
	return val, mod
end

local Sequence = {}
Sequence.ROTATE = true
Sequence.MOVE = false
local seq_parse = {
	[true]=true,['rotate']=true,['r']=true,
	[false]=false,['move']=false,['m']=false}
setmetatable(seq_parse, {__index=epf.GETTER_TO_LOWER(false)})
local function _pairs(self)
	local key,value
	return function()
		key,value = next(self.__seq,key)
		if key == nil then return nil, nil end
		return key, value
	end
end
local function _call(self, _type, val, modifier)
	return self.add(_type, val, modifier)
end
function Sequence.new()
	local self = {__seq={}}
	self.rotate = function(angle, modifier)
		self.__seq[#self.__seq+1] = {true, testSequence(angle, modifier)}
		return #self.__seq
	end
	self.move = function(distance, modifier)
		self.__seq[#self.__seq+1] = {false, testSequence(distance, modifier)}
		return #self.__seq
	end
	self.add = function(_type, val, modifier)
		self.__seq[#self.__seq+1] = {not not _type, testSequence(val, modifier)}
		return #self.__seq
	end
	self.run = function(gearshift)
		local i = 1
		while i <= #self.__seq do
			while gearshift.isRunning() do
				sleep(0)
			end
			if self.__seq[i][1] then
				gearshift.rotate(table.unpack(self.__seq[i],2,3))
			else
				gearshift.move(table.unpack(self.__seq[i],2,3))
			end
			i = i + 1
		end
	end
	self.load = function(tbl, clear)
		if clear then self.__seq = {} end
		for _, v in pairs(tbl) do
			self.__seq[#self.__seq+1] = {seq_parse[v[1]], testSequence(table.unpack(v,2,3))}
		end
		return #self.__seq
	end
	self.save = function()
		local t = {}
		for _,v in pairs(self.__seq) do
			t[#t+1]={v[1] and 'rotate' or 'move', v[2], v[3]}
		end
		return t
	end
	
	setmetatable(self,{
	__name = 'utility',
	__subtype = "Sequence",
	__call = _call,
	__pairs = _pairs,
	})
	
	return self
end

function Sequence.add(self, distance, modifier)
	return self.add(distance, modifier)
end
function Sequence.rotate(self, angle, modifier)
	return self.rotate(angle, modifier)
end
function Sequence.move(self, distance, modifier)
	return self.move(distance, modifier)
end
function Sequence.load(self, tbl)
	return self.load(tbl)
end
function Sequence.save(self)
	return self.save()
end


local lib = {}
lib.SequencedGearshift = Peripheral
lib.Sequence = setmetatable(Sequence,{
	__call = Sequence.new
})
local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__subtype="SequencedGearshift",
	__name="library",
})
return lib
