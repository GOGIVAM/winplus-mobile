import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

BadgeColor _statusColor(String s) => switch (s) {
      'Publié' => BadgeColor.success,
      'En révision' => BadgeColor.warn,
      _ => BadgeColor.neutral,
    };

Widget _teacherHeader(BuildContext context, String? title) {
  final s = WinTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      if (title == null) Image.asset('assets/winplus-logo.png', width: 40)
      else Text(title, style: WinType.fraunces(size: 22, color: s.onStrong)),
      const Spacer(),
      Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
      const SizedBox(width: 14),
      const WinAvatar('M Fopa', size: 34, color: WinColors.cream200),
    ]),
  );
}

Widget _statCard(BuildContext c, IconData icon, String value, String label) {
  final s = WinTheme.of(c);
  return WinCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 20, color: s.primary),
    const SizedBox(height: 8),
    Text(value, style: WinType.fraunces(size: 22, color: s.onStrong)),
    Text(label, style: WinType.labelM(s.onMuted)),
  ]));
}

Widget _heroStat(String value, String title, String sub) => Builder(builder: (_) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Text(value, style: WinType.fraunces(size: 22, color: WinColors.teal400)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: WinType.labelS(WinColors.cream100).copyWith(fontWeight: FontWeight.w600)),
          Text(sub, style: WinType.labelS(WinColors.ink300)),
        ])),
      ]),
    ));

Widget _hero(BuildContext c, String tag, List<InlineSpan> rich, List<Widget> stats) {
  final s = WinTheme.of(c);
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [s.heroFrom, s.heroTo], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tag, style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Text.rich(TextSpan(style: WinType.bodyL(WinColors.cream50), children: rich)),
      const SizedBox(height: 18),
      Row(children: [for (int i = 0; i < stats.length; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: stats[i])]]),
    ]),
  );
}

TextSpan _accent(String t) => TextSpan(text: t, style: WinType.fraunces(size: 16, color: WinColors.teal400).copyWith(fontStyle: FontStyle.italic));

/// ===================== ACCUEIL =====================
class TeacherDashTab extends StatelessWidget {
  const TeacherDashTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final published = WinData.profContent.where((c) => c.status == 'Publié').toList();
    final totalDl = WinData.profContent.fold(0, (a, c) => a + c.downloads);
    return Column(children: [
      _teacherHeader(context, null),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        _hero(context, 'BONJOUR M. FOPA', [const TextSpan(text: 'Tes contenus ont été téléchargés '), _accent('+340 fois'), const TextSpan(text: ' cette semaine.')], [
          _heroStat('${published.length}', 'contenus publiés', 'En ligne'),
          _heroStat('4,8', 'note moyenne', 'Sur 5'),
        ]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _statCard(context, Icons.download_outlined, '$totalDl', 'Téléchargements')), const SizedBox(width: 10), Expanded(child: _statCard(context, Icons.account_balance_wallet_outlined, '907k', 'Revenus (XAF)'))]),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _statCard(context, Icons.people_outline, '412', 'Étudiants')), const SizedBox(width: 10), Expanded(child: _statCard(context, Icons.star_outline, '4,8', 'Note moyenne'))]),
        const SizedBox(height: 20),
        WinButton('Publier un nouveau contenu', variant: WinButtonVariant.accent, block: true, icon: Icons.add_box_outlined),
        const SizedBox(height: 24),
        Text('Tes meilleurs contenus', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        ...published.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _ContentRow(c: c))),
      ])),
    ]);
  }
}

class _ContentRow extends StatelessWidget {
  final ProfContent c;
  const _ContentRow({required this.c});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(padding: const EdgeInsets.all(14), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.description_outlined, size: 20, color: s.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 4),
        Text('${c.downloads} téléch.${c.rating > 0 ? '  ·  ${c.rating} ★' : ''}', style: WinType.labelM(s.onMuted)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        WinBadge(c.status, color: _statusColor(c.status)),
        if (c.revenue > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${fmtXaf(c.revenue)} XAF', style: WinType.labelM(s.onMuted))),
      ]),
    ]));
  }
}

/// ===================== CONTENUS =====================
class TeacherContentTab extends StatefulWidget {
  const TeacherContentTab({super.key});
  @override
  State<TeacherContentTab> createState() => _TeacherContentTabState();
}

class _TeacherContentTabState extends State<TeacherContentTab> {
  String _f = 'Tout';
  final _filters = const ['Tout', 'Publié', 'En révision', 'Brouillon'];
  @override
  Widget build(BuildContext context) {
    final items = _f == 'Tout' ? WinData.profContent : WinData.profContent.where((c) => c.status == _f).toList();
    return Column(children: [
      _teacherHeader(context, 'Mes contenus'),
      SizedBox(height: 36, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filters.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => WinChip(_filters[i], active: _f == _filters[i], onTap: () => setState(() => _f = _filters[i])))),
      const SizedBox(height: 12),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _ContentRow(c: items[i]))),
    ]);
  }
}

/// ===================== ÉTUDIANTS =====================
class TeacherStudentsTab extends StatelessWidget {
  const TeacherStudentsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final students = [('Ahmed Nkono', 'Tle C', 72, 'up'), ('Brenda Mballa', 'Tle C', 86, 'up'), ('Yann Tchami', 'Tle D', 54, 'down'), ('Aïcha Bello', 'Concours', 91, 'up'), ('Steve Ngono', 'Tle A', 63, 'down')];
    return Column(children: [
      _teacherHeader(context, 'Mes étudiants'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: WinTextField(icon: Icons.search, hint: 'Rechercher un étudiant…')),
      const SizedBox(height: 12),
      Expanded(child: ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), itemCount: students.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
        final st = students[i];
        final col = st.$3 < 60 ? WinColors.error : (st.$3 < 80 ? WinColors.warn : WinColors.success);
        return WinCard(padding: const EdgeInsets.all(12), child: Row(children: [
          WinAvatar(st.$1, size: 42),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(st.$1, style: WinType.titleM(s.onStrong)), Text(st.$2, style: WinType.labelM(s.onMuted))])),
          Icon(st.$4 == 'up' ? Icons.trending_up : Icons.trending_down, size: 14, color: st.$4 == 'up' ? WinColors.success : WinColors.error),
          const SizedBox(width: 4),
          Text('${st.$3}%', style: WinType.fraunces(size: 16, color: col)),
        ]));
      })),
    ]);
  }
}

/// ===================== SESSIONS =====================
class TeacherSessionsTab extends StatelessWidget {
  const TeacherSessionsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sessions = [('math', 'Révision Dérivées — Tle C', '14:00 – 15:30', true), ('pc', 'Correction épreuve Physique', '16:30 – 17:30', false)];
    return Column(children: [
      _teacherHeader(context, 'Sessions'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Text("Aujourd'hui, mardi 10 juin", style: WinType.titleS(s.onMuted)),
        const SizedBox(height: 12),
        ...sessions.map((se) {
          final subj = WinData.subjectById(se.$1);
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: WinCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 4, height: 36, decoration: BoxDecoration(color: subj.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(se.$2, style: WinType.titleM(s.onStrong)), Text(se.$3, style: WinType.labelM(s.onMuted))])),
              if (se.$4) const WinBadge('● Bientôt', color: BadgeColor.error),
            ]),
            const SizedBox(height: 12),
            WinButton(se.$4 ? 'Démarrer la session' : 'Voir les détails', variant: se.$4 ? WinButtonVariant.accent : WinButtonVariant.outline, block: true, small: true, icon: se.$4 ? Icons.play_arrow_rounded : Icons.event_outlined),
          ])));
        }),
        const SizedBox(height: 8),
        WinButton('Planifier une session', variant: WinButtonVariant.outline, block: true, icon: Icons.add),
      ])),
    ]);
  }
}

/// ===================== REVENUS =====================
class TeacherRevenueTab extends StatelessWidget {
  const TeacherRevenueTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final curve = [120, 180, 150, 210, 240, 300, 280, 340, 320, 390, 420, 480];
    final max = curve.reduce((a, b) => a > b ? a : b);
    final tx = [('Pack ENSP — 12 ventes', '8 juin', 96000, true), ('Correction BAC C Physique', '6 juin', 27000, true), ('Retrait MTN MoMo', '1 juin', 50000, false), ('Quiz Chimie — 8 ventes', '28 mai', 8000, true)];
    return Column(children: [
      _teacherHeader(context, 'Revenus'),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [s.heroFrom, s.heroTo], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SOLDE DISPONIBLE', style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text('184 500 XAF', style: WinType.fraunces(size: 32, color: WinColors.cream50)),
            const SizedBox(height: 14),
            WinButton('Retirer mes gains', variant: WinButtonVariant.accent, small: true, icon: Icons.account_balance_wallet_outlined),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Revenus mensuels', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        WinCard(child: SizedBox(height: 110, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: curve.map((v) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(height: 110.0 * v / max, decoration: BoxDecoration(color: v == max ? s.primary : WinColors.teal100, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))))))).toList()))),
        const SizedBox(height: 20),
        Text('Transactions', style: WinType.fraunces(size: 18, color: s.onStrong)),
        const SizedBox(height: 12),
        WinCard(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(children: [
          for (int i = 0; i < tx.length; i++)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: i < tx.length - 1 ? Border(bottom: BorderSide(color: s.outline)) : null),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: tx[i].$4 ? WinColors.successBg : s.surface2, shape: BoxShape.circle), child: Icon(tx[i].$4 ? Icons.trending_up : Icons.account_balance_wallet_outlined, size: 16, color: tx[i].$4 ? WinColors.success : s.onMuted)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)), Text(tx[i].$2, style: WinType.labelM(s.onMuted))])),
                Text('${tx[i].$4 ? '+' : '−'}${fmtXaf(tx[i].$3)}', style: WinType.fraunces(size: 15, color: tx[i].$4 ? WinColors.success : s.onStrong)),
              ]),
            ),
        ])),
      ])),
    ]);
  }
}
