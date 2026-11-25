import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/affiliate_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : programme d'affiliation du professeur (lien, chiffres, commissions).
void main() {
  late FauxReseau faux;
  final partageOrigine = AffiliateScreen.share;
  late List<String> partages;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement();
    partages = [];
    AffiliateScreen.share = (url, sujet) async => partages.add(url);
  });
  tearDown(() => AffiliateScreen.share = partageOrigine);

  void routes({List commissions = const []}) {
    faux.repond('GET', '/affiliate/me', {
      'id': 1, 'code': 'NGO42', 'referralUrl': 'https://winplus.cm/?ref=NGO42', 'commissionRate': 10, 'status': 'active',
      'createdAt': '2026-11-01T00:00:00Z',
    });
    faux.repond('GET', '/affiliate/me/stats', {
      'account': {'code': 'NGO42'}, 'totalClicks': 37, 'totalConversions': 4,
      'pendingEarnings': 1500, 'confirmedEarnings': 3000, 'paidEarnings': 2000,
    });
    faux.repond('GET', '/affiliate/me/commissions', commissions);
  }

  testWidgets('lien, code, taux, chiffres et commissions avec leur statut', (tester) async {
    routes(commissions: [
      {'id': 1, 'orderId': 8, 'orderNumber': 'WP-0008', 'orderAmount': 15000, 'commissionRateApplied': 10,
       'commissionAmount': 1500, 'status': 'pending', 'createdAt': '2026-11-20T08:00:00Z'},
      {'id': 2, 'orderId': 5, 'orderNumber': 'WP-0005', 'orderAmount': 20000, 'commissionRateApplied': 10,
       'commissionAmount': 2000, 'status': 'paid', 'createdAt': '2026-11-10T08:00:00Z'},
    ]);
    await monterEcran(tester, const AffiliateScreen());
    final l = L10n.current;
    expect(find.text('https://winplus.cm/?ref=NGO42'), findsOneWidget);
    expect(find.text(l.affCode('NGO42')), findsOneWidget);
    expect(find.text(l.affRate('10')), findsOneWidget);
    expect(find.text('37'), findsOneWidget);
    expect(find.text('${fmtXaf(5000)} XAF'), findsOneWidget, reason: 'confirmees + payees');
    await tester.scrollUntilVisible(find.text(l.affStatusPaid), 200, scrollable: find.byType(Scrollable).first);
    expect(find.widgetWithText(WinBadge, l.affStatusPending), findsOneWidget);
    expect(find.text(l.affStatusPaid), findsOneWidget);
  });

  testWidgets('copier met le lien dans le presse-papiers ; partager envoie le lien', (tester) async {
    routes();
    await monterEcran(tester, const AffiliateScreen());
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copie = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final l = L10n.current;
    await tester.tap(find.text(l.affCopy));
    await reseau(tester);
    expect(copie, 'https://winplus.cm/?ref=NGO42');
    expect(find.text(l.affLinkCopied), findsOneWidget);
    await tester.tap(find.text(l.affShare));
    await reseau(tester);
    expect(partages, ['https://winplus.cm/?ref=NGO42']);
  });

  testWidgets('aucune commission : explication et « Partager mon lien »', (tester) async {
    routes();
    await monterEcran(tester, const AffiliateScreen());
    final l = L10n.current;
    final bouton = find.text(l.affShareMyLink);
    await tester.scrollUntilVisible(bouton, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text(l.affEmpty), findsOneWidget);
    await tester.tap(bouton);
    await reseau(tester);
    expect(partages, hasLength(1));
  });

  testWidgets('panne : erreur et Reessayer', (tester) async {
    faux.repond('GET', '/affiliate/me', {'error': 'x'}, statut: 500);
    await monterEcran(tester, const AffiliateScreen());
    final l = L10n.current;
    expect(find.text(l.commonLoadError), findsOneWidget);
    routes();
    await tester.tap(find.text(l.commonRetry));
    await reseau(tester);
    expect(find.text(l.affLinkTitle), findsOneWidget);
  });
}
