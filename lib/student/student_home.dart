import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/user_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'content_detail_screen.dart';

String _fmtDate(DateTime d) {
  const days = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche'
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre'
  ];
  final day = days[d.weekday - 1];
  return '${day[0].toUpperCase()}${day.substring(1)} ${d.day} ${months[d.month - 1]} ${d.year}';
}

/// ===================== ACCUEIL ÉTUDIANT =====================
class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});
  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  ApiUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.instance.getProfile();
      if (mounted) { setState(() => _profile = p); }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = SubscriptionScope.of(context);
    final effectiveTier = sub.tier;

    final firstName = _profile?.firstName ?? WinData.userProfile.name.split(' ').first;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12 ? 'Bonjour' : (hour < 18 ? 'Bon après-midi' : 'Bonsoir');

    const stats = WinData.studentStats;
    final weekHours = '${stats.hoursThisWeek}h';

    final (String planLabel, Color planColor) = switch (effectiveTier) {
      PlanTier.libre => ('Gratuit', WinColors.ink400),
      PlanTier.standard => ('Standard', WinColors.blue500),
      PlanTier.premium => ('Premium', WinColors.teal500),
      PlanTier.famille => ('Famille', WinColors.gold),
    };

    return Column(children: [
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
                    Row(children: [
                      Text(_fmtDate(now),
                          style: WinType.labelS(WinColors.ink300)
                              .copyWith(letterSpacing: 0.8)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                            color: planColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: planColor.withValues(alpha: 0.4))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.workspace_premium_outlined,
                              size: 12, color: planColor),
                          const SizedBox(width: 4),
                          Text(planLabel,
                              style: WinType.manrope(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: planColor)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text.rich(TextSpan(
                        style: WinType.bodyL(WinColors.cream50),
                        children: [
                          TextSpan(text: '$greeting $firstName  '),
                          TextSpan(
                              text: '${stats.streakDays} jours',
                              style: WinType.archivo(
                                      size: 16, color: WinColors.teal400)
                                  .copyWith(fontStyle: FontStyle.italic)),
                          const TextSpan(text: " d'affilée !"),
                        ])),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                          child: _HeroStat(
                              value: WinStreakFlame(stats.streakDays,
                                  light: true, size: 22),
                              title: "jours d'affilée",
                              sub: 'Streak')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _HeroStat(
                              value: Text('${stats.avgScore}%',
                                  style: WinType.archivo(
                                      size: 22, color: WinColors.teal400)),
                              title: 'score moyen',
                              sub: 'Cette semaine')),
                    ]),
                    const SizedBox(height: 10),
                    _HeroStat(
                      value: Text(weekHours,
                          style: WinType.archivo(
                              size: 22, color: WinColors.teal400)),
                      title: "d'étude cette semaine",
                      sub: 'Objectif 35h',
                    ),
                  ]),
            ),
            const SizedBox(height: 12),
            // UPGRADE BANNER  visible uniquement en plan Gratuit hors devMode
            if (effectiveTier == PlanTier.libre)
              _UpgradeBanner(s: s),
            const SizedBox(height: 4),
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
            // 2.1  Continue Learning
            const SizedBox(height: 24),
            const _SectionHeader("Continue où tu t'es arrêté"),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: WinData.inProgress.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _InProgressCard(item: WinData.inProgress[i]),
              ),
            ),
            // 2.2  WinAI Reco
            const SizedBox(height: 24),
            _SectionHeader(
              'Pour toi · WinAI',
              sub: effectiveTier.index >= PlanTier.premium.index
                  ? 'Analyse complète · Basé sur tes lacunes en Physique'
                  : 'Basé sur tes résultats récents',
            ),
            ...WinData.aiRecommendations.take(2).map((reco) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AiRecoCard(reco: reco),
                )),
            // 2.3  Examens à venir
            const SizedBox(height: 24),
            const _SectionHeader('Examens à venir'),
            ...WinData.upcomingExams.take(2).map((exam) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExamCountdownCard(exam: exam),
                )),
            // 2.4  Activité récente
            const SizedBox(height: 24),
            const _SectionHeader('Activité récente'),
            ...WinData.activityFeed.take(5).map((e) => _ActivityRow(event: e)),
            // STATS
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: _StatCard(Icons.check_circle_outline,
                      '${WinData.quizWeek}', 'Quiz / sem.')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(Icons.schedule, weekHours, 'Étude / sem.')),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatCard(Icons.emoji_events_outlined,
                      '${stats.totalBadges}', 'Badges')),
            ]),
          ],
        ),
      ),
    ]);
  }
}

class _InProgressCard extends StatelessWidget {
  final InProgressContent item;
  const _InProgressCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(item.subjectId);
    final content = Content(
      id: 'ip_${item.subjectId}',
      title: item.title,
      subjectId: item.subjectId,
      exam: 'BAC',
      level: 'Terminale',
      year: 2024,
      type: ContentType.epreuve,
      price: 2500,
      rating100: 0,
      ratings: 0,
      downloads: 0,
      free: false,
    );
    return SizedBox(
      width: 220,
      child: WinCard(
        padding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ContentDetailScreen(content: content))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(subj.icon, size: 18, color: subj.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.titleM(s.onStrong)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(item.lastOpened, style: WinType.labelM(s.onMuted)),
          const SizedBox(height: 8),
          WinProgressBar(item.progressPct.toDouble(), height: 4),
          const SizedBox(height: 6),
          Row(children: [
            Text('${item.progressPct}%',
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Reprendre', style: WinType.manrope(size: 11, weight: FontWeight.w700, color: s.primary)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 11, color: s.primary),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _AiRecoCard extends StatelessWidget {
  final AiRecommendation reco;
  const _AiRecoCard({required this.reco});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final (IconData icon, Color color) = switch (reco.type) {
      RecoType.weakSubject => (Icons.trending_up, WinColors.error),
      RecoType.suggestedQuiz => (Icons.quiz_outlined, s.primary),
      RecoType.examPlan => (Icons.event_note_outlined, WinColors.warn),
      _ => (Icons.auto_awesome_outlined, s.primary),
    };
    final subjId = switch (reco.type) {
      RecoType.weakSubject => 'pc',
      RecoType.suggestedQuiz => 'math',
      RecoType.examPlan => 'math',
      _ => 'fr',
    };
    final subj = WinData.subjectById(subjId);
    final recoContent = Content(
      id: 'reco_$subjId',
      title: reco.title,
      subjectId: subjId,
      exam: 'BAC',
      level: 'Terminale',
      year: 2024,
      type: reco.type == RecoType.suggestedQuiz
          ? ContentType.quiz
          : ContentType.correction,
      price: 1500,
      rating100: 0,
      ratings: 0,
      downloads: 0,
      free: false,
    );
    return WinCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ContentDetailScreen(content: recoContent))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reco.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 4),
          Text(reco.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WinType.bodyS(s.onMuted)
                  .copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Row(children: [
            WinChip(subj.short, icon: subj.icon),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Voir', style: WinType.manrope(size: 12, weight: FontWeight.w700, color: s.primary)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 12, color: s.primary),
            ]),
          ]),
        ])),
      ]),
    );
  }
}

class _ExamCountdownCard extends StatelessWidget {
  final ExamCountdown exam;
  const _ExamCountdownCard({required this.exam});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(exam.subject);
    final urgentColor = exam.daysLeft <= 7 ? WinColors.error : s.primary;
    return WinCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: subj.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(subj.icon, size: 22, color: subj.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 2),
            Text('${subj.short} · ${exam.date}',
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${exam.daysLeft}',
              style: WinType.archivo(size: 28, color: urgentColor)),
          Text('jours', style: WinType.labelS(urgentColor)),
        ]),
      ]),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEvent event;
  const _ActivityRow({required this.event});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final (IconData icon, Color color) = switch (event.type) {
      ActivityType.quiz => (Icons.quiz_outlined, WinColors.teal500),
      ActivityType.download => (Icons.download_outlined, WinColors.blue500),
      ActivityType.badge => (Icons.emoji_events_outlined, WinColors.gold),
      ActivityType.purchase => (Icons.shopping_bag_outlined, WinColors.success),
      ActivityType.session => (Icons.timer_outlined, WinColors.ink600),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WinType.bodyM(s.onStrong)
                    .copyWith(fontWeight: FontWeight.w600)),
            Text(event.time, style: WinType.labelM(s.onMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        Text(event.detail, style: WinType.labelM(s.primary)),
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
          color: Colors.white.withValues(alpha: 0.08),
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
        Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
        const SizedBox(height: 4),
        Text(label, style: WinType.labelM(s.onMuted)),
      ]),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  final WinScheme s;
  const _UpgradeBanner({required this.s});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WinColors.teal50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WinColors.teal100),
      ),
      child: Row(children: [
        const Icon(Icons.bolt_outlined, size: 20, color: WinColors.teal600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Passez Standard pour débloquer les recommandations IA et les téléchargements illimités.',
            style: WinType.bodyS(WinColors.teal700)
                .copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {},
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Voir', style: WinType.manrope(size: 12, weight: FontWeight.w700, color: WinColors.teal600)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_rounded, size: 12, color: WinColors.teal600),
          ]),
        ),
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
        Text(title, style: WinType.archivo(size: 18, color: s.onStrong)),
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
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ContentDetailScreen(content: content))),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 92,
          decoration: BoxDecoration(
              color: subj.color.withValues(alpha: 0.12),
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
            Text(content.free ? 'Gratuit' : '${fmtXaf(content.price)} XAF',
                style: WinType.archivo(
                    size: 18,
                    color: content.free ? WinColors.success : s.onStrong)),
          ]),
        ),
      ]),
    );
  }
}
