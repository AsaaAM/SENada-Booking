import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? _role;
  int? _userId;

  String? get role => _role;
  int? get userId => _userId;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userId = prefs.getInt('userId');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success']) {
        _token = response.data['data']['token'];
        _role = response.data['data']['user']['role'];
        _userId = response.data['data']['user']['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setInt('userId', _userId!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      developer.log('Login error', error: e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String namaLengkap, String email, String password, String noHp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'nama_lengkap': namaLengkap,
        'email': email,
        'password': password,
        'no_hp': noHp,
      });

      if (response.statusCode == 201 && response.data['success']) {
        _token = response.data['data']['token'];
        _role = response.data['data']['user']['role'];
        _userId = response.data['data']['user']['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        await prefs.setInt('userId', _userId!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      developer.log('Register error', error: e);
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('userId');
    notifyListeners();
  }
}
