import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'canvas_dashboard.dart';
import 'canvas_editor.dart';
import 'models/canvas_document.dart';
import '../../services/canvas_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_projects_provider.dart';

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  final List<CanvasDocument> _openDocuments = [];
  String? _activeDocumentId; // null means Dashboard is active

  void _createNewProject() async {
    final controller = TextEditingController(text: 'Untitled Canvas');
    
    final projectName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Canvas Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What would you like to call this canvas?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., Brainstorming',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create Canvas'),
          ),
        ],
      ),
    );

    if (projectName == null || projectName.isEmpty) return;

    final now = DateTime.now();
    final newDocument = CanvasDocument(
      id: 'canvas_${now.microsecondsSinceEpoch}',
      name: projectName,
      nodes: const [],
      edges: const [],
      createdAt: now,
      updatedAt: now,
    );

    await CanvasService.saveProject(newDocument);
    _openProject(newDocument);
  }

  void _openProject(CanvasDocument document) {
    setState(() {
      final existingIndex = _openDocuments.indexWhere((doc) => doc.id == document.id);
      if (existingIndex == -1) {
        _openDocuments.add(document);
      }
      _activeDocumentId = document.id;
    });
  }

  void _closeProject(String id) {
    setState(() {
      _openDocuments.removeWhere((doc) => doc.id == id);
      if (_activeDocumentId == id) {
        _activeDocumentId = _openDocuments.isNotEmpty ? _openDocuments.last.id : null;
      }
    });
  }

  void _handleRenameProject(CanvasDocument project, String newName) {
    setState(() {
      final index = _openDocuments.indexWhere((doc) => doc.id == project.id);
      if (index != -1) {
        _openDocuments[index] = _openDocuments[index].copyWith(name: newName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(selectedCanvasIdProvider, (previous, next) {
      if (next != null && _activeDocumentId != next) {
        final projects = ref.read(canvasProjectsProvider);
        final doc = projects.where((p) => p.id == next).firstOrNull;
        if (doc != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _openProject(doc);
            ref.read(selectedCanvasIdProvider.notifier).set(null);
          });
        }
      }
    });

    final theme = Theme.of(context);
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          if (isDesktop) const SizedBox(height: 32),
          _buildTabBar(context),
          Expanded(
            child: IndexedStack(
              index: _activeDocumentId == null ? 0 : (_openDocuments.indexWhere((doc) => doc.id == _activeDocumentId) + 1),
              children: [
                CanvasDashboard(
                  isActive: _activeDocumentId == null,
                  onSelectProject: _openProject,
                  onRenameProject: _handleRenameProject,
                  onDeleteProject: _closeProject,
                  onCreateNew: _createNewProject,
                ),
                ..._openDocuments.map((doc) {
                  return CanvasEditor(
                    key: ValueKey(doc.id),
                    document: doc,
                    onBack: () => setState(() => _activeDocumentId = null),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildTab(
            context: context,
            title: 'Dashboard',
            icon: LucideIcons.layoutGrid,
            isActive: _activeDocumentId == null,
            onTap: () => setState(() => _activeDocumentId = null),
          ),
          ..._openDocuments.map((doc) => _buildTab(
                context: context,
                title: doc.name,
                icon: LucideIcons.fileCode,
                isActive: _activeDocumentId == doc.id,
                onTap: () => setState(() => _activeDocumentId = doc.id),
                onClose: () => _closeProject(doc.id),
              )),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClose,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? theme.scaffoldBackgroundColor : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            bottom: BorderSide(
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? theme.textTheme.bodyLarge?.color : theme.textTheme.bodySmall?.color,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: isActive 
                        ? theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) 
                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
