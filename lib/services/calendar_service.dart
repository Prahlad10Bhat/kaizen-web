import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';

class CalendarService {
  static Future<Map<String, dynamic>?> importIcs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );

    if (result != null && result.files.single.path != null) {
      final filename = result.files.single.name.replaceAll('.ics', '');
      final calendarId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
      
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      final tasks = _parseIcs(content, calendarId);
      
      return {
        'id': calendarId,
        'name': filename,
        'tasks': tasks,
      };
    }
    return null;
  }

  static List<Task> _parseIcs(String content, String calendarId) {
    List<Task> tasks = [];
    final eventRegex = RegExp(r'BEGIN:VEVENT([\s\S]*?)END:VEVENT');
    final matches = eventRegex.allMatches(content);

    for (var match in matches) {
      String eventBody = match.group(1)!;
      String summary = _getIcsValue(eventBody, 'SUMMARY') ?? 'Imported Event';
      String description = _getIcsValue(eventBody, 'DESCRIPTION') ?? '';
      String dtStart = _getIcsValue(eventBody, 'DTSTART') ?? '';
      
      DateTime? dueDate;
      if (dtStart.isNotEmpty) {
        try {
          // Basic ICS date format: YYYYMMDDTHHMMSSZ
          String dateStr = dtStart.replaceAll('VALUE=DATE:', '').split(':').last;
          if (dateStr.length >= 8) {
             dueDate = DateTime.parse(
              "${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}"
            );
          }
        } catch (e) {
          print('Error parsing ICS date: $dtStart');
        }
      }

      tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString() + tasks.length.toString(),
        title: summary,
        description: description,
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        dueDate: dueDate,
        calendarId: calendarId,
        assignees: ['https://randomuser.me/api/portraits/men/46.jpg'], // Default import avatar
      ));
    }
    return tasks;
  }

  static String? _getIcsValue(String body, String key) {
    final lines = body.split('\n');
    for (var line in lines) {
      if (line.startsWith('$key:')) {
        return line.substring(key.length + 1).trim();
      }
    }
    return null;
  }

  static Future<bool> exportIcs(List<Task> tasks) async {
    String icsContent = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Kaizen//NONSGML v1.0//EN\n";
    
    for (var task in tasks) {
      if (task.dueDate == null) continue;
      
      String stamp = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(DateTime.now().toUtc());
      String start = DateFormat("yyyyMMdd'T'HHmmss'Z'").format(task.dueDate!.toUtc());
      
      icsContent += "BEGIN:VEVENT\n";
      icsContent += "UID:${task.id}@kaizen.app\n";
      icsContent += "DTSTAMP:$stamp\n";
      icsContent += "DTSTART:$start\n";
      icsContent += "SUMMARY:${task.title}\n";
      icsContent += "DESCRIPTION:${task.description}\n";
      icsContent += "END:VEVENT\n";
    }
    
    icsContent += "END:VCALENDAR";

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Calendar Export',
      fileName: 'kaizen_calendar.ics',
      type: FileType.custom,
      allowedExtensions: ['ics'],
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(icsContent);
      return true;
    }
    return false;
  }
}
