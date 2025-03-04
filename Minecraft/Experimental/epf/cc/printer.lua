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
	
	Important notes:
	1.	The printer does not separate lines longer than 25 characters, so everything after the 25th character is not printed.
	2.	The printer does not detect \n and \r as line ending characters, it sees them as spaces. Use epf.fixString(text[, remove_empty) for replace \r\n and \r to \n and remove empty strings.
	3.	Tab \t acts as a regular space.
	4.	Library, Book and Page (added by this library) divide text according to these features.
	5.	The Page size matches the printed page (up to 25*21=525 characters).
	6.	The Book is the same size as the book being bound (up to 525*16=8400 characters).
	7.	The library consists of an unlimited number of books.
	8.	Use Library(text[,titles[,name[,fixed), Book(text[,titles[,name[,fixed), Page(text[,title[,fixed) for create Library, Book and Page.
		text - string or array-like table with splitted text.
		titles - array-like table with page titles.
		name - string with name of Book or Library.
		title - string with title for Page.
		fixed - boolean. Text already fixed (\r\n, \r -> \n)
]]
local epf = require 'epf'
local expect = require "cc.expect"
local expect = expect.expect

local lib = {}

local Peripheral = {}
local Page = {} -- Single page
local Book = {} -- Book with pages
local Library = {} -- Array of books

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


local function _reverse_queue(queue)
	local r = {}
	for i=#queue, 1, -1 do
		if subtype(queue[i]) == 'Library' then
			for j=#queue[i], 1, -1 do
				local b = queue[i].books[j]
				for k=#b, 1, -1 do
					r[#r+1] = b.pages[k]
				end
			end
		elseif subtype(queue[i]) == 'Book' then
			for j=#queue[i], 1, -1 do
				r[#r+1] = queue.pages[j]
			end
		elseif subtype(queue[i]) == 'Page' then
			r[#r+1] = queue[i]
		else
			error("Unknown value type in queue #"..tostring(i))
		end
	end
	return r
end

local function _print_page(printer, page)
	printer.newPage()
	printer.setPageTitle(page.title)
	for i, l in pairs(page) do
		printer.pos(1,i)
		printer.write(l) -- Note: The printer does not break lines longer than 25 characters, and does not recognize \r and \n as line breaks, so Page does this for it.
	end
	printer.endPage()
	return 1
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
	
	self.__queue = {}
	self.addQueue = function(text, noCopy)
		if custype(text) == 'utility' and (subtype(text) == 'Library' or
			subtype(text) == 'Library' or subtype(text) == 'Library') then
				self.__queue[#self.__queue+1] = noCopy and text or table.copy(text)
		else
			self.__queue[#self.__queue+1] = Library.newEx(tostring(text))
		end
	end
	self.remQueue = function(index) return table.remove(self.__queue,index) end
	self.clearQueue = function() while #self.__queue > 0 do table.remove(self.__queue) end end
	self.printQueue = function(delay, preserveError)
		-- Note: After trying to print the queue, books and libraries are split into pages
		delay = math.max(1,tonumber(delay) or 1)
		-- We split it into pages and reverse it to avoid index shifting when deleting pages (now we delete the last page, not the first one)
		local q, printed = _reverse_queue(self.__queue), 0
		while #q > 0 and self.getInkLevel()*self.getPaperLevel() > 0 do
			local res, err = pcall(_print_page, self, q[#q])
			if res then
				printed = printed + 1
				table.remove(q)
				sleep(delay)
			else
				-- Reverse back
				self.__queue = _reverse_queue(q)
				if not preserveError then error(err) end
				break
			end
		end
		if #q == 0 then
			self.__queue = {}
		elseif self.getInkLevel()*self.getPaperLevel() == 0 then
			if not preserveError then error("Not enough ink or paper") end
		end
		
		return printed
	end
	self.printLibrary = function(libr, noCheck)
		expect(1,libr, "Library")
		if not noCheck then
			local pages = 0
			for _,book in pairs(libr) do pages = pages + #book end
			if (self.getInkLevel() < pages or self.getPaperLevel() < pages) then
				error("Not enough ink or paper for printing library")
			end
		end
		local printed = 0
		for _,book in pairs(libr) do
			printed = printed + self.printBook(book, noCheck)
		end
		return printed
	end
	self.printBook = function(book, noCheck)
		expect(1,book, "Book")
		if not noCheck and (self.getInkLevel() < #book or self.getPaperLevel() < #book)
			then error("Not enough ink or paper for printing book")
		end
		local printed = 0
		for _,page in pairs(book) do
			self.printPage(page, noCheck)
		end
		return #book
	end
	self.printPage = function(page, noCheck)
		expect(1,page, "Page")
		if not noCheck and self.getInkLevel()*self.getPaperLevel() == 0 then
			error("Not enough ink or paper for printing page")
		end
		return _print_page(self, page)
	end
	return self
end
Peripheral = epf.wrapperFixer(Peripheral, "printer", "Printer")

Page.LINE_MAX_LENGTH = 25
Page.LINES_PER_PAGE = 21 -- Page max 525 characters
Book.MAX_PAGES = 16 -- Book max 8400 characters

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
	__subtype = "Page",
	__name = "utility",
	__len = function(self) return #self.lines end,
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
		local l, t
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
	local l = #text % Page.LINES_PER_PAGE
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
	__subtype = "Book",
	__name = "utility",
	__len = function(self) return #self.pages end,
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
		self.pages[#self.pages+1], text = Page.new(text, table.remove(titles,1), true)
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
	local l = #text % (Page.LINES_PER_PAGE * Book.MAX_PAGES) -- 16*21
	
	if #text > 0 then
		if l == 0 then l = Page.LINES_PER_PAGE * Book.MAX_PAGES end
		l = math.ceil(l/Page.LINES_PER_PAGE)
		for i=l, 1, -1 do
			self.pages[i], text = Page.newEx(text, table.remove(titles))
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
	__subtype = "Library",
	__name = "utility",
	__len = function(self) return #self.books end,
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
		local n = string.format("%s #%i", name or "Unnamed book", #self.books+1)
		self.books[#self.books+1], text = Book.new(text, titles, n, true)
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
function Library.newEx(text, titles, name, fixed)
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
		self.books[b], text = Book.newEx(text, titles, n, true)
		b = b - 1
	end
	
	setmetatable(self, libraryMeta)
	return self
end
function Library.fromFile(path)
	if fs.exists(path) and not fs.isDir(path) then
		local f = io.open(path, 'r')
		local t = f:read('*a')
		local l = Library(t)
		f:close()
		return l
	end
end

local pblMeta = {
__call = function(self, ...) return self.newEx(...)end,
}

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
		"(text, [titles[, name]]) - Library with books\n",
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
	__name="library",
	__subtype="Printer",
	__tostring=function(self)
		return "EPF-library for Printer (CC:Tweaked)"
	end,
})

return lib
