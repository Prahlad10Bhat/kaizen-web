import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationMessage {
  final String message;
  final bool isError;
  final DateTime timestamp;

  NotificationMessage({
    required this.message,
    this.isError = false,
  }) : timestamp = DateTime.now();
}

class NotificationNotifier extends Notifier<NotificationMessage?> {
  @override
  NotificationMessage? build() => null;

  void show(String message, {bool isError = false}) {
    state = NotificationMessage(message: message, isError: isError);
  }

  void clear() {
    state = null;
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationMessage?>(() {
  return NotificationNotifier();
});
