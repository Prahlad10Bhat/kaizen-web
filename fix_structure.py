"""
Fix structural syntax errors in calendar_page.dart:

Pattern 1: ElevatedButton/OutlinedButton/IconButton .styleFrom() with misplaced closing paren
  
  BROKEN:
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.primaryColor,
      foregroundColor: theme.colorScheme.onPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: ...
  
  FIXED:
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.primaryColor,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    ),
    child: ...

Pattern 2: AlertDialog with misplaced side/shape:
  BROKEN:
    AlertDialog(
      backgroundColor: ..., side: BorderSide(...)),
      title: ...
  FIXED:
    AlertDialog(
      backgroundColor: ...,
      side: BorderSide(...),
      title: ...

Pattern 3: IconButton.styleFrom() with minimumSize misplaced:
  BROKEN:
    style: IconButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.1)),
      minimumSize: const Size(...),
    ),
  FIXED:
    style: IconButton.styleFrom(
      backgroundColor: color.withValues(alpha: 0.1),
      minimumSize: const Size(...),
    ),
"""

def fix_calendar_page():
    with open('lib/features/calendar/calendar_page.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Fix 1: ElevatedButton.styleFrom - closing paren before padding
    # Pattern: "foregroundColor: theme.colorScheme.onPrimary),\n  padding: ..." 
    # The `)` at end of the foregroundColor line closes styleFrom too early
    content = content.replace(
        '          foregroundColor: theme.colorScheme.onPrimary),\n          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),\n        ),\n        child: const Text(\'Today\', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n      );',
        '          foregroundColor: theme.colorScheme.onPrimary,\n          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),\n        ),\n        child: const Text(\'Today\', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),\n      );'
    )
    
    # Fix 2: OutlinedButton.styleFrom - same pattern
    content = content.replace(
        "        side: BorderSide(color: theme.dividerColor)),\n          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),\n        ),\n        child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),",
        "        side: BorderSide(color: theme.dividerColor),\n        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),\n        ),\n        child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),"
    )
    
    # Fix 3: IconButton.styleFrom - minimumSize misplaced
    content = content.replace(
        "                  backgroundColor: appColors.calendarAccent.withValues(alpha: 0.1)),\n                    minimumSize: isUltraCompact ? const Size(36, 36) : const Size(48, 48),\n                  ),\n                ),",
        "                  backgroundColor: appColors.calendarAccent.withValues(alpha: 0.1),\n                    minimumSize: isUltraCompact ? const Size(36, 36) : const Size(48, 48),\n                  ),\n                ),"
    )
    
    # Fix 4: compact IconButton.styleFrom
    content = content.replace(
        "            backgroundColor: isCurrentlyToday ? theme.cardColor : theme.primaryColor),\n              minimumSize: isUltraCompact ? const Size(40, 40) : const Size(52, 52),\n            ),",
        "            backgroundColor: isCurrentlyToday ? theme.cardColor : theme.primaryColor,\n            minimumSize: isUltraCompact ? const Size(40, 40) : const Size(52, 52),\n            ),"
    )
    
    # Fix 5: AlertDialog in management dialog - side param
    # Pattern: "backgroundColor: ..., side: ...)"  -> separate lines with proper comma
    content = content.replace(
        "      builder: (context) => AlertDialog(\n        backgroundColor: theme.dialogTheme.backgroundColor,\n          side: BorderSide(color: theme.dividerColor),\n        ),\n        title: Row(",
        "      builder: (context) => AlertDialog(\n        backgroundColor: theme.dialogTheme.backgroundColor,\n        shape: RoundedRectangleBorder(\n          side: BorderSide(color: theme.dividerColor),\n          borderRadius: BorderRadius.circular(16),\n        ),\n        title: Row("
    )
    
    # Fix 6: ElevatedButton.styleFrom with misplaced closing in action button
    content = content.replace(
        "                    backgroundColor: const Color(0xFF1E1E1E),\n                      foregroundColor: Colors.white,\n                      elevation: 0),\n                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),\n                      minimumSize: const Size(0, 32),\n                    ),",
        "                    backgroundColor: const Color(0xFF1E1E1E),\n                      foregroundColor: Colors.white,\n                      elevation: 0,\n                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),\n                      minimumSize: const Size(0, 32),\n                    ),"
    )
    
    # Fix 7: ElevatedButton in calendar management - minimumSize  
    content = content.replace(
        "                elevation: 0),\n                minimumSize: const Size(double.infinity, 36),\n              ),\n            ),",
        "                elevation: 0,\n                minimumSize: const Size(double.infinity, 36),\n              ),\n            ),"
    )

    # Fix 8: ElevatedButton.icon - minimumSize
    content = content.replace(
        "            backgroundColor: theme.primaryColor),\n              minimumSize: const Size(double.infinity, 40),\n            ),\n          ),\n        ),",
        "            backgroundColor: theme.primaryColor,\n              minimumSize: const Size(double.infinity, 40),\n            ),\n          ),\n        ),"
    )
    
    # Fix 9: Add Calendar/Edit Calendar AlertDialog - side as shape
    for broken, fixed in [
        (
            "      builder: (context) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          backgroundColor: theme.dialogTheme.backgroundColor, side: BorderSide(color: theme.dividerColor)),\n          title: Text('Create Calendar'",
            "      builder: (context) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          backgroundColor: theme.dialogTheme.backgroundColor,\n          title: Text('Create Calendar'"
        ),
        (
            "      builder: (context) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          backgroundColor: theme.dialogTheme.backgroundColor, side: BorderSide(color: theme.dividerColor)),\n          title: Text('Edit Calendar'",
            "      builder: (context) => StatefulBuilder(\n        builder: (context, setDialogState) => AlertDialog(\n          backgroundColor: theme.dialogTheme.backgroundColor,\n          title: Text('Edit Calendar'"
        ),
        (
            "      builder: (context) => AlertDialog(\n        backgroundColor: theme.dialogTheme.backgroundColor, side: BorderSide(color: theme.dividerColor)),\n        title: Text('Delete Calendar'",
            "      builder: (context) => AlertDialog(\n        backgroundColor: theme.dialogTheme.backgroundColor,\n        title: Text('Delete Calendar'"
        ),
    ]:
        content = content.replace(broken, fixed)
    
    # Fix 10: Checkbox visual density misplaced
    # pattern: "activeColor: Color(c.colorValue)),\n  visualDensity:"
    # The )) closes the Checkbox constructor too early, leaving visualDensity as dangling
    import re
    # Fix Checkbox with misplaced closing paren
    content = re.sub(
        r'(Checkbox\([^)]+activeColor: Color\(c\.colorValue\))\),(\s+visualDensity:)',
        r'\1,\2',
        content
    )

    # Fix 11: sidebar Row's ElevatedButton.styleFrom
    content = content.replace(
        "            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),\n              foregroundColor: theme.primaryColor,\n              elevation: 0),\n              minimumSize: const Size(double.infinity, 36),\n            ),\n          ),",
        "            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),\n              foregroundColor: theme.primaryColor,\n              elevation: 0,\n              minimumSize: const Size(double.infinity, 36),\n            ),\n          ),"
    )

    # Fix 12: MenuAnchor ElevatedButton styles (in right sidebar)
    content = content.replace(
        "                  foregroundColor: Colors.white,\n                  elevation: 0),\n                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),\n                  minimumSize: const Size(0, 32),\n                ),",
        "                  foregroundColor: Colors.white,\n                  elevation: 0,\n                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),\n                  minimumSize: const Size(0, 32),\n                ),"
    )
    
    if content != original:
        with open('lib/features/calendar/calendar_page.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        changed = sum(1 for a, b in zip(original.splitlines(), content.splitlines()) if a != b)
        print(f"Fixed calendar_page.dart ({changed} lines changed)")
    else:
        print("No changes to calendar_page.dart - patterns not found")


def fix_task_board_page():
    with open('lib/features/tasks/task_board_page.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Fix the showMenu with misplaced side/closing paren
    # BROKEN:
    #   color: theme.cardColor,
    #   elevation: 8,
    #     side: BorderSide(color: theme.dividerColor),
    #   ),
    #   items: [
    content = content.replace(
        "            color: theme.cardColor,\n            elevation: 8,\n              side: BorderSide(color: theme.dividerColor),\n            ),\n            items: [",
        "            color: theme.cardColor,\n            elevation: 8,\n            items: ["
    )
    
    # Fix Padding/Row with = instead of : (named param corruption)
    content = content.replace(
        "          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),\n          child: Row(",
        "          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),\n          child: Row("
    )
    
    if content != original:
        with open('lib/features/tasks/task_board_page.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Fixed task_board_page.dart")
    else:
        print("No changes to task_board_page.dart - patterns not found")


fix_calendar_page()
fix_task_board_page()
print("Done.")
