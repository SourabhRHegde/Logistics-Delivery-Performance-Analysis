#!/usr/bin/env python3
import json
import os

notebook_path = 'NovaMart_EDA_Notebook.ipynb'

# Read file with UTF-8
try:
    with open(notebook_path, 'r', encoding='utf-8') as f:
        nb = json.load(f)
    print(f"Successfully loaded notebook with {len(nb['cells'])} cells")
except json.JSONDecodeError as e:
    print(f"JSON decode error: {e}")
    # Try to recover
    with open(notebook_path, 'rb') as f:
        raw_data = f.read()
    print(f"Raw file size: {len(raw_data)} bytes")
    
    # Try to find valid JSON
    json_str = raw_data.decode('utf-8', errors='ignore')
    
    # Find the notebook cells section
    try:
        nb = json.loads(json_str)
        print(f"Recovered notebook with {len(nb['cells'])} cells")
        
        # Write back the recovered notebook
        with open(notebook_path + '.recovered', 'w', encoding='utf-8') as f:
            json.dump(nb, f, indent=1)
        print("Saved recovered notebook as .recovered file")
        
    except json.JSONDecodeError as e2:
        print(f"Cannot recover JSON: {e2}")
        print(f"Error at line {e2.lineno}, column {e2.colno}")
except Exception as e:
    print(f"Unexpected error: {e}")

