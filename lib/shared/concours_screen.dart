import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/concours_service.dart';
import '../services/subject_service.dart';
import '../student/content_detail_screen.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/external_links.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

(String, BadgeColor) _status(AppLocalizations l, String status) => switch (status) {
      'open' => (l.concRegOpen, BadgeColor.success),
      'upcoming' => (l.concRegUpcoming, BadgeColor.blue),
      'closed' => (l.concRegClosed, BadgeColor.neutral),
      _ => ('', BadgeColor.neutral),
    };

/// « Concours et examens » (lot 7), comme le hub /concours du site : les
/// quatorze concours et examens, le nombre d'épreuves publiées et la
/// prochaine date du calendrier officiel.
class ConcoursHubScreen extends StatefulWidget {
  const ConcoursHubScreen({super.key});

  @override
  State<ConcoursHubScreen> createState() => _ConcoursHubScreenState();
}

class _ConcoursHubScreenState extends State<ConcoursHubScreen> {
  final _svc = ConcoursService.instance;
  Map<String, ConcoursEvent> _events = const {};
  final Map<String, int?> _counts = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Les écoles sont connues d'avance : la liste s'affiche tout de suite, et
    // le calendrier puis le nombre d'épreuves de chaque école arrivent un à
    // un (lot 8 : l'écran attendait toutes les réponses et restait sur son
    // squelette quand un seul calcul traînait).
    setState(() => _loaded = true);
    final events = _svc.events().catchError((_) => <String, ConcoursEvent>{}).then((e) {
      if (mounted) setState(() => _events = e);
    });
    final counts = concoursSchools.map((c) => _svc
        .stats(c.slug)
        .then<int?>((s) => s.total)
        .catchError((_) => null)
        .then((n) {
          if (mounted) setState(() => _counts[c.slug] = n);
        }));
    await Future.wait([events, ...counts]);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final lang = L10n.locale.languageCode;
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.concTitle)),
      body: SafeArea(
        child: !_loaded
            ? const WinLoading()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                  Text(l.concIntro, style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  for (final c in concoursSchools) _school(s, l, c, _events[c.slug], lang, now),
                ]),
              ),
      ),
    );
  }

  Widget _school(WinScheme s, AppLocalizations l, ConcoursSchool c, ConcoursEvent? e, String lang, DateTime now) {
    final count = _counts[c.slug];
    final next = e?.nextDate(now);
    final (statusText, statusColor) = _status(l, e?.registrationStatus ?? 'unknown');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConcoursDetailScreen(school: c))),
        child: Row(children: [
          Icon(PhosphorIconsRegular.graduationCap, color: s.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: WinType.titleS(s.onStrong)),
              const SizedBox(height: 2),
              Text(
                  [
                    if (count != null) l.concExams(count),
                    if (next != null) l.concNextDate(WinFormat.date(next)),
                  ].join(' · '),
                  style: WinType.labelM(s.onMuted)),
            ]),
          ),
          if (statusText.isNotEmpty) ...[const SizedBox(width: 8), WinBadge(statusText, color: statusColor)],
          const SizedBox(width: 4),
          Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onMuted),
        ]),
      ),
    );
  }
}

/// Page d'un concours : calendrier et informations officielles, épreuves
/// publiées par matière et par année, conseils, conditions, filières,
/// coefficients, programme et questions fréquentes.
class ConcoursDetailScreen extends StatefulWidget {
  final ConcoursSchool school;
  const ConcoursDetailScreen({super.key, required this.school});

  /// Ouverture d'une épreuve ; remplaçable dans les tests.
  static Future<void> Function(BuildContext context, int subjectId) openSubject = (context, id) async {
    final subject = await SubjectService.instance.getById(id);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentDetailScreen(content: subject.toContent())));
  };

  @override
  State<ConcoursDetailScreen> createState() => _ConcoursDetailScreenState();
}

class _ConcoursDetailScreenState extends State<ConcoursDetailScreen> {
  final _svc = ConcoursService.instance;
  ConcoursEvent? _event;
  ConcoursStats? _stats;
  bool _loaded = false;
  bool _statsError = false;
  String? _category;
  int? _year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _statsError = false);
    final event = _svc.event(widget.school.slug);
    ConcoursStats? stats;
    var statsError = false;
    try {
      stats = await _svc.stats(widget.school.slug);
    } catch (_) {
      statsError = true;
    }
    final e = await event;
    if (!mounted) return;
    setState(() {
      _event = e;
      _stats = stats ?? _stats;
      _statsError = statsError && _stats == null;
      _loaded = true;
    });
  }

  Future<void> _open(ConcoursExam x) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = context.l10n.commonLoadError;
    try {
      await ConcoursDetailScreen.openSubject(context, x.subjectId);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _row(WinScheme s, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: s.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: WinType.bodyM(s.onMuted))),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: WinType.labelM(s.onStrong))),
        ]),
      );

  Widget _section(WinScheme s, String title, Widget child) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          child,
        ]),
      );

  Widget _calendar(WinScheme s, AppLocalizations l, ConcoursEvent e) {
    final (statusText, statusColor) = _status(l, e.registrationStatus);
    String? d(DateTime? x) => x == null ? null : WinFormat.date(x);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(l.concCalendar(e.year), style: WinType.titleS(s.onStrong))),
          if (statusText.isNotEmpty) WinBadge(statusText, color: statusColor),
        ]),
        const SizedBox(height: 12),
        if (e.registrationStart != null || e.registrationEnd != null)
          _row(s, PhosphorIconsRegular.pencilSimpleLine, l.concRegistration,
              [d(e.registrationStart), d(e.registrationEnd)].whereType<String>().join(' → ')),
        if (e.examDate != null) _row(s, PhosphorIconsRegular.exam, l.concExamDate, d(e.examDate)!),
        if (e.resultsDate != null) _row(s, PhosphorIconsRegular.megaphone, l.concResults, d(e.resultsDate)!),
        if (e.location != null) _row(s, PhosphorIconsRegular.mapPin, l.concLocation, e.location!),
        if (e.feeXaf != null) _row(s, PhosphorIconsRegular.money, l.concFee, WinFormat.xaf(e.feeXaf!)),
        if (e.officialUrl != null) ...[
          const SizedBox(height: 4),
          WinButton(l.concOfficialSite,
              block: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.arrowSquareOut,
              onTap: () => ExternalLinks.open(e.officialUrl!)),
        ],
        if (e.sourceCheckedAt != null) ...[
          const SizedBox(height: 8),
          Text(l.concChecked(WinFormat.date(e.sourceCheckedAt!)), style: WinType.labelS(s.onMuted)),
        ],
      ]),
    );
  }

  Widget _exams(WinScheme s, AppLocalizations l, ConcoursStats st) {
    final shown = st.exams
        .where((x) => _category == null || x.category == _category)
        .where((x) => _year == null || x.year == _year)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.concStats(st.total, st.withCorrection, st.free), style: WinType.bodyS(s.onMuted)),
      if (st.categories.length > 1) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            WinChip(l.concAllSubjects, active: _category == null, onTap: () => setState(() => _category = null)),
            for (final c in st.categories) ...[
              const SizedBox(width: 8),
              WinChip('${c.$1} (${c.$2})', active: _category == c.$1, onTap: () => setState(() => _category = c.$1)),
            ],
          ]),
        ),
      ],
      if (st.years.length > 1) ...[
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            WinChip(l.concAllYears, active: _year == null, onTap: () => setState(() => _year = null)),
            for (final y in st.years) ...[
              const SizedBox(width: 8),
              WinChip('$y', active: _year == y, onTap: () => setState(() => _year = y)),
            ],
          ]),
        ),
      ],
      const SizedBox(height: 8),
      if (shown.isEmpty)
        Text(l.concNoExam, style: WinType.bodyM(s.onMuted))
      else
        for (final x in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WinCard(
              onTap: () => _open(x),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(x.title, style: WinType.titleS(s.onStrong)),
                    Text(
                        [
                          if (x.category.isNotEmpty) x.category,
                          if (x.year > 0) '${x.year}',
                          if (x.hasCorrection) l.concWithCorrection,
                        ].join(' · '),
                        style: WinType.labelM(s.onMuted)),
                  ]),
                ),
                const SizedBox(width: 8),
                WinBadge(x.isFree ? l.concFree : WinFormat.xaf(x.price), color: x.isFree ? BadgeColor.success : BadgeColor.neutral),
              ]),
            ),
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final lang = L10n.locale.languageCode;
    final e = _event;
    final st = _stats;
    Widget body;
    if (!_loaded) {
      body = const WinLoading();
    } else {
      final tips = e?.tips(lang) ?? const [];
      final faq = e?.faq(lang) ?? const [];
      final texts = <(String, String?)>[
        (l.concConditions, e?.field('admissionConditions', lang)),
        (l.concTracks, e?.field('tracks', lang)),
        (l.concCoefficients, e?.field('coefficients', lang)),
        (l.concProgramme, e?.field('programme', lang)),
      ].where((t) => t.$2 != null).toList();
      final notes = e?.field('notes', lang);
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          if (e != null) _calendar(s, l, e) else Text(l.concNoCalendar, style: WinType.bodyM(s.onMuted)),
          if (notes != null) ...[const SizedBox(height: 10), Text(notes, style: WinType.bodyM(s.onMuted))],
          _section(
              s,
              l.concExamsTitle,
              _statsError
                  ? WinErrorState(message: l.commonLoadError, onRetry: _load)
                  : st == null || st.total == 0
                      ? Text(l.concNoExam, style: WinType.bodyM(s.onMuted))
                      : _exams(s, l, st)),
          if (tips.isNotEmpty)
            _section(
                s,
                l.concTips,
                WinCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final t in tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(PhosphorIconsRegular.lightbulb, size: 16, color: s.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: WinType.bodyM(s.onStrong))),
                        ]),
                      ),
                  ]),
                )),
          for (final t in texts)
            _section(s, t.$1, WinCard(child: Text(t.$2!.replaceAll(RegExp(r'[*#_`]'), ''), style: WinType.bodyM(s.onStrong)))),
          if (faq.isNotEmpty)
            _section(
                s,
                l.concFaq,
                WinCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final f in faq)
                      ExpansionTile(
                        title: Text(f.question, style: WinType.titleS(s.onStrong)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(f.answer, style: WinType.bodyM(s.onMuted))],
                      ),
                  ]),
                )),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(e?.name(lang) ?? widget.school.name)),
      body: SafeArea(child: body),
    );
  }
}
