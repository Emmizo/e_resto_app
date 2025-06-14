abstract class AuthService {
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  // Add more methods as needed
}
