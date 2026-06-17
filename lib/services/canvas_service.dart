import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/canvas/models/canvas_document.dart';

class CanvasService {
  static const String _storageKey = 'kaizen_canvas_projects';

  static Future<List<CanvasDocument>> getProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? projectsJson = prefs.getString(_storageKey);

    if (projectsJson == null || projectsJson.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(projectsJson);
      return decoded.map((item) => CanvasDocument.fromJson(item)).toList();
    } catch (e) {
      print('Error loading canvas projects: $e');
      return [];
    }
  }

  static Future<void> saveProject(CanvasDocument project) async {
    final projects = await getProjects();
    
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
    } else {
      projects.add(project);
    }

    await _saveAll(projects);
  }

  static Future<void> deleteProject(String id) async {
    final projects = await getProjects();
    projects.removeWhere((p) => p.id == id);
    await _saveAll(projects);
  }

  static Future<void> _saveAll(List<CanvasDocument> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(projects.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
