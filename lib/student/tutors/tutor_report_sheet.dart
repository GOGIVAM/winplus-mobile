import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/tutor_verification_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Lot 9.5 (17.12, 17.16) : signaler le tuteur d'une séance (participants et
/// payeur, y compris pour une séance annulée ou en cours). Motif dans une
/// liste + description. Distinct de la contestation (remboursement).
/// Renvoie true si le signalement est parti.
Future<bool?> showTutorReportSheet(BuildContext context, {required int bookingId, String? tutorName}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TutorReportSheet(bookingId: bookingId, tutorName: tutorName),
  );
}

class _TutorReportSheet extends StatefulWidget {
  final int bookingId;
  final String? tutorName;
  const _TutorReportSheet({required this.bookingId, this.tutorName});

  @override
  State<_TutorReportSheet> createState() => _TutorReportSheetState();
}

class _TutorReportSheetState extends State<_TutorReportSheet> {
  List<TutorReportReason> _reasons = kFallbackReportReasons;
  String? _reason;
  final _descCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    TutorVerificationService.instance.reportReasons().then((r) {
      if (mounted) setState(() => _reasons = r);
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_reason == null) {
      setState(() => _error = context.l10n.tutoringReportChooseReason);
      return;
    }
    if (_reason == 'other' && _descCtrl.text.trim().length < 10) {
      setState(() => _error = context.l10n.tutoringReportDescribe);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final msg = await TutorVerificationService.instance
          .report(bookingId: widget.bookingId, reason: _reason!, description: _descCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: s.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.tutoringReportName(widget.tutorName ?? context.l10n.tutoringTheTutor), style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 6),
            Text(
                context.l10n.tutoringReportIntro,
                style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.tutoringReportReason, border: const OutlineInputBorder()),
              items: _reasons.map((r) => DropdownMenuItem(value: r.code, child: Text(r.label))).toList(),
              onChanged: _sending ? null : (v) => setState(() => _reason = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: _reason == 'other' ? context.l10n.commonDescription : context.l10n.tutoringReportDescriptionOptional,
                hintText: context.l10n.tutoringReportPlaceholder,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              WinAlert(_error!, type: BadgeColor.error),
            ],
            const SizedBox(height: 12),
            WinButton(context.l10n.tutoringReportSubmit,
                block: true, variant: WinButtonVariant.danger, loading: _sending, onTap: _sending ? null : _send),
          ]),
        ),
      ),
    );
  }
}
