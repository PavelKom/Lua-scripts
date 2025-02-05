--[[
	Block Reader peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/block_reader/
]]
local epf = require 'epf'

local Peripheral = {}
Peripheral.__str = function(self)
	return string.format("%s '%s' Current block: '%s'", subtype(self), peripheral.getName(self), self.block)
end
function Peripheral.__init(self)
	self.__getter = {
		block = function() return self.getBlockName() end,
		data = function() return self.getBlockData() end,
		states = function() return self.getBlockStates() end,
		tile = function() return self.isTileEntity() end,
	}
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "blockReader", "Block Reader")

local lib = {}
lib.BlockReader = Peripheral

function lib.help()
	local text = {
		"Block Reader library. Contains:\n",
		"BlockReader",
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
	__subtype="BlockReader",
	__name="library",
	__tostring=function(self)
		return "EPF-library for Block Reader (Advanced Peripherals)"
	end,
})

return lib
