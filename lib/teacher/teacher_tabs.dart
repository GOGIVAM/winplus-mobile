import 'package:flutter/material.dart';
import '../app_config.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'content_publish_screen.dart';
import 'correction_queue_screen.dart';
import 'session_create_screen.dart';
import '../shared/messaging/messaging_screen.dart';

BadgeColor _statusColor(String s) => switch (s) {
      'Publié' => BadgeColor.success,
      'published' => BadgeColor.success,
      'En révision' => BadgeColor.warn,
      'pending' => BadgeColor.warn,
      _ => BadgeColor.neutral,
    };

String _statusLabel(String s) => switch (s) {
      'published' => 'Publié',
      'pending' => 'En révision',
      'draft' => 'Brouillon',
      _ => s,
    };

Widget _teacherHeader(BuildContext context, String? title) {
  final s = WinTheme.of(context);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      if (title == null)
        Image.asset('assets/winplus-logo.png', width: 40)
      else
        Text(title, style: WinType.archivo(size: 22, color: s.onStrong)),
      const Spacer(),
      Icon(Icons.notifications_outlined, size: 23, color: s.onSurface),
      const SizedBox(width: 14),
      const WinAvatar('M Fopa', size: 34, color: WinColors.cream200),
    ]),
  );
}

Widget _statCard(BuildContext c, IconData icon, String value, String label) {
  final s = WinTheme.of(c);
  return WinCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: s.primary),
        const SizedBox(height: 8),
        Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
        Text(label, style: WinType.labelM(s.onMuted)),
      ]));
}

Widget _heroStat(String value, String title, String sub) => Builder(
    builder: (_) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Text(value,
                style: WinType.archivo(size: 22, color: WinColors.teal400)),
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
        ));

Widget _hero(
    BuildContext c, String tag, List<InlineSpan> rich, List<Widget> stats) {
  final s = WinTheme.of(c);
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
            colors: [s.heroFrom, s.heroTo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tag,
          style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Text.rich(
          TextSpan(style: WinType.bodyL(WinColors.cream50), children: rich)),
      const SizedBox(height: 18),
      Row(children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: stats[i])
        ]
      ]),
    ]),
  );
}

TextSpan _accent(String t) => TextSpan(
    text: t,
    style: WinType.archivo(size: 16, color: WinColors.teal400)
        .copyWith(fontStyle: FontStyle.italic));

/// ===================== ACCUEIL =====================
class TeacherDashTab extends StatefulWidget {
  const TeacherDashTab({super.key});
  @override
  State<TeacherDashTab> createState() => _TeacherDashTabState();
}

class _TeacherDashTabState extends State<TeacherDashTab> {
  List<ApiPublishedContent>? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TeacherService.instance.getMyContent();
      if (mounted) setState(() => _content = data);
    } catch (_) {
      if (mounted) setState(() => _content = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = _content ?? [];
    final published = content.where((c) => c.status == 'published' || c.status == 'Publié').toList();
    final totalDl = content.fold(0, (a, c) => a + c.downloads);
    final subScope = SubscriptionScope.of(context);
    final atPublishLimit = !AppConfig.devMode && subScope.isFree && published.length >= 2;

    return Column(children: [
      _teacherHeader(context, null),
      Expanded(
          child: _content == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                _hero(context, 'BONJOUR M. FOPA', [
                  const TextSpan(text: 'Tes contenus ont été téléchargés '),
                  _accent('+$totalDl fois'),
                  const TextSpan(text: ' au total.')
                ], [
                  _heroStat('${published.length}', 'contenus publiés', 'En ligne'),
                  _heroStat('4,8', 'note moyenne', 'Sur 5'),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: _statCard(context, Icons.download_outlined, '$totalDl',
                          'Téléchargements')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(
                          context,
                          Icons.account_balance_wallet_outlined,
                          '907k',
                          'Revenus (XAF)'))
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: _statCard(
                          context, Icons.people_outline, '412', 'Étudiants')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(
                          context, Icons.star_outline, '4,8', 'Note moyenne'))
                ]),
                const SizedBox(height: 20),
                WinButton(
                    atPublishLimit
                        ? 'Limite atteinte (plan gratuit)'
                        : 'Publier un nouveau contenu',
                    variant: atPublishLimit
                        ? WinButtonVariant.outline
                        : WinButtonVariant.accent,
                    block: true,
                    icon: atPublishLimit ? Icons.lock_outline : Icons.add_box_outlined,
                    onTap: atPublishLimit ? null : () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ContentPublishScreen()));
                      setState(() => _content = null);
                      _load();
                    }),
                const SizedBox(height: 10),
                WinButton('File de corrections',
                    variant: WinButtonVariant.outline,
                    block: true,
                    icon: Icons.rate_review_outlined,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CorrectionQueueScreen()))),
                const SizedBox(height: 24),
                Text('Tes meilleurs contenus',
                    style: WinType.archivo(size: 18, color: s.onStrong)),
                const SizedBox(height: 12),
                if (published.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Aucun contenu publié.', style: WinType.bodyM(s.onMuted)),
                  ))
                else
                  ...published.take(5).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ContentRow(c: c))),
              ])),
    ]);
  }
}

class _ContentRow extends StatelessWidget {
  final ApiPublishedContent c;
  const _ContentRow({required this.c});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: s.primaryContainer,
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.description_outlined, size: 20, color: s.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(c.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 4),
                Text(
                    '${c.downloads} téléch.${c.rating > 0 ? '  ·  ${c.rating.toStringAsFixed(1)} ★' : ''}',
                    style: WinType.labelM(s.onMuted)),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            WinBadge(_statusLabel(c.status), color: _statusColor(c.status)),
            if (c.revenue > 0)
              Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${fmtXaf(c.revenue)} XAF',
                      style: WinType.labelM(s.onMuted))),
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
  List<ApiPublishedContent>? _all;
  final _filters = const ['Tout', 'Publié', 'En révision', 'Brouillon'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TeacherService.instance.getMyContent();
      if (mounted) setState(() => _all = data);
    } catch (_) {
      if (mounted) setState(() => _all = []);
    }
  }

  List<ApiPublishedContent> get _items {
    final all = _all ?? [];
    if (_f == 'Tout') return all;
    final normalized = switch (_f) {
      'Publié' => 'published',
      'En révision' => 'pending',
      'Brouillon' => 'draft',
      _ => _f.toLowerCase(),
    };
    return all.where((c) => c.status == normalized || c.status == _f).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _teacherHeader(context, 'Mes contenus'),
      SizedBox(
          height: 36,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => WinChip(_filters[i],
                  active: _f == _filters[i],
                  onTap: () => setState(() => _f = _filters[i])))),
      const SizedBox(height: 12),
      Expanded(
          child: _all == null
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(child: Builder(builder: (ctx) {
                      final s = WinTheme.of(ctx);
                      return Text('Aucun contenu.', style: WinType.bodyM(s.onMuted));
                    }))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ContentRow(c: _items[i]))),
    ]);
  }
}

/// ===================== ÉTUDIANTS =====================
class TeacherStudentsTab extends StatelessWidget {
  const TeacherStudentsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final students = [
      ('Ahmed Nkono', 'Tle C', 72, 'up'),
      ('Brenda Mballa', 'Tle C', 86, 'up'),
      ('Yann Tchami', 'Tle D', 54, 'down'),
      ('Aïcha Bello', 'Concours', 91, 'up'),
      ('Steve Ngono', 'Tle A', 63, 'down')
    ];
    return Column(children: [
      _teacherHeader(context, 'Mes étudiants'),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WinTextField(
              icon: Icons.search, hint: 'Rechercher un étudiant…')),
      const SizedBox(height: 12),
      Expanded(
          child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final st = students[i];
                final col = st.$3 < 60
                    ? WinColors.error
                    : (st.$3 < 80 ? WinColors.warn : WinColors.success);
                return WinCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      WinAvatar(st.$1, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(st.$1, style: WinType.titleM(s.onStrong)),
                            Text(st.$2, style: WinType.labelM(s.onMuted))
                          ])),
                      Icon(
                          st.$4 == 'up'
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 14,
                          color: st.$4 == 'up'
                              ? WinColors.success
                              : WinColors.error),
                      const SizedBox(width: 4),
                      Text('${st.$3}%',
                          style: WinType.archivo(size: 16, color: col)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MessagingScreen())),
                        child: Icon(Icons.chat_outlined, size: 20, color: s.primary),
                      ),
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
    final sessions = [
      (WinColors.teal500, 'Révision Dérivées  Tle C', '14:00 – 15:30', true),
      (WinColors.blue500, 'Correction épreuve Physique', '16:30 – 17:30', false)
    ];
    return Column(children: [
      _teacherHeader(context, 'Sessions'),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
            Text("Aujourd'hui, mardi 10 juin",
                style: WinType.titleS(s.onMuted)),
            const SizedBox(height: 12),
            ...sessions.map((se) {
              return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WinCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                              width: 4,
                              height: 36,
                              color: se.$1),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(se.$2, style: WinType.titleM(s.onStrong)),
                                Text(se.$3, style: WinType.labelM(s.onMuted))
                              ])),
                          if (se.$4)
                            const WinBadge('● Bientôt',
                                color: BadgeColor.error),
                        ]),
                        const SizedBox(height: 12),
                        WinButton(
                            se.$4 ? 'Démarrer la session' : 'Voir les détails',
                            variant: se.$4
                                ? WinButtonVariant.accent
                                : WinButtonVariant.outline,
                            block: true,
                            small: true,
                            icon: se.$4
                                ? Icons.play_arrow_rounded
                                : Icons.event_outlined),
                      ])));
            }),
            const SizedBox(height: 8),
            WinButton('Planifier une session',
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.add,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SessionCreateScreen()))),
          ])),
    ]);
  }
}

/// ===================== REVENUS =====================
class TeacherRevenueTab extends StatefulWidget {
  const TeacherRevenueTab({super.key});
  @override
  State<TeacherRevenueTab> createState() => _TeacherRevenueTabState();
}

class _TeacherRevenueTabState extends State<TeacherRevenueTab> {
  Map<String, dynamic>? _revenue;
  List<Map<String, dynamic>> _contentRevenue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TeacherService.instance.getRevenueSummary(),
        TeacherService.instance.getContentRevenue(),
      ]);
      if (mounted) {
        setState(() {
          _revenue = results[0] as Map<String, dynamic>;
          _contentRevenue = results[1] as List<Map<String, dynamic>>;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _revenue = {}; _contentRevenue = []; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final balance = (_revenue?['balance'] as num?)?.toInt() ?? 184500;
    final rawTx = _revenue?['transactions'] as List? ?? _fallbackTx;
    final tx = rawTx.map((e) {
      if (e is Map<String, dynamic>) {
        return (
          e['label'] as String? ?? '',
          e['date'] as String? ?? '',
          (e['amount'] as num?)?.toInt() ?? 0,
          e['isCredit'] as bool? ?? true,
        );
      }
      return e as (String, String, int, bool);
    }).toList();

    final curve = [120, 180, 150, 210, 240, 300, 280, 340, 320, 390, 420, 480];
    final max = curve.reduce((a, b) => a > b ? a : b);

    return Column(children: [
      _teacherHeader(context, 'Revenus'),
      Expanded(
          child: _revenue == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                          colors: [s.heroFrom, s.heroTo],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOLDE DISPONIBLE',
                            style: WinType.labelS(WinColors.ink300)
                                .copyWith(letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text('${fmtXaf(balance)} XAF',
                            style: WinType.archivo(
                                size: 32, color: WinColors.cream50)),
                        const SizedBox(height: 14),
                        WinButton('Retirer mes gains',
                            variant: WinButtonVariant.accent,
                            small: true,
                            icon: Icons.account_balance_wallet_outlined),
                      ]),
                ),
                const SizedBox(height: 20),
                Text('Revenus mensuels',
                    style: WinType.archivo(size: 18, color: s.onStrong)),
                const SizedBox(height: 12),
                WinCard(
                    child: SizedBox(
                        height: 110,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: curve
                                .map((v) => Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: Container(
                                            height: 110.0 * v / max,
                                            decoration: BoxDecoration(
                                                color: v == max
                                                    ? s.primary
                                                    : WinColors.teal100,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(4)))))))
                                .toList()))),
                const SizedBox(height: 20),
                Text('Transactions',
                    style: WinType.archivo(size: 18, color: s.onStrong)),
                const SizedBox(height: 12),
                WinCard(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(children: [
                      for (int i = 0; i < tx.length; i++)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              border: i < tx.length - 1
                                  ? Border(bottom: BorderSide(color: s.outline))
                                  : null),
                          child: Row(children: [
                            Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: tx[i].$4 ? WinColors.successBg : s.surface2,
                                    shape: BoxShape.circle),
                                child: Icon(
                                    tx[i].$4
                                        ? Icons.trending_up
                                        : Icons.account_balance_wallet_outlined,
                                    size: 16,
                                    color: tx[i].$4 ? WinColors.success : s.onMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  Text(tx[i].$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: WinType.bodyM(s.onStrong)
                                          .copyWith(fontWeight: FontWeight.w600)),
                                  Text(tx[i].$2, style: WinType.labelM(s.onMuted))
                                ])),
                            Text('${tx[i].$4 ? '+' : '−'}${fmtXaf(tx[i].$3)}',
                                style: WinType.archivo(
                                    size: 15,
                                    color: tx[i].$4 ? WinColors.success : s.onStrong)),
                          ]),
                        ),
                    ])),
              if (_contentRevenue.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Revenus par contenu',
                    style: WinType.archivo(size: 18, color: s.onStrong)),
                const SizedBox(height: 12),
                WinCard(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(children: [
                      for (int i = 0; i < _contentRevenue.length; i++)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              border: i < _contentRevenue.length - 1
                                  ? Border(bottom: BorderSide(color: s.outline))
                                  : null),
                          child: Row(children: [
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(
                                  _contentRevenue[i]['title'] as String? ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: WinType.bodyM(s.onStrong)
                                      .copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                  '${_contentRevenue[i]['sales'] ?? 0} ventes',
                                  style: WinType.labelM(s.onMuted)),
                            ])),
                            Text(
                                '+${fmtXaf((_contentRevenue[i]['revenue'] as num?)?.toInt() ?? 0)}',
                                style: WinType.archivo(
                                    size: 15, color: WinColors.success)),
                          ]),
                        ),
                    ])),
              ],
              ])),
    ]);
  }
}

const _fallbackTx = [
  ('Pack ENSP  12 ventes', '8 juin', 96000, true),
  ('Correction BAC C Physique', '6 juin', 27000, true),
  ('Retrait MTN MoMo', '1 juin', 50000, false),
  ('Quiz Chimie  8 ventes', '28 mai', 8000, true),
];
