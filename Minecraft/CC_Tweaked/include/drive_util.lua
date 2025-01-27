--[[
	Drive Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Drive
	https://tweaked.cc/peripheral/drive.html
	TODO: Add manual
]]

getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'drive', 'Drive', Peripheral)
	if wrapped ~= nil then return wrapped end
	self.__getter = {
		label = function() return self.object.getDiskLabel() end,
		present = function() return self.object.isDiskPresent() end,
		data = function() return self.object.hasData() end,
		empty = function() return not self.object.hasData() end,
		id = function() return self.object.getDiskID() end,
		path = function() return self.object.getMountPath() end,
		audio = function() return self.object.hasAudio() end,
		title = function() return self.object.getAudioTitle() end,
	}
	self.__setter = {
		label = function(label) return pcall(self.object.setDiskLabel,label) end,
	}
	play = function() return self.object.playAudio() end
	stop = function() return self.object.stopAudio() end
	eject = function() return self.object.ejectDisk() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Drive"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.Drive=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end


return lib
