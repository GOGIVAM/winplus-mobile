import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../institution/institution_tabs.dart' show InstitutionWinAITab;
import '../parent/parent_tabs.dart' show ParentWinAITab;
import '../student/student_tabs.dart' show StudentWinAITab;
import '../teacher/teacher_tabs.dart' show TeacherWinAITab;
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'winai_memories_sheet.dart';

class _WinAIRoleConfig {
  final String subtitle;
  final Color accent;
  final List<String> suggestions;
  const _WinAIRoleConfig({
    required this.subtitle,
    required this.accent,
    required this.suggestions,
  });
}

/// Widget flottant global WinAI (inspiré du bouton + mini-carte du site web) :
/// un bouton rond déplaçable par l'utilisateur, superposé à tous les écrans
/// d'un espace (monté une seule fois au niveau de la coquille RoleShell pour
/// que sa position survive aux changements d'onglet). Un tap ouvre une
/// mini-carte de lancement rapide (suggestions, mémoire, saisie) qui bascule
/// vers l'écran de conversation complet propre au rôle — jamais de chat en
/// ligne dans la mini-carte elle-même, comme sur le web.
class WinAIFloatingWidget extends StatefulWidget {
  final Widget child;
  final WinRole role;
  const WinAIFloatingWidget(
      {super.key, required this.child, required this.role});

  @override
  State<WinAIFloatingWidget> createState() => _WinAIFloatingWidgetState();
}

class _WinAIFloatingWidgetState extends State<WinAIFloatingWidget> {
  static const double _size = 58;
  Offset? _pos;
  bool _open = false;
  bool _dragged = false;
  final _ctrl = TextEditingController();

  _WinAIRoleConfig _configFor(WinRole role) => switch (role) {
        WinRole.student => _WinAIRoleConfig(
            subtitle: 'Ton assistant pédagogique personnel',
            accent: WinColors.teal500,
            suggestions: const [
              'Explique-moi les dérivées',
              'Plan de révision BAC C',
              'Mes matières faibles ?',
              'Génère un quiz Chimie',
            ],
          ),
        WinRole.parent => _WinAIRoleConfig(
            subtitle: 'Ton conseiller familial chaleureux',
            accent: WinColors.blue500,
            suggestions: const [
              'Mon enfant est en difficulté',
              'Plan de révision maison',
              'Analyse ses résultats',
              'Comment le motiver ?',
            ],
          ),
        WinRole.teacher => _WinAIRoleConfig(
            subtitle: 'Ton assistant éditorial & pédagogique',
            accent: WinColors.gold,
            suggestions: const [
              'Quiz Terminale C (10 QCM)',
              'Fiche de cours',
              'Correction type',
              'Optimiser un titre',
            ],
          ),
        WinRole.institution => _WinAIRoleConfig(
            subtitle: 'Ton auditeur analytique & stratège institutionnel',
            accent: WinColors.teal500,
            suggestions: const [
              'Analyse de cohorte',
              'Élèves à risque',
              "Plan d'action prioritaire",
              'Benchmark national',
            ],
          ),
      };

  static Widget _screenFor(WinRole role, String? initialMessage) {
    switch (role) {
      case WinRole.student:
        return StudentWinAITab(initialMessage: initialMessage);
      case WinRole.parent:
        return ParentWinAITab(initialMessage: initialMessage);
      case WinRole.teacher:
        return TeacherWinAITab(initialMessage: initialMessage);
      case WinRole.institution:
        return InstitutionWinAITab(initialMessage: initialMessage);
    }
  }

  void _openFull([String? initialMessage]) {
    setState(() => _open = false);
    Navigator.push(
      context,
      WinPageRoute(
        builder: (ctx) => _screenFor(widget.role, initialMessage),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final cfg = _configFor(widget.role);

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight;
      _pos ??= Offset(maxW - _size - 16, maxH - _size - 16);
      final pos = Offset(
        _pos!.dx.clamp(8, maxW - _size - 8),
        _pos!.dy.clamp(8, maxH - _size - 8),
      );

      return Stack(children: [
        widget.child,

        // ── Scrim + mini-carte ──
        if (_open) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _open = false),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: pos.dy > maxH / 2 ? null : (maxH - pos.dy - _size) + 16,
            top: pos.dy > maxH / 2 ? maxH - pos.dy + 16 : null,
            child: _MiniCard(
              subtitle: cfg.subtitle,
              accent: cfg.accent,
              suggestions: cfg.suggestions,
              ctrl: _ctrl,
              onClose: () => setState(() => _open = false),
              onSuggestion: _openFull,
              onSend: () => _openFull(_ctrl.text.trim()),
              onMemories: () {
                setState(() => _open = false);
                showWinAIMemoriesSheet(context);
              },
              onOpenFull: () => _openFull(),
            ),
          ),
        ],

        // ── Bouton flottant déplaçable ──
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: GestureDetector(
            onPanStart: (_) => _dragged = false,
            onPanUpdate: (details) {
              _dragged = true;
              setState(() => _pos = pos + details.delta);
            },
            onTap: () {
              if (_dragged) return;
              setState(() => _open = !_open);
            },
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cfg.accent, cfg.accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.auto_awesome, color: s.onPrimary, size: 26),
            ),
          ),
        ),
      ]);
    });
  }
}

class _MiniCard extends StatelessWidget {
  final String subtitle;
  final Color accent;
  final List<String> suggestions;
  final TextEditingController ctrl;
  final VoidCallback onClose;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onSend;
  final VoidCallback onMemories;
  final VoidCallback onOpenFull;
  const _MiniCard({
    required this.subtitle,
    required this.accent,
    required this.suggestions,
    required this.ctrl,
    required this.onClose,
    required this.onSuggestion,
    required this.onSend,
    required this.onMemories,
    required this.onOpenFull,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 440),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: BorderRadius.circular(WinRadii.xl),
          boxShadow: WinShadows.lg,
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: Icon(Icons.auto_awesome, size: 18, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text('WinAI',
                          style: WinType.archivo(size: 17, color: s.onStrong))),
                  GestureDetector(
                    onTap: onOpenFull,
                    child: Icon(Icons.open_in_full, size: 18, color: s.onMuted),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(Icons.close, size: 20, color: s.onMuted),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle, style: WinType.bodyS(s.onMuted)),
                const SizedBox(height: 14),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map((q) => GestureDetector(
                              onTap: () => onSuggestion(q),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(WinRadii.full),
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.25))),
                                child: Text(q,
                                    style: WinType.manrope(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: accent)),
                              ),
                            ))
                        .toList()),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onMemories,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(WinRadii.full),
                      border: Border.all(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.psychology_rounded,
                          size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      Text('Mémoire WinAI',
                          style: WinType.manrope(
                              size: 12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF8B5CF6))),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: s.surface2,
                        borderRadius: BorderRadius.circular(WinRadii.full),
                        border: Border.all(color: s.outline),
                      ),
                      child: TextField(
                        controller: ctrl,
                        onSubmitted: (_) => onSend(),
                        style: WinType.bodyM(s.onStrong),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Écris ta question…',
                          hintStyle: WinType.bodyS(s.onFaint),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration:
                          BoxDecoration(color: accent, shape: BoxShape.circle),
                      child:
                          const Icon(Icons.send, size: 18, color: Colors.white),
                    ),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }
}
