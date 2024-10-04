--[[
	Block Reader Utility library by PavelKom.
	Version: 0.9
	Wrapped Block Reader
	https://advancedperipherals.netlify.app/peripherals/block_reader/
	ToDo: Add manual
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_PERIPHERAL = nil

-- Peripheral
function this_library:BlockReader(name)
	name = name or 'blockReader'
	local ret = {object = peripheral.find(name)}
	if ret.object == nil then error("Can't connect to Block Reader '"..name.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	
	ret.__getter = {
		block = function() return ret.object.getBlockName() end,
		data = function() return ret.object.getBlockData() end,
		states = function() return ret.object.getBlockStates() end,
		tile = function() return ret.object.isTileEntity() end,
	}
	ret.getBlockName = ret.__getter.name
	ret.getBlockData = ret.__getter.data
	ret.getBlockStates = ret.__getter.states
	ret.isTileEntity = ret.__getter.tile
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Block Reader '%s' Current block: '%s'", self.name, self.block)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

function testDefaultPeripheral()
	if this_library.DEFAULT_PERIPHERAL == nil then
		this_library.DEFAULT_PERIPHERAL = this_library:BlockReader()
	end
end

function this_library.getBlockName()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.block
end
this_library.getBlock = this_library.getBlockName
function this_library.getBlockData()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.data
end
this_library.getData = this_library.getBlockData
function this_library.getBlockStates()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.states
end
this_library.getStates = this_library.getBlockStates
function this_library.isTileEntity()
	testDefaultPeripheral()
	return this_library.DEFAULT_PERIPHERAL.isTile
end
this_library.isTile = this_library.isTileEntity

return this_library
