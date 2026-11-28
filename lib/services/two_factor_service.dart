import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../l10n/l10n.dart';
import 'api_client.dart';

/// État de la double authentification du compte (GET /users/2fa/status).
class TwoFactorStatus {
  final bool isEnabled;
  final DateTime? enabledAt;
  final int backupCodesCount;
  final bool pendingSetup;
  const TwoFactorStatus(
      {this.isEnabled = false, this.enabledAt, this.backupCodesCount = 0, this.pendingSetup = false});

  factory TwoFactorStatus.fromJson(Map j) => TwoFactorStatus(
        isEnabled: j['isEnabled'] == true,
        enabledAt: DateTime.tryParse('${j['enabledAt'] ?? ''}'),
        backupCodesCount: (j['backupCodesCount'] as num?)?.toInt() ?? 0,
        pendingSetup: j['pendingSetup'] == true,
      );
}

/// Début d'activation (POST /users/2fa/enable) : clé à saisir dans
/// l'application d'authentification, lien qui l'ouvre sur ce téléphone, et
/// QR code pour un autre appareil.
class TwoFactorSetup {
  final String secret;
  final String secretGrouped;
  final String? otpauthUrl;
  final Uint8List? qrPng;
  const TwoFactorSetup({required this.secret, required this.secretGrouped, this.otpauthUrl, this.qrPng});

  factory TwoFactorSetup.fromJson(Map j) {
    Uint8List? png;
    final qr = '${j['qrCode'] ?? ''}';
    final i = qr.indexOf('base64,');
    if (i >= 0) {
      try {
        png = base64Decode(qr.substring(i + 7));
      } catch (_) {}
    }
    final secret = '${j['secret'] ?? ''}';
    return TwoFactorSetup(
      secret: secret,
      secretGrouped: (j['secretGrouped'] as String?) ?? secret,
      otpauthUrl: j['otpauthUrl'] as String?,
      qrPng: png,
    );
  }
}

/// Refus du serveur : { success:false, code, error, message }, message en
/// français affiché tel quel.
class TwoFactorException implements Exception {
  final String? code;
  final String message;
  const TwoFactorException(this.message, [this.code]);
  @override
  String toString() => message;
}

/// Réglages de la double authentification (contrat de winplus-api 2a006d2) :
/// activation en deux temps (enable puis verify avec un premier code), huit
/// codes de secours montrés une seule fois, désactivation avec le mot de
/// passe et un code, nouveaux codes de secours.
class TwoFactorService {
  TwoFactorService._();
  static final TwoFactorService instance = TwoFactorService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      final d = e.response?.data;
      if (e.response == null) throw TwoFactorException(L10n.current.commonNetworkError);
      final m = d is Map ? (d['message'] ?? d['error'])?.toString() : null;
      throw TwoFactorException(m ?? L10n.current.twoFaError, d is Map ? d['code']?.toString() : null);
    }
  }

  static List<String> _codes(Object? data) {
    final l = data is Map ? data['backupCodes'] : null;
    return l is List ? l.map((e) => '$e').toList() : const [];
  }

  Future<TwoFactorStatus> status() => _call(() async {
        final res = await _dio.get('/users/2fa/status');
        return TwoFactorStatus.fromJson(res.data is Map ? res.data as Map : const {});
      });

  Future<TwoFactorSetup> enable() => _call(() async {
        final res = await _dio.post('/users/2fa/enable');
        return TwoFactorSetup.fromJson(res.data is Map ? res.data as Map : const {});
      });

  /// Premier code de l'application : active la 2FA et renvoie les 8 codes
  /// de secours (affichés une seule fois).
  Future<List<String>> verify(String code) => _call(() async {
        final res = await _dio.post('/users/2fa/verify', data: {'code': code.trim()});
        return _codes(res.data);
      });

  /// [password] exigé sauf pour un compte Google ; [code] de l'application
  /// ou de secours.
  Future<void> disable({String? password, required String code}) => _call(() async {
        await _dio.post('/users/2fa/disable', data: {
          if (password != null && password.isNotEmpty) 'password': password,
          'code': code.trim(),
        });
      });

  /// Remplace les anciens codes de secours (demande un code de l'application).
  Future<List<String>> newBackupCodes(String code) => _call(() async {
        final res = await _dio.post('/users/2fa/backup-codes', data: {'code': code.trim()});
        return _codes(res.data);
      });
}
