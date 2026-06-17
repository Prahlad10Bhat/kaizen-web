import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/update_service.dart';

import '../../providers/settings_provider.dart';
import '../../providers/boxclock_provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/changelog_dialog.dart';
import '../../utils/snackbar_utils.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: GoogleFonts.sora(
                    color: theme.textTheme.displayLarge?.color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? 'v${snapshot.data!.version}' : 'Loading...';
                    return _AnimatedUpdateButton(version: version);
                  },
                ),
              ],
            ),
            const Gap(24),
            
            _buildSection(
              context,
              'THEME',
              [
                _buildSettingTile(
                  context,
                  _getThemeIcon(settings.themeMode),
                  'Theme',
                  settings.themeMode.label,
                  onTap: () => _showThemeDialog(context, ref),
                ),
              ],
            ),
            
            const Gap(24),
            _buildSection(
              context,
              'NOTIFICATIONS',
              [
                _buildToggleTile(
                  context,
                  LucideIcons.bell,
                  'Enable Notifications',
                  settings.notificationsEnabled,
                  (v) => ref.read(settingsProvider.notifier).setNotifications(v),
                ),
                _buildToggleTile(
                  context,
                  LucideIcons.timer,
                  'Enable Floating Timer',
                  settings.showTimer,
                  (v) => ref.read(settingsProvider.notifier).setShowTimer(v),
                ),
                _buildSettingTile(
                  context,
                  LucideIcons.music,
                  'Alarm Tune',
                  settings.alarmAudioPath == null 
                    ? 'Alarm Tune' 
                    : settings.alarmAudioPath == 'system' 
                      ? 'System Notification' 
                      : settings.alarmAudioPath!.split(r'\').last.split('/').last,
                  onTap: () => _showAlarmTuneDialog(context, ref),
                ),
              ],
            ),
            
            const Gap(24),
            _buildSection(
              context,
              'SUPPORT & COMMUNITY',
              [
                _buildSettingTile(
                  context,
                  LucideIcons.sparkles,
                  'What\'s New',
                  'Changelog',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ChangelogDialog(),
                    );
                  },
                ),
                _buildSettingTile(
                  context,
                  LucideIcons.messageSquare,
                  'Feedback',
                  'Send feedback',
                  onTap: () {
                    ref.read(navigationProvider.notifier).setPage(AppPage.feedback);
                  },
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }



  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String title, String value, {required VoidCallback onTap, VoidCallback? onClear}) {
    final theme = Theme.of(context);
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.primaryColor.withValues(alpha: 0.9), size: 16),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (onClear != null)
                  IconButton(
                    icon: Icon(LucideIcons.x, size: 16, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (onClear != null) const Gap(8),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: theme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),
                Icon(LucideIcons.chevronRight, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(BuildContext context, IconData icon, String title, bool value, Function(bool) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: theme.primaryColor.withValues(alpha: 0.9), size: 16),
          ),
          const Gap(16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        title: Text('Theme', style: GoogleFonts.sora(color: theme.textTheme.titleLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final palette = _getPaletteForMode(mode);
            return ListTile(
              leading: Icon(_getThemeIcon(mode), color: theme.primaryColor, size: 20),
              title: Text(mode.label, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              trailing: palette != null ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorDot(palette.background),
                  const Gap(4),
                  _buildColorDot(palette.surfaceElevated),
                  const Gap(4),
                  _buildColorDot(palette.accent),
                ],
              ) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAlarmTuneDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentPath = ref.read(settingsProvider).alarmAudioPath;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor,
        title: Text('Alarm Tune', style: GoogleFonts.sora(color: theme.textTheme.titleLarge?.color)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.music, color: theme.primaryColor, size: 20),
              title: Text('Alarm Tune (Default)', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              trailing: currentPath == null ? Icon(LucideIcons.check, color: theme.primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlarmAudioPath(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.bell, color: theme.primaryColor, size: 20),
              title: Text('System Notification (Silent)', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              trailing: currentPath == 'system' ? Icon(LucideIcons.check, color: theme.primaryColor) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setAlarmAudioPath('system');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.folderSearch, color: theme.primaryColor, size: 20),
              title: Text('Choose Custom File...', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              trailing: (currentPath != null && currentPath != 'system') ? Icon(LucideIcons.check, color: theme.primaryColor) : null,
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                );
                if (result != null && result.files.single.path != null) {
                  ref.read(settingsProvider.notifier).setAlarmAudioPath(result.files.single.path);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return LucideIcons.sun;
      case AppThemeMode.dark:
        return LucideIcons.moon;
      case AppThemeMode.cherryBlossom:
        return LucideIcons.flower2;
      case AppThemeMode.coffee:
        return LucideIcons.coffee;
      case AppThemeMode.ember:
        return LucideIcons.leaf;
      case AppThemeMode.ivory:
        return LucideIcons.feather;
      case AppThemeMode.ash:
        return LucideIcons.layoutTemplate;
      case AppThemeMode.plush:
        return LucideIcons.cloud;
      case AppThemeMode.system:
        return LucideIcons.monitor;
    }
  }

  AppPalette? _getPaletteForMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return AppPalette.light;
      case AppThemeMode.dark:
        return AppPalette.dark;
      case AppThemeMode.cherryBlossom:
        return AppPalette.cherryBlossom;
      case AppThemeMode.coffee:
        return AppPalette.coffee;
      case AppThemeMode.ember:
        return AppPalette.ember;
      case AppThemeMode.ivory:
        return AppPalette.ivory;
      case AppThemeMode.ash:
        return AppPalette.ash;
      case AppThemeMode.plush:
        return AppPalette.plush;
      case AppThemeMode.system:
        return null;
    }
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 1),
      ),
    );
  }
}

class _AnimatedUpdateButton extends StatefulWidget {
  final String version;
  
  const _AnimatedUpdateButton({required this.version});

  @override
  State<_AnimatedUpdateButton> createState() => _AnimatedUpdateButtonState();
}

class _AnimatedUpdateButtonState extends State<_AnimatedUpdateButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isChecking = false;
  bool _updateAvailable = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _checkInitialUpdate();
  }

  Future<void> _checkInitialUpdate() async {
    try {
      final available = await UpdateService.isUpdateAvailable();
      if (mounted) {
        setState(() {
          _updateAvailable = available;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });
    _controller.repeat();

    SnackbarUtils.showCustomSnackBar(context, 'Checking for updates...');
    
    try {
      final updateAvailable = await UpdateService.isUpdateAvailable();
      if (mounted) {
        setState(() {
          _updateAvailable = updateAvailable;
          _hasChecked = true;
        });
      }
      if (updateAvailable) {
        await UpdateService.downloadAndInstallUpdate();
      } else {
        SnackbarUtils.showCustomSnackBar(context, 'App is up to date');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
        _controller.stop();
        _controller.reset();
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'v${widget.version.replaceAll('v', '')}',
              style: GoogleFonts.inter(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Gap(12),
            InkWell(
              onTap: _isChecking ? null : _handleUpdate,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _updateAvailable ? const Color(0xFF10B981) : theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _updateAvailable ? const Color(0xFF10B981) : theme.primaryColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: _updateAvailable ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _controller,
                      child: Icon(
                        _isChecking
                            ? LucideIcons.refreshCw
                            : (_updateAvailable
                                ? LucideIcons.download
                                : LucideIcons.check),
                        size: 14,
                        color: _updateAvailable ? Colors.white : theme.primaryColor,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      _isChecking ? 'Checking...' : (_updateAvailable ? 'Update Available' : 'Up to Date'),
                      style: GoogleFonts.inter(
                        color: _updateAvailable ? Colors.white : theme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _updateAvailable ? 0.3 : 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
