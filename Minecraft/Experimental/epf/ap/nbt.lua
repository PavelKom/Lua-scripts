--[[
	NBT Storage peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://advancedperipherals.netlify.app/peripherals/nbt_storage/
]]
local epf = require 'epf'

local Peripheral = {}
function Peripheral.__init(self)
	self.write = function(data)
		if type(data) == 'table' then
			return self.writeTable(data)
		end
		return self.writeJson(data)
	end
	self.__getter.data = self.read
	self.__setter.data = self.write
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "nbtStorage", "NBTStorage")

local lib = {}
lib.NBTStorage = Peripheral

function lib.help()
	local text = {
		"NBT Storage library. Contains:\n",
		"NBTStorage",
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
	__subtype="NBTStorage",
	__name="library",
	__tostring=function(self)
		return "EPF-library for NBT Storage (Advanced Peripherals)"
	end,
})

return lib
