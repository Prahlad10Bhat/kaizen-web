import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../providers/task_provider.dart';
import '../models/calendar.dart';
import '../providers/calendar_provider.dart';
import 'custom_time_picker.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class UniversalTaskDialog extends ConsumerStatefulWidget {
  final Task? initialTask;
  final bool isEventContext;
  final TaskStatus? defaultStatus;
  final DateTime? initialDate;

  const UniversalTaskDialog({
    super.key, 
    this.initialTask, 
    this.isEventContext = false,
    this.defaultStatus,
    this.initialDate,
  });

  @override
  ConsumerState<UniversalTaskDialog> createState() => _UniversalTaskDialogState();
}

class _UniversalTaskDialogState extends ConsumerState<UniversalTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late TaskPriority _priority;
  late TaskStatus _status;
  late String _selectedCalendarId;
  late bool _isRecurring;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initialTask?.description ?? '');
    
    _selectedDate = widget.initialTask?.dueDate ?? widget.initialDate ?? DateTime.now();
    _selectedTime = widget.initialTask?.dueDate != null 
        ? TimeOfDay.fromDateTime(widget.initialTask!.dueDate!) 
        : TimeOfDay.now();
        
    _priority = widget.initialTask?.priority ?? TaskPriority.medium;
    _status = widget.initialTask?.status ?? widget.defaultStatus ?? TaskStatus.todo;
    
    if (widget.initialTask?.calendarId != null) {
      _selectedCalendarId = widget.initialTask!.calendarId!;
    } else {
      final activeCalendarId = ref.read(activeCalendarProvider);
      final calendars = ref.read(calendarProvider);
      final activeCal = calendars.firstWhere((c) => c.id == activeCalendarId, orElse: () => calendars.first);
      
      if (widget.isEventContext && activeCal.isTaskCalendar) {
        final firstEventCal = calendars.firstWhere((c) => !c.isTaskCalendar, orElse: () => activeCal);
        _selectedCalendarId = firstEventCal.id;
      } else if (!widget.isEventContext && !activeCal.isTaskCalendar) {
        final firstTaskCal = calendars.firstWhere((c) => c.isTaskCalendar, orElse: () => activeCal);
        _selectedCalendarId = firstTaskCal.id;
      } else {
        _selectedCalendarId = activeCalendarId;
      }
    }
    
    _isRecurring = widget.initialTask?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    
    // Find selected calendar type dynamically
    final selectedCalendar = calendars.firstWhere(
      (c) => c.id == _selectedCalendarId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );
    final isTaskCalendar = selectedCalendar.isTaskCalendar;

    // Filter calendars to only show ones matching the current context
    final filteredCalendars = calendars.where((c) => c.isTaskCalendar != widget.isEventContext).toList();

    return Dialog(
      backgroundColor: theme.cardColor,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [theme.primaryColor.withValues(alpha: 0.05), Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing 
                        ? (isTaskCalendar ? 'Edit Task' : 'Edit Event') 
                        : (isTaskCalendar ? 'Create Task' : 'Create Event'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color, fontFamily: 'Sora'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodySmall?.color),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Gap(24),
              _buildLabel(context, isTaskCalendar ? 'Task Title' : 'Event Title'),
              const Gap(8),
              _buildTextField(context, controller: _titleController, hint: 'Enter title...', autofocus: true),
              const Gap(16),
              _buildLabel(context, 'Description (Optional)'),
              const Gap(8),
              _buildTextField(context, controller: _descriptionController, hint: 'Enter description...', maxLines: 3),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Calendar'),
                        const Gap(8),
                        _buildCalendarPicker(context, filteredCalendars.isNotEmpty ? filteredCalendars : calendars),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Priority'),
                        const Gap(8),
                        _buildPriorityPicker(context, appColors),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Date (Optional)'),
                        const Gap(8),
                        _buildDatePicker(context),
                      ],
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Start time'),
                        const Gap(8),
                        _buildTimePicker(context),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(20),
              if (!isTaskCalendar)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.repeat, size: 16, color: theme.textTheme.bodySmall?.color),
                                const Gap(12),
                                Text('Recurring Event', style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Switch(
                              value: _isRecurring,
                              activeColor: theme.primaryColor,
                              onChanged: (v) => setState(() => _isRecurring = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (!isTaskCalendar) const Gap(32),
              if (isTaskCalendar) const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing 
                        ? 'Save Changes' 
                        : (isTaskCalendar ? 'Create Task' : 'Create Event'), 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_titleController.text.isEmpty) return;

    DateTime? finalDueDate;
    if (_selectedDate != null) {
      finalDueDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime?.hour ?? 0,
        _selectedTime?.minute ?? 0,
      );
    }

    if (widget.initialTask != null) {
      final updatedTask = widget.initialTask!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        priority: _priority,
        status: _status,
        dueDate: finalDueDate,
        calendarId: _selectedCalendarId,
        isRecurring: _isRecurring,
      );
      ref.read(taskProvider.notifier).updateTask(updatedTask);
    } else {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        status: _status,
        priority: _priority,
        dueDate: finalDueDate,
        calendarId: _selectedCalendarId,
        isRecurring: _isRecurring,
      );
      ref.read(taskProvider.notifier).addTask(newTask);
    }
    
    Navigator.pop(context);
  }

  Widget _buildCalendarPicker(BuildContext context, List<Calendar> calendars) {
    final theme = Theme.of(context);
    final selectedCalendar = calendars.firstWhere(
      (c) => c.id == _selectedCalendarId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );
    
    return PopupMenuButton<String>(
      initialValue: _selectedCalendarId,
      tooltip: '',
      color: theme.cardColor,
      elevation: 8,
      position: PopupMenuPosition.under,
      onSelected: (v) {
        setState(() {
          _selectedCalendarId = v;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        height: 48,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(selectedCalendar.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                selectedCalendar.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedCalendar.isTaskCalendar ? 'TASK' : 'EVENT',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const Gap(8),
            Icon(LucideIcons.chevronDown, size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
      itemBuilder: (context) => calendars.map((c) => PopupMenuItem<String>(
        value: c.id,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(c.colorValue),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                c.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                c.isTaskCalendar ? 'TASK' : 'EVENT',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPriorityPicker(BuildContext context, AppColorsExtension appColors) {
    final theme = Theme.of(context);
    final pColor = _priority == TaskPriority.high ? appColors.highPriority : (_priority == TaskPriority.medium ? appColors.mediumPriority : appColors.lowPriority);

    return PopupMenuButton<TaskPriority>(
      initialValue: _priority,
      tooltip: '',
      color: theme.cardColor,
      elevation: 8,
      position: PopupMenuPosition.under,
      onSelected: (v) => setState(() => _priority = v),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        height: 48,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
            ),
            const Gap(8),
            Expanded(
              child: Text(_priority.name.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            ),
            const Gap(8),
            Icon(LucideIcons.chevronDown, size: 16, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
      itemBuilder: (context) => TaskPriority.values.map((p) => PopupMenuItem<TaskPriority>(
        value: p,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: p == TaskPriority.high ? appColors.highPriority : (p == TaskPriority.medium ? appColors.mediumPriority : appColors.lowPriority),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Text(p.name.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          ],
        ),
      )).toList(),
    );
  }


  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (d != null) {
          setState(() {
            _selectedDate = d;
            _selectedTime ??= TimeOfDay.now();
          });
        }
      },
      child: _buildInputBox(
        context, 
        _selectedDate != null ? DateFormat('dd MMM yyyy').format(_selectedDate!) : 'No date set', 
        icon: LucideIcons.calendar,
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        if (_selectedDate == null) {
          SnackbarUtils.showCustomSnackBar(context, 'Please select a date first', isError: true);
          return;
        }
        final t = await showCustomTimePicker(
          context: context, 
          initialTime: _selectedTime ?? TimeOfDay.now(),
        );
        if (t != null) setState(() => _selectedTime = t);
      },
      child: _buildInputBox(
        context, 
        _selectedTime != null ? _selectedTime!.format(context) : '--:--', 
        icon: LucideIcons.clock,
        disabled: _selectedDate == null,
      ),
    );
  }

  Widget _buildTextField(BuildContext context, {required TextEditingController controller, required String hint, int maxLines = 1, bool autofocus = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLines: maxLines,
        inputFormatters: maxLines == 1 ? [FilteringTextInputFormatter.deny(RegExp(r'\n'))] : [],
        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildInputBox(BuildContext context, String text, {required IconData icon, bool disabled = false}) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: disabled ? theme.disabledColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: disabled ? theme.disabledColor : theme.textTheme.bodySmall?.color),
          const Gap(12),
          Text(text, style: TextStyle(fontSize: 14, color: disabled ? theme.disabledColor : theme.textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold),
    );
  }
}
