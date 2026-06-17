import 'package:flutter_riverpod/flutter_riverpod.dart';

class SidebarNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Default to expanded
  }

  void toggle() {
    state = !state;
  }

  void setExpanded(bool value) {
    state = value;
  }
}

final sidebarProvider = NotifierProvider<SidebarNotifier, bool>(() {
  return SidebarNotifier();
});
