import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/parent/subscription_status_screen.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _abo([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'hasPlan': true,
      'pricingPlanId': 2,
      'planName': 'Famille',
      'status': 'active',
      'billingPeriod': 'monthly',
      'expiresAt': '2026-07-01T12:00:00Z',
      'autoRenew': true,
      'price': 5000,
      ...en,
    };

/// Liste verticale de l'ecran (construite au fil du defilement).
final _vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    // Boites en memoire : une ecriture sur disque lancee pendant un test ne
    // se termine jamais dans son temps simule et bloquerait le test suivant.
    await Hive.openBox(LocalCacheService.parentDashboardBoxName, bytes: Uint8List(0));
    await initialiserDates();
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.parentDashboard.clear();
    faux.repond('GET', '/parent/children', [
      {'id': 4, 'firstName': 'Zoe', 'lastName': 'Eto'},
    ]);
    faux.repond('GET', '/payments/history', {'payments': []});
  });

  testWidgets('chargement puis abonnement actif : plan, badge, echeance, renouvellement et enfants', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo());
    telephone(tester);
    await monter(tester, ecran(const SubscriptionStatusScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    final echeance = DateTime.parse('2026-07-01T12:00:00Z').toLocal();
    final d = '${echeance.day.toString().padLeft(2, '0')}/${echeance.month.toString().padLeft(2, '0')}/${echeance.year}';
    expect(find.text('Famille'), findsOneWidget);
    expect(find.text(l.commonActive), findsWidgets);
    expect(find.text(l.parentSubPeriodUntil(d)), findsOneWidget);
    expect(find.text(l.parentSubAutoRenewOn), findsOneWidget);
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(_bouton(l.parentSubRenewNow), findsOneWidget);
    expect(_bouton(l.parentSubChangePlan), findsOneWidget);
  });

  testWidgets('plan gratuit : badge « gratuit », pas de renouvellement ni de resiliation', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo({'hasPlan': false, 'planName': 'Gratuit', 'expiresAt': null}));
    await monterEcran(tester, const SubscriptionStatusScreen());
    final l = L10n.current;
    // Le plan s'appelle aussi « Gratuit » : on vise le badge.
    expect(find.widgetWithText(WinBadge, l.commonFree), findsOneWidget);
    expect(_bouton(l.parentSubRenewNow), findsNothing);
    expect(_bouton(l.parentSubCancel), findsNothing);
    expect(_bouton(l.studentCoachSeePlans), findsOneWidget);
  });

  testWidgets('essai et grace de paiement : badges dedies', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo({'status': 'trialing'}));
    await monterEcran(tester, const SubscriptionStatusScreen());
    expect(find.text(L10n.current.parentSubTrial), findsOneWidget);
  });

  testWidgets('paiement en attente (grace) : badge d\'avertissement', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo({'status': 'past_due'}));
    await monterEcran(tester, const SubscriptionStatusScreen());
    expect(find.text(L10n.current.parentSubPaymentPending), findsOneWidget);
  });

  testWidgets('changement de plan programme : alerte et annulation du changement', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo({'pendingPlanName': 'Standard'}));
    faux.repond('DELETE', '/subscriptions/me/pending', {});
    await monterEcran(tester, const SubscriptionStatusScreen());
    expect(find.text(L10n.current.parentSubPendingSwitch('Standard')), findsOneWidget);
    final b = _bouton(L10n.current.parentSubCancelChange);
    await tester.scrollUntilVisible(b, 200, scrollable: _vertical);
    await pomper(tester);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('DELETE', '/subscriptions/me/pending'), hasLength(1));
  });

  testWidgets('desactiver le renouvellement automatique envoie l\'inverse de l\'etat actuel', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo());
    faux.repond('PUT', '/subscriptions/me/auto-renew', {});
    await monterEcran(tester, const SubscriptionStatusScreen());
    final b = _bouton(L10n.current.parentSubDisableAutoRenew);
    await tester.scrollUntilVisible(b, 200, scrollable: _vertical);
    await pomper(tester);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('PUT', '/subscriptions/me/auto-renew').single.data, {'enabled': false});
  });

  testWidgets('resilier : confirmation, puis appel serveur ; annuler dans la boite ne fait rien', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo());
    faux.repond('POST', '/subscriptions/me/cancel', {});
    await monterEcran(tester, const SubscriptionStatusScreen());
    final b = _bouton(L10n.current.parentSubCancel);
    await tester.scrollUntilVisible(b, 200, scrollable: _vertical);
    await pomper(tester);
    await tester.tap(b);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.parentSubCancelConfirmTitle), findsOneWidget);
    await tester.tap(find.text(L10n.current.commonCancel));
    await reseau(tester);
    expect(faux.recues('POST', '/subscriptions/me/cancel'), isEmpty);
    await tester.tap(b);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(L10n.current.parentSubCancel).last);
    await reseau(tester);
    expect(faux.recues('POST', '/subscriptions/me/cancel'), hasLength(1));
  });

  testWidgets('resiliation deja programmee : « Reprendre » appelle resume, pas de bouton de renouvellement auto', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo({'cancelAtPeriodEnd': true}));
    faux.repond('POST', '/subscriptions/me/resume', {});
    await monterEcran(tester, const SubscriptionStatusScreen());
    final l = L10n.current;
    expect(_bouton(l.parentSubDisableAutoRenew), findsNothing);
    final b = _bouton(l.parentSubResume);
    await tester.scrollUntilVisible(b, 200, scrollable: _vertical);
    await pomper(tester);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('POST', '/subscriptions/me/resume'), hasLength(1));
  });

  testWidgets('historique de paiements : etat vide puis lignes', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo());
    await monterEcran(tester, const SubscriptionStatusScreen());
    await tester.scrollUntilVisible(find.text(L10n.current.parentSubNoPayment), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text(L10n.current.parentSubNoPayment), findsOneWidget);
  });

  testWidgets('actualiser relit l\'abonnement', (tester) async {
    faux.repond('GET', '/subscriptions/me', _abo());
    await monterEcran(tester, const SubscriptionStatusScreen());
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await reseau(tester);
    expect(faux.recues('GET', '/subscriptions/me'), hasLength(2));
  });
}
