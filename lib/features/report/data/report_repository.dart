import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reportRepositoryProvider = Provider((ref) {
  return ReportRepository(Supabase.instance.client);
});

final myReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  return ref.read(reportRepositoryProvider).fetchMyReports();
});

class ReportModel {
  final String id;
  final String content;
  final DateTime createdAt;

  ReportModel({required this.id, required this.content, required this.createdAt});

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ReportRepository {
  final SupabaseClient _supabase;
  ReportRepository(this._supabase);

  Future<void> submitReport(String content) async {
    final userId = _supabase.auth.currentUser!.id;

    // 1. Write to User's private history
    await _supabase.from('anonymous_reports_user').insert({
      'user_id': userId,
      'content': content,
    });

    // 2. Write to Public/Admin table (Anonymous)
    await _supabase.from('anonymous_reports_public').insert({
      'content': content,
    });
  }

  Future<List<ReportModel>> fetchMyReports() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('anonymous_reports_user')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => ReportModel.fromMap(e)).toList();
  }
}