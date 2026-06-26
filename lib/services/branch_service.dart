import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/branch.dart';
import '../models/service_model.dart';

class BranchService {
  final SupabaseClient _client;

  BranchService(this._client);

  Future<List<Branch>> getBranches() async {
    final data = await _client
        .from('branches')
        .select()
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<List<Branch>> getAllBranches() async {
    final data = await _client.from('branches').select().order('name');

    return (data as List).map((e) => Branch.fromJson(e)).toList();
  }

  Future<Branch?> getBranch(String branchId) async {
    final data = await _client
        .from('branches')
        .select()
        .eq('id', branchId)
        .maybeSingle();

    if (data == null) return null;
    return Branch.fromJson(data);
  }

  Future<List<ServiceModel>> getServicesForBranch(String branchId) async {
    final data = await _client
        .from('services')
        .select()
        .eq('branch_id', branchId)
        .eq('is_active', true)
        .order('name');

    return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<List<ServiceModel>> getAllServicesForBranch(String branchId) async {
    final data = await _client
        .from('services')
        .select()
        .eq('branch_id', branchId)
        .order('name');

    return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<Branch> createBranch({
    required String name,
    required String address,
    required String contact,
  }) async {
    final data = await _client
        .from('branches')
        .insert({
          'name': name,
          'address': address,
          'contact': contact,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return Branch.fromJson(data);
  }

  Future<void> updateBranch({
    required String id,
    required String name,
    required String address,
    required String contact,
  }) async {
    await _client.from('branches').update({
      'name': name,
      'address': address,
      'contact': contact,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> toggleBranch(String id, bool isActive) async {
    await _client.from('branches').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  Future<ServiceModel> createService({
    required String branchId,
    required String name,
    required String description,
    required int avgServiceTime,
  }) async {
    final data = await _client
        .from('services')
        .insert({
          'branch_id': branchId,
          'name': name,
          'description': description,
          'avg_service_time': avgServiceTime,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return ServiceModel.fromJson(data);
  }

  Future<void> updateService({
    required String id,
    required String name,
    required String description,
    required int avgServiceTime,
  }) async {
    await _client.from('services').update({
      'name': name,
      'description': description,
      'avg_service_time': avgServiceTime,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> toggleService(String id, bool isActive) async {
    await _client.from('services').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _client.from('services').delete().eq('id', id);
  }
}
