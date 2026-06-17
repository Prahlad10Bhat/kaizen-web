import re

with open(r'd:\Apps\FlutterApps\kaizen\lib\features\home\home_page.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

brace_level = 0

for i, line in enumerate(lines):
    line_num = i + 1
    
    # Print brace level for declarations
    trimmed = line.strip()
    if trimmed.startswith('class ') or trimmed.startswith('Widget ') or trimmed.startswith('void ') or trimmed.startswith('Future<') or trimmed.startswith('Color '):
        print(f"L{line_num:4d} (lvl {brace_level}): {trimmed}")
        
    for char in line:
        if char == '{':
            brace_level += 1
        elif char == '}':
            brace_level -= 1
            if brace_level < 0:
                print(f"Error: Negative brace level at line {line_num}")

print(f"Final levels -> Braces: {brace_level}")
