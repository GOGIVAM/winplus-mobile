import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/tutor_verification_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Lot 9.5 (suivi 17.11, 17.16) : vérification du tuteur pour le présentiel.
/// Trois voies, une seule suffit :
///  1. pièce d'identité (recto, verso si besoin) + selfie, comparés par un admin ;
///  2. entretien en visio ou en rencontre (la pièce et un selfie sont joints
///     au dossier : l'entretien ne remplace pas l'identité) ;
///  3. caution de l'institution de rattachement.
/// Le diplôme reste un badge facultatif.
class TutorVerificationScreen extends StatefulWidget {
  const TutorVerificationScreen({super.key});

  @override
  State<TutorVerificationScreen> createState() => _TutorVerificationScreenState();
}

String _fmt(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return L10n.current.fmtDateAtTime('${two(l.day)}/${two(l.month)}/${l.year}', '${two(l.hour)}:${two(l.minute)}');
}

class _TutorVerificationScreenState extends State<TutorVerificationScreen> {
  TutorVerificationStatus? _status;
  String? _loadError;
  bool _busy = false;

  String _docType = 'cni';
  IdentityUpload? _front;
  IdentityUpload? _back;
  IdentityUpload? _selfie;

  String _format = 'video';
  final _availabilityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _availabilityCtrl.dispose();
    _cityCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final s = await TutorVerificationService.instance.getMine();
      if (mounted) setState(() => _status = s);
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<IdentityUpload?> _pick({required bool imageOnly}) async {
    final res = await FilePicker.platform.pickFiles(
      type: imageOnly ? FileType.image : FileType.custom,
      allowedExtensions: imageOnly ? null : ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final f = res?.files.firstOrNull;
    if (f == null || f.bytes == null) return null;
    if (f.size > 8 * 1024 * 1024) {
      _toast(L10n.current.teacherVerifFileTooBig);
      return null;
    }
    return IdentityUpload(f.bytes!, f.name);
  }

  /// Lot 9.5 (17.17) : selfie pris directement avec l'appareil photo (caméra
  /// frontale de préférence). Le choix d'un fichier reste possible en secours
  /// (appareil sans caméra, accès refusé, ordinateur).
  Future<IdentityUpload?> _takePhoto() async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (shot == null) return null;
      final bytes = await shot.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        _toast(L10n.current.teacherVerifPhotoTooBig);
        return null;
      }
      final name = shot.name.contains('.') ? shot.name : 'selfie.jpg';
      return IdentityUpload(bytes, name);
    } catch (_) {
      _toast(L10n.current.teacherVerifCameraUnavailable);
      return null;
    }
  }

  Future<void> _run(Future<TutorVerificationStatus> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      final s = await action();
      if (!mounted) return;
      setState(() => _status = s);
      _toast(ok);
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitIdentity({int? interviewId}) async {
    if (_front == null || _selfie == null) {
      _toast(L10n.current.teacherVerifNeedFiles);
      return;
    }
    await _run(
        () => TutorVerificationService.instance.submitIdentity(
            documentType: _docType, front: _front!, back: _back, selfie: _selfie!, interviewId: interviewId),
        L10n.current.teacherVerifSent);
    if (mounted) setState(() { _front = null; _back = null; _selfie = null; });
  }

  Future<void> _requestInterview() async {
    await _run(
        () => TutorVerificationService.instance.requestInterview(
            format: _format,
            availability: _availabilityCtrl.text.trim(),
            city: _format == 'in_person' ? _cityCtrl.text.trim() : null,
            message: _messageCtrl.text.trim()),
        L10n.current.teacherVerifRequested);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final st = _status;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text(context.l10n.teacherVerifTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: st == null
          ? Center(
              child: _loadError != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_loadError!, textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
                        const SizedBox(height: 12),
                        WinButton(context.l10n.commonRetry, onTap: _load),
                      ]))
                  : const CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                _header(s, st),
                const SizedBox(height: 14),
                _identityCard(s, st),
                const SizedBox(height: 12),
                _interviewCard(s, st),
                const SizedBox(height: 12),
                _institutionCard(s, st),
                if (st.history.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(context.l10n.teacherVerifHistory, style: WinType.labelM(s.onStrong)),
                  const SizedBox(height: 6),
                  for (final h in st.history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${_fmt(h.createdAt)} · ${h.label}${h.reason != null ? ' · ${h.reason}' : ''}',
                          style: WinType.labelS(s.onMuted)),
                    ),
                ],
              ]),
            ),
    );
  }

  Widget _header(WinScheme s, TutorVerificationStatus st) {
    final (label, color) = st.isSuspended
        ? (context.l10n.teacherVerifSuspended, BadgeColor.error)
        : st.isVerified
            ? (context.l10n.tutoringInPersonVerified, BadgeColor.success)
            : (context.l10n.tutoringOnlineOnly, BadgeColor.neutral);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.verified_user_outlined, color: s.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.teacherPricingInPerson, style: WinType.titleM(s.onStrong))),
          WinBadge(label, color: color),
        ]),
        const SizedBox(height: 8),
        Text(
            context.l10n.teacherVerifIntro,
            style: WinType.bodyS(s.onMuted)),
        if (st.isVerified && st.routes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(context.l10n.teacherVerifRoutesValidated(st.routes.map((r) => kVerificationRouteLabels[r] ?? r).join(', ')),
              style: WinType.labelS(s.onMuted)),
        ],
        if (st.isSuspended) ...[
          const SizedBox(height: 10),
          WinAlert(
              context.l10n.teacherVerifSuspendedBanner,
              type: BadgeColor.error),
        ],
      ]),
    );
  }

  Widget _fileRow(WinScheme s, String label, IdentityUpload? file, bool imageOnly, ValueChanged<IdentityUpload?> set,
          {bool camera = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
              child: Text(file == null ? label : context.l10n.teacherVerifFileLine(label, file.fileName),
                  style: WinType.labelM(file == null ? s.onMuted : s.onStrong), overflow: TextOverflow.ellipsis)),
          if (camera) ...[
            WinButton(file == null ? context.l10n.teacherVerifTake : context.l10n.teacherVerifRetake,
                small: true,
                icon: Icons.photo_camera_outlined,
                onTap: _busy
                    ? null
                    : () async {
                        final shot = await _takePhoto();
                        if (shot != null) set(shot);
                      }),
            const SizedBox(width: 6),
          ],
          WinButton(file == null ? (camera ? context.l10n.teacherVerifFile : context.l10n.teacherVerifChoose) : context.l10n.studentProfileChange,
              small: true,
              variant: WinButtonVariant.outline,
              icon: Icons.upload_file_outlined,
              onTap: _busy ? null : () async => set(await _pick(imageOnly: imageOnly))),
        ]),
      );

  Widget _identityForm(WinScheme s, TutorVerificationStatus st, {int? interviewId}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(
          initialValue: _docType,
          decoration: InputDecoration(labelText: context.l10n.teacherVerifDocType, border: const OutlineInputBorder()),
          items: kIdentityDocumentTypes.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: _busy ? null : (v) => setState(() => _docType = v ?? 'cni'),
        ),
        const SizedBox(height: 10),
        _fileRow(s, context.l10n.teacherVerifFront, _front, false, (f) => setState(() => _front = f)),
        _fileRow(s, context.l10n.teacherVerifBack, _back, false, (f) => setState(() => _back = f)),
        _fileRow(s, context.l10n.teacherVerifSelfie, _selfie, true, (f) => setState(() => _selfie = f), camera: true),
        WinButton(context.l10n.teacherVerifSubmit,
            block: true,
            small: true,
            loading: _busy,
            icon: Icons.badge_outlined,
            onTap: _busy || _front == null || _selfie == null ? null : () => _submitIdentity(interviewId: interviewId)),
        const SizedBox(height: 6),
        Text(
            context.l10n.teacherVerifRetention(st.retentionDaysAfterApproval, st.retentionDaysAfterRejection),
            style: WinType.labelS(s.onFaint)),
      ]);

  Widget _identityCard(WinScheme s, TutorVerificationStatus st) {
    final id = st.latestIdentity;
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: s.onMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(context.l10n.teacherVerifIdentityTitle, style: WinType.titleM(s.onStrong))),
          if (st.hasApprovedIdentity) WinBadge(context.l10n.teacherVerifValidated, color: BadgeColor.success),
        ]),
        const SizedBox(height: 6),
        Text(context.l10n.teacherVerifIdentityText, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 10),
        if (st.hasApprovedIdentity)
          Text(context.l10n.teacherVerifIdentityOk, style: WinType.labelM(s.onMuted))
        else if (id?.status == 'pending')
          WinAlert(context.l10n.teacherVerifPendingSince(_fmt(id!.submittedAt)), type: BadgeColor.warn)
        else ...[
          if (id?.status == 'rejected') ...[
            WinAlert(context.l10n.teacherVerifRejected(id!.rejectionReason ?? ''), type: BadgeColor.error),
            const SizedBox(height: 10),
          ],
          _identityForm(s, st),
        ],
      ]),
    );
  }

  Widget _interviewCard(WinScheme s, TutorVerificationStatus st) {
    final it = st.latestInterview;
    final open = it != null && it.isOpen;
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.video_call_outlined, size: 18, color: s.onMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(context.l10n.teacherVerifInterviewTitle, style: WinType.titleM(s.onStrong))),
          if (it != null)
            WinBadge(kInterviewStatusLabels[it.status] ?? it.status,
                color: it.status == 'passed' ? BadgeColor.success : open ? BadgeColor.warn : BadgeColor.neutral),
        ]),
        const SizedBox(height: 6),
        Text(context.l10n.teacherVerifInterviewText,
            style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 10),
        if (open) ...[
          if (it.status == 'scheduled')
            Text(
                '${context.l10n.teacherVerifScheduledOn(_fmt(it.scheduledAt))}${it.meetingUrl != null ? '\n${context.l10n.teacherVerifLink(it.meetingUrl!)}' : ''}${it.location != null ? '\n${context.l10n.teacherVerifPlace(it.location!)}' : ''}',
                style: WinType.bodyM(s.onStrong))
          else
            Text(context.l10n.teacherVerifRequestedOn(_fmt(it.requestedAt)), style: WinType.labelM(s.onMuted)),
          if (!it.hasIdentityAttached && !st.hasApprovedIdentity && st.latestIdentity?.status != 'pending') ...[
            const SizedBox(height: 10),
            Text(context.l10n.teacherVerifAttach, style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 6),
            _identityForm(s, st, interviewId: it.id),
          ],
          const SizedBox(height: 8),
          WinButton(context.l10n.teacherVerifCancelRequest,
              small: true,
              variant: WinButtonVariant.ghost,
              onTap: _busy ? null : () => _run(() => TutorVerificationService.instance.cancelInterview(it.id), context.l10n.teacherVerifCancelled)),
        ] else if (st.hasPassedInterview)
          Text(
              '${context.l10n.teacherVerifPassed}${st.hasApprovedIdentity ? '' : ' ${context.l10n.teacherVerifPassedNeedIdentity}'}',
              style: WinType.labelM(s.onMuted))
        else ...[
          if (it?.outcomeReason != null) ...[
            WinAlert(context.l10n.teacherVerifLastInterview(it!.outcomeReason!), type: BadgeColor.neutral),
            const SizedBox(height: 8),
          ],
          Row(children: [
            for (final f in [('video', context.l10n.teacherVerifVideo), ('in_person', context.l10n.teacherVerifMeeting)]) ...[
              Expanded(
                child: WinButton(f.$2,
                    small: true,
                    variant: _format == f.$1 ? WinButtonVariant.primary : WinButtonVariant.outline,
                    onTap: () => setState(() => _format = f.$1)),
              ),
              const SizedBox(width: 8),
            ],
          ]),
          const SizedBox(height: 10),
          WinTextField(label: context.l10n.teacherVerifAvailability, hint: context.l10n.teacherVerifAvailabilityHint, controller: _availabilityCtrl),
          if (_format == 'in_person') ...[
            const SizedBox(height: 8),
            WinTextField(label: context.l10n.teacherVerifMeetingCity, hint: context.l10n.teacherVerifCityHint, controller: _cityCtrl),
          ],
          const SizedBox(height: 8),
          WinTextField(label: context.l10n.teacherVerifMessage, controller: _messageCtrl),
          const SizedBox(height: 10),
          WinButton(context.l10n.teacherVerifRequestInterview,
              block: true, small: true, loading: _busy, icon: Icons.event_available_outlined, onTap: _busy ? null : _requestInterview),
        ],
      ]),
    );
  }

  Widget _institutionCard(WinScheme s, TutorVerificationStatus st) {
    final active = st.endorsements.where((e) => e.status == 'active').toList();
    final revoked = st.endorsements.where((e) => e.status == 'revoked').take(3).toList();
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.apartment_outlined, size: 18, color: s.onMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(context.l10n.teacherVerifInstitutionTitle, style: WinType.titleM(s.onStrong))),
          if (active.any((e) => e.isValid)) WinBadge(context.l10n.teacherVerifActive, color: BadgeColor.success),
        ]),
        const SizedBox(height: 6),
        Text(
            context.l10n.teacherVerifInstitutionText,
            style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Text(context.l10n.teacherVerifNoEndorsement,
              style: WinType.labelS(s.onFaint))
        else
          for (final e in active)
            Text('${e.institutionName ?? context.l10n.roleInstitution} · ${context.l10n.teacherVerifVerifiedBy(e.verifierName)}${e.isValid ? '' : ' ${context.l10n.teacherVerifInactiveLink}'}',
                style: WinType.labelM(s.onStrong)),
        for (final e in revoked)
          Text('${context.l10n.teacherVerifRevoked(e.institutionName ?? '', _fmt(e.revokedAt))}${e.revocationReason != null ? context.l10n.teacherVerifReasonSuffix(e.revocationReason!) : ''}',
              style: WinType.labelS(WinColors.ink400)),
      ]),
    );
  }
}
