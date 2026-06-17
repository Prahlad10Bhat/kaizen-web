"""
calendar_page.dart decomposition script.

Strategy:
- Read entire file
- Identify exact line boundaries for each extractable section
- Create widget files with proper imports + correct parent class
- Replace extracted methods in calendar_page.dart with thin delegating calls
- Preserve ALL logic, visual appearance, and behavior
"""

import os
import re

CALENDAR_PAGE = r"lib/features/calendar/calendar_page.dart"

with open(CALENDAR_PAGE, "r", encoding="utf-8") as f:
    content = f.read()

lines = content.splitlines(keepends=True)
print(f"Total lines: {len(lines)}")

# Find method start lines
method_starts = {}
for i, line in enumerate(lines):
    m = re.match(r'^  (?:Widget|void|bool|String|DateTime|int|List|Map|Set|Future|Stream|double)\s+(\w+)\s*[\(<]', line)
    if m:
        method_starts[m.group(1)] = i  # 0-based

print("Methods found:")
for name, line in sorted(method_starts.items(), key=lambda x: x[1]):
    print(f"  {name} @ line {line+1}")
