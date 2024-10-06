-- Данная программа позволит запустить 3D шахту / заполнитель
-- Для работы этой версии программы требуется мод Project Red или More Red
-- Для запуска без них используйте альтернатуивную версию

-- Направление вращения должно быть ПРОТИВ ЧАСОВОЙ СТРЕЛКИ
-- Таймер сдвига оси на 1 блок при скорости вращения в 256 RPM
local step_256 = 0.225
local timed_z_step = 1/9
-- Размер шахты, включая нулевую позицию; разгружать каждые N слоёв в течении M секунд
local speed_X, speed_Y, speed_Z = step_256, step_256,  step_256 * 1.25
local X_size = 50
local Y_size = 50
local Z_size = 100
local unload_timer = 10
--Сторона подключения шины из модов Project Red и More Red
local io_bundled_side = "bottom"


-- Цвета входов/выходов
local in_X_zero = colours.white
local in_Y_zero = colours.orange
local out_reverse = colours.lightBlue
local out_X_move = colours.magenta
local out_Y_move = colours.yellow
local out_Z_move = colours.lime
local out_job_off = colours.pink

-- Выходные сигналы. Для работы оси Y, нужна включенная ось X, для Z - X и Y. Реверс используется для всех осей
local signal_X         = out_X_move
local signal_X_reverse = out_X_move                           + out_reverse
local signal_Y         = out_X_move + out_Y_move
local signal_Y_reverse = out_X_move + out_Y_move              + out_reverse
local signal_Z         = out_X_move + out_Y_move + out_Z_move + out_reverse
local signal_Z_reverse = out_X_move + out_Y_move + out_Z_move

-- Получить знак числа
function math.sign(val)
	if val < 0 then
		return -1
	end
	return 1
end
-- Пересчёт времени прохода вдоль оси на указанныe шаги
-- Откалиброванно до 64 блоков
function update_speed_X(length)
	length = length or (X_size-1)
	if math.abs(length) == 1 then
		return speed_X
	end
	return math.abs(length/10) + 0.2
end
-- Откалиброванно до 64 блоков
function update_speed_Y(length)
	length = length or (Y_size-1)
	if math.abs(length) == 1 then
		return speed_Y
	end
	return math.abs(length/10) + 0.2
end
-- Откалиброванно до 40 блоков
function update_speed_Z(length)
	length = length or (Z_size-1)
	if math.abs(length) == 1 then
		return speed_Z
	elseif 0 < length and length < 24 then
		return math.abs(length/10)
	--elseif 0 > length and length > -27 then
	--	return math.abs(length/10) + 0.3
	end
	return math.abs(length/10) + 0.3
end
-- Включать/отключать активатор
local b_disable_user = false
function signal_activator()
	return b_disable_user and out_job_off or 0
end
-- Установить значение сигнала с учетом работы активатора
function out_signal(val)
	val = val or 0
	rs.setBundledOutput(io_bundled_side, val + signal_activator())
end
function activator_on()
	b_disable_user = false
end
function activator_off()
	b_disable_user = true
end
function activator_switch()
	b_disable_user = not b_disable_user
end
-- condition and ifTrue or ifFalse
-- Движение вдоль оси
function move_x(steps)
	steps = tonumber(steps) or 1
	out_signal(steps > 0 and signal_X or signal_X_reverse)
	sleep(update_speed_X(steps))
	out_signal(0)
	sleep(0.1)
end
function move_y(steps)
	steps = tonumber(steps) or 1
	out_signal(steps > 0 and signal_Y or signal_Y_reverse)
	sleep(update_speed_Y(steps))
	out_signal(0)
	sleep(0.1)
end
function move_z(steps)
	steps = tonumber(steps) or 1
	out_signal(steps > 0 and signal_Z or signal_Z_reverse)
	sleep(update_speed_Z(steps))
	out_signal(0)
	sleep(0.1)
end
-- Обнуление осей
-- Обнуление осей X и Y, на случай вылета программы/игры
function zero_x()
	move_x(1-X_size)
end
function zero_y()
	move_y(1-Y_size)
end
function zero_z()
	move_z(Z_size)
end
function zero_layer()
	for i = 1, 10 do
		if not isColorOn(in_X_zero) then
			zero_x()
		end
		if not isColorOn(in_Y_zero) then
			zero_y()
		end
		if isColorOn(in_X_zero + in_Y_zero) then
			return
		end
	end
	print("Can't zeroing axis!!!")
end
function zero_all()
	zero_z()
	zero_layer()
end
-- Замощение слоя
function move_layer(x,y)
	local b_Y_reverse = false
	x = tonumber(x) or (X_size-1)
	y = tonumber(y) or (Y_size-1)
	lx = math.abs(x)
	sx = math.sign(x)
	for i = 0, lx do
		move_y(b_Y_reverse and -y or y)
		b_Y_reverse = not b_Y_reverse
		if i ~= lx then
			move_x(sx)
		end
	end
end
function iterate_layer(x,y)
	move_layer(x, y)
	zero_layer()
	move_z(-1)
end
-- Проверка, включен ли кабель в шине
function isColorOn(val, color)
	if color == nil then
		color, val = val, rs.getBundledInput(io_bundled_side)
	end
	return bit.band(val, color) ~= 0
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
-- Строки, начинающиеся с * становятся комментариями
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
			for k, v in pairs(split_text(l)) do
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
	return ret[1], ret[2]
end

-- Именовынные алгоритмы для создания своих более сложных алгоритмов (3D заполнение или добыча)
-- При необходимости можете добавить свои алгоритмы (пирамиды или иное) сюда
--[[
+A -A A   - вкл/выкл/переключить активатор
X Y Z     - движение вдоль осей, порядок важен! X10 - переместиться НА 10 клеток вправо
XY XYZ    - выполнить замощение слоя без/с переходом на следующий (вниз)
0X 0Y 0Z 0XY 0XYZ - обнуления
T - таймер, пауза T10 - пауза на 10 секунд
P - принт в консоль, поддерживает \n
;* в начале строки делает из неё комментарий

]]
local movement_names = {
	["+A"] = activator_on, ["-A"] = activator_off, ["A"] = activator_switch,
	["0X"] = zero_x, ["0Y"] = zero_y, ["0Z"] = zero_z, 
	["oX"] = zero_x, ["oY"] = zero_y, ["oZ"] = zero_z, 
	["0XY"] = zero_layer, ["0XYZ"] = zero_all
}
function try_move(data)
	if data:sub(1,1) == "T" then -- Пауза
		sleep(tonumber(data:sub(2)) or 1)
	elseif data:sub(1,3) == "XYZ" then
		iterate_layer(split_size(data:sub(4)))
	elseif data:sub(1,2) == "XY" then
		move_layer(split_size(data:sub(3)))
	elseif data:sub(1,1) == "P" then -- Печать в консоль
		print(data:sub(2))
	elseif data:sub(1,1) == "X" then -- Двигаться вдоль X
		move_x(tonumber(data:sub(2)))
	elseif data:sub(1,1) == "Y" then -- Двигаться вдоль Y
		move_y(tonumber(data:sub(2)))
	elseif data:sub(1,1) == "Z" then -- Двигаться вдоль Z
		move_z(tonumber(data:sub(2)))
	elseif movement_names[data] ~= nil then -- Любое другое движение
		movement_names[data]()
	else
		print("Unknown movement '"..data.."'")
	end
end
--Ваш кастомный алгоритм
local test_moves = [[
0XYZ
XY
0XYZ
]]
-- Запуск вашего кастомного алгоритма
function do_test_moves()
	for _, move in pairs(split_text(test_moves)) do
		try_move(move)
	end
end
-- Запуск кастомного алгоритма из внешнего файла
function do_test_file(path)
	for _, move in pairs(split_file(path)) do
		try_move(move)
	end
end
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
		do_test_file(path)
	end
end
-- Провести стандартную раскопку
function dig()
	zero_all()
	for z = 1,Z_size do
		if z < Z_size then
			iterate_layer()
		else
			move_layer()
		end
		sleep(unload_timer)
	end
	zero_all()
end

-- Расскоментируйте, чтобы выполнить кастомный алгоритм
--do_test_moves()
-- Расскоментируйте, чтобы выполнить алгоритм из внешнего файла
--do_test_file("pyramid.txt")

local input = { ... }
if #input == 0 then
	dig()
end
for i = 1, #input do
	file_from_name(input[i])
end


