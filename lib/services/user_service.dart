import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../l10n/l10n.dart';

class ApiUserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? role;
  final String? level;
  final String? locale;
  final String? avatarUrl;
  /// Décision 15.3 : facultative, sert à fiabiliser la minorité RGPD.
  final DateTime? dateOfBirth;
  const ApiUserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.role,
    this.level,
    this.locale,
    this.avatarUrl,
    this.dateOfBirth,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory ApiUserProfile.fromJson(Map<String, dynamic> j) => ApiUserProfile(
        id: j['id'] as int? ?? 0,
        email: j['email'] as String? ?? '',
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        phone: j['phone'] as String?,
        role: j['role'] as String?,
        level: j['level'] as String?,
        locale: j['locale'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        dateOfBirth: j['dateOfBirth'] != null
            ? DateTime.tryParse(j['dateOfBirth'] as String)
            : null,
      );
}

class ApiNotification {
  final int id;
  final String title;
  final String? body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  const ApiNotification({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> j) => ApiNotification(
        id: j['id'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? j['message'] as String?,
        type: j['type'] as String? ?? 'info',
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  ApiNotification copyWith({bool? isRead}) => ApiNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// Une page de `GET /notifications` avec les compteurs serveur (toutes pages).
class NotificationPage {
  final List<ApiNotification> items;
  final int unread;
  final int total;
  const NotificationPage(
      {required this.items, required this.unread, required this.total});
}

class ApiDownloadEntry {
  final int subjectId;
  final String title;
  final DateTime downloadedAt;
  final String? category;
  const ApiDownloadEntry({
    required this.subjectId,
    required this.title,
    required this.downloadedAt,
    this.category,
  });

  factory ApiDownloadEntry.fromJson(Map<String, dynamic> j) => ApiDownloadEntry(
        subjectId: j['subjectId'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        downloadedAt: DateTime.tryParse(j['downloadedAt'] as String? ?? '') ??
            DateTime.now(),
        category: j['category'] as String?,
      );
}

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _api = ApiClient.instance;

  Future<ApiUserProfile> getProfile() async {
    final res = await _api.dio.get('/users/me');
    return ApiUserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? level,
    String? locale,
    String? specialization,
    String? targetExam,
    List<String>? teachingSubjects,
    List<String>? teachingLevels,
    // Module 15 (lot 6) : onboarding parent, parité avec le web
    // (frontend/src/pages/CompleteProfile.tsx, ParentOnboarding).
    String? parentChildObjective,
    String? parentFollowUpPreference,
    String? learningStyle,
    // Décision 15.3 (arbitrages lot 7, 2026-10-08) : date de naissance,
    // facultative et non bloquante, au format "yyyy-MM-dd". Fiabilise la
    // vérification de minorité de l'export RGPD d'un enfant (module 43).
    // Parité explicitement exigée web ET mobile dès ce lot (contrairement à
    // 15.2, reportée au lot 8) : voir CompleteProfileScreen.
    String? dateOfBirth,
  }) async {
    try {
      await _api.dio.put('/users/profile', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (level != null) 'level': level,
        if (locale != null) 'locale': locale,
        if (specialization != null) 'specialization': specialization,
        if (targetExam != null) 'targetExam': targetExam,
        if (teachingSubjects != null) 'teachingSubjects': teachingSubjects,
        if (teachingLevels != null) 'teachingLevels': teachingLevels,
        if (parentChildObjective != null) 'parentChildObjective': parentChildObjective,
        if (parentFollowUpPreference != null) 'parentFollowUpPreference': parentFollowUpPreference,
        if (learningStyle != null) 'learningStyle': learningStyle,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String current, String next) async {
    try {
      await _api.dio.post('/auth/change-password', data: {
        'currentPassword': current,
        'newPassword': next,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Nombre de notifications non lues, toujours issu du serveur (toutes
  /// pages), partagé par la barre du haut, le profil et l'écran
  /// Notifications. Avant, chaque écran le recomptait sur la première page
  /// chargée (20 lignes au plus) et ne se mettait pas à jour après une
  /// lecture faite ailleurs.
  final ValueNotifier<int> unreadNotifications = ValueNotifier<int>(0);

  void _applyUnread(dynamic body) {
    final unread = body is Map ? body['unread'] : null;
    if (unread is int) unreadNotifications.value = unread < 0 ? 0 : unread;
  }

  /// Relit le compteur serveur. Sans réseau, le dernier compte connu reste.
  Future<void> refreshUnreadCount() async {
    try {
      final res = await _api.dio.get('/notifications/unread-count');
      _applyUnread(res.data);
    } catch (_) {}
  }

  /// À la déconnexion : aucun badge du compte précédent ne doit rester.
  void resetNotifications() => unreadNotifications.value = 0;

  Future<NotificationPage> getNotificationsPage(
      {int page = 1, int limit = 20}) async {
    final res = await _api.dio
        .get('/notifications', queryParameters: {'page': page, 'limit': limit});
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw as Map<String, dynamic>?)?['data'] as List? ?? [];
    final items = list
        .map((e) => ApiNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    final unread = raw is Map && raw['unread'] is int
        ? raw['unread'] as int
        : items.where((n) => !n.isRead).length;
    final total =
        raw is Map && raw['total'] is int ? raw['total'] as int : items.length;
    unreadNotifications.value = unread;
    return NotificationPage(items: items, unread: unread, total: total);
  }

  Future<List<ApiNotification>> getNotifications() async =>
      (await getNotificationsPage()).items;

  /// Retourne false en cas d'échec réseau plutôt que d'avaler l'erreur
  /// silencieusement  l'écran appelant doit pouvoir distinguer un vrai
  /// succès d'un échec, au lieu d'afficher "tout est à jour" à tort.
  /// Le badge passe à 0 tout de suite, puis prend la valeur du serveur.
  Future<bool> markAllNotificationsRead() async {
    final before = unreadNotifications.value;
    unreadNotifications.value = 0;
    try {
      final res = await _api.dio.put('/notifications/read-all');
      _applyUnread(res.data);
      return true;
    } catch (_) {
      unreadNotifications.value = before;
      refreshUnreadCount();
      return false;
    }
  }

  /// [wasUnread] : décrémente le badge tout de suite (optimiste), puis le
  /// serveur donne la valeur exacte.
  Future<bool> markNotificationRead(int id, {bool wasUnread = true}) async {
    if (wasUnread && unreadNotifications.value > 0) {
      unreadNotifications.value = unreadNotifications.value - 1;
    }
    try {
      final res = await _api.dio.put('/notifications/$id/read');
      _applyUnread(res.data);
      return true;
    } catch (_) {
      refreshUnreadCount();
      return false;
    }
  }

  Future<List<ApiDownloadEntry>> getDownloadHistory() async {
    final res = await _api.dio.get('/users/me/downloads');
    final list = res.data as List? ?? [];
    return list
        .map((e) => ApiDownloadEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> deleteAccount() async {
    try {
      await _api.dio.delete('/users/me');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Module 40 (lot 8, décision 15.2) : changement d'adresse email ────────
  // Parcours demande → code → confirmation, parité exacte avec l'onglet
  // Sécurité du profil web (frontend/src/pages/Profile.tsx). Les deux routes
  // existent déjà côté serveur (UsersController.cs, module 20/40) : aucune
  // modification backend, uniquement le branchement mobile.

  /// POST /users/change-email  envoie un code à 6 chiffres à [newEmail].
  /// Lance une [EmailChangeException] avec le message serveur en cas d'échec
  /// (email déjà utilisé, etc.) pour que l'écran affiche l'erreur exacte.
  Future<void> requestEmailChange(String newEmail) async {
    try {
      await _api.dio.post('/users/change-email', data: {'newEmail': newEmail});
    } on DioException catch (e) {
      throw EmailChangeException(_serverError(e));
    }
  }

  /// POST /users/confirm-email-change  valide le code reçu par email.
  /// Retourne la nouvelle adresse confirmée par le serveur.
  Future<String> confirmEmailChange(String verificationCode) async {
    try {
      final res = await _api.dio.post('/users/confirm-email-change',
          data: {'verificationCode': verificationCode});
      final data = res.data as Map<String, dynamic>;
      return data['newEmail'] as String? ?? '';
    } on DioException catch (e) {
      throw EmailChangeException(_serverError(e));
    }
  }

  String _serverError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return L10n.current.svcGenericError;
  }
}

/// Erreur de changement d'email portant le message exact renvoyé par le
/// serveur (ex. "Email already in use", "Invalid verification code",
/// "Too many attempts. Request a new code.").
class EmailChangeException implements Exception {
  final String message;
  const EmailChangeException(this.message);
  @override
  String toString() => message;
}
