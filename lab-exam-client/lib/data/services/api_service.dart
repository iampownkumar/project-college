// ============================================================
// File: lib/data/services/api_service.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Central HTTP client wrapping all server API calls
//              (health, login, question, sandbox file download,
//               heartbeat, run-log, submission).
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/config_loader.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';

class ApiService {
  String get _base => ConfigLoader.instance.server.baseUrl;

  // ── helpers ──────────────────────────────────────────────

  Uri _uri(String path) => Uri.parse('$_base$path');

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Map<String, dynamic> _decode(http.Response r, String context) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    String detail = r.body;
    try {
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      detail = j['detail']?.toString() ?? detail;
    } catch (_) {}
    throw ApiException('$context failed: $detail', statusCode: r.statusCode);
  }

  // ── public methods ────────────────────────────────────────

  Future<bool> checkHealth() async {
    try {
      final r = await http.get(_uri(ApiConstants.health)).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> payload) async {
    try {
      final r = await http
          .post(_uri(ApiConstants.login), headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));
      return _decode(r, 'Login');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ServerUnreachableException('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAssignedQuestion(String regNo) async {
    try {
      final r = await http
          .get(_uri('${ApiConstants.assignedQuestion}/$regNo'))
          .timeout(const Duration(seconds: 10));
      return _decode(r, 'Question fetch');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw QuestionException('Question fetch error: $e');
    }
  }

  Future<Map<String, dynamic>?> postHeartbeat(Map<String, dynamic> payload) async {
    try {
      final r = await http
          .post(_uri(ApiConstants.heartbeat), headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Heartbeat failures are silent — connectivity badge handles UI.
    }
    return null;
  }

  Future<void> postRunLog(Map<String, dynamic> payload) async {
    try {
      await http
          .post(_uri(ApiConstants.runLog), headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> postSubmission(Map<String, dynamic> payload) async {
    try {
      final r = await http
          .post(_uri(ApiConstants.submission), headers: _headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));
      return _decode(r, 'Submission');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Submission error: $e');
    }
  }

  /// Download the raw bytes of a sandbox file attached to a question.
  /// Called by [SandboxService] once per file on question load.
  Future<List<int>> downloadSandboxFile({
    required int questionId,
    required String filename,
  }) async {
    try {
      final r = await http
          .get(_uri('/question/$questionId/files/$filename'))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        return r.bodyBytes;
      }
      throw ApiException(
        'File download failed ($filename): HTTP ${r.statusCode}',
        statusCode: r.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('File download error: $e');
    }
  }
}
