import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all occurrences of GestureDetector
    pattern = re.compile(r'GestureDetector\s*\(')
    
    modified = False
    
    while True:
        match = pattern.search(content)
        if not match:
            break
            
        start_idx = match.start()
        
        # Check if already wrapped
        # We can look at the 100 characters before start_idx
        # If they contain 'MouseRegion(' and 'SystemMouseCursors.click' with only whitespace/child: in between, it's wrapped.
        # But even simpler: if 'MouseRegion' and 'SystemMouseCursors.click' appear shortly before.
        before_text = content[max(0, start_idx-150):start_idx]
        if 'MouseRegion' in before_text and 'SystemMouseCursors.click' in before_text:
            # Mask this match so we don't find it again
            content = content[:start_idx] + "TEMP_GEST_DET" + content[start_idx+15:]
            continue
            
        open_parens = 0
        end_idx = -1
        for i in range(start_idx + len("GestureDetector"), len(content)):
            if content[i] == '(':
                open_parens += 1
            elif content[i] == ')':
                if open_parens == 1:
                    end_idx = i
                    break
                open_parens -= 1
                
        if end_idx != -1:
            before = content[:start_idx]
            detector_block = content[start_idx:end_idx+1]
            after = content[end_idx+1:]
            
            content = before + "MouseRegion(cursor: SystemMouseCursors.click, child: " + "TEMP_GEST_DET" + detector_block[15:] + ")" + after
            modified = True
        else:
            break
            
    # Unmask
    content = content.replace("TEMP_GEST_DET", "GestureDetector")
            
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
