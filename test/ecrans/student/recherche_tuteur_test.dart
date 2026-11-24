import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/tutors/tutor_public_profile_screen.dart';
import 'package:winplus/student/tutors/tutor_search_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);
Finder _puce(String libelle) => find.widgetWithText(WinChip, libelle);

/// Les puces de filtre sont dans des rangees qui defilent a l'horizontale :
/// fait defiler chaque rangee jusqu'a trouver la puce, puis la touche.
Future<void> _toucher(WidgetTester tester, Finder puce) async {
  final rangees = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right);
  for (var i = 0; puce.evaluate().isEmpty && i < rangees.evaluate().length; i++) {
    for (final pas in const [80.0, -80.0]) {
      if (puce.evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(puce, pas, scrollable: rangees.at(i), maxScrolls: 25);
      } on StateError {
        // Pas dans ce sens ni dans cette rangee : on essaie la suite.
      }
    }
  }
  await tester.ensureVisible(puce);
  await pomper(tester);
  await tester.tap(puce);
}

Map<String, dynamic> _tuteur([Map<String, dynamic> en = const {}]) => {
      'userId': 21,
      'fullName': 'Mme Ngo',
      'title': 'Professeure agregee',
      'hourlyRateXaf': 800,
      'subjects': ['Mathematiques'],
      'levels': ['Terminale'],
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'student'}));

  void routes(List<Map<String, dynamic>> tuteurs, {List<Map<String, dynamic>> attributions = const []}) {
    faux.repond('GET', '/tutor-profile/search', tuteurs);
    faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'student', 'activeAssignments': attributions});
  }

  Map<String, dynamic> derniere() => faux.recues('GET', '/tutor-profile/search').last.queryParameters;

  testWidgets('chargement puis cartes : nom, titre, tarif horaire, matieres', (tester) async {
    routes([_tuteur()]);
    telephone(tester);
    await monter(tester, ecran(const TutorSearchScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    expect(find.text('Mme Ngo'), findsOneWidget);
    expect(find.text('Professeure agregee'), findsOneWidget);
    expect(find.text('800 XAF/h'), findsOneWidget);
    expect(find.text('Mathematiques'), findsOneWidget);
    // Sans filtre : 30 resultats par page et aucun critere envoye.
    final q = derniere();
    expect(q['pageSize'], 30);
    expect(q['page'], 1);
    for (final cle in ['subject', 'level', 'verifiedOnly', 'mode', 'city', 'availableSoon', 'topics']) {
      expect(q.containsKey(cle), isFalse, reason: cle);
    }
  });

  testWidgets('tarif « des » si la grille propose un prix plus bas que le tarif de base', (tester) async {
    routes([_tuteur({'fromHourlyRateXaf': 500})]);
    await monterEcran(tester, const TutorSearchScreen());
    expect(find.text(L10n.current.tutoringRateFrom('500')), findsOneWidget);
    expect(find.text('800 XAF/h'), findsNothing);
  });

  testWidgets('sans tarif : « Tarif ND »', (tester) async {
    routes([_tuteur({'hourlyRateXaf': null})]);
    await monterEcran(tester, const TutorSearchScreen());
    expect(find.text(L10n.current.tutoringRateNa), findsOneWidget);
  });

  testWidgets('une carte ne montre que trois matieres', (tester) async {
    routes([_tuteur({'subjects': ['Maths', 'Physique', 'Chimie', 'SVT']})]);
    await monterEcran(tester, const TutorSearchScreen());
    // On regarde la carte du tuteur seule : la rangee de filtres peut aussi
    // montrer une puce « Chimie » ou « SVT ».
    final carte = find.ancestor(of: find.text('Mme Ngo'), matching: find.byType(WinCard)).first;
    Finder dans(String t) => find.descendant(of: carte, matching: find.text(t));
    expect(dans('Maths'), findsOneWidget);
    expect(dans('Chimie'), findsOneWidget);
    expect(dans('SVT'), findsNothing);
  });

  testWidgets('modes : « Presentiel possible » avec diplome verifie et caution', (tester) async {
    routes([
      _tuteur({'offersInPerson': true, 'isDiplomaVerified': true, 'endorsedByInstitutions': ['Lycee Leclerc']}),
      _tuteur({'userId': 22, 'fullName': 'M. Eto', 'offersInPerson': false}),
    ]);
    await monterEcran(tester, const TutorSearchScreen());
    final l = L10n.current;
    expect(find.text('${l.tutoringInPersonPossible} · ${l.tutoringDiplomaVerified} · ${l.tutoringEndorsedBy('Lycee Leclerc')}'), findsOneWidget);
    expect(find.text(l.tutoringOnlineOnly), findsOneWidget);
  });

  testWidgets('sujets correspondants affiches sur la carte', (tester) async {
    routes([_tuteur({'matchedTopics': ['derivees']})]);
    await monterEcran(tester, const TutorSearchScreen());
    expect(find.text('derivees'), findsOneWidget);
  });

  testWidgets('aucun resultat : message dedie', (tester) async {
    routes([]);
    await monterEcran(tester, const TutorSearchScreen());
    expect(find.text(L10n.current.tutoringSearchEmpty), findsOneWidget);
  });

  testWidgets('erreur : message puis « Reessayer »', (tester) async {
    faux.repond('GET', '/tutor-profile/search', {}, statut: 500);
    await monterEcran(tester, const TutorSearchScreen());
    final l = L10n.current;
    expect(find.text(l.tutoringSearchLoadError), findsOneWidget);
    routes([_tuteur()]);
    await tester.tap(_bouton(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.tutoringSearchLoadError), findsNothing);
    expect(find.text('Mme Ngo'), findsOneWidget);
  });

  testWidgets('filtre matiere : envoye au serveur, un second appui le retire', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    final maths = _puce(L10n.current.dataSubjectMath);
    await tester.tap(maths);
    await reseau(tester);
    expect(derniere()['subject'], 'Mathématiques');
    expect(tester.widget<WinChip>(maths).active, isTrue);
    expect(tester.widget<WinChip>(_puce(L10n.current.tutoringAllSubjects)).active, isFalse);
    await tester.tap(maths);
    await reseau(tester);
    expect(derniere().containsKey('subject'), isFalse);
    expect(tester.widget<WinChip>(_puce(L10n.current.tutoringAllSubjects)).active, isTrue);
  });

  testWidgets('« Toutes matieres » efface la matiere choisie', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    await _toucher(tester, _puce(L10n.current.dataSubjectPhysics));
    await reseau(tester);
    expect(derniere()['subject'], 'Physique');
    await _toucher(tester, _puce(L10n.current.tutoringAllSubjects));
    await reseau(tester);
    expect(derniere().containsKey('subject'), isFalse);
  });

  testWidgets('diplome verifie, disponible bientot et mode en ligne : criteres envoyes', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    final l = L10n.current;
    await _toucher(tester, _puce(l.tutoringDiplomaVerified));
    await reseau(tester);
    expect(derniere()['verifiedOnly'], true);
    await _toucher(tester, _puce(l.tutoringAvailableSoon));
    await reseau(tester);
    expect(derniere()['availableSoon'], true);
    await _toucher(tester, _puce(l.commonOnline));
    await reseau(tester);
    final q = derniere();
    expect(q['mode'], 'online');
    expect(q['verifiedOnly'], true);
    // Rebasculer le diplome retire le critere (null, pas faux).
    await _toucher(tester, _puce(l.tutoringDiplomaVerified));
    await reseau(tester);
    expect(derniere().containsKey('verifiedOnly'), isFalse);
  });

  testWidgets('chaque changement de filtre relance la recherche', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    expect(faux.recues('GET', '/tutor-profile/search'), hasLength(1));
    await _toucher(tester, _puce(L10n.current.dataSubjectChemistry));
    await reseau(tester);
    await _toucher(tester, _puce(L10n.current.tutoringAvailableSoon));
    await reseau(tester);
    expect(faux.recues('GET', '/tutor-profile/search'), hasLength(3));
  });

  testWidgets('ville : la puce « Douala » s\'atteint en faisant defiler la ligne', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    await pomper(tester);
    await _toucher(tester, _puce('Douala'));
    await reseau(tester);
    expect(derniere()['city'], 'Douala');
  });

  testWidgets('sujets de seance : ajout par virgules, plafonnes, envoyes en un seul parametre', (tester) async {
    routes([_tuteur()]);
    await monterEcran(tester, const TutorSearchScreen());
    await tester.enterText(find.byType(TextField), 'derivees, limites');
    await tester.tap(find.byTooltip(L10n.current.tutoringAddTopic));
    await reseau(tester);
    expect(derniere()['topics'], 'derivees,limites');
    expect(find.widgetWithText(InputChip, 'derivees'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'limites'), findsOneWidget);
    // Un doublon (casse differente) n'est pas ajoute.
    await tester.enterText(find.byType(TextField), 'LIMITES');
    await tester.tap(find.byTooltip(L10n.current.tutoringAddTopic));
    await reseau(tester);
    expect(find.byType(InputChip), findsNWidgets(2));
    // Supprimer un sujet relance la recherche sans lui.
    await tester.tap(find.descendant(of: find.widgetWithText(InputChip, 'derivees'), matching: find.byType(Icon)));
    await reseau(tester);
    expect(derniere()['topics'], 'limites');
  });

  testWidgets('repetiteurs attribues : puces en tete et carte mise en avant, classee la premiere', (tester) async {
    routes([
      _tuteur({'userId': 21, 'fullName': 'Mme Ngo'}),
      _tuteur({'userId': 22, 'fullName': 'M. Eto'}),
    ], attributions: [
      {'id': 5, 'tutorUserId': 22, 'tutorName': 'M. Eto', 'assignerType': 'parent', 'status': 'active'},
      {'id': 6, 'tutorUserId': 21, 'tutorName': 'Mme Ngo', 'assignerType': 'parent', 'status': 'ended'},
    ]);
    await monterEcran(tester, const TutorSearchScreen());
    final l = L10n.current;
    expect(find.text(l.tutoringAssignedLabel), findsOneWidget);
    // Seule l'attribution active compte : une puce, une mention sur la carte.
    expect(find.widgetWithText(WinChip, 'M. Eto'), findsOneWidget);
    expect(find.text(l.tutoringAssignedTutor), findsOneWidget);
    expect(tester.getTopLeft(find.text('M. Eto').last).dy, lessThan(tester.getTopLeft(find.text('Mme Ngo')).dy));
  });

  testWidgets('contexte de reservation indisponible : la recherche fonctionne quand meme', (tester) async {
    faux.repond('GET', '/tutor-profile/search', [_tuteur()]);
    faux.repond('GET', '/tutor-assignments/booking-context', {}, statut: 500);
    await monterEcran(tester, const TutorSearchScreen());
    expect(find.text('Mme Ngo'), findsOneWidget);
    expect(find.text(L10n.current.tutoringAssignedLabel), findsNothing);
  });

  testWidgets('toucher une carte ouvre la fiche publique du tuteur', (tester) async {
    routes([_tuteur()]);
    faux.repond('GET', '/tutor-profile/21', {'id': 1, 'userId': 21, 'fullName': 'Mme Ngo'});
    faux.repond('GET', '/tutor-bookings/tutor/21/calendar', []);
    await monterEcran(tester, const TutorSearchScreen());
    await tester.tap(find.text('Mme Ngo'));
    await reseau(tester);
    final fiche = tester.widget<TutorPublicProfileScreen>(find.byType(TutorPublicProfileScreen));
    expect(fiche.userId, 21);
    expect(fiche.assignment, isNull);
  });
}
