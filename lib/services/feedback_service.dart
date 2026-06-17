import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static final supabase = Supabase.instance.client;

  static Future<void> submitFeedback({
    required String title,
    required String message,
    required String category,
    required int rating,
    String? email,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();

    await supabase.from('feedback').insert({
      'title': title,
      'message': message,
      'category': category,
      'email': email,
      'rating': rating,
      'app_version': packageInfo.version,
      'platform': Platform.operatingSystem,
    });
  }
}
