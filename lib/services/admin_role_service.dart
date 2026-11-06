import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Represents an administrator account configured in the Firebase Firestore backend.
class AdminRecord {
  final String email;
  final String role;
  final bool active;
  final String? notes;

  const AdminRecord({
    required this.email,
    required this.role,
    this.active = true,
    this.notes,
  });

  factory AdminRecord.fromFirestoreFields(Map<String, dynamic> fields, {String? fallbackEmail}) {
    String? getString(String key) {
      final v = fields[key];
      if (v is Map && v.containsKey('stringValue')) return v['stringValue'] as String?;
      return null;
    }

    bool getBool(String key, {bool defaultValue = true}) {
      final v = fields[key];
      if (v is Map && v.containsKey('booleanValue')) return v['booleanValue'] as bool? ?? defaultValue;
      return defaultValue;
    }

    return AdminRecord(
      email: getString('email') ?? fallbackEmail ?? '',
      role: getString('role') ?? 'customer',
      active: getBool('active', defaultValue: true),
      notes: getString('notes'),
    );
  }
}

/// Service that queries Firebase Firestore backend to verify whether a user's
/// email has the 'admin' role. Only authorized emails in Firebase can access the admin side.
class AdminRoleService {
  static final AdminRoleService instance = AdminRoleService._();
  AdminRoleService._();

  static const String projectId = 'fresh-meat-39fbb';
  static const String _prefAdminCachePrefix = 'fresh_meat_admin_role_';

  /// Verifies with Firebase backend whether the given [email] or [uid] has an active 'admin' role.
  Future<bool> checkAdminRole({required String email, String? uid}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;

    try {
      // 1. Query Firestore document with ID = email
      final emailUri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/admins/${Uri.encodeComponent(cleanEmail)}',
      );
      final resp = await http.get(emailUri).timeout(const Duration(seconds: 5));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>?;
        final fields = data?['fields'] as Map<String, dynamic>?;
        if (fields != null) {
          final record = AdminRecord.fromFirestoreFields(fields, fallbackEmail: cleanEmail);
          final isAdmin = record.active && record.role.toLowerCase() == 'admin';
          await _cacheRole(cleanEmail, isAdmin);
          debugPrint('✅ AdminRoleService: $cleanEmail verified as admin: $isAdmin');
          return isAdmin;
        }
      }

      // 2. If UID is provided, also check document with ID = UID
      if (uid != null && uid.isNotEmpty) {
        final uidUri = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/admins/${Uri.encodeComponent(uid)}',
        );
        final uidResp = await http.get(uidUri).timeout(const Duration(seconds: 5));
        if (uidResp.statusCode == 200) {
          final data = jsonDecode(uidResp.body) as Map<String, dynamic>?;
          final fields = data?['fields'] as Map<String, dynamic>?;
          if (fields != null) {
            final record = AdminRecord.fromFirestoreFields(fields, fallbackEmail: cleanEmail);
            final isAdmin = record.active && record.role.toLowerCase() == 'admin';
            await _cacheRole(cleanEmail, isAdmin);
            debugPrint('✅ AdminRoleService: UID $uid verified as admin: $isAdmin');
            return isAdmin;
          }
        }
      }

      // 3. Document 404 => Not in Firebase admins collection
      if (resp.statusCode == 404) {
        await _cacheRole(cleanEmail, false);
        debugPrint('⛔ AdminRoleService: $cleanEmail not found in Firebase admins collection.');
        return false;
      }
    } catch (e) {
      debugPrint('AdminRoleService.checkAdminRole network note (using cached status): $e');
      return getCachedAdminStatus(cleanEmail);
    }

    return getCachedAdminStatus(cleanEmail);
  }

  /// Lists all authorized admin records from Firebase Firestore collection 'admins'
  Future<List<AdminRecord>> fetchAllAdmins() async {
    try {
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/admins',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>?;
        final documents = data?['documents'] as List<dynamic>?;
        if (documents != null) {
          final list = <AdminRecord>[];
          for (final doc in documents) {
            if (doc is Map<String, dynamic>) {
              final fields = doc['fields'] as Map<String, dynamic>?;
              final name = doc['name'] as String? ?? '';
              final docId = name.split('/').last;
              if (fields != null) {
                list.add(AdminRecord.fromFirestoreFields(fields, fallbackEmail: docId));
              }
            }
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('AdminRoleService.fetchAllAdmins error: $e');
    }
    return [];
  }

  Future<void> _cacheRole(String email, bool isAdmin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefAdminCachePrefix$email', isAdmin);
    } catch (_) {}
  }

  Future<bool> getCachedAdminStatus(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_prefAdminCachePrefix${email.trim().toLowerCase()}') ?? false;
    } catch (_) {
      return false;
    }
  }
}
