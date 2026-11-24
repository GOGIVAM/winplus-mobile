import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/visio_service.dart';
import 'package:winplus/shared/visio/visio_screen.dart';
import 'package:winplus/teacher/teacher_tabs.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 9.4 : cours en direct sur la visio WinPlus (GET /visio/jeton, puis
/// ouverture de la salle Jitsi), comme la page /visio/:type/:id du site.
void main() {
  late FauxReseau faux;
  late List<ApiVisioAccess> ouvertes;
  final lanceurOrigine = VisioScreen.launcher;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    ouvertes = [];
    VisioScreen.launcher = (a) async {
      ouvertes.add(a);
      return true;
    };
  });
  tearDown(() => VisioScreen.launcher = lanceurOrigine);

  Map<String, dynamic> jeton({bool moderateur = false}) => {
        'success': true,
        'data': {
          'domaine': 'visio.winplus.cm',
          'salle': 'winplus-seance-7',
          'jeton': 'a.b.c',
          'moderateur': moderateur,
          'titre': 'Revision derivees',
          'debut': '2026-11-24T10:00:00Z',
          'fin': '2026-11-24T11:00:00Z',
          'nom': 'Zoe Eto',
        },
      };

  group('VisioScreen', () {
    testWidgets('salle ouverte : jeton demande pour la bonne seance, salle ouverte avec le jeton', (tester) async {
      faux.repond('GET', '/visio/jeton', jeton(moderateur: true));
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 7));
      final q = faux.recues('GET', '/visio/jeton').single.queryParameters;
      expect(q['type'], 'seance');
      expect(q['id'], 7);
      expect(ouvertes, hasLength(1));
      final url = ouvertes.single.webUrl;
      expect(url.host, 'visio.winplus.cm');
      expect(url.path, '/winplus-seance-7');
      expect(url.queryParameters['jwt'], 'a.b.c');
      expect(url.fragment, contains('config.disableDeepLinking=true'));
      final l = L10n.current;
      expect(find.text('Revision derivees'), findsOneWidget);
      expect(find.text(l.visioHost), findsOneWidget, reason: 'le professeur anime');
      await tester.tap(find.text(l.visioReopen));
      await reseau(tester);
      expect(ouvertes, hasLength(2), reason: 'la salle peut etre rouverte');
    });

    testWidgets('participant : pas de badge « Tu animes »', (tester) async {
      faux.repond('GET', '/visio/jeton', jeton());
      await monterEcran(tester, const VisioScreen(type: VisioType.tutorat, id: 7));
      expect(faux.recues('GET', '/visio/jeton').single.queryParameters['type'], 'tutorat');
      expect(find.text(L10n.current.visioHost), findsNothing);
    });

    testWidgets('salle pas encore ouverte : heure d\'ouverture, aucune salle ouverte', (tester) async {
      final ouverture = DateTime.now().add(const Duration(days: 2));
      faux.repond('GET', '/visio/jeton',
          {'success': false, 'code': 'pas_encore', 'ouverture': ouverture.toUtc().toIso8601String()},
          statut: 409);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 7));
      final l = L10n.current;
      expect(find.text(l.visioNotYet(WinFormat.dateShort(ouverture), WinFormat.time(ouverture))), findsOneWidget);
      expect(find.text(l.visioNotYetHint), findsOneWidget);
      expect(ouvertes, isEmpty);
    });

    testWidgets('salle ouverte dans quelques minutes : l\'ecran y entre tout seul', (tester) async {
      final ouverture = DateTime.now().add(const Duration(minutes: 2));
      faux.repond('GET', '/visio/jeton',
          {'success': false, 'code': 'pas_encore', 'ouverture': ouverture.toUtc().toIso8601String()},
          statut: 409);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 7));
      expect(ouvertes, isEmpty);
      faux.repond('GET', '/visio/jeton', jeton());
      await tester.pump(const Duration(minutes: 3));
      await reseau(tester);
      expect(ouvertes, hasLength(1));
    });

    testWidgets('seance terminee, introuvable, visio desactivee : message du serveur traduit', (tester) async {
      final l = L10n.current;
      faux.repond('GET', '/visio/jeton', {'success': false, 'code': 'terminee'}, statut: 409);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 7));
      expect(find.text(l.visioEnded), findsOneWidget);

      faux.repond('GET', '/visio/jeton', {'success': false}, statut: 404);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 8));
      expect(find.text(l.visioNotFound), findsOneWidget);

      faux.repond('GET', '/visio/jeton', {'success': false}, statut: 503);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 9));
      expect(find.text(l.visioUnavailable), findsOneWidget);
      expect(ouvertes, isEmpty);
    });

    testWidgets('panne du serveur : erreur et Reessayer qui ouvre la salle', (tester) async {
      faux.repond('GET', '/visio/jeton', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 7));
      final l = L10n.current;
      expect(find.text(l.visioError), findsOneWidget);
      faux.repond('GET', '/visio/jeton', jeton());
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(ouvertes, hasLength(1));
    });
  });

  group('Seances du professeur', () {
    String dans(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

    testWidgets('seance en direct sans lien : « Demarrer la visio » ouvre la salle WinPlus', (tester) async {
      faux.repond('GET', '/sessions/mine', {
        'data': [
          {'id': 7, 'title': 'En direct', 'type': 'live', 'startDate': dans(const Duration(minutes: 20)), 'durationMinutes': 60, 'status': 'scheduled'},
          {'id': 8, 'title': 'Avec lien', 'type': 'live', 'startDate': dans(const Duration(days: 1)), 'durationMinutes': 60, 'status': 'scheduled', 'externalLink': 'https://meet.example/x'},
          {'id': 9, 'title': 'Enregistrement', 'type': 'recording', 'startDate': dans(const Duration(days: 2)), 'durationMinutes': 60, 'status': 'scheduled'},
          {'id': 10, 'title': 'Annulee', 'type': 'live', 'startDate': dans(const Duration(days: 3)), 'durationMinutes': 60, 'status': 'cancelled'},
        ],
      });
      faux.repond('GET', '/visio/jeton', jeton(moderateur: true));
      await monterEcran(tester, const Scaffold(body: TeacherSessionsTab()));
      final l = L10n.current;
      expect(find.text(l.visioStart), findsOneWidget,
          reason: 'ni la seance avec lien externe, ni l\'enregistrement, ni la seance annulee');
      expect(find.text(l.teacherSessionsJoin), findsOneWidget);
      await tester.tap(find.text(l.visioStart));
      await reseau(tester);
      expect(faux.recues('GET', '/visio/jeton').single.queryParameters['id'], 7);
      expect(ouvertes, hasLength(1));
    });
  });
}
