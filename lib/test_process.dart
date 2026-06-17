import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'dart:io';

void main() {
  print('Starting window tracker test...');
  for (int i = 0; i < 5; i++) {
    sleep(Duration(seconds: 2));
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) {
      print('No active window');
      continue;
    }

    final pPid = calloc<Uint32>();
    GetWindowThreadProcessId(hwnd, pPid);
    final pid = pPid.value;
    free(pPid);

    // PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    final hProcess = OpenProcess(0x1000, FALSE, pid);
    if (hProcess == 0) {
      print('Could not open process $pid');
      continue;
    }

    final buffer = wsalloc(MAX_PATH);
    final pSize = calloc<Uint32>()..value = MAX_PATH;
    
    final result = QueryFullProcessImageName(hProcess, 0, buffer, pSize);
    if (result != 0) {
      final fullPath = buffer.toDartString();
      final exeName = fullPath.split('\\').last;
      print('Active Process: $exeName (PID: $pid) Path: $fullPath');
    } else {
      print('Failed to get process image name for PID $pid');
    }

    free(buffer);
    free(pSize);
    CloseHandle(hProcess);
  }
}
