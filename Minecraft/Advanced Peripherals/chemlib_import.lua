--[[
	Chemlib Elements Configuration Script by PavelKom v0.5b-lua
	The script for the configuration of elements.json to work with chemlib_autocraft.lua
	Original elements.json
	https://github.com/SmashingMods/ChemLib/blob/9d42c5b4ec148a1497a04c79eee32b5216a2d30e/src/main/resources/data/chemlib/elements.json
	
	Lua version (for ingame launch)
]]

local function has_value(tab, val)
	for index, value in pairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

local PATH = 'elements.json'
local main_element_id = 6 -- Carbon
local keys_for_delete = {
	'matter_state',
	'fluid_properties',
	'metal_type',
	'color',
	'effect',
	}
local lantanoid = {57,71}
local actinoid  = {89,103}

-- Me Bridge is a bit buggy when working with Alchemistry fission and fusion reactors (cannot load/unload items correctly, tested on 1.19.2). RS Bridge is used instead, and ME is used to obtain the main element using Dissolver. 
local for_me_bridge = {6}

local x_offset = 0
local y_offset = 0
local x_l_a_offset = 5
local y_l_a_offset = 3

local f =io.open(PATH, 'r')
local d = textutils.unserializeJSON(f:read('*a'))
f:close()
local d2 = d['elements']

-- For Canbon relatives
-- Python indexes starts with 0
-- Lua indexes starts with 1
local new_data_dict = {}
for _, element in pairs(d2) do
	if element['atomic_number'] and element['atomic_number'] > 0 then
		local new_data = {}
		local index = element['atomic_number']
		new_data['atomic_number'] = index
		new_data['bridge'] = 'me' and has_value(index,for_me_bridge) or 'rs'
		new_data['name'] = 'chemlib:'..element['name']:gsub('chemlib:','')
		new_data['abbreviation'] = element['abbreviation']
		-- Add space for elements with 1 character in label
		if len(element['abbreviation']) < 2 then
			new_data['abbreviation'] = element['abbreviation']..' '
		end
		new_data['period'] = tonumber(element['period'])
		new_data['group'] = tonumber(element['group'])
		-- Set coordinates for monitor
		if index >= lantanoid[1] and index <= lantanoid[2] then
			new_data['y'] = new_data['period'] + y_offset + y_l_a_offset
			new_data['x'] = (element['atomic_number'] - lantanoid[1] + x_l_a_offset) * 2 + x_offset
		elseif index >= actinoid[1] and index <= actinoid[2] then
			new_data['y'] = new_data['period'] + y_offset + y_l_a_offset
			new_data['x'] = (element['atomic_number'] - actinoid[1] + x_l_a_offset) * 2 + x_offset
		else
			new_data['y'] = new_data['period'] + y_offset
			new_data['x'] = new_data['group'] * 2 - 1 + x_offset
		end
		-- Remove useless data
		for _, k2 in pairs(keys_for_delete) do
			if element[k2] then element[k2] = nil end
		end
		new_data_dict[index] = new_data
	end
end
for i, v in pairs(new_data_dict) do
	-- Add requires
	-- Fusion chamber
	if i >= main_element_id+2 then -- Oxygen, Fluorine, ...
		new_data_dict[i]['required'] = {
			{i-main_element_id, new_data_dict[i-main_element_id]['name']},
			{main_element_id, new_data_dict[main_element_id]['name']}
		}
	-- Fission chamber
	elseif i ~= main_element_id and i < main_element_id+2 then -- Hydrogen - Boron, Nitrogen
		new_data_dict[i]['required'] = {
			{i*2, new_data_dict[i*2]['name'],}
		}
	end
end
local new_data_list = {}
for i, v in new_data_dict.items() do
	new_data_list[#new_data_list+1] = v
end
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='  ',
	['x']=new_data_dict[lantanoid[0]-1]['x']+2,
	['y']=new_data_dict[lantanoid[0]-1]['y'],
	['color']= 'blue',
	['comment']='Patch between Ba(56) and Hf(72)',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='  ',
	['x']=new_data_dict[lantanoid[0]]['x']-2,
	['y']=new_data_dict[lantanoid[0]-1]['y'],
	['color']= 'blue',
	['comment']='Color label before La(57)',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='  ',
	['x']=new_data_dict[actinoid[0]-1]['x']+2,
	['y']=new_data_dict[actinoid[0]-1]['y'],
	['color']= 'purple',
	['comment']='Patch between Ra(88) and Rf(104)',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='  ',
	['x']=new_data_dict[actinoid[0]]['x']-2,
	['y']=new_data_dict[actinoid[0]-1]['y'],
	['color']= 'purple',
	['comment']='Color label before Ac(89)',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='Cannot be crafted',
	['x']=1 + x_offset,
	['y']=new_data_dict[actinoid[0]-1]['y']+2,
	['color']= 'red',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='Crafting',
	['x']=1 + x_offset,
	['y']=new_data_dict[actinoid[0]-1]['y']+3,
	['color']= 'yellow',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='No craft needed',
	['x']=1 + x_offset,
	['y']=new_data_dict[actinoid[0]-1]['y']+4,
	['color']= 'green',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='Lantanide',
	['x']=1 + x_offset,
	['y']=new_data_dict[actinoid[0]-1]['y']+5,
	['color']= 'blue',
	}
new_data_list[#new_data_list+1] = {
	--['atomic_number']= 0,
	['abbreviation']='Actinide',
	['x']=1 + x_offset,
	['y']=new_data_dict[actinoid[0]-1]['y']+5,
	['color']= 'purple',
	}

f = io.open(PATH, 'w')
local str_data = textutils.serializeJSON({['elements']=new_data_list})
f:write(str_data)
f:close()




