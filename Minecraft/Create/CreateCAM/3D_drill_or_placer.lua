-- Данная программа позволит запустить 3D шахту / заполнитель
-- Для работы этой версии программы требуется мод Project Red или More Red
-- Для запуска без них используйте альтернатуивную версию

-- Направление вращения должно быть ПРОТИВ ЧАСОВОЙ СТРЕЛКИ
-- Таймер сдвига оси на 1 блок при скорости вращения в 256 RPM
local step_256 = 0.225
-- Размер шахты, включая нулевую позицию
local speed_X, speed_Y, speed_Z = step_256, step_256, step_256 * 1.25
local X_size = 10
local Y_size = 10
local Z_size = 10
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
local signal_Z         = out_X_move + out_Y_move + out_Z_move
local signal_Z_reverse = out_X_move + out_Y_move + out_Z_move + out_reverse

function math.sign(val)
	if val < 0 then
		return -1
	end
	return 1
end

-- Пересчёт времени прохода вдоль оси на указанный шахты
function update_speed_X(length)
	length = length or (X_size-1)
	print("l ",length)
	if math.abs(length) == 1 then
		return speed_X
	end
	return (length/10) + 0.25
end
function update_speed_Y(length)
	length = length or (Y_size-1)
	if math.abs(length) == 1 then
		return speed_Y
	end
	return (length/10) + 0.25
end
function update_speed_Z(length)
	length = length or (Z_size-1)
	if math.abs(length) == 1 then
		return speed_Z
	end
	return length * speed_Z
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

function move_line_Y(length)
	length = length or Y_size
	out_signal( signal_Y)
	sleep(update_speed_Y(length))
	out_signal(0)
	sleep(0.1)
end
function move_line_Z(length)
	length = length or Z_size
	out_signal( signal_Z)
	sleep(update_speed_Z(length))
	out_signal(0)
	sleep(0.2)
end
function move_line_X_reverse(length)
	length = length or X_size
	out_signal( signal_X_reverse)
	sleep(update_speed_X(length))
	out_signal(0)
	sleep(0.1)
end
function move_line_Y_reverse(length)
	length = length or Y_size
	out_signal( signal_Y_reverse)
	sleep(update_speed_Y(length))
	out_signal(0)
	sleep(0.1)
end
function move_line_Z_reverse(length)
	length = length or Z_size
	out_signal( signal_Z_reverse)
	sleep(update_speed_Z(length))
	out_signal(0)
	sleep(0.2)
end

-- Возврат в координатный ноль
function zero_X()
	move_line_X_reverse()
end
function zero_Y()
	move_line_Y_reverse()
end
function zero_Z()
	move_line_Z_reverse()
end

-- Обнуление всех осей
function zero_all()
	zero_Z()
	zero_layer()
end
-- Обнуление осей X и Y, на случай вылета программы/игры
function zero_layer()
	for i = 1, 10 do
		if not isColorOn(in_X_zero) then
			zero_X()
		end
		if not isColorOn(in_Y_zero) then
			zero_Y()
		end
		if isColorOn(in_X_zero + in_Y_zero) then
			return
		end
	end
	print("Can't zeroing axis!!!")
end
-- Построчно пройтись по одному слою
local b_Y_reverse = false
function move_layer(x, y)
	print(x, y)
	x = x or (math.abs(X_size)-1)*math.sign(X_size)
	y = y or (math.abs(Y_size)-1)*math.sign(Y_size)
	dx = math.abs(x)
	ix = math.sign(x)
	print("ix ",ix)
	for i = 1,dx do
		if b_Y_reverse then
			m_y(-y)
		else
			m_y(y)
		end
		b_Y_reverse = not b_Y_reverse
		if i ~= dx then
			m_x(ix)
		end
	end
	--zero_layer()
end
-- Построчно пройтись по одному слою И сдвинуться на следующий
function iterate_layer(x, y)
	print(x, y)
	move_layer(x, y)
	zero_layer()
	move_line_Z(1)
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
function split_size(data)
	local ret={}
	for v in string.gmatch(data, "([^_,.:]+)") do
			ret[#ret+1] = v
	end
	return ret[1], ret[2]
end

function m_x(steps)
	print("m_x", steps)
	steps = tonumber(steps) or 1
	if steps > 0 then
		out_signal(signal_X)
	elseif steps < 0 then
		out_signal(signal_X_reverse)
	end
	sleep(update_speed_X(steps))
	out_signal(0)
	sleep(0.1)
end
function m_y(steps)
	steps = tonumber(steps) or 1
	if steps > 0 then
		out_signal(signal_Y)
	elseif steps < 0 then
		out_signal(signal_Y_reverse)
	end
	sleep(update_speed_Y(steps))
	out_signal(0)
	sleep(0.1)
end
function m_z(steps)
	steps = tonumber(steps) or 1
	if steps > 0 then
		out_signal(signal_Z)
	elseif steps < 0 then
		out_signal(signal_Z_reverse)
	end
	sleep(update_speed_Z(steps))
	out_signal(0)
	sleep(0.2)
end


-- Именовынные алгоритмы для создания своих более сложных алгоритмов (3D заполнение или добыча)
-- При необходимости можете добавить свои алгоритмы (пирамиды или иное) сюда
local movement_names = {
	["+A"] = activator_on, ["-A"] = activator_off, ["A"] = activator_switch,
	["X"] = m_x, ["Y"] = m_y, ["Z"] = m_z, 
	["0X"] = zero_X, ["0Y"] = zero_Y, ["0Y"] = zero_Y, 
	["oX"] = zero_X, ["oY"] = zero_Y, ["oY"] = zero_Y, 
	["0XY"] = zero_layer, ["0XYZ"] = zero_all, 
	["XY"] = nil, ["XYZ"] = nil,
	["T"] = nil, ["P"] = nil
}


--Ваш кастомный алгоритм
local test_moves = [[
0XYZ
XY
]]
-- Проверка на аргументы, иначе вызываем без них
function try_move(data)
	if data:sub(1,1) == "T" then -- Пауза
		sleep(tonumber(data:sub(2)) or 1)
	elseif data:sub(1,3) == "XYZ" then -- Пройтись по слою
		iterate_layer(split_size(data:sub(4)))
	elseif data:sub(1,2) == "XY" then -- Пройтись по слою
		move_layer(split_size(data:sub(3)))
	elseif data:sub(1,1) == "P" then -- Печать в консоль
		print(data:sub(2))
	elseif data:sub(1,1) == "X" then -- Двигаться вдоль X
		m_x(tonumber(data:sub(2)))
	elseif data:sub(1,1) == "Y" then -- Двигаться вдоль Y
		m_y(tonumber(data:sub(2)))
	elseif data:sub(1,1) == "Z" then -- Двигаться вдоль Z
		m_z(tonumber(data:sub(2)))
	elseif movement_names[data] then -- Любое другое движение
		movement_names[data]()
	else
		print("Unknown movement '"..data.."'")
	end
end
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

-- Расскоментируйте, чтобы выполнить кастомный алгоритм
do_test_moves()
-- Расскоментируйте, чтобы выполнить алгоритм из вншнего файла
--do_test_file("pyramid.txt")