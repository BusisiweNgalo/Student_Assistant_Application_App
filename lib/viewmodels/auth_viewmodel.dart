/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: auth_viewmodel.
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Listen to auth state changes 
  AuthViewModel() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.userUpdated) {
        await loadCurrentUser();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  // ==================== SIGN UP ====================
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
    required int yearOfStudy,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        _errorMessage = 'Registration failed. Please try again.';
        return false;
      }

      // Create user profile in profiles table
      await _createProfile(
        userId: response.user!.id,
        email: email.trim(),
        fullName: fullName,
        studentNumber: studentNumber,
        yearOfStudy: yearOfStudy,
      );

      // Handle email confirmation
      if (response.session == null) {
        _errorMessage = 'Registration successful! Please check your email to verify your account.';
        return true; 
      } else {
        await loadCurrentUser();
        return true;
      }
    } catch (e) {
      _errorMessage = _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SIGN IN ====================
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      await loadCurrentUser();
      return true;
    } catch (e) {
      _errorMessage = _handleError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== HELPER METHODS ====================
  Future<void> _createProfile({
    required String userId,
    required String email,
    required String fullName,
    required String studentNumber,
    required int yearOfStudy,
  }) async {
    await _supabase.from('profiles').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'student_number': studentNumber,
      'year_of_study': yearOfStudy,
      'role': 'student',
    });
  }

  Future<void> loadCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _handleError(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }
}
