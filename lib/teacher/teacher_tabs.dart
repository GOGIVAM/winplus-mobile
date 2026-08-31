import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/chatbot_service.dart';
import '../services/teacher_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'content_publish_screen.dart';
import 'content_actions_sheet.dart';
import 'correction_queue_screen.dart';
import 'session_create_screen.dart';
import '../shared/messaging/messaging_screen.dart';
import 'teacher_links_screen.dart';

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
              color: Colors.white.withValues(alpha: 0.08),
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
  ApiTeacherStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        TeacherService.instance.getMyContent(),
        TeacherService.instance.getStats(),
      ]);
      if (mounted)
        setState(() {
          _content = results[0] as List<ApiPublishedContent>;
          _stats = results[1] as ApiTeacherStats;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _content = [];
          _stats = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = _content ?? [];
    final published = content
        .where((c) => c.status == 'published' || c.status == 'Publié')
        .toList();
    final totalDl = content.fold(0, (a, c) => a + c.downloads);
    final avgRating = published.isEmpty
        ? 0.0
        : published.fold(0.0, (a, c) => a + c.rating) / published.length;
    final subScope = SubscriptionScope.of(context);
    final atPublishLimit =
        subScope.isFree && published.length >= 2;

    final weeklyRev = _stats?.weeklyRevenue ?? [0, 0, 0, 0];
    final maxRev = weeklyRev.reduce((a, b) => a > b ? a : b);
    const pendingCorrections = 0;

    return Column(children: [
      Expanded(
          child: _content == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                      // 1. Hero avec boutons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [s.heroFrom, s.heroTo],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PLAN EXPERT',
                                  style: WinType.labelS(WinColors.ink300)
                                      .copyWith(letterSpacing: 0.8)),
                              const SizedBox(height: 8),
                              Text.rich(TextSpan(
                                  style: WinType.bodyL(WinColors.cream50),
                                  children: [
                                    const TextSpan(text: 'Bonjour M. Fotso  '),
                                    _accent('80% de vos revenus'),
                                  ])),
                              const SizedBox(height: 18),
                              Row(children: [
                                Expanded(
                                    child: _heroStat('${published.length}',
                                        'publiés', 'En ligne')),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _heroStat(
                                        avgRating > 0
                                            ? avgRating.toStringAsFixed(1)
                                            : '',
                                        'note moy.',
                                        'Sur 5')),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: atPublishLimit
                                        ? null
                                        : () async {
                                            await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const ContentPublishScreen()));
                                            setState(() => _content = null);
                                            _load();
                                          },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: atPublishLimit
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : WinColors.teal400,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add,
                                                size: 16,
                                                color: atPublishLimit
                                                    ? WinColors.ink300
                                                    : WinColors.ink900),
                                            const SizedBox(width: 6),
                                            Text('Publier',
                                                style: WinType.manrope(
                                                    size: 13,
                                                    weight: FontWeight.w700,
                                                    color: atPublishLimit
                                                        ? WinColors.ink300
                                                        : WinColors.ink900)),
                                          ]),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const CorrectionQueueScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Corrections${pendingCorrections > 0 ? ' ($pendingCorrections)' : ''}',
                                        style: WinType.manrope(
                                            size: 13,
                                            weight: FontWeight.w600,
                                            color: WinColors.cream100),
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ]),
                      ),
                      const SizedBox(height: 16),

                      // 2. Statistiques calculées
                      Row(children: [
                        Expanded(
                            child: _statCard(
                                context,
                                Icons.description_outlined,
                                '${published.length}',
                                'Contenus publiés')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statCard(context, Icons.download_outlined,
                                '$totalDl', 'Téléchargements')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _statCard(
                                context,
                                Icons.star_outline,
                                avgRating > 0
                                    ? avgRating.toStringAsFixed(1)
                                    : '',
                                'Note moyenne')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statCard(
                                context,
                                Icons.people_outline,
                                '${_stats?.activeStudents ?? ''}',
                                'Étudiants actifs')),
                      ]),
                      const SizedBox(height: 24),

                      // 3. Revenus du mois
                      Text('Revenus du mois',
                          style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 4),
                      Text(
                          '${fmtXaf(_stats?.thisMonthRevenue ?? 0)} XAF ce mois',
                          style: WinType.archivo(size: 22, color: s.primary)),
                      const SizedBox(height: 12),
                      WinCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('4 dernières semaines',
                                  style: WinType.labelS(s.onMuted)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 60,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(4, (i) {
                                    final val = weeklyRev[i];
                                    final h = maxRev == 0
                                        ? 4.0
                                        : (val / maxRev) * 60.0;
                                    return Expanded(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              height: h.clamp(4.0, 60.0),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4),
                                              decoration: BoxDecoration(
                                                color: i == 3
                                                    ? s.primary
                                                    : s.primary.withValues(
                                                        alpha: 0.35),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(4)),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('S${i + 1}',
                                                style:
                                                    WinType.labelS(s.onFaint)),
                                          ]),
                                    );
                                  }),
                                ),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 24),

                      // 4. Insights WinAI
                      Text('Vos insights',
                          style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 12),
                      ...WinData.teacherInsights.map((ins) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: WinCard(
                              child: Row(children: [
                                Icon(ins.icon, size: 18, color: s.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(ins.text,
                                        style: WinType.bodyS(s.onStrong))),
                              ]),
                            ),
                          )),
                      const SizedBox(height: 24),

                      // 5. Contenus récents (3 derniers)
                      Text('Contenus récents',
                          style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 12),
                      if (content.isEmpty)
                        Center(
                            child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Aucun contenu publié.',
                              style: WinType.bodyM(s.onMuted)),
                        ))
                      else
                        ...content.take(3).map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ContentRow(
                                c: c,
                                onChanged: () {
                                  setState(() => _content = null);
                                  _load();
                                }))),
                    ])),
    ]);
  }
}

class _ContentRow extends StatelessWidget {
  final ApiPublishedContent c;
  final VoidCallback? onChanged;
  const _ContentRow({required this.c, this.onChanged});
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
                    '${c.downloads} téléch.${c.rating > 0 ? '  ·  ${c.rating.toStringAsFixed(1)}' : ''}',
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                ContentActionsSheet.show(context, c, onChanged: onChanged),
            child: Icon(Icons.more_vert, size: 20, color: s.onFaint),
          ),
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
                      return Text('Aucun contenu.',
                          style: WinType.bodyM(s.onMuted));
                    }))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _ContentRow(c: _items[i], onChanged: _load))),
    ]);
  }
}

/// ===================== ÉTUDIANTS =====================
class TeacherStudentsTab extends StatefulWidget {
  const TeacherStudentsTab({super.key});
  @override
  State<TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  String _search = '';
  String _filter = 'Tous';
  static const _filters = ['Tous', 'Actifs', 'En difficulté'];

  static const _allStudents = [
    (name: 'Ahmed Nkono', level: 'Tle C', avg: 78, up: true),
    (name: 'Brenda Mballa', level: 'Tle C', avg: 86, up: true),
    (name: 'Yann Talla', level: 'Tle C', avg: 44, up: false),
    (name: 'Fatima Koné', level: '1ère D', avg: 71, up: true),
    (name: 'Paul Essama', level: '1ère D', avg: 38, up: false),
    (name: 'Alice Nguema', level: 'Tle C', avg: 65, up: true),
    (name: 'Kevin Nkembi', level: 'Tle C', avg: 82, up: true),
    (name: 'Marie Atangana', level: '1ère D', avg: 52, up: false),
  ];

  // (name, count, avg)
  static const _classes = [
    (name: 'Tle C · Groupe A', count: 28, avg: 74),
    (name: 'Tle C · Groupe B', count: 31, avg: 68),
    (name: '1ère D', count: 24, avg: 71),
  ];

  void _showCreateClassSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: s.outline,
                              borderRadius: BorderRadius.circular(2)))),
                  Text('Créer une classe',
                      style: WinType.archivo(size: 18, color: s.onStrong)),
                  const SizedBox(height: 16),
                  WinTextField(
                      label: 'Nom de la classe',
                      hint: 'Ex: Terminale C Maths',
                      icon: Icons.class_outlined,
                      controller: ctrl),
                  const SizedBox(height: 20),
                  WinButton('Créer', block: true, icon: Icons.add, onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Classe « ${ctrl.text} » créée.')));
                  }),
                ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final students = _allStudents.where((st) {
      final matchSearch = _search.isEmpty ||
          st.name.toLowerCase().contains(_search.toLowerCase());
      final matchFilter = _filter == 'Tous' ||
          (_filter == 'Actifs' && st.avg >= 50) ||
          (_filter == 'En difficulté' && st.avg < 50);
      return matchSearch && matchFilter;
    }).toList();

    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WinTextField(
              icon: Icons.search,
              hint: 'Rechercher un étudiant…',
              onChanged: (v) => setState(() => _search = v))),
      const SizedBox(height: 8),
      SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _filters
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: WinChip(f,
                        active: _filter == f,
                        onTap: () => setState(() => _filter = f)),
                  ))
              .toList(),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
            Text('Mes classes',
                style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 10),
            ..._classes.map((cl) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WinCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: s.primaryContainer,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.class_outlined,
                            size: 20, color: s.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(cl.name,
                                style: WinType.titleM(s.onStrong),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Row(children: [
                              Text('${cl.count} élèves',
                                  style: WinType.labelM(s.onMuted)),
                              const SizedBox(width: 8),
                              Icon(Icons.bar_chart_outlined,
                                  size: 12,
                                  color: cl.avg >= 70
                                      ? WinColors.success
                                      : WinColors.warn),
                              const SizedBox(width: 2),
                              Text('${cl.avg}% moy.',
                                  style: WinType.labelM(cl.avg >= 70
                                      ? WinColors.success
                                      : WinColors.warn)),
                            ]),
                          ])),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 18, color: s.onFaint),
                    ]),
                  ),
                )),
            WinButton('Créer une classe',
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.add,
                onTap: _showCreateClassSheet),
            const SizedBox(height: 10),
            WinButton('Mes liaisons directes',
                variant: WinButtonVariant.outline,
                block: true,
                icon: Icons.link_outlined,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TeacherLinksScreen()))),
            const SizedBox(height: 24),
            Text('Étudiants',
                style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 10),
            ...students.map((st) {
              final col = st.avg < 50
                  ? WinColors.error
                  : (st.avg < 75 ? WinColors.warn : WinColors.success);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WinCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      WinAvatar(st.name, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(st.name, style: WinType.titleM(s.onStrong)),
                            Text(st.level, style: WinType.labelM(s.onMuted)),
                          ])),
                      Icon(st.up ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: st.up ? WinColors.success : WinColors.error),
                      const SizedBox(width: 4),
                      Text('${st.avg}%',
                          style: WinType.archivo(size: 16, color: col)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MessagingScreen())),
                        child: Icon(Icons.chat_outlined,
                            size: 20, color: s.primary),
                      ),
                    ])),
              );
            }),
          ])),
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
    final now = DateTime.now();
    const _jours = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    const _mois = [
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
    final dateLabel =
        "Aujourd'hui, ${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]}";
    return Column(children: [
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
            Text(dateLabel, style: WinType.titleS(s.onMuted)),
            const SizedBox(height: 12),
            ...sessions.map((se) {
              return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WinCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(width: 4, height: 36, color: se.$1),
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
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SessionCreateScreen()))),
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
        setState(() {
          _revenue = {};
          _contentRevenue = [];
        });
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
                              const WinButton('Retirer mes gains',
                                  variant: WinButtonVariant.accent,
                                  small: true,
                                  icon: Icons.account_balance_wallet_outlined),
                            ]),
                      ),
                      const SizedBox(height: 16),
                      WinCard(
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                                color: WinColors.successBg,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.percent,
                                size: 18, color: WinColors.success),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Commission Plan Expert',
                                    style: WinType.labelM(s.onMuted)),
                                Text('80% pour vous · 20% WinPlus',
                                    style: WinType.titleM(s.onStrong)),
                              ])),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 2),
                                              child: Container(
                                                  height: 110.0 * v / max,
                                                  decoration: BoxDecoration(
                                                      color: v == max
                                                          ? s.primary
                                                          : WinColors.teal100,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .vertical(
                                                              top:
                                                                  Radius.circular(
                                                                      4)))))))
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
                                        ? Border(
                                            bottom:
                                                BorderSide(color: s.outline))
                                        : null),
                                child: Row(children: [
                                  Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                          color: tx[i].$4
                                              ? WinColors.successBg
                                              : s.surface2,
                                          shape: BoxShape.circle),
                                      child: Icon(
                                          tx[i].$4
                                              ? Icons.trending_up
                                              : Icons
                                                  .account_balance_wallet_outlined,
                                          size: 16,
                                          color: tx[i].$4
                                              ? WinColors.success
                                              : s.onMuted)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(tx[i].$1,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: WinType.bodyM(s.onStrong)
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text(tx[i].$2,
                                            style: WinType.labelM(s.onMuted))
                                      ])),
                                  Text(
                                      '${tx[i].$4 ? '+' : '−'}${fmtXaf(tx[i].$3)}',
                                      style: WinType.archivo(
                                          size: 15,
                                          color: tx[i].$4
                                              ? WinColors.success
                                              : s.onStrong)),
                                ]),
                              ),
                          ])),
                      if (_contentRevenue.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Revenus par contenu',
                            style:
                                WinType.archivo(size: 18, color: s.onStrong)),
                        const SizedBox(height: 12),
                        WinCard(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(children: [
                              for (int i = 0; i < _contentRevenue.length; i++)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      border: i < _contentRevenue.length - 1
                                          ? Border(
                                              bottom:
                                                  BorderSide(color: s.outline))
                                          : null),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              _contentRevenue[i]['title']
                                                      as String? ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: WinType.bodyM(s.onStrong)
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                          Text(
                                              '${_contentRevenue[i]['sales'] ?? 0} ventes',
                                              style: WinType.labelM(s.onMuted)),
                                        ])),
                                    Text(
                                        '+${fmtXaf((_contentRevenue[i]['revenue'] as num?)?.toInt() ?? 0)}',
                                        style: WinType.archivo(
                                            size: 15,
                                            color: WinColors.success)),
                                  ]),
                                ),
                            ])),
                      ],
                    ])),
    ]);
  }
}

/// ===================== WINAI =====================
class TeacherWinAITab extends StatefulWidget {
  const TeacherWinAITab({super.key});
  @override
  State<TeacherWinAITab> createState() => _TeacherWinAITabState();
}

class _TeacherWinAITabState extends State<TeacherWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text})> _msgs = [];
  bool _thinking = false;

  static const _suggestions = [
    'Quiz Terminale C (10 QCM)',
    'Fiche de cours',
    'Correction type',
    'Optimiser un titre',
  ];

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add((me: true, text: t));
      _ctrl.clear();
      _thinking = true;
    });
    final reply = await ChatbotService.instance.sendMessage(message: t);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add((
        me: false,
        text: reply ?? 'Désolé, je n\'ai pas pu répondre. Réessaie.'
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      Expanded(
        child: _msgs.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Spacer(),
                  const WinAIOrb(size: 80),
                  const SizedBox(height: 20),
                  Text('WinAI',
                      style: WinType.archivo(size: 28, color: s.onStrong)),
                  const SizedBox(height: 6),
                  Text('Ton assistant éditorial & pédagogique',
                      style: WinType.bodyM(s.onMuted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: _suggestions
                        .map((q) => GestureDetector(
                              onTap: () => _send(q),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color:
                                        WinColors.gold.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: WinColors.gold
                                            .withValues(alpha: 0.25))),
                                alignment: Alignment.centerLeft,
                                child: Text(q,
                                    style: WinType.manrope(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: WinColors.gold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ))
                        .toList(),
                  ),
                  const Spacer(),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _msgs.length + (_thinking ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_thinking && i == _msgs.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: s.cardBg,
                            border: Border.all(color: s.cardBorder),
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: s.primary)),
                          const SizedBox(width: 8),
                          Text('WinAI réfléchit…',
                              style: WinType.bodyS(s.onMuted)),
                        ]),
                      ),
                    );
                  }
                  final m = _msgs[i];
                  return Align(
                    alignment:
                        m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.me ? WinColors.ink800 : s.cardBg,
                        border: m.me ? null : Border.all(color: s.cardBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text,
                          style: WinType.bodyM(
                              m.me ? WinColors.cream50 : s.onSurface)),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(children: [
          Expanded(
              child: WinTextField(
                  hint: 'Génère un quiz, une fiche, une correction…',
                  controller: _ctrl)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
                width: 48,
                height: 50,
                decoration: BoxDecoration(
                    color: s.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.send, size: 20, color: s.onPrimary)),
          ),
        ]),
      ),
    ]);
  }
}

const _fallbackTx = [
  ('Pack ENSP  12 ventes', '8 juin', 96000, true),
  ('Correction BAC C Physique', '6 juin', 27000, true),
  ('Retrait MTN MoMo', '1 juin', 50000, false),
  ('Quiz Chimie  8 ventes', '28 mai', 8000, true),
];
