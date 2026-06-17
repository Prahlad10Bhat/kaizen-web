import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../providers/app_tracker_provider.dart';
import '../../../models/tracked_app.dart';
import 'app_icon_widget.dart';

class TrackedAppsTable extends ConsumerStatefulWidget {
  final Function(TrackedApp) onEditApp;

  const TrackedAppsTable({
    super.key,
    required this.onEditApp,
  });

  @override
  ConsumerState<TrackedAppsTable> createState() => _TrackedAppsTableState();
}

class _TrackedAppsTableState extends ConsumerState<TrackedAppsTable> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAppDialog(BuildContext context, AppTrackerState state) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('Running Apps', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          content: SizedBox(
            width: 400,
            height: 300,
            child: state.discoveredApps.isEmpty
                ? Center(
                    child: Text(
                      state.isTrackingEnabled
                          ? 'No new apps discovered recently. Open an app and make it active to discover it.'
                          : 'Turn on tracking to detect running apps',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: state.discoveredApps.length,
                    itemBuilder: (context, index) {
                      final processName = state.discoveredApps.keys.elementAt(index);
                      final processPath = state.discoveredApps.values.elementAt(index);
                      
                      return ListTile(
                        title: Text(processName, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                        subtitle: Text(processPath ?? 'Unknown path', style: TextStyle(color: theme.textTheme.bodySmall?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showConfigureDiscoveredAppDialog(context, processName, processPath);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                          child: Text('Add', style: TextStyle(color: theme.colorScheme.onPrimary)),
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
        );
      },
    );
  }

  void _showConfigureDiscoveredAppDialog(BuildContext context, String processName, String? processPath) {
    final theme = Theme.of(context);
    String defaultName = processName.replaceAll('.exe', '');
    if (defaultName.isNotEmpty) {
      defaultName = defaultName[0].toUpperCase() + defaultName.substring(1);
    }
    final nameController = TextEditingController(text: defaultName);
    bool isProductive = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text('Configure App', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'App Name',
                    labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Is Productive?', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                    Switch(
                      value: isProductive,
                      onChanged: (val) => setState(() => isProductive = val),
                      activeColor: theme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(appTrackerProvider.notifier).addDiscoveredAppToTracking(
                      processName,
                      processPath,
                      customName: name,
                      isProductive: isProductive,
                    );
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
                child: Text('Save', style: TextStyle(color: theme.colorScheme.onPrimary)),
              ),
            ],
          );
        }
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appTrackerProvider);
    final theme = Theme.of(context);
    
    final filteredApps = _searchQuery.isEmpty 
        ? state.apps 
        : state.apps.where((app) => app.name.toLowerCase().contains(_searchQuery)).toList();
    
    int totalDaySecs = 0;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    for (var app in state.apps) {
      totalDaySecs += app.getTodayDurationSeconds();
      if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
        DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
        totalDaySecs += now.difference(visibleStart).inSeconds;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tracked Applications',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),
              ElevatedButton.icon(
                onPressed: () => _showAddAppDialog(context, state),
                icon: Icon(LucideIcons.plus, size: 16, color: theme.colorScheme.onPrimary),
                label: Text('Add App', style: TextStyle(color: theme.colorScheme.onPrimary)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                child: Row(
                  children: [
                    const Gap(12),
                    Icon(LucideIcons.search, size: 14, color: theme.textTheme.bodySmall?.color),
                    const Gap(8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color),
                        decoration: InputDecoration(
                          hintText: 'Search apps...',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(bottom: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
          const Gap(24),
          // Table Header
          Row(
            children: [
              Expanded(flex: 3, child: _HeaderCell('APPLICATION', theme)),
              Expanded(flex: 1, child: _HeaderCell('TIME SPENT', theme)),
              Expanded(flex: 2, child: _HeaderCell('USAGE', theme)),
              SizedBox(width: 80, child: _HeaderCell('ACTIONS', theme, alignRight: true)),
            ],
          ),
          const Gap(8),
          Divider(color: theme.dividerColor),
          const Gap(8),
          // Table Rows
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.separated(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredApps.length,
              separatorBuilder: (context, index) => const Gap(16),
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                int duration = app.getTodayDurationSeconds();
                if (app.id == state.activeAppId && state.currentSessionStartTime != null) {
                  DateTime visibleStart = state.currentSessionStartTime!.isBefore(startOfDay) ? startOfDay : state.currentSessionStartTime!;
                  duration += now.difference(visibleStart).inSeconds;
                }
                final percent = totalDaySecs > 0 ? (duration / totalDaySecs) : 0.0;

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          AppIconWidget(app: app, size: 24),
                          const Gap(12),
                          Expanded(
                            child: Text(
                              app.name,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        _formatDuration(duration),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                AnimatedFractionallySizedBox(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  widthFactor: percent.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: app.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(12),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${(percent * 100).round()}%',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => widget.onEditApp(app),
                            child: Icon(LucideIcons.pencil, size: 16, color: theme.textTheme.bodySmall?.color),
                          ),
                          const Gap(12),
                          InkWell(
                            onTap: () {
                              ref.read(appTrackerProvider.notifier).removeApp(app.id);
                            },
                            child: Icon(LucideIcons.trash2, size: 16, color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _HeaderCell(String text, ThemeData theme, {bool alignRight = false}) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6), 
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 10,
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
    );
  }
}
