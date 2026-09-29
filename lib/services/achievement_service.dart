import 'package:flutter/material.dart';
import 'api_client.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';

class AchievementResult {
  final List<AchievementBadge> badges;
  final int streak;
  const AchievementResult({required this.badges, required this.streak});
}

class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  final _api = ApiClient.instance;

  /// Module 25 : `GET /achievements/me` n'existe pas côté serveur (404
  /// systématique, l'écran restait sur ses valeurs de démonstration). La
  /// série de jours réelle est servie par GET /users/profile/statistics
  /// (currentStreak, même calcul que le tableau de bord web).
  ///
  /// Aucun endpoint serveur ne fournit de badges « plateforme » : la liste
  /// reste celle de démonstration tant que le product owner n'a pas tranché
  /// (construire le système de badges, ou retirer la grille de l'écran).
  Future<AchievementResult> getMyAchievements() async {
    final res = await _api.dio.get('/users/profile/statistics');
    final data = res.data as Map<String, dynamic>? ?? {};
    final streak = (data['currentStreak'] as num?)?.toInt() ?? 0;
    final rawBadges = data['badges'] as List? ?? [];
    final badges = rawBadges.isEmpty
        ? WinData.badges
        : rawBadges.map((e) {
            final j = e as Map<String, dynamic>;
            return AchievementBadge(
              j['id'] as String? ?? '',
              j['name'] as String? ?? '',
              j['description'] as String? ?? '',
              _iconFromCode(j['iconCode'] as int?),
              _colorFromHex(j['color'] as String?),
              unlocked: j['unlocked'] as bool? ?? false,
              unlockedAt: j['unlockedAt'] as String?,
            );
          }).toList();
    return AchievementResult(badges: badges, streak: streak);
  }

  static IconData _iconFromCode(int? code) {
    if (code == null) return Icons.emoji_events_outlined;
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  static Color _colorFromHex(String? hex) {
    if (hex == null) return WinColors.teal500;
    final h = hex.replaceAll('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return WinColors.teal500;
  }
}
