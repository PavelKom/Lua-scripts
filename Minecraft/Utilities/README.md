# Utilities and patches
Tips and examples

## Patches
Some patches for Lua core.
**type(object)** can now return a custom value if the *__type* parameter is specified in the metatable.

**Note**: import *cc.expect* only after *getset_util*, *patches* or any wrapped peripheral library!!!
### Table
**ipairs(tbl)** is removed from CC:Tweaked (or broken), but what if you want it? Now you can add your own *__ipairs* for custom classes.

**table.copy(tbl)** - Deep-copy with recursive protection.

**table.equal(tbl1, tbl2, ignore_mt)** - Table equality function. You can add *__eq* to metatables for custom equal test.
### String
**string.split(str[, separator])** - Split function for strings. if *separator* is *nil*, split by *space* or *\t\r\n*.
### Math
**math.clamp(value[, minimum[, maximum]])** - Clamp number between *minimum* or 0, and *maximum* or 1
### Colors/Colours
Add *blit* keys as normal colors (*colors['e'] = colors.red*).

The **colors** library uses values for RGB channels 0.0-1.0. But what if you need to work with 0-255 without fiddling with hex values?
Converting from *hex* and 0.0-1.0 to 0-255 and back
| Description | From 0-255                   | To 0-255                     |
|-------------|------------------------------|------------------------------|
| Chanell     | **colors.norm(value)**       | **colors.abs(value)**        |
| RGB         | **colors.normRGB(r,g,b)**    | **colors.absRGB(r,g,b)**     |
| Hex         | **colors.packAbsRGB(r,g,b)** | **colors.unpackAbsRGB(hex)** |

## Events
**lib.waitEventLoopEx(eventname,func)** - Create seme-infinite loop for catching events. *eventname* - Name of event. *func* - Callback function. Must be *func(tbl)* and return *true* for continue catching events.

**lib.waitEventRawLoopEx(eventname,func)** - Same for *raw* events.

Don't forget to use *parallel.waitForAny* so that waiting for an event doesn't take up all the computer's time.
```lua
events = require 'event_util'

funclion callback(tbl)
	for k, v in pairs(tbl) do
		print(k,v)
	end
end
function event_loop()
  events.waitEventLoopEx('key', callback)
end
function main_job()
	for i=1000, 0, -1 do
		print(string.format("%i second(s) left", i)
		sleep(1)
	end
end
parallel.waitForAny(event_loop, main_job)
```
## Getset library
### Getter and setter
Some programming languages have a simple way to create class properties. This is useful when changing a property requires additional computation, or when the property is read-only. Python for example:
```python
import math
class Circle():
  def __init__(self, r=1.0):
    self.__default = r
    self._radius = r
  def reset(self):
    self._radius = self.__default
  @property
  def radius(self):
    return self._radius
  @radius.setter
  def _(self, value:float):
    if value <= 0.0:
      raise ValueError("Radius must be greater than 0")
    self._radius = value
  @property
  def diameter(self):
    return self._radius * 2.0
  @diameter.setter
  def _(self, value:float):
    if value <= 0.0:
      raise ValueError("Diameter must be greater than 0")
    self._radius = value / 2.0
  @property
  def circumference(self):
    return self._radius * 2.0 * math.pi
  @circumference.setter
  def _(self, value:float):
    if value <= 0.0:
      raise ValueError("Circumference must be greater than 0")
    self._radius = value / (2.0 * math.pi)
  @property
  @property
  def square(self):
    return math.pow(self._radius, 2.0) * math.pi
  @square.setter
  def _(self, value:float):
    if value <= 0.0:
      raise ValueError("Square must be greater than 0")
    self._radius = math.sqrt(value / math.pi)
  r = radius
  d = diameter
  c = circumference
  s = square
```
**Note**: In Python, adding *_* (single underscore) to the beginning of a property or method name makes it private (but visible from the outside), while *__* (double underscore) makes it hidden.

As you can see, **_radius** is a private property, so the *radius* is used to get/set the value, and the value is checked.

The *@property* decorator turns a function into a regular property that can be accessed as *var = obj.prop*, not  *var = obj.prop()*.

The *@\<property name\>.setter* decorator turns a function into a setter of the property value, i.e. *obj.prop = 5*, not *obj.prop(5)*.

Lua has a similar method through metatables. If you try to request a property that the table does not have, then the *__index* method will be called, and if you set it, then *__newindex*. This is what *getset.GETTER* and *getset.SETTER* are based on.
```lua
getset = require "getset_util"
Circle = {}
Circle.new = function(radius)
	local self = {_radius = tonumber(radius) or 1}
	self.__default = self._radius
	self.__getter = { -- Getter table
		radius = function() return self._radius end,
		diameter = function() return self._radius * 2 end,
		circumference = function() return self._radius * 2 * math.pi end,
		square = function() return math.pow(self._radius,2) * math.pi end,
	}
	self.__getter.r = self.__getter.radius
	self.__getter.d = self.__getter.diameter
	self.__getter.c = self.__getter.circumference
	self.__getter.s = self.__getter.square
	self.__setter = { -- Setter table
		radius = function(value)
			if value <= 0 then error("Radius must be greater than 0") end
			self._radius = value
		end,
		diameter = function(value)
			if value <= 0 then error("Diameter must be greater than 0") end
			self._radius = value / 2
		end,
		circumference = function(value)
			if value <= 0 then error("Circumference must be greater than 0") end
			self._radius = value / (2 * math.pi)
		end,
		square = function(value)
			if value <= 0 then error("Square must be greater than 0") end
			self._radius = math.sqrt(value / math.pi) 
		end,
	}
	self.__setter.r = self.__setter.radius
	self.__setter.d = self.__setter.diameter
	self.__setter.c = self.__setter.circumference
	self.__setter.s = self.__setter.square
	self.reset = function() self._radius = self.__default end
	setmetatable(self, {
		__index = getset.GETTER,
		__newindex = getset.SETTER,
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS, -- See below
		__tostring = function(self) -- Set formatted print for class
			return string.format("Circle. R(%.2f), D(%.2f), C(%.2f), S(%.2f)", self.r, self.d, self.c, self.s)
		end
	})
	return self
end
Circle = setmetatable(Circle, {__call=Circle.new}) -- Allow call Circle() like Circle.new()

circle = Circle() -- Circle of unit radius
print(circle) -- "Circle. R(1.00), D(2.00), C(6.28), S(3.14)"
circle.r = 5 -- Set value
print(circle.d) -- Get value
-- circle.d = 7 is equal with circle.__setter.d(7)
```
### Pairs and ipairs
Besides this there is *getset.PAIRS* and *getset.IPAIRS*.
```lua
for k, v in pairs(circle) do
	print(k, "\n  ", table.unpack(v))
end
--[[ Output:
method
  _radius reset
getter
  radius diameter circumference square r d c s
setter
  radius diameter circumference square r d c s
]]
for k, v in ipairs(circle) do
	print(k, v)
end
-- [[ Output
  radius function: <address>
  diameter function: <address>
  circumference function: <address>
  square function: <address>
  r function: <address>
  d function: <address>
  c function: <address>
  s function: <address>
  reset function: <address>
  _radius 1
]]
```
As you can see, PAIRS splits into getters, setters and methods, but hides elements with *__* (double underscore) at the beginning of the name, which allows you to hide meta-functions and hidden parameters, as in Python. At the same time, IPARS does not split into groups, but also does not duplicate the names of methods/props.
### Equality
**getset.EQ_PERIPHERAL** allows you to add a condition for peripheral devices to match.
```lua
mon1 = Monitor()
mon2 = Monitor('monitor_3')
print(mon1 == mon2) -- If names and types of peripherals is equal, return true
```
### QoL
**getset.printTable(tbl,ignore_functions)** - Printing a table in tree view
```lua
a = {1,2,3,{4,5,'c',{7,8,b=9}}}
getset.printTable(a)
--[[ Output:
1: 1 number
2: 2 number
3: 3 number
4:
 1: 4 number
 2: 5 number
 3: c string
 4:
  1: 7 number
  2: 8 number
  b: 9 number
]]
```
**getset.STRING_TO_BOOLEAN(value)** - Convert string to boolean. Allowed strings: *true*,*false*,*yes*,*y*,*no*,*n*. Case insensitive.
```lua
print(getset.STRING_TO_BOOLEAN('yEs')) -- true
print(getset.STRING_TO_BOOLEAN('NO')) -- false
print(getset.STRING_TO_BOOLEAN('aaa')) -- nil
print(getset.STRING_TO_BOOLEAN(1)) -- nil
```
**getset.GETTER_TO_UPPER(default)** - Forces the index to be *UPPER CASE* when using *__index*. *default* is default value if index not founded.

**getset.GETTER_TO_LOWER(default)** - Similar, but *lower case*.
Useful when creating case-insensitive getters.

**getset.SIDES(side)** or **getset.SIDES.\<SIDE\>** - Table with relative and cardinal directions, case-insensitive. Also allowed as **getset.\<SIDE_IN_UPPERCASE\>**.
### Meta-tables
**getset.metaSide(getter, setter, caller, pair)** -- Meta table for working with peripheral devices that support working with *sides*. *getter*, *setter*, *caller*, *pair* - function 
```lua
-- From Advanced Peripherals/redstone_util
function outputParser(tbl)
	return function(side, value)
		if getset.STRING_TO_BOOLEAN(value) ~= nil then
			tbl.setOutput(side, getset.STRING_TO_BOOLEAN(value))
		else
			tbl.setAnalogOutput(side, tonumber(value))
		end
	end
end
...
self.input = getset.metaSide(self, self.getInput, _, self.getAnalogInput, self.getAnalogInput)
self.output = getset.metaSide(self, self.getOutput, outputParser(self), self.getAnalogOutput, self.getAnalogOutput)
...
-- In program
RedstoneIntegrator = require "redstone_util"
ri = RedstoneIntegrator()
print(ri.input.LEFT) -- true/false
print(ri.input('LEFT')) -- 0-15
ri.output.LEFT = true -- .setOutput(bool)
ri.output.RIGHT = 7 -- .setAnalogOutput(number)
for k, v in pairs(ri.input) do -- Get analog inputs from relatives sides (left, right, ...)
	print(k,v)
end
for k, v in ipairs(ri.input) do -- Get analog inputs from cardinals sides (north, south, ...)
	print(k,v)
end
```
**getset.metaPos(getter, setter)** - Meta table for working with 2D coordinates, like terminal and monitor cursor. *getter*, *setter* - function.
```lua
Terminal = require "term_util"
t = Terminal()
-- t.x same as t.pos.x
print(t.x, t.y) -- Get cursor position
print(table.unpack(t.xy)) -- Same, but as table
t.x = 5 -- Move cursor to x=5
t.y = 7 -- Same for y
t.xy = {2,3} -- Set cursor to 2;3.
t.xy = {x=3,y=4} -- Named coordinates
t.xy = {5} -- Set x=5, but reset y to 1
t.xy = {y=2} -- Same, but now x=1
t.xy = {} - Reset to 1;1
t.pos() -- Same as t.pos.xy = {}
t.pos(5) -- x=5, ignore y
t.pos(_, 7) -- y=7, ignore x
t.pos({1}) -- Same as t.xy = {1}
```
**getset.metaPalette(getter, setter)** - Meta table for working with *palette*, like terminal and monitor. *getter*, *setter* - functions.
```lua
print(t.palette[colors.red]) -- Get HEX of red color
print(t.palette['red']) -- Same
print(t.palette['e']) -- Same (blit character)
t.palette.black = 0x000000 -- Set color by hex
t.palette.black = "0x000000" -- Hex is string
t.palette.black = {0,0,0} -- By RGB
t.palette.black = {r=0,g=0,b=0} -- Same
t.palette.black = {0,_,_} -- Change specific chanell(s)
t.palette('black', 0,0,0) -- Set color by RGB
t.palette('black', 0,_,0) -- Set specific chanell(s) of color
t.palette('black', "0x000000") -- By hex. ONLY STRING!!!
t.palette({e={r=1,0,0},lime={0,g=1,0},colors.blue={0,0,b=1}, black=0x000000) -- Change multiply colors
```
