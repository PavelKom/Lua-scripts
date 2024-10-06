--[[
	Drive Utility library by PavelKom.
	Version: 0.9
	Wrapped Drive
	https://tweaked.cc/peripheral/drive.html
	TODO: Add manual
]]

getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:Drive(name)
	local def_type = 'drive'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Drive '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.__getter = {
		label = function() return ret.object.getDiskLabel() end,
		present = function() return ret.object.isDiskPresent() end,
		data = function() return ret.object.hasData() end,
		id = function() return ret.object.getDiskID() end,
		path = function() return ret.object.getMountPath() end,
		audio = function() return ret.object.hasAudio() end,
		title = function() return ret.object.getAudioTitle() end,
	}
	ret.__setter = {
		label = function(label) return pcall(ret.object.setDiskLabel,label) end,
	}
	play = function() return ret.object.playAudio() end
	stop = function() return ret.object.stopAudio() end
	eject = function() return ret.object.ejectDisk() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Drive '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end


return this_library
