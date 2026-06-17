import os
import re

lib_dir = 'd:/Apps/FlutterApps/kaizen/lib'

import_statement = "import 'package:kaizen/utils/snackbar_utils.dart';"

def count_parens(s):
    return s.count('(') - s.count(')')

for root, _, files in os.walk(lib_dir):
    for file in files:
        if not file.endswith('.dart'): continue
        if file == 'snackbar_utils.dart': continue
        
        path = os.path.join(root, file)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if 'showSnackBar' not in content:
            continue
            
        # Add import if needed
        lines = content.split('\n')
        has_import = any('snackbar_utils.dart' in line for line in lines)
        if not has_import:
            # find last import
            last_import = -1
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    last_import = i
            if last_import != -1:
                lines.insert(last_import + 1, import_statement)
            content = '\n'.join(lines)
            
        # We need to replace: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('...'), ...));
        # Let's use regex to find ScaffoldMessenger.of(context).showSnackBar(
        pattern = r'ScaffoldMessenger\.of\(context\)\.showSnackBar\('
        
        while True:
            match = re.search(pattern, content)
            if not match:
                break
                
            start_idx = match.start()
            # find end of ScaffoldMessenger...showSnackBar(
            end_idx = match.end()
            
            parens = 1
            i = end_idx
            while parens > 0 and i < len(content):
                if content[i] == '(': parens += 1
                elif content[i] == ')': parens -= 1
                i += 1
                
            # Now we have the block from start_idx to i.
            # Usually the argument is a SnackBar(content: Text('message'), ...)
            block = content[start_idx:i]
            
            # Extract the message from SnackBar(content: Text('message') or SnackBar(content: const Text('message'))
            # Let's try to match content: Text('message') or content: const Text('message')
            msg_match = re.search(r"content:\s*(?:const\s+)?Text\((.*?)\)", block, flags=re.DOTALL)
            is_error = 'Colors.red' in block or 'backgroundColor: theme.colorScheme.error' in block
            
            if msg_match:
                msg = msg_match.group(1).strip()
                # remove trailing comma if present
                if msg.endswith(','): msg = msg[:-1]
                
                replacement = f"SnackbarUtils.showCustomSnackBar(context, {msg}"
                if is_error:
                    replacement += ", isError: true"
                replacement += ")"
                
                content = content[:start_idx] + replacement + content[i:]
            else:
                print(f"Could not parse message in {file}")
                # skip this one by replacing ScaffoldMessenger with something else temporarily
                content = content[:start_idx] + "TEMP_SCAFFOLD" + content[start_idx+17:]
                
        # restore TEMP_SCAFFOLD
        content = content.replace("TEMP_SCAFFOLD", "ScaffoldMessenger")
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

print('Done')
