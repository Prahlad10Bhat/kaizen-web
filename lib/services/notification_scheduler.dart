import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import '../providers/task_provider.dart';

class NotificationScheduler {
  final Ref ref;
  Timer? _timer;
  final Set<String> _notifiedTaskIds = {};

  NotificationScheduler(this.ref) {
    _startScheduler();
  }

  void _startScheduler() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkDueTasks();
    });
    // Run an initial check immediately
    _checkDueTasks();
  }

  void _checkDueTasks() {
    final tasks = ref.read(taskProvider);
    final now = DateTime.now();

    for (final task in tasks) {
      if (task.dueDate != null) {
        // If the task is due within the next minute and hasn't been notified yet
        final diff = task.dueDate!.difference(now);
        
        // Notify if due in the next minute, or up to 5 minutes overdue (if app was closed)
        if (diff.inMinutes <= 1 && diff.inMinutes >= -5) {
          if (!_notifiedTaskIds.contains(task.id)) {
            _showNotification(task.title, task.description ?? 'Scheduled task/event is due');
            _notifiedTaskIds.add(task.id);
          }
        }
      }
    }
  }

  void _showNotification(String title, String body) {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    notification.show();
  }

  void dispose() {
    _timer?.cancel();
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = NotificationScheduler(ref);
  ref.onDispose(() => scheduler.dispose());
  return scheduler;
});
