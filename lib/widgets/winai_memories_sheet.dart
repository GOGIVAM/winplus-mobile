import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

// ── Méta par type ────────────────────────────────────────────────────────────

const _violet = Color(0xFF8B5CF6);
const _violetBg = Color(0xFFF5F3FF);

class _TypeMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _TypeMeta(this.label, this.icon, this.color, this.bg);
}

const _meta = <String, _TypeMeta>{
  'struggling_topics':   _TypeMeta('Difficulté',  Icons.warning_amber_rounded,        WinColors.error,   WinColors.errorBg),
  'understood_topics':   _TypeMeta('Maîtrisé',    Icons.check_circle_rounded,         WinColors.success,  WinColors.successBg),
  'exam_context':        _TypeMeta('Examen',       Icons.track_changes_rounded,        _violet,            _violetBg),
  'learning_preference': _TypeMeta('Préférence',   Icons.psychology_rounded,           WinColors.blue500,  WinColors.blue50),
  'motivation_style':    _TypeMeta('Motivation',   Icons.local_fire_department_rounded, WinColors.warn,    WinColors.warnBg),
};

_TypeMeta _metaFor(String type) =>
    _meta[type] ?? const _TypeMeta('Mémoire', Icons.note_alt_outlined, WinColors.ink400, WinColors.ink50);

// ── Fonction d'ouverture ──────────────────────────────────────────────────────

void showWinAIMemoriesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _WinAIMemoriesSheet(),
  );
}

// ── Widget ───────────────────────────────────────────────────────────────────

class _WinAIMemoriesSheet extends StatefulWidget {
  const _WinAIMemoriesSheet();
  @override
  State<_WinAIMemoriesSheet> createState() => _WinAIMemoriesSheetState();
}

class _WinAIMemoriesSheetState extends State<_WinAIMemoriesSheet> {
  List<ApiWinAIMemory> _memories = [];
  bool _loading = true;
  String? _error;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ChatbotService.instance.getMemories();
      if (mounted) setState(() { _memories = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Impossible de charger les mémoires.'; _loading = false; });
    }
  }

  Future<void> _delete(int id) async {
    setState(() => _deletingId = id);
    final ok = await ChatbotService.instance.deleteMemory(id);
    if (!mounted) return;
    if (ok) {
      setState(() { _memories.removeWhere((m) => m.id == id); _deletingId = null; });
    } else {
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suppression échouée.')),
      );
    }
  }

  // Grouper par type, conserver l'ordre défini dans _meta
  Map<String, List<ApiWinAIMemory>> get _grouped {
    final map = <String, List<ApiWinAIMemory>>{};
    for (final m in _memories) {
      (map[m.type] ??= []).add(m);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          decoration: BoxDecoration(color: s.outline2, borderRadius: BorderRadius.circular(2)),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _violetBg, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Icon(Icons.psychology_rounded, size: 20, color: _violet)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mémoire WinAI', style: WinType.archivo(size: 16, color: s.onStrong)),
                Text('Ce que WinAI a retenu de toi', style: WinType.bodyS(s.onMuted)),
              ]),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: s.onMuted),
              onPressed: _load,
              tooltip: 'Actualiser',
            ),
          ]),
        ),

        const Divider(height: 1),

        // Body
        Flexible(
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(_error!, style: WinType.bodyM(WinColors.error), textAlign: TextAlign.center),
                    )
                  : _memories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.eco_outlined, size: 40, color: WinColors.success),
                            const SizedBox(height: 12),
                            Text(
                              'WinAI n\'a pas encore mémorisé d\'informations. Continue à interagir !',
                              style: WinType.bodyM(s.onMuted),
                              textAlign: TextAlign.center,
                            ),
                          ]),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          shrinkWrap: true,
                          children: _grouped.entries.map((entry) {
                            final m = _metaFor(entry.key);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                                  child: Row(children: [
                                    Icon(m.icon, size: 13, color: m.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      m.label.toUpperCase(),
                                      style: WinType.manrope(size: 11, weight: FontWeight.w700, color: m.color)
                                          .copyWith(letterSpacing: 0.6),
                                    ),
                                  ]),
                                ),
                                ...entry.value.map((mem) => _MemoryRow(
                                  memory: mem,
                                  meta: m,
                                  deleting: _deletingId == mem.id,
                                  onDelete: () => _delete(mem.id),
                                )),
                              ],
                            );
                          }).toList(),
                        ),
        ),

        // Safe area bottom
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }
}

// ── Ligne mémoire ─────────────────────────────────────────────────────────────

class _MemoryRow extends StatelessWidget {
  final ApiWinAIMemory memory;
  final _TypeMeta meta;
  final bool deleting;
  final VoidCallback onDelete;
  const _MemoryRow({
    required this.memory,
    required this.meta,
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: meta.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: meta.color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(memory.content, style: WinType.bodyS(s.onSurface)),
        ),
        const SizedBox(width: 8),
        deleting
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: WinColors.error),
              )
            : GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: WinColors.error),
              ),
      ]),
    );
  }
}
