import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/user_service.dart';
import 'package:winplus/shared/notifications_ai_summary.dart';

import '../helpers/ecran.dart';
import '../helpers/faux_reseau.dart';

/// Lot 7 : résumé WinAI des notifications non lues.
void main() {
  late FauxReseau faux;
  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    NotificationsAiSummary.dismissed = false;
  });

  List<ApiNotification> nonLues(int n) => [
        for (var i = 0; i < n; i++)
          ApiNotification(id: i, title: 'Titre $i', body: 'Message $i', type: 'info', isRead: false, createdAt: DateTime(2026, 11, 20)),
      ];

  testWidgets('3 non lues : resume affiche, puis masque pour la session', (tester) async {
    faux.repond('POST', '/ai/summarize-notifications', {'summary': '- Deux devoirs a rendre\n- Un message de Mme Ngo'});
    await monterEcran(tester, Scaffold(body: NotificationsAiSummary(unread: nonLues(3))));
    final l = L10n.current;
    expect((faux.recues('POST', '/ai/summarize-notifications').single.data as Map)['notifications'], hasLength(3));
    expect(find.text('- Deux devoirs a rendre\n- Un message de Mme Ngo'), findsOneWidget);
    await tester.tap(find.byTooltip(l.notifSummaryHide));
    await pomper(tester);
    expect(find.text(l.notifSummaryTitle(3)), findsNothing);
    expect(NotificationsAiSummary.dismissed, isTrue);
  });

  testWidgets('moins de 3 non lues : aucun appel', (tester) async {
    await monterEcran(tester, Scaffold(body: NotificationsAiSummary(unread: nonLues(2))));
    expect(faux.recues('POST', '/ai/summarize-notifications'), isEmpty);
  });

  testWidgets('WinAI en panne : rien', (tester) async {
    faux.repond('POST', '/ai/summarize-notifications', {'error': 'x'}, statut: 503);
    await monterEcran(tester, Scaffold(body: NotificationsAiSummary(unread: nonLues(4))));
    expect(find.text(L10n.current.notifSummaryTitle(4)), findsNothing);
  });
}
