import 'package:flutter/material.dart';

import '../../data/models.dart' show fmtXaf;
import '../../l10n/l10n.dart';
import '../../services/visio_service.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/external_links.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';
import 'visio_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Fiche d'une séance en direct (lot 9.4), ouverte par le lien partagé
/// winplus.cm/sessions/{id}, comme sur le site : titre, professeur, horaire,
/// prix et places, puis l'action qui correspond à la personne (s'inscrire,
/// payer, vérifier un paiement, entrer dans la salle).
class LiveSessionScreen extends StatefulWidget {
  final int id;
  const LiveSessionScreen({super.key, required this.id});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  ApiLiveSession? _session;
  bool _error = false;
  bool _notFound = false;
  bool _busy = false;
  String? _enrollError;
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LiveSessionScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _session = null;
      _enrollError = null;
      _load();
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = false;
      _notFound = false;
    });
    try {
      final s = await VisioService.instance.session(widget.id);
      if (mounted) setState(() => _session = s);
    } on VisioException {
      if (mounted) setState(() => _notFound = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _enroll(ApiLiveSession se) async {
    final l = context.l10n;
    final phone = _phone.text.trim();
    if (!se.free && phone.isEmpty) {
      setState(() => _enrollError = l.liveSessionPhoneRequired);
      return;
    }
    setState(() {
      _busy = true;
      _enrollError = null;
    });
    try {
      await VisioService.instance.enroll(se.id, phone: se.free ? null : phone);
      await _load();
    } on LiveEnrollException catch (e) {
      if (mounted) setState(() => _enrollError = e.message ?? l.liveSessionEnrollError);
    } catch (_) {
      if (mounted) setState(() => _enrollError = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final se = _session;
    Widget body;
    if (_notFound) {
      body = WinEmptyState(icon: PhosphorIconsRegular.videoCameraSlash, title: l.visioNotFound);
    } else if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (se == null) {
      body = const WinLoading();
    } else {
      body = ListView(padding: const EdgeInsets.all(20), children: [
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(se.title, style: WinType.headlineS(s.onStrong)),
            if (se.teacher != null) ...[
              const SizedBox(height: 4),
              Text(l.liveSessionBy(se.teacher!), style: WinType.bodyM(s.onMuted)),
            ],
            const SizedBox(height: 10),
            Text(
                '${WinFormat.dateShort(se.start)} · ${WinFormat.time(se.start)} – ${WinFormat.time(se.end)}',
                style: WinType.labelM(s.onStrong)),
            if ((se.subject ?? '').isNotEmpty || (se.level ?? '').isNotEmpty)
              Text([se.subject, se.level].whereType<String>().where((x) => x.isNotEmpty).join(' · '),
                  style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              WinBadge(se.free ? l.commonFree : l.liveSessionPrice(fmtXaf((se.priceXaf ?? 0).round())),
                  color: se.free ? BadgeColor.success : BadgeColor.blue),
              if (se.seatsLeft != null)
                WinBadge(l.liveSessionPlaces(se.seatsLeft!),
                    color: se.seatsLeft == 0 ? BadgeColor.error : BadgeColor.neutral),
            ]),
            if ((se.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(se.description!.trim(), style: WinType.bodyM(s.onStrong)),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        ..._actions(s, l, se),
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(l.liveSessionTitle),
      ),
      body: SafeArea(child: body),
    );
  }

  List<Widget> _actions(WinScheme s, AppLocalizations l, ApiLiveSession se) {
    if (se.cancelled || se.state == 'annulee') {
      return [WinAlert(l.liveSessionCancelled, type: BadgeColor.error)];
    }
    if (se.state == 'terminee') return [WinAlert(l.visioEnded, type: BadgeColor.neutral)];
    switch (se.myRole) {
      case 'animateur':
      case 'inscrit':
        return [
          if (se.myRole == 'inscrit') ...[
            WinAlert(l.liveSessionEnrolled, type: BadgeColor.success, icon: PhosphorIconsRegular.checkCircle),
            const SizedBox(height: 12),
          ],
          if (se.externalLink != null)
            WinButton(l.liveSessionExternal,
                block: true,
                icon: PhosphorIconsRegular.arrowSquareOut,
                onTap: () => ExternalLinks.open(se.externalLink!))
          else
            WinButton(se.myRole == 'animateur' ? l.visioStart : l.visioJoin,
                block: true,
                icon: PhosphorIconsRegular.videoCamera,
                onTap: () => VisioScreen.open(context, VisioType.seance, se.id, title: se.title)),
        ];
      case 'paiement_en_attente':
        return [
          WinAlert(l.liveSessionPendingPayment, icon: PhosphorIconsRegular.clock),
          const SizedBox(height: 12),
          WinButton(l.liveSessionCheckPayment,
              block: true, variant: WinButtonVariant.outline, onTap: _load),
        ];
      default:
        final full = se.seatsLeft == 0;
        return [
          if (!se.free && !full) ...[
            WinTextField(
              label: l.liveSessionPhone,
              hint: '6XXXXXXXX',
              icon: PhosphorIconsRegular.phone,
              keyboardType: TextInputType.phone,
              controller: _phone,
            ),
            const SizedBox(height: 12),
          ],
          if (_enrollError != null) ...[
            WinAlert(_enrollError!, type: BadgeColor.error),
            const SizedBox(height: 12),
          ],
          WinButton(se.free ? l.liveSessionEnroll : l.liveSessionPay,
              block: true,
              loading: _busy,
              onTap: full || _busy ? null : () => _enroll(se)),
        ];
    }
  }
}
