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
RS and ME Bridges allow connection to storage systems from Refined Storage and Applied Energetics respectively. Working with them is similar, but there are differences:
```lua
MEBridge = require "me_util"
RSBridge = require "rs_util"

me_bridge = MEBridge()
rs_bridge = RSBridge()

-- Gases and cells only for ME
gases = me_bridge.gases
cells = me_bridge.cells

-- Storage info for ME
me_bridge.totalItems
me_bridge.totalFluids
me_bridge.usedItems
me_bridge.usedFluids
me_bridge.availableItems
me_bridge.availableFluids

-- Storage info for RS
rs_bridge.iMaxDiskStorage
rs_bridge.fMaxDiskStorage
rs_bridge.iMaxExtStorage
rs_bridge.fMaxExtStorage
```
The rest of the methods and props are the same. Some methods require an *item={name=name,nbt=nbt,fingerprint=fingerprint}* (*name* or *fingerprint* required) as an argument. There are 3 options for these methods:

**.func(...,item,...)** - Get *item* table.

**.func2(...,name,nbt,...)** - Get **name** *string* and **nbt** *string* or *nil*.

**.func3(...,fingerprint,...)** - Get **fingerprint** *string*.
```lua
me_bridge.getItem({name='minecraft:cobblestone'})
me_bridge.getItem2('minecraft:cobblestone')
me_bridge.getItem3('0123456789ABCDEF')
```
### CraftTask and Trigger
```lua
trigger = require "trigger_util"
Trigger = trigger.Trigger
CraftTask = trigger.CraftTask
task = CraftTask('minecraft:furnace') -- Simple task
t = Trigger('minecraft:cobblestone') -- Simple trigger
```
Wrapped peripherals can work with crafting tasks that can be triggered by checking for item shortages/surpluses.
**CraftTask(item, isFluid, amount, batch, trigger)** - Crafting task, useful for autocrafting.
*item={name=name,...}* - Item table.
*isFluid* - Craft item or fluid.
*amount* - Target amount of product.
*batch* - How many items per call.
*trigger* - Trigger object or *nil* for autocreating.

**Trigger(item1, math_op1, const1, op, item2, math_op2, const2, logic, trigger)** - Complex trigger for CraftTask.

*item1={name=name,...}*- First item or *nil*.

*math_op1* - Name of math operation for item1. Default *MUL* (a*b)

*const1* - First constant. Default: 1

*op* - Comparison operator. Default: *LT* (a<b)

*item2* - Second item or *nil*.

*math_op2* - Math op for item2. Default *MUL* (a*b)

*const2* - Second constant. Default: trigger.DEFAULT_AMOUNT (1000)

*logic* - Logical operator to check the condition between *self* and the *self.trigger*.

*trigger* - Other trigger or *nil*.

How it works:
```lua
	-- From trigger_util.lua
	self.test = function(bridge) -- RS or ME Bridge
		local amount1 = self.const1
		if self.item1 ~= nil then -- Get item1 in bridge
			amount1 = MATH_LAMBDA[self.math_op1](bridge.object.getItem(self.item1), amount1) -- Multiply/divide/... value
		end
		local amount2 = self.const2
		if self.item2 ~= nil then -- Same for item2
			amount2 = MATH_LAMBDA[self.math_op2](bridge.object.getItem(self.item2), amount2)
		end
		local result = OP_LAMBDA[self.op](amount1, amount2) -- amount1 [~=<>] amount2
		if self.trigger ~= nil then -- result [and/or/xor/...] trigger.test()
			result = LOGIC_LAMBDA[self.logic](result, self.trigger.test(bridge))
		end
		return result
	end
```
Allowed operators:

*trigger.OP* - Table with comparison operators.

*trigger.MATH* - Table with mathematical functions.

*trigger.LOGIC_GATE* - Table with logic gates.

Example:
```lua
-- CHARCOAL
t = Trigger({name='minecraft:charcoal'})
--	'minecraft:charcoal'*1 < 1000
t2 = Trigger({name='minecraft:oak_log'}, _,_, lib.OP.GE)
--	'minecraft:oak_log'*1 > 1000

t.trigger = t2
--	('minecraft:charcoal'*1 < 1000) and ('minecraft:oak_log'*1 > 1000)
	
task = CraftTask('minecraft:charcoal',_,_,_,t)
-- Craft charcoal if: charcoal < 1000 AND oak logs > 1000

me_bridge.add_task(task)
```
**CraftTask**s and **Trigger**s can be loaded from json (*table* or *string*) and saved to json *table*.
ME and RS Bridges support loading(*table* or *string*)/saving(*table*) json for **CraftTask**s.
```lua
-- Export to config
local tbl = me_bridge.saveTasksToJson() -- Export tasks to table
local f = io.open('autocraft.json', 'w') -- Open config file
f:write(textutils.serializeJSON(tbl)) -- Write json-formatted info to file
f:close() -- Close config file

-- Import from config
local f = io.open('autocraft.json', 'r') -- Open json config with CraftTasks
local tbl = textutils.unserializeJSON(f:read('*a')) -- Read entire file
f:close() -- Don't forget close file
me_bridge.loadTasksFromJson(tbl, true) -- Load tasks into bridge, erase old tasks
```
