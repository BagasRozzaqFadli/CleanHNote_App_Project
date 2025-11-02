import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cleanhnote/services/appwrite_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  late Account _account;
  late models.User _currentUser;

  AuthStatus _status = AuthStatus.uninitialized;
  String _error = '';

  AuthStatus get status => _status;
  models.User get currentUser => _currentUser;
  String get error => _error;

  AuthProvider() {
    _account = Account(AppwriteService.getClient());
    _loadCurrentUser();
  }

  _loadCurrentUser() async {
    try {
      _currentUser = await _account.get();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _account.createEmailPasswordSession(email: email, password: password);
      await _loadCurrentUser();
      return true;
    } on AppwriteException catch (e) {
      _error = e.message ?? 'An error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      await _account.create(userId: ID.unique(), name: name, email: email, password: password);
      return await login(email, password);
    } on AppwriteException catch (e) {
      _error = e.message ?? 'An error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      // Handle error
    } finally {
      notifyListeners();
    }
  }
}
