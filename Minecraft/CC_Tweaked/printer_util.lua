--[[
	Printer Utility library by PavelKom.
	Version: 0.9
	Wrapped Printer
	https://tweaked.cc/peripheral/monitor.html
	TODO: Add manual
]]
getset = require 'getset_util'
ccs = require "cc.strings"

local this_library = {}
this_library.DEFAULT_STRESSOMETER = nil

function this_library:Printer(name)
	local def_type = 'printer'
	local ret = {object = name and peripheral.wrap(name) or peripheral.find(def_type)}
	if ret.object == nil then error("Can't connect to Printer '"..name or def_type.."'") end
	ret.name = peripheral.getName(ret.object)
	ret.type = peripheral.getType(ret.object)
	if ret.type ~= def_type then error("Invalid peripheral type. Expect '"..def_type.."' Present '"..ret.type.."'") end

	ret.__getter = {
		size = function() return {ret.object.getPageSize()} end,
		rows = function() return ret.size[2] end,
		columns = function() return ret.size[1] end,
		ink = function() return ret.object.getInkLevel() end,
		paper = function() return ret.object.getPaperLevel() end,
	}
	ret.__setter = {
		title = function(value) return ret.object.setPageTitle(value) end,
	}
	ret.__getter.cols = ret.__getter.columns
	ret.pos = {}
	setmetatable(ret.pos, {
		__call = function(self, x_tbl, y)
			if type(x_tbl) == 'table' then
				ret.object.setCursorPos(x_tbl[1] or x_tbl.x or 1, x_tbl[2] or x_tbl.y or 1)
			elseif x_tbl ~= nil and y ~= nil then
				ret.object.setCursorPos(x_tbl, y)
			elseif x_tbl ~= nil and y == nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(x_tbl, _y)
			elseif x_tbl == nil and y ~= nil then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, y)
			end
			return ret.object.getCursorPos()
		end,
		__index = function(self, index)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				return _x
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				return _y
			elseif string.lower(tostring(index)) == 'xy' then
				return ret.object.getCursorPos()
			end
		end,
		__newindex = function(self, index, value)
			if string.lower(tostring(index)) == 'x' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(value, _y)
			elseif string.lower(tostring(index)) == 'y' then
				local _x, _y = ret.object.getCursorPos()
				ret.object.setCursorPos(_x, value)
			elseif string.lower(tostring(index)) == 'xy' then
				ret.object.setCursorPos(value[1] or value.x or 1, value[2] or value.y or 1)
			end
		end,
	})
	ret.write = function (text) return ret.object.write(text) end
	ret.write2 = function(text, onNewPage, closePage)
		local res, err, err2 = pcall(ret.object.getPageSize)
		if not res or onNewPage then
			if ret.paper == 0 then
				error("[Printer] Not enough paper")
			end
			ret.new()
			res, err, err2 = pcall(ret.object.getPageSize)
			if not res then error(err) end
		end
		local _lines = ccs.wrap(text, err)
		local _rows = err2
		if #_lines / _rows > ret.paper then
			error("[Printer] Not enough paper")
		end
		
		while #_lines > 0 do
			if _rows == 0 then
				ret.close()
				ret.new()
				_rows = ret.rows
			end
			local res, err = pcall(ret.write, _lines[1])
			table.remove(_lines,1)
			_rows = _rows - 1
		end
		if closePage then
			ret.close()
		end
	end

	ret.load = function() return ret.object.newPage() end
	ret.print = function() return ret.object.endPage() end
	
	ret.printPages = function(text, titles, delay)
		delay = delay or 1
		repeat
			if ret.paper == 0 then
				error("[Printer] Not enough paper")
			elseif ret.ink == 0 then
				error("[Printer] Not enough ink")
			end
			ret.load()
			if titles and type(titles) == 'table' and #titles > 0 then
				ret.title = tostring(titles[1])
				table.remove(titles,1)
			end
			local _cols, _rows = ret.object.getPageSize()
			local _lines = ccs.wrap(text, _cols)
			for i = 1, _rows do
				if #_lines == 0 then break end
				ret.pos.x = 1
				ret.pos.y = i
				ret.write(_lines[1])
				table.remove(_lines,1)
			end
			ret.print()
			text = table.concat(_lines)
			sleep(delay)
		until #text <= 0
	end
	ret.printPages2 = function(text, titles, delay)
		-- https://github.com/cc-tweaked/CC-Tweaked/blob/mc-1.19.2/src/main/java/dan200/computercraft/shared/media/items/ItemPrintout.java
		-- public static final int LINES_PER_PAGE = 21;
		-- public static final int LINE_MAX_LENGTH = 25;
		-- public static final int MAX_PAGES = 16;
		delay = delay or 1
		local _lines = ccs.wrap(text, 25)
		local req = math.floor(#_lines/21)
		--if req > 16 then
		--	error("[Printer] Too many pages for a book, maximum 16 pages (25x21=525 characters per page, 525x16=8400 characters per book)")
		if ret.paper < req then
			error(string.format("[Printer] Not enough paper. Required: %i Present: %i",req, ret.paper))
		elseif ret.ink < req then
			error(string.format("[Printer] Not enough ink. Required: %i Present: %i",req, ret.ink))
		end
		while #_lines > 0 do
			ret.load()
			ret.title = titles[1]
			table.remove(titles,1)
			for i = 1, 21 do
				if #_lines == 0 then break end
				ret.pos.x = 1
				ret.pos.y = i
				ret.write(_lines[1])
				table.remove(_lines,1)
			end
			ret.print()
			sleep(delay)
		end
	end
	
	ret.printBook = function(book, withSequel, delay)
		local _pages = book.pages
		if withSequel  then _pages = book.pagesWithSequel end
		if _pages > ret.paper then
			error(string.format("[Printer] Not enough paper. Required: %i Present: %i",_pages, ret.paper))
		elseif withSequel and _pages > ret.ink then
			error(string.format("[Printer] Not enough ink. Required: %i Present: %i",_pages, ret.ink))
		end
		while book do
			local _text, _titles = book.bookRaw()
			ret.printPages2(_text, _titles, delay)
			if withSequel then
				book = book.sequel
			else
				break
			end
		end
	end
	
	ret.erase = function(pages, delay)
		pages = pages or 1
		delay = delay or 1
		for i = 1, pages do
			ret.load()
			local _cols, _rows = ret.object.getPageSize()
			for i = 1, _rows do
				ret.pos.x = 1
				ret.pos.y = i
				ret.write(ccs.ensure_width(" ", _cols))
			end
			ret.title = ""
			ret.print()
			sleep(delay)
		end
	end

	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Printer '%s'", self.name)
		end,
		__eq = getset.EQ_PERIPHERAL
	})
	return ret
end

function this_library:Book(text, name)
	if text and type(text) ~= 'string' then error("[Book] Invalid input type data") end
	local ret = {name=name or '', page={}}
	if text then
		local _lines = ccs.wrap(text, 25)
		while #_lines > 0 do
			ret.page[#ret.page+1] = {line={}, title=''}
			for i = 1, 21 do
				if #_lines == 0 then break end
				ret.page[#ret.page].line[i] = _lines[1]
				table.remove(_lines,1)
			end
		end
	end
	ret.__getter = {
		pages = function() return #ret.page end,
		pagesWithSequel = function()
			local _result = ret.pages
			if ret.sequel then _result = _result + ret.sequel.pagesWithSequel end
			return _result
		end,
	}
	ret.setter = {}
	ret.setLabel = function(pageNum, title) ret.page[pageNum].title = tostring(title) end
	ret.add = function(text, pageNumInsert)
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
				ret.page[#ret.page+1] = _page
			else
				table.insert(ret.page, pageNumInsert + offset, _page)
				offset = offset + 1
			end
		end
	end
	ret.remove = function(pageNumStart, pageNumEnd)
		table.remove(ret.page, pageNumStart)
		while pageNumEnd and pageNumEnd > pageNumStart do
			table.remove(ret.page, pageNumStart)
			pageNumEnd = pageNumEnd - 1
		end
	end
	ret.pageRaw = function(pageNum) return table.concat(ret.page[pageNum].line), ret.page[pageNum].title end
	ret.bookRaw = function(startPage, endPage)
		startPage = startPage or 1
		endPage = endPage or ret.pages
		local _text = ""
		local _titles = {}
		for i=startPage, endPage do
			local _page, _title = ret.pageRaw(i)
			_text= _text.._page
			_titles[#_titles+1] = _title or ""
		end
		return _text, _titles
	end
	ret.bookFormat = function(startPage, endPage)
		startPage = startPage or 1
		endPage = endPage or ret.pages
		local _result = ""
		for i=startPage, endPage do
			local _page, _title = ret.pageRaw(i)
			_result = string.format("%sPage %i '%s'\n%s\n", _result, i, _title, _page)
		end
		return _result
	end
	ret.splitToSequel = function(cutOriginal)
		if ret.pages <= 16 then return nil end
		local _book = this_library:Book(ret.bookRaw(17))
		if cutOriginal then ret.remove(17, ret.pages) end
		return _book
	end
	ret.generateSequel = function()
		if ret.sequel then return ret.sequel end
		ret.sequel = ret.splitToSequel(true)
		if ret.sequel then ret.sequel.generateSequel() end
		return ret.sequel
	end
	ret.autoTitle = function()
		for i=1, ret.pages do
			ret.page[i].title = string.format("%i%s%s",i, #ret.page[i].title > 0 and '. ' or '', ret.page[i].title)
		end
	end
	
	setmetatable(ret, {
		__index = getset.GETTER, __newindex = getset.SETTER, 
		__pairs = getset.PAIRS, __ipairs = getset.IPAIRS,
		__tostring = function(self)
			return string.format("Book: '%s'\nText:\n%s", self.name, self.bookFormat())
		end,
		__call = function(self)
			for i=1, ret.pages do
				print(i, ret.page[i].title)
			end
		end
	})
	
	return ret
end






return this_library
