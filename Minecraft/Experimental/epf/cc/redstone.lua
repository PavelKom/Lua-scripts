--[[
	Redstone Relay peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/redstone_relay.html
	Note: Redstone relay not recognising cardinal directions, but you can call i/o with it.
	local relay = RedstoneRelay(_, 'west') -- Second argument is front side but in cardinal direction. NOT OPTIONAL!!! REQUIRED!!!
]]
local epf = require 'epf'

--if _G._CC_MINOR < 114 then
--	error("Redstone Relay added in CC 1.114.0. Update mod for using Redstone Relay")
--end

local expect = require "cc.expect"
local expect = expect.expect

local lib = {}

-- Change this setting to true for static-calls pos and palette tables
lib.EXTERNAL_TABLES = false

local Peripheral = {}

-- INPUT
function Peripheral.__input_getter(self, side)
	return self.getInput(epf.SIDES[side])
end
function Peripheral.__input_analog_getter(self, side)
	return self.getAnalogInput(epf.SIDES[side])
end
Peripheral.__input = epf.subtableSide(Peripheral,
	Peripheral.__input_analog_getter, -- input.up -> 0-15
	_,
	Peripheral.__input_getter, -- input('up') -> true/false
	Peripheral.__input_analog_getter,
	{'static'})
function Peripheral.input(self)
	rawset(Peripheral.__input,'__cur_obj',self)
	return Peripheral.__input
end

-- OUTPUT
function Peripheral.__output_getter(self, side)
	return self.getOutput(epf.SIDES[side])
end
function Peripheral.__output_analog_getter(self, side)
	return self.getAnalogOutput(epf.SIDES[side])
end
function Peripheral.__output_setter(self, side, value)
	if type(value) == 'boolean' then self.setOutput(epf.SIDES[side], value)
	elseif type(value) == 'number' then
		self.setAnalogOutput(epf.SIDES[side], math.clamp(value, 0, 15))
	else
		error("Invalid value type for setting RedstoneRelay.output. Expect boolean or number, get "..type(value))
	end
end
Peripheral.__output = epf.subtableSide(Peripheral,
	Peripheral.__output_analog_getter, -- output.up -> 0-15
	Peripheral.__output_setter, -- output.up = 0-15 or true/false
	Peripheral.__output_getter, -- output('up') -> true/false
	Peripheral.__output_analog_getter,
	{'static'})
function Peripheral.output(self)
	rawset(Peripheral.__output,'__cur_obj',self)
	return Peripheral.__output
end

-- BUNDLED INPUT
function Peripheral.__ibundle_getter(self, side)
	return self.getBundledInput(epf.SIDES[side])
end
function Peripheral.__ibundle_caller(self, side, mask)
	return self.testBundledInput(epf.SIDES[side], mask)
end
Peripheral.__ibundle = epf.subtableSide(Peripheral,
	Peripheral.__ibundle_getter, -- Bitwise 0xFFFF
	_, 
	Peripheral.__ibundle_caller, -- testBundledInput
	Peripheral.__ibundle_getter, -- iter
	{'static'})
function Peripheral.ibundle(self)
	rawset(Peripheral.__ibundle,'__cur_obj',self)
	return Peripheral.__ibundle
end

-- BUNDLED OUTPUT
function Peripheral.__obundle_getter(self, side)
	return self.getBundledOutput(epf.SIDES[side])
end
function Peripheral.__obundle_setter(self, side, value)
	return self.setBundledOutput(epf.SIDES[side], value)
end
function Peripheral.__obundle_caller(self, side, mask)
	local output = Peripheral.__obundle_getter(self, side)
	return bit32.band(output,mask) == mask
end
Peripheral.__obundle = epf.subtableSide(Peripheral,
	Peripheral.__obundle_getter, -- Bitwise 0xFFFF
	Peripheral.__obundle_setter, 
	Peripheral.__obundle_caller, -- test Bundled Output
	Peripheral.__obundle_getter, -- iter
	{'static'})
function Peripheral.obundle(self)
	rawset(Peripheral.__obundle,'__cur_obj',self)
	return Peripheral.__obundle
end

function Peripheral.__init(self)
	if not lib.EXTERNAL_TABLES then
		local f1 = function(side) return self.getAnalogInput(self.__dir_tbl[side]) end
		local f2 = function(side) return self.getInput(self.__dir_tbl[side]) end
		local input = epf.subtableSide(self,f1,_,f2,f1)
		
		f1 = function(side) return self.getAnalogOutput(self.__dir_tbl[side]) end
		f2 = function(side) return self.getOutput(self.__dir_tbl[side]) end
		local f3 = function(side, value)
			expect(2, value, "boolean", "number")
			if type(value) == 'boolean' then self.setOutput(self.__dir_tbl[side], value)
			elseif type(value) == 'number' then
				self.setAnalogOutput(self.__dir_tbl[side], math.clamp(value, 0, 15))
			end
		end
		local output = epf.subtableSide(self,f1,f3,f2,f1)
		
		f1 = function(side) return self.getBundledInput(self.__dir_tbl[side]) end
		f2 = function(side, value) return self.testBundledInput(self.__dir_tbl[side], value) end
		local ibundle = epf.subtableSide(self,f1,_,f2,f1)
		
		f1 = function(side) return self.getBundledOutput(self.__dir_tbl[side]) end
		f2 = function(side, value) return self.setBundledOutput(self.__dir_tbl[side], value) end
		f3 = function(side, value)
			return bit32.band(self.getBundledOutput(self.__dir_tbl[side]), value) == value end
		local obundle = epf.subtableSide(self,f1,f2,f3,f1)
		
		self.input = input
		self.output = output
		self.ibundle = ibundle
		self.obundle = obundle
		
		self.i = input
		self.o = output
		self.ib = ibundle
		self.ob = obundle
	end
	
	return self
end
Peripheral._new = epf.simpleNew(Peripheral)
function Peripheral.new(name, front)
	expect(2, front, "number", "string")
	
	local self = Peripheral._new(name)
	rawset(self, 'update', function(front)
	rawset(self, '__front', front)
	rawset(self, '__dir_tbl', epf.cardinalToRelativeEx(front))
	end)
	self.update(front)

	return self
end

Peripheral = epf.wrapperFixer(Peripheral, "redstone_relay", "Redstone Relay")
lib.RedstoneRelay = Peripheral

function lib.help()
	local text = {
		"Redstone Relay library. Contains:\n",
		"RedstoneRelay",
		"([name]) - Peripheral wrapper\n",
	}
	local c = {
		colors.red,
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

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__name="library",
	__subtype="RedstoneRelay",
	__tostring=function(self)
		return "EPF-library for Redstone Relay (CC:Tweaked)"
	end,
})

return lib
