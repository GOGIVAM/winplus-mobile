import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/institution_exams_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Pourcentage (0 à 100) vers une note sur 20.
String bulletinOn20(double? v) => WinFormat.grade20(v);

/// Contenu d'un bulletin (aperçu de l'établissement ou bulletin reçu) :
/// moyenne et rang, moyennes par matière face à la classe, devoirs,
/// régularité, temps d'étude, appréciation.
class BulletinView extends StatelessWidget {
  final BulletinData data;
  final String? periodLabel;
  final String? appreciation;
  const BulletinView({super.key, required this.data, this.periodLabel, this.appreciation});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final d = data;
    // Lot 1 : durée au format commun ; « – » sans temps d'étude.
    final studyTime = WinFormat.duration(d.studyMinutes);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.studentName, style: WinType.titleM(s.onStrong)),
          Text(
              [
                if (d.institutionName.isNotEmpty) d.institutionName,
                if (d.classes.isNotEmpty) d.classes.join(', '),
              ].join(' · '),
              style: WinType.labelM(s.onMuted)),
          if (periodLabel != null || (d.from != null && d.to != null))
            Text(
                [
                  if ((periodLabel ?? '').isNotEmpty) periodLabel!,
                  if (d.from != null && d.to != null) l.bullPeriod(WinFormat.dateShort(d.from!), WinFormat.dateShort(d.to!)),
                ].join(' · '),
                style: WinType.labelM(s.onMuted)),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: WinStatCard(bulletinOn20(d.average), l.bullAverage, icon: PhosphorIconsRegular.chartBar)),
        const SizedBox(width: 10),
        Expanded(
          child: WinStatCard(d.rank != null && d.classSize != null ? '${d.rank} / ${d.classSize}' : '–', l.bullRank,
              icon: PhosphorIconsRegular.ranking),
        ),
      ]),
      if (d.classAverage != null) ...[
        const SizedBox(height: 6),
        Text(l.bullClassAverage(bulletinOn20(d.classAverage)), style: WinType.labelM(s.onMuted)),
      ],
      const SizedBox(height: 16),
      Text(l.bullSubjects, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 8),
      if (d.subjects.isEmpty)
        Text(l.bullNoQuiz, style: WinType.bodyM(s.onMuted))
      else
        WinCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final x in d.subjects)
              ListTile(
                dense: true,
                title: Text(x.subject),
                subtitle: Text([
                  l.bullQuizzes(x.quizzes),
                  if (x.classAverage != null) l.bullClass(bulletinOn20(x.classAverage)),
                ].join(' · ')),
                trailing: Text(bulletinOn20(x.average), style: WinType.titleS(s.onStrong)),
              ),
          ]),
        ),
      const SizedBox(height: 16),
      WinCard(
        child: Column(children: [
          _line(s, PhosphorIconsRegular.notebook, l.bullHomework,
              d.homeworkGiven == 0 ? '–' : '${d.homeworkDone} / ${d.homeworkGiven}'),
          if (d.homeworkAverage != null) _line(s, PhosphorIconsRegular.checkCircle, l.bullHomeworkAverage, bulletinOn20(d.homeworkAverage)),
          _line(s, PhosphorIconsRegular.calendarCheck, l.bullActiveDays, '${d.activeDays}'),
          _line(s, PhosphorIconsRegular.clock, l.bullStudyTime, studyTime.isEmpty ? WinFormat.none : studyTime),
          _line(s, PhosphorIconsRegular.exam, l.bullQuizCount, '${d.quizCount}'),
        ]),
      ),
      if ((appreciation ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(l.bullAppreciation, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 8),
        WinCard(child: Text(appreciation!.trim(), style: WinType.bodyM(s.onStrong))),
      ],
    ]);
  }

  Widget _line(WinScheme s, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: s.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: WinType.bodyM(s.onMuted))),
          Text(value, style: WinType.labelM(s.onStrong)),
        ]),
      );
}

/// Un bulletin partagé, ouvert depuis une liste.
class BulletinScreen extends StatefulWidget {
  final int id;
  final String title;
  const BulletinScreen({super.key, required this.id, required this.title});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  SharedBulletin? _b;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final b = await InstitutionExamsService.instance.bulletin(widget.id);
      if (mounted) setState(() => _b = b);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final b = _b;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: _error
            ? WinErrorState(message: l.commonLoadError, onRetry: _load)
            : b == null
                ? const WinLoading()
                : b.data == null
                    ? WinEmptyState(title: l.bullUnreadable)
                    : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                        BulletinView(data: b.data!, periodLabel: b.periodLabel, appreciation: b.appreciation),
                      ]),
      ),
    );
  }
}

/// « Mes bulletins » : bulletins partagés par l'établissement (élève, ou
/// parent pour ses enfants).
class MyBulletinsScreen extends StatefulWidget {
  const MyBulletinsScreen({super.key});

  @override
  State<MyBulletinsScreen> createState() => _MyBulletinsScreenState();
}

class _MyBulletinsScreenState extends State<MyBulletinsScreen> {
  List<BulletinSummary>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final items = await InstitutionExamsService.instance.myBulletins();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const WinLoading();
    } else if (items.isEmpty) {
      body = WinEmptyState(icon: PhosphorIconsRegular.scroll, title: l.bullMineEmptyTitle, message: l.bullMineEmptyText);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          for (final b in items) bulletinTile(context, b, showStudent: true),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.bullMineTitle)),
      body: SafeArea(child: body),
    );
  }
}

/// Ligne d'un bulletin partagé (liste de l'élève, du parent ou de l'établissement).
Widget bulletinTile(BuildContext context, BulletinSummary b,
    {bool showStudent = false, VoidCallback? onDelete}) {
  final s = WinTheme.of(context);
  final l = context.l10n;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: WinCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BulletinScreen(id: b.id, title: [if (showStudent && b.studentName != null) b.studentName!, b.periodLabel].join(' · ')))),
      child: Row(children: [
        Icon(PhosphorIconsRegular.scroll, color: s.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.periodLabel, style: WinType.titleS(s.onStrong)),
            Text(
                [
                  if (showStudent && (b.studentName ?? '').isNotEmpty) b.studentName!,
                  if ((b.institutionName ?? '').isNotEmpty) b.institutionName!,
                  if (b.sharedAt != null) l.bullSharedOn(WinFormat.dateShort(b.sharedAt!)),
                ].join(' · '),
                style: WinType.labelM(s.onMuted)),
          ]),
        ),
        if (onDelete != null)
          IconButton(tooltip: l.bullDelete, onPressed: onDelete, icon: const Icon(PhosphorIconsRegular.trash))
        else
          Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onMuted),
      ]),
    ),
  );
}
