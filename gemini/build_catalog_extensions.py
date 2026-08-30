import json, re

with open(r'gemini/parsed_catalog_166.json', 'r', encoding='utf-8') as f:
    items = json.load(f)

lines = []
lines.append('# ==============================================================================')
lines.append('# CABINETRIX AI — COMPLETE 166-UNIT PDF CATALOGUE EXTENSION')
lines.append('# Generated from: references/Cabinetrix_Illustrated_Modular_Units_Catalog.pdf')
lines.append('# ==============================================================================')
lines.append('')
lines.append('module CabinetrixCatalogue')

for item in items:
    cid = item['id']
    name = item['name'].replace('"', '\\"')
    brand = item['brand'].replace('"', '\\"')
    desc = item['desc'].replace('"', '\\"')
    page = item['page']
    
    parts = [int(p) for p in re.findall(r'\d+', item['dims'])]
    w = parts[0] if len(parts) >= 1 else 600
    d = parts[1] if len(parts) >= 2 else 560
    h = parts[2] if len(parts) >= 3 else 720
    
    prefix = cid.split('-')[0]
    sub = cid.split('-')[1] if len(cid.split('-')) > 1 else ''
    
    if prefix == 'K':
        if sub in ['BAS', 'BIN']:
            cat = ':kitchen_base'
            eng_type = ':metod_base_unit'
        elif sub == 'BCO':
            cat = ':kitchen_corner_base'
            eng_type = ':base_blind_corner'
        elif sub in ['WAL', 'HOD']:
            cat = ':kitchen_wall'
            eng_type = ':wall_glass_display'
        elif sub == 'WCO':
            cat = ':kitchen_corner_wall'
            eng_type = ':wall_glass_display'
        elif sub in ['TOP', 'TFR']:
            cat = ':kitchen_top_bulkhead'
            eng_type = ':top_bulkhead_flap'
        elif sub in ['HBI', 'HIG']:
            cat = ':kitchen_tall'
            eng_type = ':tall_space_tower'
        else:
            cat = ':kitchen_other'
            eng_type = ':base_gola_drawers'
    elif prefix == 'O':
        if 'WI' in sub:
            cat = ':open_wine'
            eng_type = ':open_wine_grid'
        else:
            cat = ':open_frame'
            eng_type = ':open_rack_metal'
    elif prefix == 'W':
        cat = ':wardrobe_frame'
        eng_type = ':tall_pantry_larder'
    elif prefix == 'F':
        cat = ':functional_preset'
        eng_type = ':base_gola_drawers'
    elif prefix == 'I':
        cat = ':pax_internal'
        eng_type = ':pax_internal'
    elif prefix == 'G':
        cat = ':generic_construction'
        eng_type = ':base_gola_drawers'
    else:
        cat = ':other'
        eng_type = ':base_gola_drawers'
        
    lines.append(f'  register("{cid}", {{')
    lines.append(f'    id: "{cid}",')
    lines.append(f'    name: "{name} ({brand})",')
    lines.append(f'    brand: "{brand}",')
    lines.append(f'    category: {cat},')
    lines.append(f'    engine_type: {eng_type},')
    lines.append(f'    desc: "{desc}",')
    lines.append(f'    pdf_page: {page},')
    lines.append(f'    dimensions: {{ w: {w}.0, d: {d}.0, h: {h}.0 }}')
    lines.append('  })')
    lines.append('')

lines.append('end')

with open(r'gemini/catalogue_pdf_extensions.rb', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print('Wrote gemini/catalogue_pdf_extensions.rb successfully!')
