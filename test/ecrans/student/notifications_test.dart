import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/user_service.dart';
import 'package:winplus/student/notifications_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

String _ilYa(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    UserService.instance.resetNotifications();
  });

  testWidgets('chargement puis liste groupee par jour avec points « non lu »', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 1, 'title': 'Nouveau badge', 'body': 'Bravo', 'type': 'achievement', 'isRead': false, 'createdAt': _ilYa(const Duration(minutes: 5))},
        {'id': 2, 'title': 'Rappel', 'type': 'warning', 'isRead': true, 'createdAt': _ilYa(const Duration(hours: 30))},
      ],
      'unread': 1,
      'total': 2,
    });
    telephone(tester);
    await monter(tester, ecran(const NotificationsScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text('Nouveau badge'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Rappel'), findsOneWidget);
    expect(find.text(l.commonToday), findsOneWidget);
    // « Hier » : titre du groupe et heure de la notification d'hier.
    expect(find.text(l.commonYesterday), findsWidgets);
    expect(find.text(l.studentNotifMinutesAgo(5)), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    expect(UserService.instance.unreadNotifications.value, 1);
    expect(find.text(l.studentNotifSeeMore), findsNothing);
    expect(faux.requetes.single.queryParameters, {'page': 1, 'limit': 20});
  });

  testWidgets('liste vide : « tout est a jour »', (tester) async {
    faux.repond('GET', '/notifications', {'data': [], 'total': 0});
    await monterEcran(tester, const NotificationsScreen());
    expect(find.text(L10n.current.studentNotifAllCaughtUp), findsOneWidget);
  });

  testWidgets('erreur serveur : traitee comme une liste vide', (tester) async {
    faux.repond('GET', '/notifications', {}, statut: 500);
    await monterEcran(tester, const NotificationsScreen());
    expect(find.text(L10n.current.studentNotifAllCaughtUp), findsOneWidget);
  });

  testWidgets('toucher une notification non lue la marque lue et decremente le badge', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 1, 'title': 'A lire', 'type': 'info', 'isRead': false, 'createdAt': _ilYa(const Duration(minutes: 5))},
      ],
      'unread': 1,
      'total': 1,
    });
    faux.repond('PUT', '/notifications/1/read', {'unread': 0});
    await monterEcran(tester, const NotificationsScreen());
    expect(UserService.instance.unreadNotifications.value, 1);
    await tester.tap(find.text('A lire'));
    await reseau(tester);
    expect(faux.recues('PUT', '/notifications/1/read'), hasLength(1));
    expect(UserService.instance.unreadNotifications.value, 0);
  });

  testWidgets('toucher une notification deja lue n\'appelle pas le serveur', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 3, 'title': 'Deja vue', 'type': 'info', 'isRead': true, 'createdAt': _ilYa(const Duration(minutes: 5))},
      ],
      'total': 1,
    });
    await monterEcran(tester, const NotificationsScreen());
    await tester.tap(find.text('Deja vue'));
    await reseau(tester);
    expect(faux.recues('PUT', '/notifications/3/read'), isEmpty);
  });

  testWidgets('« Tout lire » appelle read-all ; un echec affiche un message', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 1, 'title': 'N1', 'type': 'info', 'isRead': false, 'createdAt': _ilYa(const Duration(minutes: 5))},
      ],
      'unread': 1,
      'total': 1,
    });
    await monterEcran(tester, const NotificationsScreen());
    await tester.tap(find.text(L10n.current.studentNotifReadAll));
    await reseau(tester);
    expect(find.text(L10n.current.studentNotifMarkFailed), findsOneWidget);
    expect(UserService.instance.unreadNotifications.value, 1, reason: 'le badge est restaure apres l\'echec');
  });

  testWidgets('« Tout lire » reussi : plus aucun point non lu et badge a zero', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 1, 'title': 'N1', 'type': 'info', 'isRead': false, 'createdAt': _ilYa(const Duration(minutes: 5))},
      ],
      'unread': 1,
      'total': 1,
    });
    faux.repond('PUT', '/notifications/read-all', {'unread': 0});
    await monterEcran(tester, const NotificationsScreen());
    await tester.tap(find.text(L10n.current.studentNotifReadAll));
    await reseau(tester);
    expect(UserService.instance.unreadNotifications.value, 0);
    expect(find.text(L10n.current.studentNotifMarkFailed), findsNothing);
  });

  testWidgets('« Voir plus » relit une page plus grande quand il reste des notifications', (tester) async {
    faux.repond('GET', '/notifications', {
      'data': [
        {'id': 1, 'title': 'N1', 'type': 'info', 'isRead': true, 'createdAt': _ilYa(const Duration(minutes: 5))},
      ],
      'total': 5,
    });
    await monterEcran(tester, const NotificationsScreen());
    final plus = find.text(L10n.current.studentNotifSeeMore);
    await tester.scrollUntilVisible(plus, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(plus);
    await reseau(tester);
    expect(faux.requetes.last.queryParameters, {'page': 1, 'limit': 21});
  });
}
