import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/boxclock_provider.dart';
import '../habits/habits_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final user = ref.watch(userProvider);
    final habits = ref.watch(habitsProvider);
    final boxClockData = ref.watch(boxClockProvider);

    final completedCount = tasks.where((t) => t.status.name == 'done').length;

    // 1. Task Completion Rate
    final taskCompletionRate = tasks.isEmpty ? 75.0 : (completedCount / tasks.length) * 100.0;

    // 2. Habit Consistency (last 7 days completed or frozen)
    double habitConsistency = 80.0;
    if (habits.isNotEmpty) {
      int completedOrFrozenCount = 0;
      int totalDaysEvaluated = 0;
      final now = DateTime.now();
      for (final habit in habits) {
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final key = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final status = habit.history[key];
          if (status == HabitStatus.completed || status == HabitStatus.frozen) {
            completedOrFrozenCount++;
          }
          totalDaysEvaluated++;
        }
      }
      habitConsistency = totalDaysEvaluated > 0 ? (completedOrFrozenCount / totalDaysEvaluated) * 100.0 : 80.0;
    }

    // 3. Mindset / Achievement Score (Box Clock Scores)
    final boxClockScores = boxClockData.scores;
    final avgBoxClockScore = boxClockScores.isEmpty 
        ? 80.0 
        : (boxClockScores.map((s) => s.score).reduce((a, b) => a + b) / boxClockScores.length) * 10.0;

    // Calculate Focus Score
    final focusScore = (avgBoxClockScore * 0.5) + (habitConsistency * 0.3) + (taskCompletionRate * 0.2);

    // Calculate Efficiency
    double efficiency = 100.0;
    if (tasks.isNotEmpty && habits.isNotEmpty) {
      efficiency = (taskCompletionRate * 0.6) + (habitConsistency * 0.4);
    } else if (tasks.isNotEmpty) {
      efficiency = taskCompletionRate;
    } else if (habits.isNotEmpty) {
      efficiency = habitConsistency;
    }
    
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Banner Section
            _buildHeroSection(context, ref, user),
            
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Performance & Stats
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Performance Overview'),
                        const Gap(24),
                        Row(
                          children: [
                            _buildMetricCard(context, 'Focus Score', focusScore.round().toString(), LucideIcons.zap, Colors.amber),
                            const Gap(24),
                            _buildMetricCard(context, 'Tasks Done', completedCount.toString(), LucideIcons.checkCircle2, Colors.green),
                            const Gap(24),
                            _buildMetricCard(context, 'Efficiency', "${efficiency.round()}%", LucideIcons.trendingUp, theme.primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(40),
                  // Right Column: Bio & Other Info (Space for future profile-specific info)
                  const Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHeroSection(BuildContext context, WidgetRef ref, dynamic user) {
    final theme = Theme.of(context);
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.5), theme.scaffoldBackgroundColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Icon(LucideIcons.layoutGrid, size: 300, color: Colors.white.withValues(alpha: 0.05)),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.scaffoldBackgroundColor.withValues(alpha: 0), theme.scaffoldBackgroundColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 4),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                          image: (user.profilePic.isNotEmpty && !user.profilePic.contains('randomuser.me')) ? DecorationImage(
                            image: _getImageProvider(user.profilePic),
                            fit: BoxFit.cover,
                          ) : null,
                        ),
                        child: user.profilePic.isEmpty || user.profilePic.contains('randomuser.me')
                            ? const Center(
                                child: Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                            ),
                            if (user.status.trim().isNotEmpty) ...[
                              const Gap(12),
                              _buildStatusBadge(context, user.status),
                            ],
                          ],
                        ),
                        const Gap(4),
                      ],
                    ),
                  ),
                  _buildHeroAction(context, LucideIcons.edit3, 'Edit Profile', onTap: () => _showEditProfileDialog(context, ref, user)),
                  const Gap(12),
                  _buildHeroAction(context, LucideIcons.share2, 'Share', onTap: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(20),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            Text(label, style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }


  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile user) {
    final nameController = TextEditingController(text: user.name);
    final roleController = TextEditingController(text: user.role);
    final statusController = TextEditingController(text: user.status);
    final bioController = TextEditingController(text: user.bio);
    String? currentProfilePic = user.profilePic;

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          title: Text('Edit Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.dividerColor, width: 2),
                            image: currentProfilePic != null && currentProfilePic!.isNotEmpty && !currentProfilePic!.contains('randomuser.me') ? DecorationImage(
                              image: _getImageProvider(currentProfilePic!),
                              fit: BoxFit.cover,
                            ) : null,
                          ),
                          child: currentProfilePic == null || currentProfilePic!.isEmpty || currentProfilePic!.contains('randomuser.me')
                              ? const Center(
                                  child: Icon(
                                    LucideIcons.user,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                            onTap: () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.image);
                              if (result != null && result.files.single.path != null) {
                                setDialogState(() {
                                  currentProfilePic = result.files.single.path;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                              child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                  _buildTextField(context, 'Full Name', nameController),
                  const Gap(16),
                  _buildTextField(context, 'Role', roleController),
                  const Gap(16),
                  _buildTextField(context, 'Status', statusController),
                  const Gap(16),
                  _buildTextField(context, 'Bio', bioController, maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).updateProfile(user.copyWith(
                  name: nameController.text,
                  role: roleController.text,
                  status: statusController.text,
                  bio: bioController.text,
                  profilePic: currentProfilePic,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {int maxLines = 1}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.bold)),
        const Gap(8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: maxLines == 1 ? [FilteringTextInputFormatter.deny(RegExp(r'\n'))] : null,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primaryColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const Gap(20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, IconData icon, String title, String value, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
              const Gap(12),
              Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
              const Spacer(),
              Text(value, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
              const Gap(8),
              Icon(LucideIcons.chevronRight, size: 14, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        title: Text('Select Theme', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) => ListTile(
            title: Text(mode.label, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
              Navigator.pop(context);
            },
            trailing: ref.read(settingsProvider).themeMode == mode 
              ? Icon(LucideIcons.check, color: theme.primaryColor, size: 18) 
              : null,
          )).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final languages = ['English (US)', 'Spanish', 'French', 'German', 'Japanese'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        title: Text('Select Language', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) => ListTile(
            title: Text(lang, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              ref.read(settingsProvider.notifier).setLanguage(lang);
              Navigator.pop(context);
            },
            trailing: ref.read(settingsProvider).language == lang 
              ? Icon(LucideIcons.check, color: theme.primaryColor, size: 18) 
              : null,
          )).toList(),
        ),
      ),
    );
  }


  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primaryColor),
        const Gap(12),
        Text(text, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle)),
          const Gap(8),
          Text(status, style: TextStyle(color: theme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeroAction(BuildContext context, IconData icon, String tooltip, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: theme.textTheme.bodyLarge?.color),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textTheme.bodySmall?.color, letterSpacing: 1.2),
    );
  }
}
