--[[
	Event Utility library by PavelKom.
	Version: 0.9
	List of events and methods to listen them
	https://advancedperipherals.netlify.app/peripherals/player_detector/
	TODO: Add manual
]]

local lib = {}

--[[
All eventes return event name, ...
CC:Tweaked Events
alarm				number: The ID of the alarm that finished.

char				string: The string representing the character that was pressed.

computer_command	string…: The arguments passed to the command.

disk				string: The side of the disk drive that had a disk inserted.

disk_eject			string: The side of the disk drive that had a disk removed.

file_transfer		TransferredFiles: The list of transferred files.

http_check			string: The URL requested to be checked.
					boolean: Whether the check succeeded.
					string|nil: If the check failed, a reason explaining why the check failed.

http_failure		string: The URL of the site requested.
					string: An error describing the failure.
					http.Response|nil: A response handle if the connection succeeded, but the server's response indicated failure.

http_success		string: The URL of the site requested.
					http.Response: The successful HTTP response.

key					number: The numerical key value of the key pressed.
					boolean: Whether the key event was generated while holding the key (true), rather than pressing it the first time (false).

key_up				number: The numerical key value of the key pressed.

modem_message		string: The side of the modem that received the message.
					number: The channel that the message was sent on.
					number: The reply channel set by the sender.
					any: The message as sent by the sender.
					number|nil: The distance between the sender and the receiver in blocks, or nil if the message was sent between dimensions.

monitor_resize		string: The side or network ID of the monitor that was resized.

monitor_touch		string: The side or network ID of the monitor that was touched.
					number: The X coordinate of the touch, in characters.
					number: The Y coordinate of the touch, in characters.

mouse_click			number: The mouse button that was clicked.
					number: The X-coordinate of the click.
					number: The Y-coordinate of the click.

mouse_drag			number: The mouse button that is being pressed.
					number: The X-coordinate of the mouse.
					number: The Y-coordinate of the mouse.

mouse_scroll		number: The direction of the scroll. (-1 = up, 1 = down)
					number: The X-coordinate of the mouse when scrolling.
					number: The Y-coordinate of the mouse when scrolling.

mouse_up			number: The mouse button that was released.
					number: The X-coordinate of the mouse.
					number: The Y-coordinate of the mouse.

paste				string The text that was pasted.

peripheral			string: The side the peripheral was attached to.

peripheral_detach	string: The side the peripheral was detached from.

rednet_message		number: The ID of the sending computer.
					any: The message sent.
					string|nil: The protocol of the message, if provided.

redstone			---

speaker_audio_empty	string: The name of the speaker which is available to play more audio.

task_complete		number: The ID of the task that completed.
					boolean: Whether the command succeeded.
					string: If the command failed, an error message explaining the failure. (This is not present if the command succeeded.)
					…: Any parameters returned from the command.

term_resize			---

terminate			---

timer				number: The ID of the timer that finished.

turtle_inventory	---

websocket_closed	string: The URL of the WebSocket that was closed.
					string|nil: The server-provided reason the websocket was closed. This will be nil if the connection was closed abnormally.
					number|nil: The connection close code, indicating why the socket was closed. This will be nil if the connection was closed abnormally.

websocket_failure	string: The URL of the site requested.
					string: An error describing the failure.

websocket_message	string: The URL of the WebSocket.
					string: The contents of the message.
					boolean: Whether this is a binary message.

websocket_success	string: The event name.
					string: The URL of the site.
					http.Websocket: The handle for the WebSocket.

Advanced Peripherals
chat					username: string The username of the player who sent the message
						message: string The message sent by the player
						uuid: string The player's uuid
						isHidden: boolean Whether the message is hidden or not

playerClick				username: string The username of the player who clicked the block
						devicename: string The name of the peripheral like playerDetector_4

playerJoin				username: string The username of the player who clicked the block
						dimension: string The resource id of the dimension the player is in

playerLeave				username: string The username of the player who clicked the block
						dimension: string The resource id of the dimension the player was in

playerChangedDimension	username: string The username of the player who clicked the block
						fromDim: string The resource id of the dimension the player was in
						toDim: string The resource id of the dimension the player is in

crafting				success: boolean Indicates whether a crafting job has successfully started or not
						message: string A message about the status of the crafting job
]]

function lib.waitEventLoopEx(eventname,func)
	if func == nil then
		error('event_util.waitEventLoopEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEvent(eventname)})
	end
end
function lib.waitEventRawLoopEx(eventname,func)
	if func == nil then
		error('event_util.waitEventRawLoopEx must have callback function')
	end
	local loop = true
	while loop do
		loop = func({os.pullEventRaw(eventname)})
	end
end

return lib
