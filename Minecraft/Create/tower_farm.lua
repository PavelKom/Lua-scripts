
--Bundled info
local io_bundle_side = "right"
local i_bundle = 0

local sensor_top = colours.lightBlue
local sensor_bottom = colours.magenta
local sensor_layer = colours.orange
local sensor_reverse = colours.white
	
local output_main_reverse = colours.blue
local output_layer_job = colours.lime
local output_layer_reverse = colours.red


--Monitor info
local m_side = "back"
local s_job = {
	[-2] = {"Zeroing movement", colours.red},
	[-1] = {"Move to base", colours.orange},
	[0] = {"Move to next layer", colours.lime},
	[1] = {"Combine forward", colours.cyan},
	[2] = {"Combine backward", colours.yellow}
}
local curr_layer = 0
local num_layers = 0

--Core vars
local delay = 0.5
local zeroing_delay = 0.0
local last_tick_off = true
local step = -2

-- Debug/Maintaining part
local d_keys = 0
local d_kv = {
	keys.one,
	keys.two,
	keys.three,
	keys.four,
	keys.five,
	keys.six,
	keys.seven,
	keys.eight,
	keys.nine,
	keys.zero
}
local d_strings = {
	"Zeroing movement (autodisable)",
	"Parking farmer to bottom",
	"Parking farmer to top",
	"Disable harvesting reverse",
	"NONE",
	"NONE",
	"NONE",
	"NONE",
	"NONE",
	"EXIT"
}
function isAllowedKey(key)
	for k,v in pairs(d_kv) do
	  if v == key then
		return k
	  end
	end
	return 0
end
function switchDebugBit(pos)
	if pos == 0 then
		return
	end
	local val = 2^pos
	if bit.band(d_keys, val) == 0 then
		d_keys = bit.bor(d_keys, val)
	else
		d_keys = bit.band(d_keys, bit.bnot(val))
	end
	printDebugInfo()
end
function waitForDebugInput()
	local e, key
	printDebugInfo()
	while true do
		repeat
			e, key = os.pullEvent("key")
		until key ~= 0
		if isAllowedKey(key) > 0 then
			switchDebugBit(isAllowedKey(key))
		end
	end
end
function printDebugInfo()
	term.clear()
	term.setCursorPos(1,1)
	term.setBackgroundColor(colours.black)
	term.setTextColor(colours.white)
	term.write("Debug info: ")
	term.write(step)
	term.write(" ")
	term.write(not last_tick_off)
	term.write(" ")
	term.write(io_bundle_side)
	
	term.setCursorPos(1,2)
	term.write("Use number buttons to turn debugging functions")
	term.setCursorPos(1,3)
	term.write("on/off")
	for k,v in pairs(d_kv) do 
		term.setCursorPos(1,k+3)
		term.setTextColor(colours.white)
		term.write(k % 10)
		term.write(" - ")
		if bit.band(d_keys, 2^k) == 0 then
			term.setBackgroundColor(colours.red)
		else
			term.setBackgroundColor(colours.green)
		end
		term.write(d_strings[k])
		term.setBackgroundColor(colours.black)
	end
end
function isDebugOn(key)
	return bit.band(d_keys, 2^key) ~= 0
end





function nextStep()
	if step < 0 then
		updateMovement()
		return
	end
	if step == 0 then
		if isDebugOn(5) then -- Block harvesting by debug
			return
		end
		curr_layer = curr_layer + 1
		num_layers = math.max(num_layers, curr_layer)
	elseif step == 1 and isDebugOn(4) then -- Block reverse by debug
		return
	end
	step = (step + 1) % 3
	updateMovement()
end
function updateMovement()
	--Outputs:
	--	white - main axle reverse; move farmer to base
	--	orange - block main axle; move farmer forward on layer
	--	magenta - reverse farmers axle; move farmer back on layer
	--	NONE - move to next layer
	if step == -2 then
		zeroing_delay = (zeroing_delay + delay) % 10.0
		if zeroing_delay < 5.0 then
			rs.setBundledOutput(io_bundle_side, 0)
		else
			rs.setBundledOutput(io_bundle_side, output_layer_job + output_layer_reverse)
		end
		if isColorOn(i_bundle, sensor_bottom + sensor_layer) then
			step = -1
		end
		return
	elseif step == -1 then
		rs.setBundledOutput(io_bundle_side, output_main_reverse) -- Move to top
	elseif step == 0 then
		rs.setBundledOutput(io_bundle_side, 0) -- Move to next layer
	elseif step == 1 then
		rs.setBundledOutput(io_bundle_side, output_layer_job) -- Move forward on layer
	else
		rs.setBundledOutput(io_bundle_side, output_layer_job + output_layer_reverse) -- Move backward on layer
	end
end

function isColorOn(val, color)
	return bit.band(val, color) ~= 0
end

function updateMonitor()
	local monitor = peripheral.wrap(m_side)
	if monitor == nil then
		return
	end
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.setBackgroundColor(colours.black)
	
	monitor.setTextColor(colours.white)
	monitor.write("Current status: ")
	monitor.setTextColor(s_job[step][2])
	monitor.write(s_job[step][1])
	
	monitor.setCursorPos(1,2)
	monitor.setTextColor(colours.white)
	monitor.write("Layers: ")
	monitor.setTextColor(colours.blue)
	monitor.write(curr_layer)
	monitor.setTextColor(colours.white)
	monitor.write(" / ")
	monitor.setTextColor(colours.purple)
	monitor.write(num_layers)
	
	monitor.setCursorPos(1,3)
	monitor.setTextColor(colours.white)
	monitor.write("On sensor: ")
	if last_tick_off then
		monitor.setTextColor(colours.red)
	else
		monitor.setTextColor(colours.green)
	end
	monitor.write(not last_tick_off)
	
	--monitor.setTextColor(colours.white)
	--monitor.setCursorPos(1,4)
	--monitor.write("Step: ")
	--monitor.write(step)
end
--print(shell.run("id"))

function doJob()
	while not isDebugOn(10) do
		sleep(delay)
		doJob2()
		updateMonitor()
	end
	term.clear()
	term.setCursorPos(1,1)
end
function doJob2()
	if isDebugOn(1) then
		step = -2
		switchDebugBit(1)
		return
	end
	i_bundle = rs.getBundledInput(io_bundle_side)
	if step == -2 then
		updateMovement()
		return
	end
	
	-- Start farming from top level
	if isColorOn(i_bundle, sensor_top) and last_tick_off  and not isDebugOn(3) then
		step = 0
		curr_layer = 0
		updateMovement()
		last_tick_off = false
	-- Move to top parking position
	elseif isColorOn(i_bundle, sensor_bottom)  and last_tick_off and not isDebugOn(2) then
		step = -1
		updateMovement()
		last_tick_off = false
	--Next farming step
	elseif isColorOn(i_bundle, sensor_layer + sensor_reverse) and last_tick_off then
		nextStep()
		last_tick_off = false
	elseif i_bundle == 0 then
		last_tick_off = true
	end
end

parallel.waitForAny(waitForDebugInput, doJob)


