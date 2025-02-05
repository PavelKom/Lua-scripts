--[[
	Stress controller for Create mod
	Author: PavelKom
	Version: 0.8
]]

local epf = require "epf"
local Monitor = require "epf.cc.monitor"
local Speaker = require "epf.cc.speaker"
local Stress = require "epf.create.stress"
local RscLib = require "epf.create.rsc"
local RSC = table.copy(RscLib.RotationSpeedController)

RSC.new = epf.simpleNew(RSC)
RSC.__hash = {}
do
	local _m = getmetatable(RSC)
	_m.__call = function(self,...) return RSC.new(...) end
	_m.__len = function(self)
		if not self.__names then return 0 end
		local i, k, v = 0, nil, nil
		repeat
			k, v = next(self.__names, k)
			if v and v.isAllow() then i = i + 1 end
		until k == nil
		return i
	end
	RSC = setmetatable(RSC, _m)
end

local stress = Stress()
local MON = Monitor()

if type(MON) == 'string' then
	MON = Monitor(MON)
	rawset(MON,'id',peripheral.getName(MON))
	MON.scale = 0.5
elseif type(MON) ~= "table" then
	MON = term
else
	rawset(MON,'id',peripheral.getName(MON))
	MON.scale = 0.5
end

local p, speaker = pcall(Speaker)
if not speaker then
	speaker = {playNote=function(...) end}
end
local function calibrate(rsc)
	local _stress = stress.stress
	rsc.speed = rsc.speed - 1
	sleep(0.1)
	rsc.delta = _stress - stress.stress
end

function RSC.__init_post(self)
	rawset(self, 'name', peripheral.getName(self))
	rawset(self, 'delta', 0)
	rawset(self, 'min', 0)
	rawset(self, 'max', 256)
	rawset(self, 'label', self.name)

	rawset(self, 'calibrate', function() calibrate(self) end)
	rawset(self, 'inc', function() self.abs = self.abs + 1 end)
	rawset(self, 'dec', function() self.abs = self.abs - 1 end)
	rawset(self, 'canUp', function() return self.abs < self.max and stress.cap - stress.stress >= self.delta end)
	rawset(self, 'canDown', function() return self.abs > self.min end)
	rawset(self, 'isAllow', function() return self.min >= 0 end)

	rawset(self, '_isValidEx', self.isValidEx)
	self.isValidEx = function()
		local res = self._isValidEx()
		if not res then
			for i, v in pairs(RSC.__hash) do
				if v == self.name then
					table.remove(RSC.__hash, i)
					break
				end
			end
		end
		return res
	end

	self.calibrate()

	RSC.__hash[#RSC.__hash+1] = self.name

	return self
end
function RSC.save()
	local s = {}
	if fs.exists("stress.json") and not fs.isDir("stress.json") then
		local f = io.open("stress.json", "r")
		s = textutils.unserialiseJSON(f:read("*a"))
		f:close()
	end
	for k,v in pairs(RSC.__names) do
		s[k] = {v.min, v.max, v.label}
	end
	local f = io.open("stress.json", "w")
	f:write(textutils.serialiseJSON(s))
	f:close()
end
function RSC.load()
	if not fs.exists("stress.json") or fs.isDir("stress.json") then return end
	local f = io.open("stress.json","r")
	local s = textutils.unserialiseJSON(f:read("*a"))
	f:close()
	for k,v in pairs(s) do
		local _, rsc = pcall(RSC,k)
		if rsc then
			rsc.min = v[1]
			rsc.max = v[2]
			rsc.label = v[3]
		end
	end
end
function RSC.reload()
	RSC.load()
	local names = peripheral.getNames()
	for _, name in pairs(names) do
		local exist = false
		for k, _ in pairs(RSC.__names) do
			if k == name then exist = true; break end
		end
		if not exist and peripheral.hasType(name, "Create_RotationSpeedController") then
			RSC(name)
		end
	end
	RSC.save()
end
local _time, noRotate, minSpeed, maxSpeed
local curr_color, curr_used, curr_name, curr_speed, curr_delta, _curr, curr_id = 0, 0, "", 0, 0, nil, 0
function RSC.run(rsc)
	_time = 1
	if not rsc.isValidEx() then return 0.1
	elseif rsc.abs > rsc.max then rsc.abs = rsc.max
	elseif rsc.abs < rsc.min then rsc.abs = rsc.min
	elseif stress.overload and rsc.canDown() then
		rsc.dec()
		_time = 0.1
	elseif rsc.canUp() then
		rsc.inc()
		if stress.overload then
			rsc.calibrate()
		end
		_time = 0.1
	end
	--if _curr == rsc.name then drawUpdate() end
	return _time
end
function RSC.loop()
	local _t = 1
	while true do
		_t = 1
		for k, rsc in pairs(RSC.__names) do
			_t = math.min(_t, RSC.run(rsc))
		end
		sleep(_t)
	end
end
function RSC.next()
	if #RSC > 0 then
		if _curr and not RSC.__names[_curr] then _curr = nil end
		local i = #RSC + 1
		repeat
			_curr, _ = next(RSC.__names, _curr)
			i = i - 1
		until (_curr and RSC.__names[_curr].isAllow()) or i < 0
		curr_id = curr_id + 1
		if curr_id > #RSC then curr_id = 1 end
	else
		curr_id = 0
	end
end
function RSC.update()
	curr_used = stress.use
	if curr_used < 0.75 then curr_color = colors.green
	elseif curr_used > 0.9 then curr_color = colors.red
	else curr_color = colors.yellow end
	if _curr and RSC.__names[_curr] and RSC.__names[_curr].isValid() then
		curr_name = RSC.__names[_curr].label or ""
		curr_speed = RSC.__names[_curr].speed or 0
		curr_delta = RSC.__names[_curr].delta or 0
		minSpeed = RSC.__names[_curr].min or 0
		maxSpeed = RSC.__names[_curr].max or 0
	else
		curr_name, curr_speed, curr_delta, minSpeed, maxSpeed = "", 0, 0, 0, 0
	end
end
function RSC.prev()
	if #RSC > 0 then
		for i, v in pairs(RSC.__hash) do
			if v == _curr then
				repeat
					curr_id = i - 1
					if curr_id == 0 then curr_id = #RSC end
					_curr = RSC.__hash[curr_id]
				until RSC.__names[_curr].isAllow()
				break
			end
		end
	else
		curr_id = 0
	end
end

local _prepare = {"Time:", "Stress current:", "Stress capacity:", "Stress used(%):", "RSC(s):", "Current RSC:","","Speed: Delta:"}
local function drawPrepare()
	MON.setCursorPos(24,4)
	MON.blit("Reset", "00000", "ddddd")
	MON.setCursorPos(17,5)
	MON.blit("Prev Exclude", "000000000000", "bbbbfeeeeeee")
	MON.setCursorPos(17,6)
	MON.blit("Next Reload ", "000000000000", "9999f7777777")
	MON.setCursorPos(17,8)
	MON.blit("Lock MIN--   ++", "000000000000000", "1111ffffdddddee")
	MON.setCursorPos(17,9)
	MON.blit("Save MAX--   ++", "000000000000000", "3333ffffdddddee")
	MON.setTextColor(colors.white)
	MON.setBackgroundColor(colors.black)
	for i,v in pairs(_prepare) do
		MON.setCursorPos(1,i)
		MON.write(v)
	end

	MON.setBackgroundColor(colors.black)
end
local lastTime, timeDelta, nTime = 0, epf.rawTime(0,0,5)
local function time_format()
	nTime = os.time('local')
	if ((nTime - lastTime) % 24) > timeDelta and not noRotate then
		lastTime = nTime
		RSC.next()
	end
	local h, m, s
	h, m = math.modf(nTime)
	m, s = math.modf(m*60)
	s = math.modf(s*60)
	return string.format("%02d:%02d:%02d", h, m, s)
end
local _formats = {
	"%.5i",
	"%.2f",
	"%.3i",
	"%s                             ",
	"%.2i/%.2i"
}
local _info = {
	function() MON.setCursorPos(6,1); MON.setTextColor(colors.cyan); MON.write(time_format()) end,
	function() MON.setCursorPos(18,2); MON.setTextColor(curr_color); MON.write(_formats[1]:format(stress.stress)) end,
	function() MON.setCursorPos(18,3); MON.setTextColor(curr_color); MON.write(_formats[1]:format(stress.cap)) end,
	function() MON.setCursorPos(18,4); MON.setTextColor(curr_color); MON.write(_formats[2]:format(curr_used*100)) end,
	function() MON.setCursorPos(10,5); MON.setTextColor(colors.blue);MON.write(_formats[5]:format(curr_id, #RSC)) end,
	function() MON.setCursorPos(1,7); MON.setTextColor(colors.orange); MON.write(_formats[4]:format(curr_name)) end,
	function() MON.setCursorPos(1,9); MON.setTextColor(colors.lime); MON.write(_formats[3]:format(curr_speed)) end,
	function() MON.setCursorPos(8,9); MON.setTextColor(colors.magenta); MON.write(_formats[3]:format(curr_delta)) end,
	function() MON.setCursorPos(27,8); MON.setTextColor(colors.brown); MON.write(_formats[3]:format(minSpeed)) end,
	function() MON.setCursorPos(27,9); MON.setTextColor(colors.brown); MON.write(_formats[3]:format(maxSpeed)) end,
}
local _ui_bisy = false
local function drawUpdate()
	if _ui_bisy then return end
	_ui_bisy = true
	MON.setCursorPos(1,1)
	RSC.update()
	for _,f in pairs(_info) do
		f()
	end
	sleep(0.1)
	_ui_bisy = false
end
local function drawLoop()
	while true do
		drawUpdate()
		sleep(1)
	end
end
local function loop1()
	pcall(drawLoop)
end
local function loop2()
	pcall(RSC.loop)
end
local buttons = setmetatable({},{
	__call = function(self,x,y,m)
		if not x or not y or not m then return end
		if not self[x] or not self[x][y] or not self[x][y][m] then return end
		return self[x][y][m](x,y,m)
	end,
})
local function regButton(X,Y,mouse,func)
	local _X = type(X) == 'table' and X or {X}
	local _Y = type(Y) == 'table' and Y or {Y}
	local _x, _y = {}, {}
	table.sort(_X)
	table.sort(_Y)
	for i=_X[1], (_X[2] or _X[1]) do _x[#_x+1]=i end
	for i=_Y[1], (_Y[2] or _Y[1]) do _y[#_y+1]=i end
	local _mouse = type(mouse) == 'table' and mouse or {mouse or 1}
	for _, x in pairs(_x) do
		if not buttons[x] then buttons[x] = {} end
		for _, y in pairs(_y) do
			if not buttons[x][y] then buttons[x][y] = {} end
			for _, m in pairs(_mouse) do
				buttons[x][y][m] = func
			end
		end
	end
end
local function btnPrev(...)
	lastTime = os.time('local')
	RSC.prev()
	speaker.playSound("minecraft:block.stone_button.click_off")
	drawUpdate()
end
regButton({17,20},5,1,btnPrev)

local function btnNext(...)
	lastTime = os.time('local')
	RSC.next()
	speaker.playSound("minecraft:block.stone_button.click_on")
	drawUpdate()
end
regButton({17,20},6,1,btnNext)

local function btnNoRot(...)
	noRotate = not noRotate
	MON.setCursorPos(17,8)
	if noRotate then
		MON.blit("Lock", "0000", "5555")
		speaker.playSound("minecraft:block.stone_button.click_on")
	else
		MON.blit("Lock", "0000", "1111")
		speaker.playSound("minecraft:block.stone_button.click_off")
	end
end
regButton({17,20},8,1,btnNoRot)

local function btnExclude(...)
	if _curr and RSC.__names[_curr] then
		RSC.__names[_curr].min = -1
		RSC.next()
	end
	speaker.playSound("minecraft:block.stone_button.click_off")
	drawUpdate()
end
regButton({22,28},5,1,btnExclude)

local function btnReload(...)
	RSC.reload()
	drawUpdate()
	speaker.playSound("minecraft:block.stone_button.click_on")
end
regButton({22,28},6,1,btnReload)

local function btnDecMin(x,y,m)
	if _curr and RSC.__names[_curr] then
		RSC.__names[_curr].min = math.max(0,RSC.__names[_curr].min-(10^(26-x)))
	end
	speaker.playSound("minecraft:block.stone_button.click_off")
	drawUpdate()
end
regButton({25,26},8,1,btnDecMin)

local function btnIncMin(x,y,m)
	if _curr and RSC.__names[_curr] then
		RSC.__names[_curr].min = math.min(
		RSC.__names[_curr].max,
		RSC.__names[_curr].min+(10^(x-30))
	)
	end
	speaker.playSound("minecraft:block.stone_button.click_on")
	drawUpdate()
end
regButton({30,31},8,1,btnIncMin)

local function btnDecMax(x,y,m)
	if _curr and RSC.__names[_curr] then
		RSC.__names[_curr].max = math.max(
		RSC.__names[_curr].min,
		RSC.__names[_curr].max-(10^(26-x))
	)
	end
	speaker.playSound("minecraft:block.stone_button.click_off")
	drawUpdate()
end
regButton({25,26},9,1,btnDecMax)

local function btnIncMax(x,y,m)
	if _curr and RSC.__names[_curr] then
		RSC.__names[_curr].max = math.min(256, RSC.__names[_curr].max+(10^(x-30)))
	end
	speaker.playSound("minecraft:block.stone_button.click_on")
	drawUpdate()
end
regButton({30,31},9,1,btnIncMax)

local function btnSave(x,y,m)
	RSC.save()
	speaker.playSound("minecraft:block.stone_button.click_on")
end
regButton({17,20},9,1,btnSave)

local function btnReset(x,y,m)
	local l = #RSC
	for _, v in pairs(RSC.__names) do
		if v.min < 0 then v.min = 0 end
	end
	if l == 0 then RSC.next() end
	speaker.playSound("minecraft:block.stone_button.click_on")
end
regButton({24,28},4,1,btnReset)

local function clickLoop(event, mouse, x, y)
	buttons(x,y,mouse)
	return true
end
local function clickTouch(event, id, x, y)
	if MON.id == id then buttons(x,y,1) end
	return true
end
local function attachLoop(event, name)
	if peripheral.hasType(name, "Create_RotationSpeedController") then
		if fs.exists("stress.json") and not fs.isDir("stress.json") then
			local f = io.open("stress.json","r")
			local s = textutils.unserialiseJSON(f:read("*a"))
			f:close()
			for _,v in pairs(s) do
				if v[1] == name then
					if v[2] < 0 then return true end
				end
			end
		end
		RSC(name)
		RSC.save()
	end
	return true
end
local function detachLoop(event, name)
	if peripheral.hasType(name, "Create_RotationSpeedController") then
		local p = RSC.__names[name]
		for i, v in pairs(RSC.__hash) do
			if v == p.name then
				table.remove(RSC.__hash, i)
				break
			end
		end
		RSC.__names[name] = nil
		if name == _curr then _curr = nil; RSC.next() end
		drawUpdate()
	end
	return true
end
local function loopEventAttach()
	epf.waitEventLoop('peripheral',attachLoop)
end
local function loopEventDetach()
	epf.waitEventLoop('peripheral_detach',detachLoop)
end
local function loopEventClick()
	epf.waitEventLoop('mouse_click',clickLoop)
end
local function loopEventTouch()
	epf.waitEventLoop('monitor_touch',clickTouch)
end

RSC.reload()
MON.clear()
drawPrepare()
speaker.playNote("bell",1,8)
sleep(0.15)
speaker.playNote("bell",1,12)
sleep(0.15)
speaker.playNote("bell",1,16)
while true do
	if MON == term then
		parallel.waitForAny(loop1, loop2, loopEventClick, loopEventAttach, loopEventDetach)
	else
		parallel.waitForAny(loop1, loop2, loopEventClick, loopEventAttach, loopEventDetach, loopEventTouch)
	end
end
