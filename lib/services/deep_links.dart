import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';

import '../auth/reset_password_screen.dart';
import '../shared/visio/live_session_screen.dart';
import '../shared/visio/visio_screen.dart';
import 'visio_service.dart';
import '../theme/win_motion.dart';

/// Liens du site ouverts dans l'application (lot 2, App Links Android).
///
/// Un lien https://winplus.cm/... déclaré dans AndroidManifest.xml (et
/// vérifié par le fichier .well-known/assetlinks.json du site) ouvre
/// l'application au lieu du navigateur. Seuls les liens qui ont un écran
/// mobile sont pris en charge :
/// - /reset-password/{jeton} : lien de l'e-mail « mot de passe oublié ».
/// - /visio/{seance|tutorat}/{id} : salle d'un cours en direct.
/// - /sessions/{id} : fiche d'une séance en direct (lien partagé par le
///   professeur) : inscription, puis entrée dans la salle.
///
/// Un lien reçu au lancement attend que l'écran de démarrage ait fini son
/// routage ([ready]), sinon son remplacement effacerait la page ouverte.
class DeepLinks {
  DeepLinks._();
  static final DeepLinks instance = DeepLinks._();

  GlobalKey<NavigatorState>? _navigator;
  StreamSubscription<Uri>? _abonnement;
  bool _pret = false;
  Uri? _enAttente;
  Uri? _dernier;
  DateTime? _dernierA;

  /// Hôtes du site dont les liens sont acceptés.
  static const _hotes = {'winplus.cm', 'www.winplus.cm', 'integration.winplus.cm'};

  void start(GlobalKey<NavigatorState> navigator) {
    _navigator = navigator;
    _abonnement ??= AppLinks().uriLinkStream.listen(_recevoir, onError: (_) {});
  }

  /// Appelé par l'écran de démarrage une fois la première page ouverte.
  void ready() {
    _pret = true;
    final lien = _enAttente;
    _enAttente = null;
    if (lien != null) _ouvrir(lien);
  }

  void _recevoir(Uri lien) {
    // Le même lien peut arriver deux fois (lien initial et flux) : un seul
    // traitement.
    final now = DateTime.now();
    if (lien == _dernier && _dernierA != null && now.difference(_dernierA!) < const Duration(seconds: 3)) {
      return;
    }
    _dernier = lien;
    _dernierA = now;
    if (!_pret) {
      _enAttente = lien;
      return;
    }
    _ouvrir(lien);
  }

  /// Page à ouvrir pour [lien], ou `null` si l'application ne le gère pas.
  static Widget? pageFor(Uri lien) {
    if (!_hotes.contains(lien.host)) return null;
    final s = lien.pathSegments.where((e) => e.isNotEmpty).toList();
    if (s.length == 2 && s[0] == 'reset-password') {
      return ResetPasswordScreen(token: s[1]);
    }
    if (s.length == 3 && s[0] == 'visio') {
      final type = visioTypeFrom(s[1]);
      final id = int.tryParse(s[2]);
      if (type != null && id != null) return VisioScreen(type: type, id: id);
    }
    if (s.length == 2 && s[0] == 'sessions') {
      final id = int.tryParse(s[1]);
      if (id != null) return LiveSessionScreen(id: id);
    }
    return null;
  }

  void _ouvrir(Uri lien) {
    final page = pageFor(lien);
    final nav = _navigator?.currentState;
    if (page == null || nav == null) return;
    nav.push(WinPageRoute(builder: (_) => page));
  }
}
