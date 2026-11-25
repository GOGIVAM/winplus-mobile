import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/quiz_service.dart';
import '../../services/winai_studio_service.dart';
import '../../shell/more_screen.dart';
import '../../student/quiz_screen.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/winai_markdown.dart';

/// Lecture d'une fiche de révision générée par WinAI (texte mis en forme).
class WinAISheetScreen extends StatelessWidget {
  final StudioSheet sheet;
  const WinAISheetScreen({super.key, required this.sheet});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = (sheet.content ?? '').trim();
    final meta = [sheet.subject, sheet.topic]
        .where((x) => x.trim().isNotEmpty)
        .join(' · ');
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(context.l10n.winaiToolSheet)),
      body: content.isEmpty
          ? WinEmptyState(
              title: context.l10n.winaiSheetEmpty,
              icon: PhosphorIconsRegular.fileText)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text(sheet.title, style: WinType.displayS(s.onStrong)),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: WinType.bodyS(s.onMuted)),
                ],
                const SizedBox(height: 16),
                WinAIMarkdown(content, color: s.onSurface),
              ],
            ),
    );
  }
}

/// « Mes créations » : les quiz et les fiches que WinAI a générés pour
/// l'élève, à rejouer ou à relire.
class WinAICreationsScreen extends StatefulWidget {
  const WinAICreationsScreen({super.key});
  @override
  State<WinAICreationsScreen> createState() => _WinAICreationsScreenState();
}

class _WinAICreationsScreenState extends State<WinAICreationsScreen> {
  List<StudioQuiz>? _quizzes;
  List<StudioSheet>? _sheets;
  String? _error;
  int? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _quizzes = null;
      _sheets = null;
      _error = null;
    });
    try {
      final svc = WinAiStudioService.instance;
      final q = await svc.generatedQuizzes();
      final f = await svc.generatedSheets();
      if (mounted) {
        setState(() {
          _quizzes = q;
          _sheets = f;
        });
      }
    } on WinAiStudioException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openQuiz(StudioQuiz q) async {
    if (_opening != null) return;
    setState(() => _opening = q.id);
    try {
      final api = await QuizService.instance.getById(q.id);
      if (!mounted) return;
      await Navigator.push(
          context,
          WinPageRoute(
              builder: (_) => QuizActiveScreen(quiz: api.toQuiz())));
    } catch (_) {
      if (mounted) _toast(context.l10n.commonLoadError);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  Future<void> _openSheet(StudioSheet f) async {
    if (_opening != null) return;
    setState(() => _opening = -f.id);
    try {
      // La liste ne porte pas toujours le texte : on relit la fiche complète.
      final full = (f.content ?? '').trim().isNotEmpty
          ? f
          : await WinAiStudioService.instance.sheet(f.id);
      if (!mounted) return;
      await Navigator.push(context,
          WinPageRoute(builder: (_) => WinAISheetScreen(sheet: full)));
    } on WinAiStudioException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget body;
    final quizzes = _quizzes, sheets = _sheets;
    if (_error != null) {
      body = WinErrorState(message: _error!, onRetry: _load);
    } else if (quizzes == null || sheets == null) {
      body = const WinLoading();
    } else if (quizzes.isEmpty && sheets.isEmpty) {
      body = WinEmptyState(
          title: l.winaiCreationsEmpty,
          message: l.winaiCreationsEmptyHint,
          icon: PhosphorIconsRegular.sparkle);
    } else {
      Widget title(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(t, style: WinType.titleL(s.onStrong)));
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (quizzes.isNotEmpty) ...[
              title(l.winaiCreationsQuizzes),
              MoreGroup(children: [
                for (final q in quizzes)
                  MoreLine(
                      icon: PhosphorIconsRegular.exam,
                      label: q.title,
                      onTap: () => _openQuiz(q)),
              ]),
              const SizedBox(height: 18),
            ],
            if (sheets.isNotEmpty) ...[
              title(l.winaiCreationsSheets),
              MoreGroup(children: [
                for (final f in sheets)
                  MoreLine(
                      icon: PhosphorIconsRegular.fileText,
                      label: f.title,
                      onTap: () => _openSheet(f)),
              ]),
            ],
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(l.winaiCreationsTitle),
        bottom: _opening == null
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3)),
      ),
      body: body,
    );
  }
}
