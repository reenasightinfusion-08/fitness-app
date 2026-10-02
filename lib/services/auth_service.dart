import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Thrown for any auth failure the UI should show as-is (bad credentials,
/// wrong code, unreachable server, etc).
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to the fitness-backend Express API and holds the JWT it hands
/// back in secure storage.
class AuthService {
  AuthService();

  /// Android emulator reaches the host machine at 10.0.2.2. On a physical
  /// device swap this for your computer's LAN IP (see backend/README.md);
  /// on the iOS simulator `localhost` works.
  static const _tokenKey = 'auth_token';

  /// Candidate addresses:
  /// - Live Vercel production backend (24/7 online)
  /// - 127.0.0.1:4000 (physical Android device with `adb reverse`, or desktop)
  /// - 10.0.2.2:4000 (standard Android Studio emulator)
  /// - 192.168.29.88:4000 (local Wi-Fi IP for physical phones without USB reverse)
  /// - localhost:4000 (desktop / web / iOS simulator)
  static const String _liveProductionHost =
      'https://fitness-backend-eight.vercel.app';

  static const List<String> _candidateHosts = [
    _liveProductionHost,
    'http://127.0.0.1:4000',
    'http://10.0.2.2:4000',
    'http://192.168.29.88:4000',
    'http://localhost:4000',
  ];

  static String? _resolvedHost;

  static Future<String> _getHost() async {
    if (_resolvedHost != null) return _resolvedHost!;

    for (final host in _candidateHosts) {
      try {
        final timeout = host.startsWith('https://')
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 800);
        final res = await http.get(Uri.parse('$host/health')).timeout(timeout);
        if (res.statusCode == 200) {
          debugPrint('[AuthService] Connected to backend at $host');
          _resolvedHost = host;
          return host;
        }
      } catch (e) {
        debugPrint('[AuthService] Probe to $host: $e');
      }
    }

    _resolvedHost = _liveProductionHost;
    debugPrint(
      '[AuthService] Defaulting to live production at $_liveProductionHost',
    );
    return _liveProductionHost;
  }

  static Future<String> _getBaseUrl() async => '${await _getHost()}/api/auth';

  final _storage = const FlutterSecureStorage();

  Future<void> signup({required String email, required String password}) =>
      _post('/signup', {'email': email, 'password': password});

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _post('/verify-email', {'email': email, 'code': code});
    await _storage.write(key: _tokenKey, value: data['token'] as String);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _post('/login', {'email': email, 'password': password});
    await _storage.write(key: _tokenKey, value: data['token'] as String);
  }

  Future<void> forgotPassword({required String email}) =>
      _post('/forgot-password', {'email': email});

  Future<void> resendCode({required String email, required String purpose}) =>
      _post('/resend-code', {'email': email, 'purpose': purpose});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _post('/reset-password', {
    'email': email,
    'code': code,
    'newPassword': newPassword,
  });

  Future<bool> hasSession() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<void> logout() => _storage.delete(key: _tokenKey);

  /// The saved stretch reminders, each `{ time: {hour, minute}, isOn, days }`.
  Future<List<dynamic>> getReminders() => _reachable(() async {
    final data = await _authedGet('/users/me/reminders');
    return (data['reminders'] as List?) ?? <dynamic>[];
  });

  /// Replaces the saved reminders with [reminders] (their `toJson()` maps).
  Future<void> saveReminders(List<Map<String, dynamic>> reminders) =>
      _reachable(() async {
        await _authedPut('/users/me/reminders', {'reminders': reminders});
      });

  /// Stretches the user marked as painful, each `{ stretch: id, name }`.
  Future<List<dynamic>> getHurtStretches() => _reachable(() async {
    final me = await _authedGet('/users/me');
    return (me['hurtStretches'] as List?) ?? <dynamic>[];
  });

  Future<void> addHurtStretch(String stretchId) => _reachable(() async {
    await _authedPut('/users/me/hurt-stretches/$stretchId');
  });

  Future<void> removeHurtStretch(String stretchId) => _reachable(() async {
    await _authedDelete('/users/me/hurt-stretches/$stretchId');
  });

  /// Permanently deletes the signed-in account and all its data on the server,
  /// then signs out on this phone. Throws [AuthException] if it couldn't be
  /// deleted, in which case the user stays signed in.
  Future<void> deleteAccount() => _reachable(() async {
    if (!await hasSession()) return; // the sample account has nothing saved
    await _authedDelete('/users/me');
    await logout();
  });

  Future<Map<String, dynamic>> getMe() => _authedGet('/users/me');

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) =>
      _authedPatch('/users/me', updates);

  /// Today's routine for the signed-in user, picked by the server from the
  /// profile saved during onboarding.
  ///
  /// Sends the phone's local date and UTC offset so "today" (and "done
  /// today") follow the user's clock rather than the server's. Throws
  /// [AuthException] with the server's reason, e.g. when no routine is safe
  /// for the profile, or when the server can't be reached.
  Future<Map<String, dynamic>> getTodaysPlan() async {
    final now = DateTime.now();
    final date = now.toIso8601String().substring(0, 10);
    try {
      return await _authedGet(
        '/plans/today?date=$date&tzOffset=${now.timeZoneOffset.inMinutes}',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] today\'s plan request failed: $e');
      _resolvedHost = null;
      throw AuthException("Couldn't reach the server. Check your connection.");
    }
  }

  /// Runs a signed-in request and turns a network failure into the same
  /// friendly [AuthException] as the other calls, so screens handle one error type.
  Future<T> _reachable<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] request failed: $e');
      _resolvedHost = null;
      throw AuthException("Couldn't reach the server. Check your connection.");
    }
  }

  /// The plan behind today's routine: how many days it has and the routine for
  /// each. Same `date` / `tzOffset` as [getTodaysPlan].
  Future<Map<String, dynamic>> getPlanOverview() {
    final now = DateTime.now();
    final date = now.toIso8601String().substring(0, 10);
    return _reachable(
      () => _authedGet(
        '/plans/overview?date=$date&tzOffset=${now.timeZoneOffset.inMinutes}',
      ),
    );
  }

  /// Begins a routine so it can be resumed later. [source] is 'plan' when the
  /// user started it from today's plan, which is what marks the plan as done.
  Future<void> beginRoutine({
    required String routineId,
    required String routineType,
    required String source,
  }) => _reachable(() async {
    await _authedPost('/active-routines', {
      'routineId': routineId,
      'routineType': routineType,
      'source': source,
    });
  });

  /// Routines the user began and hasn't finished, each with its stretches and
  /// how far they got.
  Future<List<dynamic>> getCurrentRoutines() =>
      _reachable(() => _authedGetList('/active-routines/current'));

  /// Completed routines for the signed-in user, newest first. Each entry has
  /// no `stretches` field — the server strips it so history stays small.
  Future<List<dynamic>> getRoutineHistory() =>
      _reachable(() => _authedGetList('/active-routines/history'));

  /// Saves how many stretches are done; reaching the total completes the routine.
  Future<void> saveRoutineProgress(String id, int completedStretch) =>
      _reachable(() async {
        await _authedPatch('/active-routines/$id/progress', {
          'completedStretch': completedStretch,
        });
      });

  /// The signed-in user's own routines, newest first, each with its stretches
  /// populated.
  Future<List<dynamic>> getCustomRoutines() =>
      _reachable(() => _authedGetList('/custom-routines'));

  /// Saves a routine built in the routine builder. The server replies with no
  /// data, so fetch the list again to get the stored record.
  Future<void> createCustomRoutine(Map<String, dynamic> routine) =>
      _reachable(() async {
        await _authedPost('/custom-routines', routine);
      });

  /// Ids of the routines the user favourited, oldest first. The profile stores
  /// each as `{ routineId, routineType }`.
  Future<List<String>> getFavorites() => _reachable(() async {
    final me = await _authedGet('/users/me');
    return [
      for (final entry in me['favorites'] as List? ?? const [])
        if (entry is Map) entry['routineId'] as String else entry as String,
    ];
  });

  /// Adds [routineId] (a library or custom routine) to the user's favorites.
  Future<void> addFavorite(String routineId) => _reachable(() async {
    await _authedPut('/users/me/favorites/$routineId');
  });

  Future<void> removeFavorite(String routineId) => _reachable(() async {
    await _authedDelete('/users/me/favorites/$routineId');
  });

  /// Permanently deletes one of the user's routines.
  Future<void> deleteCustomRoutine(String id) => _reachable(() async {
    await _authedDelete('/custom-routines/$id');
  });

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final baseUrl = await _getBaseUrl();
    final url = '$baseUrl$path';
    debugPrint('[AuthService] POST $url');

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[AuthService] request to $url failed: $e');
      _resolvedHost = null;
      throw AuthException("Couldn't reach the server. Check your connection.");
    }

    debugPrint('[AuthService] Response status: ${response.statusCode}');

    return _decode(response);
  }

  Future<String?> _authHeader() async {
    final token = await _storage.read(key: _tokenKey);
    return token == null ? null : 'Bearer $token';
  }

  Future<Map<String, dynamic>> _authedGet(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .get(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<List<dynamic>> _authedGetList(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .get(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    return (_data(response) as List?) ?? <dynamic>[];
  }

  Future<Map<String, dynamic>> _authedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .post(
          Uri.parse('$host/api$path'),
          headers: {'Content-Type': 'application/json', 'Authorization': auth},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _authedPatch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .patch(
          Uri.parse('$host/api$path'),
          headers: {'Content-Type': 'application/json', 'Authorization': auth},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _authedPut(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .put(
          Uri.parse('$host/api$path'),
          headers: {
            'Authorization': auth,
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  Future<Map<String, dynamic>> _authedDelete(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .delete(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    return _decode(response);
  }

  /// Every endpoint replies `{ success, message, data }`. Returns `data`
  /// as a map (empty when null) and throws [AuthException] with `message`
  /// on failure.
  Map<String, dynamic> _decode(http.Response response) =>
      (_data(response) as Map<String, dynamic>?) ?? <String, dynamic>{};

  /// The raw `data` of a reply (a map, a list or null), after the same error check.
  Object? _data(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] == false) {
      final message = body['message'] as String? ?? 'Something went wrong';
      debugPrint('[AuthService] Server returned error: $message');
      throw AuthException(message);
    }
    return body['data'];
  }
}
