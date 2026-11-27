import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/l10n.dart';
import '../../services/tutor_review_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';

/// Avis des élèves sur le profil public d'un tuteur (lot 6 : avant, seuls
/// la note et le nombre d'avis s'affichaient). Rien tant qu'il n'y en a pas.
class TutorReviewsSection extends StatefulWidget {
  final int tutorUserId;

  /// Vrai sur l'aperçu du répétiteur : il répond aux avis, ou corrige sa
  /// réponse.
  final bool canReply;
  const TutorReviewsSection(
      {super.key, required this.tutorUserId, this.canReply = false});

  @override
  State<TutorReviewsSection> createState() => _TutorReviewsSectionState();
}

class _TutorReviewsSectionState extends State<TutorReviewsSection> {
  List<TutorReview>? _reviews;
  bool _all = false;

  @override
  void initState() {
    super.initState();
    TutorReviewService.instance.getForTutor(widget.tutorUserId).then((r) {
      if (mounted) setState(() => _reviews = r);
    }).catchError((_) {
      if (mounted) setState(() => _reviews = const []);
    });
  }

  /// Réponse publique à un avis ; le refus du serveur (filtre des
  /// coordonnées, par exemple) s'affiche tel quel.
  Future<void> _reply(TutorReview r) async {
    final l = context.l10n;
    final text = await showWinBottomSheet<String>(
        context: context,
        title: l.reviewsReplyTitle,
        child: _ReplyForm(initial: r.tutorReply ?? ''));
    if (text == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await TutorReviewService.instance.reply(r.id, text);
      if (!mounted) return;
      setState(() => _reviews = [
            for (final x in _reviews ?? const <TutorReview>[])
              x.id == r.id ? updated : x,
          ]);
      messenger.showSnackBar(SnackBar(content: Text(l.reviewsReplySent)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews;
    if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    final shown = _all ? reviews : reviews.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.reviewsTitle(reviews.length), style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 8),
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WinCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.studentName ?? l.reviewsStudent, style: WinType.titleS(s.onStrong))),
                  for (var i = 1; i <= 5; i++)
                    Icon(i <= r.rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        size: 14, color: WinColors.gold),
                ]),
                if (r.createdAt != null) Text(WinFormat.dateShort(r.createdAt!), style: WinType.labelS(s.onMuted)),
                if ((r.comment ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(r.comment!.trim(), style: WinType.bodyM(s.onStrong)),
                ],
                if ((r.tutorReply ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: s.surface2, borderRadius: BorderRadius.circular(10)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.reviewsTutorReply, style: WinType.labelM(s.onMuted)),
                      const SizedBox(height: 2),
                      Text(r.tutorReply!.trim(), style: WinType.bodyS(s.onStrong)),
                    ]),
                  ),
                ],
                if (widget.canReply)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                        onPressed: () => _reply(r),
                        child: Text((r.tutorReply ?? '').trim().isEmpty
                            ? l.reviewsReply
                            : l.reviewsEditReply)),
                  ),
              ]),
            ),
          ),
        if (!_all && reviews.length > 3)
          TextButton(onPressed: () => setState(() => _all = true), child: Text(l.reviewsSeeAll(reviews.length))),
      ]),
    );
  }
}

/// Saisie de la réponse du répétiteur (500 caractères, comme le serveur).
class _ReplyForm extends StatefulWidget {
  final String initial;
  const _ReplyForm({required this.initial});

  @override
  State<_ReplyForm> createState() => _ReplyFormState();
}

class _ReplyFormState extends State<_ReplyForm> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.reviewsReplyPublic, style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.reviewsReplyHint),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          WinButton(l.reviewsReplySend,
              block: true,
              onTap: _ctrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _ctrl.text.trim())),
        ]);
  }
}
