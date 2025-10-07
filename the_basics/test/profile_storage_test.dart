import 'package:flutter_test/flutter_test.dart';
import 'package:the_basics/utils/profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ProfileStorage Tests', () {
    test('should save and retrieve pending profile', () async {
      // Test data
      final testProfile = {
        'email': 'test@example.com',
        'username': 'testuser',
        'first_name': 'John',
        'last_name': 'Doe',
        'contact_no': '09123456789',
        'date_of_birth': '1990-01-01',
      };

      // Save profile
      await ProfileStorage.savePendingProfile(testProfile);

      // Retrieve profile
      final retrieved = await ProfileStorage.getPendingProfile();

      // Verify
      expect(retrieved, isNotNull);
      expect(retrieved!['email'], equals('test@example.com'));
      expect(retrieved['username'], equals('testuser'));
      expect(retrieved['first_name'], equals('John'));
      expect(retrieved['last_name'], equals('Doe'));
      expect(retrieved['contact_no'], equals('09123456789'));
      expect(retrieved['date_of_birth'], equals('1990-01-01'));

      // Clean up
      await ProfileStorage.clearPendingProfile();
      final cleared = await ProfileStorage.getPendingProfile();
      expect(cleared, isNull);
    });

    test('should return null when no pending profile exists', () async {
      // Clear any existing data
      await ProfileStorage.clearPendingProfile();

      // Attempt to retrieve
      final retrieved = await ProfileStorage.getPendingProfile();

      // Should be null
      expect(retrieved, isNull);
    });
  });
}