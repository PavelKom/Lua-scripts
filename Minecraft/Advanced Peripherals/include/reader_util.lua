--[[
	Block Reader Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Block Reader
	https://advancedperipherals.netlify.app/peripherals/block_reader/
	ToDo: Add manual
]]
getset = require 'getset_util'

local lib = {}
local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'blockReader', 'Block Reader', Peripheral)
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {
		block = function() return self.object.getBlockName() end,
		data = function() return self.object.getBlockData() end,
		states = function() return self.object.getBlockStates() end,
		tile = function() return self.object.isTileEntity() end,
	}
	self.getBlockName = self.__getter.block
	self.getBlockData = self.__getter.data
	self.getBlockStates = self.__getter.states
	self.isTileEntity = self.__getter.tile
	
	self.__setter = {}
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s' Current block: '%s'", self.type, self.name, self.block)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	Peripheral.__items[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.BlockReader=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib.getBlockName()
	testDefaultPeripheral()
	return Peripheral.default.block
end
lib.getBlock = lib.getBlockName
function lib.getBlockData()
	testDefaultPeripheral()
	return Peripheral.default.data
end
lib.getData = lib.getBlockData
function lib.getBlockStates()
	testDefaultPeripheral()
	return Peripheral.default.states
end
lib.getStates = lib.getBlockStates
function lib.isTileEntity()
	testDefaultPeripheral()
	return Peripheral.default.isTile
end
lib.isTile = lib.isTileEntity

return lib
