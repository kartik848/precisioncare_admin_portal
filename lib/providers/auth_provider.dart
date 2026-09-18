import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUserProfile();
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final fresh = await _authService.getCurrentUserProfile();
      if (fresh != null) {
        _user = fresh;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String sex,
    DateTime? dob,
    required String address,
    required String mobile,
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        age: age,
        sex: sex,
        dob: dob,
        address: address,
        mobile: mobile,
        profileImageUrl: profileImageUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.updateProfile(updatedProfile);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
