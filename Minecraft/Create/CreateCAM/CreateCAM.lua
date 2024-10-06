--[[
CreateCAM v0.9.1 by PavelKom
https://github.com/PavelKom
CNC-like drill/builder with extendable spindel and rails
G-code included on 1%   :^)
Used mods:
	Create        - mechanical part
	ComputerCraft - this code
	CC:Tweaked    - peripheral
]]
--[[
Методы движения и прочего, разделяются пробелами или переносом на следующую строку
A, G90 - Движение в абсолютной системе отсчёта (Absolute) ✓
B
C
D, G0 - Выключить активатор / холостой ход по прямой (Disable) ✓
E, G1 - Включить активатор / рабочий ход по прямой (Enable) ✓
F= - Выполнить внешний чертеж, макрос (File) ✓
G - используется для G-кодов
H
I - Шахматное заполнение
J - Краткосрочный импулься на шпиндель (вкл/выкл Блок-липучки)
K
L=%text% - Выполнить скрипт; loadstring(%text%); Аналог Eval(%text%) из других языков
M - Замощение слоя/прямоугольника (Matrix) ✓
N - Замощение слоя/прямоугольника + переход на слой ниже (Next) ✓
O
P - Печать в консоль, поддерживает \n, \t, \r, \\, \x. БЕЗ ПРОБЕЛОВ. Для пробела используйте \t, \r, \x20 (Print) ✓
Q - Полый прямоугольник
R, G91 - Относительная координата (Relative) ✓
S - Пауза в секундах (Sleep) ✓
T - Печать на монитор, поддерживает некоторые тех.символы (Text) ✓
U - Обнуление всех осей ✓
V - Скорость вращения осей (Velocity)
W
X - Координата X ✓
Y - Координата Y ✓
Z - Координата Z ✓
]]


-- Настройки

-- Время погрузки/разгрузки предметов
local unload_timer = 20
-- Множитель длины шага шпинделя, изменяйте, если добавляете активаторы на него
local axis_mult = {
	["X"] = 1,
	["Y"] = 1,
	["Z"] = 1
}
-- Размер карьера, по осям вычитайте 1, т.к. парковка происходит в (0,0,0)
-- Т.е. у карьера в 64 на 64 и в глубину 32 блока будет размер (63,63,-31)
local max_pos = {
	["X"] = 0,
	["Y"] = 0,
	["Z"] = 0
}
-- Стороны
local in_zero_side = "top" -- Вход датчика обнуления
local out_y_side = "back" -- Включение оси Y
local out_z_side = "left" -- Включение оси Z
local out_activator_side = "bottom" -- Вкл/выкл активатора
local out_blinker_side = "front" -- Подача краткого сигнала (для Блок-липучки)

--------------------------
-- НИЧЕГО НЕ МЕНЯЙТЕ НИЖЕ ЭТОЙ СТРОКИ, ЕСЛИ НЕ УВЕРЕНЫ В ТОМ, ЧТО ДЕЛАЕТЕ

settings.define("CreateCAM.X",{
	description = "CreateCAM X absolute position",
	default = 0,
	type = "number",
})
settings.define("CreateCAM.Y",{
	description = "CreateCAM Y absolute position",
	default = 0,
	type = "number",
})
settings.define("CreateCAM.Z",{
	description = "CreateCAM Z absolute position",
	default = 0,
	type = "number",
})
settings.define("CreateCAM.A",{
	description = "CreateCAM Movement type",
	default = 1,
	type = "number",
})
settings.define("CreateCAM.E",{
	description = "CreateCAM X activators is enabled",
	default = 1,
	type = "number",
})

local progs = {}
local c_steps = {}
local n_steps = {}
local stepname = ""
VAR = {}

-- Типы переферийных устройств
local gearbox_name = "Create_SequencedGearshift"
local monitor_name = "monitor"
local speed_name = "Create_RotationSpeedController"
local gearbox = peripheral.find(gearbox_name)
local monitor = peripheral.find(monitor_name)
local speed_controller = peripheral.find(speed_name)
if gearbox == nil then
	print("!!!Sequenced Gearshift NOT CONNECTED!!!")
	return
end
if monitor == nil then
	print("!!!Monitor NOT CONNECTED!!!")
	return
end
if speed_controller == nil then
	print("!!!Rotation Speed Controller NOT CONNECTED!!!")
	return
end

-- Получить знак числа
function math.sign(val)
	if val < 0 then
		return -1
	end
	return 1
end
-- Ограничить число между двумя другими
function math.clamp(val, low, high)
	low = low or 0
	high = high or 1
	return math.max(low, math.min(high, val))
end
-- Шпиндель припаркован
function isOnZero()
	return rs.getInput(in_zero_side)
end
-- Проверка на тип движения (абсолютный/относительный)
function isAbsolute()
	return getCurrPos("A") == 1
end
-- Включены ли активаторы на шпинделе
function isEnabled()
	return getCurrPos("E") == 1
end
function switchEnabled()
	setCurrPos("E", (getCurrPos("E")+1) % 2)
end
-- Установить значение сигнала с учетом работы активатора
function update_redstone(axis)
	rs.setOutput(out_activator_side, not isEnabled())
	rs.setOutput(out_y_side, axis == "Y" or axis == "Z")
	rs.setOutput(out_z_side, axis == "Z")
	sleep(0.1)
end
-- Получить текущую координату шпинделя, тип движения, активирован ли шпиндель
function getCurrPos(axis)
	return settings.get("CreateCAM."..axis)
--[[
	local f = io.open(".pos", "r")
	local _pos = {}
	if f == nil then
		_pos["X"] = 0
		_pos["Y"] = 0
		_pos["Z"] = 0
		_pos["A"] = 1
		_pos["E"] = 1
	else
		_pos["X"] = f:read() or 0
		_pos["Y"] = f:read() or 0
		_pos["Z"] = f:read() or 0
		_pos["A"] = f:read() or 1
		_pos["E"] = f:read() or 1
		f:close()
	end
	return tonumber(_pos[axis])]]
end
-- Установить данные
function setCurrPos(axis, pos)
	settings.set("CreateCAM."..axis, pos)
--[[
	local f = io.open(".pos", "r")
	local _pos = {}
	if f == nil then
		_pos["X"] = 0
		_pos["Y"] = 0
		_pos["Z"] = 0
		_pos["A"] = 1
		_pos["E"] = 1
	else
		_pos["X"] = f:read() or 0
		_pos["Y"] = f:read() or 0
		_pos["Z"] = f:read() or 0
		_pos["A"] = f:read() or 1
		_pos["E"] = f:read() or 1
		f:close()
	end
	_pos[axis] = pos
	f = io.open(".pos", "w+")
	f:write(math.floor(math.max(0,_pos["X"])).."\n")
	f:write(math.floor(math.max(0,_pos["Y"])).."\n")
	f:write(math.floor(math.min(0,_pos["Z"])).."\n")
	f:write(math.floor(math.clamp(_pos["A"],0,1)).."\n")
	f:write(math.floor(math.clamp(_pos["E"],0,1)).."\n")
	f:close()]]
end

-- G91 Относительное движение. Сдвинуться НА
function move_rel(axis, pos, force)
	if axis ~= "X" and axis ~= "Y" and axis ~= "Z" then
		print("Wrong axis "..axis)
		return
	end
	if force ~= true then
		if (axis == "X" or axis == "Y") then
			if getCurrPos(axis) + pos > max_pos[axis] then
				pos = max_pos[axis] - getCurrPos(axis)
			elseif getCurrPos(axis) + pos < 0 then
				pos = 0 - getCurrPos(axis)
			end
		else
			if getCurrPos(axis) + pos < max_pos[axis] then
				pos = max_pos[axis] - getCurrPos(axis)
			elseif getCurrPos(axis) + pos > 0 then
				pos = 0 - getCurrPos(axis)
			end
		end
	end
	update_redstone(axis)
	pos = pos * axis_mult[axis]
	gearbox.move(math.abs(pos),math.sign(pos))
	while gearbox.isRunning() do
		sleep(0.1)
	end
	if axis ~= "Z" then
		setCurrPos(axis, getCurrPos(axis) + pos)
	else
		setCurrPos(axis, getCurrPos(axis) - pos)
	end
	update_redstone()
	updateMonitor()
end

-- G90 Абсолютное движение. Сдвинуться В
function move_abs(axis, pos, force)
	if axis ~= "X" and axis ~= "Y" and axis ~= "Z" then
		print("Wrong axis "..axis)
		return
	end
	move_rel(axis, (pos - getCurrPos(axis))/math.abs(axis_mult[axis]), force)
end
-- Обнулить оси
function move_zero()
	for i=1,5 do
		if isOnZero() then
			print("Zeroing complete")
			setCurrPos("X", 0)
			setCurrPos("Y", 0)
			setCurrPos("Z", 0)
			updateMonitor()
			return
		end
		move_rel("Z", 0-max_pos["Z"], true)
		move_rel("Y", -max_pos["Y"]/axis_mult["Y"], true)
		move_rel("X", -max_pos["X"]/axis_mult["X"], true)
	end
	print("Can't zeroing axis!!!")
end
-- Произвести замощение слоя; есть возможность продолжения работы (экспериментальная ф-ция)
function move_matrix(x,y,z, cont)
	x = (tonumber(x) or max_pos["X"])/axis_mult["X"]
	y = (tonumber(y) or max_pos["Y"])/axis_mult["Y"]
	local ry = false
	local sx = math.sign(x)
	local ax = math.abs(x)
	local i = 0
	if cont == true then
		i = getCurrPos("X") + 1
		move_abs("Y", 0)
	end
	while i <= ax do
		move_rel("Y", ry and -y or y)
		ry = not ry
		if i ~= ax then
			move_rel("X", sx)
		end
		i = i + 1
	end
end
-- Произвести замощение с переходом на следующий слой
function move_next(x,y,z, cont)
	x = (tonumber(x) or max_pos["X"])/axis_mult["X"]
	y = (tonumber(y) or max_pos["Y"])/axis_mult["Y"]
	move_matrix(x,y, cont)
	--move_abs("Y", -y)
	--move_abs("X", -x)
	move_rel("Y", -y)
	move_rel("X", -x)
	--setCurrPos("X", 0)
	--setCurrPos("Y", 0)
	move_rel("Z", tonumber(z) or -1)
end
-- Сделать полый прямоугольник
function move_rect(x,y,z)
	x = (tonumber(x) or max_pos["X"])/axis_mult["X"]
	y = (tonumber(y) or max_pos["Y"])/axis_mult["Y"]
	move_rel("X", x)
	move_rel("Y", y)
	move_rel("X", -x)
	move_rel("Y", -y)
end
-- Шахматное заполнение
function move_checkers(x,y,z)
	x = (tonumber(x) or max_pos["X"])/axis_mult["X"]
	y = (tonumber(y) or max_pos["Y"])/axis_mult["Y"]
	z = (z == 0 or z == nil) and 0 or 1
	local v = speed_controller.getTargetSpeed()
	speed_controller.setTargetSpeed(256)
	setCurrPos("E", z)
	local bx, by = 0, 0
	local dx, dy, sx, sy = math.abs(x), math.abs(y), math.sign(x), math.sign(y)
	while bx <= dx do
		by = 0
		while by < dy do
			move_rel("Y", sy)
			switchEnabled()
			by = by + 1
		end
		sy = -sy
		if bx ~= x then
			move_rel("X", sx)
			switchEnabled()
		end
		bx = bx + 1
	end
	if ((dx+1)*(dy+1) % 2) == z then
		move_rel("Y", sy)
		switchEnabled()
		move_rel("Y", -sy)
	end
	speed_controller.setTargetSpeed(v)
end

-- Патч для переноса на другую строку на мониторах
-- ComputerCraft's "term" lib not support \n and \r
-- print("A\nBC") return
-- A
-- BC
-- term.write("A\nBC") return
-- A BC
function nextLine(obj)
	obj = obj or term
	local _, y = obj.getCursorPos()
	obj.setCursorPos(1, y + 1)
end
-- Обновить сообщение на мониторе
local buf_message = ""
function updateMonitor(message)
	if monitor == nil then
		return
	end
	if message ~= nil then
		buf_message = string.gsub(string.gsub(string.gsub(message, "\\t", "\t"), "\\n", "\n"), "\\r", "\r")
	end
	monitor.clear()
	monitor.setTextScale(1.5)
	monitor.setCursorPos(1,1)
	monitor.blit("CreateCAM v0.9", "CCCCCCEDBFEDCB", "FFFFFFFFFFFFFF")
	
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Current program: ")
	monitor.setTextColor(colours.green)
	monitor.write(progs[#progs] or "NONE")
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Subprograms: ")
	monitor.setTextColor(colours.yellow)
	monitor.write(("%d"):format(math.max(0,#progs-1)))
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Step: ")
	monitor.setTextColor(colours.cyan)
	monitor.write(stepname)
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Movement type: ")
	monitor.setTextColor(colours.lime)
	monitor.write(isAbsolute() and "abs" or "rel")
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Rotation speed: ")
	local s = speed_controller.getTargetSpeed()
	if s > 250 then
		monitor.setTextColor(colours.red)
	else
		monitor.setTextColor(colours.green)
	end
	monitor.write(("%d"):format(s))
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Activator enabled: ")
	monitor.setTextColor(colours.purple)
	monitor.write(isEnabled())
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Steps: ")
	monitor.setTextColor(colours.blue)
	monitor.write(("%d"):format(c_steps[#n_steps] or 0))
	monitor.setTextColor(colours.white)
	monitor.write("/")
	monitor.setTextColor(colours.purple)
	monitor.write(("%d"):format(n_steps[#n_steps] or 0))
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Size:     ")
	monitor.setTextColor(colours.red)
	local p1, p2 = monitor.getCursorPos()
	monitor.write(("%d"):format(max_pos["X"]))
	monitor.setCursorPos(p1+5, p2)
	monitor.setTextColor(colours.green)
	monitor.write(("%d"):format(max_pos["Y"]))
	monitor.setCursorPos(p1+10, p2)
	monitor.setTextColor(colours.blue)
	monitor.write(("%d"):format(max_pos["Z"]))
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Location: ")
	monitor.setTextColor(colours.red)
	local p1, p2 = monitor.getCursorPos()
	monitor.write(("%d"):format(getCurrPos("X")))
	monitor.setCursorPos(p1+5, p2)
	monitor.setTextColor(colours.green)
	monitor.write(("%d"):format(getCurrPos("Y")))
	monitor.setCursorPos(p1+10, p2)
	monitor.setTextColor(colours.blue)
	monitor.write(("%d"):format(getCurrPos("Z")))
	
	nextLine(monitor)
	monitor.setTextColor(colours.white)
	monitor.write("Message: ")
	nextLine(monitor)
	monitor.setTextColor(colours.pink)
	smartWrite(monitor, xc_replace(buf_message))
	
end


-- Выполнить процедуру из файла
function eval(data)
	stepname = data
	-- БЕЗ ПЕРЕМЕННЫХ
	-- Тип движения
	if data == "A" or data == "G90" then
		setCurrPos("A", 1)
		updateMonitor()
	elseif data == "R" or data == "G91" then
		setCurrPos("A", 0)
		updateMonitor()
	-- Активатор
	elseif data == "D" or data == "G0" then
		setCurrPos("E", 0)
		update_redstone()
		updateMonitor()
	elseif data == "E" or data == "G1" then
		setCurrPos("E", 1)
		update_redstone()
		updateMonitor()
	elseif data == "J" then
		rs.setOutput(out_blinker_side, true)
		sleep(0.2)
		rs.setOutput(out_blinker_side, false)
		sleep(0.1)
	
	-- Выполнить строку
	elseif data:sub(1,2) == "L=" then
		loadstring(xc_replace(data:sub(3)))()
	
	-- С ПЕРЕМЕННЫМИ
	-- Запуск файла
	elseif data:sub(1,2) == "F=" then
		file_from_name(data:sub(3))
	-- Печать в терминал
	elseif data:sub(1,1) == "P" then
		print(data:sub(2))
	-- Печать на монитор
	elseif data:sub(1,1) == "T" then
		updateMonitor(data:sub(2))
	-- Пауза в секундах
	elseif data:sub(1,1) == "S" then
		sleep(tonumber(data:sub(2)) or 0.1)
	elseif data:sub(1,1) == "U" then
		move_zero()
		sleep(tonumber(data:sub(2)) or 0.1)
	-- Скорость вращения
	elseif data:sub(1,1) == "V" then
		speed_controller.setTargetSpeed(math.min(256,math.abs(data:sub(2) or 256)))
		sleep(0.1)
		
	-- Замощение прямоугольника
	elseif data:sub(1,1) == "M" then
		move_matrix(split_size(data:sub(2)))
	elseif data:sub(1,1) == "N" then
		move_next(split_size(data:sub(2)))
	elseif data:sub(1,1) == "Q" then
		move_rect(split_size(data:sub(2)))
	elseif data:sub(1,1) == "I" then
		move_checkers(split_size(data:sub(2)))
	
	-- Движение по осям
	elseif data:sub(1,1) == "X" or data:sub(1,1) == "Y" or data:sub(1,1) == "Z" then 
		if isAbsolute() then
			move_abs(data:sub(1,1), tonumber(data:sub(2)) or 0)
		else
			move_rel(data:sub(1,1), tonumber(data:sub(2)) or 0)
		end
	end
end


-- Работа со строками
-- Многострочная печать на монитор
function smartWrite(obj, text)
	local lines_ = split_text_by_lines(text)
	for i, line in pairs(lines_) do
		obj.write(line)
		if i ~= #lines_ then
			nextLine(obj)
		end
	end
end
-- Исправление \x символов, \\x20 -> \x20
local xc_lib = {}
for i=1, 255 do
	if i < 10 then
		xc_lib["\\x0"..i] = string.char(i)
	else
		xc_lib["\\x"..i] = string.char(i)
	end
end
function xc_replace(data)
	for i, v in pairs(xc_lib) do
		data = string.gsub(data, i, v)
	end
	return data
end
-- Разбиение текста. Разделитель перенос на следующую строку
function split_text_by_lines(data)
	local ret = {}
	for token in string.gmatch(data, "[^"..string.char(10).."]+") do
		ret[#ret+1] = token
	end
	return ret
end
-- Разбиение текста. Разделитель пробелы, табуляция и новые строки
function split_text(data)
	local ret = {}
	for token in string.gmatch(data, "[^%s]+") do
		ret[#ret+1] = token
	end
	return ret
end
-- Разбиение файла на именнованные алгоритмы
-- Строки, начинающиеся с ; и * становятся комментариями
function split_file(path)
	local ret = {}
	local f = io.open(path)
	if f == nil then
		print("File '"..path.."'not exist")
		return ret
	end
	for l in f:lines() do
		--if l:sub(1,1) ~= "*" and l:sub(1,1) ~= ";" then
		if string.match(l:sub(1,1), "[*;]+") == nil then
			for _, v in pairs(split_text(l)) do
				ret[#ret+1] = v
			end
		end
	end
	f:close()
	return ret
end
-- Разделить строку с размерами
function split_size(data)
	local ret={}
	for v in string.gmatch(data, "([^_,.:]+)") do
			ret[#ret+1] = v
	end
	return ret[1], ret[2], ret[3]
end

-- Запуск кастомного алгоритма из внешнего файла
function do_test_file(path)
	local moves = split_file(path)
	n_steps[#n_steps+1] = #moves
	for _, move in pairs(moves) do
		eval(move)
		c_steps[#c_steps] = c_steps[#c_steps] + 1
	end
	table.remove(c_steps)
	table.remove(n_steps)
end
-- Проверка существования файла; запрос на TEST будет искать файлы TEST и TEST.txt; регистронезависимо (Windows)
function file_from_name(path)
	local ff = io.open(path)
	if ff == nil then
		path = path..".txt"
		ff = io.open(path)
	end
	if ff == nil then
		print("File '"..path.."' not exist")
	else
		ff:close()
		print("Reading file: "..path)
		progs[#progs+1] = path
		c_steps[#c_steps+1] = 0
		do_test_file(path)
	end
	table.remove(progs)
	updateMonitor()
end

local help_syntax = [[Methods must be separated by spaces or line breaks
Methods are performed step by step
Allowed methods:
U            - Zeroing axes
A, G90       - Set absolute position mode
R, G91       - Set relative position mode
D, G0        - Disable activator(s)
E, G1        - Enable activator(s)
F=%file%     - Load file like a sub-blueprint or macro
J            - Activate spindels redstone signal on 0.5 sec
L=%eval%     - Evaluate string
M%x%:%y%     - (M%x%%Colon%%y%) Fill the rectangle. The current position for it is 0:0.
               You can use negative values to move left:backward.
    M%x%     - Same as -M%x%:%max_pos[Y]%
    M        - Same as -M%max_pos[X]%:%max_pos[Y]%
N%x%:%y%:%z% - Fill the rectangle like -M%x%:%y% and move Z %z% blocks
    N%x%:%y% - Same as -N%x%:%y%:-1
    N%x%     - Same as -N%x%:%max_pos[Y]%:-1
    N        - Same as -N%max_pos[X]%:%max_pos[Y]%:-1
P%s%         - Print in the terminal. Support \\n and others
Q%x%:%y%     - Rectangle perimeter. The current position for it is 0:0.
               You can use negative values to move left:backward.
    Q%x%     - Same as Q%x%:%max_pos[Y]%
    Q        - Same as Q%max_pos[X]%:%max_pos[Y]%
I%x%:%y%:%z% - Checkers fill; if %z% is 0, place on odd coordinates (%x%+%y%)
I%x%:%y%     - Same as -I%x%:%y%:0
I%x%         - Same as -I%x%:%max_pos[Y]%:0
I            - Same as -I%max_pos[X]%:%max_pos[Y]%:0
T%s%         - Print on the monitor. Support \\n and others
S%f%         - Sleep for the specified time in seconds
S            - Same as -S0.1
V%i%         - Set the speed to the specified rpm value. Values: 0-256. 256 unsafe!
    V        - Same as -V256 (full speed)
X%i%, Y%i%, Z%i% - Move along the X/Y/Z axis -X/Y/Z same as -X0/Y0/Z0
;            - (Semicolon) A comment. ONLY FROM THE BEGINNING OF THE LINE
*            - (Asterisk) A comment. ONLY FROM THE BEGINNING OF THE LINE
]]
local help_str = [[Allowed keys:
-0, -O, -U    - Zeroing axes
-A, -G90      - Set absolute position mode
-R, -G91      - Set relative position mode
-D, -G0       - Disable activator(s)
-E, -G1       - Enable activator(s)
-H            - Print program launch help on monitor
-B            - Print blueprint syntax help on monitor
-I%x%:%y%:%z% - Checkers fill; if %z% is 0, place on odd coordinates (%x%+%y%)
-I%x%:%y%     - Same as -I%x%:%y%:0
-I%x%         - Same as -I%x%:%max_pos[Y]%:0
-I            - Same as -I%max_pos[X]%:%max_pos[Y]%:0
-J            - Activate spindels redstone signal on 0.5 sec
-M%x%:%y%     - (M%x%%Colon%%y%) Fill the rectangle. The current position for it is 0:0.
                You can use negative values to move left:backward.
-M%x%         - Same as -M%x%:%max_pos[Y]%
-M            - Same as -M%max_pos[X]%:%max_pos[Y]%
-N%x%:%y%:%z% - Fill the rectangle like -M%x%:%y% and move Z %z% blocks
-N%x%:%y%     - Same as -N%x%:%y%:-1
-N%x%         - Same as -N%x%:%max_pos[Y]%:-1
-N            - Same as -N%max_pos[X]%:%max_pos[Y]%:-1
-P%s%         - Print in the terminal. Support \\n and others
-Q%x%:%y%     - Rectangle perimeter. The current position for it is 0:0.
                You can use negative values to move left:backward.
-Q%x%         - Same as Q%x%:%max_pos[Y]%
-Q            - Same as Q%max_pos[X]%:%max_pos[Y]%
-T%s%         - Print on the monitor. Support \\n and others
-S%f%         - Sleep for the specified time in seconds. -S same as -S0.1
-V%i%         - Set the speed to the specified rpm value. Values: 0-256. 256 unsafe!
-V            - Same as -V256 (full speed)
-X%i%, -Y%i%, -Z%i% - Move along the X/Y/Z axis -X/Y/Z same as -X0/Y0/Z0
Reading files:
CreateCAM path/to/file second/file without/spaces
If you call a file, the program will try to run it as is
or with a .txt extension
file and .txt file
file.txt and file.txt.txt

]]

-- Провести стандартную раскопку
local input = { ... }
if #input == 0 then
	speed_controller.setTargetSpeed(256)
	move_zero()
	speed_controller.setTargetSpeed(255)
	updateMonitor("Digging normal")
	for z = max_pos["Z"],0 do
		if z ~= 0 then
			move_next()
		else
			move_matrix()
		end
		sleep(unload_timer)
	end
	move_zero()
else
	-- Выполнить процедуры по ключам или выполнить внешние чертежи
	for i = 1, #input do
		if input[i]:sub(1,1) == "-" then
			if input[i]:sub(2):upper() == "C" then
				updateMonitor("Continue digging")
				local z = max_pos["Z"] - getCurrPos("Z")
				while z <= 0 do
					if z ~= 0 then
						move_next(nil, nil, nil,true)
					else
						move_matrix(nil, nil, nil, true)
					end
					sleep(unload_timer)
				end
				move_zero()
			
			elseif input[i]:sub(2):upper() == "O" or input[i]:sub(2) == "0" or input[i]:sub(2) == "U" then
				eval("U")
			elseif input[i]:sub(2):upper() == "A" or input[i]:sub(2):upper() == "G90" then
				eval("A")
			elseif input[i]:sub(2):upper() == "R" or input[i]:sub(2):upper() == "G91" then
				eval("R")
			elseif input[i]:sub(2):upper() == "D" or input[i]:sub(2):upper() == "G0" then
				eval("D")
			elseif input[i]:sub(2):upper() == "E" or input[i]:sub(2):upper() == "G1" then
				eval("E")
			elseif input[i]:sub(2):upper() == "H" then
				print("Help printed on monitor")
				monitor.clear()
				monitor.setTextScale(0.5)
				monitor.setCursorPos(1,1)
				monitor.blit("CreateCAM v0.9", "CCCCCCEDBFEDCB", "FFFFFFFFFFFFFF")
				nextLine(monitor)
				monitor.setTextColor(colours.white)
				smartWrite(monitor, xc_replace(help_str))
			elseif input[i]:sub(2):upper() == "B" then
				print("Help printed on monitor")
				monitor.clear()
				monitor.setTextScale(0.5)
				monitor.setCursorPos(1,1)
				monitor.blit("CreateCAM v0.9", "CCCCCCEDBFEDCB", "FFFFFFFFFFFFFF")
				nextLine(monitor)
				monitor.setTextColor(colours.white)
				smartWrite(monitor, xc_replace(help_syntax))
			elseif input[i]:sub(2,2):upper() == "P" or
				   input[i]:sub(2,2):upper() == "T" or
				   input[i]:sub(2,2):upper() == "S" or
				   input[i]:sub(2,2):upper() == "V" or
				   input[i]:sub(2,2):upper() == "M" or
				   input[i]:sub(2,2):upper() == "N" or
				   input[i]:sub(2,2):upper() == "Q" or
				   input[i]:sub(2,2):upper() == "I" or
				   input[i]:sub(2,2):upper() == "J" or
				   input[i]:sub(2,2):upper() == "X" or
				   input[i]:sub(2,2):upper() == "Y" or
				   input[i]:sub(2,2):upper() == "Z" then
				eval(input[i]:sub(2,2):upper()..input[i]:sub(3))
			else
				file_from_name(input[i])
			end
		else
			for i = 1, #input do
				file_from_name(input[i])
			end
		end
	end


end
