import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/services/update_service.dart';

void main() {
  group('UpdateService.isVersionOlder', () {
    test('should return true when latest is newer', () {
      expect(UpdateService.isVersionOlder('1.0.0', '1.0.1'), isTrue);
      expect(UpdateService.isVersionOlder('1.0.0', '1.1.0'), isTrue);
      expect(UpdateService.isVersionOlder('1.0.0', '2.0.0'), isTrue);
      expect(UpdateService.isVersionOlder('1.0.11', '1.0.12'), isTrue);
    });

    test('should return false when latest is older', () {
      expect(UpdateService.isVersionOlder('1.0.1', '1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('1.1.0', '1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('2.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('1.0.12', '1.0.11'), isFalse);
    });

    test('should return false when latest is same', () {
      expect(UpdateService.isVersionOlder('1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('1.0.12', '1.0.12'), isFalse);
    });

    test('should handle leading v prefix', () {
      expect(UpdateService.isVersionOlder('v1.0.0', 'v1.0.1'), isTrue);
      expect(UpdateService.isVersionOlder('v1.0.1', 'v1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('1.0.0', 'v1.0.1'), isTrue);
      expect(UpdateService.isVersionOlder('v1.0.0', '1.0.1'), isTrue);
    });

    test('should handle pre-release suffixes', () {
      // pre-release is older than stable
      expect(UpdateService.isVersionOlder('1.0.0-alpha', '1.0.0'), isTrue);
      
      // stable is newer than pre-release, so current stable trying to download pre-release is false
      expect(UpdateService.isVersionOlder('1.0.0', '1.0.0-alpha'), isFalse);
      
      // alpha is older than beta
      expect(UpdateService.isVersionOlder('1.0.0-alpha', '1.0.0-beta'), isTrue);
      
      // beta is newer than alpha, so current beta trying to download alpha is false
      expect(UpdateService.isVersionOlder('1.0.0-beta', '1.0.0-alpha'), isFalse);
    });

    test('should handle format errors or exceptions gracefully by returning false', () {
      expect(UpdateService.isVersionOlder('invalid', '1.0.0'), isFalse);
      expect(UpdateService.isVersionOlder('1.0.0', 'invalid'), isFalse);
      expect(UpdateService.isVersionOlder('invalid', 'invalid'), isFalse);
    });
  });
}
