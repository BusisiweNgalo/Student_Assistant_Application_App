import 'package:flutter/material.dart';
import 'package:sa_apply/models/application_model.dart';
import 'package:sa_apply/services/application_service.dart';

enum ApplicationStatus { initial, loading, loaded, error }

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  ApplicationStatus _status = ApplicationStatus.initial;
  List<ApplicationModel> _applications = [];
  String? _errorMessage;

  ApplicationStatus get status => _status;
  List<ApplicationModel> get applications => _applications;
  String? get errorMessage => _errorMessage;
  bool get hasApplication => _applications.isNotEmpty;

  Future<void> fetchMyApplications() async {
    _status = ApplicationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await _service.getMyApplications();
      _status = ApplicationStatus.loaded;
    } catch (e) {
      _status = ApplicationStatus.error;
      _errorMessage = 'Failed to load applications.';
    }
    notifyListeners();
  }

  Future<bool> submitApplication(ApplicationModel application) async {
    try {
      final created = await _service.createApplication(application);
      _applications.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit application.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateApplication(
      String id, Map<String, dynamic> updates) async {
    try {
      final updated = await _service.updateApplication(id, updates);
      final index = _applications.indexWhere((a) => a.id == id);
      if (index != -1) {
        _applications[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update application.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteApplication(String id) async {
    try {
      await _service.deleteApplication(id);
      _applications.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete application.';
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _applications = [];
    _status = ApplicationStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}

