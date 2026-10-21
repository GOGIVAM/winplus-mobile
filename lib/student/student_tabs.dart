import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../services/chatbot_service.dart';
import '../widgets/winai_memories_sheet.dart';
import '../services/subject_service.dart';
import '../services/student_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/shop/cart_screen.dart';
import '../shared/shop/orders_screen.dart';
import 'student_home.dart';
import 'search_screen.dart';
import 'download_history_screen.dart';
import 'favorites_screen.dart';
import 'achievements_screen.dart';
import 'certificates_screen.dart';
import 'exam_coach_screen.dart';
import 'study_groups_screen.dart';
import 'study_session_screen.dart';
import 'student_reports_screen.dart';
import 'quiz_revision_screen.dart';
import 'my_courses_screen.dart';
import 'course_catalog_screen.dart';
import 'tutors/tutor_search_screen.dart';
import 'tutors/my_tutor_bookings_screen.dart';
import '../widgets/knowledge_base_toggle.dart';

export 'student_home.dart' show StudentHomeTab;

/// ===================== CATALOGUE =====================
class StudentCatalogTab extends StatefulWidget {
  const StudentCatalogTab({super.key});
  @override
  State<StudentCatalogTab> createState() => _StudentCatalogTabState();
}

class _StudentCatalogTabState extends State<StudentCatalogTab> {
  String _type = 'Tout';
  List<Content>? _allItems;
  bool _error = false;

  static const _types = [
    'Tout',
    'Épreuves',
    'Corrections',
    'Quiz',
    'Livres',
    'Packs'
  ];
  static const _contentTypeMap = {
    'Épreuves': ContentType.epreuve,
    'Corrections': ContentType.correction,
    'Quiz': ContentType.quiz,
    'Livres': ContentType.livre,
    'Packs': ContentType.pack,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _allItems = null;
      _error = false;
    });
    try {
      final page = await SubjectService.instance.getAll(pageSize: 50);
      if (mounted)
        setState(
            () => _allItems = page.items.map((s) => s.toContent()).toList());
    } catch (_) {
      // Pas de catalogue de démonstration : erreur affichée avec « Réessayer ».
      if (mounted)
        setState(() {
          _allItems = [];
          _error = true;
        });
    }
  }

  // Libellés affichés ; les valeurs des filtres restent celles d'origine.
  String _typeLabel(String t) => switch (t) {
        'Tout' => context.l10n.commonAll,
        'Épreuves' => context.l10n.studentTabsTypePapers,
        'Corrections' => context.l10n.studentTabsTypeCorrections,
        'Livres' => context.l10n.studentTabsTypeBooks,
        'Packs' => context.l10n.studentTabsTypePacks,
        _ => t,
      };

  List<Content> get _filtered {
    final all = _allItems ?? [];
    if (_type == 'Tout') return all;
    final ct = _contentTypeMap[_type];
    return ct == null ? all : all.where((c) => c.type == ct).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _filtered;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Text(context.l10n.shellTabCatalog,
              style: WinType.archivo(size: 22, color: s.onStrong)),
          const Spacer(),
          if (_allItems != null)
            IconButton(
              icon: Icon(Icons.refresh_outlined, size: 20, color: s.onMuted),
              onPressed: _load,
            ),
          IconButton(
            icon:
                Icon(Icons.shopping_cart_outlined, size: 20, color: s.onMuted),
            onPressed: () => Navigator.push(
                context, WinPageRoute(builder: (_) => const CartScreen())),
          ),
        ]),
      ),
      // Bannière formations
      GestureDetector(
        onTap: () => Navigator.push(
            context, WinPageRoute(builder: (_) => const CourseCatalogScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(WinRadii.sm),
          ),
          child: Row(children: [
            const Icon(Icons.play_lesson_outlined,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentTabsStructuredCourses,
                      style: WinType.titleM(Colors.white)),
                  Text(context.l10n.studentTabsStructuredCoursesSub,
                      style: WinType.labelS(Colors.white70)),
                ])),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white60, size: 14),
          ]),
        ),
      ),
      // Bannière répétiteurs (Mode Répétiteur  professeur_complete.md)
      GestureDetector(
        onTap: () => Navigator.push(
            context, WinPageRoute(builder: (_) => const TutorSearchScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(WinRadii.sm),
          ),
          child: Row(children: [
            const Icon(Icons.person_search_outlined,
                color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentTabsFindTutor,
                      style: WinType.titleM(Colors.white)),
                  Text(context.l10n.studentTabsFindTutorSub,
                      style: WinType.labelS(Colors.white70)),
                ])),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white60, size: 14),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const SearchScreen())),
          child:
              WinTextField(icon: Icons.search, hint: context.l10n.studentTabsSearchHint),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _types.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => WinChip(_typeLabel(_types[i]),
              active: _type == _types[i],
              onTap: () => setState(() => _type = _types[i])),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _allItems == null
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                    const SizedBox(height: 12),
                    Text(context.l10n.studentTabsCatalogLoadError,
                        style: WinType.bodyM(s.onMuted)),
                    const SizedBox(height: 12),
                    WinButton(context.l10n.commonRetry, onTap: _load),
                  ]))
                : items.isEmpty
                    ? Center(
                        child: Text(context.l10n.studentTabsNoContent,
                            style: WinType.bodyM(s.onMuted)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72),
                        itemCount: items.length,
                        itemBuilder: (_, i) => ContentCard(content: items[i]),
                      ),
      ),
    ]);
  }
}

/// ===================== MON ESPACE =====================
class StudentSpaceTab extends StatefulWidget {
  const StudentSpaceTab({super.key});
  @override
  State<StudentSpaceTab> createState() => _StudentSpaceTabState();
}

/// Statistiques réelles (GET /student/stats) ; « — » tant qu'elles ne sont
/// pas chargées. Plus de score ni de temps d'étude de démonstration.
class _StudentSpaceTabState extends State<StudentSpaceTab> {
  ApiStudentStats? _stats;

  @override
  void initState() {
    super.initState();
    StudentService.instance.getStats().then((st) {
      if (mounted) setState(() => _stats = st);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final avg = _stats != null ? '${_stats!.averageScore.round()}%' : '—';
    final week =
        _stats != null ? '${_stats!.weeklyStudyHoursTotal.round()}h' : '—';
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text(context.l10n.shellTabMySpace,
                  style: WinType.archivo(size: 22, color: s.onStrong)))),
      Expanded(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(children: [
                Expanded(
                    child: _MiniStat(avg, context.l10n.studentReportsAvgScore, Icons.trending_up)),
                const SizedBox(width: 10),
                Expanded(
                    child: _MiniStat(week, context.l10n.studentTabsStudyThisWeek,
                        Icons.schedule)),
              ]),
              const SizedBox(height: 16),
              // Formations
              _QuickLink(
                  context.l10n.studentMyCoursesTitle,
                  Icons.play_lesson_outlined,
                  WinColors.teal600,
                  () => Navigator.push(context,
                      WinPageRoute(builder: (_) => const MyCoursesScreen()))),
              const SizedBox(height: 10),
              _QuickLink(
                  context.l10n.studentTabsCourseCatalog,
                  Icons.explore_outlined,
                  WinColors.teal400,
                  () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => const CourseCatalogScreen()))),
              const SizedBox(height: 10),
              _QuickLink(
                  context.l10n.studentTabsFindTutor,
                  Icons.person_search_outlined,
                  WinColors.blue500,
                  () => Navigator.push(context,
                      WinPageRoute(builder: (_) => const TutorSearchScreen()))),
              const SizedBox(height: 10),
              _QuickLink(
                  context.l10n.studentTabsMyBookings,
                  Icons.event_available_outlined,
                  WinColors.teal500,
                  () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => const MyTutorBookingsScreen()))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentTabsFavorites,
                        Icons.favorite_border,
                        WinColors.error,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const FavoritesScreen())))),
                const SizedBox(width: 10),
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentHomeBadges,
                        Icons.emoji_events_outlined,
                        WinColors.gold,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const AchievementsScreen())))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentTabsCertificates,
                        Icons.workspace_premium_outlined,
                        WinColors.teal400,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const CertificatesScreen())))),
                const SizedBox(width: 10),
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentTabsExamCoach,
                        Icons.school_outlined,
                        WinColors.ink600,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const ExamCoachScreen())))),
              ]),
              const SizedBox(height: 10),
              // Module 32 (lot 8, décision 14.3) : portage mobile de la
              // session d'étude guidée (briefing → quiz → synthèse WinAI),
              // point d'entrée équivalent à StudySessionLauncher côté web.
              _QuickLink(
                  context.l10n.studentTabsGuidedSession,
                  Icons.auto_awesome_outlined,
                  WinColors.teal500,
                  () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => const StudySessionScreen()))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentTabsMyCart,
                        Icons.shopping_cart_outlined,
                        WinColors.teal600,
                        () => Navigator.push(context,
                            WinPageRoute(builder: (_) => const CartScreen())))),
                const SizedBox(width: 10),
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentTabsMyOrders,
                        Icons.receipt_long_outlined,
                        WinColors.blue500,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const OrdersScreen())))),
              ]),
              const SizedBox(height: 10),
              _QuickLink(
                  context.l10n.studentHubHistory,
                  Icons.download_outlined,
                  WinColors.ink400,
                  () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => const DownloadHistoryScreen()))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentLinksStudyGroups,
                        Icons.groups_outlined,
                        WinColors.teal600,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) => const StudyGroupsScreen())))),
                const SizedBox(width: 10),
                Expanded(
                    child: _QuickLink(
                        context.l10n.studentReportsTitle,
                        Icons.bar_chart_outlined,
                        WinColors.blue500,
                        () => Navigator.push(
                            context,
                            WinPageRoute(
                                builder: (_) =>
                                    const StudentReportsScreen())))),
              ]),
              const SizedBox(height: 10),
              _QuickLink(
                  context.l10n.studentHubRevisionQuiz,
                  Icons.quiz_outlined,
                  WinColors.warn,
                  () => Navigator.push(
                      context,
                      WinPageRoute(
                          builder: (_) => const QuizRevisionScreen()))),
              // « Performance par matière » de démonstration retirée : aucun
              // score par matière n'est servi pour l'élève ; ses résultats
              // réels sont dans « Mes rapports ».
            ]),
      ),
    ]);
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: WinType.titleM(s.onStrong))),
        Icon(Icons.chevron_right, size: 18, color: s.onFaint),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _MiniStat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: s.primary),
          const SizedBox(height: 8),
          Text(value, style: WinType.archivo(size: 22, color: s.onStrong)),
          Text(label, style: WinType.labelM(s.onMuted)),
        ]));
  }
}

/// ===================== WINAI =====================
class StudentWinAITab extends StatefulWidget {
  final String? initialMessage;
  const StudentWinAITab({super.key, this.initialMessage});
  @override
  State<StudentWinAITab> createState() => _StudentWinAITabState();
}

class _StudentWinAITabState extends State<StudentWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text, String? attachment})> _msgs = [];
  bool _thinking = false;

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
      _msgs.add((me: true, text: t, attachment: null));
      _ctrl.clear();
      _thinking = true;
    });
    final reply = await ChatbotService.instance.sendMessage(message: t);
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add((
        me: false,
        text: reply ?? L10n.current.studentTabsAiNoReply,
        attachment: null
      ));
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final name = file.name;
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
        .contains(name.split('.').last.toLowerCase());
    setState(() {
      _msgs.add((
        me: true,
        text: L10n.current.studentTabsAiFileAttached(name),
        attachment: isImage ? 'image' : 'file'
      ));
      _thinking = true;
    });
    final reply = await ChatbotService.instance.sendMessage(
      message: 'Analyse ce fichier : $name',
    );
    if (!mounted) return;
    setState(() {
      _thinking = false;
      _msgs.add((
        me: false,
        text: reply ?? L10n.current.studentTabsAiFileReceived,
        attachment: null
      ));
    });
  }

  void _showAttachSheet() {
    final s = WinTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
            color: s.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: s.outline2,
                  borderRadius: BorderRadius.circular(WinRadii.full))),
          Text(context.l10n.studentTabsAttachFile, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 20),
          _AttachOption(
              Icons.image_outlined, context.l10n.studentTabsAttachImage, WinColors.blue500, () {
            Navigator.pop(context);
            _pickFile();
          }),
          const SizedBox(height: 12),
          _AttachOption(Icons.description_outlined, context.l10n.studentTabsAttachDocument,
              WinColors.teal500, () {
            Navigator.pop(context);
            _pickFile();
          }),
          const SizedBox(height: 12),
          _AttachOption(Icons.mic_outlined, context.l10n.studentTabsAttachVoice, WinColors.warn,
              () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(context.l10n.studentTabsVoiceSoon)),
            );
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final suggestions = [
      context.l10n.studentTabsAiSuggest1,
      context.l10n.studentTabsAiSuggest2,
      context.l10n.studentTabsAiSuggest3,
      context.l10n.studentTabsAiSuggest4
    ];
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
                    Text(context.l10n.studentTabsAiTagline,
                        style: WinType.bodyM(s.onMuted)),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: suggestions
                          .map((q) => GestureDetector(
                                onTap: () => _send(q),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: WinColors.teal50,
                                      borderRadius:
                                          BorderRadius.circular(WinRadii.sm),
                                      border:
                                          Border.all(color: WinColors.teal100)),
                                  alignment: Alignment.centerLeft,
                                  child: Text(q,
                                      style: WinType.manrope(
                                          size: 13,
                                          weight: FontWeight.w600,
                                          color: WinColors.teal700)),
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
                          borderRadius: BorderRadius.circular(WinRadii.sm),
                          border: Border.all(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.psychology_rounded,
                              size: 15, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 8),
                          Text(context.l10n.commonWinaiMemory,
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
                            Text(context.l10n.commonWinaiThinking,
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
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (m.attachment != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            m.attachment == 'image'
                                                ? Icons.image_outlined
                                                : Icons.attach_file,
                                            size: 14,
                                            color: m.me
                                                ? WinColors.teal300
                                                : s.primary),
                                        const SizedBox(width: 4),
                                        Text(context.l10n.studentTabsAttachment,
                                            style: WinType.labelS(m.me
                                                ? WinColors.teal300
                                                : s.primary)),
                                      ]),
                                ),
                              Text(m.text,
                                  style: WinType.bodyM(
                                      m.me ? WinColors.cream50 : s.onSurface)),
                            ]),
                      ),
                    );
                  },
                ),
        ),
        const KnowledgeBaseToggle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(children: [
            GestureDetector(
              onTap: _showAttachSheet,
              child: Container(
                width: 46,
                height: 50,
                decoration: BoxDecoration(
                    color: s.surface2,
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                    border: Border.all(color: s.outline)),
                child: Icon(Icons.attach_file, size: 20, color: s.onMuted),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: WinTextField(
                    hint: context.l10n.studentTabsAiHint, controller: _ctrl)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                  width: 48,
                  height: 50,
                  decoration: BoxDecoration(
                      color: s.primary,
                      borderRadius: BorderRadius.circular(WinRadii.sm)),
                  child: Icon(Icons.send, size: 20, color: s.onPrimary)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(WinRadii.lg),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Text(label,
              style: WinType.bodyM(s.onStrong)
                  .copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
