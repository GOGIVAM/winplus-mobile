import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class CorrectionQueueScreen extends StatefulWidget {
  const CorrectionQueueScreen({super.key});
  @override
  State<CorrectionQueueScreen> createState() => _CorrectionQueueScreenState();
}

class _CorrectionQueueScreenState extends State<CorrectionQueueScreen> {
  List<ApiSubmission>? _subs;
  String _filter = 'Tout';
  static const _filters = ['Tout', 'En attente', 'Corrigé'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final subs = await TeacherService.instance.getSubmissions();
      if (mounted) setState(() => _subs = subs);
    } catch (_) {
      if (mounted) setState(() => _subs = []);
    }
  }

  List<ApiSubmission> get _items {
    final all = _subs ?? [];
    return switch (_filter) {
      'En attente' => all.where((s) => !s.corrected).toList(),
      'Corrigé' => all.where((s) => s.corrected).toList(),
      _ => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final pending = (_subs ?? []).where((x) => !x.corrected).length;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('File de corrections', style: WinType.headlineS(s.onStrong)),
        actions: [
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: WinBadge('$pending en attente', color: BadgeColor.warn)),
            ),
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() => _subs = null); _load(); },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: _filters.map((f) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: WinChip(f, active: _filter == f, onTap: () => setState(() => _filter = f)),
          )).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList(s)),
      ]),
    );
  }

  Widget _buildList(WinScheme s) {
    if (_subs == null) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline, size: 64, color: s.onFaint),
        const SizedBox(height: 12),
        Text('Aucune soumission', style: WinType.bodyM(s.onMuted)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _SubmissionCard(
        sub: _items[i],
        onCorrect: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CorrectionSheet(sub: _items[i]),
          );
          _load();
        },
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final ApiSubmission sub;
  final VoidCallback onCorrect;
  const _SubmissionCard({required this.sub, required this.onCorrect});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WinAvatar(sub.studentName, size: 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.studentName, style: WinType.titleM(s.onStrong)),
            Text(sub.submittedAt, style: WinType.labelM(s.onFaint)),
          ])),
          if (sub.corrected)
            WinBadge('${sub.score}/20', color: BadgeColor.success)
          else
            const WinBadge('En attente', color: BadgeColor.warn),
        ]),
        const SizedBox(height: 8),
        Text(sub.contentTitle, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 12),
        if (!sub.corrected)
          WinButton('Corriger', small: true, icon: Icons.rate_review_outlined, onTap: onCorrect)
        else
          Row(children: [
            WinButton('Voir la correction', small: true, variant: WinButtonVariant.outline, onTap: () {}),
            const SizedBox(width: 8),
            WinButton('Modifier', small: true, variant: WinButtonVariant.ghost, onTap: onCorrect),
          ]),
      ]),
    );
  }
}

class _CorrectionSheet extends StatefulWidget {
  final ApiSubmission sub;
  const _CorrectionSheet({required this.sub});
  @override
  State<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends State<_CorrectionSheet> {
  double _score = 12;
  final _fbCtrl = TextEditingController();
  bool _sent = false, _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await TeacherService.instance.correctSubmission(
        widget.sub.id, _score.round(), _fbCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() { _loading = false; _sent = true; });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.zero),
      padding: EdgeInsets.fromLTRB(24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, color: s.outline2, margin: const EdgeInsets.only(bottom: 16)),
        Text('Corriger : ${widget.sub.studentName}', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 4),
        Text(widget.sub.contentTitle, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 20),
        if (_sent)
          WinAlert('Correction envoyée à ${widget.sub.studentName}.', type: BadgeColor.success)
        else ...[
          Row(children: [
            Text('Note : ', style: WinType.titleM(s.onStrong)),
            Text('${_score.round()}/20',
                style: WinType.archivo(size: 24, weight: FontWeight.w700, color: s.primary)),
          ]),
          Slider(
            value: _score, min: 0, max: 20, divisions: 40,
            activeColor: s.primary, inactiveColor: s.outline2,
            onChanged: (v) => setState(() => _score = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fbCtrl,
            maxLines: 4,
            style: WinType.manrope(size: 14, color: s.onStrong),
            decoration: InputDecoration(
              hintText: 'Commentaires et retours à l\'étudiant…',
              hintStyle: WinType.manrope(size: 14, color: s.onFaint),
              filled: true, fillColor: s.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: s.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: s.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: s.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          WinButton('Envoyer la correction', block: true, loading: _loading,
              icon: Icons.send_outlined, onTap: _submit),
        ],
      ]),
    );
  }
}
