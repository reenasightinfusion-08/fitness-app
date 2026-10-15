import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:fitness_app/core/config/api_config.dart';
import 'package:fitness_app/services/apple_auth_service.dart';
import 'package:fitness_app/services/google_auth_service.dart';

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

  static const _tokenKey = 'auth_token';
  static const _onboardedKey = 'onboarding_complete';

  static Future<String> _getHost() async => ApiConfig.baseUrl;

  static Future<String> _getBaseUrl() async => '${await _getHost()}/api/auth';

  final _storage = const FlutterSecureStorage();
  final _googleAuth = GoogleAuthService();
  final _appleAuth = AppleAuthService();

  /// Called after the server rejects the saved token (expired, or the password
  /// was changed on another device), once it has been cleared from this phone.
  void Function()? onSessionExpired;

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

  /// Signs in through Google. Returns false if the user dismissed the account
  /// picker, true once the backend has issued a session. With [isSignup] the
  /// backend refuses a Google account that already has an account.
  Future<bool> loginWithGoogle({bool isSignup = false}) async {
    final idToken = await _googleAuth.getIdToken();
    if (idToken == null) return false;
    final data = await _post('/google', {
      'idToken': idToken,
      if (isSignup) 'intent': 'signup',
    });
    await _storage.write(key: _tokenKey, value: data['token'] as String);
    return true;
  }

  /// Signs in through Sign in with Apple (iOS). Returns false if the user
  /// dismissed the Apple sheet, true once the backend has issued a session.
  Future<bool> loginWithApple() async {
    final credential = await _appleAuth.getCredential();
    if (credential == null) return false;
    final data = await _post('/apple', {
      'identityToken': credential.identityToken,
      'nonce': credential.nonce,
      if (credential.name != null) 'name': credential.name,
    });
    await _storage.write(key: _tokenKey, value: data['token'] as String);
    return true;
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

  /// Checks a reset code without using it up.
  Future<void> verifyResetCode({required String email, required String code}) =>
      _post('/verify-reset-code', {'email': email, 'code': code});

  /// Changes the signed-in user's password; the server checks [currentPassword].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _reachable(() async {
    final data = await _authedPost('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    // Changing the password revokes old tokens; the server sends a fresh one.
    final token = data['token'];
    if (token is String) await _storage.write(key: _tokenKey, value: token);
  });

  Future<bool> hasSession() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _onboardedKey);
    await _googleAuth.signOut();
  }

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
    if (!await hasSession()) return; // nothing to delete without an account
    await _authedDelete('/users/me');
    await logout();
  });

  Future<Map<String, dynamic>> getMe() async {
    final me = await _authedGet('/users/me');
    await _rememberOnboarding(me);
    return me;
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> updates) async {
    final me = await _authedPatch('/users/me', updates);
    await _rememberOnboarding(me);
    return me;
  }

  /// Whether this phone has seen the account finish setup. Lets a returning
  /// user reach Home when the profile can't be fetched (offline at launch).
  Future<bool> onboardingCompleteCached() async =>
      (await _storage.read(key: _onboardedKey)) == 'true';

  Future<void> _rememberOnboarding(Map<String, dynamic> me) async {
    final user = (me['user'] ?? me['data'] ?? me);
    if (user is Map && user['onboardingComplete'] == true) {
      await _storage.write(key: _onboardedKey, value: 'true');
    }
  }

  /// A 401 on a signed-in request means the saved token is no longer valid.
  Future<void> _checkSession(http.Response response) async {
    if (response.statusCode != 401) return;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _onboardedKey);
    onSessionExpired?.call();
    throw AuthException('Your session expired. Please sign in again.');
  }

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
    await _checkSession(response);
    return _decode(response);
  }

  Future<List<dynamic>> _authedGetList(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .get(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    await _checkSession(response);
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
    await _checkSession(response);
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
    await _checkSession(response);
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
    await _checkSession(response);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _authedDelete(String path) async {
    final host = await _getHost();
    final auth = await _authHeader();
    if (auth == null) throw AuthException('Not signed in');

    final response = await http
        .delete(Uri.parse('$host/api$path'), headers: {'Authorization': auth})
        .timeout(const Duration(seconds: 10));
    await _checkSession(response);
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
