import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class LeagueGateway {
  Future<bool> initialize();
  bool get signedIn;
  Stream<bool> get authChanges;
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<void> join(String alias, int avatar);
  Future<void> leave();
  Future<Map<String, dynamic>> board();
  Future<Map<String, dynamic>> beginRound();
  Future<Map<String, dynamic>> submit(String id, List<int> choices);
}

class LeagueService implements LeagueGateway {
  static final LeagueService instance = LeagueService._();
  LeagueService._();
  Future<bool>? _initializing;
  SupabaseClient? _client;
  // Keep PKCE storage and callback on the same origin, including PR previews.
  // Supabase still requires this exact URL in its redirect allowlist.
  static String webRedirectFor(Uri location) =>
      '${location.origin}/?league-auth=1';
  static const mobileRedirect =
      'com.sharedbyatt.thaiformyanmar://league-callback/';
  @override
  Stream<bool> get authChanges => client.auth.onAuthStateChange
      .map((event) => event.session != null)
      .distinct();
  @override
  Future<bool> initialize() async {
    try {
      return await (_initializing ??= _initialize());
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  Future<bool> _initialize() async {
    final config =
        jsonDecode(
              await rootBundle.loadString('assets/data/league_config.json'),
            )
            as Map;
    final url = config['url'] as String? ?? '';
    final key = config['publishableKey'] as String? ?? '';
    if (url.isEmpty || key.isEmpty) return false;
    if (Uri.tryParse(url)?.scheme != 'https' ||
        !key.startsWith('sb_publishable_')) {
      throw const FormatException('Invalid public League configuration');
    }
    await Supabase.initialize(url: url, publishableKey: key);
    _client = Supabase.instance.client;
    return true;
  }

  SupabaseClient get client => _client!;
  @override
  bool get signedIn => _client?.auth.currentSession != null;
  @override
  Future<bool> signInWithGoogle() => client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? webRedirectFor(Uri.base) : mobileRedirect,
    scopes: 'openid email profile',
    queryParams: const {'prompt': 'select_account'},
    authScreenLaunchMode: kIsWeb
        ? LaunchMode.platformDefault
        : LaunchMode.externalApplication,
  );

  @override
  Future<void> signOut() => client.auth.signOut();

  @override
  Future<void> join(String alias, int avatar) async {
    await client.rpc(
      'league_join',
      params: {'p_alias': alias.trim(), 'p_avatar': avatar},
    );
  }

  @override
  Future<void> leave() async {
    await client.rpc('league_leave');
  }

  Future<Map<String, dynamic>> _rpc(
    String name, [
    Map<String, dynamic>? params,
  ]) async => Map<String, dynamic>.from(
    await client.rpc(name, params: params).timeout(const Duration(seconds: 20))
        as Map,
  );
  @override
  Future<Map<String, dynamic>> board() => _rpc('league_board');
  @override
  Future<Map<String, dynamic>> beginRound() => _rpc('league_begin_round');
  @override
  Future<Map<String, dynamic>> submit(String id, List<int> choices) =>
      _rpc('league_submit_round', {'p_round': id, 'p_choices': choices});
}
