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
	local def_type = 'nbtStorage'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to NBT Storage '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end
	
	ret.read = function() return ret.object.read() end
	ret.writeTable = function(nbt) return ret.object.writeTable(nbt) end
	ret.write = ret.writeTable
	ret.writeJson = function(json)
		if type(json) == 'table' then
			json = textutils.serialiseJSON(json)
		end
		return ret.object.writeJson(json)
	end
	ret.write2 = ret.writeJson
	
	ret.__getter = {}
	ret.__getter.data = ret.read
	
	ret.__setter = {}
	ret.__setter.data = ret.write
	ret.__setter.jdata = ret.writeJson
	
	
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
