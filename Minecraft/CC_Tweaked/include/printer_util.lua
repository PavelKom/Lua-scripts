--[[
	Printer Utility library by PavelKom.
	Version: 0.9.5
	Wrapped Printer
	https://tweaked.cc/peripheral/monitor.html
	TODO: Add manual
]]
getset = require 'getset_util'
ccs = require "cc.strings"
local lib = {}

local Peripheral = {}
Peripheral.__items = {}
function Peripheral:new(name)
	local self, wrapped = getset.VALIDATE_PERIPHERAL(name, 'printer', 'Printer', Peripheral)
	if wrapped ~= nil then return wrapped end
	self.__getter = {
		size = function() return {self.object.getPageSize()} end,
		rows = function() return self.size[2] end,
		columns = function() return self.size[1] end,
		ink = function() return self.object.getInkLevel() end,
		paper = function() return self.object.getPaperLevel() end,
	}
	self.__setter = {
		title = function(value) return self.object.setPageTitle(value) end,
	}
	self.__getter.cols = self.__getter.columns
	self.pos = getset.metaPos(self, 'getCursorPos', 'setCursorPos')
	self.write = function (text) return self.object.write(text) end
	self.write2 = function(text, onNewPage, closePage)
		local res, err, err2 = pcall(self.object.getPageSize)
		if not res or onNewPage then
			if self.paper == 0 then
				error("[Printer] Not enough paper")
			end
			self.new()
			res, err, err2 = pcall(self.object.getPageSize)
			if not res then error(err) end
		end
		local _lines = ccs.wrap(text, err)
		local _rows = err2
		if #_lines / _rows > self.paper then
			error("[Printer] Not enough paper")
		end
		
		while #_lines > 0 do
			if _rows == 0 then
				self.close()
				self.new()
				_rows = self.rows
			end
			local res, err = pcall(self.write, _lines[1])
			table.remove(_lines,1)
			_rows = _rows - 1
		end
		if closePage then
			self.close()
		end
	end

	self.load = function() return self.object.newPage() end
	self.print = function() return self.object.endPage() end
	
	self.printPages = function(text, titles, delay)
		delay = delay or 1
		repeat
			if self.paper == 0 then
				error("[Printer] Not enough paper")
			elseif self.ink == 0 then
				error("[Printer] Not enough ink")
			end
			self.load()
			if titles and type(titles) == 'table' and #titles > 0 then
				self.title = tostring(titles[1])
				table.remove(titles,1)
			end
			local _cols, _rows = self.object.getPageSize()
			local _lines = ccs.wrap(text, _cols)
			for i = 1, _rows do
				if #_lines == 0 then break end
				self.pos.x = 1
				self.pos.y = i
				self.write(_lines[1])
				table.remove(_lines,1)
			end
			self.print()
			text = table.concat(_lines)
			sleep(delay)
		until #text <= 0
	end
	self.printPages2 = function(text, titles, delay)
		-- https://github.com/cc-tweaked/CC-Tweaked/blob/mc-1.19.2/src/main/java/dan200/computercraft/shared/media/items/ItemPrintout.java
		-- public static final int LINES_PER_PAGE = 21;
		-- public static final int LINE_MAX_LENGTH = 25;
		-- public static final int MAX_PAGES = 16;
		delay = delay or 1
		local _lines = ccs.wrap(text, 25)
		local req = math.floor(#_lines/21)
		--if req > 16 then
		--	error("[Printer] Too many pages for a book, maximum 16 pages (25x21=525 characters per page, 525x16=8400 characters per book)")
		if self.paper < req then
			error(string.format("[Printer] Not enough paper. Required: %i Present: %i",req, self.paper))
		elseif self.ink < req then
			error(string.format("[Printer] Not enough ink. Required: %i Present: %i",req, self.ink))
		end
		while #_lines > 0 do
			self.load()
			self.title = titles[1]
			table.remove(titles,1)
			for i = 1, 21 do
				if #_lines == 0 then break end
				self.pos.x = 1
				self.pos.y = i
				self.write(_lines[1])
				table.remove(_lines,1)
			end
			self.print()
			sleep(delay)
		end
	end
	
	self.printBook = function(book, withSequel, delay)
		local _pages = book.pages
		if withSequel  then _pages = book.pagesWithSequel end
		if _pages > self.paper then
			error(string.format("[Printer] Not enough paper. Required: %i Present: %i",_pages, self.paper))
		elseif withSequel and _pages > self.ink then
			error(string.format("[Printer] Not enough ink. Required: %i Present: %i",_pages, self.ink))
		end
		while book do
			local _text, _titles = book.bookRaw()
			self.printPages2(_text, _titles, delay)
			if withSequel then
				book = book.sequel
			else
				break
			end
		end
	end
	
	self.erase = function(pages, delay)
		pages = pages or 1
		delay = delay or 1
		for i = 1, pages do
			self.load()
			local _cols, _rows = self.object.getPageSize()
			for i = 1, _rows do
				self.pos.x = 1
				self.pos.y = i
				self.write(ccs.ensure_width(" ", _cols))
			end
			self.title = ""
			self.print()
			sleep(delay)
		end
	end

	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("%s '%s'", type(self), self.name)
		end,
		__eq = getset.EQ_PERIPHERAL,
		__type = "Printer"
	})
	Peripheral.__items[self.name] = self
	if not Peripheral.default then Peripheral.default = self end
	return self
end
Peripheral.delete = function(name)
	if name then Peripheral.__items[_name] = nil end
end
lib.Printer=setmetatable(Peripheral,{__call=Peripheral.new})
lib=setmetatable(lib,{__call=Peripheral.new})

function testDefaultPeripheral()
	if not Peripheral.default then
		Peripheral()
	end
end

function lib:Book(text, name)
	if text and type(text) ~= 'string' then error("[Book] Invalid input type data") end
	local self = {name=name or '', page={}}
	if text then
		local _lines = ccs.wrap(text, 25)
		while #_lines > 0 do
			self.page[#self.page+1] = {line={}, title=''}
			for i = 1, 21 do
				if #_lines == 0 then break end
				self.page[#self.page].line[i] = _lines[1]
				table.remove(_lines,1)
			end
		end
	end
	self.__getter = {
		pages = function() return #self.page end,
		pagesWithSequel = function()
			local _result = self.pages
			if self.sequel then _result = _result + self.sequel.pagesWithSequel end
			return _result
		end,
	}
	self.setter = {}
	self.setLabel = function(pageNum, title) self.page[pageNum].title = tostring(title) end
	self.add = function(text, pageNumInsert)
		local _lines = ccs.wrap(text, 25)
		local offset = 0
		while #_lines > 0 do
			local _page = {line={}, title=''}
			for i = 1, 21 do
				if #_lines == 0 then break end
				_page.line[i] = _lines[1]
				table.remove(_lines,1)
			end
			if not pageNumInsert then
				self.page[#self.page+1] = _page
			else
				table.insert(self.page, pageNumInsert + offset, _page)
				offset = offset + 1
			end
		end
	end
	self.remove = function(pageNumStart, pageNumEnd)
		table.remove(self.page, pageNumStart)
		while pageNumEnd and pageNumEnd > pageNumStart do
			table.remove(self.page, pageNumStart)
			pageNumEnd = pageNumEnd - 1
		end
	end
	self.pageRaw = function(pageNum) return table.concat(self.page[pageNum].line), self.page[pageNum].title end
	self.bookRaw = function(startPage, endPage)
		startPage = startPage or 1
		endPage = endPage or self.pages
		local _text = ""
		local _titles = {}
		for i=startPage, endPage do
			local _page, _title = self.pageRaw(i)
			_text= _text.._page
			_titles[#_titles+1] = _title or ""
		end
		return _text, _titles
	end
	self.bookFormat = function(startPage, endPage)
		startPage = startPage or 1
		endPage = endPage or self.pages
		local _result = ""
		for i=startPage, endPage do
			local _page, _title = self.pageRaw(i)
			_result = string.format("%sPage %i '%s'\n%s\n", _result, i, _title, _page)
		end
		return _result
	end
	self.splitToSequel = function(cutOriginal)
		if self.pages <= 16 then return nil end
		local _book = lib:Book(self.bookRaw(17))
		if cutOriginal then self.remove(17, self.pages) end
		return _book
	end
	self.generateSequel = function()
		if self.sequel then return self.sequel end
		self.sequel = self.splitToSequel(true)
		if self.sequel then self.sequel.generateSequel() end
		return self.sequel
	end
	self.autoTitle = function()
		for i=1, self.pages do
			self.page[i].title = string.format("%i%s%s",i, #self.page[i].title > 0 and '. ' or '', self.page[i].title)
		end
	end
	
	setmetatable(self, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Book: '%s'\nText:\n%s", self.name, self.bookFormat())
		end,
		__call = function(self)
			for i=1, self.pages do
				print(i, self.page[i].title)
			end
		end
	})
	
	return self
end






return lib
