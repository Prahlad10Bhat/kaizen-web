import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/canvas_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_context_menu.dart';
import 'models/canvas_document.dart';

class CanvasDashboard extends ConsumerStatefulWidget {
  final bool isActive;
  final Function(CanvasDocument) onSelectProject;
  final Function(CanvasDocument, String) onRenameProject;
  final Function(String) onDeleteProject;
  final VoidCallback onCreateNew;

  const CanvasDashboard({
    super.key,
    required this.isActive,
    required this.onSelectProject,
    required this.onRenameProject,
    required this.onDeleteProject,
    required this.onCreateNew,
  });

  @override
  ConsumerState<CanvasDashboard> createState() => _CanvasDashboardState();
}

class _CanvasDashboardState extends ConsumerState<CanvasDashboard> {
  List<CanvasDocument> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void didUpdateWidget(CanvasDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await CanvasService.getProjects();
    
    // Sort pinned first, then by updatedAt
    projects.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 40),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _projects.isEmpty
                      ? _buildEmptyState(context)
                      : _buildProjectGrid(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Canvas Projects',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showSettingsDialog(context),
                  icon: Icon(LucideIcons.settings, size: 20, color: theme.textTheme.labelLarge?.color),
                  tooltip: 'Settings & Controls',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your visual workspaces and diagrams',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                fontSize: 16,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: widget.onCreateNew,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('New Project'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final settings = ref.watch(settingsProvider);
          
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.dialogTheme.backgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Canvas Controls', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(LucideIcons.x, size: 20, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildHelpItem(context, LucideIcons.gitCommit, 'Linking', 'Drag from a node\'s handle to connect to another node'),
                    const SizedBox(height: 16),
                    _buildHelpItem(context, LucideIcons.move, 'Panning', 'Right-click and drag to pan around the canvas'),
                    const SizedBox(height: 16),
                    _buildHelpItem(context, LucideIcons.imagePlus, 'Media', 'Embed images and audio nodes directly'),
                    const SizedBox(height: 32),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 24),
                    Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
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
                                const SizedBox(width: 12),
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
                    const SizedBox(height: 32),
                    Center(child: Text('Kaizen Canvas v1.0', style: TextStyle(color: theme.textTheme.labelLarge?.color, fontSize: 11))),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    return Padding(
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.layoutGrid,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No projects yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first canvas to start visualizing ideas',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: widget.onCreateNew,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.1,
      ),
      itemCount: _projects.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildCreateNewCard(context);
        }
        return _buildProjectCard(context, _projects[index - 1]);
      },
    );
  }

  Widget _buildCreateNewCard(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onCreateNew,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'New Project',
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameProject(CanvasDocument project) async {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: project.name);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Canvas'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new name',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != project.name) {
      await CanvasService.saveProject(project.copyWith(name: newName, updatedAt: DateTime.now()));
      widget.onRenameProject(project, newName);
      _loadProjects();
    }
  }

  Future<void> _deleteProject(CanvasDocument project) async {
    final theme = Theme.of(context);
    final settings = ref.read(settingsProvider);
    
    if (!settings.askBeforeDelete) {
      await CanvasService.deleteProject(project.id);
      widget.onDeleteProject(project.id);
      _loadProjects();
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
            title: Text('Delete Project', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this project? This action cannot be undone.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 24),
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
                        const SizedBox(width: 8),
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
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    if (confirm == true) {
      await CanvasService.deleteProject(project.id);
      widget.onDeleteProject(project.id);
      _loadProjects();
    }
  }

  void _showContextMenu(BuildContext context, Offset position, CanvasDocument project) {
    showCustomContextMenu(
      context: context,
      position: position,
      items: [
        CustomContextMenuItem(
          icon: project.isPinned ? LucideIcons.pinOff : LucideIcons.pin,
          label: project.isPinned ? 'Unpin' : 'Pin',
          onTap: () async {
            await CanvasService.saveProject(project.copyWith(isPinned: !project.isPinned));
            _loadProjects();
          },
        ),
        CustomContextMenuItem(
          icon: LucideIcons.edit3,
          label: 'Rename',
          onTap: () => Future.microtask(() => _renameProject(project)),
        ),
        CustomContextMenuItem(
          icon: LucideIcons.trash2,
          label: 'Delete',
          isDestructive: true,
          onTap: () => Future.microtask(() => _deleteProject(project)),
        ),
      ],
    );
  }

  Widget _buildProjectCard(BuildContext context, CanvasDocument project) {
    final theme = Theme.of(context);
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition, project);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: project.isPinned 
              ? Colors.amber.withValues(alpha: 0.3) 
              : theme.dividerColor.withValues(alpha: 0.08),
            width: project.isPinned ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => widget.onSelectProject(project),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          LucideIcons.layoutGrid,
                          color: theme.colorScheme.primary.withValues(alpha: 0.05),
                          size: 48,
                        ),
                      ),
                      if (project.isPinned)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Icon(Icons.push_pin, size: 16, color: Colors.amber.withValues(alpha: 0.7)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _renameProject(project),
                          borderRadius: BorderRadius.circular(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Updated ${project.updatedAt.day}/${project.updatedAt.month}/${project.updatedAt.year}',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.35),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Builder(
                        builder: (buttonContext) {
                          return IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () {
                              final RenderBox button = buttonContext.findRenderObject() as RenderBox;
                              final RenderBox overlay = Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
                              final Offset position = button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay);
                              _showContextMenu(
                                buttonContext,
                                position,
                                project,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

