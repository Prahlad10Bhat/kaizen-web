import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/settings_provider.dart';
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
import '../../../widgets/media_preview.dart';
import '../../../services/app_tour_service.dart';
import '../../../widgets/window_buttons.dart';
import '../../../theme/app_colors.dart';
import 'package:kaizen/utils/snackbar_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../notes_page.dart';
import '../providers/notes_providers.dart';
class NoteEditor extends ConsumerStatefulWidget {
  final Note note;
  final VoidCallback onDelete;
  const NoteEditor({super.key, required this.note, required this.onDelete});

  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late TextEditingController _titleController;
  late LinkTextEditingController _contentController;

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  late ScrollController _mediaScrollController;
  late ScrollController _tagScrollController;
  late ScrollController _colorScrollController;
  bool _isHoveringMedia = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = LinkTextEditingController(text: widget.note.content);
    _mediaScrollController = ScrollController();
    _tagScrollController = ScrollController();
    _colorScrollController = ScrollController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _mediaScrollController.dispose();
    _tagScrollController.dispose();
    _colorScrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final updatedNote = widget.note.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );
    ref.read(notesProvider.notifier).updateNote(updatedNote);
  }

  Future<void> _pasteFromClipboard() async {
    try {
      // 1. Check for copied files first (e.g. copied from explorer)
      final List<String> files = await Pasteboard.files();
      if (files.isNotEmpty) {
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'mp4', 'mov', 'webm', 'mp3', 'wav', 'm4a'];
        final validPaths = files.where((path) {
          final ext = path.split('.').last.toLowerCase();
          return allowedExtensions.contains(ext);
        }).toList();

        if (validPaths.isNotEmpty) {
          ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(
            mediaPaths: [...widget.note.mediaPaths, ...validPaths],
            updatedAt: DateTime.now(),
          ));
          if (mounted) {
            SnackbarUtils.showCustomSnackBar(context, 'Pasted ${validPaths.length} file(s)');
          }
          return;
        }
      }

      // 2. Otherwise, check for direct image bytes (e.g. screenshot or copied web image)
      final Uint8List? imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        final appDir = await getApplicationSupportDirectory();
        final notesDir = Directory('${appDir.path}/pasted_notes_images');
        if (!await notesDir.exists()) {
          await notesDir.create(recursive: true);
        }

        final filename = 'pasted_img_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${notesDir.path}/$filename');
        await file.writeAsBytes(imageBytes);

        ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(
          mediaPaths: [...widget.note.mediaPaths, file.path],
          updatedAt: DateTime.now(),
        ));

        if (mounted) {
          SnackbarUtils.showCustomSnackBar(context, 'Pasted image from clipboard');
        }
        return;
      }

      // 3. Fallback to text pasting
      final ClipboardData? textData = await Clipboard.getData(Clipboard.kTextPlain);
      if (textData != null && textData.text != null && textData.text!.isNotEmpty) {
        final text = textData.text!;
        if (_titleFocusNode.hasFocus) {
          final textSelection = _titleController.selection;
          if (textSelection.isValid) {
            final newText = _titleController.text.replaceRange(textSelection.start, textSelection.end, text);
            _titleController.value = _titleController.value.copyWith(
              text: newText,
              selection: TextSelection.collapsed(offset: textSelection.start + text.length),
            );
          } else {
            _titleController.text += text;
            _titleController.selection = TextSelection.collapsed(offset: _titleController.text.length);
          }
          _onChanged();
        } else if (_contentFocusNode.hasFocus) {
          final textSelection = _contentController.selection;
          if (textSelection.isValid) {
            final newText = _contentController.text.replaceRange(textSelection.start, textSelection.end, text);
            _contentController.value = _contentController.value.copyWith(
              text: newText,
              selection: TextSelection.collapsed(offset: textSelection.start + text.length),
            );
          } else {
            _contentController.text += text;
            _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
          }
          _onChanged();
        } else {
          // If neither has focus, default to content
          _contentController.text += text;
          _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
          _onChanged();
        }
        return;
      }

      if (mounted) {
        SnackbarUtils.showCustomSnackBar(context, 'No text, image, or valid media found in clipboard');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showCustomSnackBar(context, 'Error pasting from clipboard: $e', isError: true);
      }
    }
  }

  Future<void> _confirmAndLaunchUrl(String url) async {
    final theme = Theme.of(context);
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    
    final shouldLaunch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        title: Text('Open External Link?', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        content: Text(
          'You are about to be redirected to:\n\n$url',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to site'),
          ),
        ],
      ),
    );

    if (shouldLaunch == true) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          SnackbarUtils.showCustomSnackBar(context, 'Could not launch $url', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _pasteFromClipboard,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _pasteFromClipboard,
      },
      child: Column(
        children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: AppTourKeys.notesEditorTitleKey,
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  onChanged: (_) => _onChanged(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                key: AppTourKeys.notesEditorMediaKey,
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'webm', 'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
                  );
                  if (result != null && result.files.single.path != null) {
                    ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(
                          mediaPaths: [...widget.note.mediaPaths, result.files.single.path!],
                        ));
                  }
                },
                icon: const Icon(LucideIcons.imagePlus),
                color: theme.textTheme.bodyMedium?.color,
                tooltip: 'Add Image/Media',
              ),
              const Gap(8),
              IconButton(
                onPressed: () {
                  if (_titleController.text.trim().isEmpty &&
                      _contentController.text.trim().isEmpty &&
                      widget.note.mediaPaths.isEmpty) {
                    ref.read(notesProvider.notifier).deleteNote(widget.note.id);
                  }
                  ref.read(selectedNoteIdProvider.notifier).set(null);
                },
                icon: const Icon(LucideIcons.x),
                color: theme.textTheme.bodyMedium?.color,
              ),
            ],
          ),
        ),
        Container(
          key: AppTourKeys.notesEditorColorKey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.02),
            border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
          ),
          child: Row(
          children: [
              // Color Picker
              Expanded(
                flex: 2,
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final newOffset = _colorScrollController.offset + pointerSignal.scrollDelta.dy;
                      _colorScrollController.jumpTo(
                        newOffset.clamp(0.0, _colorScrollController.position.maxScrollExtent),
                      );
                    }
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.touch,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    child: SingleChildScrollView(
                      controller: _colorScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildColorOption(null, 'Default'),
                          _buildColorOption(const Color(0xFFE57373), 'Red'),
                          _buildColorOption(const Color(0xFF81C784), 'Green'),
                          _buildColorOption(const Color(0xFF64B5F6), 'Blue'),
                          _buildColorOption(const Color(0xFFFFD54F), 'Yellow'),
                          _buildColorOption(const Color(0xFFBA68C8), 'Purple'),
                          const Gap(8),
                          IconButton(
                            onPressed: () => _showColorPicker(),
                            icon: const Icon(LucideIcons.palette, size: 16),
                            color: theme.textTheme.bodyMedium?.color,
                            tooltip: 'Custom Color',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              VerticalDivider(width: 1, indent: 8, endIndent: 8, color: theme.dividerTheme.color),
              const Gap(16),
              // Tags
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(LucideIcons.tag, size: 14, color: theme.textTheme.labelLarge?.color),
                    const Gap(12),
                    Expanded(
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final newOffset = _tagScrollController.offset + pointerSignal.scrollDelta.dy;
                            _tagScrollController.jumpTo(
                              newOffset.clamp(0.0, _tagScrollController.position.maxScrollExtent),
                            );
                          }
                        },
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.touch,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: Scrollbar(
                            controller: _tagScrollController,
                            thickness: 2,
                            child: SingleChildScrollView(
                              controller: _tagScrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: ref.watch(tagsProvider).map((tag) {
                                  final isSelected = widget.note.tagIds.contains(tag.id);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: InkWell(
                                        onTap: () {
                                        final newTagIds = List<String>.from(widget.note.tagIds);
                                        if (isSelected) {
                                          newTagIds.remove(tag.id);
                                        } else {
                                          newTagIds.add(tag.id);
                                        }
                                        ref.read(notesProvider.notifier).updateNote(
                                              widget.note.copyWith(tagIds: newTagIds),
                                            );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? tag.color.withValues(alpha: 0.2) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? tag.color.withValues(alpha: 0.4) : theme.dividerColor,
                                          ),
                                        ),
                                        child: Text(
                                          tag.label,
                                          style: TextStyle(
                                            color: isSelected ? tag.color : theme.textTheme.bodyMedium?.color,
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    IconButton(
                      onPressed: () => _showAddTagDialog(),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      color: theme.textTheme.labelLarge?.color,
                      tooltip: 'Add Tag',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: const EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _contentFocusNode.requestFocus(),
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.note.mediaPaths.isNotEmpty) ...[
                    const Gap(24),
                    SizedBox(
                      height: 200,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringMedia = true),
                        onExit: (_) => setState(() => _isHoveringMedia = false),
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: _mediaScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.note.mediaPaths.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: MediaPreview(
                                    path: widget.note.mediaPaths[index],
                                    onDelete: () {
                                      final newPaths = List<String>.from(widget.note.mediaPaths);
                                      newPaths.removeAt(index);
                                      ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(
                                            mediaPaths: newPaths,
                                          ));
                                    },
                                  ),
                                );
                              },
                            ),
                            if (_isHoveringMedia && widget.note.mediaPaths.length > 4) ...[
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: _buildScrollButton(isLeft: true),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: _buildScrollButton(isLeft: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    onChanged: (_) => _onChanged(),
                    onTap: () async {
                      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
                      if (isCtrlPressed) {
                        final selection = _contentController.selection;
                        if (selection.isValid && selection.isCollapsed) {
                          final text = _contentController.text;
                          final RegExp urlRegex = RegExp(
                            r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
                            caseSensitive: false,
                          );
                          for (final match in urlRegex.allMatches(text)) {
                            if (selection.baseOffset >= match.start && selection.baseOffset <= match.end) {
                              final url = match.group(0)!;
                              await _confirmAndLaunchUrl(url);
                              break;
                            }
                          }
                        }
                      }
                    },
                    maxLines: null,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Note',
                      hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color),
                      border: InputBorder.none,
                    ),
                    contextMenuBuilder: (context, editableTextState) {
                      final List<ContextMenuButtonItem> buttonItems = editableTextState.contextMenuButtonItems;
                      
                      final selection = editableTextState.textEditingValue.selection;
                      if (selection.isValid) {
                        final text = _contentController.text;
                        final RegExp urlRegex = RegExp(
                          r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
                          caseSensitive: false,
                        );
                        String? hoveredUrl;
                        for (final match in urlRegex.allMatches(text)) {
                          if (selection.baseOffset >= match.start && selection.baseOffset <= match.end) {
                            hoveredUrl = match.group(0);
                            break;
                          }
                        }
                        
                        if (hoveredUrl != null) {
                          buttonItems.insert(0, ContextMenuButtonItem(
                            label: 'Open Link',
                            onPressed: () async {
                              ContextMenuController.removeAny();
                              await _confirmAndLaunchUrl(hoveredUrl!);
                            },
                          ));
                        }
                      }
                      
                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: buttonItems,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  void _showColorPicker() {
    final theme = Theme.of(context);
    Color pickerColor = widget.note.color ?? theme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        content: Container(
          width: 500,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.dialogTheme.backgroundColor?.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Color',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'Fine-tune your note appearance',
                            style: TextStyle(
                              color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: theme.textTheme.bodyMedium?.color,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ColorPicker(
                            pickerColor: pickerColor,
                            onColorChanged: (color) {
                              pickerColor = color;
                            },
                            colorPickerWidth: 120,
                            pickerAreaHeightPercent: 0.8,
                            enableAlpha: true,
                            displayThumbColor: false,
                            paletteType: PaletteType.hsvWithHue,
                            labelTypes: const [],
                            pickerAreaBorderRadius: BorderRadius.circular(0),
                            hexInputBar: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(color: Wrapped(pickerColor)));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Save Color',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
    );
  }

  void _showAddTagDialog() {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    Color selectedColor = theme.primaryColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor,
          shape: theme.dialogTheme.shape,
          title: Text('New Tag', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Tag label',
                  hintStyle: TextStyle(color: theme.textTheme.labelLarge?.color),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
                ),
              ),
              const Gap(24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Tag Color', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                      onTap: () => setDialogState(() => selectedColor = color),
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
                        ),
                      ),
                    ))).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(tagsProvider.notifier).addTag(controller.text, selectedColor);
                  Navigator.pop(context);
                }
              },
              child: Text('Create', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollButton({required bool isLeft}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: () {
            final offset = _mediaScrollController.offset + (isLeft ? -300 : 300);
            _mediaScrollController.animateTo(
              offset.clamp(0, _mediaScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isLeft ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
              size: 20,
              color: Colors.white,
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildColorOption(Color? color, String tooltip) {
    final theme = Theme.of(context);
    final isSelected = widget.note.color == color;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => ref.read(notesProvider.notifier).updateNote(widget.note.copyWith(color: Wrapped(color))),
            borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? (theme.textTheme.bodyLarge?.color ?? Colors.white) : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected ? Icon(Icons.check, size: 12, color: theme.scaffoldBackgroundColor) : null,
          ),
            ),
          ),
        ),
    );
  }
}

class LinkTextEditingController extends TextEditingController {
  LinkTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final RegExp urlRegex = RegExp(
      r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?',
      caseSensitive: false,
    );

    final List<InlineSpan> children = [];
    int start = 0;

    for (final Match match in urlRegex.allMatches(text)) {
      if (match.start > start) {
        children.add(TextSpan(text: text.substring(start, match.start), style: style));
      }
      final String url = match.group(0)!;
      children.add(
        TextSpan(
          text: url,
          style: style?.copyWith(
            color: Theme.of(context).primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(style: style, children: children);
  }
}
