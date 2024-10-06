local c = require 'create_util'

local stress = c:Stressometer()
local rot = c:RotationSpeedController()
local display = c:DisplayLink()
if stress == nil then
	error("Can't connect to Stressometr")
elseif rot == nil then
	error("Can't connect to Rotation Speed Controller")
end
-- Конфиги
settings.define("StressControl.Step",{
	description = "Step value for rotation",
	default = 1,
	type = "number",
})
settings.define("StressControl.Max",{
	description = "Max speed value for rotation",
	default = 256,
	type = "number",
})
settings.define("StressControl.Sign",{
	description = "Sign value for rotation",
	default = 1,
	type = "number",
})
settings.define("StressControl.Mode",{
	description = "Work mode: 0 - slow, 1 - fast",
	default = 1,
	type = "number",
})

local SPEED_STEP = settings.get("StressControl.Step")
local SPEED_MAX = settings.get("StressControl.Max")
local SPEED_SIGN = settings.get("StressControl.Sign")
local SPEED_MODE = settings.get("StressControl.Mode")
local SPEED_SIGN_STR = {[1]='+', [-1]='-'}
local MODE_STR = {[0]='SLOW',[1]='FAST'}

local delta = 0
local stop = false
local stress_buf = nil

local SpeedMode = {slow=0, fast=1}

-- Проверка на возможность ускориться
function canUp()
	return (stress.stress + delta * SPEED_STEP <= stress.cap) and (rot.abs + SPEED_STEP <= SPEED_MAX)
end
function fastSpeedChange()
	p = stress.use
	if p ~= 0.0 or tostring(p) == 'nan' then
		rot.speed = math.min(SPEED_MAX, math.floor(rot.abs / p))*SPEED_SIGN
	else
		rot.speed = SPEED_MAX * SPEED_SIGN
	end
end
-- Калибровка пороговой скорости вращения
function calibrate(force)
	if rot.dir ~= SPEED_SIGN then rot.inv() end
	if force then
		rot.speed = SPEED_MAX * SPEED_SIGN
		sleep(0.05)
	end
	while stress.overload do
		rot.speed = rot.abs - SPEED_SIGN
		sleep(0.05)
		draw()
	end
	delta = stress.stress
	rot.speed = rot.speed - SPEED_SIGN
	sleep(0.05)
	delta = delta - stress.stress
	draw()
	rot.speed = rot.speed + SPEED_SIGN
end
-- Ускоряемся
function goUp()
	if not canUp() then
		return
	end
	rot.speed = rot.speed + SPEED_STEP * SPEED_SIGN
	sleep(0.05)
end
-- Замедляеся
function goDown()
	if rot.abs < SPEED_STEP then
		return
	end
	rot.speed = rot.speed - SPEED_STEP * SPEED_SIGN
	sleep(0.05)
end

function getStressColor()
	s = stress.use
	if s < 0.25 then return colors.lime
	elseif s < 0.50 then return colors.green
	elseif s < 0.75 then return colors.yellow
	elseif s < 1 then return colors.orange end
	return colors.red
end

function getStatus()
	if rot.speed == 0 then return 'STOP    ', nil, colors.magenta
	elseif stress.overload then return 'OVERLOAD', nil, colors.red
	end
	return 'WORKING ', nil, colors.green
end

function draw()
	if display ~= nil then
		display.setPos(1,1)
		display.clearLine()
		display.write(string.format('Stress: %.0f%%', stress.use*100.0))
		display.setPos(1,2)
		display.clearLine()
		display.write(string.format('%i/%i|%i', stress.stress, stress.cap, delta))
		display.setPos(1,3)
		display.clearLine()
		display.write(string.format('Speed: %s%i', SPEED_SIGN_STR[SPEED_SIGN], SPEED_STEP))
		display.setPos(1,4)
		display.clearLine()
		display.write(string.format('%i/%i', rot.speed, SPEED_MAX*SPEED_SIGN))
		display.update()
	end
	term.setCursorPos(1,3)
	term.clearLine()
	writeColor(string.format('  Stress: %i/%i [%.0f%%] <%i>', stress.stress, stress.cap, stress.use*100.0, delta), _, getStressColor())
	term.setCursorPos(1,4)
	term.clearLine()
	writeColor(string.format('  Speed: %i/%i [%s%i]', rot.speed, SPEED_MAX*SPEED_SIGN, SPEED_SIGN_STR[SPEED_SIGN], SPEED_STEP))
	term.setCursorPos(9,2)
	writeColor(getStatus())
	term.setCursorPos(29,2)
	writeColor(MODE_STR[SPEED_MODE], _, colors.pink)
end

function writeColor(text, bg, fg)
	text = text or ""
	if term.isColor() then
		bg = bg or colors.black
		fg = fg or colors.white
		term.setTextColor(fg)
		term.setBackgroundColor(bg)
	end
	term.write(text)
end

function nextLine(x)
	x = x or 1
	_x, y = term.getCursorPos()
	term.setCursorPos(x, y+1)
end

function prepareTerminal()
	term.clear()
	term.setCursorPos(1,1)
	writeColor('Stress Controller', _, colors.orange)
	writeColor(' by ')
	writeColor('PavelKom ', _, colors.red)
	writeColor('github.com/PavelKom', _, colors.blue)
	nextLine()
	writeColor('Status:               Mode:')
	term.setCursorPos(1,5)
	writeColor('Control buttons:')
	nextLine()
	writeColor('  1 - Set maximum speed', _, colors.red)
	nextLine()
	writeColor('  2 - Set speed to 0', _, colors.green)
	nextLine()
	writeColor('  3 - Invert rotation', _, colors.blue)
	nextLine()
	writeColor('  4 - STOP/RESUME MACHINE', _, colors.magenta)
	nextLine()
	writeColor('  5 - Calibrate', _, colors.lime)
	nextLine()
	writeColor('  6 - Change mode', _, colors.pink)
	nextLine()
	nextLine()
	writeColor('  Q/W/A/S - Step  +1/+10/-1/-10', _, colors.cyan)
	nextLine()
	writeColor('  E/R/D/F - Speed +1/+10/-1/-10', _, colors.orange)
	writeColor()
end

-- Лямбда-функции при нажатии кнопок
buttonMap = {
	[49] = function() rot.set(rot.dir * SPEED_MAX) end, -- 1
	[50] = function() -- 2
		rot.set(0)
		draw()
		end,
	[51] = function() -- 3
		SPEED_SIGN = SPEED_SIGN * (-1)
		rot.inv()
		settings.set("StressControl.Sign", SPEED_SIGN)
		draw()
		end,
	[52] = function() -- 4
		rot.switch()
		draw()
		end,
	[53] = function() calibrate() end, -- 5
	[54] = function() -- 6
		SPEED_MODE = (SPEED_MODE + 1) % 2
		settings.set("StressControl.Mode", SPEED_MODE)
		doJob(true)
		end,
	[81] = function() -- Q    Step+1
		SPEED_STEP = math.min(256,SPEED_STEP + 1)
		settings.set("StressControl.Step", SPEED_STEP)
		doJob(true)
		end,
	[87] = function() -- W    Step+10
		SPEED_STEP = math.min(256,SPEED_STEP + 10)
		settings.set("StressControl.Step", SPEED_STEP)
		doJob(true)
		end,
	[65] = function() -- A    Step-1
		SPEED_STEP = math.max(1,SPEED_STEP - 1)
		settings.set("StressControl.Step", SPEED_STEP)
		doJob(true)
		end,
	[83] = function() -- S    Step-10
		SPEED_STEP = math.max(1,SPEED_STEP - 10)
		settings.set("StressControl.Step", SPEED_STEP)
		doJob(true)
		end,
	[69] = function() -- E    Speed+1
		SPEED_MAX = math.min(256,SPEED_MAX + 1)
		settings.set("StressControl.Max", SPEED_MAX)
		doJob(true)
		end,
	[82] = function() -- R    Speed+10
		SPEED_MAX = math.min(256,SPEED_MAX + 10)
		settings.set("StressControl.Max", SPEED_MAX)
		doJob(true)
		end,
	[68] = function() -- D    Speed-1
		SPEED_MAX = math.max(0,SPEED_MAX - 1)
		settings.set("StressControl.Max", SPEED_MAX)
		doJob(true)
		end,
	[70] = function() -- F    Speed-10
		SPEED_MAX = math.max(0,SPEED_MAX - 10)
		settings.set("StressControl.Max", SPEED_MAX)
		doJob(true)
		end,
}




function doJob(no_loop)
	while true do
		if not rot.is_stopped then
			if SPEED_MODE == SpeedMode.fast then
				fastSpeedChange()
			elseif stress.overload then
				calibrate()
			elseif rot.abs > SPEED_MAX then
				goDown()
			else
				goUp()
			end
		end
		draw()
		if no_loop then return end
		sleep(1)
	end
end

function doEvents()
	local eventData = nil
	while true do
		eventData = {os.pullEvent("key")}
		--for k,v in pairs(eventData) do
		--	print(k,v)
		--end
		f = buttonMap[eventData[2]]
		if f ~= nil then
			f()
		end
	end
end

-- Основной рабочий цикл
prepareTerminal()
calibrate()
parallel.waitForAll(doJob, doEvents)



