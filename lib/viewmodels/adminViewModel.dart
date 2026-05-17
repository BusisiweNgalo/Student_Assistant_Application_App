import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/application_model.dart';

class AdminViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<UserModel> _students = [];
  List<ApplicationModel> _allApplications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get students => _students;
  List<ApplicationModel> get allApplications => _allApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch all students
  Future<void> fetchAllStudents() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'student')
          .order('full_name');

      _students = response
          .map<UserModel>((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all applications (for admin)
  Future<void> fetchAllApplications({String? statusFilter}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      var query = _supabase
          .from('applications')
          .select('*, profiles!student_id(full_name, student_number)')
          .order('created_at', ascending: false);

      if (statusFilter != null) {
        query = query.eq('status', statusFilter);
      }

      final response = await query;

      _allApplications = response
          .map<ApplicationModel>((json) => ApplicationModel.fromJson(json))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Approve / Reject Application
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String newStatus, // 'approved' or 'rejected'
    String? remarks,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _supabase.from('applications').update({
        'status': newStatus,
        'remarks': remarks,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': _supabase.auth.currentUser?.id,
      }).eq('id', applicationId);

      await fetchAllApplications(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Change student role (if needed)
  Future<bool> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      await fetchAllStudents();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
