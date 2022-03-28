import 'package:oauth2/oauth2.dart';

///Place to store the credentials.
abstract class CredentialsStorage {
  Future<Credentials?> read();
  //Save credentials
  Future<void> save(Credentials credentials);
  //For signing out and clear credentials.
  Future<void> clear();
}
