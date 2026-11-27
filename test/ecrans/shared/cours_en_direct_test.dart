import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/data/models.dart' show WinRole;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/deep_links.dart';
import 'package:winplus/services/visio_service.dart';
import 'package:winplus/shared/visio/live_classes_screen.dart';
import 'package:winplus/shared/visio/live_session_screen.dart';
import 'package:winplus/shared/visio/visio_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 9.4 : « Cours en direct » (GET /visio/mes-cours), fiche d'une séance
/// partagée (/sessions/{id}), enregistrements et appel de présence.
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
    VisioScreen.presenceEnabled = false;
  });
  tearDown(() {
    VisioScreen.launcher = lanceurOrigine;
    VisioScreen.presenceEnabled = true;
  });

  String dans(Duration d) => DateTime.now().add(d).toUtc().toIso8601String();

  Map<String, dynamic> cours(int id, String titre,
          {String type = 'seance',
          String role = 'participant',
          String etat = 'a_venir',
          String? enfant,
          bool attente = false,
          int enregistrements = 0}) =>
      {
        'type': type, 'id': id, 'titre': titre, 'matiere': 'Maths',
        'debut': dans(const Duration(hours: 2)), 'fin': dans(const Duration(hours: 3)),
        'role': role, 'animateur': 'M. Ndi', 'enfant': enfant,
        'enAttentePaiement': attente, 'etat': etat, 'enregistrements': enregistrements,
      };

  Map<String, dynamic> jeton() => {
        'data': {'domaine': 'visio.winplus.cm', 'salle': 'winplus-seance-1', 'jeton': 'j', 'titre': 'T', 'nom': 'Zoe'},
      };

  group('LiveClassesScreen', () {
    testWidgets('sections, roles et actions : animateur demarre, eleve rejoint, parent consulte', (tester) async {
      faux.repond('GET', '/visio/mes-cours', {
        'success': true,
        'data': [
          cours(1, 'Cours ouvert', etat: 'ouverte', role: 'animateur'),
          cours(2, 'Tutorat a venir', type: 'tutorat'),
          cours(3, 'Cours de Leo', role: 'enfant', enfant: 'Leo Eto'),
          cours(4, 'Paiement en cours', attente: true),
          cours(5, 'Cours passe', etat: 'terminee', enregistrements: 2),
        ],
      });
      await monterEcran(tester, const LiveClassesScreen());
      final l = L10n.current;
      expect(find.text(l.liveSectionOpen), findsOneWidget);
      expect(find.text(l.liveSectionUpcoming), findsWidgets, reason: 'titre de section et badges');
      expect(find.text(l.visioStart), findsOneWidget, reason: 'cours 1, anime');
      expect(find.text(l.visioJoin), findsOneWidget, reason: 'seul le tutorat 2 : 3 parent, 4 paiement, 5 termine');
      expect(find.text(l.liveForChild('Leo Eto')), findsOneWidget);
      expect(find.text(l.liveChildReadOnly), findsOneWidget);
      expect(find.text(l.livePendingPayment), findsOneWidget);
      await tester.scrollUntilVisible(find.text(l.liveRecordingsCount(2)), 200);
      expect(find.text(l.liveRecordingsCount(2)), findsOneWidget);
      expect(find.text(l.liveSectionEnded), findsOneWidget);
    });

    testWidgets('rejoindre ouvre la salle du bon type', (tester) async {
      faux.repond('GET', '/visio/mes-cours', {'data': [cours(2, 'Tutorat', type: 'tutorat', etat: 'ouverte')]});
      faux.repond('GET', '/visio/jeton', jeton());
      await monterEcran(tester, const LiveClassesScreen());
      await tester.tap(find.text(L10n.current.visioJoin));
      await reseau(tester);
      final q = faux.recues('GET', '/visio/jeton').single.queryParameters;
      expect(q['type'], 'tutorat');
      expect(q['id'], 2);
      expect(ouvertes, hasLength(1));
    });

    testWidgets('aucun cours : message ; panne : erreur et Reessayer', (tester) async {
      final l = L10n.current;
      faux.repond('GET', '/visio/mes-cours', {'error': 'panne'}, statut: 500);
      await monterEcran(tester, const LiveClassesScreen());
      expect(find.text(l.commonLoadError), findsOneWidget);
      faux.repond('GET', '/visio/mes-cours', {'data': []});
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.liveEmpty), findsOneWidget);
    });

    testWidgets('enregistrements : liste avec taille et date', (tester) async {
      faux.repond('GET', '/visio/enregistrements', {
        'data': {
          'titre': 'Cours passe',
          'liste': [
            {'id': 1, 'fileName': 'seance-1.webm', 'sizeBytes': 52428800, 'createdAt': '2026-11-20T10:00:00Z', 'url': 'https://s3.example/x'},
          ],
        },
      });
      await monterEcran(tester, const VisioRecordingsScreen(type: VisioType.seance, id: 5, title: 'Cours passe'));
      expect(find.text('seance-1.webm'), findsOneWidget);
      expect(find.textContaining('50 Mo'), findsOneWidget);
      expect(faux.recues('GET', '/visio/enregistrements').single.queryParameters['id'], 5);
    });
  });

  group('LiveClassesScreen, lancer un cours (G6)', () {
    WinAppState etat(WinRole r) => WinAppState()..setRole(r);

    testWidgets('professeur : demarrer maintenant cree la seance et ouvre la salle', (tester) async {
      faux.repond('GET', '/visio/mes-cours', {'success': true, 'data': []});
      faux.repond('POST', '/sessions', {'success': true, 'data': {'id': 42, 'title': 'Revision'}});
      faux.repond('GET', '/visio/jeton', jeton());
      await monterEcran(tester, const LiveClassesScreen(), etat: etat(WinRole.teacher));
      final l = L10n.current;
      expect(find.text(l.liveEmptyHintHost), findsOneWidget);
      expect(find.text(l.livePlan), findsOneWidget);
      await tester.tap(find.text(l.liveStartNow));
      await pomper(tester);
      await tester.enterText(find.byType(TextField), 'Revision');
      await tester.tap(find.text(l.liveStartGo));
      await reseau(tester);
      final d = faux.recues('POST', '/sessions').single.data as Map;
      expect(d['title'], 'Revision');
      expect(d['type'], 'live');
      expect(d['durationMinutes'], 60);
      expect(faux.recues('GET', '/visio/jeton').single.queryParameters['id'], anyOf(42, '42'));
    });

    testWidgets('eleve : ni demarrer ni planifier, texte tutoye ; parent : vouvoye', (tester) async {
      faux.repond('GET', '/visio/mes-cours', {'success': true, 'data': []});
      await monterEcran(tester, const LiveClassesScreen(), etat: etat(WinRole.student));
      final l = L10n.current;
      expect(find.text(l.liveStartNow), findsNothing);
      expect(find.text(l.liveEmptyHint), findsOneWidget);
      await monterEcran(tester, const LiveClassesScreen(), etat: etat(WinRole.parent));
      expect(find.text(l.liveEmptyHintFormal), findsOneWidget);
    });
  });

  group('LiveSessionScreen', () {
    Map<String, dynamic> fiche({String monRole = 'aucun', bool gratuit = true, int? places = 4, String etat = 'a_venir'}) => {
          'success': true,
          'data': {
            'id': 9, 'titre': 'Revision BAC', 'description': 'Derivees', 'matiere': 'Maths', 'niveau': 'Terminale',
            'debut': dans(const Duration(days: 1)), 'fin': dans(const Duration(days: 1, hours: 1)),
            'gratuit': gratuit, 'prixXaf': gratuit ? null : 1500, 'placesRestantes': places,
            'annulee': false, 'professeur': {'nom': 'M. Ndi'}, 'monRole': monRole, 'etat': etat,
          },
        };

    testWidgets('seance gratuite : inscription puis « inscrit » et Rejoindre', (tester) async {
      faux.repond('GET', '/visio/seance/9', fiche());
      faux.repond('POST', '/sessions/9/enroll', {'success': true});
      await monterEcran(tester, const LiveSessionScreen(id: 9));
      final l = L10n.current;
      expect(find.text('Revision BAC'), findsOneWidget);
      expect(find.text(l.liveSessionBy('M. Ndi')), findsOneWidget);
      expect(find.text(l.liveSessionPlaces(4)), findsOneWidget);
      faux.repond('GET', '/visio/seance/9', fiche(monRole: 'inscrit'));
      await tester.tap(find.text(l.liveSessionEnroll));
      await reseau(tester);
      expect(faux.recues('POST', '/sessions/9/enroll'), hasLength(1));
      expect(find.text(l.liveSessionEnrolled), findsOneWidget);
      expect(find.text(l.visioJoin), findsOneWidget);
    });

    testWidgets('seance payante : numero exige, puis envoye ; paiement en attente', (tester) async {
      faux.repond('GET', '/visio/seance/9', fiche(gratuit: false));
      faux.repond('POST', '/sessions/9/enroll', {'success': true});
      await monterEcran(tester, const LiveSessionScreen(id: 9));
      final l = L10n.current;
      await tester.tap(find.text(l.liveSessionPay));
      await reseau(tester);
      expect(find.text(l.liveSessionPhoneRequired), findsOneWidget);
      expect(faux.recues('POST', '/sessions/9/enroll'), isEmpty);
      await tester.enterText(find.byType(TextField), '677000000');
      faux.repond('GET', '/visio/seance/9', fiche(gratuit: false, monRole: 'paiement_en_attente'));
      await tester.tap(find.text(l.liveSessionPay));
      await reseau(tester);
      expect((faux.recues('POST', '/sessions/9/enroll').single.data as Map)['phone'], '677000000');
      expect(find.text(l.liveSessionPendingPayment), findsOneWidget);
    });

    testWidgets('refus du serveur : son message ; seance complete : bouton inactif', (tester) async {
      faux.repond('GET', '/visio/seance/9', fiche());
      faux.repond('POST', '/sessions/9/enroll', {'success': false, 'error': 'Cette session est complète.'}, statut: 400);
      await monterEcran(tester, const LiveSessionScreen(id: 9));
      await tester.tap(find.text(L10n.current.liveSessionEnroll));
      await reseau(tester);
      expect(find.text('Cette session est complète.'), findsOneWidget);

      faux.repond('GET', '/visio/seance/10', {...fiche(places: 0), 'data': {...fiche(places: 0)['data'] as Map, 'id': 10}});
      await monterEcran(tester, const LiveSessionScreen(id: 10));
      expect(find.text(L10n.current.liveSessionPlaces(0)), findsOneWidget);
    });

    testWidgets('seance introuvable : message', (tester) async {
      faux.repond('GET', '/visio/seance/9', {'success': false}, statut: 404);
      await monterEcran(tester, const LiveSessionScreen(id: 9));
      expect(find.text(L10n.current.visioNotFound), findsOneWidget);
    });
  });

  group('Presence', () {
    testWidgets('arrivee a l\'ouverture, present chaque minute avec le meme passage, depart en quittant', (tester) async {
      VisioScreen.presenceEnabled = true;
      faux.repond('GET', '/visio/jeton', jeton());
      faux.repond('POST', '/visio/presence', {'success': true, 'data': {'presenceId': 42}});
      await monterEcran(tester, const VisioScreen(type: VisioType.seance, id: 1));
      List<Map> signaux() => faux.recues('POST', '/visio/presence').map((o) => o.data as Map).toList();
      expect(signaux().single['evenement'], 'arrivee');
      expect(signaux().single.containsKey('presenceId'), isFalse);
      await tester.pump(const Duration(minutes: 1));
      await reseau(tester);
      expect(signaux().last['evenement'], 'present');
      expect(signaux().last['presenceId'], 42);
      await tester.pumpWidget(const SizedBox());
      await reseau(tester);
      expect(signaux().last['evenement'], 'depart');
      expect(signaux().last['presenceId'], 42);
    });
  });

  test('lien /sessions/{id} : fiche de la seance', () {
    final page = DeepLinks.pageFor(Uri.parse('https://winplus.cm/sessions/9'));
    expect(page, isA<LiveSessionScreen>());
    expect((page! as LiveSessionScreen).id, 9);
    expect(DeepLinks.pageFor(Uri.parse('https://winplus.cm/sessions/abc')), isNull);
  });
}
