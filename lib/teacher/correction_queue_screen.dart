import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import '../widgets/win_screen.dart';
import '../widgets/external_links.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CorrectionQueueScreen extends StatefulWidget {
  const CorrectionQueueScreen({super.key});
  @override
  State<CorrectionQueueScreen> createState() => _CorrectionQueueScreenState();
}

class _CorrectionQueueScreenState extends State<CorrectionQueueScreen> {
  List<ApiSubmission>? _subs;
  bool _failed = false;
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
      if (mounted) {
        setState(() {
          _subs = subs;
          _failed = false;
        });
      }
    } catch (_) {
      // Une panne n'est pas « rien à corriger ».
      if (mounted) {
        setState(() {
          _subs = [];
          _failed = true;
        });
      }
    }
  }

  String _filterLabel(BuildContext context, String f) => switch (f) {
        'En attente' => context.l10n.commonPending,
        'Corrigé' => context.l10n.teacherCorrectionFilterMarked,
        _ => context.l10n.commonAll,
      };

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
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text(context.l10n.teacherCorrectionQueueTitle, style: WinType.headlineS(s.onStrong)),
        actions: [
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                  child:
                      WinBadge(context.l10n.teacherCorrectionPendingCount(pending), color: BadgeColor.warn)),
            ),
          IconButton(
            icon: Icon(PhosphorIconsRegular.arrowClockwise, color: s.onStrong),
            onPressed: () {
              setState(() => _subs = null);
              _load();
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters
                    .map((f) => WinChip(_filterLabel(context, f),
                        active: _filter == f,
                        onTap: () => setState(() => _filter = f)))
                    .toList()),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildList(s)),
      ]),
    );
  }

  Widget _buildList(WinScheme s) {
    if (_subs == null) return const WinLoading();
    if (_failed) {
      return WinErrorState(
          message: context.l10n.commonLoadError,
          onRetry: () {
            setState(() => _subs = null);
            _load();
          });
    }
    if (_items.isEmpty) {
      return WinEmptyState(title: context.l10n.teacherCorrectionEmpty, icon: PhosphorIconsRegular.checkCircle);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _SubmissionCard(
        sub: _items[i],
        onCorrect: () async {
          await showModalBottomSheet(
      showDragHandle: false,
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
    final l = context.l10n;
    final who = [sub.studentName, if (sub.className != null) sub.className!].join(' \u00b7 ');
    final when = [
      if (sub.submittedAt != null) l.teacherCorrectionSubmittedOn(WinFormat.dayMonth(sub.submittedAt!)),
      if (!sub.corrected && sub.daysWaiting > 0) l.teacherCorrectionWaitingDays(sub.daysWaiting),
    ].join(' \u00b7 ');
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: sub.corrected ? WinColors.success : WinColors.warn,
                    width: 2)),
            child: WinAvatar(sub.studentName, size: 32),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Le devoir d'abord : deux copies du même élève se distinguent.
            Text(sub.contentTitle.isEmpty ? sub.studentName : sub.contentTitle,
                style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 2),
            Text(who, style: WinType.bodyS(s.onMuted)),
            if (when.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(when, style: WinType.labelM(s.onFaint)),
            ],
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (sub.corrected)
              WinBadge(WinFormat.grade20(sub.score20 == null ? null : sub.score20! * 5),
                  color: BadgeColor.success)
            else
              WinBadge(sub.isDraft ? l.commonDraft : l.commonPending, color: BadgeColor.warn),
            if (sub.urgent && !sub.corrected) ...[
              const SizedBox(height: 6),
              WinBadge(l.teacherCorrectionUrgent, color: BadgeColor.error),
            ],
          ]),
        ]),
        const SizedBox(height: 12),
        if (!sub.corrected)
          WinButton(l.teacherCorrectionCorrect,
              small: true, icon: PhosphorIconsRegular.chatText, onTap: onCorrect)
        else
          // La feuille de correction montre la note et le commentaire déjà
          // donnés : un seul bouton suffit pour les revoir et les modifier.
          WinButton(l.commonEdit,
              small: true, variant: WinButtonVariant.outline, onTap: onCorrect),
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
  // Note sur le barème du devoir (20, ou 100 pour un quiz assigné), reprise
  // de la correction déjà donnée ; 12/20 par défaut pour une nouvelle copie.
  late final double _max = widget.sub.maxScore > 0 ? widget.sub.maxScore : 20;
  late double _score = (widget.sub.score ?? _max * 0.6).clamp(0, _max).toDouble();
  late final _fbCtrl = TextEditingController(text: widget.sub.comment ?? '');
  bool _sent = false, _loading = false;

  @override
  void dispose() {
    _fbCtrl.dispose();
    super.dispose();
  }

  /// Au demi-point près ; un entier reste un entier.
  num get _note {
    final v = (_score * 2).round() / 2;
    return v == v.roundToDouble() ? v.toInt() : v;
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await TeacherService.instance
        .correctSubmission(widget.sub.id, _note, _fbCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() {
        _loading = false;
        _sent = true;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.teacherCorrectionSendError)));
    }
  }

  Future<void> _openFile() async {
    final ok = await ExternalLinks.open(widget.sub.fileUrl!);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.teacherCorrectionOpenFileError)));
    }
  }

  Widget _work(WinScheme s) {
    final l = context.l10n;
    final sub = widget.sub;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.teacherCorrectionStudentWork, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 8),
      if (sub.textContent != null)
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: s.surface2,
              borderRadius: BorderRadius.circular(WinRadii.md),
              border: Border.all(color: s.outline)),
          child: SingleChildScrollView(
              child: Text(sub.textContent!, style: WinType.bodyM(s.onStrong))),
        ),
      if (sub.fileUrl != null) ...[
        if (sub.textContent != null) const SizedBox(height: 8),
        WinButton(l.teacherCorrectionOpenFile,
            small: true,
            variant: WinButtonVariant.outline,
            icon: PhosphorIconsRegular.fileArrowDown,
            onTap: _openFile),
      ],
      if (sub.textContent == null && sub.fileUrl == null)
        Text(l.teacherCorrectionNoWork, style: WinType.bodyS(s.onFaint)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final maxLabel = WinFormat.decimal(_max);
    return Container(
      decoration: BoxDecoration(
          color: s.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: s.outline2,
                    borderRadius: BorderRadius.circular(WinRadii.full)),
                margin: const EdgeInsets.only(bottom: 16)),
          ),
          Text(l.teacherCorrectionSheetTitle(widget.sub.studentName),
              textAlign: TextAlign.center, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 4),
          Text(widget.sub.contentTitle,
              textAlign: TextAlign.center, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 20),
          if (_sent)
            WinAlert(l.teacherCorrectionSent(widget.sub.studentName),
                type: BadgeColor.success)
          else ...[
            _work(s),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Text(l.teacherCorrectionScale(maxLabel),
                      style: WinType.titleM(s.onStrong))),
              Text('${WinFormat.decimal(_note)}/$maxLabel',
                  style: WinType.archivo(
                      size: 24, weight: FontWeight.w700, color: s.primary)),
            ]),
            Slider(
              value: _score,
              min: 0,
              max: _max,
              divisions: (_max * 2).round(),
              activeColor: s.primary,
              inactiveColor: s.outline2,
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fbCtrl,
              maxLines: 4,
              style: WinType.manrope(size: 14, color: s.onStrong),
              decoration: InputDecoration(
                hintText: l.teacherCorrectionFeedbackHint,
                hintStyle: WinType.manrope(size: 14, color: s.onFaint),
                filled: true,
                fillColor: s.surface2,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WinRadii.md),
                    borderSide: BorderSide(color: s.outline)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WinRadii.md),
                    borderSide: BorderSide(color: s.outline)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(WinRadii.md),
                    borderSide: BorderSide(color: s.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            WinButton(l.teacherCorrectionSend,
                block: true,
                loading: _loading,
                icon: PhosphorIconsRegular.paperPlaneRight,
                onTap: _submit),
          ],
        ]),
      ),
    );
  }
}
