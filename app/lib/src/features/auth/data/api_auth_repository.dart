import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snap_here/src/features/auth/domain/auth_models.dart';
import 'package:snap_here/src/features/auth/domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    http.Client? client,
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<AuthSession> exchangeGoogleCredential(
    GoogleIdentityCredential credential,
  ) async {
    final json = await _post('/v1/auth/google', {
      'idToken': credential.idToken,
    });
    return AuthSession.fromJson(json);
  }

  @override
  Future<AuthSession> completeProfile({
    required String accessToken,
    required ProfileSubmission submission,
  }) async {
    final json = await _post(
      '/v1/profile',
      submission.toJson(),
      accessToken: accessToken,
    );
    return AuthSession.fromJson(json);
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    final json = await _post('/v1/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthSession.fromJson(json);
  }

  @override
  Future<void> signOut(String accessToken) async {
    await _post('/v1/auth/logout', const {}, accessToken: accessToken);
  }

  @override
  Future<void> deleteAccount(String accessToken) async {
    await _delete('/v1/account', accessToken: accessToken);
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body, {
    String? accessToken,
  }) async {
    _ensureConfigured();
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'content-type': 'application/json',
            'accept': 'application/json',
            if (accessToken != null) 'authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  Future<Map<String, Object?>> _delete(
    String path, {
    required String accessToken,
  }) async {
    _ensureConfigured();
    final response = await _client
        .delete(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'accept': 'application/json',
            'authorization': 'Bearer $accessToken',
          },
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  Map<String, Object?> _decodeResponse(http.Response response) {
    Map<String, Object?> body = const {};
    if (response.body.isNotEmpty) {
      try {
        body = Map<String, Object?>.from(jsonDecode(response.body) as Map);
      } on FormatException {
        throw const AuthFailure('서버 응답 형식이 올바르지 않습니다.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure(
        body['message'] as String? ??
            '요청을 처리하지 못했습니다. (${response.statusCode})',
      );
    }
    return body;
  }

  void _ensureConfigured() {
    if (_baseUrl.isEmpty) {
      throw const AuthFailure('API_BASE_URL이 설정되지 않았습니다.');
    }
  }
}

class ApiLegalDocumentRepository implements LegalDocumentRepository {
  ApiLegalDocumentRepository({
    http.Client? client,
    String baseUrl = const String.fromEnvironment('API_BASE_URL'),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<LegalDocument> fetch(LegalDocumentType type) async {
    if (_baseUrl.isEmpty) {
      throw const AuthFailure('API_BASE_URL이 설정되지 않았습니다.');
    }
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/v1/legal/${type.path}'),
          headers: const {'accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthFailure('약관 문서를 불러오지 못했습니다. (${response.statusCode})');
    }
    try {
      final json = Map<String, Object?>.from(jsonDecode(response.body) as Map);
      final sections = (json['sections']! as List)
          .map((section) => Map<String, Object?>.from(section as Map))
          .map(
            (section) => LegalSection(
              heading: section['heading']! as String,
              body: section['body']! as String,
            ),
          )
          .toList(growable: false);
      return LegalDocument(
        type: type,
        title: json['title']! as String,
        version: json['version']! as String,
        effectiveDate: DateTime.parse(json['effectiveDate']! as String),
        sections: sections,
      );
    } on Object {
      throw const AuthFailure('약관 문서 응답 형식이 올바르지 않습니다.');
    }
  }
}
