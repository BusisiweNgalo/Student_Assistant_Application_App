/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: application_viewmodel.
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_model.dart'; 

class ApplicationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ApplicationModel> _applications = [];
  ApplicationModel? _selectedApplication;
  bool _isLoading = false;
  String? _errorMessage;

  List<ApplicationModel> get applications => _applications;
  ApplicationModel? get selectedApplication => _selectedApplication;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


  Future<void> fetchMyApplications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await _supabase
          .from('applications')
          .select()
          .eq('student_id', userId)
          .order('created_at', ascending: false);

      _applications = response
          .map<ApplicationModel>((json) => ApplicationModel.fromJson(json))
          .toList();

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Submit new application
  Future<bool> submitApplication({
    required String title,
    required String description,
    required String type, 
    String? documentUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      await _supabase.from('applications').insert({
        'student_id': userId,
        'title': title,
        'description': description,
        'type': type,
        'document_url': documentUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchMyApplications(); 
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  
  Future<void> fetchApplicationById(String applicationId) async {
    try {
      final response = await _supabase
          .from('applications')
          .select()
          .eq('id', applicationId)
          .single();

      _selectedApplication = ApplicationModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
