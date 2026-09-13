import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  //*el token

  Future<void> saveToken(String token) async {
    await _secureStorage.write(
      key: 'token',
      value: token,
    );
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(
      key: 'token',
    );
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(
      key: 'token',
    );
  }

  //*la sesion

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('logged_in', true);
  }

  Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('logged_in') ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('logged_in');
  }

  //*las notas cuando no hay conexion

  Future<void> saveNotes(List<dynamic> notes) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'local_notes',
      jsonEncode(notes),
    );
  }

  Future<List<dynamic>> getLocalNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('local_notes');

    if (data == null || data.isEmpty) {
      return [];
    }

    return jsonDecode(data);
  }

  //*los cambios cuando no hay conexion

  Future<void> savePendingChanges(
      List<dynamic> changes) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'pending_changes',
      jsonEncode(changes),
    );
  }

  Future<List<dynamic>> getPendingChanges() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString('pending_changes');

    if (data == null || data.isEmpty) {
      return [];
    }

    return jsonDecode(data);
  }

  Future<void> clearPendingChanges() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('pending_changes');
  }
}