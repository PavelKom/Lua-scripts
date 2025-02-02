--[[
	Printer peripheral wrapper
	Author: PavelKom
	Version: 0.2
	Extended Peripherals Framework version: 2.3
	https://tweaked.cc/peripheral/printer.html
	
	Note:
	Book size and page size hardcoded to mod.
	https://github.com/cc-tweaked/CC-Tweaked/blob/mc-1.19.2/src/main/java/dan200/computercraft/shared/media/items/ItemPrintout.java
	public static final int LINES_PER_PAGE = 21;
	public static final int LINE_MAX_LENGTH = 25;
	public static final int MAX_PAGES = 16;
]]
local epf = require 'epf'
local expect = require "cc.expect"
local expect = expect.expect

local lib = {}

local Peripheral = {}

-- Change this setting to true for static-calls pos and palette tables
lib.EXTERNAL_TABLES = false

-- CURSOR POSITION
function Peripheral.__pos_getter(self)
	return self.getCursorPos()
end
function Peripheral.__pos_setter(self, ...)
	self.setCursorPos(...)
end
Peripheral.__pos = epf.subtablePos(Peripheral,
	Peripheral.__pos_getter, Peripheral.__pos_setter, _, {'static'})
function Peripheral.pos(self)
	rawset(Peripheral.__pos,'__cur_obj',self) -- On getting .pos return static pos but set current object as target
	return Peripheral.__pos
end

function Peripheral.__init(self)
	if not lib.EXTERNAL_TABLES then
		self.pos = epf.subtablePos(self,
			self.getCursorPos, self.setCursorPos)
	end

	self.__getter = {
		size = function() return {self.getPageSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		ink = function() return self.getInkLevel() end,
		paper = function() return self.getPaperLevel() end,
		
		x = function() return self.pos.x end,
		y = function() return self.pos.y end,
		xy = function() return self.pos.xy end,
	}
	self.__setter = {
		title = function(value) return self.setPageTitle(value) end,
		
		x = function(value) self.pos.x = value end,
		y = function(value) self.pos.y = value end,
		xy = function(value) self.pos.xy = value end,
	}
	self.__getter.cols = self.__getter.columns
	self.__getter.row = self.__getter.y
	self.__getter.column = self.__getter.x
	self.__getter.col = self.__getter.x
	
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "printer", "Printer")
local Page = {} -- Single page
local Book = {} -- Book with pages
local Library = {} -- Array of books
Book.MAX_PAGES = 16
Page.LINES_PER_PAGE = 21
Page.LINE_MAX_LENGTH = 25

-- Metatable fo Pages
local pageMeta = {
	__pairs = function(self)
		local i=0
		return function()
			i=i+1
			if not self.lines[i] then return nil, nil end
			return i, self.lines[i]
		end
	end,
	__tostring = function(self)
		return table.concat(self.lines,'\n')
	end,
	__type = "Page",
}

--[[
	Create new book page.
	@tparam string|table text Page text as string or table with lines
	@tparam[opt=nil] string title Page title
	@tparam[opt=false] boolean String already fixed
	@treturn table Page
	@treturn string Unused text
]]
function Page.new(text, title, fixed)
	expect(1,text, "string", "table")
	expect(2,title, "string", "nil")
	expect(3,fixed, "boolean", "nil")
	local self = {title=tostring(title),lines = {}}
	if type(text) == 'string' then
		local l
		for i=1, Page.LINES_PER_PAGE do
			if #text == 0 then break end
			l, t = epf.iterLineEx(t, Page.LINE_MAX_LENGTH, fixed)
			self.lines[#self.lines+1] = l
		end
	else
		for i=1, Page.LINES_PER_PAGE do
			if #text == 0 then break end
			self.lines[#self.lines+1] = table.remove(text, 1)
		end
	end
	
	self.isEmpty = function() return #self.lines == 0 end
	self.info = function() return string.format("Page(%s):%s",self.title,table.concat(self.lines,'\n')) end
	
	setmetatable(self, pageMeta)
	return self, text
end

--[[
	Create new book page. The end of the text is used, not the beginning.
	@tparam table text Table with lines
	@tparam[opt=nil] string title Page title
	@treturn table Page
	@treturn string Unused text
]]
function Page.newEx(text, title)
	expect(1,text, "string", "table")
	expect(2,title, "string", "nil")
	local self = {title=tostring(title),lines = {}}
	local l = text % Page.LINES_PER_PAGE
	if #text > 0 then
		if l == 0 then l = Page.LINES_PER_PAGE end
		for i=l, 1, -1 do
			self.lines[i] = table.remove(text) -- Get from last postition
		end
	end
	self.info = function() return string.format("Page(%s):%s",self.title,table.concat(self.lines,'\n')) end
	setmetatable(self, pageMeta)
	return self, text
end

local bookMeta = {
	__pairs = function(self)
		local i=0
		return function()
			i=i+1
			if not self.pages[i] then return nil, nil end
			return i, self.pages[i]
		end
	end,
	__tostring = function(self)
		return self.name.." Pages: "..tostring(#self.pages)
	end,
	__type = "Book",
}

--[[
	Create new book
	
	@tparam string|table text Book text as string or table with lines
	@tparam[opt=nil] table titles Page titles
	@tparam[opt=nil] string name Book name
	@treturn table Book
	@treturn string Unused text
	@treturn table Unused titles
]]
function Book.new(text, titles, name, fixed)
	expect(1,text, "string", "table")
	expect(2,titles, "table", "nil")
	expect(2,fixed, "boolean", "nil")
	
	-- Convert text from srting to table
	if type(text) == 'string' then
		text = epf.splitText(text, Page.LINE_MAX_LENGTH, fixed)
	end
	titles = titles or {}
	
	local self = {pages={}, name=name or "Unnamed book"}
	
	for i=1, Book.MAX_PAGES do
		if #text == 0 then break end
		pages[#pages+1], text = Page.new(text, table.remove(titles,1), true)
	end
	
	self.isEmpty = function() return #self.pages == 0 end
	self.info = function() return string.format("Book:%s",self.title,table.concat(self.pages,'\n')) end
	
	setmetatable(self, bookMeta)
	return self, text, titles
end
--[[
	Create new book. The end of the text is used, not the beginning.
	
	@tparam string|table text Page text as string or table with lines
	@tparam[opt=nil] table titles Page titles
	@treturn table Book
	@treturn string Unused text
]]
function Book.newEx(text, titles, name, fixed)
	expect(1,text, "string", "table")
	expect(2,titles, "table", "nil")
	expect(2,fixed, "boolean", "nil")
	
	-- Convert text from srting to table
	if type(text) == 'string' then
		text = epf.splitText(text, Page.LINE_MAX_LENGTH, fixed)
	end
	titles = titles or {}
	
	local self = {pages={}, name=name or "Unnamed book"}
	local l = text % (Book.LINES_PER_PAGE * Book.MAX_PAGES) -- 16*21
	
	if #text > 0 then
		if l == 0 then l = Page.LINES_PER_PAGE * Book.MAX_PAGES end
		l = math.ceil(l/Page.LINES_PER_PAGE)
		for i=l, 1, -1 do
			pages[i], text = Book.newPageEx(text, table.remove(titles), true)
		end
	end
	
	for i=1, Book.MAX_PAGES do
		if #text == 0 then break end
		
	end
	
	self.isEmpty = function() return #self.pages == 0 end
	self.info = function() return string.format("Book:%s",self.title,table.concat(self.pages,'\n')) end
	
	setmetatable(self, bookMeta)
	return self, text
end

local libraryMeta = {
	__pairs = function(self)
		local i=0
		return function()
			i=i+1
			if not self.books[i] then return nil, nil end
			return i, self.books[i]
		end
	end,
	__tostring = function(self)
		return self.name.." Books: "..tostring(#self.books)
	end,
	__type = "Library",
}

--[[
	Array with books
	
	@tparam string|table text Books text as string or table with lines
	@tparam[opt=nil] table titles Page titles
	@tparam[opt=nil] string name Library name
	@treturn table Array of books
]]
function Library.new(text, titles, name, fixed)
	expect(1,text, "string", "table")
	expect(2,titles, "table", "nil")
	expect(2,fixed, "boolean", "nil")
	
	-- Convert text from srting to table
	if type(text) == 'string' then
		text = epf.splitText(text, Page.LINE_MAX_LENGTH, fixed)
	end
	titles = titles or {}

	local self = {books={}, name=name or "Unnamed library"}
	
	while #text > 0 do
		local n = string.format("%s #%i", name or "Unnamed book", #books+1)
		books[#books+1] = Book.new(text, titles, n, true)
	end
	
	setmetatable(self, libraryMeta)
	return self
end

--[[
	Array with books. Read text from end.
	
	@tparam string|table text Books text as string or table with lines
	@tparam[opt=nil] table titles Page titles
	@tparam[opt=nil] string name Library name
	@treturn table Array of books
]]
function Library.new(text, titles, name, fixed)
	expect(1,text, "string", "table")
	expect(2,titles, "table", "nil")
	expect(2,fixed, "boolean", "nil")
	
	-- Convert text from srting to table
	if type(text) == 'string' then
		text = epf.splitText(text, Page.LINE_MAX_LENGTH, fixed)
	end
	titles = titles or {}

	local self = {books={}, name=name or "Unnamed library"}
	
	local b = math.ceil( #text / (Book.MAX_PAGES * Page.LINE_MAX_LENGTH) )
	
	while #text > 0 do
		local n = string.format("%s #%i", name or "Unnamed book", b)
		books[b] = Book.new(text, titles, n, true)
		b = b - 1
	end
	
	setmetatable(self, libraryMeta)
	return self
end

local pblMeta = {
__call = function(self, alt, ...)
	if alt then return self.newEx(...)
	else self.new(...)
	end
end}

lib.Page = setmetatable(Page, pblMeta)
lib.Book = setmetatable(Book, pblMeta)
lib.Library = setmetatable(Library, pblMeta)

lib.Printer = Peripheral

function lib.help()
	local text = {
		"Printer library. Contains:\n",
		"Printer",
		"([name]) - Peripheral wrapper\n",
		"Page",
		"(text, [label]) - Single page for printing\n",
		"Book",
		"(text, [titles[, name]]) - Book with pages\n",
		"Library",
		"(text, [titles[, name]]) - Library with books",
	}
	local c = {
		colors.red,
		colors.blue,
		colors.green,
		colors.magenta,
	}
	if term.isColor() then
		local bg = term.getBackgroundColor()
		local fg = term.getTextColor()
		term.setBackgroundColor(colors.black)
		for i=1, #text do
			term.setTextColor(i % 2 == 1 and colors.white or c[i/2])
			term.write(text[i])
			if i % 2 == 1 then
				local x,y = term.getCursorPos()
				term.setCursorPos(1,y+1)
			end
		end
		term.setBackgroundColor(bg)
		term.setTextColor(fg)
	else
		print(table.concat(text))
	end
end

local _m = getmetatable(Peripheral)
lib = setmetatable(lib, {
	__call=_m.__call,
	__type="library",
	__name="Printer",
	__subtype="peripheral wrapper library",
	__tostring=function(self)
		return "EPF-library for Printer (CC:Tweaked)"
	end,
})

return lib
