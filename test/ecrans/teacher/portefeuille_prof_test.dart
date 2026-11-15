import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/teacher/teacher_wallet_view.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

String _xaf(int n) => '${n < 0 ? '−' : ''}${fmtXaf(n.abs())} FCFA';

/// La vue n'a pas de Scaffold : on la pose dans un Scaffold.
Widget _page() => const Scaffold(body: TeacherWalletView());

Map<String, dynamic> _solde([Map<String, dynamic> en = const {}]) => {
      'availableXaf': 12500,
      'pendingXaf': 3000,
      'engagedXaf': 0,
      'isAnomaly': false,
      'minWithdrawalXaf': 500,
      'minRechargeXaf': 200,
      ...en,
    };

Map<String, dynamic> _retrait([Map<String, dynamic> en = const {}]) => {
      'id': 9,
      'status': 'pending',
      'amountXaf': 3000,
      'operator': 'mtn',
      'phoneMasked': '6XX XX 12 34',
      'inProgress': true,
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  void routes({
    Map<String, dynamic>? solde,
    List<Map<String, dynamic>> operations = const [],
    int? total,
    List<Map<String, dynamic>> revenus = const [],
    Object? part,
  }) {
    faux.repond('GET', '/wallet/me', {'data': solde ?? _solde()});
    faux.repond('GET', '/wallet/me/entries', {'data': {'items': operations, 'total': total ?? operations.length}});
    faux.repond('GET', '/teacher/revenue/by-content', revenus);
    faux.repond('GET', '/teacher/revenue-share', part ?? {'data': {}});
  }

  Future<void> monterVue(WidgetTester tester) => monterEcran(tester, _page());

  Future<void> ouvrirRetrait(WidgetTester tester) async {
    await tester.tap(_bouton('Retirer'));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
  }

  Future<void> remplirRetrait(WidgetTester tester, {String tel = '612345678', String confirmation = '612345678', String montant = '3000'}) async {
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), tel);
    await tester.enterText(champs.at(1), confirmation);
    await tester.enterText(champs.at(2), montant);
    await pomper(tester);
  }

  group('Solde et historique', () {
    testWidgets('chargement puis solde, en attente, engage et minimum de retrait', (tester) async {
      routes(solde: _solde({'engagedXaf': 700}));
      telephone(tester);
      await monter(tester, ecran(_page()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await reseau(tester);
      expect(find.text('SOLDE DISPONIBLE'), findsOneWidget);
      expect(find.text(_xaf(12500)), findsOneWidget);
      expect(find.text('En attente : ${_xaf(3000)}'), findsOneWidget);
      expect(find.text('Engagé (retrait en cours) : ${_xaf(700)}'), findsOneWidget);
      expect(find.text('Retrait minimum ${_xaf(500)}, sans frais'), findsOneWidget);
      expect(find.textContaining('Anomalie'), findsNothing);
    });

    testWidgets('anomalie de solde : signalee au support', (tester) async {
      routes(solde: _solde({'isAnomaly': true}));
      await monterVue(tester);
      expect(find.text('Anomalie de solde signalée au support WinPlus.'), findsOneWidget);
    });

    testWidgets('portefeuille vide : message d\'accueil et historique vide', (tester) async {
      routes(solde: _solde({'availableXaf': 0, 'pendingXaf': 0}));
      await monterVue(tester);
      expect(find.textContaining('Ton portefeuille est vide'), findsOneWidget);
      expect(find.text('Aucune opération pour l\'instant.'), findsOneWidget);
    });

    testWidgets('solde indisponible : message du serveur puis « Reessayer »', (tester) async {
      faux.repond('GET', '/wallet/me', {'error': 'Service momentanement coupe'}, statut: 500);
      faux.repond('GET', '/wallet/me/entries', {'data': {'items': [], 'total': 0}});
      faux.repond('GET', '/teacher/revenue/by-content', []);
      faux.repond('GET', '/teacher/revenue-share', {'data': {}});
      await monterVue(tester);
      expect(find.text('Solde indisponible'), findsOneWidget);
      expect(find.text('Service momentanement coupe'), findsOneWidget);
      routes();
      await tester.tap(_bouton('Réessayer'));
      await reseau(tester);
      expect(find.text('Solde indisponible'), findsNothing);
      expect(find.text(_xaf(12500)), findsOneWidget);
    });

    testWidgets('hors ligne : message de connexion', (tester) async {
      faux.coupure('GET', '/wallet/me');
      faux.repond('GET', '/wallet/me/entries', {'data': {'items': [], 'total': 0}});
      faux.repond('GET', '/teacher/revenue/by-content', []);
      faux.repond('GET', '/teacher/revenue-share', {'data': {}});
      await monterVue(tester);
      expect(find.text('Solde indisponible'), findsOneWidget);
      expect(find.text('Connexion impossible. Vérifie ton réseau et réessaie.'), findsOneWidget);
    });

    testWidgets('session expiree (401) : proposition de se reconnecter', (tester) async {
      faux.repond('GET', '/wallet/me', {}, statut: 401);
      faux.repond('GET', '/wallet/me/entries', {'data': {'items': [], 'total': 0}});
      faux.repond('GET', '/teacher/revenue/by-content', []);
      faux.repond('GET', '/teacher/revenue-share', {'data': {}});
      await monterVue(tester);
      expect(find.text('Session expirée'), findsOneWidget);
      expect(_bouton('Se reconnecter'), findsOneWidget);
      expect(_bouton('Réessayer'), findsNothing);
    });

    testWidgets('operations : credit en vert, debit, versement a zero, statuts en attente et annulee', (tester) async {
      routes(operations: [
        {'id': 1, 'date': '2026-04-06T12:00:00Z', 'source': 'catalogue', 'label': 'Vente Epreuve BAC', 'amountXaf': 5000, 'status': 'completed'},
        {'id': 2, 'date': '2026-04-05T12:00:00Z', 'source': 'retrait', 'label': 'Retrait MTN', 'amountXaf': -2000, 'status': 'pending'},
        {'id': 3, 'date': '2026-04-04T12:00:00Z', 'source': 'achat', 'label': 'Achat annule', 'amountXaf': -300, 'status': 'reversed'},
        {'id': 4, 'date': '2026-04-03T12:00:00Z', 'source': 'credit_admin', 'label': 'Geste commercial', 'amountXaf': 0, 'status': 'completed'},
      ]);
      await monterVue(tester);
      expect(find.text('Vente Epreuve BAC'), findsOneWidget);
      expect(find.text('+${_xaf(5000)}'), findsOneWidget);
      expect(find.text(_xaf(-2000)), findsOneWidget);
      expect(find.textContaining('06/04/2026'), findsOneWidget);
      expect(find.textContaining('· en attente'), findsOneWidget);
      expect(find.textContaining('· annulée'), findsOneWidget);
      expect(find.text('Versé'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('« Voir plus » charge la page suivante et affiche le nombre restant', (tester) async {
      routes(operations: [
        {'id': 1, 'source': 'catalogue', 'label': 'Vente A', 'amountXaf': 100, 'status': 'completed'},
        {'id': 2, 'source': 'catalogue', 'label': 'Vente B', 'amountXaf': 100, 'status': 'completed'},
      ], total: 5);
      await monterVue(tester);
      expect(faux.recues('GET', '/wallet/me/entries').single.queryParameters, {'source': 'all', 'page': 1, 'pageSize': 20});
      final plus = _bouton('Voir plus (3)');
      await tester.scrollUntilVisible(plus, 300, scrollable: find.byType(Scrollable).first);
      faux.repond('GET', '/wallet/me/entries', {
        'data': {
          'items': [
            {'id': 3, 'source': 'catalogue', 'label': 'Vente C', 'amountXaf': 100, 'status': 'completed'},
          ],
          'total': 5,
        },
      });
      await tester.tap(plus);
      await reseau(tester);
      expect(faux.recues('GET', '/wallet/me/entries').last.queryParameters['page'], 2);
      expect(find.text('Vente A'), findsOneWidget);
      expect(find.text('Vente C'), findsOneWidget);
      expect(_bouton('Voir plus (2)'), findsOneWidget);
    });

    testWidgets('filtre de source : recharge la liste depuis la premiere page', (tester) async {
      routes(operations: [
        {'id': 1, 'source': 'catalogue', 'label': 'Vente A', 'amountXaf': 100, 'status': 'completed'},
      ]);
      await monterVue(tester);
      faux.repond('GET', '/wallet/me/entries', {'data': {'items': [], 'total': 0}});
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ventes'));
      await reseau(tester);
      final q = faux.recues('GET', '/wallet/me/entries').last.queryParameters;
      expect(q['source'], 'catalogue');
      expect(q['page'], 1);
      expect(find.text('Vente A'), findsNothing);
      expect(find.text('Aucune opération pour cette source.'), findsOneWidget);
    });

    testWidgets('historique en erreur : message et « Reessayer » sans toucher au solde', (tester) async {
      routes();
      faux.repond('GET', '/wallet/me/entries', {'error': 'Historique indisponible'}, statut: 500);
      await monterVue(tester);
      expect(find.text(_xaf(12500)), findsOneWidget);
      expect(find.text('Historique indisponible'), findsOneWidget);
      faux.repond('GET', '/wallet/me/entries', {
        'data': {
          'items': [
            {'id': 1, 'source': 'catalogue', 'label': 'Vente A', 'amountXaf': 100, 'status': 'completed'},
          ],
          'total': 1,
        },
      });
      final reessayer = _bouton('Réessayer');
      await tester.scrollUntilVisible(reessayer, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(reessayer);
      await reseau(tester);
      expect(find.text('Vente A'), findsOneWidget);
      expect(faux.recues('GET', '/wallet/me'), hasLength(1));
    });

    testWidgets('part du professeur et revenus par contenu', (tester) async {
      routes(
        part: {'data': {'planName': 'Pro', 'teacherShare': 0.7}},
        revenus: [
          {'title': 'Epreuve de maths', 'sales': 12, 'revenue': 36000},
        ],
      );
      await monterVue(tester);
      expect(find.text('Cours particuliers · plan Pro'), findsOneWidget);
      expect(find.text('70 % pour toi · 30 % WinPlus'), findsOneWidget);
      final titre = find.text('Epreuve de maths');
      await tester.scrollUntilVisible(titre, 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('12 ventes'), findsOneWidget);
      expect(find.text('+${_xaf(36000)}'), findsOneWidget);
    });

    testWidgets('sections secondaires en panne : masquees, le solde reste affiche', (tester) async {
      routes();
      faux.repond('GET', '/teacher/revenue/by-content', {}, statut: 500);
      await monterVue(tester);
      expect(find.text(_xaf(12500)), findsOneWidget);
      expect(find.text('Revenus par contenu'), findsNothing);
      expect(find.textContaining('pour toi'), findsNothing);
    });
  });

  group('Retrait', () {
    testWidgets('« Retirer » inactif sous le minimum de retrait', (tester) async {
      routes(solde: _solde({'availableXaf': 300}));
      await monterVue(tester);
      expect(tester.widget<WinButton>(_bouton('Retirer')).onTap, isNull);
      expect(tester.widget<WinButton>(_bouton('Recharger')).onTap, isNotNull);
    });

    testWidgets('formulaire : consignes, disponible et « Tout retirer »', (tester) async {
      routes();
      await monterVue(tester);
      await ouvrirRetrait(tester);
      expect(find.text('Retirer des fonds'), findsOneWidget);
      expect(find.text('Minimum ${_xaf(500)}, aucun frais, pas de plafond. Disponible : ${_xaf(12500)}.'), findsOneWidget);
      await tester.tap(find.text('Tout retirer (${_xaf(12500)})'));
      await pomper(tester);
      expect(tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text, '12500');
    });

    testWidgets('validations : numero invalide, numeros differents, minimum, solde insuffisant', (tester) async {
      routes();
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await remplirRetrait(tester, tel: '61234', confirmation: '61234');
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      expect(find.text('Numéro Mobile Money invalide : 9 chiffres (ex. 6XXXXXXXX).'), findsOneWidget);
      await remplirRetrait(tester, confirmation: '699999999');
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      expect(find.text('Les deux numéros saisis ne correspondent pas.'), findsOneWidget);
      await remplirRetrait(tester, montant: '100');
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      expect(find.text('Le montant minimum de retrait est de ${_xaf(500)}.'), findsOneWidget);
      await remplirRetrait(tester, montant: '99999');
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      expect(find.text('Solde insuffisant : ${_xaf(12500)} disponibles.'), findsOneWidget);
      expect(faux.recues('POST', '/withdrawals'), isEmpty);
    });

    testWidgets('recapitulatif puis « Modifier » revient au formulaire', (tester) async {
      routes();
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await remplirRetrait(tester);
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      expect(find.text('Confirmer le retrait'), findsOneWidget);
      expect(find.text('Aucun'), findsOneWidget);
      expect(find.text('MTN MoMo'), findsOneWidget);
      expect(find.text('612345678'), findsOneWidget);
      expect(_bouton('Retirer ${_xaf(3000)}'), findsOneWidget);
      await tester.tap(_bouton('Modifier'));
      await pomper(tester);
      expect(find.text('Retirer des fonds'), findsOneWidget);
    });

    testWidgets('confirmation : appel serveur avec operateur, numero, montant et identifiant unique ; transfert en cours affiche', (tester) async {
      routes();
      faux.repond('POST', '/withdrawals', {'data': _retrait()});
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await tester.tap(find.text('Orange Money'));
      await pomper(tester);
      await remplirRetrait(tester);
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      await tester.tap(_bouton('Retirer ${_xaf(3000)}'));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      final envoi = faux.recues('POST', '/withdrawals').single.data as Map;
      expect(envoi['operator'], 'orange');
      expect(envoi['phone'], '612345678');
      expect(envoi['amount'], 3000);
      expect(envoi['clientRequestId'], isA<String>());
      expect((envoi['clientRequestId'] as String).length, greaterThan(10));
      expect(find.text('Transfert en cours…'), findsOneWidget);
      // Un retrait est en cours : un second est impossible.
      expect(tester.widget<WinButton>(_bouton('Retirer')).onTap, isNull);
      // Le solde est relu apres la demande.
      expect(faux.recues('GET', '/wallet/me'), hasLength(2));
      await monter(tester, const SizedBox());
    });

    testWidgets('refus du serveur (409) : message dans la fenetre, retour au formulaire', (tester) async {
      routes();
      faux.repond('POST', '/withdrawals', {'error': 'Un retrait est deja en cours'}, statut: 409);
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await remplirRetrait(tester);
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      await tester.tap(_bouton('Retirer ${_xaf(3000)}'));
      await reseau(tester);
      expect(find.text('Un retrait est deja en cours'), findsOneWidget);
      expect(find.text('Retirer des fonds'), findsOneWidget);
    });

    testWidgets('solde insuffisant (402) : nouveau solde affiche dans le formulaire', (tester) async {
      routes();
      faux.repond('POST', '/withdrawals', {'error': 'Solde insuffisant', 'balanceXaf': 1000}, statut: 402);
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await remplirRetrait(tester);
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      await tester.tap(_bouton('Retirer ${_xaf(3000)}'));
      await reseau(tester);
      expect(find.text('Solde insuffisant'), findsOneWidget);
      expect(find.textContaining('Disponible : ${_xaf(1000)}'), findsOneWidget);
    });

    testWidgets('erreur reseau : meme identifiant de demande au renvoi, pas de doublon cote serveur', (tester) async {
      routes();
      faux.coupure('POST', '/withdrawals');
      await monterVue(tester);
      await ouvrirRetrait(tester);
      await remplirRetrait(tester);
      await tester.tap(_bouton('Continuer'));
      await pomper(tester);
      await tester.tap(_bouton('Retirer ${_xaf(3000)}'));
      await reseau(tester);
      expect(find.text('Connexion impossible. Vérifie ton réseau et réessaie.'), findsOneWidget);
      // Toujours sur le recapitulatif : on renvoie.
      faux.repond('POST', '/withdrawals', {'data': _retrait()});
      await tester.tap(_bouton('Retirer ${_xaf(3000)}'));
      await reseau(tester);
      final envois = faux.recues('POST', '/withdrawals');
      expect(envois, hasLength(2));
      expect((envois[0].data as Map)['clientRequestId'], (envois[1].data as Map)['clientRequestId']);
      await monter(tester, const SizedBox());
    });

    testWidgets('retrait deja en cours au chargement : etat reel reaffiche, abouti apres le suivi', (tester) async {
      routes(solde: _solde({'activeWithdrawal': _retrait(), 'engagedXaf': 3000}));
      faux.repond('GET', '/withdrawals/status/9', {'data': _retrait({'status': 'completed', 'processedAt': '2026-04-06T12:00:00Z', 'inProgress': false})});
      await monterVue(tester);
      expect(find.text('Transfert en cours…'), findsOneWidget);
      expect(find.textContaining('L\'opération se poursuit même si tu quittes l\'application'), findsOneWidget);
      expect(find.textContaining('MTN MoMo 6XX XX 12 34'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton('Retirer')).onTap, isNull);
      // Suivi toutes les 5 secondes.
      await pomper(tester, const Duration(seconds: 5));
      await reseau(tester);
      expect(faux.recues('GET', '/withdrawals/status/9'), isNotEmpty);
      expect(find.text('Retrait effectué'), findsOneWidget);
      expect(find.textContaining('envoyés vers MTN MoMo'), findsOneWidget);
      // Fin de suivi : le solde et l'historique sont relus.
      expect(faux.recues('GET', '/wallet/me'), hasLength(2));
      // La carte se ferme.
      await tester.tap(find.byTooltip('Fermer'));
      await pomper(tester);
      expect(find.text('Retrait effectué'), findsNothing);
      await monter(tester, const SizedBox());
    });

    testWidgets('retrait echoue : motif et remise sur le solde', (tester) async {
      routes(solde: _solde({'activeWithdrawal': _retrait()}));
      faux.repond('GET', '/withdrawals/status/9', {'data': _retrait({'status': 'failed', 'failureReason': 'Numero inactif', 'inProgress': false})});
      await monterVue(tester);
      await pomper(tester, const Duration(seconds: 5));
      await reseau(tester);
      expect(find.text('Retrait non abouti'), findsOneWidget);
      expect(find.text('Numero inactif Les ${_xaf(3000)} ont été remis sur ton solde.'), findsOneWidget);
      await monter(tester, const SizedBox());
    });
  });

  group('Recharge', () {
    Future<void> ouvrirRecharge(WidgetTester tester) async {
      await tester.tap(_bouton('Recharger'));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
    }

    testWidgets('validations : montant minimum puis numero invalide', (tester) async {
      routes();
      await monterVue(tester);
      await ouvrirRecharge(tester);
      expect(find.text('Recharger mon portefeuille'), findsOneWidget);
      final champs = find.byType(TextField);
      await tester.enterText(champs.at(1), '50');
      await tester.tap(_bouton('Recharger').last);
      await pomper(tester);
      expect(find.text('Le montant minimum de recharge est de ${_xaf(200)}.'), findsWidgets);
      await tester.enterText(champs.at(1), '1000');
      await tester.enterText(champs.at(0), '6123');
      await tester.tap(_bouton('Recharger').last);
      await pomper(tester);
      expect(find.text('Numéro Mobile Money invalide : 9 chiffres (ex. 6XXXXXXXX).'), findsOneWidget);
      expect(faux.recues('POST', '/wallet/recharge'), isEmpty);
    });

    testWidgets('paiement confirme : attente, suivi du statut, « Recharge confirmee », puis solde relu', (tester) async {
      routes();
      faux.repond('POST', '/wallet/recharge', {'data': {'paymentId': 5, 'amountXaf': 1000}});
      faux.repond('GET', '/payments/5/status', {'status': 'COMPLETED'});
      await monterVue(tester);
      await ouvrirRecharge(tester);
      final champs = find.byType(TextField);
      await tester.enterText(champs.at(0), '612345678');
      await tester.enterText(champs.at(1), '1000');
      await tester.tap(_bouton('Recharger').last);
      await reseau(tester);
      final envoi = faux.recues('POST', '/wallet/recharge').single.data as Map;
      expect(envoi['amount'], 1000);
      expect(envoi['operator'], 'mtn');
      expect(envoi['phone'], '612345678');
      expect(find.text('Confirme le paiement sur ton téléphone…'), findsOneWidget);
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text('Recharge confirmée'), findsOneWidget);
      await tester.tap(_bouton('Terminé'));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await reseau(tester);
      expect(find.text('Recharge confirmée'), findsNothing);
      expect(faux.recues('GET', '/wallet/me'), hasLength(2));
    });

    testWidgets('paiement refuse : message du serveur et aucun credit', (tester) async {
      routes();
      faux.repond('POST', '/wallet/recharge', {'data': {'paymentId': 6, 'amountXaf': 1000}});
      faux.repond('GET', '/payments/6/status', {'status': 'failed', 'errorMessage': 'Paiement annule par le client'});
      await monterVue(tester);
      await ouvrirRecharge(tester);
      final champs = find.byType(TextField);
      await tester.enterText(champs.at(0), '612345678');
      await tester.enterText(champs.at(1), '1000');
      await tester.tap(_bouton('Recharger').last);
      await reseau(tester);
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text('Recharge non aboutie'), findsOneWidget);
      expect(find.text('Paiement annule par le client'), findsOneWidget);
      await tester.tap(_bouton('Terminé'));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      // Pas de rechargement du solde apres un echec.
      expect(faux.recues('GET', '/wallet/me'), hasLength(1));
    });

    testWidgets('lancement refuse par le serveur : message dans la fenetre', (tester) async {
      routes();
      faux.repond('POST', '/wallet/recharge', {'error': 'Operateur indisponible'}, statut: 400);
      await monterVue(tester);
      await ouvrirRecharge(tester);
      final champs = find.byType(TextField);
      await tester.enterText(champs.at(0), '612345678');
      await tester.enterText(champs.at(1), '1000');
      await tester.tap(_bouton('Recharger').last);
      await reseau(tester);
      expect(find.text('Operateur indisponible'), findsOneWidget);
      expect(find.text('Recharger mon portefeuille'), findsOneWidget);
    });
  });
}
