import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/tutor_profile_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);
Finder _puce(String libelle) => find.widgetWithText(WinChip, libelle);

/// Politique publique : le service la garde en memoire apres le premier
/// succes, tous les tests de ce fichier servent donc la meme.
const _politique = {
  'version': '2026-03-01',
  'disputeWindowHours': 24,
  'notchPayFeePercent': 3,
  'bounds': {
    'fullRefundHoursMin': 12,
    'fullRefundHoursMax': 48,
    'partialRefundPercentMin': 0,
    'partialRefundPercentMax': 100,
    'noRefundHoursMin': 0,
    'noRefundHoursMax': 12,
  },
  'sections': [],
};

Map<String, dynamic> _profil([Map<String, dynamic> en = const {}]) => {
      'id': 1,
      'userId': 2,
      'fullName': 'Mme Ngo',
      'title': 'Professeure agregee',
      'hourlyRateXaf': 800,
      'subjects': ['Mathématiques'],
      'levels': ['Terminale'],
      'specialties': [],
      'offersOnline': true,
      'onboardingStep': 0,
      'completionScore': 60,
      'fullRefundHours': 24,
      'partialRefundPercent': 50,
      'noRefundHours': 2,
      'monthlyMaxDiscountPercent': 30,
      ...en,
    };

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement(prefs: {'user_role': 'teacher'}));

  void routes([Map<String, dynamic>? profil, List<Map<String, String>> manquants = const []]) {
    final p = profil ?? _profil();
    faux.repond('GET', '/tutor-profile/me', p);
    faux.repond('GET', '/tutor-profile/me/completion', {'score': 60, 'missingItems': manquants});
    faux.repond('GET', '/tutor-policy', _politique);
    // L'enregistrement renvoie le profil avec l'etape demandee.
    faux.sur('PUT', '/tutor-profile/me', (o) => FauxReponse({...p, 'onboardingStep': (o.data as Map)['onboardingStep']}));
  }

  /// Ecran tres haut : toute l'etape est construite, sans defilement.
  Future<void> monterProfil(WidgetTester tester) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 5000);
    await monter(tester, ecran(const TutorProfileScreen()));
    await reseau(tester);
  }

  /// Les messages s'affichent l'un apres l'autre : attend la fin du premier.
  Future<void> laisserPasserUnMessage(WidgetTester tester) async {
    await pomper(tester, const Duration(milliseconds: 4500));
    for (var i = 0; i < 3; i++) {
      await pomper(tester, const Duration(milliseconds: 500));
    }
  }

  Map<String, dynamic> envoye() => faux.recues('PUT', '/tutor-profile/me').last.data as Map<String, dynamic>;

  testWidgets('chargement puis titre, complétude, pastilles manquantes et etape 1', (tester) async {
    routes(null, [
      {'label': 'Biographie'},
    ]);
    telephone(tester);
    tester.view.physicalSize = const Size(800, 5000);
    await monter(tester, ecran(const TutorProfileScreen()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    final l = L10n.current;
    expect(find.text(l.teacherProfileTitle), findsOneWidget);
    expect(find.text(l.teacherProfileCompletion), findsOneWidget);
    expect(find.text('60/100'), findsOneWidget);
    expect(find.text('Biographie'), findsOneWidget);
    expect(find.text(l.teacherProfileSubjectsTaught), findsOneWidget);
    // Profil existant : matiere et niveau deja actifs.
    expect(tester.widget<WinChip>(_puce(l.dataSubjectMath)).active, isTrue);
    expect(tester.widget<WinChip>(_puce(l.dataSubjectPhysics)).active, isFalse);
    expect(tester.widget<WinChip>(_puce('Terminale')).active, isTrue);
  });

  testWidgets('reprend a l\'etape enregistree (etape 3 = disponibilites)', (tester) async {
    routes(_profil({'onboardingStep': 4}));
    await monterProfil(tester);
    expect(find.text(L10n.current.teacherProfileWeeklySlots), findsOneWidget);
    expect(find.text(L10n.current.teacherProfileSubjectsTaught), findsNothing);
  });

  testWidgets('profil impossible a charger : message d\'erreur', (tester) async {
    faux.repond('GET', '/tutor-profile/me', {}, statut: 500);
    await monterProfil(tester);
    expect(find.text(L10n.current.teacherProfileLoadError), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('etape 1 : « Continuer » enregistre matieres, niveaux et specialites puis passe a l\'etape 2', (tester) async {
    routes();
    await monterProfil(tester);
    final l = L10n.current;
    await tester.tap(_puce(l.dataSubjectPhysics));
    await pomper(tester);
    await tester.tap(_puce(l.dataSubjectMath));
    await pomper(tester);
    await tester.tap(_puce(l.teacherProfileSpecHoliday));
    await pomper(tester);
    await tester.tap(_bouton(l.commonContinue));
    await reseau(tester);
    final p = envoye();
    expect(p['subjects'], ['Physique']);
    expect(p['levels'], ['Terminale']);
    expect(p['specialties'], ['Cours de vacances']);
    expect(p['onboardingStep'], 1);
    expect(find.text(l.teacherProfileStepSaved), findsOneWidget);
    expect(find.text(l.teacherProfileModes), findsOneWidget);
  });

  testWidgets('echec de l\'enregistrement : message et on reste sur l\'etape', (tester) async {
    routes();
    faux.repond('PUT', '/tutor-profile/me', {}, statut: 500);
    await monterProfil(tester);
    await tester.tap(_bouton(L10n.current.commonContinue));
    await reseau(tester);
    expect(find.text(L10n.current.teacherProfileSaveError), findsOneWidget);
    expect(find.text(L10n.current.teacherProfileSubjectsTaught), findsOneWidget);
  });

  testWidgets('« Precedent » inactif a la premiere etape, ramene a l\'etape precedente ensuite', (tester) async {
    routes(_profil({'onboardingStep': 2}));
    await monterProfil(tester);
    final l = L10n.current;
    expect(find.text(l.teacherProfileModes), findsOneWidget);
    await tester.tap(_bouton(l.teacherProfilePrevious));
    await pomper(tester);
    expect(find.text(l.teacherProfileSubjectsTaught), findsOneWidget);
    expect(tester.widget<WinButton>(_bouton(l.teacherProfilePrevious)).onTap, isNull);
  });

  group('Etape 2 : modes et zones', () {
    testWidgets('modes envoyes avec les zones', (tester) async {
      routes(_profil({'onboardingStep': 2, 'inPersonAllowed': true}));
      await monterProfil(tester);
      final l = L10n.current;
      expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, l.teacherProfileOnlineViaWinplus)).value, isTrue);
      await tester.tap(find.widgetWithText(CheckboxListTile, l.teacherProfileAtStudentHome));
      await pomper(tester);
      expect(find.text(l.teacherProfileZones), findsOneWidget);
      // Zone « Douala · Akwa » ajoutee par les deux listes.
      await tester.tap(find.text(l.teacherProfileChooseCity));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text('Douala').last);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text(l.teacherProfileDistrictHint));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text('Akwa').last);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(_bouton(l.teacherProfileAddZone));
      await pomper(tester);
      expect(find.textContaining('Akwa'), findsOneWidget);
      await tester.tap(_bouton(l.commonContinue));
      await reseau(tester);
      final p = envoye();
      expect(p['offersOnline'], true);
      expect(p['offersAtStudentHome'], true);
      expect(p['offersAtTutorHome'], false);
      expect(p['interventionZones'], [
        {'city': 'Douala', 'quartier': 'Akwa'},
      ]);
    });

    testWidgets('autre ville : saisie libre sans quartier', (tester) async {
      routes(_profil({'onboardingStep': 2, 'offersAtTutorHome': true, 'inPersonAllowed': true}));
      await monterProfil(tester);
      final l = L10n.current;
      await tester.tap(find.text(l.teacherProfileChooseCity));
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.tap(find.text(l.teacherProfileOtherCity).last);
      await pomper(tester);
      await pomper(tester, const Duration(milliseconds: 400));
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileCityOrDistrictHint), 'Bafoussam');
      await tester.tap(_bouton(l.teacherProfileAddZone));
      await pomper(tester);
      await tester.tap(_bouton(l.commonContinue));
      await reseau(tester);
      expect(envoye()['interventionZones'], [
        {'city': 'Bafoussam', 'quartier': null},
      ]);
    });

    testWidgets('presentiel non verifie : alerte, bouton de verification et choix en « actif apres verification »', (tester) async {
      routes(_profil({
        'onboardingStep': 2,
        'inPersonAllowed': false,
        'savedOffersAtStudentHome': true,
      }));
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.textContaining(l.teacherProfileBlockedDefault), findsOneWidget);
      expect(_bouton(l.teacherProfileGetVerified), findsOneWidget);
      // Le choix enregistre reste coche, avec sa mention.
      expect(find.text(l.teacherProfileActiveAfterVerification), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, l.teacherProfileAtStudentHome)).value, isTrue);
    });

    testWidgets('presentiel autorise : aucune alerte de verification', (tester) async {
      routes(_profil({'onboardingStep': 2, 'inPersonAllowed': true}));
      await monterProfil(tester);
      expect(_bouton(L10n.current.teacherProfileGetVerified), findsNothing);
    });
  });

  group('Etape 3 : tarifs', () {
    testWidgets('suggestion WinAI : alerte du tarif propose, puis « Utiliser ce tarif » remplit le champ', (tester) async {
      routes(_profil({'onboardingStep': 3}));
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {
        'suggested_rate_xaf': 1500,
        'range_low_xaf': 1000,
        'range_high_xaf': 2000,
        'based_on': 'market_data',
        'explanation': 'Selon le marche',
      });
      await monterProfil(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherProfileAiSuggestion));
      await reseau(tester);
      final envoi = faux.recues('POST', '/tutor-profile/me/suggest-rate').single.data as Map;
      expect(envoi['subject'], 'Mathématiques');
      expect(envoi['level'], 'Terminale');
      expect(find.text(l.teacherProfileRateSuggested(1500, 1000, 2000, 'Selon le marche')), findsOneWidget);
      await tester.tap(find.text(l.teacherProfileUseRate));
      await pomper(tester);
      expect(tester.widget<TextField>(find.widgetWithText(TextField, '1500').first).controller!.text, '1500');
    });

    testWidgets('suggestion indisponible : message', (tester) async {
      routes(_profil({'onboardingStep': 3}));
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {}, statut: 500);
      await monterProfil(tester);
      await tester.tap(_bouton(L10n.current.teacherProfileAiSuggestion));
      await reseau(tester);
      expect(find.text(L10n.current.teacherProfileAiUnavailable), findsOneWidget);
    });

    testWidgets('sans matiere choisie : la suggestion n\'envoie rien', (tester) async {
      routes(_profil({'onboardingStep': 3, 'subjects': []}));
      await monterProfil(tester);
      await tester.tap(_bouton(L10n.current.teacherProfileAiSuggestion));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-profile/me/suggest-rate'), isEmpty);
    });

    testWidgets('seance d\'essai et engagement mensuel : champs affiches puis envoyes, remise bornee par le serveur', (tester) async {
      routes(_profil({'onboardingStep': 3}));
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.widgetWithText(TextField, l.teacherProfileTrialPriceHint), findsNothing);
      await tester.tap(find.widgetWithText(CheckboxListTile, l.teacherProfileTrialToggle));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileTrialPriceHint), '300');
      await tester.tap(find.widgetWithText(SwitchListTile, l.teacherProfileMonthlyToggle));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileMonthlyDiscountHint(30)), '80');
      await tester.tap(_bouton(l.commonContinue));
      await reseau(tester);
      final p = envoye();
      expect(p['hourlyRateXaf'], 800);
      expect(p['trialSessionEnabled'], true);
      expect(p['trialSessionPriceXaf'], 300);
      expect(p['monthlyEnabled'], true);
      // 80 % demande, 30 % maximum autorise.
      expect(p['monthlyDiscountPercent'], 30);
      // Etape 3 terminee (comme l'etape 1 envoie 1).
      expect(p['onboardingStep'], 3);
    });
  });

  group('Etape 4 : disponibilites et politique', () {
    testWidgets('creneaux, preavis et maximum hebdomadaire envoyes avec les delais de remboursement', (tester) async {
      routes(_profil({'onboardingStep': 4}));
      await monterProfil(tester);
      final l = L10n.current;
      // Lundi matin et mardi soir.
      final lundi = find.text(WinFormat.weekdayShortCap(DateTime.monday));
      await tester.tap(lundi);
      await pomper(tester);
      await tester.tap(_puce(l.teacherProfileHours(48)));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileUnlimited), '6');
      await tester.tap(_bouton(l.commonContinue));
      await reseau(tester);
      final p = envoye();
      expect(p['noticeHours'], 48);
      expect(p['maxSessionsPerWeek'], 6);
      expect(p['availabilitySlots'], [
        {'dayOfWeek': 1, 'startTime': '08:00', 'endTime': '12:00', 'isActive': true},
      ]);
      expect(p['fullRefundHours'], 24);
      expect(p['partialRefundPercent'], 50);
      expect(p['noRefundHours'], 2);
    });

    testWidgets('politique d\'annulation : valeurs actuelles, limites du serveur et boutons + / -', (tester) async {
      routes(_profil({'onboardingStep': 4}));
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.text('24 ${l.teacherProfileHoursBefore}'), findsOneWidget);
      expect(find.text('50 %'), findsOneWidget);
      expect(find.text('2 ${l.teacherProfileHoursBefore}'), findsOneWidget);
      expect(find.text(l.teacherProfilePolicyBounds(12, 48, 0, 100, 0, 12)), findsOneWidget);
      final moins = find.byIcon(PhosphorIconsRegular.minusCircle);
      final plus = find.byIcon(PhosphorIconsRegular.plusCircle);
      // Remboursement partiel : pas de 10 points.
      await tester.tap(moins.at(1));
      await pomper(tester);
      expect(find.text('40 %'), findsOneWidget);
      await tester.tap(plus.at(1));
      await pomper(tester);
      await tester.tap(plus.at(1));
      await pomper(tester);
      expect(find.text('60 %'), findsOneWidget);
      // Remboursement total : pas de 1 heure.
      await tester.tap(plus.at(0));
      await pomper(tester);
      expect(find.text('25 ${l.teacherProfileHoursBefore}'), findsOneWidget);
    });

    testWidgets('bornes atteintes : le bouton correspondant est inactif', (tester) async {
      routes(_profil({'onboardingStep': 4, 'fullRefundHours': 12, 'partialRefundPercent': 100, 'noRefundHours': 12}));
      await monterProfil(tester);
      final moins = find.byIcon(PhosphorIconsRegular.minusCircle);
      final plus = find.byIcon(PhosphorIconsRegular.plusCircle);
      IconButton bouton(Finder icone) => tester.widget<IconButton>(find.ancestor(of: icone, matching: find.byType(IconButton)));
      expect(bouton(moins.at(0)).onPressed, isNull);
      expect(bouton(plus.at(1)).onPressed, isNull);
      // Aucun remboursement : limite au delai de remboursement total (12 h).
      expect(bouton(plus.at(2)).onPressed, isNull);
    });
  });

  group('Etape 5 : presentation, verification et activation', () {
    testWidgets('« Enregistrer » envoie titre, bio, video et style', (tester) async {
      routes(_profil({'onboardingStep': 5}));
      await monterProfil(tester);
      final l = L10n.current;
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileProTitleHint), 'Agregee de maths');
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.maxLength == 300), 'Dix ans d\'experience');
      await tester.tap(_puce(l.teacherProfileStyleInteractive));
      await pomper(tester);
      await tester.enterText(find.widgetWithText(TextField, 'https://youtube.com/...'), 'https://exemple.test/v');
      await tester.tap(_bouton(l.commonSave));
      await reseau(tester);
      expect(envoye(), {
        'title': 'Agregee de maths',
        'tutorBio': 'Dix ans d\'experience',
        'videoUrl': 'https://exemple.test/v',
        'teachingStyle': 'Interactif',
        'onboardingStep': 5,
      });
      expect(find.text(l.teacherProfileStepSaved), findsOneWidget);
    });

    testWidgets('« Activer » enregistre puis active le profil', (tester) async {
      routes(_profil({'onboardingStep': 5}));
      faux.repond('POST', '/tutor-profile/me/activate', _profil({'onboardingStep': 5, 'isActive': true}));
      await monterProfil(tester);
      final l = L10n.current;
      await tester.tap(_bouton(l.teacherProfileActivate));
      await reseau(tester);
      expect(faux.recues('PUT', '/tutor-profile/me'), hasLength(1));
      expect(faux.recues('POST', '/tutor-profile/me/activate'), hasLength(1));
      expect(_bouton(l.teacherProfileActivate), findsNothing);
      // Le message d'enregistrement passe d'abord : « Profil active » est en file.
      await laisserPasserUnMessage(tester);
      expect(find.text(l.teacherProfileActivated), findsOneWidget);
    });

    testWidgets('activation refusee : message d\'erreur, le bouton reste', (tester) async {
      routes(_profil({'onboardingStep': 5}));
      faux.repond('POST', '/tutor-profile/me/activate', {'error': 'Profil incomplet'}, statut: 400);
      await monterProfil(tester);
      await tester.tap(_bouton(L10n.current.teacherProfileActivate));
      await reseau(tester);
      // Le message d'enregistrement passe d'abord : l'erreur est en file.
      await laisserPasserUnMessage(tester);
      expect(find.text(L10n.current.teacherProfileActivateError), findsOneWidget);
      expect(_bouton(L10n.current.teacherProfileActivate), findsOneWidget);
    });

    testWidgets('profil actif : pas de bouton « Activer »', (tester) async {
      routes(_profil({'onboardingStep': 5, 'isActive': true}));
      await monterProfil(tester);
      expect(_bouton(L10n.current.teacherProfileActivate), findsNothing);
      expect(_bouton(L10n.current.commonSave), findsOneWidget);
    });

    testWidgets('diplome : envoi de l\'adresse du document puis relecture du profil', (tester) async {
      routes(_profil({'onboardingStep': 5}));
      faux.repond('POST', '/tutor-profile/me/verification-document', {'id': 4, 'documentUrl': 'https://exemple.test/d.pdf', 'status': 'pending'});
      await monterProfil(tester);
      final l = L10n.current;
      await tester.enterText(find.widgetWithText(TextField, l.teacherProfileDocUrlHint), ' https://exemple.test/d.pdf ');
      // Il existe deux boutons « Envoyer » possibles : celui du diplome est le seul de l'ecran.
      await tester.tap(_bouton(l.commonSend));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-profile/me/verification-document').single.data, {'documentUrl': 'https://exemple.test/d.pdf'});
      expect(faux.recues('GET', '/tutor-profile/me'), hasLength(2));
    });

    testWidgets('diplome deja envoye : son statut est affiche a la place du champ', (tester) async {
      routes(_profil({
        'onboardingStep': 5,
        'pendingOrLatestDocument': {'id': 4, 'documentUrl': 'https://exemple.test/d.pdf', 'status': 'pending'},
      }));
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.text(l.teacherProfileDocStatus('pending')), findsOneWidget);
      expect(find.widgetWithText(TextField, l.teacherProfileDocUrlHint), findsNothing);
    });

    testWidgets('carte de verification : libelle selon l\'etat (a faire, verifie, suspendu)', (tester) async {
      routes(_profil({'onboardingStep': 5}));
      await monterProfil(tester);
      final l = L10n.current;
      expect(find.text(l.teacherProfileVerifRoutes), findsOneWidget);
      await monter(tester, const SizedBox());
      routes(_profil({'onboardingStep': 5, 'isInPersonVerified': true}));
      await monterProfil(tester);
      expect(find.text(l.teacherProfileVerifOpen), findsOneWidget);
      await monter(tester, const SizedBox());
      routes(_profil({'onboardingStep': 5, 'isInPersonVerified': true, 'inPersonSuspended': true}));
      await monterProfil(tester);
      expect(find.text(l.teacherProfileVerifSuspended), findsOneWidget);
    });
  });

  group('Apercu et vacances', () {
    testWidgets('apercu « comme un eleve » : titre, tarif, matieres ; retour a l\'edition', (tester) async {
      routes(_profil({'tutorBio': 'Dix ans d\'experience', 'trialSessionEnabled': true, 'isDiplomaVerified': true}));
      await monterProfil(tester);
      final l = L10n.current;
      await tester.tap(find.byTooltip(l.teacherProfilePreview));
      await pomper(tester);
      expect(find.text('Professeure agregee'), findsOneWidget);
      expect(find.text('Dix ans d\'experience'), findsOneWidget);
      expect(find.text('800 XAF/h'), findsOneWidget);
      expect(find.text(l.teacherProfileTrialOffered), findsOneWidget);
      expect(find.text(l.tutoringDiplomaVerified), findsOneWidget);
      // Aucun avis encore : mention neutre (la note s'affiche des le premier avis).
      expect(find.text(l.teacherProfileNoReviews), findsOneWidget);
      expect(find.text(l.dataSubjectMath), findsOneWidget);
      await tester.tap(find.byTooltip(l.teacherProfileBackToEdit));
      await pomper(tester);
      expect(find.text(l.teacherProfileSubjectsTaught), findsOneWidget);
    });

    testWidgets('profil actif : mode « en vacances » envoye au serveur ; absent pour un profil inactif', (tester) async {
      routes(_profil({'isActive': true}));
      faux.repond('POST', '/tutor-profile/me/vacation', _profil({'isActive': true, 'isOnVacation': true}));
      await monterProfil(tester);
      final l = L10n.current;
      await tester.tap(find.byTooltip(l.teacherProfileOnHoliday));
      await reseau(tester);
      expect(faux.recues('POST', '/tutor-profile/me/vacation').single.data, true);
      expect(find.byIcon(PhosphorIconsRegular.airplaneTakeoff), findsOneWidget);

      await monter(tester, const SizedBox());
      routes(_profil());
      await monterProfil(tester);
      expect(find.byTooltip(l.teacherProfileOnHoliday), findsNothing);
    });
  });
}
