// ============================================================
// File: lib/features/auth/auth_provider.dart
// Project: Lab Exam Client - Korelium Labs
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-15
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: ChangeNotifier managing login state, server health
//              check, and exposing student/session/assignment data.
// ============================================================

import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/machine_info.dart';
import '../../data/models/login_response_model.dart';
import '../../data/services/api_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AuthProvider({ApiService? api}) : _api = api ?? ApiService();

  AuthStatus _status = AuthStatus.idle;
  String _error = '';
  bool _serverOnline = false;

  LoginResponseModel? _loginData;

  AuthStatus get status => _status;
  String get error => _error;
  bool get serverOnline => _serverOnline;
  LoginResponseModel? get loginData => _loginData;

  StudentModel? get student => _loginData?.student;
  SessionModel? get session => _loginData?.session;
  AssignmentModel? get assignment => _loginData?.assignment;

  Future<void> checkServer() async {
    _serverOnline = await _api.checkHealth();
    notifyListeners();
  }

  Future<bool> login(String registrationNumber) async {
    _status = AuthStatus.loading;
    _error = '';
    notifyListeners();

    try {
      final ip = await MachineInfo.getMachineIp();
      final payload = {
        'registration_number': registrationNumber.trim().toUpperCase(),
        'machine_name': MachineInfo.machineName,
        'machine_ip': ip,
        'client_version': AppConstants.clientVersion,
      };

      final json = await _api.login(payload);
      final response = LoginResponseModel.fromJson(json);

      if (!response.success) {
        _status = AuthStatus.error;
        _error = response.message;
        notifyListeners();
        return false;
      }

      _loginData = response;
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _loginData = null;
    _status = AuthStatus.idle;
    _error = '';
    notifyListeners();
  }
}
