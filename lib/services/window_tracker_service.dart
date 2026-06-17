import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_tracker_provider.dart';

class WindowTrackerService {
  Timer? _timer;
  final Ref _ref;

  WindowTrackerService(this._ref);

  void start() {
    if (!Platform.isWindows) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkActiveWindow();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _checkActiveWindow() {
    final windowInfo = _getActiveWindowInfo();
    if (windowInfo == null || windowInfo.processName.isEmpty) {
      _ref.read(appTrackerProvider.notifier).setActiveAppAndIncrement(null, windowTitle: null);
      return;
    }

    // Call the new method on AppTrackerNotifier that handles auto-registration
    _ref.read(appTrackerProvider.notifier).autoDetectAndSetActiveApp(
      processName: windowInfo.processName,
      windowTitle: windowInfo.title,
      processPath: windowInfo.processPath,
    );
  }

  ({String title, String processName, String processPath})? _getActiveWindowInfo() {
    if (!Platform.isWindows) return null;
    
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return null;
      
      // Get Window Title
      String title = '';
      final length = GetWindowTextLength(hwnd);
      if (length > 0) {
        final titleBuffer = wsalloc(length + 1);
        GetWindowText(hwnd, titleBuffer, length + 1);
        title = titleBuffer.toDartString();
        free(titleBuffer);
      }
      
      // Get Process Name
      String processName = '';
      String processPath = '';
      final pPid = calloc<Uint32>();
      GetWindowThreadProcessId(hwnd, pPid);
      final pid = pPid.value;
      free(pPid);

      // PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
      final hProcess = OpenProcess(0x1000, FALSE, pid);
      if (hProcess != 0) {
        final buffer = wsalloc(MAX_PATH);
        final pSize = calloc<Uint32>()..value = MAX_PATH;
        
        final result = QueryFullProcessImageName(hProcess, 0, buffer, pSize);
        if (result != 0) {
          final fullPath = buffer.toDartString();
          processPath = fullPath;
          processName = fullPath.split('\\').last; // e.g. "chrome.exe"
        }
        
        free(buffer);
        free(pSize);
        CloseHandle(hProcess);
      }
      
      return (title: title, processName: processName, processPath: processPath);
    } catch (e) {
      return null;
    }
  }
}

final windowTrackerServiceProvider = Provider<WindowTrackerService>((ref) {
  final service = WindowTrackerService(ref);
  return service;
});
