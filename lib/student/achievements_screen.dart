import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final badges = WinData.badges;
    final unlocked = badges.where((b) => b.unlocked).length;
    final total = badges.length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Achievements', style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Progress header
          WinCard(
            bg: WinColors.ink800,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                WinStreakFlame(WinData.streak, light: true, size: 28),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Série actuelle',
                      style: WinType.labelM(WinColors.ink300)),
                  Text('${WinData.streak} jours consécutifs',
                      style: WinType.titleM(WinColors.cream50)),
                ]),
              ]),
              const SizedBox(height: 16),
              Text('$unlocked / $total badges débloqués',
                  style: WinType.bodyS(WinColors.ink300)),
              const SizedBox(height: 6),
              WinProgressBar(unlocked / total * 100,
                  color: WinColors.teal400),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Mes badges', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: badges.length,
            itemBuilder: (_, i) => _BadgeCard(badges[i]),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementBadge badge;
  const _BadgeCard(this.badge);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(alignment: Alignment.center, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: badge.unlocked
                    ? badge.color.withValues(alpha: 0.15)
                    : s.surface2,
                shape: BoxShape.circle,
              ),
              child: Opacity(
                opacity: badge.unlocked ? 1.0 : 0.3,
                child: Icon(badge.icon, size: 32,
                    color: badge.unlocked ? badge.color : s.onFaint),
              ),
            ),
            if (!badge.unlocked)
              Icon(Icons.lock, size: 18, color: s.onFaint),
          ]),
          const SizedBox(height: 10),
          Text(badge.name,
              style: WinType.titleM(s.onStrong),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(badge.description,
              style: WinType.labelS(s.onMuted),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          if (badge.unlocked)
            WinBadge('Débloqué', color: BadgeColor.teal)
          else
            const WinBadge('Verrouillé'),
          if (badge.unlocked && badge.unlockedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(badge.unlockedAt!,
                  style: WinType.labelS(s.onFaint)),
            ),
        ],
      ),
    );
  }
}
