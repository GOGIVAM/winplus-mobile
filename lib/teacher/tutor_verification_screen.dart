import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/tutor_verification_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

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
  return '${two(l.day)}/${two(l.month)}/${l.year} à ${two(l.hour)}:${two(l.minute)}';
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
      _toast('Fichier trop volumineux (8 Mo maximum).');
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
        _toast('Photo trop volumineuse (8 Mo maximum).');
        return null;
      }
      final name = shot.name.contains('.') ? shot.name : 'selfie.jpg';
      return IdentityUpload(bytes, name);
    } catch (_) {
      _toast("Appareil photo indisponible : choisis plutôt une photo de ton visage dans tes fichiers.");
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
      _toast('Ajoute au moins le recto de ta pièce et un selfie.');
      return;
    }
    await _run(
        () => TutorVerificationService.instance.submitIdentity(
            documentType: _docType, front: _front!, back: _back, selfie: _selfie!, interviewId: interviewId),
        "Documents envoyés. L'équipe WinPlus va les comparer.");
    if (mounted) setState(() { _front = null; _back = null; _selfie = null; });
  }

  Future<void> _requestInterview() async {
    await _run(
        () => TutorVerificationService.instance.requestInterview(
            format: _format,
            availability: _availabilityCtrl.text.trim(),
            city: _format == 'in_person' ? _cityCtrl.text.trim() : null,
            message: _messageCtrl.text.trim()),
        'Demande envoyée. Un agent WinPlus va te proposer une date.');
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
        title: Text('Vérification présentiel', style: WinType.headlineS(s.onStrong)),
      ),
      body: st == null
          ? Center(
              child: _loadError != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_loadError!, textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
                        const SizedBox(height: 12),
                        WinButton('Réessayer', onTap: _load),
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
                  Text('Historique', style: WinType.labelM(s.onStrong)),
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
        ? ('Présentiel suspendu', BadgeColor.error)
        : st.isVerified
            ? ('Vérifié pour le présentiel', BadgeColor.success)
            : ('En ligne uniquement', BadgeColor.neutral);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.verified_user_outlined, color: s.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('Présentiel', style: WinType.titleM(s.onStrong))),
          WinBadge(label, color: color),
        ]),
        const SizedBox(height: 8),
        Text(
            "Les séances chez l'élève, chez toi ou en lieu neutre sont réservées aux tuteurs vérifiés. "
            'Choisis une des trois voies : une seule suffit. Le diplôme reste un badge facultatif.',
            style: WinType.bodyS(s.onMuted)),
        if (st.isVerified && st.routes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Voie(s) validée(s) : ${st.routes.map((r) => kVerificationRouteLabels[r] ?? r).join(', ')}',
              style: WinType.labelS(s.onMuted)),
        ],
        if (st.isSuspended) ...[
          const SizedBox(height: 10),
          const WinAlert(
              "Suite à des signalements, tes séances présentielles sont suspendues le temps qu'un membre de l'équipe WinPlus examine la situation. Tes séances en ligne restent possibles.",
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
              child: Text(file == null ? label : '$label : ${file.fileName}',
                  style: WinType.labelM(file == null ? s.onMuted : s.onStrong), overflow: TextOverflow.ellipsis)),
          if (camera) ...[
            WinButton(file == null ? 'Prendre' : 'Reprendre',
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
          WinButton(file == null ? (camera ? 'Fichier' : 'Choisir') : 'Changer',
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
          decoration: const InputDecoration(labelText: 'Type de pièce', border: OutlineInputBorder()),
          items: kIdentityDocumentTypes.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: _busy ? null : (v) => setState(() => _docType = v ?? 'cni'),
        ),
        const SizedBox(height: 10),
        _fileRow(s, 'Recto de la pièce', _front, false, (f) => setState(() => _front = f)),
        _fileRow(s, 'Verso (si besoin)', _back, false, (f) => setState(() => _back = f)),
        _fileRow(s, 'Selfie (ton visage)', _selfie, true, (f) => setState(() => _selfie = f), camera: true),
        WinButton("Envoyer pour vérification",
            block: true,
            small: true,
            loading: _busy,
            icon: Icons.badge_outlined,
            onTap: _busy || _front == null || _selfie == null ? null : () => _submitIdentity(interviewId: interviewId)),
        const SizedBox(height: 6),
        Text(
            "Fichiers privés, vus seulement par l'équipe WinPlus, jamais affichés sur ton profil. "
            'Supprimés ${st.retentionDaysAfterApproval} jours après la validation (${st.retentionDaysAfterRejection} jours après un refus) ; seule la décision est conservée.',
            style: WinType.labelS(s.onFaint)),
      ]);

  Widget _identityCard(WinScheme s, TutorVerificationStatus st) {
    final id = st.latestIdentity;
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.badge_outlined, size: 18, color: s.onMuted),
          const SizedBox(width: 6),
          Expanded(child: Text("Pièce d'identité et selfie", style: WinType.titleM(s.onStrong))),
          if (st.hasApprovedIdentity) const WinBadge('Validée', color: BadgeColor.success),
        ]),
        const SizedBox(height: 6),
        Text('Un administrateur compare la photo de ta pièce et ton visage.', style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 10),
        if (st.hasApprovedIdentity)
          Text("Ta pièce d'identité est validée.", style: WinType.labelM(s.onMuted))
        else if (id?.status == 'pending')
          WinAlert('En cours de vérification depuis le ${_fmt(id!.submittedAt)}.', type: BadgeColor.warn)
        else ...[
          if (id?.status == 'rejected') ...[
            WinAlert('Refusée : ${id!.rejectionReason ?? ''}. Tu peux envoyer de nouveaux documents.', type: BadgeColor.error),
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
          Expanded(child: Text('Entretien avec un agent', style: WinType.titleM(s.onStrong))),
          if (it != null)
            WinBadge(kInterviewStatusLabels[it.status] ?? it.status,
                color: it.status == 'passed' ? BadgeColor.success : open ? BadgeColor.warn : BadgeColor.neutral),
        ]),
        const SizedBox(height: 6),
        Text("En visio ou en rencontre. L'entretien ne remplace pas l'identité : prépare ta pièce, elle est jointe au dossier avec un selfie.",
            style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 10),
        if (open) ...[
          if (it.status == 'scheduled')
            Text(
                'Prévu le ${_fmt(it.scheduledAt)}${it.meetingUrl != null ? '\nLien : ${it.meetingUrl}' : ''}${it.location != null ? '\nLieu : ${it.location}' : ''}',
                style: WinType.bodyM(s.onStrong))
          else
            Text('Demande envoyée le ${_fmt(it.requestedAt)}. Un agent va te proposer une date.', style: WinType.labelM(s.onMuted)),
          if (!it.hasIdentityAttached && !st.hasApprovedIdentity && st.latestIdentity?.status != 'pending') ...[
            const SizedBox(height: 10),
            Text("Joindre ma pièce et mon selfie à l'entretien", style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 6),
            _identityForm(s, st, interviewId: it.id),
          ],
          const SizedBox(height: 8),
          WinButton('Annuler la demande',
              small: true,
              variant: WinButtonVariant.ghost,
              onTap: _busy ? null : () => _run(() => TutorVerificationService.instance.cancelInterview(it.id), 'Demande annulée.')),
        ] else if (st.hasPassedInterview)
          Text(
              'Entretien réussi.${st.hasApprovedIdentity ? '' : " Il reste à valider ta pièce d'identité et ton selfie pour ouvrir le présentiel."}',
              style: WinType.labelM(s.onMuted))
        else ...[
          if (it?.outcomeReason != null) ...[
            WinAlert('Dernier entretien : ${it!.outcomeReason}', type: BadgeColor.neutral),
            const SizedBox(height: 8),
          ],
          Row(children: [
            for (final f in const [('video', 'Visio'), ('in_person', 'Rencontre')]) ...[
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
          WinTextField(label: 'Tes disponibilités', hint: 'Ex. : mardi et jeudi après 17 h', controller: _availabilityCtrl),
          if (_format == 'in_person') ...[
            const SizedBox(height: 8),
            WinTextField(label: 'Ville de la rencontre', hint: 'Douala, Yaoundé…', controller: _cityCtrl),
          ],
          const SizedBox(height: 8),
          WinTextField(label: 'Message (facultatif)', controller: _messageCtrl),
          const SizedBox(height: 10),
          WinButton('Demander un entretien',
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
          Expanded(child: Text('Caution de ton institution', style: WinType.titleM(s.onStrong))),
          if (active.any((e) => e.isValid)) const WinBadge('Active', color: BadgeColor.success),
        ]),
        const SizedBox(height: 6),
        Text(
            "Si tu es rattaché à un établissement sur WinPlus, il peut te cautionner après t'avoir vérifié par ses propres moyens. "
            'Si le rattachement ou la caution est retiré, cette voie tombe.',
            style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 8),
        if (active.isEmpty)
          Text('Aucune caution pour le moment. Demande à ton établissement de rattachement (Réseau) de te cautionner.',
              style: WinType.labelS(s.onFaint))
        else
          for (final e in active)
            Text('${e.institutionName ?? 'Établissement'} · vérifié par ${e.verifierName}${e.isValid ? '' : ' (rattachement inactif)'}',
                style: WinType.labelM(s.onStrong)),
        for (final e in revoked)
          Text('Caution de ${e.institutionName ?? ''} retirée le ${_fmt(e.revokedAt)}${e.revocationReason != null ? ' : ${e.revocationReason}' : ''}',
              style: WinType.labelS(WinColors.ink400)),
      ]),
    );
  }
}
