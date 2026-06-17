import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ChangelogDialog extends StatefulWidget {
  const ChangelogDialog({super.key});

  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Robust source of truth matching pubspec.yaml to avoid package_info_plus empty/debug values on desktop
    const currentVersion = '1.0.11';
    final lastViewedVersion = prefs.getString('last_viewed_changelog_version');

    if (lastViewedVersion != currentVersion) {
      // Save version immediately to prevent multiple popups or debugger reload re-triggers
      await prefs.setString('last_viewed_changelog_version', currentVersion);
      
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ChangelogDialog(),
        );
      }
    }
  }

  @override
  State<ChangelogDialog> createState() => _ChangelogDialogState();
}

class _ChangelogDialogState extends State<ChangelogDialog> {



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: theme.dialogTheme.backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'What\'s New in Kaizen',
                        style: GoogleFonts.sora(
                          color: theme.textTheme.displayLarge?.color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            
            const Gap(24),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVersionSection(
                      context,
                      'v1.0.11',
                      [
                        'Patched Search Hub issues.',
                        'More UI improvements.',
                      ],
                      isLatest: true,
                    ),
                    const Gap(32),
                    _buildVersionSection(
                      context,
                      'v1.0.10',
                      [
                        'Refined Sidebar Header: The logo and app name now act as a seamless button to toggle the sidebar, and the expand/collapse icons have been intuitively placed.',
                        'Smart Popups: Success popups now glow green, while errors show up as red, making system feedback instantly clear.',
                        'App Tracker: Keep track of your daily app usage and productivity metrics.',
                        'App Notifications: Stay updated with system-wide app notifications and alerts.',
                        'Search Hub: A new centralized search hub to help you find anything instantly.',
                        'Improved Canvas: Major enhancements to the drawing canvas for a smoother and better experience.',
                        'Timer Settings: The timer can now be easily enabled or disabled from the settings page.',
                        'Addition of two new themes: Ash, Plush.',
                      ],
                    ),
                    const Gap(32),
                    _buildVersionSection(
                      context,
                      'v1.0.9',
                      [
                        'Added App Tour: The App Tour is here to help you get started with Kaizen. It will guide you through the app and help you get the most out of it.',
                        'UI Polish: Refined several visual elements.',
                        'Enable/Disable Timer: The timer can now be enabled/disabled in settings.'
                      ],
                      isLatest: false,
                    ),
                    const Gap(32),
                    _buildVersionSection(
                      context,
                      'v1.0.8',
                      [
                        'Added Custom Workouts: Create your own routines from scratch. Removed preset demo data app-wide for a fully personalized experience.',
                        'Updated Ivory Theme: Changed the theme icon to a soft feather to better reflect its aesthetic.',
                        'Streamlined Canvas: Removed the canvas size feature for a simpler infinite drawing experience.',
                        'Upgraded Dynamic Timer: Fully customizable alarm tunes, independent hour/minute/second controls, and smart tap-to-stop interaction.',
                      ],
                    ),

                    const Gap(40),
                  ],
                ),
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(40),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it, thanks!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionSection(BuildContext context, String version, List<String> items, {bool isLatest = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              version,
              style: GoogleFonts.inter(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isLatest) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LATEST',
                  style: GoogleFonts.inter(
                    color: theme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
        const Gap(16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
