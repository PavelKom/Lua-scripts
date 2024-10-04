--[[
	NBT Storage Utility library by PavelKom.
	Version: 0.9
	Wrapped NBT Storage
	https://advancedperipherals.netlify.app/peripherals/nbt_storage/
	TODO: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:NBTStorage(name)
	name = name or 'nbtStorage'
	local ret = {object = peripheral.find(name), _nil = function() end}
	if ret.object == nil then error("Can't connect to Inventory Manager '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	ret.__getter = {}
	ret.read = function() return ret.object.read() end
	ret.__getter.data = ret.read
	
	ret.writeTable = function(nbt) return ret.object.writeTable(nbt) end
	ret.write = ret.writeTable
	
	ret.writeJson = function(json)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		return ret.object.writeJson(json)
	end
	ret.write2 = ret.writeJson
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("NBT Storage '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:NBTStorage()
	end
end
function this_library.read()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.read()
end
function this_library.writeTable(tbl)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.writeTable(tbl)
end
function this_library.writeJson(json)
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.writeJson(json)
end

return this_library
