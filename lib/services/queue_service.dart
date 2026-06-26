import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/queue_token.dart';

class QueueStats {
  final int tokensToday;
  final int currentlyServing;
  final int inQueue;
  final double avgWaitMinutes;

  const QueueStats({
    this.tokensToday = 0,
    this.currentlyServing = 0,
    this.inQueue = 0,
    this.avgWaitMinutes = 0,
  });
}

class QueueService {
  final SupabaseClient _client;

  QueueService(this._client);

  Future<QueueToken> generateToken({
    required String serviceId,
    required String branchId,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // Get current queue count for token number
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final countResult = await _client
        .from('tokens')
        .select('id')
        .eq('branch_id', branchId)
        .eq('service_id', serviceId)
        .gte('created_at', '${todayStr}T00:00:00');

    final count = (countResult as List).length;
    final tokenNumber = 'T${(count + 1).toString().padLeft(3, '0')}';

    // Get current position
    final waitingResult = await _client
        .from('tokens')
        .select('id')
        .eq('branch_id', branchId)
        .eq('service_id', serviceId)
        .eq('status', 'waiting');

    final position = (waitingResult as List).length + 1;

    // Get service info for estimated wait
    final serviceData = await _client
        .from('services')
        .select('name, avg_service_time, branches(name)')
        .eq('id', serviceId)
        .single();

    final avgTime = serviceData['avg_service_time'] as int? ?? 10;

    final data = await _client
        .from('tokens')
        .insert({
          'user_id': userId,
          'service_id': serviceId,
          'branch_id': branchId,
          'token_number': tokenNumber,
          'position': position,
          'status': 'waiting',
          'estimated_wait_minutes': position * avgTime,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select(
          '*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)',
        )
        .single();

    return QueueToken.fromJson(data);
  }

  Future<List<QueueToken>> getUserActiveTokens() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('user_id', userId)
        .inFilter('status', ['waiting', 'called', 'serving'])
        .order('created_at', ascending: false);

    return (data as List).map((e) => QueueToken.fromJson(e)).toList();
  }

  Future<List<QueueToken>> getUserTokenHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((e) => QueueToken.fromJson(e)).toList();
  }

  Future<QueueToken?> getToken(String tokenId) async {
    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('id', tokenId)
        .maybeSingle();

    if (data == null) return null;
    return QueueToken.fromJson(data);
  }

  Future<void> cancelToken(String tokenId) async {
    await _client.from('tokens').update({
      'status': 'cancelled',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', tokenId);
  }

  Future<List<QueueToken>> getQueueForService(String serviceId) async {
    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('service_id', serviceId)
        .inFilter('status', ['waiting', 'called', 'serving'])
        .order('position', ascending: true);

    return (data as List).map((e) => QueueToken.fromJson(e)).toList();
  }

  Future<QueueToken?> callNextToken(String serviceId) async {
    // Complete current serving token
    await _client
        .from('tokens')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('service_id', serviceId)
        .inFilter('status', ['called', 'serving']);

    // Get next waiting token
    final nextData = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('service_id', serviceId)
        .eq('status', 'waiting')
        .order('position', ascending: true)
        .limit(1)
        .maybeSingle();

    if (nextData == null) return null;

    // Update to called
    final updated = await _client
        .from('tokens')
        .update({
          'status': 'called',
          'called_at': DateTime.now().toIso8601String(),
        })
        .eq('id', nextData['id'])
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .single();

    return QueueToken.fromJson(updated);
  }

  Future<void> skipToken(String tokenId) async {
    await _client.from('tokens').update({
      'status': 'skipped',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', tokenId);
  }

  Future<void> completeToken(String tokenId) async {
    await _client.from('tokens').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', tokenId);
  }

  Future<void> serveToken(String tokenId) async {
    await _client.from('tokens').update({
      'status': 'serving',
    }).eq('id', tokenId);
  }

  Future<QueueToken?> getCurrentServing(String serviceId) async {
    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('service_id', serviceId)
        .inFilter('status', ['called', 'serving'])
        .order('called_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return QueueToken.fromJson(data);
  }

  Future<List<QueueToken>> getCompletedToday(String serviceId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final data = await _client
        .from('tokens')
        .select('*, services:service_id(name), branches:branch_id(name), profiles:user_id(full_name)')
        .eq('service_id', serviceId)
        .eq('status', 'completed')
        .gte('created_at', '${todayStr}T00:00:00')
        .order('completed_at', ascending: false);

    return (data as List).map((e) => QueueToken.fromJson(e)).toList();
  }

  Future<QueueStats> getQueueStats() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final allToday = await _client
        .from('tokens')
        .select('id, status, created_at, called_at')
        .gte('created_at', '${todayStr}T00:00:00');

    final tokens = allToday as List;
    final tokensToday = tokens.length;
    final currentlyServing =
        tokens.where((t) => t['status'] == 'called' || t['status'] == 'serving').length;
    final inQueue = tokens.where((t) => t['status'] == 'waiting').length;

    // Calculate avg wait
    double avgWait = 0;
    final completedWithWait = tokens.where(
        (t) => t['status'] == 'completed' && t['called_at'] != null);
    if (completedWithWait.isNotEmpty) {
      double totalWait = 0;
      for (final t in completedWithWait) {
        final created = DateTime.parse(t['created_at']);
        final called = DateTime.parse(t['called_at']);
        totalWait += called.difference(created).inMinutes;
      }
      avgWait = totalWait / completedWithWait.length;
    }

    return QueueStats(
      tokensToday: tokensToday,
      currentlyServing: currentlyServing,
      inQueue: inQueue,
      avgWaitMinutes: avgWait,
    );
  }

  RealtimeChannel subscribeToToken(
    String tokenId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _client
        .channel('token_$tokenId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'tokens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tokenId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToServiceQueue(
    String serviceId,
    void Function() onUpdate,
  ) {
    return _client
        .channel('service_queue_$serviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tokens',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'service_id',
            value: serviceId,
          ),
          callback: (_) {
            onUpdate();
          },
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
