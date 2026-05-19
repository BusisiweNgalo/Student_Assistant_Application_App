import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sa_apply/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _user;
  String? _userRole;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  String? get userRole => _userRole;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = _authService.currentUser;
    _status =
        _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

    if (_user != null) {
      _fetchRole();
    }

    _authService.authStateChanges.listen((data) {
      _user = data.session?.user;
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      if (_user != null) {
        _fetchRole();
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchRole() async {
    _userRole = await _authService.getUserRole();
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading();
    try {
      final response =
          await _authService.signIn(email: email, password: password);
      if (response.user != null) {
        _user = response.user;
        _userRole = await _authService.getUserRole();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _setError('Login failed. Please try again.');
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
    String role = 'student',
  }) async {
    _setLoading();
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        studentNumber: studentNumber,
        role: role,
      );
      if (response.user != null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }
      _setError('Sign up failed. Please try again.');
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('An unexpected error occurred.');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userRole = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading();
    try {
      await _authService.resetPassword(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
