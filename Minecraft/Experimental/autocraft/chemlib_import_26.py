'''
    Chemlib Elements Configuration Script by PavelKom v1.0-python
    The script for the configuration of elements.json to work with chemlib_autocraft.lua
    Original elements.json
    https://github.com/SmashingMods/ChemLib/blob/9d42c5b4ec148a1497a04c79eee32b5216a2d30e/src/main/resources/data/chemlib/elements.json
    
    Python version (for non-ingame launch)

    Iron (Ferrum 26) version
'''

import json

PATH = r'elements.json'
main_element_id = 26 # Iron
keys_for_delete = [
    'matter_state',
    'fluid_properties',
    'metal_type',
    'color',
    'effect',
    ]
lantanoid = [i for i in range(57,72)] # 57-71
actinoid  = [i for i in range(89,104)] # 89-103

# Me Bridge is a bit buggy when working with Alchemistry fission and fusion reactors (cannot load/unload items correctly, tested on 1.19.2). RS Bridge is used instead, and ME is used to obtain the main element using Dissolver. 
for_me_bridge =  [i for i in range(1,119)]  #[6]

x_offset = 0
y_offset = 0
x_l_a_offset = 2
y_l_a_offset = 3

with open(PATH) as f:
    d = json.load(f)
d2 = d['elements']

# Python indexes starts with 0
# Lua indexes starts with 1
new_data_dict = {}
for element in d2:
    if 'atomic_number' not in element:
        continue
    if element['atomic_number'] <= 0:
        continue
    new_data = {}
    index = element['atomic_number']
    new_data['atomic_number'] = index
    new_data['bridge'] = 'me' if index in for_me_bridge else 'rs'
    new_data['name'] = 'chemlib:' + element['name'].replace('chemlib:','')
    new_data['abbreviation'] = element['abbreviation']
    # Add space for elements with 1 character in label
    if len(element['abbreviation']) < 2:
        new_data['abbreviation'] = element['abbreviation'] + ' '
    new_data['period'] = int(element['period'])
    new_data['group'] = int(element['group'])
    # Set coordinates for monitor
    if index in lantanoid:
        new_data['y'] = new_data['period'] + y_offset + y_l_a_offset
        new_data['x'] = (element['atomic_number'] - lantanoid[0] + x_l_a_offset) * 2 + x_offset
    elif index in actinoid:
        new_data['y'] = new_data['period'] + y_offset + y_l_a_offset
        new_data['x'] = (element['atomic_number'] - actinoid[0] + x_l_a_offset) * 2 + x_offset
    else:
        new_data['y'] = new_data['period'] + y_offset
        new_data['x'] = new_data['group'] * 2 - 1 + x_offset
    # Remove useless data
    for k2 in keys_for_delete:
        if k2 in element:
            del element[k2]
    new_data_dict[index] = new_data

for i, v in new_data_dict.items():
    # Add requires
    # Fusion chamber
    if i == main_element_id*2: # Tellurium
        new_data_dict[i]['required'] = [
            new_data_dict[main_element_id-1]['name'],
            new_data_dict[main_element_id+1]['name']
        ]
    # Fission chamber
    elif i < main_element_id:
        new_data_dict[i]['required'] = [
            new_data_dict[i*2]['name'],
        ]
    elif i > main_element_id:
        new_data_dict[i]['required'] = [
            new_data_dict[i-main_element_id]['name'],
            new_data_dict[main_element_id]['name']
        ]

new_data_list = []
for i, v in new_data_dict.items():
    new_data_list.append(v)
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[lantanoid[0]-1]['x']+2,
    'y':new_data_dict[lantanoid[0]-1]['y'],
    'color': 'blue',
    'comment':'Patch between Ba(56) and Hf(72)',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[lantanoid[0]]['x']-2,
    'y':new_data_dict[lantanoid[0]]['y'],
    'color': 'blue',
    'comment':'Color label before La(57)',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[actinoid[0]-1]['x']+2,
    'y':new_data_dict[actinoid[0]-1]['y'],
    'color': 'purple',
    'comment':'Patch between Ra(88) and Rf(104)',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[actinoid[0]]['x']-2,
    'y':new_data_dict[actinoid[0]]['y'],
    'color': 'purple',
    'comment':'Color label before Ac(89)',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'Cannot be crafted',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]]['y']+2 + y_offset,
    'color': 'red',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'Crafting',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]]['y']+3 + y_offset,
    'color': 'yellow',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'No craft needed',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]]['y']+4 + y_offset,
    'color': 'green',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'Lantanide',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]]['y']+5 + y_offset,
    'color': 'blue',
    })
new_data_list.append({
    #'atomic_number': 0,
    'abbreviation':'Actinide',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]]['y']+6 + y_offset,
    'color': 'purple',
    })

with open(PATH, 'w') as f:
    json.dump({'elements':new_data_list}, f, indent=4, sort_keys=True)

