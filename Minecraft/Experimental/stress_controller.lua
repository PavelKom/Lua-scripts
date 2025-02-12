--[[
    Stress controller for Create mod
    Requires:
        Extended Peripherals Framework (aka epf) - A library for simplifying work with peripheral devices via wrappers.
            https://github.com/PavelKom/Lua-scripts/tree/master/Minecraft/Experimental
        GUI (fork by PavelKom) - Library for creating widgets for a terminal or monitor.
            https://github.com/PavelKom/ComputerCraft-GUI
    Author: PavelKom
    Version: 0.8
]]

--------------------------------------CONFIG-------------------------------------
local stressometer_name = ''     -- Specific name for stressometer
local cfg_name = "stress_controller.json" -- Config name
--DO NOT CHANGE ANYTHING BELOW THIS LINE UNLESS YOU ARE SURE WHAT YOU ARE DOING--
local Stress = require "epf.create.stress"
do
    local res, err = pcall(Stress, stressometer_name)
    if not res then
        error("Connect at least one stressometer to the computer system!!!")
    end
end
local Monitor = require "epf.cc.monitor"
local GUI = require "GUI"
local StressBar = GUI.StressometerBar
local RSC = GUI.RotationSpeedControllerAuto

local cfg = {}

local FUNC_TABLE = {}

local mon_list = setmetatable({}, {
    __len=function(self)
        local l = 0
        for _,_ in pairs(self) do l = l + 1 end
        return l
    end
})
local function eraseRSC(s)
    local master = s._PARENT
    local mon = s.target
    local w = nil
    for i=2, #mon_list[mon] do
        if mon_list[mon][i] == master then
            table.remove(mon_list[mon], i)
            break
        end
    end
    s:_func()
end
local function eraseFrame(s)
    local mon = s.target
    local c = s._PARENT._CHILDREN[1].color_bg
    s._PARENT:erase()
    s:erase()
    mon_list[mon] = nil
    mon.setBackgroundColor(c)
    mon.clear()
    if #mon_list == 0 then GUI.EXIT() end
end
local function fixMonitor(mon)
    mon_list[mon] = mon_list[mon] or {}
    local _name = mon == term.native() and "term" or peripheral.getName(mon)
    if #mon_list[mon] == 0 then
        if mon ~= term.native() then mon.scale = 0.5 end
        local frame = GUI.Panel()   -- #1
        local canvas = GUI.Canvas{frame, target=mon,bg=colors.black}
        canvas.frame:rect(1,1,mon.getSize())
        GUI.Button{frame,target=mon,text='X',bg=colors.red,func=eraseFrame}
        GUI.Button{frame, x=1,y=2,w=6,target=mon,bg=colors.cyan,text='Reload',func=FUNC_TABLE.run}
        GUI.Button{frame, x=8,y=2,w=4,target=mon,text='Save',func=FUNC_TABLE.save_cfg}
        GUI.Label{frame,x=2,w=10,target=mon,text=_name, bg=colors.orange}
        StressBar{frame, target=mon,stress=stressometer_name,x=3,y=3,label=_name}
        mon_list[mon][#mon_list[mon]+1] = frame
        frame:draw()
    end
    local stress_add = true
    for _, v in pairs(mon_list[mon][1]._CHILDREN) do
        if custype(v) == 'StressometerBar' then
            return
        end
    end
    StressBar{mon_list[mon][1], target=mon,stress=stressometer_name,x=3,y=3,label=_name}._PARENT:draw()
end
local function addRSC(mon, name)
    fixMonitor(mon)
    local offset = #mon_list[mon]+4
    local rsc = RSC{mon_list[mon][1], target=mon,rsc=name,x=offset,y=offset}
    rsc.__buttons.bErase._func = rsc.__buttons.bErase.func
    rsc.__buttons.bErase.func = eraseRSC
    mon_list[mon][#mon_list[mon]+1] = rsc
    --sc:draw()
    return rsc
end
local function read_cfg(s)
    if not fs.exists(cfg_name) then
        return
    end
    local f = io.open(cfg_name, "r")
    cfg = textutils.unserialiseJSON(f:read("*a"))
    f:close()
    for k,v in pairs(cfg) do
        if peripheral.isPresent(k) and peripheral.hasType(k, 'Create_RotationSpeedController') then
            local mon = v.monitor
            if mon ~= 'term' and peripheral.isPresent(mon) and peripheral.hasType(mon, 'monitor') then
                mon = Monitor(mon)
            else
                mon = term.native()
            end
            fixMonitor(mon)
            local rsc = nil
            for _mon, list in pairs(mon_list) do
                for i=2, #list do
                    if list[i].__pName == k then
                        rsc = list[i]
                        if mon ~= rsc.target then
                            rsc.target = mon
                            for j, child in pairs(list[1]._CHILDREN) do
                                if child == rsc then
                                    table.remove(list[1]._CHILDREN, j)
                                    break
                                end
                            end
                            mon_list[mon][1]:addCHILD(rsc)
                            mon_list[mon][1]:draw()
                            list[1]:draw()
                        end
                        goto skipCreate
                    end
                end
            end
            rsc = addRSC(mon, k)
            ::skipCreate::
            rsc.minSpeed = v.min
            rsc.maxSpeed = v.max
            rsc.label = v.label
            rsc:draw()
        end
    end
end
function FUNC_TABLE.save_cfg(s)
    if fs.exists(cfg_name) then
        local f = io.open(cfg_name, "r")
        cfg = textutils.unserialiseJSON(f:read("*a"))
        f:close()
    end
    for mon, list in pairs(mon_list) do
        local monName = mon == term.native() and 'term' or peripheral.getName(mon)
        for i=#list, 2, -1 do
            local master = list[i]
            local name = master.__pName
            cfg[name] = cfg[name] or {}
            cfg[name].min = master.minSpeed
            cfg[name].max = master.maxSpeed
            cfg[name].label = master.label
            cfg[name].monitor = monName
        end
    end
    local f = io.open(cfg_name, 'w')
    f:write(textutils.serialiseJSON(cfg))
    f:close()
end
local function iter_rsc()
    local _term = term.native()
    for _,name in pairs(peripheral.getNames()) do
        if peripheral.hasType(name, 'Create_RotationSpeedController') then
            for mon,list in pairs(mon_list) do
                for i=2, #list do
                    if list[i].__pName == name then goto continue end
                end
            end
            addRSC(_term, name)
        end
        ::continue::
    end
end
local function eventMonResize()
    while true do
        local e, name = os.pullEvent("monitor_resize")
        for mon, list in pairs(mon_list) do
            if mon ~= term.native() and peripheral.getName(mon) == name then
                local frame = list[1]._CHILDREN[1].frame
                frame:clear()
                frame:rect(1,1,mon.getSize())
                list[1]:draw()
                break
            end
        end
    end
end
local function stub() while true do sleep(1) end end
GUI.think(stub)
function FUNC_TABLE.run(s)
    read_cfg()
    iter_rsc()
end
local function no_exit()
    parallel.waitForAny(GUI.NO_EXIT, eventMonResize)
end
GUI.DRAW()
parallel.waitForAll(FUNC_TABLE.run, no_exit)
