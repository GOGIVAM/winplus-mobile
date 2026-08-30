import 'api_client.dart';

class ApiUserProfile {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? role;
  final String? level;
  final String? avatarUrl;
  const ApiUserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.role,
    this.level,
    this.avatarUrl,
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
        avatarUrl: j['avatarUrl'] as String?,
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
  }) async {
    try {
      await _api.dio.put('/users/profile', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (level != null) 'level': level,
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

  Future<List<ApiNotification>> getNotifications() async {
    final res = await _api.dio.get('/notifications');
    final raw = res.data;
    final list = raw is List
        ? raw
        : (raw as Map<String, dynamic>?)?['data'] as List? ?? [];
    return list
        .map((e) => ApiNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _api.dio.put('/notifications/read-all');
    } catch (_) {}
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
}
