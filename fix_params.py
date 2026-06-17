"""
Fix structural corruption in calendar_page.dart and task_board_page.dart.
The main corruption patterns are:
1. Named parameters using '=' instead of ':' (e.g., onPressed = )
2. ElevatedButton.styleFrom() closing parens misplaced  
3. AlertDialog with misplaced closing syntax

This script rewrites the files with corrected syntax.
"""

import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Pattern 1: Fix named params using = instead of :
    # Match things like:  identifier = expression,
    # where identifier looks like a Flutter named param (lowercase start, no space before)
    # Be conservative - only fix known-bad patterns
    
    # In widget contexts: property = value  -> property: value
    # This is tricky because we also use = for assignments in code blocks
    # Strategy: only fix inside widget constructor calls (lines with no preceding variable declaration)
    
    lines = content.splitlines(keepends=True)
    fixed_lines = []
    
    for line in lines:
        original_line = line
        
        # Fix pattern: "  identifier = " at start of property context
        # These appear inside widget builds where named params should use :
        # Match lines that look like: "                  onPressed = () =>"
        # but NOT "  final x = " or "  x = y;" (assignments)
        # Heuristic: if line has no 'final', 'var', 'const' and uses known widget params
        
        widget_params = [
            'onPressed', 'onTap', 'onChanged', 'onSelected', 'onSecondaryTap',
            'child', 'children', 'icon', 'label', 'style', 'decoration',
            'padding', 'margin', 'color', 'backgroundColor', 'foregroundColor',
            'minimumSize', 'shape', 'elevation', 'side', 'leadingIcon',
            'builder', 'itemBuilder', 'tooltip', 'value', 'groupValue',
            'flex', 'fit', 'alignment', 'crossAxisAlignment', 'mainAxisAlignment',
            'mainAxisSize', 'textStyle', 'textAlign', 'overflow', 'maxLines',
            'autofocus', 'controller', 'hintText', 'hintStyle', 'fillColor',
            'filled', 'border', 'enabledBorder', 'contentPadding', 'prefixIcon',
            'suffixIcon', 'visualDensity', 'activeColor', 'toggleable',
            'cursor', 'mouseCursor', 'borderRadius', 'crossAxisCount',
            'childAspectRatio', 'crossAxisSpacing', 'mainAxisSpacing',
            'physics', 'shrinkWrap', 'itemCount', 'constraints',
            'itemExtent', 'key', 'textInputAction', 'keyboardType',
            'minWidth', 'maxWidth', 'minHeight', 'maxHeight',
        ]
        
        # Check if the line has a named param using = instead of :
        for param in widget_params:
            # Match: whitespace + param + whitespace* + = + whitespace
            # But NOT: param == (equality check)
            pattern = rf'^(\s+{re.escape(param)})\s*=\s*(?!=)'
            if re.match(pattern, line):
                line = re.sub(pattern, rf'\1: ', line)
                break
        
        fixed_lines.append(line)
    
    content = ''.join(fixed_lines)
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")
        return True
    
    print(f"No changes needed for {filepath}")
    return False

# Fix both files
fix_file('lib/features/calendar/calendar_page.dart')
fix_file('lib/features/tasks/task_board_page.dart')
