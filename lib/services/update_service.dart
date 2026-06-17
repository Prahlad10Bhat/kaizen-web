import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateService {
  static const String latestVersionUrl =
      'https://github.com/Prahlad10Bhat/APPUPDATE/releases/latest';

  static const String installerDownloadUrl =
      'https://github.com/Prahlad10Bhat/APPUPDATE/releases/latest/download/KaizenSetup.exe';

  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version.trim().replaceAll('v', '');
  }

  static Future<String?> getLatestVersion() async {
    try {
      final client = HttpClient();

      final request = await client.getUrl(
        Uri.parse(latestVersionUrl),
      );

      request.followRedirects = false;

      final response = await request.close();

      final location =
          response.headers.value(HttpHeaders.locationHeader);

      if (location == null) return null;

      final uri = Uri.parse(location);

      final tag = uri.pathSegments.last.replaceAll('v', '');

      print('LATEST VERSION: $tag');

      return tag;
    } catch (e) {
      print('Version fetch failed: $e');
      return null;
    }
  }

  static bool isVersionOlder(String current, String latest) {
    try {
      final cleanCurrent = current.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');
      final cleanLatest = latest.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');

      // Separate main version and pre-release/build suffix
      final currentMain = cleanCurrent.split(RegExp(r'[-+]')).first;
      final latestMain = cleanLatest.split(RegExp(r'[-+]')).first;

      // Validate that main versions are valid dot-separated integers
      final versionRegex = RegExp(r'^\d+(\.\d+)*$');
      if (!versionRegex.hasMatch(currentMain) || !versionRegex.hasMatch(latestMain)) {
        return false;
      }

      final currentParts = currentMain.split('.').map(int.parse).toList();
      final latestParts = latestMain.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;

        if (c < l) return true;
        if (c > l) return false;
      }

      // If main version parts are equal, compare pre-release suffixes
      final currentHasPre = cleanCurrent.contains('-');
      final latestHasPre = cleanLatest.contains('-');

      if (currentHasPre && !latestHasPre) {
        // e.g. current = 1.0.0-alpha, latest = 1.0.0
        // Stable release is newer than pre-release, so current is older -> return true
        return true;
      } else if (!currentHasPre && latestHasPre) {
        // e.g. current = 1.0.0, latest = 1.0.0-alpha
        // User is on stable, trying to download older/pre-release -> return false
        return false;
      } else if (currentHasPre && latestHasPre) {
        // Both are pre-releases, do lexicographical comparison of the pre-release part
        final currentPre = cleanCurrent.substring(cleanCurrent.indexOf('-') + 1);
        final latestPre = cleanLatest.substring(cleanLatest.indexOf('-') + 1);
        return currentPre.compareTo(latestPre) < 0;
      }

      return false;
    } catch (_) {
      // In case of any unexpected errors, do not allow update (safe fallback)
      return false;
    }
  }

  static bool _isVersionOlder(String current, String latest) =>
      isVersionOlder(current, latest);

  static Future<bool> isUpdateAvailable() async {
    final currentVersion = await getCurrentVersion();
    final latestVersion = await getLatestVersion();

    if (latestVersion == null) return false;

    return _isVersionOlder(currentVersion, latestVersion);
  }

  static Future<void> downloadAndInstallUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      final latestVersion = await getLatestVersion();

      if (latestVersion == null) return;

      if (!_isVersionOlder(currentVersion, latestVersion)) {
        print('Already up to date');
        return;
      }

      final dir = await getTemporaryDirectory();
      final installerPath = '${dir.path}\\KaizenSetup.exe';

      await Dio().download(
        installerDownloadUrl,
        installerPath,
      );

      await Process.start(
        installerPath,
        [
          '/SP-',
          '/VERYSILENT',
          '/SUPPRESSMSGBOXES',
          '/NORESTART',
          '/CLOSEAPPLICATIONS',
          '/RESTARTAPPLICATIONS',
        ],
        mode: ProcessStartMode.detached,
      );

      exit(0);
    } catch (e) {
      print('Update failed: $e');
    }
  }
}
