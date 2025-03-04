--[[
	Redstone Integrator peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/redstone_integrator/
	
	Note: RedstoneIntegrator not support bundled inputs/outputs. Use RedstoneRelay (CC:Tweaked version >=1.114.0)
]]
local epf = require 'epf'
local expect = require "cc.expect"
local expect = expect.expect

local lib = {}
lib.EXTERNAL_TABLES = false

local Peripheral = {}
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
		error("Invalid value type for setting RedstoneIntegrator.output. Expect boolean or number, get "..type(value))
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

-- [[ NO BUNDLED INPUT/OUTPUT ]] --

function Peripheral.__init(self)
	if not lib.EXTERNAL_TABLES then
		local f1 = function(side) return self.getAnalogInput(epf.SIDES[side]) end
		local f2 = function(side) return self.getInput(epf.SIDES[side]) end
		local input = epf.subtableSide(self,f1,_,f2,f1)
		
		f1 = function(side) return self.getAnalogOutput(epf.SIDES[side]) end
		f2 = function(side) return self.getOutput(epf.SIDES[side]) end
		local f3 = function(side, value)
			expect(2, value, "boolean", "number")
			if type(value) == 'boolean' then self.setOutput(epf.SIDES[side], value)
			elseif type(value) == 'number' then
				self.setAnalogOutput(epf.SIDES[side], math.clamp(value, 0, 15))
			end
		end
		local output = epf.subtableSide(self,f1,f3,f2,f1)
		
		self.input = input
		self.output = output
		
		self.i = input
		self.o = output
	end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "redstoneIntegrator", "Redstone Integrator")

lib.RedstoneIntegrator = Peripheral

function lib.help()
	local text = {
		"Redstone Integrator library. Contains:\n",
		"RedstoneIntegrator",
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
	__subtype="RedstoneIntegrator",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Redstone Integrator (Advanced Peripherals)"
	end,
})

return lib
