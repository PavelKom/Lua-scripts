--[[
	Note Block Utility library by PavelKom.
	Version: 0.1
	Wrapped Note Block
	https://docs.advanced-peripherals.de/integrations/minecraft/noteblock/
	TODO: Add manual
]]
getset = require 'getset_util'
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Note Block')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		note = function() return self.object.getNote() end,
	}
	self.__setter = {
		note = function(value) return self.object.changeNoteBy(value) end,
	}
	self.changeNote = function() return self.object.changeNote() end
	self.inc = self.changeNote -- Increment
	self.dec = function() return self.object.changeNoteBy((self.note-1) % 25) end -- Decrement
	self.add = function(value) return self.object.changeNoteBy((self.note+value) % 25) end -- + notes
	self.sub = function(value) return self.object.changeNoteBy((self.note-value) % 25) end -- - notes
	
	self.play = function() self.object.playNote() end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Note: %i", type(self), self.name, self.note)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Note Block",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.NoteBlock=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="noteBlock",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="NoteBlock",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
