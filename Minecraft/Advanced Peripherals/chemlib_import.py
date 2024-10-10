# 

import json

# PATH = r'<path to your computer or other folder>/elements.json'
PATH = r'C:\Users\Pratica\Documents\elements.json'
main_element_id = 6 # Carbon
keys_for_delete = [
    'matter_state',
    'fluid_properties',
    'metal_type',
    'color',
    'effect',
    ]
lantanoid = [i for i in range(57,72)] # 57-71
actinoid  = [i for i in range(89,104)] # 89-103

x_offset = 0
y_offset = 0
x_l_a_offset = 5
y_l_a_offset = 3

with open(PATH) as f:
    d = json.load(f)
d2 = d['elements']

# For Canbon relatives
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
    new_data['name'] = 'chemlib:' + element['name']
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
        new_data['x'] = new_data['group'] * 2 + x_offset
    # Remove useless data
    for k2 in keys_for_delete:
        if k2 in element:
            del element[k2]
    new_data_dict[index] = new_data

for i, v in new_data_dict.items():
    # Add requires
    # Fusion chamber
    if i >= main_element_id+2: # Oxygen, Fluorine, ...
        new_data_dict[i]['required'] = [
            new_data_dict[i-main_element_id]['name'],
            new_data_dict[main_element_id]['name']
        ]
    # Fission chamber
    elif i != main_element_id and i < main_element_id+2: # Hydrogen - Boron, Nitrogen
        new_data_dict[i]['required'] = [
            new_data_dict[i*2]['name'],
        ]

new_data_list = []
for i, v in new_data_dict.items():
    new_data_list.append(v)
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[lantanoid[0]-1]['x']+2,
    'y':new_data_dict[lantanoid[0]-1]['y'],
    'color': 'blue',
    'comment':'Patch between Ba(56) and Hf(72)',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[lantanoid[0]]['x']-2,
    'y':new_data_dict[lantanoid[0]-1]['y'],
    'color': 'blue',
    'comment':'Color label before La(57)',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[actinoid[0]-1]['x']+2,
    'y':new_data_dict[actinoid[0]-1]['y'],
    'color': 'purple',
    'comment':'Patch between Ra(88) and Rf(104)',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'  ',
    'x':new_data_dict[actinoid[0]]['x']-2,
    'y':new_data_dict[actinoid[0]-1]['y'],
    'color': 'purple',
    'comment':'Color label before Ac(89)',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'Cannot be crafted',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]-1]['y']+2,
    'color': 'red',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'Crafting',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]-1]['y']+3,
    'color': 'yellow',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'No craft needed',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]-1]['y']+4,
    'color': 'green',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'Lantanide',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]-1]['y']+5,
    'color': 'blue',
    })
new_data_list.append({
    'atomic_number': 0,
    'abbreviation':'Actinide',
    'x':1 + x_offset,
    'y':new_data_dict[actinoid[0]-1]['y']+5,
    'color': 'purple',
    })



'''
for i,k in enumerate(d2):
    # Add requires
    if i >= main_element_id+1: # Oxygen, Fluorine, ...
        d2[i]['required'] = [
            d2[i-main_element_id]['name'],
            d2[main_element_id-1]['name']
        ]
    elif i != main_element_id-1 and i < main_element_id: # Hydrogen - Nitrogen
        d2[i]['required'] = [
            d2[i*2+1]['name'],
        ]
    # Add space for elements with 1 character in label
    #if len(d2[i]['abbreviation']) < 2:
    #    d2[i]['abbreviation'] += ' '
    #d2[i]['period'] = int(d2[i]['period'])
    #d2[i]['group'] = int(d2[i]['group'])
    # Set coordinates for monitor
    #if d2[i]['atomic_number'] in lantanoid:
    #    d2[i]['y'] = d2[i]['period'] + y_offset + y_l_a_offset
    #    d2[i]['x'] = (d2[i]['atomic_number'] - lantanoid[0]+x_l_a_offset) * 2 + x_offset
    #elif d2[i]['atomic_number'] in actinoid:
    #    d2[i]['y'] = d2[i]['period'] + y_offset + y_l_a_offset
    #    d2[i]['x'] = (d2[i]['atomic_number'] - actinoid[0] + x_l_a_offset) * 2 + x_offset
    #else:
    #    d2[i]['y'] = d2[i]['period'] + y_offset
    #    d2[i]['x'] = d2[i]['group'] * 2 + x_offset
    # Remove useless data
    #for k2 in keys_for_delete:
    #    if k2 in k:
    #        del d2[i][k2]
'''

with open(PATH, 'w') as f:
    json.dump({'elements':new_data_list}, f, indent=4, sort_keys=True)

