import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/auth/complete_profile_screen.dart';
import 'package:winplus/auth/onboarding_success_screen.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/win_widgets.dart';
import 'package:winplus/widgets/win_mascot.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);

  void sessionRole(String role) => faux = preparerEnvironnement(prefs: {'user_role': role});

  group('Eleve', () {
    setUp(() => sessionRole('student'));

    testWidgets('etape 1 : niveau, date de naissance facultative, « Continuer » inactif jusqu\'au choix', (tester) async {
      await monterEcran(tester, const CompleteProfileScreen());
      final l = L10n.current;
      expect(find.text(l.authStudentLevelTitle), findsOneWidget);
      expect(find.text(l.authStudentLevelHint), findsOneWidget);
      expect(find.text(l.authDobOptional), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNull);
      await tester.tap(find.text('BAC'));
      await pomper(tester);
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNotNull);
    });

    testWidgets('trois etapes puis « Terminer » : profil enregistre avec niveau, filiere et objectif, ecran de succes', (tester) async {
      faux.repond('PUT', '/users/profile', {});
      await monterEcran(tester, const CompleteProfileScreen());
      final l = L10n.current;
      await tester.tap(find.text('BAC'));
      await pomper(tester);
      await tester.tap(_bouton(l.commonContinue));
      await pomper(tester);
      expect(find.text(l.authStudentStreamTitle), findsOneWidget);
      expect(find.text(l.authDobOptional), findsNothing, reason: 'la date de naissance n\'est demandee qu\'a l\'etape 1');
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNull);
      await tester.tap(find.text(l.authOptScience));
      await pomper(tester);
      await tester.tap(_bouton(l.commonContinue));
      await pomper(tester);
      expect(find.text(l.authStudentGoalTitle), findsOneWidget);
      expect(_bouton(l.authFinish), findsOneWidget);
      await tester.tap(find.text('BAC C'));
      await pomper(tester);
      await tester.tap(_bouton(l.authFinish));
      await reseau(tester);
      await pomper(tester, const Duration(milliseconds: 500));
      expect(faux.recues('PUT', '/users/profile').single.data, {'level': 'BAC', 'specialization': 'Scientifique', 'targetExam': 'BAC C'});
      expect(find.byType(OnboardingSuccessScreen), findsOneWidget);
    });

    testWidgets('changer de choix a la meme etape remplace le precedent', (tester) async {
      faux.repond('PUT', '/users/profile', {});
      await monterEcran(tester, const CompleteProfileScreen());
      final l = L10n.current;
      await tester.tap(find.text('BEPC'));
      await tester.tap(find.text('BTS'));
      await pomper(tester);
      await tester.tap(_bouton(l.commonContinue));
      await pomper(tester);
      await tester.tap(find.text(l.authOptLiterary));
      await pomper(tester);
      await tester.tap(_bouton(l.commonContinue));
      await pomper(tester);
      await tester.tap(find.text('ENSP'));
      await pomper(tester);
      await tester.tap(_bouton(l.authFinish));
      await reseau(tester);
      expect((faux.recues('PUT', '/users/profile').single.data as Map)['level'], 'BTS');
    });
  });

  group('Autres roles', () {
    testWidgets('etablissement : pas de questionnaire, ecran de succes directement', (tester) async {
      sessionRole('institution');
      await monterEcran(tester, const CompleteProfileScreen());
      expect(find.byType(OnboardingSuccessScreen), findsOneWidget);
      expect(find.text(L10n.current.authSuccessInstitution), findsOneWidget);
    });

    testWidgets('professeur : questionnaire sur les matieres enseignees, « Continuer » inactif', (tester) async {
      sessionRole('teacher');
      await monterEcran(tester, const CompleteProfileScreen());
      final l = L10n.current;
      expect(find.text(l.authTeacherSubjectsTitle), findsOneWidget);
      expect(find.text(l.authTeacherSubjectsHint), findsOneWidget);
      expect(tester.widget<WinButton>(_bouton(l.commonContinue)).onTap, isNull);
      expect(find.byType(OnboardingSuccessScreen), findsNothing);
    });

    testWidgets('parent : questionnaire dedie, pas l\'ecran de succes', (tester) async {
      sessionRole('parent');
      await monterEcran(tester, const CompleteProfileScreen());
      expect(find.byType(OnboardingSuccessScreen), findsNothing);
      expect(find.text(L10n.current.authStudentLevelTitle), findsNothing);
      expect(find.text(L10n.current.authTeacherSubjectsTitle), findsNothing);
      expect(find.byType(WinButton), findsWidgets);
    });

    testWidgets('role inconnu ou absent : parcours eleve par defaut', (tester) async {
      sessionRole('autre');
      await monterEcran(tester, const CompleteProfileScreen());
      expect(find.text(L10n.current.authStudentLevelTitle), findsOneWidget);
    });

    testWidgets('chargement du role : indicateur avant lecture de la session', (tester) async {
      sessionRole('student');
      telephone(tester);
      await monter(tester, ecran(const CompleteProfileScreen()));
      expect(find.byType(WinLoadingState), findsOneWidget);
      await reseau(tester);
      expect(find.byType(WinLoadingState), findsNothing);
    });
  });
}
