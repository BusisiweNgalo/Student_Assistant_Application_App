/**
*Student Number: 218009030, 220049798, 220033640, 222057332, 221002961.
*Student Name: TA RASEGO, LONWABO SIFUMBA, BN NGALO, TC LAAT, TC RADEBE.
*Question: application service.
*/

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sa_apply/models/application_model.dart';

class ApplicationService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'applications';

  String get _userId => _client.auth.currentUser!.id;

  // Fetch all applications for the current student
  Future<List<ApplicationModel>> getMyApplications() async {
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((map) => ApplicationModel.fromMap(map))
        .toList();
  }

  // Fetch a single application by id
  Future<ApplicationModel?> getApplicationById(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();

    return ApplicationModel.fromMap(response);
  }

  // Create a new application
  Future<ApplicationModel> createApplication(
      ApplicationModel application) async {
    final response = await _client
        .from(_table)
        .insert(application.toMap())
        .select()
        .single();

    return ApplicationModel.fromMap(response);
  }

  // Update an existing pending application
  Future<ApplicationModel> updateApplication(
      String id, Map<String, dynamic> updates) async {
    final response = await _client
        .from(_table)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId)
        .eq('status', 'pending')
        .select()
        .single();

    return ApplicationModel.fromMap(response);
  }

  // Delete a pending application
  Future<void> deleteApplication(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId)
        .eq('status', 'pending');
  }

  // Check if student already has an application
  Future<bool> hasExistingApplication() async {
    final response =
        await _client.from(_table).select('id').eq('user_id', _userId);

    return (response as List).isNotEmpty;
  }

  // Admin: get all applications
  Future<List<ApplicationModel>> getAllApplications() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((map) => ApplicationModel.fromMap(map))
        .toList();
  }

  // Admin: update application status
  Future<void> updateStatus(String id, String status) async {
    await _client.from(_table).update({'status': status}).eq('id', id);
  }

  // Admin: delete any application
  Future<void> adminDeleteApplication(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
