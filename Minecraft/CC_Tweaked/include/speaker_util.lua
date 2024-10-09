--[[
	Speaker Utility library by PavelKom.
	Version: 0.7
	Wrapped Printer
	https://tweaked.cc/peripheral/monitor.html
	TODO: Add manual
		  Add cc.audio.dfpwm support for playAudio
		  
		  
]]
getset = require 'getset_util'

local this_library = {}
this_library.DEFAULT_STRESSOMETER = nil

this_library.INSTRUMENTS = {"harp", "basedrum", "snare", "hat", "bass", "flute", "bell", "guitar", "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling"}
for k,v in pairs(this_library.INSTRUMENTS) do
	this_library.INSTRUMENTS[string.upper(v)] = v
end
setmetatable(this_library.INSTRUMENTS, {__index = getset.GETTER_TO_UPPER(this_library.INSTRUMENTS.BASS)})

function this_library:Speaker(name)
	local def_type = 'speaker'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Speaker '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end

	ret.__getter = {}
	ret.__setter = {}
	
	ret.note = function(instrument, volume, pitch) 
		--local res, err = pcall(ret.object.playNote, this_library.INSTRUMENTS[instrument], volume, pitch)
		--return res and err or res, err
		return ret.object.playNote(this_library.INSTRUMENTS[instrument], volume, pitch)
	end
	ret.sound = function(name, volume, pitch)
		--local res, err = pcall(ret.object.playSound, name, volume, pitch)
		--return res and err or res, err
		return ret.object.playSound(name, volume, pitch)
	end
	ret.audio = function(audio, volume) 
		local res, err = pcall(ret.object.playAudio, audio, volume)
		return res and err or res, err
	end
	ret.stop = function() ret.object.stop() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

function.this_library:Speakers()
	local def_type = 'speaker'
	local _speakers = {peripheral.find(def_type)}
	if #_speakers == 0 then error("Can't find any Speaker") end
	local ret = {speakers={}}
	for _,s in pairs(_speaker) do
		ret.speakers[#ret.speakers+1]=this_library:Speaker(peripheral.getName(s))
	end
	
	ret.__getter = {}
	ret.__setter = {}
	
	ret.note = function(instrument, volume, pitch)
		for _, s in pairs(ret.speaker) do
			pcall(s.note,this_library.INSTRUMENTS[instrument], volume, pitch)
		end
	end
	ret.sound = function(name, volume, pitch)
		for _, s in pairs(ret.speaker) do
			pcall(s.sound,name, volume, pitch)
		end
	end
	ret.audio = function(audio, volume)
		for _, s in pairs(ret.speaker) do
			pcall(s.audio,audio, volume)
		end
	end
	ret.stop = function() ret.object.stop() end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

function this_library:BoomBox()
	local ret = {playlist={}}
	ret.speakers=this_library:Speakers()
	ret.soundlist = this_library:SoundList()
	local current_track = ""
	local duration = 0
	ret.__getter = {
		track = function() return current_track end,
		duration = function() return duration end,
	}
	ret.__setter = {
	}
	
	
	
	
	
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end


function this_library.subfolders(tbl, path_tbl, original_path)
	if #path_tbl == 0 then
		tbl.name = original_path
		return
	end
	local _p = path_tbl[1]
	tbl[_p] = tbl[_p] or {}
	table.remove(path_tbl,1)
	this_library.subfolders(tbl[_p], path_tbl, original_path)
end

--[[
In .minecraft/assets/indexes/<mc_version>.json find:
"minecraft/sounds.json": {
	"hash": "<hash>",
	"size": <size>
},
Example for 1.19.2 :
"minecraft/sounds.json": {
	"hash": "a1daff5daa55f870c29becece97fc88e3da0b18e",
	"size": 412960
},
Goto .minecraft/assets/objects/a1 (a1 the first two characters in hash).
Copy a1daff5daa55f870c29becece97fc88e3da0b18e file to computer folder, rename (like sounds.json)
Create  SoundList() object, it's autogenerate sounds.txt
]]
function this_library:SoundList()
	local ret = {files = {}, paths = {}}
	
	ret.__getter = {
		count = function() return #ret.files end,
	}
	ret.__setter = {}
	
	ret.reload = function(path)
		path = path or 'sounds.txt'
		local _file = io.open(path,'r')
		if _file == nil then
			this_library.generateSoundList(_, path)
			_file = io.open(path,'r')
		end
		if _file == nil then
			error("[SoundList] Can't read sounds.txt\nRead speaker_util manual for fix this problem")
		end
		while #ret.files > 0 do table.remove(ret.files) end
		for line in _file:lines() do
			ret.files[#ret.files+1] = line
			
		end
		_file:close()
	end
	-- Get all sounds like tables [path][to][file].name = path.to.file
	ret.tree = function()
		if ret.paths and #ret.paths > 0 then return ret.paths end
		for _, file in pairs(ret.files) do
			this_library.subfolders(ret.paths, string.split(file, '.'), file)
		end
		return ret.paths
	end
	
	ret.dir = function(path)
		path = path or ''
		if not ret.paths then ret.tree() end
		local _path = string.split(path, '.') or {}
		local _tbl = table.copy(ret.paths)
		while #_path > 0 do
			if not _tbl[_path[1]] then error('Invalid path') end
			_tbl = _tbl[_path[1]]
			table.remove(_path,1)
		end
		local _f, _d = {}, {}
		for k,_ in pairs(_tbl) do
			if _tbl[k].name then _f[#_f+1] = k else _d[#_d+1] = k end
		end
		table.sort(_d)
		table.sort(_f)
		return _d, _f
	end
	
	ret.filter = function(path, regex)
		path = path or ''
		if not regex then path = string.gsub(path, '%.', '[.]') end
		local _result = {}
		for _,v in pairs(ret.files) do
			if string.find(v,path) then
				_result[#_result+1] = v
			end
		end
		return _result
	end
	
	ret.reload()
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return ret
end


function this_library.generateSoundList(path, path2)
	print('Gen')
	path = path or 'sounds.json'
	path2 = path2 or 'sounds.txt'
	--if string.sub(path, -4) ~= '.json' then path = path..'.json' end
	local f = io.open(path, 'r')
	local data = textutils.unserializeJSON(f:read('*a'))
	local filelist = {}
	for k, v in pairs(data) do
		filelist[#filelist+1] = k
	end
	f:close()
	
	local soundlist = io.open(path2,'w')
	table.sort(filelist)
	soundlist:write(table.concat(filelist,'\n'))
	soundlist:close()
end



-- Experimental
local peripheral_type = 'speaker'
local peripheral_name = 'Speaker'
local Peripheral = {}
Peripheral.__items = {}
Peripheral.note = function(obj) return function(instrument, volume, pitch) obj.object.playNote(this_library.INSTRUMENTS[instrument], volume, pitch) end end
Peripheral.sound = function(obj) return function(name, volume, pitch) obj.object.playSound(name, volume, pitch) end end
Peripheral.audio = function(obj) return function(audio, volume)
	local res, err = pcall(obj.object.playAudio, audio, volume)
	return res and err or res, err
end end
Peripheral.stop = function(obj) return function() obj.object.stop() end end
Peripheral.new = function(name)
	-- Wrap or find peripheral
	local object = name and peripheral.wrap(name) or peripheral.find(peripheral_type)
	if object == nil then error("Can't connect to "+peripheral_name+" '"..name or peripheral_type.."'") end
	-- If it already registered, return 
	if Peripheral.__items[peripheral.getName(object)] then
		return Peripheral.__items[peripheral.getName(object)]
	end
	-- Test for miss-type
	_name = peripheral.getName(object)
	_type = peripheral.getType(object)
	if _type ~= peripheral_type then error("Invalid peripheral type. Expect '"..peripheral_type.."' Present '"..type.."'") end

	setmetatable(self, {
		__index = getset.GETTER2(Peripheral), __newindex = getset.SETTER2(Peripheral), 
		__pairs = getset.PAIRS2(Peripheral), __ipairs = getset.IPAIRS2(Peripheral),
		__tostring = function(self)
			return string.format("%s '%s'", peripheral_name, self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	Peripheral.__items[_name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
this_library.Speaker_Ex = Peripheral

return this_library
