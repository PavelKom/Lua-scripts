--[[
	Testprint chars from \x00 to \xFF into terminal or printer
	Author: PavelKom
	Version: 0.1
]]

local function draw(obj)
	obj = obj or term
	if obj == term then
		obj.clear()
	else -- printer
		obj.newPage()
		obj.setPageTitle("Testprint")
	end
	obj.setCursorPos(1,1)
	obj.write(" |0123456789ABCDEF")
	obj.setCursorPos(1,2)
	obj.write("-+----------------")
	for i=0,15 do
		obj.setCursorPos(1,3+i)
		local s = ("%X|"):format(i)
		for j=0,15 do
			s=s..string.char(i*16+j)
		end
		obj.write(s)
	end
	if obj == term then
		os.pullEvent("key")
	else
		obj.endPage()
	end
end

local input = { ... }
local p
if #input > 0 then -- use printer
	p = peripheral.wrap(input[1]) or peripheral.find('printer')
	if not p then error("Printer not founded") end
end
draw(p)


