import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/chatbot_service.dart';
import '../services/teacher_service.dart';
import '../widgets/winai_memories_sheet.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'teacher_courses_screen.dart';
import 'teacher_class_detail_screen.dart';
import '../widgets/win_widgets.dart';
import 'content_publish_screen.dart';
import 'content_actions_sheet.dart';
import 'correction_queue_screen.dart';
import 'session_create_screen.dart';
import 'teacher_links_screen.dart';
import 'tutor_profile_screen.dart';
import 'tutor_bookings_screen.dart';
import 'teacher_wallet_view.dart';

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
              borderRadius: BorderRadius.circular(WinRadii.md)),
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
  int _pendingCorrections = 0;

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
        TeacherService.instance.getSubmissions(),
      ]);
      if (mounted) {
        setState(() {
          _content = results[0] as List<ApiPublishedContent>;
          _stats = results[1] as ApiTeacherStats;
          _pendingCorrections = (results[2] as List<ApiSubmission>)
              .where((s) => !s.corrected)
              .length;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _content = [];
          _stats = null;
        });
      }
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
    final atPublishLimit = subScope.isFree && published.length >= 2;

    final weeklyRev = _stats?.weeklyRevenue ?? [0, 0, 0, 0];
    final maxRev = weeklyRev.reduce((a, b) => a > b ? a : b);
    final pendingCorrections = _pendingCorrections;

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
                          borderRadius: BorderRadius.circular(WinRadii.xl),
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
                                                WinPageRoute(
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
                                        borderRadius: BorderRadius.circular(
                                            WinRadii.full),
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
                                        WinPageRoute(
                                            builder: (_) =>
                                                const CorrectionQueueScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(
                                            WinRadii.full),
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
                                                        top: Radius.circular(
                                                            WinRadii.full)),
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
                  borderRadius: BorderRadius.circular(WinRadii.sm)),
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
      // Bannière formations structurées
      GestureDetector(
        onTap: () => Navigator.push(context,
            WinPageRoute(builder: (_) => const TeacherCoursesScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(WinRadii.lg),
          ),
          child: Row(children: [
            const Icon(Icons.play_lesson_outlined,
                color: WinColors.teal400, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Mes formations', style: WinType.titleM(Colors.white)),
                  Text('Créez et gérez vos cours structurés',
                      style: WinType.labelS(Colors.white54)),
                ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: WinColors.teal600,
                borderRadius: BorderRadius.circular(WinRadii.full),
              ),
              child: Text('Gérer',
                  style: WinType.labelS(Colors.white)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
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

/// Module 12 : classes réelles du professeur (plus de listes codées en dur).
/// L'onglet « Étudiants » global a été retiré : le seul regroupement
/// d'élèves que le serveur connaît réellement est par classe (voir l'audit
/// du module  GET /teacher/students/recent est une route sans rapport,
/// non filtrée par professeur, qu'il aurait été trompeur de brancher ici).
class _TeacherStudentsTabState extends State<TeacherStudentsTab> {
  bool _showArchived = false;
  List<ApiTeacherClass>? _classes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final classes = await TeacherService.instance.getClasses(includeInactive: _showArchived);
      if (mounted) setState(() => _classes = classes);
    } catch (_) {
      if (mounted) setState(() { _classes = []; _error = "Vos classes n'ont pas pu être chargées."; });
    }
  }

  void _showCreateClassSheet() {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    bool busy = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return StatefulBuilder(builder: (ctx, setSheetState) {
          Future<void> submit() async {
            if (nameCtrl.text.trim().length < 2 || levelCtrl.text.trim().isEmpty || yearCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Nom, niveau et année sont requis.')));
              return;
            }
            setSheetState(() => busy = true);
            try {
              await TeacherService.instance.createClass(
                name: nameCtrl.text.trim(),
                level: levelCtrl.text.trim(),
                academicYear: yearCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Classe « ${nameCtrl.text.trim()} » créée.')));
              }
            } catch (_) {
              setSheetState(() => busy = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Cette classe n'a pas pu être créée (nom déjà utilisé ?).")));
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
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
                            decoration: BoxDecoration(color: s.outline, borderRadius: BorderRadius.circular(WinRadii.full)))),
                    Text('Créer une classe', style: WinType.archivo(size: 18, color: s.onStrong)),
                    const SizedBox(height: 16),
                    WinTextField(label: 'Nom de la classe', hint: 'Ex: Terminale C Maths', icon: Icons.class_outlined, controller: nameCtrl),
                    const SizedBox(height: 12),
                    WinTextField(label: 'Niveau', hint: 'Ex: Terminale', icon: Icons.school_outlined, controller: levelCtrl),
                    const SizedBox(height: 12),
                    WinTextField(label: 'Année académique', hint: 'Ex: 2026-2027', icon: Icons.calendar_today_outlined, controller: yearCtrl),
                    const SizedBox(height: 20),
                    WinButton(busy ? 'Création…' : 'Créer', block: true, icon: Icons.add, loading: busy, onTap: submit),
                  ]),
            ),
          );
        });
      },
    );
  }

  Future<void> _classAction(ApiTeacherClass klass) async {
    if (!klass.isActive) {
      try {
        await TeacherService.instance.reactivateClass(klass.id);
        await _load();
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cette classe n'a pas pu être réactivée.")));
      }
      return;
    }
    final result = await Navigator.push<bool>(context,
        WinPageRoute(builder: (_) => TeacherClassDetailScreen(initialClass: klass)));
    if (result != false) await _load();
  }

  Future<void> _deleteOrDeactivate(ApiTeacherClass klass) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(klass.studentCount > 0 ? 'Désactiver la classe ?' : 'Supprimer la classe ?'),
        content: Text(klass.studentCount > 0
            ? '« ${klass.name} » contient ${klass.studentCount} élève(s) : elle sera désactivée (pas supprimée) et retirée de la liste.'
            : 'Supprimer définitivement « ${klass.name} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (klass.studentCount > 0) {
        await TeacherService.instance.deactivateClass(klass.id);
      } else {
        await TeacherService.instance.deleteClass(klass.id);
      }
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cette action a échoué.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(children: [
          Expanded(child: Text('Mes classes', style: WinType.archivo(size: 18, color: s.onStrong))),
          WinChip(_showArchived ? 'Masquer désactivées' : 'Voir désactivées',
              active: _showArchived,
              onTap: () { setState(() => _showArchived = !_showArchived); _load(); }),
        ]),
        const SizedBox(height: 10),
        if (_classes == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Text(_error!, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              WinButton('Réessayer', icon: Icons.refresh, onTap: _load),
            ]),
          )
        else if (_classes!.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(Icons.class_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 8),
              Text(_showArchived ? 'Aucune classe' : 'Aucune classe pour le moment', style: WinType.bodyM(s.onMuted)),
            ]),
          )
        else
          ..._classes!.map((cl) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: cl.isActive ? 1 : 0.6,
                  child: WinCard(
                    padding: const EdgeInsets.all(14),
                    child: InkWell(
                      onTap: () => _classAction(cl),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: s.primaryContainer, borderRadius: BorderRadius.circular(WinRadii.sm)),
                          child: Icon(Icons.class_outlined, size: 20, color: s.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cl.name, style: WinType.titleM(s.onStrong), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Row(children: [
                                Text('${cl.studentCount} élève${cl.studentCount != 1 ? 's' : ''}', style: WinType.labelM(s.onMuted)),
                                if (cl.classAverage != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.bar_chart_outlined, size: 12, color: cl.classAverage! >= 70 ? WinColors.success : WinColors.warn),
                                  const SizedBox(width: 2),
                                  Text('${cl.classAverage}% moy.', style: WinType.labelM(cl.classAverage! >= 70 ? WinColors.success : WinColors.warn)),
                                ],
                                if (cl.pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  WinBadge('${cl.pendingCount} à corriger', color: BadgeColor.warn),
                                ],
                                if (!cl.isActive) ...[
                                  const SizedBox(width: 8),
                                  Text('Désactivée', style: WinType.labelM(s.onFaint)),
                                ],
                              ]),
                            ])),
                        if (cl.isActive)
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 19, color: s.onFaint),
                            onPressed: () => _deleteOrDeactivate(cl),
                          )
                        else
                          Icon(Icons.restore, size: 18, color: s.primary),
                      ]),
                    ),
                  ),
                ),
              )),
        WinButton('Créer une classe',
            variant: WinButtonVariant.outline, block: true, icon: Icons.add, onTap: _showCreateClassSheet),
        const SizedBox(height: 10),
        WinButton('Mes liaisons directes',
            variant: WinButtonVariant.outline,
            block: true,
            icon: Icons.link_outlined,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TeacherLinksScreen()))),
        const SizedBox(height: 10),
        WinButton('Mode Tuteur',
            variant: WinButtonVariant.outline,
            block: true,
            icon: Icons.school_outlined,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TutorProfileScreen()))),
        const SizedBox(height: 10),
        WinButton('Mes réservations élèves',
            variant: WinButtonVariant.outline,
            block: true,
            icon: Icons.event_available_outlined,
            onTap: () => Navigator.push(context, WinPageRoute(builder: (_) => const TutorBookingsScreen()))),
      ],
    );
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
                onTap: () => Navigator.push(context,
                    WinPageRoute(builder: (_) => const SessionCreateScreen()))),
          ])),
    ]);
  }
}

/// ===================== REVENUS =====================
/// Lot 2, Module 5 : portefeuille réel (solde unifié, historique du journal,
/// retrait Mobile Money automatisé, recharge), en parité avec le web. L'ancien
/// onglet affichait un solde de repli (184 500), une courbe, une commission et
/// des transactions inventés, y compris quand l'appel réseau échouait.
class TeacherRevenueTab extends StatelessWidget {
  const TeacherRevenueTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const Column(children: [Expanded(child: TeacherWalletView())]);
}

/// ===================== WINAI =====================
class TeacherWinAITab extends StatefulWidget {
  final String? initialMessage;
  const TeacherWinAITab({super.key, this.initialMessage});
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

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _send(widget.initialMessage));
    }
  }

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
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('WinAI', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
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
                                      color: WinColors.gold
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(WinRadii.md),
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
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => showWinAIMemoriesSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(WinRadii.full),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.psychology_rounded,
                              size: 15, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 8),
                          Text('Mémoire WinAI',
                              style: WinType.manrope(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6))),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Color(0xFF8B5CF6)),
                        ]),
                      ),
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
                              borderRadius: BorderRadius.circular(WinRadii.lg)),
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
                          borderRadius: BorderRadius.circular(WinRadii.lg),
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
                  height: 48,
                  decoration:
                      BoxDecoration(color: s.primary, shape: BoxShape.circle),
                  child: Icon(Icons.send, size: 20, color: s.onPrimary)),
            ),
          ]),
        ),
      ]),
    );
  }
}
