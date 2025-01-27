# CC:Tweaked
Tips and examples

Note: all peripherals are registered on the first request, so the expression
```lua
lib = require 'command_util'
c = lib:CommandBlock('computer_1')
c2 = lib:CommandBlock('computer_1')
```
will return the same table without creating duplicates.

You can also access some peripherals directly without initialization.
```lua
lib = require 'command_util'
lib.run('kill @a')
```
Or wrap directly from library (if library contain only 1 peripheral)
```lua
Monitor = require 'monitor_util'
mon = Monitor()
```
Don't access peripherals without initialization too often (slows things down) or if there is more than 1 peripheral of the same type (possible collision)

  ## Command Block
  ```lua
  lib = require 'command_util'
  cmd = lib:CommandBlock() -- Get any Command Block
  cmd = lib:CommandBlock('command_3') -- Get Command Block with specific name
  cmd.command = 'give @a minecraft:cobblestone 1' -- Set command
  print(cmd.command) -- Get current command
  cmd.run() -- execute command
  
  lib.run('give @a minecraft:cobblestone 1') -- run command without connecting to CommandBlock
  ```
  ## Computer
  ```lua
  lib = require 'computer_util'
  comp = lib:Computer()
  comp.on() - Turn on
  comp.off() - Turn off
  comp.reboot() - Reboot
  print(comp.label, comp.id) -- Get computer label, id
  comp.label = "Nuclear controller" -- Set computer label
  -- Note: Changing a computer's label is only allowed on the computer itself; attempting to change the label on a remote computer will cause an error
  ```
  ## Drive
  ```lua
  lib = require 'drive_util'
  drive = lib:Drive()
  if drive.present then -- Disk inserted
    print(drive.label, drive.id) -- Get disk label, id
    drive.label = "Moonlight Sonata" -- Set disk label
    print(drive.path) -- Get mount path
    print(drive.data, drive.empty) -- Disk with any data? | Disk is empty
    if drive.audio then
      print(drive.title) -- Get audio title
      drive.play() -- Start playing music
      sleep(5)
      drive.stop() -- Stop playing music
    end
    drive.eject() -- Eject disk
  end
  if lib.present then -- It is also possible to work with the drive without initialization
    print(lib.label)
  end
  ```
  ## Modem
  ```lua
  lib = require 'modem_util'
  modem = lib:Modem()
  if not modem.wireless then -- Is wired modem
    print(table.unpack(modem.namesRemote)) -- Get names of connected peripherals
    print(modem.nameLocal) -- Get local name
    if modem.isPresent('monitor') then
      methods = modem.methods('monitor') -- Get allowed methods
	  print(table.unpack(methods))
	  momem.call('monitor', 'write', 'Hello World!') -- Call method
    end
  end
  ```
  ## Monitor
  The monitor has a built-in **pos** table for getting/setting the cursor position. It is also possible to work directly with the cursor without accessing the **pos**.
  ```lua
  lib = require 'monitor_util'
  mon = lib:Monitor()
  -- Get cursor position
  print(mon.pos.x, mon.pos.y)
  print(mon.x, mon.y)
  print(mon.col, mon.row) -- Same
  print(table.unpack(mon.pos.xy)) -- {[1]=x, [2]=y}
  print(table.unpack(mon.xy))
  -- Set cursor position
  mon.pos.x = 2 -- Move cursor to column #2
  mon.y = 3 -- Row #3
  mon.xy = {1,2} -- Set position to (1,2)
  mon.xy = {x=1,y=2} -- Same
  mon.pos() - Reset position to (1,1)
  mon.pos(5,5) -- Set position to (5,5)
  mon.pos(7) -- Equal mon.pos.x = 7
  mon.pos(_, 6) -- Equal mon.pos.y = 6
  mon.pos({2,2}) -- Equal mon.pos.xy = {2,2}
  mon.pos({x=3,y=4}) -- Equal mon.pos.xy = {x=3,y=4}
  print(mon.size) - Get size of monitor
  print(mon.rows, mon.cols) - Same
  ```
  It is also possible to work with a color **palette**. Hex can be **number** or **string** in *get/set*, but only **string** in *call*
  ```lua
  print(mon.palette.red) -- Get hex value of red color
  print(mon.palette[colors.red])
  print(mon.palette['e']) -- Index is blit
  
  mon.palette.red = {1,0,0} -- Set color from rgb. Values from 0.0 to 1.0
  mon.palette.red = {_,0.1,_} -- Change specific channel
  mon.palette.red = 0xff0000 -- Also allow hex values
  mon.palette('red', 1,_,_) -- Set single color
  mon.palette('red', '0xff0000') -- As hex. ONLY STRING
  mon.palette('red', 0xff0000) -- Wrong. CC:Tweaked not supported Lua5.3 int subtype, we can't check number is int or float
  mon.palette({['red']={1,0,0}, ['blue']=0x0000ff, ['green'] = '0x00ff00'}) -- Set multiply colors, allow {rgb-table} and hex-values (numbers and strings)
  for k,v in pairs(mon.palette) do -- Iterate colors
    print(k, table.unpack(v)) -- k is color number (2^i), v = {r,g,b,hex}
  end
  ```
  Working with text
  ```lua
  mon.clear()
  mon.scale = 2 -- Set scale
  mon.blink = false -- Disable cursor blink
  mon.bg = color.black -- Set backgroud color
  mon.fg = color.green -- Set text color
  mon.pos()
  mon.write("Hello")
  mon.nextLine(5) -- Move to next line, but set x=5. Skip argument for x=1
  mon.print("World!", 7) -- Same as write+nextLine
  mon.prevLine() -- Same as nextLine, but in reverse
  if not mon.update() then -- Update monitor after add/remove blocks. Return false if monitor destroyed
    print("We've failed you, Xzibit!")
  end
  mon.blit("text", "0123", "4567") -- Write blit text (text, fg, bg)
  ```
  ## Printer
  The printer can also work with a **pos** table.
  ```lua
  lib = require 'printer_util'
  printer = lib:Printer()
  print(table.unpack(printer.xy))
  ```
  Work with text
  ```lua
  printer.load() -- Load paper and ink into printer
  printer.write("I am a text") -- Write text to current position (in buffer)
  printer.print() -- Print current page
  
  onNewPage = true -- Start printing from new page
  closePage = true -- Close last page
  printer.write("I am a text too", onNewPage, closePage) -- Write text multi-page text
  printer.printPages("I am a number", {"Uno", "Dos"}, 5) -- Print multi-page text with {labels}. Delay between pages: 5 sec
  printer.erase("a") -- Replace all information on page with space or specific character
  ```
  Each line can contain up to 25 characters, each page can contain up to 21 lines (525 chars), and each bound book up to 16 pages (8400 chars). If you need to write a large text, it is better to use **Book**s
  ### Books
  ***I love books*** Globglogabgalab
  ```lua
  text = "A dummy big text, maybe a Shrek script. Really big, more than 8400 chars. Actually 50 pages long"
  book = lib:Book(text, label)
  book.add("Credits") -- Add to end 
  book.add("In a far-far galaxy...", 1) -- Add to start (or any specific page)
  book.page[1].tilte = "Shrek. Swamp drama"
  book.autoTitle() -- Add <pageNum> to title on every page. Now first page called "1. Shrek. Swamp drama"
  book.generateSequel() -- Split book to 16 pages + others books with 16 pages maximum
  book.sequel -- Sequels are sometimes very good. Shrek 2, for example
  book.sequel.sequel -- Oh no, Shrek 3
  book.sequel.sequel.sequel -- Shrek 4 *>kill*
  book.sequel.sequel.sequel.sequel -- nil, because 50 = 3 * 16 + 2 pages
  -- Add hoppers to load paper and ink and unload printed pages.
  -- Print book with sequels, delay between printing 5 seconds
  printer.printBook(book, true, 5)
  ```
  ## Speaker
  ***WIP***
  ## Terminal
  Same as monitor, but without update()












