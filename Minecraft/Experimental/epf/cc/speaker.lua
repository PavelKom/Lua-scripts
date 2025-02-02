--[[
	Speaker peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/speaker.html
]]
local epf = require 'epf'
--local expect = require "cc.expect"
--local expect = expect.expect

local lib = {}

local Peripheral = {}

function Peripheral.__init(self)
	-- Autofixer instrument name
	self.__note = self.playNote
	self.playNote = function(instrument, volume, pitch)
		return self.__note(epf.INSTRUMENTS[instrument], volume, pitch)
	end
	self.note = self.playNote
	self.sound = self.playSound
	self.audio = self.playAudio
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "speaker", "Speaker")

lib.Speaker = Peripheral

function lib.help()
	local text = {
		"Speaker library. Contains:\n",
		"Speaker",
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
	__type="library",
	__name="Speaker",
	__subtype="peripheral wrapper library",
	__tostring=function(self)
		return "EPF-library for Speaker (CC:Tweaked)"
	end,
})

return lib
