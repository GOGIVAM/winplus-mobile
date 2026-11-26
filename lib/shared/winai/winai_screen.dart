import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/models.dart';
import '../../data/reference_data.dart';
import '../../institution/action_plan_screen.dart';
import '../../institution/at_risk_screen.dart';
import '../../l10n/l10n.dart';
import '../../parent/winai_alerts_screen.dart';
import '../../services/chatbot_service.dart';
import '../../shell/more_screen.dart';
import '../../student/exam_coach_screen.dart';
import '../../student/quiz_revision_screen.dart';
import '../../student/study_session_screen.dart';
import '../../teacher/correction_queue_screen.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/knowledge_base_toggle.dart';
import '../../widgets/voice_dictation_sheet.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';
import '../../widgets/winai_floating_widget.dart';
import '../../widgets/winai_markdown.dart';
import '../../widgets/winai_memories_sheet.dart';
import '../../services/winai_sources_service.dart';
import 'winai_sources_tab.dart';
import '../subscription/pricing_screen.dart';
import '../../services/quiz_service.dart';
import '../../services/winai_studio_service.dart';
import '../../student/quiz_screen.dart';
import 'winai_creations.dart';
import 'winai_tools.dart';
import 'winai_exam.dart';
import '../../services/institution_service.dart';
import '../../services/parent_service.dart';
import '../../services/winai_productions_service.dart';

/// WinAI, un seul écran pour les quatre espaces (il était recopié quatre
/// fois). Deux onglets :
///  - « Discussion » : la conversation, ses suggestions de départ, la dictée
///    et l'historique des conversations ;
///  - « Atelier » : les outils de WinAI pour ce type de compte. Un outil
///    ouvre soit son écran, soit une feuille de réglages (matière, chapitre,
///    niveau) puis lance la génération dans la discussion.
/// Rien n'est demandé au serveur à l'ouverture : l'historique n'est lu que
/// lorsqu'on l'ouvre.
class WinAIScreen extends StatefulWidget {
  final WinRole role;
  final String? initialMessage;
  const WinAIScreen({super.key, required this.role, this.initialMessage});

  @override
  State<WinAIScreen> createState() => _WinAIScreenState();
}

typedef _Msg = ({bool me, String text, List<WinAICitation> cites});

class _WinAIScreenState extends State<WinAIScreen>
    with SingleTickerProviderStateMixin {
  // Sources, Discussion, Atelier : on ouvre sur la discussion.
  late final TabController _tabs =
      TabController(length: 3, vsync: this, initialIndex: 1);

  /// Sources cochées (clé « type:id ») : la discussion et l'atelier s'y
  /// limitent. Vide : WinAI répond comme d'habitude.
  Map<String, WinAISourceRef> _sources = const {};
  final _ctrl = TextEditingController();
  final List<_Msg> _msgs = [];
  bool _thinking = false;

  /// Conversation en cours (créée par le serveur au premier message).
  int? _conversationId;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _send(widget.initialMessage));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Textes propres à chaque espace ──────────────────────────────────

  String get _tagline {
    final l = context.l10n;
    return switch (widget.role) {
      WinRole.student => l.studentTabsAiTagline,
      WinRole.parent => l.parentAiTagline,
      WinRole.teacher => l.teacherAiTagline,
      WinRole.institution => l.instAiTagline,
    };
  }

  String get _hint {
    final l = context.l10n;
    return switch (widget.role) {
      WinRole.student => l.studentTabsAiHint,
      WinRole.parent => l.parentAiHint,
      WinRole.teacher => l.teacherAiInputHint,
      WinRole.institution => l.instAiHint,
    };
  }

  List<String> get _suggestions {
    final l = context.l10n;
    return switch (widget.role) {
      WinRole.student => [
          l.studentTabsAiSuggest1,
          l.studentTabsAiSuggest2,
          l.studentTabsAiSuggest3,
          l.studentTabsAiSuggest4
        ],
      WinRole.parent => [
          l.parentAiSuggestion1,
          l.parentAiSuggestion2,
          l.parentAiSuggestion3,
          l.parentAiSuggestion4
        ],
      WinRole.teacher => [
          l.teacherAiSuggestQuiz,
          l.teacherAiSuggestSheet,
          l.teacherAiSuggestCorrection,
          l.teacherAiSuggestTitle
        ],
      WinRole.institution => [
          l.instAiSuggestion1,
          l.instRiskTitle,
          l.instAiSuggestion3,
          l.instAiSuggestion4
        ],
    };
  }

  // ── Discussion ──────────────────────────────────────────────────────

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _ctrl.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add((me: true, text: t, cites: const []));
      _ctrl.clear();
      _thinking = true;
    });
    // Réponse écrite en direct, dans la même conversation que les messages
    // précédents : WinAI garde le contexte.
    var started = false;
    var cites = const <WinAICitation>[];
    void show(String text) {
      if (!started) {
        started = true;
        _thinking = false;
        _msgs.add((me: false, text: text, cites: cites));
      } else {
        _msgs[_msgs.length - 1] = (me: false, text: text, cites: cites);
      }
    }

    final reply = await ChatbotService.instance.streamMessage(
      message: t,
      conversationId: _conversationId,
      onConversation: (id) => _conversationId = id,
      sources: _sources.values.toList(),
      onCitations: (c) => cites = c,
      onText: (text) {
        if (mounted) setState(() => show(text));
      },
    );
    if (!mounted) return;
    setState(() {
      _thinking = false;
      show(reply ?? L10n.current.studentTabsAiNoReply);
    });
  }

  /// Dictée vocale : le texte reconnu remplit le champ, à relire avant envoi.
  Future<void> _dictate() async {
    final text = await showVoiceDictation(context);
    if (!mounted || text == null || text.trim().isEmpty) return;
    final before = _ctrl.text.trim();
    _ctrl.text = before.isEmpty ? text.trim() : '$before ${text.trim()}';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  void _newChat() => setState(() {
        _msgs.clear();
        _conversationId = null;
        _thinking = false;
      });

  /// Historique : la liste n'est demandée au serveur qu'ici.
  Future<void> _openHistory() async {
    final picked = await showWinBottomSheet<ApiChatSession>(
      context: context,
      title: context.l10n.winaiHistoryTitle,
      child: const _HistoryList(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _msgs.clear();
      _conversationId = picked.id;
      _thinking = true;
    });
    _tabs.animateTo(1);
    try {
      final history = await ChatbotService.instance.getHistory(picked.id);
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _msgs.addAll(history
            .where((m) => m.content.trim().isNotEmpty)
            .map((m) =>
                (me: m.role == 'user', text: m.content, cites: const <WinAICitation>[])));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _thinking = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonLoadError)));
    }
  }

  /// Lance une génération depuis l'atelier : la demande part dans la
  /// discussion, où la réponse s'écrit en direct.
  void _generate(String prompt) {
    _tabs.animateTo(1);
    _send(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return WinAIFabHidden(child: Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: const Text('WinAI'),
        actions: [
          IconButton(
              tooltip: l.winaiNewChat,
              icon: const Icon(PhosphorIconsRegular.notePencil),
              onPressed: _newChat),
          IconButton(
              tooltip: l.winaiHistoryTitle,
              icon: const Icon(PhosphorIconsRegular.clockCounterClockwise),
              onPressed: _openHistory),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: l.winaiTabSources),
            Tab(text: l.winaiTabChat),
            Tab(text: l.winaiTabStudio)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WinAISourcesTab(
              selected: _sources,
              onChanged: (next) => setState(() => _sources = next)),
          _chat(s),
          _Studio(
              role: widget.role,
              sources: _sources.values.toList(),
              onGenerate: _generate),
        ],
      ),
    ));
  }

  Widget _chat(WinScheme s) {
    return Column(children: [
      Expanded(child: _msgs.isEmpty && !_thinking ? _welcome(s) : _thread(s)),
      // Rappel des sources cochées, avec un accès direct à leur onglet.
      if (_sources.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: WinChip(context.l10n.winaiSourcesSelected(_sources.length),
                active: true,
                icon: PhosphorIconsRegular.files,
                onTap: () => _tabs.animateTo(0)),
          ),
        ),
      const KnowledgeBaseToggle(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(children: [
          _SquareButton(
              icon: PhosphorIconsRegular.microphone,
              label: context.l10n.studentTabsAttachVoice,
              onTap: _dictate),
          const SizedBox(width: 8),
          Expanded(child: WinTextField(hint: _hint, controller: _ctrl)),
          const SizedBox(width: 8),
          _SquareButton(
              icon: PhosphorIconsFill.paperPlaneRight,
              label: context.l10n.commonSend,
              filled: true,
              onTap: _send),
        ]),
      ),
    ]);
  }

  Widget _welcome(WinScheme s) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 48),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WinAIOrb(size: 72),
                const SizedBox(height: 16),
                Text('WinAI',
                    style: WinType.archivo(size: 26, color: s.onStrong)),
                const SizedBox(height: 6),
                Text(_tagline,
                    textAlign: TextAlign.center,
                    style: WinType.bodyM(s.onMuted)),
                const SizedBox(height: 22),
                for (final q in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _Suggestion(q, onTap: () => _send(q)),
                  ),
                const SizedBox(height: 8),
                TextButton.icon(
                    onPressed: () => showWinAIMemoriesSheet(context),
                    icon: const WinAIIcon(size: 18),
                    label: Text(context.l10n.commonWinaiMemory)),
              ]),
        ),
      ),
    );
  }

  Widget _thread(WinScheme s) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _msgs.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (_thinking && i == _msgs.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: s.cardBg,
                  border: Border.all(color: s.cardBorder),
                  borderRadius: BorderRadius.circular(WinRadii.lg)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(context.l10n.commonWinaiThinking,
                    style: WinType.bodyS(s.onMuted)),
              ]),
            ),
          );
        }
        final m = _msgs[i];
        return Align(
          alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * (m.me ? .78 : .88)),
            decoration: BoxDecoration(
              // Bulle de l'utilisateur : teinte de marque du thème (suit le
              // mode sombre) ; réponse de WinAI : carte.
              color: m.me ? s.primaryContainer : s.cardBg,
              border: m.me ? null : Border.all(color: s.cardBorder),
              borderRadius: BorderRadius.circular(WinRadii.lg),
            ),
            child: m.me
                ? Text(m.text, style: WinType.bodyM(s.onStrong))
                // Réponse de WinAI : Markdown et formules compilées, puis
                // les sources sur lesquelles elle s'appuie.
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        WinAIMarkdown(m.text, color: s.onSurface),
                        if (m.cites.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          for (final c in m.cites)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(PhosphorIconsRegular.fileText,
                                        size: 14, color: s.onMuted),
                                    const SizedBox(width: 6),
                                    Expanded(
                                        child: Text(
                                            c.page == null
                                                ? c.title
                                                : context.l10n.winaiCitationPage(
                                                    c.title, c.page!),
                                            style: WinType.labelM(s.onMuted))),
                                  ]),
                            ),
                        ],
                      ]),
          ),
        );
      },
    );
  }
}

/// Suggestion de départ : une ligne pleine largeur, lisible sur téléphone.
class _Suggestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Suggestion(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Material(
      color: s.primaryContainer,
      borderRadius: BorderRadius.circular(WinRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(WinRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Expanded(
                child: Text(text,
                    style: WinType.titleM(s.dark ? s.onStrong : WinColors.teal800))),
            const SizedBox(width: 8),
            Icon(PhosphorIconsRegular.arrowRight,
                size: 16, color: s.dark ? s.onStrong : WinColors.teal800),
          ]),
        ),
      ),
    );
  }
}

/// Bouton carré de la barre de saisie (dictée, envoi), zone tactile de 48.
class _SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _SquareButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.filled = false});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: filled ? s.primary : s.surface2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WinRadii.sm),
            side: filled ? BorderSide.none : BorderSide(color: s.outline)),
        child: InkWell(
          borderRadius: BorderRadius.circular(WinRadii.sm),
          onTap: onTap,
          child: SizedBox(
              width: 48,
              height: 50,
              child: Icon(icon,
                  size: 20, color: filled ? s.onPrimary : s.onMuted)),
        ),
      ),
    );
  }
}

/// Liste des conversations passées, dans la feuille du bas.
class _HistoryList extends StatefulWidget {
  const _HistoryList();
  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  List<ApiChatSession>? _sessions;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _sessions = null;
      _failed = false;
    });
    try {
      final list = await ChatbotService.instance.getSessions();
      if (mounted) setState(() => _sessions = list);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_failed) {
      return WinErrorState(message: l.commonLoadError, onRetry: _load);
    }
    final sessions = _sessions;
    if (sessions == null) return const WinLoading(rows: 3);
    if (sessions.isEmpty) {
      return WinEmptyState(
          title: l.winaiHistoryEmpty,
          icon: PhosphorIconsRegular.chatCircle);
    }
    return MoreGroup(children: [
      for (final c in sessions)
        MoreLine(
            icon: PhosphorIconsRegular.chatCircle,
            label: c.title,
            onTap: () => Navigator.pop(context, c)),
    ]);
  }
}

// ── Atelier ─────────────────────────────────────────────────────────────

/// Réglages choisis dans la feuille d'un outil de génération.
typedef _Settings = ({String subject, String topic, int level, bool long});

/// Forme du résultat d'un outil : un texte à lire (et à écouter), ou des
/// fiches recto verso.
enum _ToolKind { text, cards }

/// Un outil de génération de l'atelier.
class _Tool {
  final IconData icon;
  final String label;
  final _ToolKind kind;

  /// L'outil propose de choisir la durée (résumé à écouter).
  final bool withLength;
  final String Function(String subject, String topic, String level, bool long)
      prompt;
  const _Tool(this.icon, this.label, this.prompt,
      {this.kind = _ToolKind.text, this.withLength = false});
}

const _difficulties = ['easy', 'medium', 'hard'];

/// Les outils de WinAI pour un type de compte, rangés par usage.
class _Studio extends StatefulWidget {
  final WinRole role;

  /// Sources cochées dans l'onglet « Sources ».
  final List<WinAISourceRef> sources;

  /// Envoie une demande dans la discussion (outils sans générateur dédié).
  final ValueChanged<String> onGenerate;
  const _Studio(
      {required this.role, required this.sources, required this.onGenerate});

  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  bool _busy = false;

  /// Génération longue en cours (épreuve complète) : message d'attente
  /// explicite au lieu du bandeau habituel.
  bool _slow = false;

  void _open(Widget page) =>
      Navigator.push(context, WinPageRoute(builder: (_) => page));

  Future<_Settings?> _settings(String title, {bool withLength = false}) =>
      showWinBottomSheet<_Settings>(
          context: context,
          title: title,
          child: _GenerateSettings(withLength: withLength));

  /// Outil sans générateur dédié : réglages, demande à WinAI, puis écran de
  /// résultat (texte avec écoute, ou fiches recto verso).
  Future<void> _run(_Tool t) async {
    final l = context.l10n;
    final set = await _settings(t.label, withLength: t.withLength);
    if (set == null || !mounted) return;
    final topic = set.topic.isEmpty ? l.winaiTopicAny : set.topic;
    final subtitle =
        [set.subject, set.topic].where((x) => x.isNotEmpty).join(' · ');
    setState(() => _busy = true);
    try {
      if (await _viaServer(t, set, subtitle)) return;
      final text = await ChatbotService.instance.generate(
          prompt: t.prompt(set.subject, topic, _levels()[set.level], set.long),
          sources: widget.sources);
      if (!mounted) return;
      final cards = t.kind == _ToolKind.cards
          ? parseFlashcards(text)
          : const <WinAIFlashcard>[];
      // Réponse qui ne suit pas la forme des fiches : on la montre en texte
      // plutôt que de la perdre.
      _open(cards.length >= 2
          ? WinAIFlashcardsScreen(
              title: t.label, subtitle: subtitle, cards: cards)
          : WinAITextScreen(
              title: t.label,
              subtitle: subtitle,
              text: text,
              speechKey: 'tool:${t.label}:${text.hashCode}'));
    } on WinAiStudioException catch (e) {
      _refused(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fiches recto verso et résumé à écouter : générés et gardés par le
  /// serveur (on les retrouve dans « Mes créations »). Renvoie false quand
  /// le serveur ne connaît pas la route : l'outil passe par la discussion.
  Future<bool> _viaServer(_Tool t, _Settings set, String subtitle) async {
    final isCards = t.kind == _ToolKind.cards;
    if (!isCards && !t.withLength) return false;
    final svc = WinAiProductionsService.instance;
    try {
      final p = isCards
          ? await svc.generateFlashcards(
              subject: set.subject, topic: set.topic, sources: widget.sources)
          : await svc.generateAudioSummary(
              subject: set.subject,
              topic: set.topic,
              long: set.long,
              sources: widget.sources);
      if (!mounted) return true;
      final sub = p.title.isEmpty ? subtitle : p.title;
      _open(isCards
          ? WinAIFlashcardsScreen(title: t.label, subtitle: sub, cards: [
              for (final c in p.cards) (question: c.front, answer: c.back),
            ])
          : WinAITextScreen(
              title: t.label,
              subtitle: sub,
              text: p.script,
              speechKey: 'audio:${p.id}',
              citations: p.citations));
      return true;
    } on WinAiStudioException catch (e) {
      if (WinAiProductionsService.routeMissing(e)) return false;
      rethrow;
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Synthèse à partir de résultats réels : on choisit l'enfant ou la
  /// classe, puis WinAI rédige (bilan de la semaine, synthèse de classe).
  Future<void> _synthesis<T>({
    required String tool,
    required String pickTitle,
    required String empty,
    required IconData icon,
    required Future<List<T>> Function() load,
    required String Function(T) label,
    required Future<WinAISynthesis> Function(T) make,
  }) async {
    final l = context.l10n;
    setState(() => _busy = true);
    List<T> items;
    try {
      items = await load();
    } catch (_) {
      _toast(l.commonLoadError);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (items.isEmpty) return _toast(empty);
    final pick = items.length == 1
        ? items.first
        : await showWinBottomSheet<T>(
            context: context,
            title: pickTitle,
            child: Builder(
                builder: (sheet) => MoreGroup(children: [
                      for (final it in items)
                        MoreLine(
                            icon: icon,
                            label: label(it),
                            onTap: () => Navigator.pop<T>(sheet, it)),
                    ])));
    if (pick == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final r = await make(pick);
      if (!mounted) return;
      _open(WinAITextScreen(
          title: tool,
          subtitle: r.title,
          text: r.text,
          speechKey: 'synthesis:${r.title}:${r.text.hashCode}'));
    } on WinAiStudioException catch (e) {
      if (WinAiProductionsService.routeMissing(e)) {
        _toast(l.winaiToolUnavailable);
      } else {
        _refused(e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Épreuve complète du professeur : réglages, génération (30 à 50
  /// secondes), puis le sujet avec son corrigé et son barème.
  Future<void> _exam() async {
    final l = context.l10n;
    final req = await showWinBottomSheet<WinAIExamRequest>(
        context: context,
        title: l.winaiToolExam,
        child: const WinAIExamSettings());
    if (req == null || !mounted) return;
    setState(() {
      _busy = true;
      _slow = true;
    });
    try {
      final exam = await WinAiProductionsService.instance
          .generateExam(req, sources: widget.sources);
      if (mounted) _open(WinAIExamScreen(exam: exam));
    } on WinAiStudioException catch (e) {
      if (WinAiProductionsService.routeMissing(e)) {
        _toast(l.winaiToolUnavailable);
      } else {
        _refused(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _slow = false;
        });
      }
    }
  }

  MoreLine _line(_Tool t) => MoreLine(
      icon: t.icon, label: t.label, onTap: _busy ? null : () => _run(t));

  List<String> _levels() {
    final l = context.l10n;
    return [l.tutoringMatEasy, l.tutoringMatMedium, l.tutoringMatHard];
  }

  /// Refus du serveur : son message, et l'accès aux offres quand c'est la
  /// limite de l'abonnement.
  void _refused(WinAiStudioException e) {
    if (!mounted) return;
    // Les offres ne sont proposées que pour une limite ou une fonction hors
    // de l'abonnement, pas pour une source refusée.
    final plans = e.status == 402 || e.code == 'feature_not_in_plan';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.message),
      action: plans
          ? SnackBarAction(
              label: context.l10n.winaiStudioSeePlans,
              onPressed: () => _open(const PricingScreen()))
          : null,
    ));
  }

  List<Object>? get _sourcesJson => widget.sources.isEmpty
      ? null
      : widget.sources.map<Object>((r) => r.toJson()).toList();

  /// Quiz : l'élève a un générateur dédié (quiz enregistré, rejouable, ouvert
  /// tout de suite dans le lecteur) ; les autres comptes passent par la
  /// discussion.
  Future<void> _quiz() async {
    final l = context.l10n;
    final set = await _settings(l.winaiToolQuiz);
    if (set == null || !mounted) return;
    final topic = set.topic.isEmpty ? l.winaiTopicAny : set.topic;
    if (widget.role != WinRole.student) {
      widget.onGenerate(
          l.winaiPromptQuiz(set.subject, topic, _levels()[set.level]));
      return;
    }
    setState(() => _busy = true);
    try {
      final g = await WinAiStudioService.instance.generateQuiz(
          subject: set.subject,
          topic: set.topic,
          difficulty: _difficulties[set.level],
          sources: _sourcesJson);
      if (!mounted) return;
      _open(QuizActiveScreen(quiz: g.quiz.toQuiz()));
    } on WinAiStudioException catch (e) {
      _refused(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sheet() async {
    final l = context.l10n;
    final set = await _settings(l.winaiToolSheet);
    if (set == null || !mounted) return;
    final topic = set.topic.isEmpty ? l.winaiTopicAny : set.topic;
    if (widget.role != WinRole.student) {
      widget.onGenerate(
          l.winaiPromptSheet(set.subject, topic, _levels()[set.level]));
      return;
    }
    setState(() => _busy = true);
    try {
      final f = await WinAiStudioService.instance.generateRevisionSheet(
          subject: set.subject,
          topic: set.topic,
          difficulty: _difficulties[set.level],
          sources: _sourcesJson);
      if (!mounted) return;
      _open(WinAISheetScreen(sheet: f));
    } on WinAiStudioException catch (e) {
      _refused(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(t, style: WinType.titleL(s.onStrong)));

    final quiz = MoreLine(
        icon: PhosphorIconsRegular.exam,
        label: l.winaiToolQuiz,
        onTap: _busy ? null : _quiz);
    final sheet = MoreLine(
        icon: PhosphorIconsRegular.fileText,
        label: l.winaiToolSheet,
        onTap: _busy ? null : _sheet);
    final cards = _Tool(PhosphorIconsRegular.cards, l.winaiToolCards,
        (a, b, c, _) => l.winaiPromptCards(a, c, b),
        kind: _ToolKind.cards);
    final audio = _Tool(PhosphorIconsRegular.headphones, l.winaiToolAudio,
        (a, b, c, long) => l.winaiPromptAudio(a, c, b, long ? 450 : 150),
        withLength: true);
    final exercises = _Tool(PhosphorIconsRegular.pencilLine,
        l.winaiToolExercises, (a, b, c, _) => l.winaiPromptExercises(a, c, b));
    final plan = _Tool(PhosphorIconsRegular.calendarCheck, l.winaiToolPlan,
        (a, b, c, _) => l.winaiPromptPlan(a, c, b));
    final lesson = _Tool(PhosphorIconsRegular.chalkboardTeacher,
        l.winaiToolLesson, (a, b, c, _) => l.winaiPromptLesson(a, c, b));
    final rubric = _Tool(PhosphorIconsRegular.listChecks, l.winaiToolRubric,
        (a, b, c, _) => l.winaiPromptRubric(a, c, b));
    final helpChild = _Tool(PhosphorIconsRegular.handHeart,
        l.winaiToolHelpChild, (a, b, c, _) => l.winaiPromptHelpChild(a, c, b));
    final askChild = _Tool(PhosphorIconsRegular.cards, l.winaiToolAskChild,
        (a, b, c, _) => l.winaiPromptCards(a, c, b),
        kind: _ToolKind.cards);
    final remediation = _Tool(PhosphorIconsRegular.lifebuoy,
        l.winaiToolRemediation,
        (a, b, c, _) => l.winaiPromptRemediation(a, c, b));
    final parentsNote = _Tool(PhosphorIconsRegular.envelopeSimple,
        l.winaiToolParentsNote,
        (a, b, c, _) => l.winaiPromptParentsNote(a, c, b));
    final support = _Tool(PhosphorIconsRegular.usersThree, l.winaiToolSupport,
        (a, b, c, _) => l.winaiPromptLesson(a, c, b));

    final List<Widget> blocks = switch (widget.role) {
      WinRole.student => [
          title(l.winaiStudioRevise),
          MoreGroup(children: [sheet, _line(cards), _line(audio), _line(plan)]),
          const SizedBox(height: 18),
          title(l.winaiStudioTrain),
          MoreGroup(children: [quiz, _line(exercises)]),
          const SizedBox(height: 18),
          title(l.winaiStudioRetrieve),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.sparkle,
                label: l.winaiCreationsTitle,
                onTap: () => _open(const WinAICreationsScreen())),
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioCoach),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.graduationCap,
                label: l.studentTabsExamCoach,
                onTap: () => _open(const ExamCoachScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.playCircle,
                label: l.studentTabsGuidedSession,
                onTap: () => _open(const StudySessionScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                label: l.studentHubRevisionQuiz,
                onTap: () => _open(const QuizRevisionScreen())),
          ]),
        ],
      WinRole.teacher => [
          title(l.winaiStudioPrepare),
          MoreGroup(children: [_line(lesson), sheet, _line(audio)]),
          const SizedBox(height: 18),
          title(l.winaiStudioAssess),
          MoreGroup(children: [quiz, _line(exercises), _line(rubric)]),
          const SizedBox(height: 18),
          title(l.winaiStudioExam),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.exam,
                label: l.winaiToolExam,
                onTap: _busy ? null : _exam),
            MoreLine(
                icon: PhosphorIconsRegular.folderOpen,
                label: l.winaiExamsTitle,
                onTap: () => _open(const WinAIExamsScreen())),
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.chatText,
                label: l.mobileHomeCorrections,
                onTap: () => _open(const CorrectionQueueScreen())),
          ]),
        ],
      WinRole.parent => [
          title(l.winaiStudioReport),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.chartLineUp,
                label: l.winaiToolWeekReport,
                onTap: _busy
                    ? null
                    : () => _synthesis<ApiChild>(
                        tool: l.winaiToolWeekReport,
                        pickTitle: l.winaiPickChild,
                        empty: l.winaiNoChild,
                        icon: PhosphorIconsRegular.student,
                        load: ParentService.instance.getChildren,
                        label: (c) => '${c.firstName} ${c.lastName}'.trim(),
                        make: (c) => WinAiProductionsService.instance
                            .childWeekReport(c.id))),
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioHelp),
          MoreGroup(children: [
            _line(helpChild),
            _line(askChild),
            _line(audio),
            _line(plan)
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.bell,
                label: l.commonWinaiAlerts,
                onTap: () => _open(const WinAIAlertsScreen())),
          ]),
        ],
      WinRole.institution => [
          title(l.winaiStudioReport),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.chartLineUp,
                label: l.winaiToolClassSummary,
                onTap: _busy
                    ? null
                    : () => _synthesis<ApiGroup>(
                        tool: l.winaiToolClassSummary,
                        pickTitle: l.winaiPickGroup,
                        empty: l.winaiNoGroup,
                        icon: PhosphorIconsRegular.usersThree,
                        load: InstitutionService.instance.getGroups,
                        label: (g) => g.name,
                        make: (g) => WinAiProductionsService.instance
                            .groupSummary(g.id))),
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioPrepare),
          MoreGroup(children: [
            _line(remediation),
            _line(support),
            _line(parentsNote)
          ]),
          const SizedBox(height: 18),
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.warning,
                label: l.instRiskTitle,
                onTap: () => _open(const AtRiskScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.listChecks,
                label: l.instRiskActionPlan,
                onTap: () => _open(const ActionPlanScreen())),
          ]),
        ],
    };

    return Column(children: [
      // Génération en cours : bandeau discret, les outils restent visibles.
      if (_busy) ...[
        const LinearProgressIndicator(minHeight: 3),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
              alignment: Alignment.centerLeft,
              child:
                  Text(_slow ? l.winaiExamBusy : l.winaiStudioBusy,
                      style: WinType.bodyS(s.onMuted))),
        ),
      ],
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(l.winaiStudioHint, style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 18),
            ...blocks,
          ],
        ),
      ),
    ]);
  }
}

/// Réglages d'une génération : matière, chapitre, niveau, puis « Générer ».
class _GenerateSettings extends StatefulWidget {
  /// Propose aussi la durée (résumé à écouter).
  final bool withLength;
  const _GenerateSettings({this.withLength = false});
  @override
  State<_GenerateSettings> createState() => _GenerateSettingsState();
}

class _GenerateSettingsState extends State<_GenerateSettings> {
  String _subject = WinData.subjects.first.id;
  int _level = 1;
  bool _long = false;
  final _topic = TextEditingController();

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final levels = [l.tutoringMatEasy, l.tutoringMatMedium, l.tutoringMatHard];
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: WinType.titleM(s.onStrong)));
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          label(l.commonSubject),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final sub in WinData.subjects)
              WinChip(sub.short,
                  active: _subject == sub.id,
                  onTap: () => setState(() => _subject = sub.id)),
          ]),
          const SizedBox(height: 18),
          label(l.winaiSettingsTopic),
          WinTextField(hint: l.winaiSettingsTopicHint, controller: _topic),
          const SizedBox(height: 18),
          label(l.commonLevel),
          Wrap(spacing: 8, children: [
            for (var i = 0; i < levels.length; i++)
              WinChip(levels[i],
                  active: _level == i,
                  onTap: () => setState(() => _level = i)),
          ]),
          if (widget.withLength) ...[
            const SizedBox(height: 18),
            label(l.winaiSettingsLength),
            Wrap(spacing: 8, children: [
              WinChip(l.winaiLengthShort,
                  active: !_long, onTap: () => setState(() => _long = false)),
              WinChip(l.winaiLengthLong,
                  active: _long, onTap: () => setState(() => _long = true)),
            ]),
          ],
          const SizedBox(height: 24),
          WinButton(l.winaiSettingsGenerate,
              block: true,
              icon: PhosphorIconsRegular.sparkle,
              onTap: () => Navigator.pop<_Settings>(context, (
                    subject: WinData.subjectById(_subject).name,
                    topic: _topic.text.trim(),
                    level: _level,
                    long: _long
                  ))),
          const SizedBox(height: 8),
        ]);
  }
}
