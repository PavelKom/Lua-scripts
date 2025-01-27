# Advanced Peripherals
Tips and examples

## Advanced Reality Controller
Temporarily disabled by the mod authors.

## Chatbox
### Peripheral
```lua
ChatBox = require "chat_util"
cbox = ChatBox()
```
**cbox.msg(message,username,prefix,brackets,bracketColor,range, hidden)** - Broadcast message to all players (*username=nil*) or specific player(s)(*username="Alice"* or *username={"Alice", "Bob"}*). *prefix* - Message prefix (aka tag). *brackets* - Prefix brackets (*[]*,*<>*,...). *bracketColor* - Bracket color (see below). *range* - Broadcast range, ignore for global broadcast. *hidden* - Send hidden message.

**cbox.toast(message,title,username,prefix,brackets,bracketColor,range)** - Send toast to player(s) (achievent-like message).

**cbox.fmsg(json, username, prefix, brackets, bracketColor, range)** - Send formatted message. *json* can be table or already formatted message.

**cbox.ftoast(messageJson, titleJson, username, prefix, brackets, bracketColor, range)** - Same for toast.

Can be called without initialization.
```lua
ChatBox.msg("Hello World!")
```
### Events
**ChatBox.waitChatEvent()** - Wait single *chat* event.

**ChatBox.waitChatEventEx(func)** -- Create seme-infinite loop for catching *chat* event. *func* - Callback function. Must be *func(tbl)* and return *true* for continue catching events. Use with *parallel.waitForAny* for avoiding problems.
### Meta-tables
**ChatBox.CHATCOLORS** - A table with color and style constants to simplify text formatting. *ChatBox.CHATCOLORS.RED*, *ChatBox.CHATCOLORS['bold']* and others.
### Functions
**ChatBox.colorText(text, color, effect, resetToDefault)** - Make formatted text. *color*, *effect* - names from *ChatBox.CHATCOLORS*. *resetToDefault* - Reset next text to default color/style.
```lua
pretty_text = ChatBox.colorText("Hello ", "red", "bold")..ChatBox.colorText("World", "green", "italic")..ChatBox.colorText("!", "blue", "obfuscated", true)
cbox.msg(pretty_text)
```
## Colony Integrator
Peripheral for 'MineColonies' mod. Allows you to obtain various statistics on the colony.

Note: If you want to simplify micromanagement of upgrading colony buildings, use the mod "MineColonies for ComputerCraft", it has the ability to highlight buildings.

## Energy Detector
Allows you to read the rate of *FE* energy and set its limits.
```lua
EnergyDetector = require "energy_util"
ed = EnergyDetector()
print(ed.rate, ed.limit) -- Get current and max FE/t
ed.limit = 1000 -- Set max FE/t
```
Can be called without initialization.
```lua
EnergyDetector.setLimit(0) -- Block FE
```
## Environment Detector
Provides current information from the environment. Biome, time, weather, radiation (from *Mekanism* mod) and other.
Can be called without initialization.

## Geo Scanner
Provides information about blocks around it and the chunk of that it is in.
Can be called without initialization.

## Inventory Manager
Get information about player inventory and armor. Add/remove items to/from player.
```lua
InventoryManager = require "inventory_util"
inv = InventoryManager()
-- inv.add(side, name, fromSlot, toSlot, count, fingerprint, tag, nbt, components)
inv.add(InventoryManager.SIDES.UP, "minecraft:cobblestone",_,_,10)
-- inv.remove2(side, item) item = {name=name, ...}
inv.remove2(InventoryManager.SIDES.UP, {tag="#wood"})
Can be called without initialization.
```
Can be called without initialization.

## NBT Storage
Can store *nbt* data for later use.
Can be called without initialization.

## Player Detector
Get info about player(s) (online, position, hp, ...) on server/dimension/specific range.
Provides events when a player connects/disconnects/clicks a block/moves between dimensions. 
Can be called without initialization.
```lua
PlayerDetector = require "player_util"
getset = require "getset_util"
player_d = PlayerDetector()
for k,v in pairs(player_d.online) do -- Iterate all online players
	getset.printTable(v)
end
```
Working with ChatBox:
```lua
PlayerDetector = require "player_util"
ChatBox = require "chat_util"

pd = PlayerDetector()
cbox = ChatBox()

-- Event callback
function greetings_msg(event, username, dimension)
	cbox.toast(string.format("Welcome to our server, &b%s&r, enjoy the game", username), _, username,"","")
end
-- Loop wrapper
function join_event_loop()
	PlayerDetector.waitPlayerJoinEventEx(greetings_msg)
end
--
function main()
	-- Do job
end

parallel.waitForAny(main, join_event_loop)
```
## Block Reader
Get info about block.
```lua
BlockReader = require "reader_util"
getset = require "getset_util"
reader = BlockReader()
getset.printTable(reader.data)
```
Can be called without initialization.
## Redstone Integrator
Get/set redstone on every side. **Wire bundles are not supported.**
```lua
RedstoneIntegrator = require "redstone_util"
ri = RedstoneIntegrator()
-- Inputs/outputs. By metatables

print(ri.input.up) -- Get true/false
print(ri.input(RedstoneIntegrator.SIDES.UP)) -- Analog 0-15 value

print(ri.output.north) -- Get true/false
print(ri.output(RedstoneIntegrator.SIDES['north'])) -- Analog 0-15 value
ri.output.up = true -- Set boolean value
ri.output.north = 7 -- Set analog value
```
Can be called without initialization.
## ME and RS Bridges
***WIP***








