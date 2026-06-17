import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/settings_page.dart';
import '../../providers/settings_provider.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';


import '../../../widgets/custom_context_menu.dart';
import '../../widgets/media_preview.dart';
import '../../widgets/window_buttons.dart';
import '../../theme/app_colors.dart';
import 'package:kaizen/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/note_editor.dart';
import 'providers/notes_providers.dart';
import '../../services/app_tour_service.dart';

class NoteTag {
  final String id;
  final String label;
  final Color color;

  NoteTag({required this.id, required this.label, required this.color});

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'color': color.value,
  };

  factory NoteTag.fromJson(Map<String, dynamic> json) => NoteTag(
    id: json['id'],
    label: json['label'],
    color: Color(json['color']),
  );
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final selectedId = ref.watch(selectedNoteIdProvider);
    final searchQuery = ref.watch(noteSearchQueryProvider).toLowerCase();
    final theme = Theme.of(context);

    // Sync controller if provider is cleared externally
    if (ref.read(noteSearchQueryProvider).isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    final allTags = ref.watch(tagsProvider);
    final matchedCategories = <String>{};
    final filteredNotes = notes.where((note) {
      final titleMatch = note.title.toLowerCase().contains(searchQuery);
      final contentMatch = note.content.toLowerCase().contains(searchQuery);
      final dateMatch = DateFormat('MMMM d, yyyy').format(note.updatedAt).toLowerCase().contains(searchQuery);
      final tagMatch = note.tagIds.any((tagId) {
        final tag = allTags.firstWhere((t) => t.id == tagId, orElse: () => NoteTag(id: '', label: '', color: Colors.transparent));
        return tag.label.toLowerCase().contains(searchQuery);
      });
      final mediaMatch = note.mediaPaths.any((path) {
        final filename = path.split(Platform.isWindows ? '\\' : '/').last.toLowerCase();
        return filename.contains(searchQuery);
      });

      if (searchQuery.isNotEmpty) {
        if (titleMatch) matchedCategories.add('Title');
        if (contentMatch) matchedCategories.add('Content');
        if (tagMatch) matchedCategories.add('Tags');
        
        // Identify specific media types that matched
        for (final path in note.mediaPaths) {
          final filename = path.split(Platform.isWindows ? '\\' : '/').last.toLowerCase();
          if (filename.contains(searchQuery)) {
            final ext = path.split('.').last.toLowerCase();
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) matchedCategories.add('Image');
            else if (['mp4', 'mov', 'webm'].contains(ext)) matchedCategories.add('Video');
            else if (['mp3', 'wav', 'm4a'].contains(ext)) matchedCategories.add('Audio');
            else matchedCategories.add('File');
          }
        }
      }

      return titleMatch || contentMatch || tagMatch || dateMatch || mediaMatch;
    }).toList();

    final sortedNotes = [...filteredNotes];
    sortedNotes.sort((a, b) {
      final aPinned = a.isPinned == true;
      final bPinned = b.isPinned == true;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Main Grid Dashboard
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, isMobile, matchedCategories.toList()),
                  Expanded(
                    child: filteredNotes.isEmpty 
                      ? _buildEmptyState(searchQuery.isNotEmpty)
                      : isMobile
                          ? ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                              itemCount: sortedNotes.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildNoteCard(context, sortedNotes[index], index: index),
                                );
                              },
                            )
                          : GridView.builder(
                              padding: EdgeInsets.fromLTRB(40, 0, 40, 40),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: sortedNotes.length,
                              itemBuilder: (context, index) {
                                return _buildNoteCard(context, sortedNotes[index], index: index);
                              },
                            ),
                  ),
                ],
              ),
              
              // Overlay Editor
              if (selectedId != null)
                Positioned.fill(
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                    onTap: () {
                      final note = notes.firstWhere((n) => n.id == selectedId);
                      if (note.title.trim().isEmpty && 
                          note.content.trim().isEmpty && 
                          note.mediaPaths.isEmpty) {
                        ref.read(notesProvider.notifier).deleteNote(note.id);
                      }
                      ref.read(selectedNoteIdProvider.notifier).set(null);
                    },
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: MouseRegion(cursor: SystemMouseCursors.basic, child: GestureDetector(
                          onTap: () {}, // Prevent tap from closing
                          child: Container(
                            width: isMobile ? constraints.maxWidth * 0.95 : 700,
                            height: isMobile ? constraints.maxHeight * 0.92 : 600,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                theme.cardColor, 
                                notes.firstWhere((n) => n.id == selectedId).color ?? Colors.transparent, 
                                0.1
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                )
                              ],
                            ),
                            child: NoteEditor(
                              note: notes.firstWhere((n) => n.id == selectedId),
                              onDelete: () => _handleDelete(context, notes.firstWhere((n) => n.id == selectedId)),
                            ),
                          ),
                        )),
                      ),
                    ),
                  )),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, Note note) async {
    final settings = ref.read(settingsProvider);
    final theme = Theme.of(context);
    
    if (!settings.askBeforeDelete) {
      ref.read(selectedNoteIdProvider.notifier).set(null);
      ref.read(notesProvider.notifier).deleteNote(note.id);
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
            title: Text('Delete Note', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this note? This action cannot be undone.',
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
      ref.read(selectedNoteIdProvider.notifier).set(null);
      ref.read(notesProvider.notifier).deleteNote(note.id);
    }
  }

  Widget _buildTopBar(BuildContext context, bool isMobile, List<String> matchCategories) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 40, isMobile ? 32 : 64, isMobile ? 16 : 40, isMobile ? 24 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Gap(12),
                  IconButton(
                    onPressed: () => _showSettingsDialog(context),
                    icon: Icon(LucideIcons.settings, size: 20, color: theme.textTheme.labelLarge?.color),
                    tooltip: 'Settings & Controls',
                  ),
                ],
              ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Container(
                              key: AppTourKeys.notesSearchKey,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                              ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => ref.read(noteSearchQueryProvider.notifier).set(val),
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Search notes...',
                                hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.5), fontSize: 14),
                                prefixIcon: Icon(LucideIcons.search, size: 18, color: theme.textTheme.labelLarge?.color),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                suffixIcon: ref.watch(noteSearchQueryProvider).isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(noteSearchQueryProvider.notifier).set('');
                                      },
                                      color: theme.textTheme.labelLarge?.color,
                                    )
                                  : null,
                              ),
                            ),
                          ),
                        ),
                        if (matchCategories.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Matches via: ${matchCategories.join(', ')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.primaryColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Gap(16),
                    Padding(
                      padding: EdgeInsets.only(bottom: matchCategories.isNotEmpty ? 24 : 0),
                      child: IconButton(
                        key: AppTourKeys.notesAddKey,
                        onPressed: () {
                          final id = ref.read(notesProvider.notifier).addNote();
                          ref.read(selectedNoteIdProvider.notifier).set(id);
                        },
                        icon: const Icon(LucideIcons.plus, size: 24),
                        color: theme.primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              if (isMobile)
                IconButton(
                  onPressed: () {
                    final id = ref.read(notesProvider.notifier).addNote();
                    ref.read(selectedNoteIdProvider.notifier).set(id);
                  },
                  icon: const Icon(LucideIcons.plus, size: 24),
                  color: theme.primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
          if (isMobile) ...[
            const Gap(16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => ref.read(noteSearchQueryProvider.notifier).set(val),
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search notes...',
                      hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.5), fontSize: 14),
                      prefixIcon: Icon(LucideIcons.search, size: 18, color: theme.textTheme.labelLarge?.color),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: ref.watch(noteSearchQueryProvider).isNotEmpty 
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(noteSearchQueryProvider.notifier).set('');
                            },
                            color: theme.textTheme.labelLarge?.color,
                          )
                        : null,
                    ),
                  ),
                ),
              ),
            ),
            if (matchCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Matches via: ${matchCategories.join(', ')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.primaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final labelController = TextEditingController();
    Color selectedColor = theme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Consumer(
          builder: (context, ref, child) {
            final tags = ref.watch(tagsProvider);
            final settings = ref.watch(settingsProvider);
            final currentView = ref.watch(dialogViewProvider);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 500,
                height: 700, // Fixed height instead of maxHeight
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.dialogTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    )
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350), // Slightly faster
                  switchInCurve: Curves.easeInOutQuart,
                  switchOutCurve: Curves.easeInOutQuart,
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final isEntering = child.key == ValueKey(currentView.mode);
                    
                    // Define sliding offsets based on direction and enter/exit state
                    Offset beginOffset;
                    if (currentView.isForward) {
                      beginOffset = isEntering ? const Offset(0.2, 0) : const Offset(-0.2, 0);
                    } else {
                      beginOffset = isEntering ? const Offset(-0.2, 0) : const Offset(0.2, 0);
                    }

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: currentView.mode == 'home'
                      ? _buildMainSettingsView(context, ref, settings)
                      : currentView.mode == 'tags'
                          ? _buildManageTagsView(context, ref, setDialogState, tags, labelController, selectedColor, (color) => selectedColor = color)
                          : _buildTagEditorView(context, ref, currentView.editingTag!),
                ),
              ),
            );
          },
        ),
      ),
    ).then((_) {
      ref.read(dialogViewProvider.notifier).set('home');
    });
  }

  Widget _buildMainSettingsView(BuildContext context, WidgetRef ref, AppSettings settings) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('home'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notes Controls', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
          const Gap(24),
          _buildHelpItem(context, LucideIcons.mousePointer, 'Right Click Menu', 'Open context menu to Pin or Delete'),
          const Gap(16),
          _buildHelpItem(context, LucideIcons.pin, 'Pinning', 'Pinned notes stay at the top of your dashboard'),
          const Gap(16),
          _buildHelpItem(context, LucideIcons.plus, 'Add Note', 'Create a new blank note in the grid'),
          const Gap(16),
          _buildHelpItem(context, LucideIcons.imagePlus, 'Media', 'Add images to your notes from the editor'),
          const Gap(32),
          Divider(color: theme.dividerColor),
          const Gap(24),
          Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
          const Gap(16),
          _buildHelpItem(
            context,
            LucideIcons.tags, 
            'Manage Tags', 
            'View and delete your custom tags',
            onTap: () => ref.read(dialogViewProvider.notifier).set('tags'),
          ),
          const Gap(16),
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => ref.read(settingsProvider.notifier).setAskBeforeDelete(!settings.askBeforeDelete),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.shieldAlert, size: 16, color: theme.textTheme.bodyMedium?.color),
                      const Gap(12),
                      Text('Ask before deleting', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                    ],
                  ),
                  Switch(
                    value: settings.askBeforeDelete,
                    onChanged: (val) => ref.read(settingsProvider.notifier).setAskBeforeDelete(val),
                    activeColor: theme.primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
          const Gap(32),
          Center(
            child: Text('Kaizen Notes v1.0', style: TextStyle(color: theme.textTheme.labelLarge?.color, fontSize: 11)),
          ),
          const Gap(8),
        ],
      ),
    );
  }

  Widget _buildManageTagsView(
    BuildContext context, 
    WidgetRef ref, 
    StateSetter setDialogState, 
    List<NoteTag> tags, 
    TextEditingController labelController, 
    Color selectedColor,
    Function(Color) onColorUpdate
  ) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const ValueKey('tags'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => ref.read(dialogViewProvider.notifier).set('home'),
                icon: Icon(LucideIcons.arrowLeft, size: 20, color: theme.textTheme.bodyMedium?.color),
              ),
              const Gap(12),
              Text('Manage Tags', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
          const Gap(20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: labelController,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'New tag label...',
                          hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.4)),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const Gap(12),
                    MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: BlockPicker(
                              pickerColor: selectedColor,
                              onColorChanged: (color) {
                                onColorUpdate(color);
                                setDialogState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle, border: Border.all(color: theme.dividerColor, width: 1.5)),
                      ),
                    )),
                  ],
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (labelController.text.trim().isNotEmpty) {
                        ref.read(tagsProvider.notifier).addTag(labelController.text.trim(), selectedColor);
                        labelController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Add Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          Text('Current Tags (Drag to reorder)', style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.bold)),
          const Gap(12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: tags.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No tags yet', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)))),
                )
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: tags.length,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(tagsProvider.notifier).reorderTags(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return Column(
                      key: ValueKey(tag.id),
                      children: [
                        ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Icon(LucideIcons.gripVertical, size: 14, color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.3)),
                                ),
                              ),
                              const Gap(12),
                              Icon(LucideIcons.tag, size: 14, color: tag.color),
                            ],
                          ),
                          title: Text(tag.label, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(LucideIcons.edit3, size: 16, color: theme.primaryColor.withValues(alpha: 0.7)),
                                onPressed: () => ref.read(dialogViewProvider.notifier).set('edit_tag', tag: tag),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                onPressed: () => ref.read(tagsProvider.notifier).deleteTag(tag.id),
                              ),
                            ],
                          ),
                        ),
                        if (index < tags.length - 1) 
                          Divider(color: theme.dividerColor, height: 1),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagEditorView(BuildContext context, WidgetRef ref, NoteTag tag) {
    final theme = Theme.of(context);
    final labelController = TextEditingController(text: tag.label);
    Color selectedColor = tag.color;

    return SingleChildScrollView(
      key: const ValueKey('edit_tag'),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => ref.read(dialogViewProvider.notifier).set('tags'),
                  icon: Icon(LucideIcons.arrowLeft, size: 20, color: theme.textTheme.bodyMedium?.color),
                ),
                const Gap(12),
                Text('Edit Tag', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Gap(24),
            Text('Tag Label', style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(8),
            TextField(
              controller: labelController,
              autofocus: true,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter tag name...',
                filled: true,
                fillColor: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const Gap(24),
            Text('Select Color', style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Colors.redAccent,
                Colors.orangeAccent,
                Colors.amberAccent,
                Colors.greenAccent,
                Colors.blueAccent,
                Colors.purpleAccent,
                Colors.pinkAccent,
                theme.primaryColor,
              ].map((color) => MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? (theme.textTheme.bodyLarge?.color ?? Colors.white) : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (selectedColor == color)
                            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)
                        ],
                      ),
                      child: selectedColor == color ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ))).toList(),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (labelController.text.trim().isNotEmpty) {
                    ref.read(tagsProvider.notifier).updateTag(tag.id, labelController.text.trim(), selectedColor);
                    ref.read(dialogViewProvider.notifier).set('tags');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String description, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: theme.primaryColor),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(LucideIcons.chevronRight, size: 14, color: theme.textTheme.labelLarge?.color),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    final theme = Theme.of(context);
    
    if (isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No search results found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            const Gap(12),
            Text(
              'Try adjusting your search query',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.fileText, size: 48, color: theme.primaryColor),
              ),
              const Gap(24),
              Text(
                'Create a Note',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
              ),
              const Gap(8),
              SizedBox(
                width: 340,
                child: Text(
                  'A single idea can change everything. Create your first note to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
                ),
              ),
              const Gap(32),
              ElevatedButton(
                onPressed: () {
                  final id = ref.read(notesProvider.notifier).addNote();
                  ref.read(selectedNoteIdProvider.notifier).set(id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  elevation: 0,
                ),
                child: const Text('Create First Note', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note, {int? index}) {
    final theme = Theme.of(context);
    final allTags = ref.watch(tagsProvider);
    final firstTagColor = note.tagIds.isNotEmpty 
        ? allTags.firstWhere((t) => t.id == note.tagIds.first, orElse: () => NoteTag(id: '', label: '', color: Colors.transparent)).color
        : null;
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => ref.read(selectedNoteIdProvider.notifier).set(note.id),
          onLongPress: () {
            final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
            showCustomContextMenu(
              context: context,
              position: MediaQuery.of(context).size.center(Offset.zero),
              items: [
                CustomContextMenuItem(
                  icon: note.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                  label: note.isPinned ? 'Unpin' : 'Pin',
                  onTap: () => ref.read(notesProvider.notifier).togglePin(note.id),
                ),
                CustomContextMenuItem(
                  icon: LucideIcons.trash2,
                  label: 'Delete',
                  isDestructive: true,
                  onTap: () => _handleDelete(context, note),
                ),
              ],
            );
          },
          child: Container(
            key: index == 0 ? AppTourKeys.notesSampleNoteKey : null,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: note.color?.withValues(alpha: 0.08) ?? theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: note.isPinned 
                    ? theme.primaryColor.withValues(alpha: 0.5) 
                    : (note.color ?? (firstTagColor != null && firstTagColor != Colors.transparent ? firstTagColor : null))?.withValues(alpha: 0.3) 
                      ?? theme.dividerColor.withValues(alpha: 0.1),
                width: note.isPinned ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.01),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (note.isPinned)
                      Icon(LucideIcons.pin, size: 14, color: theme.primaryColor),
                  ],
                ),
                const Gap(6),
                Text(
                  DateFormat('MMMM d, yyyy â€¢ h:mm a').format(note.updatedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  ),
                ),
                const Gap(12),
                Text(
                  note.content.isEmpty ? 'No additional text content.' : note.content.trim().replaceAll(RegExp(r'\n+'), '  '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
                if (note.mediaPaths.isNotEmpty) ...[
                  const Gap(16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: note.mediaPaths.length,
                      itemBuilder: (context, mediaIndex) {
                        final path = note.mediaPaths[mediaIndex];
                        final ext = path.split('.').last.toLowerCase();
                        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
                        
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark 
                                ? const Color(0xFF13131F)
                                : theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: isImage
                              ? Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(child: Icon(LucideIcons.image, size: 18, color: theme.primaryColor)),
                                )
                              : Center(
                                  child: Icon(
                                    ext == 'mp4' || ext == 'mov' ? LucideIcons.playCircle : LucideIcons.file,
                                    size: 18,
                                    color: theme.primaryColor,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
                if (note.tagIds.isNotEmpty) ...[
                  const Gap(16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: note.tagIds.map((tagId) {
                      final tag = allTags.firstWhere((t) => t.id == tagId, orElse: () => NoteTag(id: '', label: '', color: Colors.transparent));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tag.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tag.color.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          tag.label,
                          style: GoogleFonts.inter(
                            color: tag.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => ref.read(selectedNoteIdProvider.notifier).set(note.id),
        onSecondaryTapDown: (details) {
          showCustomContextMenu(
            context: context,
            position: details.globalPosition,
            items: [
              CustomContextMenuItem(
                icon: note.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                label: note.isPinned ? 'Unpin' : 'Pin',
                onTap: () => ref.read(notesProvider.notifier).togglePin(note.id),
              ),
              CustomContextMenuItem(
                icon: LucideIcons.trash2,
                label: 'Delete',
                isDestructive: true,
                onTap: () => _handleDelete(context, note),
              ),
            ],
          );
        },
        child: Container(
          key: index == 0 ? AppTourKeys.notesSampleNoteKey : null,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: note.color?.withValues(alpha: 0.1) ?? theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: note.isPinned 
                  ? theme.primaryColor.withValues(alpha: 0.4) 
                  : (note.color ?? (firstTagColor != null && firstTagColor != Colors.transparent ? firstTagColor : null))?.withValues(alpha: 0.3) 
                    ?? theme.primaryColor.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  if (note.isPinned)
                    Icon(LucideIcons.pin, size: 12, color: theme.primaryColor),
                  const Gap(8),
                  Text(
                    DateFormat('MMM d').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.textTheme.labelLarge?.color,
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  note.content.isEmpty ? 'No content' : note.content.trim().replaceAll(RegExp(r'\n+'), '  '),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              // Media Indicators
              if (note.mediaPaths.isNotEmpty) ...[
                const Gap(8),
                _buildMediaIndicators(note.mediaPaths),
              ],
              if (note.tagIds.isNotEmpty) ...[
                const Gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: note.tagIds.map((tagId) {
                    final tag = ref.watch(tagsProvider).firstWhere((t) => t.id == tagId, orElse: () => NoteTag(id: '', label: '', color: Colors.transparent));
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tag.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tag.color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        tag.label,
                        style: TextStyle(
                          color: tag.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaIndicators(List<String> paths) {
    int images = 0;
    int videos = 0;
    int audio = 0;

    for (final path in paths) {
      final ext = path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) images++;
      else if (['mp4', 'mov', 'webm'].contains(ext)) videos++;
      else if (['mp3', 'wav', 'm4a'].contains(ext)) audio++;
    }

    return Row(
      children: [
        if (images > 0) _indicator(context, LucideIcons.image, images.toString()),
        if (videos > 0) _indicator(context, LucideIcons.playCircle, videos.toString()),
        if (audio > 0) _indicator(context, LucideIcons.music, audio.toString()),
      ],
    );
  }

  Widget _indicator(BuildContext context, IconData icon, String count) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? Colors.white70;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

