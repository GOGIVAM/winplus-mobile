import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/institution/announcements_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/announcements_feed.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : annonces d'établissement (envoi par l'établissement, réception par
/// l'élève et le parent), comme le site.
void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());

  Map<String, dynamic> recue(int id, String titre, {String type = 'info'}) => {
        'id': id, 'title': titre, 'content': 'Contenu $id', 'type': type,
        'createdAt': '2026-11-24T08:00:00Z', 'institutionName': 'Lycee Leclerc', 'groupName': null,
      };

  group('Reception', () {
    testWidgets('flux : titre, contenu, etablissement, pastille urgente', (tester) async {
      faux.repond('GET', '/institution/announcements/feed', {'data': [recue(1, 'Reunion parents', type: 'urgent'), recue(2, 'Sortie')]});
      await monterEcran(tester, const AnnouncementsFeedScreen());
      final l = L10n.current;
      expect(find.text('Reunion parents'), findsOneWidget);
      expect(find.text('Contenu 1'), findsOneWidget);
      expect(find.textContaining('Lycee Leclerc'), findsNWidgets(2));
      expect(find.text(l.annTypeUrgent), findsOneWidget);
    });

    testWidgets('flux vide : message ; panne : erreur et Reessayer', (tester) async {
      final l = L10n.current;
      faux.repond('GET', '/institution/announcements/feed', {'error': 'x'}, statut: 500);
      await monterEcran(tester, const AnnouncementsFeedScreen());
      expect(find.text(l.commonLoadError), findsOneWidget);
      faux.repond('GET', '/institution/announcements/feed', {'data': []});
      await tester.tap(find.text(l.commonRetry));
      await reseau(tester);
      expect(find.text(l.annFeedEmpty), findsOneWidget);
    });

    testWidgets('carte d\'accueil : trois annonces au plus et « Tout voir » ; rien sans annonce', (tester) async {
      faux.repond('GET', '/institution/announcements/feed',
          {'data': [recue(1, 'A1'), recue(2, 'A2'), recue(3, 'A3'), recue(4, 'A4')]});
      await monterEcran(tester, const Scaffold(body: SingleChildScrollView(child: AnnouncementsFeedCard())));
      final l = L10n.current;
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A3'), findsOneWidget);
      expect(find.text('A4'), findsNothing);
      await tester.tap(find.text(l.annSeeAll));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.byType(AnnouncementsFeedScreen), findsOneWidget);
    });

    testWidgets('carte d\'accueil sans annonce ou en panne : rien du tout', (tester) async {
      faux.repond('GET', '/institution/announcements/feed', {'data': []});
      await monterEcran(tester, const Scaffold(body: AnnouncementsFeedCard()));
      expect(find.text(L10n.current.annTitle), findsNothing);
      faux.repond('GET', '/institution/announcements/feed', {'error': 'x'}, statut: 500);
      await monterEcran(tester, const Scaffold(body: AnnouncementsFeedCard(key: ValueKey('b'))));
      expect(find.text(L10n.current.annTitle), findsNothing);
      expect(find.text(L10n.current.commonLoadError), findsNothing);
    });
  });

  group('Etablissement', () {
    Map<String, dynamic> envoyee(int id, String titre) => {
          'id': id, 'title': titre, 'content': 'Texte', 'audience': 'parents', 'type': 'important',
          'recipientCount': 42, 'expiresAt': null, 'createdAt': '2026-11-24T08:00:00Z', 'groupId': 3, 'groupName': 'Tle C',
        };

    testWidgets('annonces envoyees : public, classe, destinataires ; suppression apres confirmation', (tester) async {
      faux.repond('GET', '/institution/announcements', {'data': [envoyee(1, 'Conseil de classe')]});
      faux.repond('DELETE', '/institution/announcements/1', {'success': true});
      await monterEcran(tester, const InstitutionAnnouncementsScreen());
      final l = L10n.current;
      expect(find.text('Conseil de classe'), findsOneWidget);
      expect(find.textContaining(l.annAudienceParents), findsOneWidget);
      expect(find.textContaining(l.annRecipients(42)), findsOneWidget);
      expect(find.text(l.annTypeImportant), findsOneWidget);
      await tester.tap(find.byTooltip(l.commonDelete));
      await reseau(tester);
      await tester.tap(find.text(l.commonDelete).last);
      await reseau(tester);
      expect(faux.recues('DELETE', '/institution/announcements/1'), hasLength(1));
      expect(find.text('Conseil de classe'), findsNothing);
    });

    testWidgets('creation : titre et message exiges, puis envoi avec public, type et classe', (tester) async {
      faux.repond('GET', '/institution/announcements', {'data': []});
      faux.repond('GET', '/institution/groups', [
        {'id': 3, 'name': 'Tle C', 'memberCount': 30, 'level': 'Terminale'},
      ]);
      faux.repond('POST', '/institution/announcements', {'data': {'id': 9, 'recipientCount': 30}, 'success': true});
      await monterEcran(tester, const InstitutionAnnouncementsScreen());
      final l = L10n.current;
      // Feuille entière visible : téléphone haut.
      tester.view.physicalSize = const Size(800, 2400);
      await pomper(tester);
      await tester.tap(find.text(l.annNew));
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      final publier = find.text(l.annPublish);
      await tester.ensureVisible(publier);
      await tester.tap(publier);
      await reseau(tester);
      expect(find.text(l.annRequired), findsOneWidget);
      expect(faux.recues('POST', '/institution/announcements'), isEmpty);
      await tester.enterText(find.byType(TextField).at(0), 'Sortie au musee');
      await tester.enterText(find.byType(TextField).at(1), 'Rendez-vous a 8 h devant le lycee.');
      await tester.tap(find.text(l.annAudienceStudents));
      await tester.tap(find.text(l.annTypeUrgent));
      await tester.tap(find.text('Tle C'));
      await pomper(tester);
      await tester.ensureVisible(publier);
      await tester.tap(publier);
      await reseau(tester);
      final d = faux.recues('POST', '/institution/announcements').single.data as Map;
      expect(d['title'], 'Sortie au musee');
      expect(d['audience'], 'students');
      expect(d['type'], 'urgent');
      expect(d['studyGroupId'], 3);
      expect(d.containsKey('expiresAt'), isFalse);
      expect(find.text(l.annSent(30)), findsOneWidget);
    });
  });
}
