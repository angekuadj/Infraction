import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_roles.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._baseUrl);
  String? _baseUrl;

  static const String prefKeyToken = 'auth_token';
  static const String prefKeyUser = 'auth_user';
  static const String prefKeyRole = 'auth_role';

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _error;
  bool _initialized = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && (_token?.isNotEmpty ?? false);
  bool get isLoading => _status == AuthStatus.loading;
  bool get initialized => _initialized;

  AppRole get role => AppRoleX.fromString(_user?.role);
  bool get isUsager => role == AppRole.usager;
  bool get isClient => role == AppRole.client;
  bool get isAgent => role == AppRole.agent;
  bool get isAdmin => role == AppRole.admin;
  bool get isProprietaire => _user?.role?.toLowerCase() == 'proprietaire';

  AuthService? get _service =>
      _baseUrl == null || _baseUrl!.isEmpty ? null : AuthService(_baseUrl!);

  void updateBaseUrl(String? baseUrl) {
    if (_baseUrl != baseUrl) {
      _baseUrl = baseUrl;
      notifyListeners();
    }
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(prefKeyToken);
      final userRaw = prefs.getString(prefKeyUser);
      if (userRaw != null) {
        try {
          _user = UserModel.fromJson(
            jsonDecode(userRaw) as Map<String, dynamic>,
          );
        } catch (_) {
          _user = null;
        }
      }
      if (_token != null && _token!.isNotEmpty) {
        _status = AuthStatus.authenticated;
        // Rafraîchit le profil en arrière-plan.
        refreshMe().ignore();
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // Session illisible : démarrage en état déconnecté.
      _status = AuthStatus.unauthenticated;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    final service = _service;
    if (service == null) {
      _error = 'Endpoint non configuré';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await service.login(
        identifier: identifier,
        password: password,
      );
      _user = result.user;
      _token = result.token ?? result.user.token ?? result.user.accessToken;
      _status = AuthStatus.authenticated;
      await _persist();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur de connexion: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    String? prenom,
    String? email,
    required String phone,
    required String password,
    String? role,
    String? cni,
    String? plaque,
    String? matricule,
    String? cniPhotoPath,
  }) async {
    final service = _service;
    if (service == null) {
      _error = 'Endpoint non configuré';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = cniPhotoPath != null && cniPhotoPath.isNotEmpty
          ? await service.registerWithPhoto(
              nom: nom,
              prenom: prenom,
              email: email,
              phone: phone,
              password: password,
              role: role,
              cni: cni,
              plaque: plaque,
              matricule: matricule,
              cniPhotoPath: cniPhotoPath,
            )
          : await service.register(
              nom: nom,
              prenom: prenom,
              email: email,
              phone: phone,
              password: password,
              role: role,
              cni: cni,
              plaque: plaque,
              matricule: matricule,
            );
      _user = result.user;
      _token = result.token ?? result.user.token ?? result.user.accessToken;
      _status = AuthStatus.authenticated;
      await _persist();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = 'Erreur d\'inscription (${e.statusCode}): ${e.message}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erreur d\'inscription: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshMe() async {
    final service = _service;
    if (service == null || _token == null) return false;
    try {
      final me = await service.me(_token!);
      _user = me.copyWith(
        token: me.token ?? _token,
        accessToken: me.accessToken ?? _token,
      );
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitPlaque(String plaque) async {
    final service = _service;
    if (service == null || _token == null) return false;
    try {
      await service.submitPlaque(token: _token!, plaque: plaque);
      _user = _user?.copyWith(
        plaqueImmatriculation: plaque,
        numeroImmatriculation: plaque,
      );
      await _persist();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> declarePanne({DateTime? start, DateTime? end}) async {
    final service = _service;
    if (service == null || _token == null) return false;
    try {
      await service.declarePanne(token: _token!, start: start, end: end);
      _user = _user?.copyWith(enPanne: true);
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeyToken);
    await prefs.remove(prefKeyUser);
    await prefs.remove(prefKeyRole);
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    _persist().ignore();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(prefKeyToken, _token!);
    }
    if (_user != null) {
      await prefs.setString(prefKeyUser, jsonEncode(_user!.toJson()));
      await prefs.setString(prefKeyRole, _user!.role ?? '');
    }
  }
}
