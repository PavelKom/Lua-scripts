local Monitor = require "epf.cc.monitor"
local Stress = require "epf.create.stress"
local RSC = require "epf.create.rsc"

local mon = Monitor()
local stress = Stress()
local rsc = RSC()

mon.scale = 2

local delta = 0

local pos_time = 7
local pos_speed = 8
local pos_cur_stress = 18
local pos_max_stress = 18
local pos_load_stress = 18
local pos_delta = 9

local function prepare()
	mon.clear()
	mon.pos()
	mon.fg = colors.white
	mon.print("Time: ")
	mon.print("Speed: ")
	mon.print("Stress current:  ")
	mon.print("Stress capacity: ")
	mon.print("Stress used(%):  ")
	mon.print("Delta:  ")
	
end

local function time_format(nTime)
	local h, m, s
	h, m = math.modf(nTime)
	m, s = math.modf(m*60)
	s = math.modf(s*60)
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function calibrate()
	local _stress = stress.stress
	rsc.speed = rsc.speed - 1
	sleep(0)
	delta = _stress - stress.stress
end

local function run()
	--local cur_time = textutils.formatTime(os.time('local'))
	mon.pos(pos_time,1)
	mon.fg = colors.cyan
	mon.print(time_format(os.time('local')), pos_speed)
	
	local used = stress.use
	local c = colors.red
	if used < 0.75 then c = colors.green
	elseif used < 0.9 then c = colors.yellow
	end
	
	mon.fg = c
	mon.print(("%.3i  "):format(rsc.abs), pos_cur_stress)
	mon.print(("%.5i   "):format(stress.stress), pos_max_stress)
	mon.fg = colors.magenta
	mon.print(("%.5i   "):format(stress.cap), pos_load_stress)
	mon.fg = c
	mon.print(("%.2f   "):format(used*100), pos_delta)
	mon.print(("%.3i   "):format(delta))
	
	if stress.overload and rsc.speed > 0 then
		rsc.speed = rsc.speed - 1
		return 0
	elseif stress.stress + delta < stress.cap then
		rsc.speed = rsc.speed + 1
		sleep(0)
		if stress.overload then calibrate() end
		return 0
	end
	return 1
end
prepare()
calibrate()
while true do
	local res, err = pcall(run)
	if not res then
		mon()
		print(err)
	else
		sleep(err)
	end
end
