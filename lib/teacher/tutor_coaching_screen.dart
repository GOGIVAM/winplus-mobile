import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/messaging_service.dart';
import '../services/tutor_insights_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import '../services/content_refusal.dart';

/// « Coaching WinAI » du répétiteur (lot 7), comme TutorCoachingPanel du
/// site : rapport mensuel (points forts, matières en progrès, stagnations,
/// recommandations) et, plus bas, la fiche de révision WinAI de chaque élève
/// suivi en cours particuliers.
class TutorCoachingScreen extends StatefulWidget {
  const TutorCoachingScreen({super.key});

  @override
  State<TutorCoachingScreen> createState() => _TutorCoachingScreenState();
}

class _TutorCoachingScreenState extends State<TutorCoachingScreen> {
  final _svc = TutorInsightsService.instance;
  CoachingReport? _report;
  List<TutoredStudent> _students = const [];
  bool _loaded = false;
  bool _error = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final report = await _svc.latestReport();
      final students = await _svc.students();
      if (!mounted) return;
      setState(() {
        _report = report;
        _students = students;
        _loaded = true;
      });
    } catch (_) {
      if (mounted && !_loaded) setState(() => _error = true);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final r = await _svc.generateReport();
      if (!mounted) return;
      setState(() => _report = r);
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.coachGenerated)));
    } on TutorInsightsException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _block(WinScheme s, String title, IconData icon, Color color, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(title, style: WinType.titleS(s.onStrong)),
        ]),
        const SizedBox(height: 6),
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•  ', style: WinType.bodyM(color)),
              Expanded(child: Text(it, style: WinType.bodyM(s.onStrong))),
            ]),
          ),
      ]),
    );
  }

  Widget _reportCard(WinScheme s, AppLocalizations l) {
    final r = _report;
    if (r == null || r.isEmpty) {
      return WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.coachEmptyTitle, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 4),
          Text(l.coachEmptyText, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          WinButton(l.coachGenerateNow,
              block: true, icon: PhosphorIconsRegular.sparkle, loading: _generating, onTap: _generating ? null : _generate),
        ]),
      );
    }
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.monthLabel.isEmpty ? l.coachTitle : r.monthLabel, style: WinType.titleM(s.onStrong)),
        if (r.generatedAt != null)
          Text(l.coachGeneratedOn(WinFormat.dateShort(r.generatedAt!)), style: WinType.labelM(s.onMuted)),
        if (r.text.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(r.text.trim(), style: WinType.bodyM(s.onStrong)),
        ],
        _block(s, l.coachStrengths, PhosphorIconsRegular.thumbsUp, WinColors.success, r.strengths),
        _block(s, l.coachImproving, PhosphorIconsRegular.trendUp, WinColors.teal600, r.improving),
        _block(s, l.coachStagnation, PhosphorIconsRegular.warning, WinColors.warn, r.stagnation),
        _block(s, l.coachRecommendations, PhosphorIconsRegular.lightbulb, s.primary, r.recommendations),
        const SizedBox(height: 14),
        WinButton(l.coachRegenerate,
            block: true,
            variant: WinButtonVariant.outline,
            loading: _generating,
            onTap: _generating ? null : _generate),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (!_loaded) {
      body = const WinLoading();
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Text(l.coachIntro, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          _reportCard(s, l),
          const SizedBox(height: 20),
          Text(l.coachSheetsTitle, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 2),
          Text(l.coachSheetsIntro, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 8),
          if (_students.isEmpty)
            Text(l.coachNoStudents, style: WinType.bodyM(s.onMuted))
          else
            for (final st in _students)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WinCard(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => TutorStudentSheetScreen(student: st))),
                  child: Row(children: [
                    Icon(PhosphorIconsRegular.student, color: s.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(st.name, style: WinType.titleS(s.onStrong)),
                        Text(
                            [
                              l.coachSessions(st.sessions),
                              if ((st.lastSubject ?? '').isNotEmpty) st.lastSubject!,
                            ].join(' · '),
                            style: WinType.labelM(s.onMuted)),
                      ]),
                    ),
                    Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onMuted),
                  ]),
                ),
              ),
        ]),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.coachTitle)),
      body: SafeArea(child: body),
    );
  }
}

/// Fiche de révision WinAI d'un élève : générer, modifier, enregistrer,
/// envoyer dans la messagerie, copier.
class TutorStudentSheetScreen extends StatefulWidget {
  final TutoredStudent student;
  const TutorStudentSheetScreen({super.key, required this.student});

  @override
  State<TutorStudentSheetScreen> createState() => _TutorStudentSheetScreenState();
}

class _TutorStudentSheetScreenState extends State<TutorStudentSheetScreen> {
  final _svc = TutorInsightsService.instance;
  final _text = TextEditingController();
  bool _loading = true;
  bool _error = false;
  bool _generating = false;
  bool _saving = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final saved = await _svc.savedSheet(widget.student.userId);
      if (!mounted) return;
      if (saved != null) _text.text = saved;
      setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _toast(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      final t = await _svc.generateSheet(widget.student.userId);
      if (mounted && t.trim().isNotEmpty) _text.text = t.trim();
    } on TutorInsightsException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() => _saving = true);
    try {
      await _svc.saveSheet(widget.student.userId, _text.text.trim(), subject: widget.student.lastSubject);
      if (mounted) _toast(l.coachSheetSaved);
    } on TutorInsightsException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _send() async {
    final l = context.l10n;
    setState(() => _sending = true);
    int? id;
    String? refusal;
    try {
      id = await MessagingService.instance
          .startConversation(widget.student.userId, firstMessage: '${l.coachSheetMessage}\n\n${_text.text.trim()}');
    } on ContentRefused catch (r) {
      // Filtre des messageries : message du serveur, le texte reste.
      refusal = r.message;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    _toast(refusal ?? (id != null ? l.coachSheetSent(widget.student.name) : l.coachSheetSendError));
  }

  Future<void> _copy() async {
    final l = context.l10n;
    await Clipboard.setData(ClipboardData(text: _text.text.trim()));
    if (mounted) _toast(l.coachSheetCopied);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final hasText = _text.text.trim().isNotEmpty;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (_loading) {
      body = const WinLoading();
    } else {
      body = ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        Text(l.coachSheetIntro, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 12),
        if (!hasText)
          WinButton(l.coachSheetGenerate,
              block: true, icon: PhosphorIconsRegular.sparkle, loading: _generating, onTap: _generating ? null : _generate)
        else ...[
          TextField(controller: _text, minLines: 8, maxLines: 20, keyboardType: TextInputType.multiline),
          const SizedBox(height: 12),
          WinButton(l.coachSheetSave, block: true, loading: _saving, onTap: _saving ? null : _save),
          const SizedBox(height: 8),
          WinButton(l.coachSheetSend,
              block: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.paperPlaneTilt,
              loading: _sending,
              onTap: _sending ? null : _send),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: WinButton(l.coachSheetCopy,
                  block: true, variant: WinButtonVariant.ghost, icon: PhosphorIconsRegular.copy, onTap: _copy),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: WinButton(l.coachRegenerate,
                  block: true,
                  variant: WinButtonVariant.ghost,
                  icon: PhosphorIconsRegular.sparkle,
                  loading: _generating,
                  onTap: _generating ? null : _generate),
            ),
          ]),
        ],
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(widget.student.name)),
      body: SafeArea(child: body),
    );
  }
}
