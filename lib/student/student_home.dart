import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// ===================== ACCUEIL ÉTUDIANT =====================
class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      _TopBar(),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // HERO
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                      colors: [s.heroFrom, s.heroTo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MARDI 10 JUIN',
                        style: WinType.labelS(WinColors.ink300)
                            .copyWith(letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Text.rich(TextSpan(
                        style: WinType.bodyL(WinColors.cream50),
                        children: [
                          const TextSpan(
                              text: 'Bonne matinée Ahmed  tu as une session '),
                          TextSpan(
                              text: 'Maths',
                              style: WinType.fraunces(
                                      size: 16, color: WinColors.teal400)
                                  .copyWith(fontStyle: FontStyle.italic)),
                          const TextSpan(text: ' planifiée à '),
                          TextSpan(
                              text: '14h',
                              style: WinType.fraunces(
                                      size: 16, color: WinColors.teal400)
                                  .copyWith(fontStyle: FontStyle.italic)),
                          const TextSpan(text: '.'),
                        ])),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: _HeroStat(
                              value: WinStreakFlame(WinData.streak,
                                  light: true, size: 22),
                              title: "jours d'affilée",
                              sub: "Série d'étude")),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _HeroStat(
                              value: Text('${WinData.dayGoal}%',
                                  style: WinType.fraunces(
                                      size: 22, color: WinColors.teal400)),
                              title: 'objectif du jour',
                              sub: "Temps d'étude")),
                    ]),
                  ]),
            ),
            const SizedBox(height: 16),
            // CHIPS
            SizedBox(
                height: 36,
                child:
                    ListView(scrollDirection: Axis.horizontal, children: const [
                  WinChip('Reprendre', icon: Icons.play_arrow_rounded),
                  SizedBox(width: 8),
                  WinChip('Mes Quiz', icon: Icons.check_circle_outline),
                  SizedBox(width: 8),
                  WinChip('Téléchargements', icon: Icons.download_outlined),
                ])),
            const SizedBox(height: 24),
            _SectionHeader('Recommandé par WinAI',
                sub: 'Basé sur tes résultats en Physique'),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                    width: 168,
                    child: ContentCard(
                        content: WinData.contentById(['c2', 'c4', 'c8'][i]))),
              ),
            ),
            const SizedBox(height: 24),
            // STATS
            Row(children: [
              Expanded(
                  child: _StatCard(Icons.check_circle_outline,
                      '${WinData.quizWeek}', 'Quiz / sem.')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(
                      Icons.schedule, WinData.studyToday, 'Étude du jour')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(Icons.download_outlined,
                      '${WinData.downloadsTotal}', 'Téléchargés')),
            ]),
          ],
        ),
      ),
    ]);
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Image.asset('assets/winplus-logo.png', width: 40),
        const Spacer(),
        Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
        const SizedBox(width: 14),
        const WinAvatar('Ahmed Nkono', size: 34),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final Widget value;
  final String title, sub;
  const _HeroStat(
      {required this.value, required this.title, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        value,
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(title,
                  style: WinType.labelS(WinColors.cream100)
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(sub, style: WinType.labelS(WinColors.ink300)),
            ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatCard(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: s.primary),
        const SizedBox(height: 8),
        Text(value, style: WinType.fraunces(size: 22, color: s.onStrong)),
        const SizedBox(height: 4),
        Text(label, style: WinType.labelM(s.onMuted)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  const _SectionHeader(this.title, {this.sub});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: WinType.fraunces(size: 18, color: s.onStrong)),
        if (sub != null)
          Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub!, style: WinType.bodyS(s.onMuted))),
      ]),
    );
  }
}

/// Carte de contenu (catalogue).
class ContentCard extends StatelessWidget {
  final Content content;
  const ContentCard({super.key, required this.content});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(content.subjectId);
    return WinCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 92,
          decoration: BoxDecoration(
              color: subj.color.withOpacity(0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16))),
          child: Center(child: Icon(subj.icon, size: 38, color: subj.color)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                height: 38,
                child: Text(content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.titleM(s.onStrong))),
            const SizedBox(height: 4),
            Text('${subj.short} · ${content.level} · ${content.year}',
                style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 8),
            Text(content.free ? 'Gratuit' : '${fmtXaf(content.price)}\u00a0XAF',
                style: WinType.fraunces(
                    size: 18,
                    color: content.free ? WinColors.success : s.onStrong)),
          ]),
        ),
      ]),
    );
  }
}
