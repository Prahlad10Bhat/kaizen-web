import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/task.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/task_provider.dart';
import '../../../services/calendar_service.dart';
import '../../../widgets/universal_task_dialog.dart';
import '../../widgets/avatar_stack.dart';
import '../../providers/sidebar_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../../models/calendar.dart';
import '../../../providers/calendar_provider.dart';
import '../../../providers/settings_provider.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class AppCalendarPage extends ConsumerStatefulWidget {
  const AppCalendarPage({super.key});

  @override
  ConsumerState<AppCalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<AppCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  ThemeData get theme => Theme.of(context);
  AppColorsExtension get appColors => theme.extension<AppColorsExtension>()!;
  String _selectedView = 'Month';
  String _previousView = 'Month';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isCalendarsSidebarExpanded = true;

  static const List<int> _calendarPresetColors = [
    0xFF6C63FF, // Indigo/Blue-Purple
    0xFF81C784, // Soft Green
    0xFFFFB74D, // Soft Orange/Amber
    0xFFE57373, // Soft Red
    0xFF4FC3F7, // Light Blue
    0xFFBA68C8, // Lavender/Purple
    0xFFFF8A65, // Coral
    0xFFA1887F, // Warm Grey/Brown
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final isSidebarExpanded = ref.watch(sidebarProvider);
    final allTasks = ref.watch(taskProvider);
    final calendars = ref.watch(calendarProvider);
    
    // Set of visible calendar IDs
    final visibleCalendarIds = calendars.where((c) => c.isVisible).map((c) => c.id).toSet();
    
    // Filter out tasks that belong to hidden calendars
    final visibleTasks = allTasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
      return visibleCalendarIds.contains(cId);
    }).toList();
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;
          final isUltraCompact = constraints.maxWidth < 650;
          
          final double horizontalPadding = isUltraCompact 
              ? (isSidebarExpanded ? 8.0 : 4.0) 
              : 24.0;
          
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(isCompact, isUltraCompact),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isUltraCompact ? 8.0 : 24.0,
                        ),
                        child: (_selectedView == 'List')
                          ? _buildListView(visibleTasks)
                          : _buildCalendarGrid(isUltraCompact, isSidebarExpanded, visibleTasks),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) _buildRightSidebar(visibleTasks),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool screenIsCompact, bool screenIsUltraCompact) {
    return LayoutBuilder(
      builder: (context, headerConstraints) {
        final headerWidth = headerConstraints.maxWidth;
        final isMegaCompact = headerWidth < 350;
        final isUltraCompact = headerWidth < 580;
        final isCompact = headerWidth < 850;
        
        return Container(
          padding: EdgeInsets.only(
            left: isUltraCompact ? 12 : (isCompact ? 20 : 32),
            right: isUltraCompact ? 12 : (isCompact ? 20 : 32),
            top: 64,
            bottom: isUltraCompact ? 16 : 24,
          ),
          child: Row(
            children: [
              if (!isUltraCompact) ...[
                SizedBox(
                  width: isCompact ? 160 : 220,
                  child: Text(
                    DateFormat('MMMM yyyy').format(_focusedDay),
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const Gap(16),
                IconButton(
                  onPressed: () => _navigateMonth(-1),
                  icon: const Icon(LucideIcons.chevronLeft, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const Gap(8),
                IconButton(
                  onPressed: () => _navigateMonth(1),
                  icon: const Icon(LucideIcons.chevronRight, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
                const Gap(16),
              ],
              if (!isCompact) ...[
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final isCurrentlyToday = DateUtils.isSameDay(_selectedDay, now) && 
                        _focusedDay.year == now.year && _focusedDay.month == now.month;
                    
                    if (!isCurrentlyToday) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime.now();
                            _selectedDay = DateTime.now();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      );
                    }
                    
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                        side: BorderSide(color: theme.dividerColor),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  }
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _showCreateItemDialog(),
                  icon: Icon(LucideIcons.plus, color: appColors.calendarAccent, size: isUltraCompact ? 18 : 24),
                  style: IconButton.styleFrom(
                    backgroundColor: appColors.calendarAccent.withValues(alpha: 0.1),
                    minimumSize: isUltraCompact ? const Size(36, 36) : const Size(48, 48),
                  ),
                ),
                const Gap(8),
                Builder(
                  builder: (context) {
                    final now = DateTime.now();
                    final isCurrentlyToday = DateUtils.isSameDay(_selectedDay, now) && 
                        _focusedDay.year == now.year && _focusedDay.month == now.month;
                    
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _focusedDay = DateTime.now();
                          _selectedDay = DateTime.now();
                        });
                      },
                      icon: Icon(LucideIcons.calendar, color: isCurrentlyToday ? theme.textTheme.bodyLarge?.color : theme.colorScheme.onPrimary, size: isUltraCompact ? 20 : 26),
                      style: IconButton.styleFrom(
                        backgroundColor: isCurrentlyToday ? theme.cardColor : theme.primaryColor,
                        minimumSize: isUltraCompact ? const Size(40, 40) : const Size(52, 52),
                      ),
                    );
                  }
                ),
              ],
              if (!isMegaCompact && !_isSearching) ...[
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: (isCompact ? ['M', 'L'] : ['Month', 'List']).map((view) {
                      final fullName = view == 'M' ? 'Month' : view == 'L' ? 'List' : view;
                      final isSelected = _selectedView == fullName;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                          onTap: () => setState(() => _selectedView = fullName),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 10 : (isCompact ? 12 : 16), vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? appColors.calendarGrid : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            view,
                            style: TextStyle(
                              color: isSelected ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
                              fontSize: isUltraCompact ? 11 : 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      )),
                    );
                  }).toList(),
                  ),
                ),
              ],
               if (!isUltraCompact) ...[
                const Gap(24),
                if (!isCompact) ...[
                  if (_isSearching)
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                            prefixIcon: Icon(LucideIcons.search, size: 18, color: theme.primaryColor),
                            suffixIcon: IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                  _selectedView = _previousView;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (v) {
                            setState(() {
                              if (v.isNotEmpty && _selectedView != 'List') {
                                _previousView = _selectedView;
                                _selectedView = 'List';
                              } else if (v.isEmpty && _selectedView == 'List' && _previousView != 'List') {
                                _selectedView = _previousView;
                              }
                            });
                          },
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => setState(() => _isSearching = true),
                      icon: Icon(LucideIcons.search, color: theme.textTheme.bodySmall?.color, size: 20),
                    ),
                  const Gap(8),
                  Consumer(
                    builder: (context, ref, child) {
                      final notificationsEnabled = ref.watch(settingsProvider).notificationsEnabled;
                      return IconButton(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setNotifications(!notificationsEnabled);
                        },
                        icon: Icon(
                          notificationsEnabled ? Icons.notifications_active : LucideIcons.bell,
                          color: theme.textTheme.bodySmall?.color,
                          size: 20,
                        ),
                        tooltip: notificationsEnabled ? 'Disable Event Notifications' : 'Enable Event Notifications',
                      );
                    },
                  ),
                  const Gap(20),
                ],
                IconButton(
                  onPressed: _showCalendarManagementDialog,
                  icon: Icon(LucideIcons.calendarRange, color: theme.textTheme.bodySmall?.color, size: 20),
                  tooltip: 'Calendar Management',
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  void _showCalendarManagementDialog() {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.calendarRange, color: theme.primaryColor, size: 24),
            ),
            const Gap(16),
            Text(
              'Calendar Management',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sora',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Consumer(
            builder: (context, ref, child) {
              final calendars = ref.watch(calendarProvider);
              final activeCalendarId = ref.watch(activeCalendarProvider);

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Calendars',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: calendars.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final c = calendars[index];
                          final isVisible = c.isVisible;
                          final isActive = c.id == activeCalendarId;

                          return InkWell(
                            onTap: () {
                              ref.read(activeCalendarProvider.notifier).state = c.id;
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isActive ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
                                border: Border(
                                  bottom: index == calendars.length - 1
                                      ? BorderSide.none
                                      : BorderSide(color: theme.dividerColor),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isVisible,
                                    onChanged: (_) => ref.read(calendarProvider.notifier).toggleVisibility(c.id),
                                    activeColor: Color(c.colorValue),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const Gap(6),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(c.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Gap(10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          c.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                            color: isVisible 
                                                ? theme.textTheme.bodyLarge?.color 
                                                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Gap(2),
                                        Row(
                                          children: [
                                            Icon(
                                              c.isTaskCalendar ? LucideIcons.checkSquare : LucideIcons.calendarDays,
                                              size: 9,
                                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                            ),
                                            const Gap(4),
                                            Text(
                                              c.isTaskCalendar ? 'Tasks' : 'Events',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            if (c.id.startsWith('imported_')) ...[
                                              const Gap(8),
                                              Icon(
                                                LucideIcons.downloadCloud,
                                                size: 9,
                                                color: theme.primaryColor.withValues(alpha: 0.7),
                                              ),
                                              const Gap(4),
                                              Text(
                                                'Imported ICS',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: theme.primaryColor.withValues(alpha: 0.7),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit2, size: 14),
                                    onPressed: () => _showEditCalendarDialog(c),
                                    tooltip: 'Edit Calendar',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (c.id != 'default_tasks') ...[
                                    const Gap(12),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                      onPressed: () => _confirmDeleteCalendar(c),
                                      tooltip: 'Delete Calendar',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(12),
                    ElevatedButton.icon(
                      onPressed: _showAddCalendarDialog,
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('Add Custom Calendar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                        foregroundColor: theme.primaryColor,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                    const Gap(24),
                    Divider(color: theme.dividerColor),
                    const Gap(16),
                    Text(
                      'ICS Integrations',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.download,
                            label: 'Import .ics',
                            onTap: () {
                              _showImportTypeSelectionDialog(context, ref, calendars);
                            },
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.upload,
                            label: 'Export .ics',
                            onTap: () async {
                              final allTasks = ref.read(taskProvider);
                              final success = await CalendarService.exportIcs(allTasks);
                              if (success) {
                                SnackbarUtils.showCustomSnackBar(context, 'Calendar exported successfully');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(24),
                    Divider(color: theme.dividerColor),
                    const Gap(16),
                    Text(
                      'External Calendar Sync',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Gap(12),
                    _buildImportOption(
                      icon: LucideIcons.globe,
                      title: 'Sync with Google Calendar',
                      subtitle: 'Automatically import and sync your events.',
                      onTap: () {},
                    ),
                    const Gap(12),
                    _buildImportOption(
                      icon: LucideIcons.mail,
                      title: 'Sync with Outlook',
                      subtitle: 'Connect your Microsoft account.',
                      onTap: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.textTheme.bodySmall?.color, size: 24),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: theme.textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showImportTypeSelectionDialog(BuildContext context, WidgetRef ref, List<Calendar> calendars) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          title: Text('Import ICS as...', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.checkSquare, color: theme.primaryColor),
                title: Text('Tasks', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                subtitle: Text('Import items as tasks with checkboxes', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                onTap: () {
                  Navigator.pop(context);
                  _handleImportIcs(context, ref, calendars, isTaskCalendar: true);
                },
                hoverColor: theme.primaryColor.withValues(alpha: 0.05),
              ),
              const Gap(8),
              ListTile(
                leading: Icon(LucideIcons.calendarDays, color: theme.primaryColor),
                title: Text('Events', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                subtitle: Text('Import items as calendar events', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                onTap: () {
                  Navigator.pop(context);
                  _handleImportIcs(context, ref, calendars, isTaskCalendar: false);
                },
                hoverColor: theme.primaryColor.withValues(alpha: 0.05),
              ),
            ],
          ),
        );
      }
    );
  }

  Future<void> _handleImportIcs(BuildContext context, WidgetRef ref, List<Calendar> calendars, {required bool isTaskCalendar}) async {
    final result = await CalendarService.importIcs();
    if (result != null) {
      final String calendarId = result['id'] as String;
      final String calendarName = result['name'] as String;
      final List<Task> tasks = List<Task>.from(result['tasks'] as List);

      final colorValue = _calendarPresetColors[calendars.length % _calendarPresetColors.length];

      final newCalendar = Calendar(
        id: calendarId,
        name: calendarName,
        colorValue: colorValue,
        isTaskCalendar: isTaskCalendar,
        isVisible: true,
      );

      ref.read(calendarProvider.notifier).addCalendar(newCalendar);
      ref.read(taskProvider.notifier).addTasks(tasks);

      if (context.mounted) {
        SnackbarUtils.showCustomSnackBar(context, 'Imported calendar "$calendarName" with ${tasks.length} items');
      }
    }
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.textTheme.bodyLarge?.color),
            const Gap(8),
            Text(label, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(bool isUltraCompact, bool isSidebarExpanded, List<Task> allTasks) {
    final calendars = ref.watch(calendarProvider);
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final daysOfWeek = isUltraCompact ? ['S', 'M', 'T', 'W', 'T', 'F', 'S'] : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final double aspectRatio = isUltraCompact ? (isSidebarExpanded ? 1.0 : 0.85) : 1.2;

    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final prevMonthLastDay = DateTime(_focusedDay.year, _focusedDay.month, 0);
    
    // Filter tasks based on search
    final filteredTasks = _searchController.text.isEmpty 
        ? allTasks 
        : allTasks.where((t) => t.title.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    
    final daysInMonth = lastDayOfMonth.day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday
    
    return Column(
      children: [
        Row(
          children: daysOfWeek.map((day) => Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  day,
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color, 
                    fontSize: isUltraCompact ? 10 : 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: isUltraCompact ? 4 : 8,
              mainAxisSpacing: isUltraCompact ? 4 : 8,
            ),
            itemCount: 42, // 6 weeks to ensure all months fit
            itemBuilder: (context, index) {
              DateTime day;
              bool isCurrentMonth = true;
              
              if (index < firstDayWeekday) {
                day = DateTime(_focusedDay.year, _focusedDay.month - 1, prevMonthLastDay.day - (firstDayWeekday - index - 1));
                isCurrentMonth = false;
              } else if (index < firstDayWeekday + daysInMonth) {
                day = DateTime(_focusedDay.year, _focusedDay.month, index - firstDayWeekday + 1);
              } else {
                day = DateTime(_focusedDay.year, _focusedDay.month + 1, index - (firstDayWeekday + daysInMonth) + 1);
                isCurrentMonth = false;
              }
              
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final isSelected = DateUtils.isSameDay(day, _selectedDay);
              
              final dayTasks = filteredTasks.where((t) => 
                t.dueDate != null && DateUtils.isSameDay(t.dueDate!, day)
              ).toList();
              
              int taskCount = 0;
              int eventCount = 0;
              Color? singleColor;
              for (final t in dayTasks) {
                final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
                final cal = calendars.firstWhere(
                  (c) => c.id == cId,
                  orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
                );
                if (cal.isTaskCalendar) {
                  taskCount++;
                } else {
                  eventCount++;
                }
                
                final calColor = Color(cal.colorValue);
                if (singleColor == null) {
                  singleColor = calColor;
                } else if (singleColor != calColor) {
                  singleColor = theme.primaryColor;
                }
              }
              final displayColor = singleColor ?? theme.primaryColor;
              
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isToday ? theme.primaryColor.withValues(alpha: 0.15) : appColors.calendarAccent.withValues(alpha: 0.15))
                          : (isCurrentMonth ? appColors.calendarSurface : appColors.calendarSurface.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday 
                            ? (isSelected ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.4))
                            : (isSelected ? appColors.calendarAccent.withValues(alpha: 0.5) : Colors.transparent),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    padding: EdgeInsets.all(isUltraCompact ? 4 : 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday 
                                ? (isSelected ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.5))
                                : (isSelected ? appColors.calendarAccent : (isCurrentMonth ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color)),
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: isUltraCompact ? 10 : 12,
                          ),
                        ),
                        const Gap(4),
                        if (dayTasks.isNotEmpty)
                          Tooltip(
                            message: dayTasks.map((t) {
                              final calendars = ref.read(calendarProvider);
                              final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
                              final parentCalendar = calendars.firstWhere(
                                (c) => c.id == cId,
                                orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
                              );
                              return '• [${parentCalendar.name}] ${t.title} (${DateFormat('HH:mm').format(t.dueDate!)})';
                            }).join('\n'),
                            textStyle: TextStyle(fontSize: 12, color: theme.textTheme.bodyLarge?.color),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 4 : 6, vertical: isUltraCompact ? 2 : 4),
                              decoration: BoxDecoration(
                                color: Color.alphaBlend(displayColor.withValues(alpha: 0.15), appColors.calendarSurface),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isUltraCompact) ...[
                                    Text(
                                      [
                                        if (taskCount > 0) '$taskCount Task${taskCount > 1 ? 's' : ''}',
                                        if (eventCount > 0) '$eventCount Event${eventCount > 1 ? 's' : ''}'
                                      ].join(', '),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: displayColor,
                                      ),
                                    ),
                                    const Gap(4),
                                  ],
                                  ...dayTasks.take(4).map((t) {
                                    final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
                                    final cal = calendars.firstWhere(
                                      (c) => c.id == cId,
                                      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
                                    );
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: Color(cal.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildListView(List<Task> allTasks) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    final filteredTasks = allTasks.where((t) {
      final matchesSearch = _searchController.text.isEmpty || 
          t.title.toLowerCase().contains(_searchController.text.toLowerCase());
          
      if (!matchesSearch || t.dueDate == null) return false;
      
      if (t.isRecurring) return true;
      
      final eventDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return !eventDate.isBefore(startOfToday);
    }).toList();

    final sortedTasks = [...filteredTasks];
    sortedTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      
    if (sortedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, size: 48, color: theme.textTheme.bodySmall?.color),
            const Gap(16),
            Text(
              _searchController.text.isNotEmpty ? 'No Matches Found' : 'No scheduled tasks', 
              style: TextStyle(color: theme.textTheme.bodySmall?.color),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final cId = (task.calendarId == null || task.calendarId == '' || task.calendarId == 'null') ? 'default_tasks' : task.calendarId!;
        final parentCal = calendars.firstWhere(
          (c) => c.id == cId,
          orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
        );
        final calendarColor = Color(parentCal.colorValue);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = task.dueDate!;
              _focusedDay = task.dueDate!;
              _isSearching = false;
              _searchController.clear();
              _selectedView = _previousView;
            });
          },
          onSecondaryTap: () => _showEditItemDialog(task),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appColors.calendarSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: calendarColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('MMM').format(task.dueDate!), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                      Text(DateFormat('dd').format(task.dueDate!), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    ],
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: theme.textTheme.bodySmall?.color),
                          const Gap(4),
                          Text(DateFormat('HH:mm').format(task.dueDate!), style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
                          const Gap(12),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: calendarColor, shape: BoxShape.circle),
                          ),
                          const Gap(6),
                          Text(
                            parentCal.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 16, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    switch (priority) {
      case TaskPriority.high: return appColors.highPriority;
      case TaskPriority.medium: return appColors.mediumPriority;
      case TaskPriority.low: return appColors.lowPriority;
    }
  }

  Widget _buildEventItem(String title, String time, Color color) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor, // Solid background to pop over selection
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: TextStyle(fontSize: 9, color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(List<Task> allTasks) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    final activeCalendarId = ref.watch(activeCalendarProvider);
    final activeCalendar = calendars.firstWhere(
      (c) => c.id == activeCalendarId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );

    final selectedDayTasks = allTasks.where((t) => 
      t.dueDate != null && DateUtils.isSameDay(t.dueDate!, _selectedDay)
    ).toList();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: appColors.calendarSurface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd MMM yyyy').format(_selectedDay),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(16),
          // _buildMiniCalendar(), // Retained for future use if needed
          // const Gap(32),
          _buildFocusWidget(selectedDayTasks),
          const Gap(32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks & Events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              MenuAnchor(
                builder: (context, controller, child) {
                  return ElevatedButton(
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text('+ New', style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w500, fontSize: 13)),
                  );
                },
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: Icon(LucideIcons.checkSquare, size: 16, color: theme.primaryColor),
                    child: const Text('New Task'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => UniversalTaskDialog(
                          isEventContext: false,
                          initialDate: _selectedDay,
                        ),
                      );
                    },
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.calendarDays, size: 16, color: Colors.blueAccent),
                    child: const Text('New Event'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => UniversalTaskDialog(
                          isEventContext: true,
                          initialDate: _selectedDay,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Gap(16),
          Expanded(
            child: selectedDayTasks.isEmpty 
              ? Center(child: Text('No scheduled items', style: TextStyle(color: theme.textTheme.bodySmall?.color)))
              : ListView.builder(
                  itemCount: selectedDayTasks.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final task = selectedDayTasks[index];
                    return _buildCheckItem(task);
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _navigateMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    });
  }

  Future<void> _handleDelete(BuildContext context, Task task, bool isTaskCalendar) async {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);
    
    if (!settings.askBeforeDelete) {
      ref.read(taskProvider.notifier).removeTask(task.id);
      SnackbarUtils.showCustomSnackBar(context, isTaskCalendar ? 'Task deleted' : 'Event deleted');
      return;
    }

    bool dontShowAgain = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.dialogTheme.backgroundColor,
            shape: theme.dialogTheme.shape,
            title: Text(isTaskCalendar ? 'Delete Task' : 'Delete Event', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this ${isTaskCalendar ? 'task' : 'event'}? This action cannot be undone.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const Gap(24),
                InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => setState(() => dontShowAgain = !dontShowAgain),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: dontShowAgain,
                          onChanged: (val) => setState(() => dontShowAgain = val ?? false),
                          activeColor: theme.primaryColor,
                          visualDensity: VisualDensity.compact,
                          toggleable: true,
                        ),
                        const Gap(8),
                        Text(
                          "Don't show me again",
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dontShowAgain) {
                    ref.read(settingsProvider.notifier).setAskBeforeDelete(false);
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      ref.read(taskProvider.notifier).removeTask(task.id);
      if (context.mounted) {
        SnackbarUtils.showCustomSnackBar(context, isTaskCalendar ? 'Task deleted' : 'Event deleted');
      }
    }
  }

  void _showCreateItemDialog() {
    final calendars = ref.read(calendarProvider);
    final activeCalendarId = ref.read(activeCalendarProvider);
    final activeCalendar = calendars.firstWhere(
      (c) => c.id == activeCalendarId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );

    showDialog(
      context: context,
      builder: (context) => UniversalTaskDialog(
        isEventContext: !activeCalendar.isTaskCalendar,
        initialDate: _selectedDay,
      ),
    );
  }

  void _showEditItemDialog(Task task) {
    final calendars = ref.read(calendarProvider);
    final cId = (task.calendarId == null || task.calendarId == '' || task.calendarId == 'null') ? 'default_tasks' : task.calendarId!;
    final parentCalendar = calendars.firstWhere(
      (c) => c.id == cId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );

    showDialog(
      context: context,
      builder: (context) => UniversalTaskDialog(initialTask: task, isEventContext: !parentCalendar.isTaskCalendar),
    );
  }

  Widget _buildMiniCalendar() {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Text(d, style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)))).toList(),
        ),
        const Gap(8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: 42,
          itemBuilder: (context, index) {
            DateTime day;
            bool isCurrentMonth = true;
            
            if (index < firstDayWeekday) {
              day = DateTime(_focusedDay.year, _focusedDay.month - 1, index - firstDayWeekday + 1);
              isCurrentMonth = false;
            } else if (index < firstDayWeekday + lastDayOfMonth.day) {
              day = DateTime(_focusedDay.year, _focusedDay.month, index - firstDayWeekday + 1);
            } else {
              day = DateTime(_focusedDay.year, _focusedDay.month + 1, index - (firstDayWeekday + lastDayOfMonth.day) + 1);
              isCurrentMonth = false;
            }

            final isToday = DateUtils.isSameDay(day, DateTime.now());
            final isSelected = DateUtils.isSameDay(day, _selectedDay);
            final isFocusedMonth = day.month == _focusedDay.month;

            return Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _selectedDay = day),
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: theme.primaryColor.withValues(alpha: 0.15),
                  splashColor: theme.primaryColor.withValues(alpha: 0.2),
                  highlightColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Ink(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isToday ? theme.primaryColor : appColors.calendarAccent) 
                          : (isToday 
                              ? theme.primaryColor.withValues(alpha: 0.2) 
                              : (isFocusedMonth ? theme.dividerColor.withValues(alpha: 0.05) : Colors.transparent)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.transparent
                            : (isToday 
                                ? theme.primaryColor.withValues(alpha: 0.5) 
                                : (isFocusedMonth ? theme.dividerColor.withValues(alpha: 0.3) : Colors.transparent)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected 
                              ? (isToday ? theme.colorScheme.onPrimary : Colors.black) 
                              : (isToday ? theme.primaryColor.withValues(alpha: 0.8) : (isFocusedMonth ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color)),
                          fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFocusWidget(List<Task> dayTasks) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);

    final taskItems = dayTasks.where((t) {
      final cId = (t.calendarId == null || t.calendarId == '' || t.calendarId == 'null') ? 'default_tasks' : t.calendarId!;
      final parentCal = calendars.firstWhere(
        (c) => c.id == cId,
        orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
      );
      return parentCal.isTaskCalendar;
    }).toList();

    final doneTasks = taskItems.where((t) => t.status == TaskStatus.done).length;
    final totalTasks = taskItems.length;
    final progress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Focus on work span', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Gap(16),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                    ),
                  ),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                ],
              ),
              const Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFocusStat(LucideIcons.briefcase, '$totalTasks total'),
                  const Gap(8),
                  _buildFocusStat(LucideIcons.checkCircle, '$doneTasks completed'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStat(IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.textTheme.bodySmall?.color),
        const Gap(8),
        Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
      ],
    );
  }

  Widget _buildCheckItem(Task task) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final calendars = ref.watch(calendarProvider);
    final isDone = task.status == TaskStatus.done;
    
    final cId = (task.calendarId == null || task.calendarId == '' || task.calendarId == 'null') ? 'default_tasks' : task.calendarId!;
    final parentCal = calendars.firstWhere(
      (c) => c.id == cId,
      orElse: () => calendars.firstWhere((c) => c.id == 'default_tasks', orElse: () => calendars.first),
    );
    final isTaskCalendar = parentCal.isTaskCalendar;
    final calendarColor = Color(parentCal.colorValue);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: isTaskCalendar 
                ? () {
                    final newStatus = isDone ? TaskStatus.todo : TaskStatus.done;
                    ref.read(taskProvider.notifier).updateTask(task.copyWith(status: newStatus));
                  }
                : null,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: Row(
                  children: [
                    if (isTaskCalendar) ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isDone ? theme.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone ? theme.primaryColor : theme.dividerColor,
                            width: 1.5,
                          ),
                        ),
                        child: isDone ? Icon(LucideIcons.check, size: 14, color: theme.colorScheme.onPrimary) : null,
                      ),
                    ] else ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: calendarColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: calendarColor, width: 1.5),
                        ),
                        child: Icon(LucideIcons.calendarDays, size: 10, color: calendarColor),
                      ),
                    ],
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDone ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.4) : theme.textTheme.bodyLarge?.color,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              decorationColor: theme.primaryColor.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isTaskCalendar ? 'Task' : 'Event',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => _showEditItemDialog(task),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Icon(
                LucideIcons.pencil, 
                size: 14, 
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)
              ),
            ),
          ),
          InkWell(
            onTap: () => _handleDelete(context, task, isTaskCalendar),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 16, 12),
              child: Icon(
                LucideIcons.trash2, 
                size: 14, 
                color: Colors.redAccent.withValues(alpha: 0.7)
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCalendarDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    int selectedColorValue = _calendarPresetColors[0];
    bool isTaskCalendar = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          title: Text('Create Calendar', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Work Meetings',
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                  ),
                ),
                const Gap(20),
                Text('Type', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isTaskCalendar = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isTaskCalendar ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
                            border: Border.all(color: isTaskCalendar ? theme.primaryColor : theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.checkSquare, color: isTaskCalendar ? theme.primaryColor : theme.textTheme.bodySmall?.color),
                              const Gap(8),
                              Text('Task Calendar', style: TextStyle(color: isTaskCalendar ? theme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Items act as tasks', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isTaskCalendar = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isTaskCalendar ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
                            border: Border.all(color: !isTaskCalendar ? theme.primaryColor : theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.calendarDays, color: !isTaskCalendar ? theme.primaryColor : theme.textTheme.bodySmall?.color),
                              const Gap(8),
                              Text('Normal Calendar', style: TextStyle(color: !isTaskCalendar ? theme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Items act as events', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                Text('Color', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _calendarPresetColors.map((colorVal) {
                    final isSelected = selectedColorValue == colorVal;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColorValue = colorVal),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: theme.textTheme.bodyLarge!.color!, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final newCalendar = Calendar(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  colorValue: selectedColorValue,
                  isTaskCalendar: isTaskCalendar,
                  isVisible: true,
                );
                ref.read(calendarProvider.notifier).addCalendar(newCalendar);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCalendarDialog(Calendar calendar) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: calendar.name);
    int selectedColorValue = calendar.colorValue;
    bool isTaskCalendar = calendar.isTaskCalendar;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          title: Text('Edit Calendar', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Work Meetings',
                    hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
                  ),
                ),
                const Gap(20),
                Text('Type', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isTaskCalendar = true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isTaskCalendar ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
                            border: Border.all(color: isTaskCalendar ? theme.primaryColor : theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.checkSquare, color: isTaskCalendar ? theme.primaryColor : theme.textTheme.bodySmall?.color),
                              const Gap(8),
                              Text('Task Calendar', style: TextStyle(color: isTaskCalendar ? theme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Items act as tasks', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => isTaskCalendar = false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isTaskCalendar ? theme.primaryColor.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
                            border: Border.all(color: !isTaskCalendar ? theme.primaryColor : theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(LucideIcons.calendarDays, color: !isTaskCalendar ? theme.primaryColor : theme.textTheme.bodySmall?.color),
                              const Gap(8),
                              Text('Normal Calendar', style: TextStyle(color: !isTaskCalendar ? theme.primaryColor : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Items act as events', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                Text('Color', style: TextStyle(color: theme.textTheme.bodySmall?.color, fontWeight: FontWeight.bold, fontSize: 12)),
                const Gap(8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _calendarPresetColors.map((colorVal) {
                    final isSelected = selectedColorValue == colorVal;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColorValue = colorVal),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: theme.textTheme.bodyLarge!.color!, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(LucideIcons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final updatedCalendar = calendar.copyWith(
                  name: nameController.text.trim(),
                  colorValue: selectedColorValue,
                  isTaskCalendar: isTaskCalendar,
                );
                ref.read(calendarProvider.notifier).updateCalendar(updatedCalendar);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCalendar(Calendar calendar) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        title: Text('Delete Calendar', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${calendar.name}"? This will also delete all events and tasks belonging to this calendar. This action cannot be undone.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(taskProvider.notifier).removeTasksByCalendarId(calendar.id);
              ref.read(calendarProvider.notifier).deleteCalendar(calendar.id);
              Navigator.pop(context);
              SnackbarUtils.showCustomSnackBar(context, 'Deleted calendar "${calendar.name}" and all associated items');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftCalendarsSidebar(bool isCompact, List<Calendar> calendars) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    final activeCalendarId = ref.watch(activeCalendarProvider);

    if (!_isCalendarsSidebarExpanded) {
      return Container(
        width: 60,
        decoration: BoxDecoration(
          color: appColors.calendarSurface,
          border: Border(right: BorderSide(color: theme.dividerColor)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            IconButton(
              onPressed: () => setState(() => _isCalendarsSidebarExpanded = true),
              icon: const Icon(LucideIcons.chevronRight, size: 18),
              tooltip: 'Expand panel',
            ),
            const Gap(16),
            IconButton(
              onPressed: _showAddCalendarDialog,
              icon: const Icon(LucideIcons.plus, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: theme.primaryColor,
              ),
              tooltip: 'Add calendar',
            ),
            const Gap(24),
            Expanded(
              child: ListView.builder(
                itemCount: calendars.length,
                itemBuilder: (context, index) {
                  final c = calendars[index];
                  final isVisible = c.isVisible;
                  final isActive = c.id == activeCalendarId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Tooltip(
                        message: '${c.name} (${c.isTaskCalendar ? 'Task' : 'Event'})',
                        child: InkWell(
                          onTap: () {
                            ref.read(activeCalendarProvider.notifier).state = c.id;
                          },
                          onDoubleTap: () => ref.read(calendarProvider.notifier).toggleVisibility(c.id),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(c.colorValue).withValues(alpha: isVisible ? 0.2 : 0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(c.colorValue).withValues(alpha: isVisible ? 0.8 : 0.2),
                                width: isActive ? 2.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                c.abbreviation,
                                style: TextStyle(
                                  color: Color(c.colorValue).withValues(alpha: isVisible ? 1.0 : 0.4),
                                  fontSize: c.abbreviation.length > 2 ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Sora',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: appColors.calendarSurface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Calendars',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                  fontFamily: 'Sora',
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isCalendarsSidebarExpanded = false),
                icon: const Icon(LucideIcons.chevronLeft, size: 18),
                tooltip: 'Collapse panel',
              ),
            ],
          ),
          const Gap(16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ElevatedButton.icon(
              onPressed: _showAddCalendarDialog,
              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              label: const Text('Add Calendar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          const Gap(20),
          Expanded(
            child: ListView.builder(
              itemCount: calendars.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final c = calendars[index];
                final isVisible = c.isVisible;
                final isActive = c.id == activeCalendarId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isActive ? theme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? theme.primaryColor.withValues(alpha: 0.2) : Colors.transparent),
                  ),
                  child: InkWell(
                    onTap: () {
                      ref.read(activeCalendarProvider.notifier).state = c.id;
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isVisible,
                            onChanged: (_) => ref.read(calendarProvider.notifier).toggleVisibility(c.id),
                            activeColor: Color(c.colorValue),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Gap(6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(c.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isVisible 
                                        ? theme.textTheme.bodyLarge?.color 
                                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      c.isTaskCalendar ? LucideIcons.checkSquare : LucideIcons.calendarDays,
                                      size: 9,
                                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                    ),
                                    const Gap(4),
                                    Text(
                                      c.isTaskCalendar ? 'Tasks' : 'Events',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    if (c.id.startsWith('imported_')) ...[
                                      const Gap(8),
                                      Icon(
                                        LucideIcons.downloadCloud,
                                        size: 9,
                                        color: theme.primaryColor.withValues(alpha: 0.7),
                                      ),
                                      const Gap(4),
                                      Text(
                                        'Imported ICS',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: theme.primaryColor.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(LucideIcons.moreVertical, size: 14, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.edit2, size: 12),
                                    Gap(8),
                                    Text('Edit', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (c.id != 'default_tasks')
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(LucideIcons.trash2, size: 12, color: Colors.redAccent),
                                      Gap(8),
                                      Text('Delete', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                    ],
                                  ),
                                ),
                            ],
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showEditCalendarDialog(c);
                              } else if (val == 'delete') {
                                _confirmDeleteCalendar(c);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
