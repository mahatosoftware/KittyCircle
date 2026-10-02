import 'package:flutter_test/flutter_test.dart';
import 'package:kitty_circle/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository session persistence tests', () {
    test('Unauthenticated session state is false', () {
      final authRepo = AuthRepository();
      expect(authRepo.isUserAuthenticated, isFalse);
    });

    test('signOut sets isUserAuthenticated to false', () async {
      final authRepo = AuthRepository();
      await authRepo.signOut();
      expect(authRepo.isUserAuthenticated, isFalse);
    });

    test('signInWithEmail restores isUserAuthenticated to true', () async {
      final authRepo = AuthRepository();
      await authRepo.signOut();
      expect(authRepo.isUserAuthenticated, isFalse);

      await authRepo.signInWithEmail('test@example.com', 'password123');
      expect(authRepo.isUserAuthenticated, isTrue);
    });
  });
}
