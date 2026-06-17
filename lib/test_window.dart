import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'dart:io';

void main() async {
  print('Starting window tracker test...');
  for (int i = 0; i < 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) {
      print('No active window');
      continue;
    }
    
    final length = GetWindowTextLength(hwnd);
    if (length == 0) {
      print('Window has no title');
      continue;
    }
    
    final buffer = wsalloc(length + 1);
    GetWindowText(hwnd, buffer, length + 1);
    final title = buffer.toDartString();
    free(buffer);
    print('Active Window Title: \$title'); // Escaped incorrectly again? Let's use concatenation:
    print('Active Window Title: ' + title);
  }
}
