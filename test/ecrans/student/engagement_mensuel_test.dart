import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_profile_service.dart';
import 'package:winplus/shared/tutor_engagement_screen.dart';
import 'package:winplus/student/tutors/tutor_engagement_flow_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

String _jour(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _aujourdhui = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

/// Disponible le mardi de 17 h a 19 h : le creneau propose par defaut est
/// donc « mardi 17:00, 1 h ».
TutorProfile _profil([Map<String, dynamic> en = const {}]) => TutorProfile.fromJson({
      'id': 1,
      'userId': 21,
      'fullName': 'Mme Ngo',
      'subjects': ['Maths'],
      'offersOnline': true,
      'noticeHours': 24,
      'monthlyEnabled': true,
      'monthlyDiscountPercent': 10,
      'availabilitySlots': [
        {'dayOfWeek': 2, 'startTime': '17:00', 'endTime': '19:00'},
      ],
      'fullRefundHours': 24,
      'partialRefundPercent': 50,
      'noRefundHours': 2,
      ...en,
    });

Map<String, dynamic> _devis([Map<String, dynamic> en = const {}]) => {
      'startDate': '2026-05-05',
      'endDate': '2026-05-26',
      'monthlyEnabled': true,
      'discountPercent': 10,
      'participantCount': 1,
      'sessions': [
        for (final j in ['05', '12', '19', '26'])
          {'sessionDate': '2026-05-$j', 'startTime': '17:00', 'endTime': '18:00', 'baseTotalXaf': 5000, 'discountXaf': 500, 'priceXaf': 4500, 'isAvailable': true},
      ],
      'subtotalXaf': 20000,
      'discountXaf': 2000,
      'totalXaf': 18000,
      'isAvailable': true,
      ...en,
    };

Map<String, dynamic> _engagement(String statut, {Map<String, dynamic> en = const {}}) => {
      'id': 40,
      'tutorUserId': 21,
      'tutorName': 'Mme Ngo',
      'status': statut,
      'startDate': '2026-05-05',
      'endDate': '2026-05-26',
      'sessionsCount': 4,
      'totalXaf': 18000,
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() {
    faux = preparerEnvironnement(prefs: {'user_role': 'student', 'user_id': 3});
    faux.repond('GET', '/tutor-assignments/booking-context', {'role': 'student', 'allowedPayerTypes': ['student']});
    faux.repond('GET', '/tutor-policy', {'version': '2026-03-01', 'disputeWindowHours': 24, 'notchPayFeePercent': 3, 'sections': []});
  });

  Future<void> monterParcours(WidgetTester tester, {TutorProfile? profil}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(TutorEngagementFlowScreen(profile: profil ?? _profil(), initialTopics: const ['limites'])));
    await reseau(tester);
  }

  Future<void> allerAuDevis(WidgetTester tester, {Map<String, dynamic>? devis}) async {
    faux.repond('POST', '/tutor-engagements/quote', devis ?? _devis());
    await monterParcours(tester);
    await tester.tap(_bouton(L10n.current.tutoringEngSeeQuote));
    await reseau(tester);
  }

  Future<void> allerAuPaiement(WidgetTester tester, {num? solde}) async {
    if (solde == null) {
      faux.repond('GET', '/wallet/me', {}, statut: 500);
    } else {
      faux.repond('GET', '/wallet/me', {'data': {'availableXaf': solde}});
    }
    await allerAuDevis(tester);
    await tester.tap(_bouton(L10n.current.tutoringEngPayMonth));
    await reseau(tester);
  }

  group('Etape 1 : plan du mois', () {
    testWidgets('intro avec la remise, premier jour (preavis compris), creneau par defaut et nombre de seances', (tester) async {
      await monterParcours(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringEngStagePlan), findsOneWidget);
      expect(find.text('${l.tutoringEngIntro}${l.tutoringEngIntroDiscount(10)}${l.tutoringEngIntroEnd}'), findsOneWidget);
      final debut = _aujourdhui.add(const Duration(days: 2));
      expect(find.textContaining('${debut.year}'), findsWidgets);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text(l.tutoringEngPerMonth(4)), findsOneWidget);
      expect(find.text('limites'), findsOneWidget);
    });

    testWidgets('ajouter puis retirer un creneau : 8 puis 4 seances ; le dernier ne peut pas etre retire', (tester) async {
      await monterParcours(tester);
      final l = L10n.current;
      // L'info-bulle est dans le bouton : on remonte au bouton lui-même.
      IconButton retirer(int i) => tester.widget<IconButton>(
          find.ancestor(of: find.byTooltip(l.tutoringEngRemoveSlot).at(i), matching: find.byType(IconButton)).first);
      expect(retirer(0).onPressed, isNull);
      await tester.tap(find.text(l.tutoringEngAddSlot));
      await pomper(tester);
      expect(find.text(l.tutoringEngPerMonth(8)), findsOneWidget);
      await tester.tap(find.byTooltip(l.tutoringEngRemoveSlot).at(1));
      await pomper(tester);
      expect(find.text(l.tutoringEngPerMonth(4)), findsOneWidget);
    });

    testWidgets('« Voir le devis » : plan envoye au serveur', (tester) async {
      await allerAuDevis(tester);
      final envoi = faux.recues('POST', '/tutor-engagements/quote').single.data as Map;
      expect(envoi['tutorUserId'], 21);
      expect(envoi['startDate'], _jour(_aujourdhui.add(const Duration(days: 2))));
      expect(envoi['mode'], 'online');
      expect(envoi['subject'], 'Maths');
      expect(envoi['slots'], [
        {'dayOfWeek': 2, 'startTime': '17:00', 'durationMinutes': 60},
      ]);
    });
  });

  group('Etape 2 : devis', () {
    testWidgets('quatre seances, prix barres, sous-total, remise et total', (tester) async {
      await allerAuDevis(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringEngStageQuote), findsOneWidget);
      expect(find.text('${fmtXaf(4500)} XAF'), findsNWidgets(4));
      expect(find.text('${fmtXaf(5000)} '), findsNWidgets(4));
      expect(find.text(l.tutoringEngSubtotal), findsOneWidget);
      expect(find.text(l.tutoringEngMonthlyDiscount(10)), findsOneWidget);
      expect(find.text('-${fmtXaf(2000)} XAF'), findsOneWidget);
      expect(find.text('${fmtXaf(18000)} XAF'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.tutoringEngPayMonth)).onTap, isNotNull);
    });

    testWidgets('seance indisponible : motif et alerte, paiement inactif', (tester) async {
      await allerAuDevis(
        tester,
        devis: _devis({
          'isAvailable': false,
          'sessions': [
            {'sessionDate': '2026-05-05', 'startTime': '17:00', 'endTime': '18:00', 'priceXaf': 4500, 'isAvailable': false, 'unavailableReason': 'Deja reserve'},
          ],
        }),
      );
      final l = L10n.current;
      expect(find.text('Deja reserve'), findsOneWidget);
      expect(find.text(l.tutoringEngSomeUnavailable), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.tutoringEngPayMonth)).onTap, isNull);
    });

    testWidgets('offre mensuelle desactivee : alerte « ne propose pas »', (tester) async {
      await allerAuDevis(tester, devis: _devis({'isAvailable': false, 'monthlyEnabled': false}));
      expect(find.text(L10n.current.tutoringEngNotOffered), findsOneWidget);
    });

    testWidgets('devis en erreur : message, « Modifier les creneaux » revient au plan', (tester) async {
      faux.repond('POST', '/tutor-engagements/quote', {'message': 'Plan invalide'}, statut: 400);
      await monterParcours(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.tutoringEngSeeQuote));
      await reseau(tester);
      expect(find.text('Plan invalide'), findsOneWidget);
      await tester.tap(_bouton(l.tutoringEngEditSlots));
      await pomper(tester);
      expect(find.text(l.tutoringEngStagePlan), findsOneWidget);
    });
  });

  group('Etape 3 : paiement', () {
    testWidgets('solde suffisant : renouvellement automatique coche et envoye, puis succes', (tester) async {
      await allerAuPaiement(tester, solde: 20000);
      final l = L10n.current;
      faux.repond('POST', '/tutor-engagements', {'engagement': _engagement('pending_tutor_approval')});
      expect(find.text(l.tutoringEngStagePayment), findsOneWidget);
      expect(find.textContaining(fmtXaf(20000)), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile));
      await pomper(tester);
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(18000))));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-engagements').single.data as Map;
      expect(envoi['paymentMethod'], 'wallet');
      expect(envoi['autoRenew'], true);
      expect(envoi['topics'], ['limites']);
      expect(envoi.containsKey('phone'), isFalse);
      expect(find.text(l.tutoringEngStageSuccess), findsOneWidget);
      expect(find.text(l.tutoringEngPaymentReceived), findsOneWidget);
      expect(_bouton(l.tutoringEngSeeEngagement), findsOneWidget);
    });

    testWidgets('solde insuffisant : montant manquant, paiement inactif', (tester) async {
      await allerAuPaiement(tester, solde: 5000);
      final l = L10n.current;
      expect(find.text(l.tutoringEngWalletMissing(fmtXaf(13000))), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.tutoringPayAmount(fmtXaf(18000)))).onTap, isNull);
    });

    testWidgets('solde illisible : Mobile Money impose ; numero de 9 chiffres exige', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringMomoNumber), findsOneWidget);
      await tester.enterText(find.byType(TextField), '6123');
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(18000))));
      await pomper(tester);
      expect(find.text(l.tutoringEngPhoneFormat), findsOneWidget);
      expect(faux.recues('POST', '/tutor-engagements'), isEmpty);
    });

    testWidgets('Mobile Money : numero normalise, attente, suivi puis engagement paye ; « Voir l\'engagement »', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-engagements', {'engagement': _engagement('pending_payment')});
      faux.repond('GET', '/tutor-engagements/40', _engagement('pending_payment'));
      await tester.enterText(find.byType(TextField), '237 612 345 678');
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(18000))));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-engagements').single.data as Map;
      expect(envoi['phone'], '612345678');
      expect(envoi['paymentMethod'], 'mobile_money');
      expect(envoi['autoRenew'], false);
      expect(find.text(l.tutoringEngValidateOnPhone), findsOneWidget);
      faux.repond('GET', '/tutor-engagements/40', _engagement('pending_tutor_approval'));
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text(l.tutoringEngPaymentReceived), findsOneWidget);
      await tester.tap(_bouton(l.tutoringEngSeeEngagement));
      await reseau(tester);
      expect(tester.widget<TutorEngagementScreen>(find.byType(TutorEngagementScreen)).engagementId, 40);
    });

    testWidgets('paiement refuse : « Paiement non confirme » et motif', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-engagements', {'engagement': _engagement('pending_payment')});
      faux.repond('GET', '/tutor-engagements/40', _engagement('cancelled', en: {'cancellationReason': 'Paiement refuse'}));
      await tester.enterText(find.byType(TextField), '612345678');
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(18000))));
      await reseau(tester);
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text(l.tutoringEngPaymentNotConfirmed), findsOneWidget);
      expect(find.text('Paiement refuse'), findsOneWidget);
    });

    testWidgets('creation refusee : message du serveur', (tester) async {
      await allerAuPaiement(tester, solde: 20000);
      faux.repond('POST', '/tutor-engagements', {'message': 'Seances en conflit'}, statut: 409);
      await tester.tap(_bouton(L10n.current.tutoringPayAmount(fmtXaf(18000))));
      await reseau(tester);
      expect(find.text('Seances en conflit'), findsOneWidget);
    });

    testWidgets('fleche retour : du paiement au devis', (tester) async {
      await allerAuPaiement(tester, solde: 20000);
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowLeft));
      await pomper(tester);
      expect(find.text(L10n.current.tutoringEngStageQuote), findsOneWidget);
    });
  });
}
