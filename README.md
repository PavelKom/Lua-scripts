# Lua scripts
## Factorio: LuaCombinator3
   Simple Lua scripts to simplify the game

  Scripts to simplify the process of automating mining, production, attack, and more.

  Supported mods:
  * AAI (vehicles, structures, zones)
  * Bob's mods (items and recipes)
  * Crafting Combinator
  * Recursive Blueprints


## Minecraft: ComputerCraft
  * `patches` - Patches for Lua (add table.copy, string.split and other functions). Must be required before others libraries.
  * `getset_util` - The main library that allows you to provide getters and setters to properties of class objects. It is mainly needed to create other wrappers for the peripherals.
  
  ```lua
  rsc = create_util:RotationSpeedController()
  rsc.speed -- same as rsc.getSpeed()
  rsc.speed = 5 -- same as rsc.setSpeed(5)
  ```
  
  ### WRAPPERS
  
  #### CC:Tweaked
  * `command_util` - Command Block
  * `computer_util` - Computer
  * `drive_util` - Drive
  * `modem_util` - Modem
  * `monitor_util` - Monitor. get/setCursorPosition wrapped as `pos` table. get/setPaletteColour as `palette` table.
  ```lua
  mon = monitor_util:Monitor()
  -- get/set cursor position
  print(mon.x,mon.y) -- "1 1"
  mon.x = 3
  mon.y = 5
  print(mon.pos.x,mon.pos.y,mon.pos.xy) -- "3, 5"
  mon.xy = {2,4}
  print(mon.xy) -- "table: <address>" table={2,4}
  mon.pos.xy = {6,8}
  print(mon.pos.xy) -- "table: <address>" table={6,8}
  print(mon.pos(7,9)) -- "7, 9" set x and/or y and return 2 numbers
  -- get/set palette colors
  -- Get palette color: return hex
  print(mon.palette.red) -- "<hex code>"
  -- Call palette color: return rgb array
  print(mon.palette('red')) -- "<r>, <g>, <b>"
  -- Set palette colors from hex or rgb
  mon.palette[colors.green] = {0,1,0}
  mon.palette['blue'] = 0x0000FF
  for k, v in pairs(mon.palette) do
	print(k, table.unpack(v)) -- k is colors.<color> numeric value, v is table={r,g,b,hex}
  end
  Support color indexes:
  colors.red (and other) - number
  'red' - color name
  'e' - blit color
  ```
  * `printer_util` - Printer. Can print entire **Book**s (16 pages). CC:Tweaked hardcoded page size: 25x21=525. Book size: 25x21x16=8400. It can divide large books (more than 16 pages) into books of normal size.
  ```lua
  printer = printer_util:Printer()
  book = printer_util:Book([text ot nil])
  book.add("A dummy big text, maybe a Shrek script. Really big, more than 8400 chars. Actually 50 pages long")
  book.page[1].tilte = "Shrek. Swamp drama"
  book.autoTitle() -- Add <pageNum> to title on every page. Now first page called "1. Shrek. Swamp drama"
  book.generateSequel() -- Split book to 16 pages + others books with 16 pages maximum
  book.sequel -- Sequels are sometimes very good. Shrek 2, for example
  book.sequel.sequel -- Oh no, Shrek 3
  book.sequel.sequel.sequel -- Shrek 4 *>kill*
  book.sequel.sequel.sequel.sequel - nil, because 50 = 3 * 16 + 2 pages
  -- Add hoppers to load paper and ink and unload printed pages.
  -- Print book with sequels, delay between printing 5 seconds
  printer.printBook(book, true, 5)
  -- Enjoy reading
  ```
  * `speaker_util` - Speaker. There are instructions on how to get all the sounds from the game to play them through speaker.playSound(). [WIP] Audioplayer.
  ```lua
  speaker = speaker_util:Speaker()
  speaker.sound('music_disc.cat')
  
  -- After preparing to receive all the sounds in the game
  soundlist = speaker_util:SoundList()
  for _, v in pairs(soundlist.filter('music_disc.')) do
	print(v)
	-- music_disc.11
	-- ...
	-- music_disc.ward
  end
  ```
  
  #### Advanced peripherals
  * `ar_util` - Augmented Reality Controller. Peripheral is disabled by mod authors.
  * `chat_util` - ChatBox. There is a sheet for colors and chat effects like **§c** (red), **§l** (bold).
  ```lua
  chatbox = chatbox_util:ChatBox()
  local text = chatbox_util.colorText("Hello World!", 'aqua', chatbox_util.CHATCOLORS.OBFUSCATED, true) -- "§b§kHello World!§r"
  chatbox.msg(text) -- Print a message to all players
  chatbox.msg(text, "Steve") -- Print a message only to Steve
  ```
  * `colony_util` - Colony Integrator. For ***MineColonies*** mod.
  * `energy_util` - Energy Detector.
  * `environment_util` - Environment Detector.
  * `geo_util` - Geo Scanner. 
  * `inventory_util` - Inventory Manager.
  * `me_util` - ME Bridge. For ***Applied Energistic 2*** mod. Methods that require ***item*** as an argument have alternatives for **name**+**nbt** and *fingerprint*.It is possible to easily customize the autocraft of items with complex checks for the availability of resources by creating **Task**s.
  ```lua
  me = me_util:MEBridge()
  me.craftItem2('minecraft:furnace',4,_,_) -- Craft 4 Furnaces, ignore NBT and CPU name
  
  -- Create task: item to craft, required amount, NBT, fingerprint, batch size, is fluid?, triggers, useORlogic?
  task = me_util:CraftTask('minecraft:stone', 1000, _, _, 64, _, _, _)
  -- If triggers is nil then creating new one: me.getItem(item) < amount
  -- Adding another trigger:
  task.triggers.add('minecraft:cobblestone', _, 1000, _, me_util.OP.GT) -- minecraft:cobblestone > 1000
  me.addTask(task) -- Register task to MEBridge
  -- Creating callback function
  function craftCallback(data)
	print(string.format(
	"Crafting ('%s','%s','%s'). Amount: %i. Result: %s", 
	data.item,data.nbt,data.fingerprint,data.amount,data.result
	))
  end
  me.craftTasks(craftCallback) -- Calling callback function on every crafting
  -- By default, Triggers work according to logic AND cannot be switched to logic OR
  ```
  * `nbt_util` - NBT Storage.
  * `player_util` - Player Detector.
  * `reader_util` - Block Reader.
  * `redstone_util` - Redstone Integrator. get/set(Analog)[Input/Output] wrapped as **input** and **output** tables.
  ```lua
  integrator = redstone_util:RedstoneIntegrator()
  print(integrator.input.west) -- return true/false
  print(integrator.input('west')) -- return 0-15
  integrator.output[this_library.SIDES.WEST] = 7 -- Set analog output
  integrator.output['up'] = true -- Set output
  for k,v in pairs(integrator.input) do
	print(k,v)
	-- k is relative directions: right, left, front, back, top, bottom
	-- v is 0-15
  end
  for k,v in ipairs(integrator.input) do
	print(k,v)
	-- k is cardinal directions: north, south, east, west, up, down
	-- v is 0-15
  end
  ```
  * `rs_util` - RS Bridge. For ***Refined Storage*** mod. Same as `me_util`.
  
  #### Create and addons
  * `create_util` - Create peripherals.
  * `create_cna_util` - Create: Crafts & Additions peripherals.
  
  ### Scripts
  #### Create and addons
  * `stress_controller` - Script to protect the mechanical system from overload (adjusts the **rotation speed** depending on the **stress**)
  * `CreateCAM` - CNC-like drill/builder with extendable spindel and rails(with schematic). Old version, without wrappers. ***DO NOT USE WITH Create Interactive !!!!!!!!!!***
  * `tower_farm` - Vertical farm. Old version, without wrappers. ***DO NOT USE WITH Create Interactive !!!!!!!!!!***
