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
import '../../widgets/winai_markdown.dart';
import '../../widgets/winai_memories_sheet.dart';

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

typedef _Msg = ({bool me, String text});

class _WinAIScreenState extends State<WinAIScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
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
      _msgs.add((me: true, text: t));
      _ctrl.clear();
      _thinking = true;
    });
    // Réponse écrite en direct, dans la même conversation que les messages
    // précédents : WinAI garde le contexte.
    var started = false;
    void show(String text) {
      if (!started) {
        started = true;
        _thinking = false;
        _msgs.add((me: false, text: text));
      } else {
        _msgs[_msgs.length - 1] = (me: false, text: text);
      }
    }

    final reply = await ChatbotService.instance.streamMessage(
      message: t,
      conversationId: _conversationId,
      onConversation: (id) => _conversationId = id,
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
    _tabs.animateTo(0);
    try {
      final history = await ChatbotService.instance.getHistory(picked.id);
      if (!mounted) return;
      setState(() {
        _thinking = false;
        _msgs.addAll(history
            .where((m) => m.content.trim().isNotEmpty)
            .map((m) => (me: m.role == 'user', text: m.content)));
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
    _tabs.animateTo(0);
    _send(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
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
          tabs: [Tab(text: l.winaiTabChat), Tab(text: l.winaiTabStudio)],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _chat(s),
          _Studio(role: widget.role, onGenerate: _generate),
        ],
      ),
    );
  }

  Widget _chat(WinScheme s) {
    return Column(children: [
      Expanded(child: _msgs.isEmpty && !_thinking ? _welcome(s) : _thread(s)),
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
                // Réponse de WinAI : Markdown et formules compilées.
                : WinAIMarkdown(m.text, color: s.onSurface),
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

/// Les outils de WinAI pour un type de compte, rangés par usage.
class _Studio extends StatelessWidget {
  final WinRole role;
  final ValueChanged<String> onGenerate;
  const _Studio({required this.role, required this.onGenerate});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, WinPageRoute(builder: (_) => page));

  /// Feuille de réglages d'un outil de génération, puis envoi de la demande.
  Future<void> _settings(BuildContext context, String title,
      String Function(String subject, String topic, String level) prompt) async {
    final text = await showWinBottomSheet<String>(
      context: context,
      title: title,
      child: _GenerateSettings(prompt: prompt),
    );
    if (text != null) onGenerate(text);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    Widget title(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(t, style: WinType.titleL(s.onStrong)));

    final generate = MoreGroup(children: [
      MoreLine(
          icon: PhosphorIconsRegular.exam,
          label: l.winaiToolQuiz,
          onTap: () => _settings(context, l.winaiToolQuiz, l.winaiPromptQuiz)),
      MoreLine(
          icon: PhosphorIconsRegular.fileText,
          label: l.winaiToolSheet,
          onTap: () =>
              _settings(context, l.winaiToolSheet, l.winaiPromptSheet)),
    ]);

    final List<Widget> blocks = switch (role) {
      WinRole.student => [
          title(l.winaiStudioGenerate),
          generate,
          const SizedBox(height: 18),
          title(l.spaceGroupPractice),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.graduationCap,
                label: l.studentTabsExamCoach,
                onTap: () => _open(context, const ExamCoachScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.playCircle,
                label: l.studentTabsGuidedSession,
                onTap: () => _open(context, const StudySessionScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                label: l.studentHubRevisionQuiz,
                onTap: () => _open(context, const QuizRevisionScreen())),
          ]),
        ],
      WinRole.teacher => [
          title(l.winaiStudioGenerate),
          generate,
          const SizedBox(height: 18),
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.chatText,
                label: l.mobileHomeCorrections,
                onTap: () => _open(context, const CorrectionQueueScreen())),
          ]),
        ],
      WinRole.parent => [
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.bell,
                label: l.commonWinaiAlerts,
                onTap: () => _open(context, const WinAIAlertsScreen())),
          ]),
        ],
      WinRole.institution => [
          title(l.winaiStudioFollow),
          MoreGroup(children: [
            MoreLine(
                icon: PhosphorIconsRegular.warning,
                label: l.instRiskTitle,
                onTap: () => _open(context, const AtRiskScreen())),
            MoreLine(
                icon: PhosphorIconsRegular.listChecks,
                label: l.instRiskActionPlan,
                onTap: () => _open(context, const ActionPlanScreen())),
          ]),
        ],
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(l.winaiStudioHint, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 18),
        ...blocks,
      ],
    );
  }
}

/// Réglages d'une génération : matière, chapitre, niveau, puis « Générer ».
class _GenerateSettings extends StatefulWidget {
  final String Function(String subject, String topic, String level) prompt;
  const _GenerateSettings({required this.prompt});
  @override
  State<_GenerateSettings> createState() => _GenerateSettingsState();
}

class _GenerateSettingsState extends State<_GenerateSettings> {
  String _subject = WinData.subjects.first.id;
  int _level = 1;
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
          const SizedBox(height: 24),
          WinButton(l.winaiSettingsGenerate,
              block: true,
              icon: PhosphorIconsRegular.sparkle,
              onTap: () => Navigator.pop(
                  context,
                  widget.prompt(WinData.subjectById(_subject).name,
                      _topic.text.trim().isEmpty
                          ? l.winaiTopicAny
                          : _topic.text.trim(),
                      levels[_level]))),
          const SizedBox(height: 8),
        ]);
  }
}
