import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import '../../providers/active_canvas_provider.dart';

import 'controllers/canvas_controller.dart';
import 'controllers/viewport_controller.dart';
import 'models/canvas_document.dart';
import 'models/canvas_node.dart';
import 'widgets/canvas_toolbar.dart';
import 'widgets/infinite_canvas.dart';
import 'widgets/canvas_search_bar.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../providers/boxclock_provider.dart';
import 'package:kaizen/utils/snackbar_utils.dart';

class CanvasEditor extends riverpod.ConsumerStatefulWidget {
  final CanvasDocument document;
  final VoidCallback? onBack;

  const CanvasEditor({
    super.key,
    required this.document,
    this.onBack,
  });

  @override
  riverpod.ConsumerState<CanvasEditor> createState() => _CanvasEditorState();
}

class _CanvasEditorState extends riverpod.ConsumerState<CanvasEditor> {
  late CanvasController _canvasController;
  late ViewportController _viewportController;

  @override
  void initState() {
    super.initState();

    _canvasController = CanvasController(
      document: widget.document,
    );

    _viewportController = ViewportController(
      initialOffset: Offset(
        widget.document.viewportOffsetDx ?? 0,
        widget.document.viewportOffsetDy ?? 0,
      ),
      initialScale: widget.document.viewportScale ?? 1.0,
    );

    // Register controller globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeCanvasControllerProvider.notifier).set(_canvasController);
      }
    });
  }

  @override
  void dispose() {
    // Unregister controller using ref - safely available in dispose for ConsumerState
    try {
      if (ref.read(activeCanvasControllerProvider) == _canvasController) {
        ref.read(activeCanvasControllerProvider.notifier).set(null);
      }
    } catch (_) {
      // ref might already be disposed in some cases, though usually safe in ConsumerState
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.backspace): const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): const DuplicateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ): const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY): const RedoIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DeleteIntent: CanvasEditorAction<DeleteIntent>(
            controller: _canvasController,
            onInvokeAction: _handleDelete,
            requireSelection: true,
          ),
          DuplicateIntent: CanvasEditorAction<DuplicateIntent>(
            controller: _canvasController,
            onInvokeAction: _handleDuplicate,
            requireSelection: true,
          ),
          UndoIntent: CanvasEditorAction<UndoIntent>(
            controller: _canvasController,
            onInvokeAction: _canvasController.undo,
          ),
          RedoIntent: CanvasEditorAction<RedoIntent>(
            controller: _canvasController,
            onInvokeAction: _canvasController.redo,
          ),
        },
        child: Focus(
          autofocus: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _canvasController),
          ChangeNotifierProvider.value(value: _viewportController),
        ],
        child: Consumer<CanvasController>(
          builder: (context, controller, child) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: InfiniteCanvas(
                      canvasController: _canvasController,
                      viewportController: _viewportController,
                    ),
                  ),
                  CanvasToolbar(
                    canvasController: _canvasController,
                    viewportController: _viewportController,
                    onAddNode: _showAddNodeDialog,
                    onBack: widget.onBack ?? () => Navigator.of(context).pop(),
                  ),
                  if (controller.isSearchOpen)
                    const CanvasSearchBar(),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _CanvasQuickActions(
                        onAddText: () {
                          final center = _viewportController.screenToWorld(
                            Offset(MediaQuery.of(context).size.width / 2, 
                                   MediaQuery.of(context).size.height / 2),
                          );
                          _canvasController.addNode(
                            title: '',
                            content: '',
                            type: CanvasNodeType.text,
                            position: center - const Offset(100, 50),
                            size: const Size(200, 100),
                          );
                        },
                        onAddMedia: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'webm', 'mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
                          );
                          
                          if (result != null && result.files.single.path != null) {
                            final ext = result.files.single.extension?.toLowerCase() ?? '';
                            final isAudio = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].contains(ext);
                            final center = _viewportController.screenToWorld(
                              Offset(MediaQuery.of(context).size.width / 2, 
                                     MediaQuery.of(context).size.height / 2),
                            );
                            _canvasController.addNode(
                              title: result.files.single.name,
                              content: result.files.single.path!,
                              type: isAudio ? CanvasNodeType.audio : CanvasNodeType.image,
                              position: center - const Offset(150, 150),
                              size: isAudio ? const Size(320, 160) : const Size(300, 300),
                            );
                          }
                        },
                        onAddAudio: () {
                          SnackbarUtils.showCustomSnackBar(context, 'Live audio capture coming soon');
                        },
                        onAddTask: () {
                          final tasks = ref.read(taskProvider);
                          _showSelectionDialog<Task>(
                            title: 'Select a Task',
                            items: tasks,
                            themeColor: Colors.teal,
                            icon: LucideIcons.checkSquare,
                            labelBuilder: (t) => t.title,
                            subLabelBuilder: (t) => t.description ?? 'No description',
                            onSelected: (task) {
                              final center = _viewportController.screenToWorld(
                                Offset(MediaQuery.of(context).size.width / 2, 
                                       MediaQuery.of(context).size.height / 2),
                              );
                              _canvasController.addNode(
                                title: task.title,
                                content: task.id,
                                type: CanvasNodeType.task,
                                position: center - const Offset(125, 60),
                                size: const Size(250, 120),
                              );
                            },
                          );
                        },
                        onAddGoal: () {
                          final goals = ref.read(boxClockProvider).goals;
                          _showSelectionDialog<LifeGoal>(
                            title: 'Select a Goal',
                            items: goals,
                            themeColor: Colors.orange,
                            icon: LucideIcons.target,
                            labelBuilder: (g) => g.name,
                            subLabelBuilder: (g) => g.category.name,
                            onSelected: (goal) {
                              final center = _viewportController.screenToWorld(
                                Offset(MediaQuery.of(context).size.width / 2, 
                                       MediaQuery.of(context).size.height / 2),
                              );
                              _canvasController.addNode(
                                title: goal.name,
                                content: goal.id,
                                type: CanvasNodeType.goal,
                                position: center - const Offset(130, 55),
                                size: const Size(260, 110),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    ),
    );
  }

  void _showAddNodeDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final theme = Theme.of(context);

    CanvasNodeType selectedType = CanvasNodeType.note;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              shape: theme.dialogTheme.shape,
              title: const Text('Add Node'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: theme.textTheme.bodyLarge,
                      decoration: _inputDecoration('Title', context),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: contentController,
                      maxLines: 5,
                      style: theme.textTheme.bodyLarge,
                      decoration: _inputDecoration('Content', context),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<CanvasNodeType>(
                      value: selectedType,
                      dropdownColor: theme.dialogBackgroundColor,
                      style: theme.textTheme.bodyLarge,
                      decoration: _inputDecoration('Type', context),
                      items: CanvasNodeType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final center = _viewportController.screenToWorld(
                        Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                      );
                      _canvasController.addNode(
                        title: titleController.text,
                        content: contentController.text,
                        type: selectedType,
                        position: center - const Offset(100, 50),
                        size: selectedType == CanvasNodeType.audio ? const Size(320, 160) : const Size(200, 100),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add Node'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint, BuildContext context) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
      ),
      filled: true,
      fillColor: theme.dividerColor.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _handleDelete() {
    _canvasController.deleteSelectedNodes();
  }

  void _handleDuplicate() {
    _canvasController.duplicateSelectedNodes();
  }

  void _showSelectionDialog<T>({
    required String title,
    required List<T> items,
    required Color themeColor,
    required IconData icon,
    required String Function(T) labelBuilder,
    required String Function(T) subLabelBuilder,
    required void Function(T) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredItems = items.where((item) {
              final label = labelBuilder(item).toLowerCase();
              return label.contains(searchQuery.toLowerCase());
            }).toList();
            
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: theme.dialogTheme.backgroundColor ?? theme.dialogBackgroundColor,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: isDark ? 0.3 : 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: themeColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 440,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(LucideIcons.search, color: themeColor),
                        filled: true,
                        fillColor: themeColor.withValues(alpha: isDark ? 0.1 : 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: isDark ? 0.05 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              hoverColor: themeColor.withValues(alpha: 0.05),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: themeColor, size: 20),
                              ),
                              title: Text(
                                labelBuilder(item),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subLabelBuilder(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                onSelected(item);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DuplicateIntent extends Intent {
  const DuplicateIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class CanvasEditorAction<T extends Intent> extends Action<T> {
  final CanvasController controller;
  final void Function() onInvokeAction;
  final bool requireSelection;
  final bool ignoreIfTextFocused;

  CanvasEditorAction({
    required this.controller,
    required this.onInvokeAction,
    this.requireSelection = false,
    this.ignoreIfTextFocused = true,
  });

  @override
  bool isEnabled(T intent) {
    if (requireSelection && controller.selectedNodeIds.isEmpty) return false;
    
    if (ignoreIfTextFocused) {
      final focus = FocusManager.instance.primaryFocus;
      final isTextFocused = focus != null && 
          (focus.context?.widget is EditableText || 
           focus.context?.findAncestorWidgetOfExactType<EditableText>() != null);
           
      if (isTextFocused) return false;
    }
    
    return true;
  }

  @override
  void invoke(T intent) => onInvokeAction();
}

class _CanvasQuickActions extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddMedia;
  final VoidCallback onAddAudio;
  final VoidCallback onAddTask;
  final VoidCallback onAddGoal;

  const _CanvasQuickActions({
    required this.onAddText,
    required this.onAddMedia,
    required this.onAddAudio,
    required this.onAddTask,
    required this.onAddGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.text_fields_rounded,
            label: 'Text',
            onTap: onAddText,
          ),
          const SizedBox(width: 2),
          _ActionButton(
            icon: Icons.image_rounded,
            label: 'Media',
            onTap: onAddMedia,
          ),
          const SizedBox(width: 2),
          _ActionButton(
            icon: Icons.mic_rounded,
            label: 'Audio',
            onTap: onAddAudio,
          ),
          const SizedBox(width: 2),
          _ActionButton(
            icon: Icons.check_box_rounded,
            label: 'Task',
            onTap: onAddTask,
          ),
          const SizedBox(width: 2),
          _ActionButton(
            icon: Icons.flag_rounded,
            label: 'Goal',
            onTap: onAddGoal,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
