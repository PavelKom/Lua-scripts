--[[
	Drive peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/drive.html
]]
local epf = require 'epf'

local Peripheral = {}
function Peripheral.__init(self)
	self.__getter = {
		label = function() return self.getDiskLabel() end,
		present = function() return self.isDiskPresent() end,
		data = function() return self.hasData() end,
		empty = function() return not self.hasData() end,
		id = function() return self.getDiskID() end,
		path = function() return self.getMountPath() end,
		audio = function() return self.hasAudio() end,
		title = function() return self.getAudioTitle() end,
	}
	self.__setter = {
		label = function(label) return pcall(self.setDiskLabel,label) end,
	}
	play = function() return self.playAudio() end
	stop = function() return self.stopAudio() end
	eject = function() return self.ejectDisk() end
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "drive", "Drive")

local lib = {}
lib.Drive = Peripheral

function lib.help()
	local text = {
		"Drive library. Contains:\n",
		"Drive",
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
	__name="Drive",
	__subtype="peripheral wrapper library",
	__tostring=function(self)
		return "EPF-library for Drive (CC:Tweaked)"
	end,
})

return lib
