import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _userName;
  String? _userEmail;
  final AuthService _authService = AuthService();

  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    _token = await _authService.login(email, password);
    _userId = await _authService.getUserId();
    _userName = await _authService.getUserName();
    _userEmail = await _authService.getUserEmail();
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _token = await _authService.getToken();
    _userId = await _authService.getUserId();
    _userName = await _authService.getUserName();
    _userEmail = await _authService.getUserEmail();
    notifyListeners();
  }
}
