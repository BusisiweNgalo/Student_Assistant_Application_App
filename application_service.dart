

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sa_apply/models/application_model.dart';

class ApplicationService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _table = 'applications';

  String get _userId => _client.auth.currentUser!.id;

  
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

  
  Future<ApplicationModel?> getApplicationById(String id) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();

    return ApplicationModel.fromMap(response);
  }

  
  Future<ApplicationModel> createApplication(
      ApplicationModel application) async {
    final response = await _client
        .from(_table)
        .insert(application.toMap())
        .select()
        .single();

    return ApplicationModel.fromMap(response);
  }

  
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

    
  Future<void> deleteApplication(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId)
        .eq('status', 'pending');
  }

  
  Future<bool> hasExistingApplication() async {
    final response =
        await _client.from(_table).select('id').eq('user_id', _userId);

    return (response as List).isNotEmpty;
  }

  
  Future<List<ApplicationModel>> getAllApplications() async {
    final response = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((map) => ApplicationModel.fromMap(map))
        .toList();
  }


  Future<void> updateStatus(String id, String status) async {
    await _client.from(_table).update({'status': status}).eq('id', id);
  }

  
  Future<void> adminDeleteApplication(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
