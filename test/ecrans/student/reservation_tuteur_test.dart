import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/tutor_booking_service.dart';
import 'package:winplus/services/tutor_profile_service.dart';
import 'package:winplus/student/tutors/tutor_booking_flow_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

String _jour(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final _aujourdhui = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

TutorProfile _profil([Map<String, dynamic> en = const {}]) => TutorProfile.fromJson({
      'id': 1,
      'userId': 21,
      'fullName': 'Mme Ngo',
      'subjects': ['Maths', 'Physique'],
      'offersOnline': true,
      'offersAtTutorHome': true,
      'fullRefundHours': 24,
      'partialRefundPercent': 50,
      'noRefundHours': 2,
      ...en,
    });

TutorAvailabilityOccurrence _creneau(String heure, {bool reservable = true, List<int> durees = const [60, 90]}) =>
    TutorAvailabilityOccurrence.fromJson({'date': _jour(_aujourdhui), 'startTime': heure, 'availableDurationsMinutes': durees, 'isBookable': reservable});

Map<String, dynamic> _devis([Map<String, dynamic> en = const {}]) => {
      'startTime': '15:00',
      'endTime': '16:00',
      'durationMinutes': 60,
      'modeCategory': 'online',
      'subject': 'Maths',
      'baseHourlyRateXaf': 4500,
      'subtotalXaf': 4500,
      'totalXaf': 4500,
      'isAvailable': true,
      ...en,
    };

Map<String, dynamic> _reservation(String statut, {Map<String, dynamic> en = const {}}) => {
      'id': 88,
      'tutorUserId': 21,
      'tutorName': 'Mme Ngo',
      'studentUserId': 3,
      'sessionDate': _jour(_aujourdhui),
      'startTime': '15:00',
      'endTime': '16:00',
      'mode': 'online',
      'priceXaf': 4500,
      'status': statut,
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

  /// Ecran haut : chaque etape est construite sans defilement.
  Future<void> monterParcours(WidgetTester tester, {TutorProfile? profil, List<TutorAvailabilityOccurrence>? creneaux, TutorAvailabilityOccurrence? initial, List<String> sujets = const []}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    final liste = creneaux ?? [_creneau('15:00'), _creneau('17:30', reservable: false)];
    await monter(
      tester,
      ecran(TutorBookingFlowScreen(profile: profil ?? _profil(), occurrences: liste, initialOccurrence: initial, initialTopics: sujets)),
    );
    await reseau(tester);
  }

  /// Etape 1 (creneau) puis etape 2 (recapitulatif) avec le devis demande.
  Future<void> allerAuRecap(WidgetTester tester, {Map<String, dynamic>? devis}) async {
    faux.repond('POST', '/tutor-bookings/quote', devis ?? _devis());
    await monterParcours(tester);
    await tester.tap(find.text('15:00'));
    await pomper(tester);
    await tester.tap(_bouton(L10n.current.commonContinue));
    await reseau(tester);
  }

  Future<void> allerAuPaiement(WidgetTester tester, {num? solde}) async {
    if (solde == null) {
      faux.repond('GET', '/wallet/me', {}, statut: 500);
    } else {
      faux.repond('GET', '/wallet/me', {'data': {'availableXaf': solde}});
    }
    await allerAuRecap(tester);
    await tester.tap(_bouton(L10n.current.tutoringPayAmount(fmtXaf(4500))));
    await reseau(tester);
  }

  group('Etape 1 : creneau', () {
    testWidgets('tuteur, quatorze jours, creneaux du jour ; « Continuer » inactif sans creneau', (tester) async {
      await monterParcours(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringStepChooseSlot), findsOneWidget);
      expect(find.text('Mme Ngo'), findsOneWidget);
      expect(find.text(l.tutoringChooseDay), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('17:30'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNull);
    });

    testWidgets('creneau complet : non selectionnable', (tester) async {
      await monterParcours(tester);
      await tester.tap(find.text('17:30'));
      await pomper(tester);
      expect(find.text(L10n.current.commonDuration), findsNothing);
    });

    testWidgets('choisir un creneau : duree d\'une heure par defaut, heure de fin, autre duree possible', (tester) async {
      await monterParcours(tester);
      final l = L10n.current;
      await tester.tap(find.text('15:00'));
      await pomper(tester);
      expect(find.text(l.tutoringEndsAt('16:00')), findsOneWidget);
      expect(tester.widget<WinChip>(find.widgetWithText(WinChip, formatDurationMinutes(60))).active, isTrue);
      await tester.tap(find.widgetWithText(WinChip, formatDurationMinutes(90)));
      await pomper(tester);
      expect(find.text(l.tutoringEndsAt('16:30')), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNotNull);
    });

    testWidgets('autre jour sans creneau : « Aucun creneau ce jour-la »', (tester) async {
      await monterParcours(tester);
      final demain = _aujourdhui.add(const Duration(days: 1));
      await tester.tap(find.text('${demain.day}').first);
      await pomper(tester);
      expect(find.text(L10n.current.tutoringNoSlotThatDay), findsOneWidget);
    });

    testWidgets('creneau donne par la fiche : deja choisi', (tester) async {
      final c = _creneau('15:00');
      await monterParcours(tester, creneaux: [c], initial: c);
      expect(find.text(L10n.current.tutoringEndsAt('16:00')), findsOneWidget);
    });

    testWidgets('sans creneaux fournis : calendrier de deux semaines lu ; en erreur, message', (tester) async {
      faux.repond('GET', '/tutor-bookings/tutor/21/calendar', {}, statut: 500);
      telephone(tester);
      await monter(tester, ecran(TutorBookingFlowScreen(profile: _profil())));
      await reseau(tester);
      expect(faux.recues('GET', '/tutor-bookings/tutor/21/calendar'), hasLength(2));
      expect(find.text(L10n.current.tutoringCalendarError), findsOneWidget);
    });

    testWidgets('plusieurs matieres : choix de la matiere ; sujets de la recherche repris', (tester) async {
      await monterParcours(tester, sujets: ['derivees']);
      expect(tester.widget<WinChip>(find.widgetWithText(WinChip, 'Maths')).active, isTrue);
      expect(find.text('derivees'), findsOneWidget);
    });
  });

  group('Etape 2 : recapitulatif', () {
    testWidgets('devis demande au serveur, prix, modes et bouton de paiement avec le montant', (tester) async {
      await allerAuRecap(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringStepRecap), findsOneWidget);
      final envoi = faux.recues('POST', '/tutor-bookings/quote').single.data as Map;
      expect(envoi, {
        'tutorUserId': 21,
        'sessionDate': _jour(_aujourdhui),
        'startTime': '15:00',
        'durationMinutes': 60,
        'mode': 'online',
        'subject': 'Maths',
        'participantCount': 1,
      });
      expect(find.text(l.tutoringSessionMode), findsOneWidget);
      expect(find.text(l.commonOnline), findsOneWidget);
      expect(find.text(l.tutoringModeTutorHome), findsOneWidget);
      expect(_bouton(l.tutoringPayAmount(fmtXaf(4500))), findsOneWidget);
    });

    testWidgets('changer de mode redemande le devis', (tester) async {
      await allerAuRecap(tester);
      await tester.tap(find.text(L10n.current.tutoringModeTutorHome));
      await reseau(tester);
      final envois = faux.recues('POST', '/tutor-bookings/quote');
      expect(envois, hasLength(2));
      expect((envois.last.data as Map)['mode'], 'tutor_home');
    });

    testWidgets('devis en erreur : message du serveur, paiement inactif', (tester) async {
      faux.repond('POST', '/tutor-bookings/quote', {'message': 'Tarif absent'}, statut: 400);
      await monterParcours(tester);
      await tester.tap(find.text('15:00'));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.commonContinue));
      await reseau(tester);
      expect(find.text('Tarif absent'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(L10n.current.tutoringPayNow)).onTap, isNull);
    });

    testWidgets('creneau devenu indisponible : alerte et paiement inactif', (tester) async {
      await allerAuRecap(tester, devis: _devis({'isAvailable': false, 'unavailableReason': 'Creneau pris'}));
      final l = L10n.current;
      expect(find.text('Creneau pris'), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.tutoringPayNow)).onTap, isNull);
    });

    testWidgets('fleche retour : revient au choix du creneau', (tester) async {
      await allerAuRecap(tester);
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowLeft));
      await pomper(tester);
      expect(find.text(L10n.current.tutoringStepChooseSlot), findsOneWidget);
    });
  });

  group('Etape 3 : paiement', () {
    testWidgets('Mobile Money : numero trop court refuse', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringPayMethod), findsOneWidget);
      await tester.enterText(find.byType(TextField), '6123');
      await tester.tap(_bouton('${l.tutoringPay} ${fmtXaf(4500)} XAF'));
      await pomper(tester);
      expect(find.text(l.tutoringPhoneInvalid), findsOneWidget);
      expect(faux.recues('POST', '/tutor-bookings'), isEmpty);
    });

    testWidgets('Mobile Money : numero normalise, attente, puis seance confirmee', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-bookings', {'booking': _reservation('pending_payment', en: {'notchpayReference': 'NP-123'})});
      faux.repond('GET', '/tutor-bookings/88', _reservation('pending_payment'));
      await tester.enterText(find.byType(TextField), '+237 6 12 34 56 78');
      await tester.tap(_bouton('${l.tutoringPay} ${fmtXaf(4500)} XAF'));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-bookings').single.data as Map;
      expect(envoi['phone'], '612345678');
      expect(envoi['paymentMethod'], 'mobile_money');
      expect(envoi['payerType'], 'student');
      expect(envoi.containsKey('participantUserIds'), isFalse);
      expect(find.text(l.tutoringWaitingConfirmation), findsOneWidget);
      expect(find.text(l.tutoringReference('NP-123')), findsOneWidget);
      // Suivi toutes les 4 secondes.
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text(l.tutoringWaitingConfirmation), findsOneWidget);
      faux.repond('GET', '/tutor-bookings/88', _reservation('confirmed'));
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text(l.tutoringSessionConfirmed), findsOneWidget);
      expect(find.text('${fmtXaf(4500)} XAF'), findsOneWidget);
      expect(_bouton(l.tutoringViewMySession), findsOneWidget);
    });

    testWidgets('paiement annule : motif, puis « Reessayer » revient au formulaire', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-bookings', {'booking': _reservation('pending_payment')});
      faux.repond('GET', '/tutor-bookings/88', _reservation('cancelled', en: {'cancellationReason': 'Paiement refuse'}));
      await tester.enterText(find.byType(TextField), '612345678');
      await tester.tap(_bouton('${l.tutoringPay} ${fmtXaf(4500)} XAF'));
      await reseau(tester);
      await pomper(tester, const Duration(seconds: 4));
      await reseau(tester);
      expect(find.text(l.tutoringBookingCancelled), findsOneWidget);
      expect(find.text('Paiement refuse'), findsOneWidget);
      await tester.tap(_bouton(l.commonRetry));
      await pomper(tester);
      expect(find.text(l.tutoringPayMethod), findsOneWidget);
    });

    testWidgets('creation refusee : message du serveur', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      faux.repond('POST', '/tutor-bookings', {'message': 'Creneau deja reserve'}, statut: 409);
      await tester.enterText(find.byType(TextField), '612345678');
      await tester.tap(_bouton('${l.tutoringPay} ${fmtXaf(4500)} XAF'));
      await reseau(tester);
      expect(find.text('Creneau deja reserve'), findsOneWidget);
    });

    testWidgets('solde illisible : option portefeuille inactive', (tester) async {
      await allerAuPaiement(tester);
      final l = L10n.current;
      expect(find.text(l.tutoringWalletUnavailable), findsOneWidget);
      await tester.tap(find.text(l.tutoringWalletMine));
      await pomper(tester);
      expect(find.text(l.tutoringMomoNumber), findsOneWidget);
    });

    testWidgets('solde suffisant : paiement immediat sans numero, en attente du tuteur', (tester) async {
      await allerAuPaiement(tester, solde: 10000);
      final l = L10n.current;
      faux.repond('POST', '/tutor-bookings', {'booking': _reservation('pending_tutor_approval', en: {'paymentMethod': 'wallet'})});
      expect(find.text(l.tutoringWalletAvailable(fmtXaf(10000))), findsOneWidget);
      await tester.tap(find.text(l.tutoringWalletMine));
      await pomper(tester);
      expect(find.text(l.tutoringWalletOk), findsOneWidget);
      expect(find.text(l.tutoringMomoNumber), findsNothing);
      await tester.tap(_bouton('${l.tutoringPayWithBalance} ${fmtXaf(4500)} XAF'));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-bookings').single.data as Map;
      expect(envoi['paymentMethod'], 'wallet');
      expect(envoi.containsKey('phone'), isFalse);
      expect(find.text(l.tutoringPaymentReceivedAwaiting), findsOneWidget);
      expect(find.text(l.tutoringMustAccept), findsOneWidget);
      // Paiement par solde : aucun suivi.
      await pomper(tester, const Duration(seconds: 4));
      expect(faux.recues('GET', '/tutor-bookings/88'), isEmpty);
    });

    testWidgets('solde insuffisant : montant manquant et paiement inactif', (tester) async {
      await allerAuPaiement(tester, solde: 1000);
      final l = L10n.current;
      await tester.tap(find.text(l.tutoringWalletMine));
      await pomper(tester);
      expect(find.text(l.tutoringWalletMissing(fmtXaf(3500), l.tutoringShortfallMine)), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton('${l.tutoringPayWithBalance} ${fmtXaf(4500)} XAF')).onTap, isNull);
    });
  });

  group('Seance d\'essai et lieu', () {
    /// Recapitulatif avec un profil donne.
    Future<void> recap(WidgetTester tester, TutorProfile profil) async {
      faux.repond('POST', '/tutor-bookings/quote', _devis());
      await monterParcours(tester, profil: profil);
      await tester.tap(find.text('15:00'));
      await pomper(tester);
      await tester.tap(_bouton(L10n.current.commonContinue));
      await reseau(tester);
    }

    testWidgets('essai non propose : pas de choix, devis et bouton habituels', (tester) async {
      await recap(tester, _profil({'trialSessionEnabled': true, 'trialEligible': false}));
      final l = L10n.current;
      expect(find.text(l.tutoringTrialTitle), findsNothing);
      expect(_bouton(l.tutoringPayAmount(fmtXaf(4500))), findsOneWidget);
    });

    testWidgets('essai gratuit : devis d\'essai, demande envoyee sans paiement, en attente du repetiteur', (tester) async {
      await recap(tester, _profil({'trialSessionEnabled': true, 'trialEligible': true}));
      final l = L10n.current;
      expect(find.text(l.tutoringTrialFreeHint), findsOneWidget);
      faux.repond('POST', '/tutor-bookings/quote', _devis({'isTrial': true, 'totalXaf': 0, 'regularTotalXaf': 4500}));
      await tester.tap(find.byType(SwitchListTile));
      await reseau(tester);
      expect((faux.recues('POST', '/tutor-bookings/quote').last.data as Map)['isTrial'], true);
      expect(find.text(l.tutoringTrialInsteadOf(fmtXaf(4500))), findsOneWidget);
      faux.repond('POST', '/tutor-bookings', {
        'booking': _reservation('pending_tutor_approval', en: {'priceXaf': 0, 'isTrial': true, 'paymentStatus': 'not_required', 'paymentMethod': 'free'}),
      });
      await tester.tap(_bouton(l.tutoringTrialSend));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-bookings').single.data as Map;
      expect(envoi['isTrial'], true);
      expect(envoi.containsKey('phone'), isFalse);
      expect(find.text(l.tutoringTrialSent), findsOneWidget);
      expect(find.text(l.tutoringTrialMustAccept), findsOneWidget);
      expect(find.text(l.tutoringTrialFree), findsOneWidget);
      // Ni portefeuille lu, ni suivi de paiement.
      expect(faux.recues('GET', '/wallet/me'), isEmpty);
      await pomper(tester, const Duration(seconds: 4));
      expect(faux.recues('GET', '/tutor-bookings/88'), isEmpty);
    });

    testWidgets('essai refuse par le serveur : son message s\'affiche sur le recapitulatif', (tester) async {
      await recap(tester, _profil({'trialSessionEnabled': true, 'trialEligible': true}));
      faux.repond('POST', '/tutor-bookings/quote', _devis({'isTrial': true, 'totalXaf': 0, 'regularTotalXaf': 4500}));
      await tester.tap(find.byType(SwitchListTile));
      await reseau(tester);
      faux.repond('POST', '/tutor-bookings', {'success': false, 'code': 'essai_non_disponible', 'message': 'Une seance a deja ete reservee avec ce repetiteur.'}, statut: 400);
      await tester.tap(_bouton(L10n.current.tutoringTrialSend));
      await reseau(tester);
      expect(find.text('Une seance a deja ete reservee avec ce repetiteur.'), findsOneWidget);
      expect(find.text(L10n.current.tutoringStepRecap), findsOneWidget);
    });

    testWidgets('essai payant : paiement habituel au prix d\'essai', (tester) async {
      await recap(tester, _profil({'trialSessionEnabled': true, 'trialEligible': true, 'trialSessionPriceXaf': 2000}));
      final l = L10n.current;
      expect(find.text(l.tutoringTrialPriceHint(fmtXaf(2000))), findsOneWidget);
      faux.repond('POST', '/tutor-bookings/quote', _devis({'isTrial': true, 'totalXaf': 2000, 'regularTotalXaf': 4500}));
      await tester.tap(find.byType(SwitchListTile));
      await reseau(tester);
      expect(_bouton(l.tutoringPayAmount(fmtXaf(2000))), findsOneWidget);
      expect(_bouton(l.tutoringTrialSend), findsNothing);
    });

    testWidgets('a domicile : le lieu est demande avant le paiement, puis envoye avec la precision', (tester) async {
      faux.repond('GET', '/wallet/me', {'data': {'availableXaf': 10000}});
      await recap(tester, _profil({'offersAtStudentHome': true}));
      final l = L10n.current;
      // En ligne : aucun champ de lieu.
      expect(find.text(l.tutoringLocationLabel), findsNothing);
      await tester.tap(find.text(l.tutoringModeStudentHomeMine));
      await reseau(tester);
      expect(find.text(l.tutoringLocationLabel), findsOneWidget);
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(4500))));
      await reseau(tester);
      expect(find.text(l.tutoringLocationRequired), findsOneWidget);
      expect(find.text(l.tutoringStepRecap), findsOneWidget);
      // Les deux champs du lieu (un champ de sujets les precede sur l'ecran).
      Finder champ(String libelle) => find.descendant(of: find.widgetWithText(WinTextField, libelle), matching: find.byType(TextField));
      await tester.enterText(champ(l.tutoringLocationLabel), 'Akwa, rue Joss, face a la pharmacie');
      await pomper(tester);
      await tester.enterText(champ(l.tutoringLocationNoteLabel), 'Portail bleu');
      await pomper(tester);
      expect(find.text(l.tutoringLocationRequired), findsNothing);
      await tester.tap(_bouton(l.tutoringPayAmount(fmtXaf(4500))));
      await reseau(tester);
      faux.repond('POST', '/tutor-bookings', {
        'booking': _reservation('pending_tutor_approval', en: {'mode': 'student_home', 'paymentMethod': 'wallet', 'locationAddress': 'Akwa, rue Joss, face a la pharmacie'}),
      });
      await tester.tap(find.text(l.tutoringWalletMine));
      await pomper(tester);
      await tester.tap(_bouton('${l.tutoringPayWithBalance} ${fmtXaf(4500)} XAF'));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-bookings').single.data as Map;
      expect(envoi['mode'], 'student_home');
      expect(envoi['locationAddress'], 'Akwa, rue Joss, face a la pharmacie');
      expect(envoi['locationNote'], 'Portail bleu');
      expect(find.text('Akwa, rue Joss, face a la pharmacie'), findsOneWidget);
    });

    testWidgets('chez le repetiteur : pas de champ, une phrase dit ou la seance a lieu', (tester) async {
      await recap(tester, _profil());
      final l = L10n.current;
      await tester.tap(find.text(l.tutoringModeTutorHome));
      await reseau(tester);
      expect(find.text(l.tutoringLocationTutorHome), findsOneWidget);
      expect(find.text(l.tutoringLocationLabel), findsNothing);
    });
  });
}
