--[[
	NBT Storage Utility library by PavelKom.
	Version: 0.9.5
	Wrapped NBT Storage
	https://advancedperipherals.netlify.app/peripherals/nbt_storage/
	TODO: Add manual
]]
getset = require 'getset_util'

local lib = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'NBT Storage')
	if wrapped ~= nil then return wrapped end
	
	self.read = function() return self.object.read() end
	self.writeTable = function(nbt) return self.object.writeTable(nbt) end
	self.write = self.writeTable
	self.writeJson = function(json)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		return self.object.writeJson(json)
	end
	self.write2 = self.writeJson
	
	self.__getter = {}
	self.__getter.data = self.read
	
	self.__setter = {}
	self.__setter.data = self.write
	self.__setter.jdata = self.writeJson
	
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "NBT Storage",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.NBTStorage=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="nbtStorage",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="NBTStorage",})

function testDefaultPeripheral()
	if Peripheral.default == nil then
		Peripheral()
	end
end
function lib.read()
	testDefaultPeripheral()
	return Peripheral.default.read()
end
function lib.writeTable(tbl)
	testDefaultPeripheral()
	return Peripheral.default.writeTable(tbl)
end
function lib.writeJson(json)
	testDefaultPeripheral()
	return Peripheral.default.writeJson(json)
end

return lib
