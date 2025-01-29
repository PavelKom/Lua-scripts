--[[
	Speaker Utility library by PavelKom.
	Version: 0.7.5
	Wrapped Speaker
	https://tweaked.cc/peripheral/speaker.html
	TODO: Add manual
		  Add cc.audio.dfpwm support for playAudio
		  
		  
]]
getset = require 'getset_util'

local lib = {}

lib.INSTRUMENTS = {"harp", "basedrum", "snare", "hat", "bass", "flute", "bell", "guitar", "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling"}
for k,v in pairs(lib.INSTRUMENTS) do
	lib.INSTRUMENTS[string.upper(v)] = v
end
setmetatable(lib.INSTRUMENTS, {__index = getset.GETTER_TO_UPPER(lib.INSTRUMENTS.BASS)})

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, Peripheral, 'Speaker')
	if wrapped ~= nil then return wrapped end
	
	self.__getter = {}
	self.__setter = {}
	
	self.note = function(instrument, volume, pitch) 
		--local res, err = pcall(self.object.playNote, lib.INSTRUMENTS[instrument], volume, pitch)
		--return res and err or res, err
		return self.object.playNote(lib.INSTRUMENTS[instrument], volume, pitch)
	end
	self.sound = function(name, volume, pitch)
		--local res, err = pcall(self.object.playSound, name, volume, pitch)
		--return res and err or res, err
		return self.object.playSound(name, volume, pitch)
	end
	self.audio = function(audio, volume) 
		local res, err = pcall(self.object.playAudio, audio, volume)
		return res and err or res, err
	end
	self.stop = function() self.object.stop() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Speaker",
		__subtype = "peripheral",
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[name] = nil end
end
lib.Speaker=setmetatable(Peripheral,{__call=Peripheral.new,__type = "peripheral",__subtype="speaker",})
lib=setmetatable(lib,{__call=Peripheral.new,__type = "library",__subtype="Speaker",})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

return lib
--[[
----------- OLD API
function.lib:Speakers()
	local def_type = 'speaker'
	local _speakers = {peripheral.find(def_type)}
	if #_speakers == 0 then error("Can't find any Speaker") end
	local self = {speakers={}}
	for _,s in pairs(_speaker) do
		self.speakers[#self.speakers+1]=lib:Speaker(peripheral.getName(s))
	end
	
	self.__getter = {}
	self.__setter = {}
	
	self.note = function(instrument, volume, pitch)
		for _, s in pairs(self.speaker) do
			pcall(s.note,lib.INSTRUMENTS[instrument], volume, pitch)
		end
	end
	self.sound = function(name, volume, pitch)
		for _, s in pairs(self.speaker) do
			pcall(s.sound,name, volume, pitch)
		end
	end
	self.audio = function(audio, volume)
		for _, s in pairs(self.speaker) do
			pcall(s.audio,audio, volume)
		end
	end
	self.stop = function() self.object.stop() end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return self
end

function lib:BoomBox()
	local self = {playlist={}}
	self.speakers=lib:Speakers()
	self.soundlist = lib:SoundList()
	local current_track = ""
	local duration = 0
	self.__getter = {
		track = function() return current_track end,
		duration = function() return duration end,
	}
	self.__setter = {
	}
	
	
	
	
	
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return self
end


function lib.subfolders(tbl, path_tbl, original_path)
	if #path_tbl == 0 then
		tbl.name = original_path
		return
	end
	local _p = path_tbl[1]
	tbl[_p] = tbl[_p] or {}
	table.remove(path_tbl,1)
	lib.subfolders(tbl[_p], path_tbl, original_path)
end


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
--[[
function lib:SoundList()
	local self = {files = {}, paths = {}}
	
	self.__getter = {
		count = function() return #self.files end,
	}
	self.__setter = {}
	
	self.reload = function(path)
		path = path or 'sounds.txt'
		local _file = io.open(path,'r')
		if _file == nil then
			lib.generateSoundList(_, path)
			_file = io.open(path,'r')
		end
		if _file == nil then
			error("[SoundList] Can't read sounds.txt\nRead speaker_util manual for fix this problem")
		end
		while #self.files > 0 do table.remove(self.files) end
		for line in _file:lines() do
			self.files[#self.files+1] = line
			
		end
		_file:close()
	end
	-- Get all sounds like tables [path][to][file].name = path.to.file
	self.tree = function()
		if self.paths and #self.paths > 0 then return self.paths end
		for _, file in pairs(self.files) do
			lib.subfolders(self.paths, string.split(file, '.'), file)
		end
		return self.paths
	end
	
	self.dir = function(path)
		path = path or ''
		if not self.paths then self.tree() end
		local _path = string.split(path, '.') or {}
		local _tbl = table.copy(self.paths)
		while #_path > 0 do
			if not _tbl[_path[1] ] then error('Invalid path') end
			_tbl = _tbl[_path[1] ]
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
	
	self.filter = function(path, regex)
		path = path or ''
		if not regex then path = string.gsub(path, '%.', '[.]') end
		local _result = {}
		for _,v in pairs(self.files) do
			if string.find(v,path) then
				_result[#_result+1] = v
			end
		end
		return _result
	end
	
	self.reload()
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Speaker '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	
	return self
end


function lib.generateSoundList(path, path2)
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

return lib
]]
