# fix_syntax.ps1
# Automatically fixes the most common AI-generated corruption in Dart files:
# 1. styleFrom() closing early with ), leaving params like 'padding:', 'elevation:', 'minimumSize:', 'child:' outside
# 2. Other constructors (AlertDialog, TextButton.styleFrom, etc.) with the same premature closing paren

$files = @(
    "lib\features\boxclock\boxclock_page.dart",
    "lib\features\canvas\canvas_dashboard.dart",
    "lib\features\canvas\canvas_editor.dart",
    "lib\features\habits\habits_page.dart",
    "lib\features\notes\notes_page.dart",
    "lib\features\notes\widgets\note_editor.dart",
    "lib\features\settings\settings_page.dart",
    "lib\features\workout\workout_page.dart"
)

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        Write-Host "Skipping $file (not found)"
        continue
    }
    
    $content = Get-Content $file -Raw -Encoding UTF8
    $originalContent = $content
    
    # Pattern 1: styleFrom( ... lastParam), then next line is misplaced param: value,
    # Fix: remove the premature ) so the next param becomes valid
    # We target: backgroundColor: X,\n                foregroundColor: Y),\n              padding: or elevation: or minimumSize:
    
    # This regex finds the pattern: any content), followed by indent + named param that shouldn't be outside
    # We look for: <whitespace>foregroundColor: <...>),\n<whitespace>padding: (or elevation: or minimumSize:)
    $content = $content -replace '(\s+)(foregroundColor:\s+[^,\r\n]+)\),(\s+)((?:padding|elevation|minimumSize|shape|textStyle|side|fixedSize|maximumSize|tapTargetSize|visualDensity|splashColor|shadowColor|overlayColor|surfaceTintColor|enableFeedback|animationDuration):\s)', '$1$2,$3$4'
    $content = $content -replace '(\s+)(backgroundColor:\s+[^,\r\n]+)\),(\s+)((?:padding|elevation|minimumSize|foregroundColor|shape|textStyle|side|fixedSize|maximumSize|tapTargetSize|visualDensity|splashColor|shadowColor|overlayColor|surfaceTintColor|enableFeedback|animationDuration):\s)', '$1$2,$3$4'
    
    # More patterns - any line ending with ),  followed by named param that implies we're still inside styleFrom
    $content = $content -replace '(\s+)(elevation:\s+\d+)\),(\s+)((?:padding|minimumSize|foregroundColor|backgroundColor|shape|textStyle):\s)', '$1$2,$3$4'
    $content = $content -replace '(\s+)(padding:\s+const[^,\r\n]+)\),(\s+)((?:elevation|minimumSize|foregroundColor|backgroundColor|shape|textStyle):\s)', '$1$2,$3$4'
    $content = $content -replace '(\s+)(minimumSize:\s+const[^,\r\n]+)\),(\s+)((?:elevation|padding|foregroundColor|backgroundColor|shape|textStyle):\s)', '$1$2,$3$4'
    
    # Pattern 2: ElevatedButton.styleFrom(...),\n  ),\n  child: - the extra ), closes the ElevatedButton, leaving child: outside
    # This is the "child outside constructor" pattern
    # We look for: style: ElevatedButton.styleFrom(\n...),\n  ),\n  child:
    # And fix it to: style: ElevatedButton.styleFrom(\n...),\n  child:
    # Then the outer ), is removed
    
    # AlertDialog that closes too early: backgroundColor: X)),  -> backgroundColor: X,
    $content = $content -replace '(backgroundColor:\s+[^,\r\n]+)\)\),', '$1,'
    
    # TextButton.styleFrom that closes early: padding: X)),
    $content = $content -replace '(TextButton\.styleFrom\([^)]*)(padding:\s+[^,\r\n]+)\),\s*\),\s*child:', {
        param($m)
        "$($m.Groups[1].Value)$($m.Groups[2].Value),`n                          ),`n                          child:"
    }
    
    if ($content -ne $originalContent) {
        Set-Content $file -Value $content -Encoding UTF8 -NoNewline
        Write-Host "Fixed: $file"
    } else {
        Write-Host "No changes: $file"  
    }
}

Write-Host "Done."
