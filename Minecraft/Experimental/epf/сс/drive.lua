--[[
	Drive peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripheral Framework version: 2.0
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

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__subtype="peripheral wrapper library"
})

return lib
