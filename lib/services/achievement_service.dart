import 'package:flutter/material.dart';
import 'api_client.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';

class AchievementResult {
  final List<AchievementBadge> badges;
  final int streak;
  const AchievementResult({required this.badges, required this.streak});
}

// AchievementBadge (id/name/description/icon/color/unlocked/unlockedAt) est
// déjà défini dans data/models.dart : réutilisé tel quel, "id" portant
// désormais le "code" stable du badge (voir BadgeCodes.cs côté backend).
// L'icône/couleur ne sont pas envoyées par le serveur (indice textuel
// seulement dans BadgeDefinition.Icon) : mappées localement par code.

const _iconByCode = <String, IconData>{
  'first_quiz_passed': Icons.quiz_outlined,
  'ten_quizzes_passed': Icons.library_books_outlined,
  'perfect_quiz_score': Icons.star_outlined,
  'first_course_completed': Icons.workspace_premium_outlined,
  'streak_7': Icons.local_fire_department_outlined,
  'streak_30': Icons.whatshot_outlined,
};

const _colorByCode = <String, Color>{
  'first_quiz_passed': WinColors.teal500,
  'ten_quizzes_passed': WinColors.blue500,
  'perfect_quiz_score': WinColors.gold,
  'first_course_completed': WinColors.teal400,
  'streak_7': WinColors.warn,
  'streak_30': WinColors.gold,
};

class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  final _api = ApiClient.instance;

  /// Module 24 (lot 8, rattrapage 16.2) : GET /api/badges renvoie désormais
  /// le vrai catalogue de badges plateforme (débloqués + verrouillés), et
  /// GET /users/profile/statistics reste la source de la série de jours
  /// actifs réelle (même calcul que le tableau de bord web).
  Future<AchievementResult> getMyAchievements() async {
    final results = await Future.wait([
      _api.dio.get('/users/profile/statistics'),
      _api.dio.get('/badges'),
    ]);

    final statsData = results[0].data as Map<String, dynamic>? ?? {};
    final streak = (statsData['currentStreak'] as num?)?.toInt() ?? 0;

    final badgesRes = results[1].data as Map<String, dynamic>? ?? {};
    final rawBadges = badgesRes['data'] as List? ?? [];
    final badges = rawBadges.map((e) {
      final j = e as Map<String, dynamic>;
      final code = j['code'] as String? ?? '';
      return AchievementBadge(
        code,
        j['title'] as String? ?? '',
        j['description'] as String? ?? '',
        _iconByCode[code] ?? Icons.emoji_events_outlined,
        _colorByCode[code] ?? WinColors.teal500,
        unlocked: j['unlocked'] as bool? ?? false,
        unlockedAt: j['unlockedAt'] as String?,
      );
    }).toList();

    return AchievementResult(badges: badges, streak: streak);
  }
}
