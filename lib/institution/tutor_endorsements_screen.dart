import 'package:flutter/material.dart';

import '../services/tutor_verification_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Lot 9.5 (17.11) : l'institution cautionne un répétiteur qui lui est
/// rattaché, après l'avoir vérifié par ses propres moyens (comment, par qui,
/// quand), et peut retirer la caution. Le rattachement lui-même se gère sur
/// le web (Réseau) ; le retirer retire aussi la caution.
class TutorEndorsementsScreen extends StatefulWidget {
  const TutorEndorsementsScreen({super.key});

  @override
  State<TutorEndorsementsScreen> createState() => _TutorEndorsementsScreenState();
}

class _TutorEndorsementsScreenState extends State<TutorEndorsementsScreen> {
  List<InstitutionTutorForEndorsement>? _tutors;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final t = await TutorVerificationService.instance.institutionTutors();
      if (mounted) setState(() => _tutors = t.where((x) => x.hasTutorProfile).toList());
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _endorse(InstitutionTutorForEndorsement t) async {
    final statement = TextEditingController();
    final verifier = TextEditingController();
    DateTime verifiedOn = DateTime.now();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        final s = WinTheme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ctx.l10n.instEndorseTitle(t.tutorName ?? ctx.l10n.instEndorseThisTutor), style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 6),
              Text(ctx.l10n.instEndorseSheetInfo,
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 12),
              TextField(
                controller: statement,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                    labelText: ctx.l10n.instEndorseHowLabel,
                    hintText: ctx.l10n.instEndorseHowHint,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: verifier,
                maxLength: 150,
                decoration: InputDecoration(labelText: ctx.l10n.instEndorseVerifierLabel, border: const OutlineInputBorder()),
              ),
              Row(children: [
                Expanded(
                    child: Text(
                        ctx.l10n.instEndorseOnDate('${verifiedOn.day.toString().padLeft(2, '0')}/${verifiedOn.month.toString().padLeft(2, '0')}/${verifiedOn.year}'),
                        style: WinType.bodyM(s.onStrong))),
                WinButton(ctx.l10n.instEndorseChangeDate, small: true, variant: WinButtonVariant.outline, onTap: () async {
                  final d = await showDatePicker(
                      context: ctx, initialDate: verifiedOn, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (d != null) setSheet(() => verifiedOn = d);
                }),
              ]),
              const SizedBox(height: 12),
              WinButton(ctx.l10n.instEndorseConfirm, block: true, onTap: () => Navigator.pop(ctx, true)),
            ]),
          ),
        );
      }),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await TutorVerificationService.instance.endorse(
          tutorUserId: t.tutorUserId, statement: statement.text.trim(), verifierName: verifier.text.trim(), verifiedOn: verifiedOn);
      _toast(L10n.current.instEndorseSaved);
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(InstitutionTutorForEndorsement t) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.instEndorseRevokeTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(ctx.l10n.instEndorseRevokeText),
          const SizedBox(height: 8),
          TextField(controller: reason, decoration: InputDecoration(labelText: ctx.l10n.instEndorseReasonLabel)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.instEndorseRevokeAction)),
        ],
      ),
    );
    if (ok != true || t.activeEndorsement == null) return;
    setState(() => _busy = true);
    try {
      await TutorVerificationService.instance.revokeEndorsement(t.activeEndorsement!.id, reason: reason.text.trim());
      _toast(L10n.current.instEndorseRevoked);
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final tutors = _tutors;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text(context.l10n.instEndorseScreenTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: tutors == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
                        const SizedBox(height: 12),
                        WinButton(context.l10n.commonRetry, onTap: _load),
                      ]))
                  : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
                Text(
                    context.l10n.instEndorseIntro,
                    style: WinType.bodyS(s.onMuted)),
                const SizedBox(height: 12),
                if (tutors.isEmpty)
                  Text(context.l10n.instEndorseEmpty, style: WinType.bodyM(s.onMuted)),
                for (final t in tutors) ...[
                  WinCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        WinAvatar(t.tutorName ?? '?', size: 36),
                        const SizedBox(width: 10),
                        Expanded(child: Text(t.tutorName ?? context.l10n.roleTutor, style: WinType.titleM(s.onStrong))),
                        if (t.activeEndorsement != null) WinBadge(context.l10n.instEndorseBadge, color: BadgeColor.success),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                          t.activeEndorsement != null
                              ? context.l10n.instEndorseVerifiedBy(t.activeEndorsement!.verifierName)
                              : t.isInPersonVerified
                                  ? context.l10n.instEndorseOtherRoute
                                  : context.l10n.instEndorseNotEndorsed,
                          style: WinType.labelM(s.onMuted)),
                      const SizedBox(height: 10),
                      t.activeEndorsement != null
                          ? WinButton(context.l10n.instEndorseRevoke,
                              small: true, variant: WinButtonVariant.outline, onTap: _busy ? null : () => _revoke(t))
                          : WinButton(context.l10n.instEndorseAction, small: true, onTap: _busy ? null : () => _endorse(t)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
              ]),
            ),
    );
  }
}
