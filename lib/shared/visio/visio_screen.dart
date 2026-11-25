import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/visio_service.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/external_links.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';

/// Cours en direct sur la visio WinPlus (lot 9.4), comme la page
/// /visio/:type/:id du site : le serveur donne un jeton valable pour la
/// seule salle de la séance (GET /visio/jeton), puis la salle Jitsi
/// (visio.winplus.cm) s'ouvre. L'animateur (professeur, répétiteur) y entre
/// en modérateur.
///
/// La salle ouvre 30 minutes avant le début : avant, l'écran l'annonce et
/// y entre tout seul à l'heure. Après la fin (plus une heure de marge), il
/// dit que la séance est terminée.
class VisioScreen extends StatefulWidget {
  final VisioType type;
  final int id;

  /// Titre connu de l'écran appelant, affiché pendant le chargement.
  final String? title;

  const VisioScreen({super.key, required this.type, required this.id, this.title});

  /// Ouvre l'écran de la salle [type] / [id].
  static Future<void> open(BuildContext context, VisioType type, int id, {String? title}) =>
      Navigator.of(context).push(WinPageRoute(
          builder: (_) => VisioScreen(type: type, id: id, title: title)));

  /// Ouverture de la salle. Navigateur du téléphone : Chrome gère la caméra,
  /// le micro et le partage d'écran de Jitsi. Remplaçable dans les tests.
  static Future<bool> Function(ApiVisioAccess access) launcher =
      (access) => ExternalLinks.open(access.webUrl.toString());

  /// Signaux de présence (appel du professeur). Les tests qui ne portent
  /// pas dessus les coupent : le signal de départ part à la fermeture de
  /// l'écran, après la fin du test.
  static bool presenceEnabled = true;

  @override
  State<VisioScreen> createState() => _VisioScreenState();
}

enum _Etat { chargement, ouverte, refus, erreur }

class _VisioScreenState extends State<VisioScreen> {
  _Etat _etat = _Etat.chargement;
  ApiVisioAccess? _acces;
  VisioException? _refus;
  bool _horsLigne = false;
  bool _ouvertureRatee = false;
  Timer? _attente;

  // Appel du professeur (POST /visio/presence) : arrivée à l'ouverture de la
  // salle, signal chaque minute tant que cet écran reste ouvert, départ à sa
  // fermeture. La salle est dans Chrome : l'application ne voit pas quand la
  // personne quitte Jitsi ; le serveur la compte partie 3 min après le
  // dernier signal.
  int? _presenceId;
  Timer? _presenceTimer;
  bool _presenceStarted = false;
  VisioType? _presenceType;
  int? _presenceRef;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void didUpdateWidget(VisioScreen old) {
    super.didUpdateWidget(old);
    // Autre séance dans le même écran (lien reçu pendant qu'il est ouvert).
    if (old.type != widget.type || old.id != widget.id) {
      _stopPresence();
      _acces = null;
      _charger();
    }
  }

  @override
  void dispose() {
    _attente?.cancel();
    _stopPresence();
    super.dispose();
  }

  void _startPresence() {
    if (_presenceStarted || !VisioScreen.presenceEnabled) return;
    _presenceStarted = true;
    _presenceType = widget.type;
    _presenceRef = widget.id;
    _signal('arrivee');
    _presenceTimer = Timer.periodic(const Duration(minutes: 1), (_) => _signal('present'));
  }

  void _stopPresence() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    if (_presenceStarted) _signal('depart');
    _presenceStarted = false;
    _presenceId = null;
  }

  Future<void> _signal(String event) async {
    final type = _presenceType, ref = _presenceRef;
    if (type == null || ref == null) return;
    try {
      final id = await VisioService.instance
          .presence(type, ref, event, presenceId: _presenceId);
      if (event != 'depart' && id != null) _presenceId = id;
    } catch (e) {
      // Signal facultatif : l'appel du professeur peut manquer une minute,
      // la personne n'a rien à faire.
      debugPrint('Visio : signal de presence « $event » non envoye ($e)');
    }
  }

  Future<void> _charger() async {
    _attente?.cancel();
    setState(() {
      _etat = _Etat.chargement;
      _refus = null;
      _horsLigne = false;
    });
    try {
      final acces = await VisioService.instance.access(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _acces = acces;
        _etat = _Etat.ouverte;
      });
      await _ouvrir();
    } on VisioException catch (e) {
      if (!mounted) return;
      setState(() {
        _refus = e;
        _etat = _Etat.refus;
      });
      _programmerOuverture(e);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Pas de réponse du serveur : réseau coupé ou trop lent.
        _horsLigne = e is DioException && e.response == null;
        _etat = _Etat.erreur;
      });
    }
  }

  /// Salle pas encore ouverte : nouvel essai à l'heure d'ouverture (comme
  /// le site, qui entre tout seul si la page reste ouverte).
  void _programmerOuverture(VisioException e) {
    final heure = e.opensAt;
    if (e.reason != VisioRefusal.notYet || heure == null) return;
    final delai = heure.difference(DateTime.now()) + const Duration(seconds: 5);
    if (delai > const Duration(hours: 12)) return;
    _attente = Timer(delai.isNegative ? Duration.zero : delai, () {
      if (mounted) _charger();
    });
  }

  Future<void> _ouvrir() async {
    final acces = _acces;
    if (acces == null) return;
    final ok = await VisioScreen.launcher(acces);
    if (!mounted) return;
    setState(() => _ouvertureRatee = !ok);
    if (ok) _startPresence();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(l.visioTitle),
      ),
      body: SafeArea(child: _corps(s, l)),
    );
  }

  Widget _corps(WinScheme s, AppLocalizations l) {
    switch (_etat) {
      case _Etat.chargement:
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (widget.title != null) ...[
              Text(widget.title!,
                  textAlign: TextAlign.center, style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 6),
            ],
            Text(l.visioPreparing, style: WinType.bodyM(s.onMuted)),
          ]),
        );
      case _Etat.erreur:
        return WinErrorState(
            message: _horsLigne ? l.commonLoadError : l.visioError, onRetry: _charger);
      case _Etat.refus:
        return _refusVue(s, l, _refus!);
      case _Etat.ouverte:
        return _salleVue(s, l, _acces!);
    }
  }

  Widget _refusVue(WinScheme s, AppLocalizations l, VisioException e) {
    switch (e.reason) {
      case VisioRefusal.notYet:
        final h = e.opensAt;
        return WinEmptyState(
          icon: Icons.schedule,
          title: h == null
              ? l.visioError
              : l.visioNotYet(WinFormat.dateShort(h), WinFormat.time(h)),
          message: l.visioNotYetHint,
          actionLabel: l.commonRetry,
          onAction: _charger,
        );
      case VisioRefusal.ended:
        return WinEmptyState(icon: Icons.event_busy_outlined, title: l.visioEnded);
      case VisioRefusal.notFound:
        return WinEmptyState(icon: Icons.videocam_off_outlined, title: l.visioNotFound);
      case VisioRefusal.unavailable:
        return WinErrorState(message: l.visioUnavailable, onRetry: _charger);
    }
  }

  Widget _salleVue(WinScheme s, AppLocalizations l, ApiVisioAccess a) {
    final debut = a.start, fin = a.end;
    return ListView(padding: const EdgeInsets.all(20), children: [
      WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.videocam_outlined, color: s.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(a.title, style: WinType.titleL(s.onStrong))),
          ]),
          if (debut != null && fin != null) ...[
            const SizedBox(height: 6),
            Text(
                '${WinFormat.dateShort(debut)} · ${WinFormat.time(debut)} – ${WinFormat.time(fin)}',
                style: WinType.labelM(s.onMuted)),
          ],
          if (a.moderator) ...[
            const SizedBox(height: 10),
            WinBadge(l.visioHost, color: BadgeColor.teal),
          ],
        ]),
      ),
      const SizedBox(height: 16),
      Text(_ouvertureRatee ? l.commonLinkOpenError : l.visioOpenedHint,
          style: WinType.bodyM(_ouvertureRatee ? s.onStrong : s.onMuted)),
      const SizedBox(height: 16),
      WinButton(l.visioReopen,
          block: true, icon: Icons.videocam_outlined, onTap: _ouvrir),
      const SizedBox(height: 10),
      WinButton(l.visioLeave,
          block: true,
          variant: WinButtonVariant.outline,
          onTap: () => Navigator.of(context).maybePop()),
    ]);
  }
}
