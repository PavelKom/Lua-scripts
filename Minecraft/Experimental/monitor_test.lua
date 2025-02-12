local Monitor = require "epf.cc.monitor"
local GUI = require "GUI"

--local Predraw = GUI.Predraw
local locals = GUI.getLocals()
local rect = locals.primitives.drawRectAbs
local box = locals.primitives.drawBoxAbs
local line = locals.primitives.drawLine

local buttons = setmetatable({}, {
	__len=function(self)
		local i = 0
		for _,_ in pairs(self) do i = i + 1 end
		return i
	end
})

local function killme(button)
    buttons[button] = nil
    local master = button._PARENT
    local mon = button.target
    sleep(0.1)
    button:erase()
    sleep(0.1)
    if master then master:draw() end
    mon.bg=colors.black
    mon.clear()
    if #buttons == 0 then GUI.EXIT() end
end

for _,name in pairs(peripheral.getNames()) do
    if peripheral.hasType(name, 'monitor') then
        local mon = Monitor(name)
        mon.bg = colors.black
        mon.fg = colors.white
        mon.scale = 0.5
        mon.clear()
        local _x, _y = mon.getSize()
        local b = GUI.Button{target=mon,bg=colors.cyan,w=_x,h=_y,text=string.format("%s %ix%i", name, _x,_y),
        func=function(s) GUI.think(killme, s) end}
        b:draw()
        buttons[b] = ''
    end
end




GUI.NO_EXIT()