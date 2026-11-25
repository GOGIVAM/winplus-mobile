import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_engagement_service.dart';
import 'package:winplus/shared/tutor_engagement_screen.dart';
import 'package:winplus/shared/tutor_session_material_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

Map<String, dynamic> _seance(int id, {String status = 'confirmed', Map<String, dynamic> en = const {}}) => {
      'id': id,
      'sessionDate': '2026-05-05',
      'startTime': '17:00',
      'endTime': '18:00',
      'priceXaf': 4500,
      'status': status,
      'moneyState': 'held',
      ...en,
    };

Map<String, dynamic> _engagement([Map<String, dynamic> en = const {}]) => {
      'id': 40,
      'tutorUserId': 2,
      'tutorName': 'Mme Ngo',
      'status': 'active',
      'startDate': '2026-05-04',
      'endDate': '2026-06-01',
      'nextStartDate': '2026-06-01',
      'slots': [
        {'dayOfWeek': 2, 'startTime': '17:00', 'durationMinutes': 60},
      ],
      'subject': 'Maths',
      'payerType': 'parent',
      'payerName': 'Marie Eto',
      'participants': [
        {'userId': 3, 'name': 'Paul Eto'},
      ],
      'totalXaf': 18000,
      'heldXaf': 13500,
      'releasedXaf': 4500,
      'refundedXaf': 0,
      'paymentMethod': 'wallet',
      'sessionsCount': 4,
      'sessionsDone': 1,
      'sessions': [_seance(101)],
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'parent'}));

  void servir(Map<String, dynamic> e, {int id = 40}) => faux.repond('GET', '/tutor-engagements/$id', e);

  /// Ecran haut : toute la fiche est construite sans defilement.
  Future<void> monterFiche(WidgetTester tester, {int id = 40}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(TutorEngagementScreen(engagementId: id)));
    await reseau(tester);
  }

  /// Fenetre de motif : saisit le texte puis valide (ou revient).
  Future<void> repondre(WidgetTester tester, {String texte = '', bool valider = true}) async {
    await pomper(tester, const Duration(milliseconds: 400));
    if (texte.isNotEmpty) await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), texte);
    await tester.tap(find.text(valider ? L10n.current.commonConfirm : L10n.current.commonBack));
    await reseau(tester);
  }

  group('EngagementListTile', () {
    testWidgets('vue payeur : tuteur, matiere, statut, periode et total', (tester) async {
      final e = TutorEngagementRecord.fromJson(_engagement());
      await monterEcran(tester, Scaffold(body: EngagementListTile(engagement: e)));
      final l = L10n.current;
      expect(find.text('Mme Ngo · Maths'), findsOneWidget);
      expect(find.text(e.statusLabel), findsOneWidget);
      expect(find.text(l.tutoringEngTileTotal(fmtXaf(18000), 1, 4)), findsOneWidget);
    });

    testWidgets('vue tuteur : participants a la place du tuteur', (tester) async {
      final e = TutorEngagementRecord.fromJson(_engagement());
      await monterEcran(tester, Scaffold(body: EngagementListTile(engagement: e, tutorView: true)));
      expect(find.text('Paul Eto · Maths'), findsOneWidget);
    });

    testWidgets('toucher la ligne ouvre la fiche puis previent au retour', (tester) async {
      servir(_engagement());
      var change = 0;
      final e = TutorEngagementRecord.fromJson(_engagement());
      await monterEcran(tester, Scaffold(body: EngagementListTile(engagement: e, onChanged: () => change++)));
      await tester.tap(find.text('Mme Ngo · Maths'));
      await reseau(tester);
      expect(find.byType(TutorEngagementScreen), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await pomper(tester, const Duration(milliseconds: 400));
      expect(change, 1);
    });

    test('couleur du badge selon le statut', () {
      expect(engagementBadgeColor('active'), BadgeColor.success);
      expect(engagementBadgeColor('completed'), BadgeColor.success);
      expect(engagementBadgeColor('pending_payment'), BadgeColor.warn);
      expect(engagementBadgeColor('pending_tutor_approval'), BadgeColor.warn);
      expect(engagementBadgeColor('cancelled'), BadgeColor.error);
    });
  });

  group('TutorEngagementScreen', () {
    testWidgets('chargement puis fiche : tuteur, montants, flux d\'argent et seances', (tester) async {
      servir(_engagement({'viewerIsPayer': true}));
      telephone(tester);
      await monter(tester, ecran(const TutorEngagementScreen(engagementId: 40)));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringEngWith('Mme Ngo')), findsOneWidget);
      expect(find.text(l.tutoringEngPaidAdvance), findsOneWidget);
      expect(find.text('${fmtXaf(18000)} XAF'), findsOneWidget);
      expect(find.text('${fmtXaf(13500)} XAF'), findsOneWidget);
      expect(find.text(l.tutoringEngSessions(1, 4)), findsOneWidget);
      expect(find.textContaining('17:00-18:00'), findsOneWidget);
    });

    testWidgets('introuvable : message du serveur ou message par defaut', (tester) async {
      faux.repond('GET', '/tutor-engagements/40', {'message': 'Acces refuse'}, statut: 403);
      await monterFiche(tester);
      expect(find.text('Acces refuse'), findsOneWidget);
      await monter(tester, const SizedBox());
      faux.repond('GET', '/tutor-engagements/40', {}, statut: 404);
      await monterFiche(tester);
      expect(find.text(L10n.current.tutoringEngNotFound), findsOneWidget);
    });

    testWidgets('remise, frais retenus et motif d\'annulation dans la note', (tester) async {
      servir(_engagement({'status': 'cancelled', 'discountPercent': 10, 'discountXaf': 2000, 'feesRetainedXaf': 300, 'cancellationReason': 'Demenagement'}));
      await monterFiche(tester);
      final l = L10n.current;
      expect(find.textContaining(l.tutoringEngFeesNote(fmtXaf(300)).trim()), findsOneWidget);
      expect(find.text(l.tutoringEngReason('Demenagement')), findsOneWidget);
    });

    group('Tuteur, demande en attente', () {
      Map<String, dynamic> attente() => _engagement({'status': 'pending_tutor_approval', 'viewerIsTutor': true, 'responseDeadlineAt': '2026-05-01T10:00:00Z'});

      testWidgets('delai de reponse et boutons Accepter / Refuser', (tester) async {
        servir(attente());
        await monterFiche(tester);
        final l = L10n.current;
        expect(find.text('Paul Eto'), findsOneWidget);
        expect(find.textContaining(l.tutoringEngReplyBefore('').trim()), findsOneWidget);
        expect(_bouton(l.tutoringEngAccept), findsOneWidget);
        expect(_bouton(l.commonDecline), findsOneWidget);
        expect(_bouton(l.tutoringEngCancel), findsNothing);
      });

      testWidgets('accepter : appel serveur, message et fiche relue', (tester) async {
        servir(attente());
        faux.repond('PUT', '/tutor-engagements/40/accept', _engagement({'status': 'active'}));
        await monterFiche(tester);
        servir(_engagement({'status': 'active', 'viewerIsTutor': true}));
        await tester.tap(_bouton(L10n.current.tutoringEngAccept));
        await reseau(tester);
        expect(faux.recues('PUT', '/tutor-engagements/40/accept'), hasLength(1));
        expect(find.text(L10n.current.tutoringEngAccepted), findsOneWidget);
        expect(faux.recues('GET', '/tutor-engagements/40'), hasLength(2));
        expect(_bouton(L10n.current.tutoringEngAccept), findsNothing);
      });

      testWidgets('refuser avec motif ; « Retour » n\'envoie rien', (tester) async {
        servir(attente());
        faux.repond('PUT', '/tutor-engagements/40/decline', _engagement({'status': 'rejected'}));
        await monterFiche(tester);
        final l = L10n.current;
        await tester.tap(_bouton(l.commonDecline));
        await repondre(tester, valider: false);
        expect(faux.recues('PUT', '/tutor-engagements/40/decline'), isEmpty);
        await tester.tap(_bouton(l.commonDecline));
        await repondre(tester, texte: '  Complet ');
        expect(faux.recues('PUT', '/tutor-engagements/40/decline').single.data, {'reason': 'Complet'});
        expect(find.text(l.tutoringEngDeclined), findsOneWidget);
      });

      testWidgets('erreur serveur : son message est affiche', (tester) async {
        servir(attente());
        faux.repond('PUT', '/tutor-engagements/40/accept', {'message': 'Creneau deja pris'}, statut: 409);
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngAccept));
        await reseau(tester);
        expect(find.text('Creneau deja pris'), findsOneWidget);
      });
    });

    testWidgets('annuler l\'engagement : motif vide envoye a null', (tester) async {
      servir(_engagement({'viewerIsPayer': true, 'canCancel': true}));
      faux.repond('POST', '/tutor-engagements/40/cancel', _engagement({'status': 'cancelled'}));
      await monterFiche(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringEngCancel));
      await pomper(tester, const Duration(milliseconds: 400));
      expect(find.text(l.tutoringEngCancelPayerConfirm), findsOneWidget);
      await repondre(tester);
      expect(faux.recues('POST', '/tutor-engagements/40/cancel').single.data, {'reason': null});
      expect(find.text(l.tutoringEngCancelled), findsOneWidget);
    });

    group('Renouvellement (payeur)', () {
      testWidgets('engagement par solde : interrupteur automatique et renouvellement manuel', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'canSetAutoRenew': true, 'canRenew': true}));
        faux.repond('PUT', '/tutor-engagements/40/auto-renew', _engagement({'autoRenew': true}));
        await monterFiche(tester);
        final l = L10n.current;
        expect(find.text(l.tutoringEngRenewal), findsOneWidget);
        expect(find.text(l.tutoringEngAutoRenewTitle), findsOneWidget);
        expect(_bouton(l.tutoringEngRenewWallet), findsOneWidget);
        expect(_bouton(l.tutoringEngRenewMm), findsOneWidget);
        await tester.tap(find.byType(SwitchListTile));
        await reseau(tester);
        expect(faux.recues('PUT', '/tutor-engagements/40/auto-renew').single.data, {'enabled': true});
        expect(find.text(l.tutoringEngAutoOn), findsOneWidget);
      });

      testWidgets('paiement Mobile Money : automatique indisponible ; echec affiche', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'paymentMethod': 'mobile_money', 'autoRenewFailureReason': 'Solde insuffisant'}));
        await monterFiche(tester);
        final l = L10n.current;
        expect(find.text(l.tutoringEngAutoWalletOnly), findsOneWidget);
        expect(find.text(l.tutoringEngAutoFailed('Solde insuffisant')), findsOneWidget);
      });

      testWidgets('renouveler par solde : ouvre la fiche du mois suivant', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'canRenew': true}));
        faux.repond('POST', '/tutor-engagements/40/renew', {'engagement': _engagement({'id': 41})});
        servir(_engagement({'id': 41, 'startDate': '2026-06-01', 'endDate': '2026-06-29'}), id: 41);
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngRenewWallet));
        await reseau(tester);
        await pomper(tester, const Duration(milliseconds: 400));
        await reseau(tester);
        expect(faux.recues('POST', '/tutor-engagements/40/renew').single.data, {'paymentMethod': 'wallet'});
        expect(tester.widget<TutorEngagementScreen>(find.byType(TutorEngagementScreen)).engagementId, 41);
      });

      testWidgets('renouveler par Mobile Money : numero demande, chiffres seuls envoyes', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'canRenew': true}));
        faux.repond('POST', '/tutor-engagements/40/renew', {'engagement': _engagement({'id': 41})});
        servir(_engagement({'id': 41}), id: 41);
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngRenewMm));
        await pomper(tester, const Duration(milliseconds: 400));
        expect(find.text(L10n.current.tutoringMomoNumber), findsOneWidget);
        await repondre(tester, texte: '6 12 34 56 78');
        expect(faux.recues('POST', '/tutor-engagements/40/renew').single.data, {'paymentMethod': 'mobile_money', 'phone': '612345678'});
      });

      testWidgets('Mobile Money sans numero : rien n\'est envoye', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'canRenew': true}));
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngRenewMm));
        await repondre(tester);
        expect(faux.recues('POST', '/tutor-engagements/40/renew'), isEmpty);
      });

      testWidgets('deja renouvele : « Voir le mois suivant »', (tester) async {
        servir(_engagement({'viewerIsPayer': true, 'renewedToEngagementId': 41}));
        servir(_engagement({'id': 41}), id: 41);
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngSeeNextMonth));
        await reseau(tester);
        // L'ecran du mois suivant est pousse par-dessus : le premier reste dessous (masque).
        expect(find.byType(TutorEngagementScreen, skipOffstage: false), findsNWidgets(2));
        expect(tester.widget<TutorEngagementScreen>(find.byType(TutorEngagementScreen)).engagementId, 41);
      });

      testWidgets('vue du tuteur : pas de section de renouvellement', (tester) async {
        servir(_engagement({'viewerIsTutor': true}));
        await monterFiche(tester);
        expect(find.text(L10n.current.tutoringEngRenewal), findsNothing);
      });
    });

    group('Seances', () {
      testWidgets('remboursement et support de seance pour une seance confirmee', (tester) async {
        servir(_engagement({
          'sessions': [
            _seance(101, en: {'refundAmountXaf': 2250, 'refundPercent': 50}),
            _seance(102, status: 'cancelled'),
          ],
        }));
        await monterFiche(tester);
        final l = L10n.current;
        expect(find.textContaining(l.tutoringEngRefundedAmount(fmtXaf(2250))), findsOneWidget);
        expect(_bouton(l.tutoringMaterial), findsOneWidget);
        await tester.tap(_bouton(l.tutoringMaterial));
        await reseau(tester);
        expect(tester.widget<TutorSessionMaterialScreen>(find.byType(TutorSessionMaterialScreen)).bookingId, 101);
      });

      testWidgets('marquer effectuee : appel serveur et message', (tester) async {
        servir(_engagement({
          'sessions': [_seance(101, en: {'canMarkCompleted': true})],
        }));
        faux.repond('PUT', '/tutor-bookings/101/complete', {'id': 101, 'sessionDate': '2026-05-05', 'status': 'completed'});
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringStatusCompleted));
        await reseau(tester);
        expect(faux.recues('PUT', '/tutor-bookings/101/complete'), hasLength(1));
        expect(find.text(L10n.current.tutoringEngMarkedCompleted), findsOneWidget);
      });

      testWidgets('contester : motif obligatoire ; vide = rien envoye, rempli = contestation', (tester) async {
        servir(_engagement({
          'sessions': [_seance(101, status: 'completed', en: {'canDispute': true})],
        }));
        faux.repond('PUT', '/tutor-bookings/101/dispute', {'id': 101, 'sessionDate': '2026-05-05', 'status': 'disputed'});
        await monterFiche(tester);
        final l = L10n.current;
        await tester.tap(_bouton(l.tutoringDispute));
        await repondre(tester);
        expect(faux.recues('PUT', '/tutor-bookings/101/dispute'), isEmpty);
        await tester.tap(_bouton(l.tutoringDispute));
        await repondre(tester, texte: 'Tuteur absent');
        expect(faux.recues('PUT', '/tutor-bookings/101/dispute').single.data, {'reason': 'Tuteur absent'});
        expect(find.text(l.tutoringEngDisputed), findsOneWidget);
      });

      testWidgets('annuler une seance : appel serveur avec le motif', (tester) async {
        servir(_engagement({
          'sessions': [_seance(101, en: {'canCancel': true})],
        }));
        faux.repond('POST', '/tutor-bookings/101/cancel', {'id': 101, 'sessionDate': '2026-05-05', 'status': 'cancelled'});
        await monterFiche(tester);
        await tester.tap(_bouton(L10n.current.tutoringEngCancelSession));
        await repondre(tester, texte: 'Malade');
        expect(faux.recues('POST', '/tutor-bookings/101/cancel').single.data, {'reason': 'Malade'});
        expect(find.text(L10n.current.tutoringEngSessionCancelled), findsOneWidget);
      });
    });
  });
}
