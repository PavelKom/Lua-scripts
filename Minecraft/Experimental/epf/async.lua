-- From 
-- https://computercraft.ru/topic/393-mnogopotochnost-v-computercraft/
-- https://pastebin.com/32S4HssH

-- Think method for autoupdate by time

local lib = {}

lib.pullEventRawBackup = os.pullEventRaw

local _filter_m = {
	__len=function(self)
		local i = 0
		for _,_ in pairs(self) do i = i + 1 end
		return i
	end
}
-- Patch for multishell loads
local mainThread={coroutine.running()}
local filter=setmetatable({},_filter_m)

function lib.updateThread()
	local running = coroutine.running()
	local toAdd = true
	for i=1, #mainThread do
		if running == mainThread[i] then
			toAdd = false
			break
		end
	end
	if toAdd then
		mainThread[#mainThread+1]=coroutine.running()
	end
end

local function SingleThread( _sFilter )
    return coroutine.yield( _sFilter )
end
local thread = false
local function MultiThread( _sFilter )
	for i=#mainThread, 1, -1 do
		if coroutine.running() == mainThread[i] then
			thread = true
			local event,co
			repeat
				event={coroutine.yield()}
				co=next(filter)
				if not co then os.pullEventRaw=SingleThread end
				while co do
					if coroutine.status( co ) == "dead" then
						filter[co],co=nil,next(filter,co)
					else
						if filter[co] == '' or filter[co] == event[1] or event[1] == "terminate" then
						local ok, param = coroutine.resume( co, unpack(event) )
						if not ok then filter={} error( param )
						else filter[co] = param or '' end
						end
						co=next(filter,co)
					end
				end
			until _sFilter == nil or _sFilter == event[1] or event[1] == "terminate"
			return unpack(event)
		end
		if type(mainThread[i]) ~= 'thread' or coroutine.status( mainThread[i] ) == "dead" then
			table.remove(mainThread, i)
		end
	end
  	return coroutine.yield( _sFilter )
end
 

function lib.create(f,...)
  os.pullEventRaw=MultiThread
  local co=coroutine.create(f)
  filter[co]=''
  local ok, param = coroutine.resume( co, ... )
  if not ok then filter={} error( param )
  else filter[co] = param or '' end
  lib.updateThread()
  return co
end
lib.think = lib.create
 
function lib.kill(co)
  filter[co]=nil
end

function lib.killAll()
  filter=setmetatable({},_filter_m)
  os.pullEventRaw=SingleThread
end

function lib.busy()
	return #filter > 0
end

return lib
