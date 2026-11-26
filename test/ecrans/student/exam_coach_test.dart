import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/local_cache_service.dart';
import 'package:winplus/student/exam_coach_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

String _planJson() => jsonEncode({
      'weeks': [
        {
          'days': [
            {'day': 1, 'focus_area': 'Algebre', 'duration_minutes': 90, 'activity_type': 'study'},
            {'day': 2, 'focus_area': 'Repos', 'duration_minutes': 0, 'activity_type': 'rest'},
          ],
        },
      ],
    });

void main() {
  late FauxReseau faux;
  late Directory dossier;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dossier = ouvrirDossierHive();
    await Hive.openBox(LocalCacheService.examCoachBoxName, bytes: Uint8List(0));
  });
  tearDownAll(() => fermerHive(dossier));

  setUp(() async {
    faux = preparerEnvironnement();
    await LocalCacheService.examCoach.clear();
  });

  testWidgets('sans le droit Exam Coach : ecran verrouille et bouton « voir les plans »', (tester) async {
    await monterEcran(tester, const ExamCoachScreen());
    expect(find.text(L10n.current.studentCoachLocked), findsOneWidget);
    expect(_bouton(L10n.current.studentCoachSeePlans), findsOneWidget);
    expect(faux.recues('GET', '/exam-coach/active'), isEmpty);
  });

  testWidgets('« voir les plans » ouvre la feuille de mise a niveau', (tester) async {
    await monterEcran(tester, const ExamCoachScreen());
    await tester.tap(_bouton(L10n.current.studentCoachSeePlans));
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.subFeatureOfPlan('Standard')), findsOneWidget);
    // La feuille ouverte a lance ses minuteurs (animation, chargement des
    // offres) : on la retire et on les laisse finir.
    await monter(tester, const SizedBox());
    await pomper(tester, const Duration(seconds: 2));
  });

  testWidgets('droit present et aucun plan (404) : formulaire de configuration, generation inactive sans date', (tester) async {
    faux.repond('GET', '/exam-coach/active', {}, statut: 404);
    final abo = await abonnementAvecDroits(tester, faux, {'ai.feature.exam_coach': true});
    await monterEcran(tester, const ExamCoachScreen(), abonnement: abo);
    final l = L10n.current;
    expect(find.text(l.studentCoachIntro), findsOneWidget);
    expect(find.text(l.studentCoachTargetExam), findsOneWidget);
    expect(find.text(l.studentCoachPickDate), findsOneWidget);
    final generer = _bouton(l.studentCoachGenerate);
    await tester.ensureVisible(generer);
    await tester.tap(generer);
    await reseau(tester);
    expect(faux.recues('POST', '/exam-coach'), isEmpty);
  });

  testWidgets('plan actif : jours restants, avancement, semaine et jours de repos', (tester) async {
    final exam = DateTime.now().add(const Duration(days: 40)).toUtc().toIso8601String();
    faux.repond('GET', '/exam-coach/active', {
      'id': 3,
      'examType': 'BAC_C',
      'examDate': exam,
      'hoursPerDay': 2,
      'confidenceScore': 0.8,
      'isActive': true,
      'planJson': _planJson(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'completedDays': [],
    });
    final abo = await abonnementAvecDroits(tester, faux, {'ai.feature.exam_coach': true});
    await monterEcran(tester, const ExamCoachScreen(), abonnement: abo);
    final l = L10n.current;
    expect(find.text(l.studentCoachThisWeek), findsOneWidget);
    expect(find.text('Algebre'), findsOneWidget);
    expect(find.text('1 h 30'), findsOneWidget);
    expect(find.text(l.studentCoachRest), findsOneWidget);
    expect(find.text(l.studentCoachReliability(80)), findsOneWidget);
    expect(_bouton(l.studentCoachMarkToday), findsOneWidget);
  });

  testWidgets('« marquer aujourd\'hui » envoie le jour du plan puis recharge', (tester) async {
    faux.repond('GET', '/exam-coach/active', {
      'id': 3,
      'examType': 'BAC_C',
      'examDate': DateTime.now().add(const Duration(days: 40)).toUtc().toIso8601String(),
      'planJson': _planJson(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    faux.repond('PUT', '/exam-coach/3/complete-day', {});
    final abo = await abonnementAvecDroits(tester, faux, {'ai.feature.exam_coach': true});
    await monterEcran(tester, const ExamCoachScreen(), abonnement: abo);
    final b = _bouton(L10n.current.studentCoachMarkToday);
    await tester.ensureVisible(b);
    await tester.tap(b);
    await reseau(tester);
    expect(faux.recues('PUT', '/exam-coach/3/complete-day').single.data, {'dayNumber': 1});
    expect(faux.recues('GET', '/exam-coach/active'), hasLength(2));
  });

  testWidgets('supprimer le plan : confirmation puis retour au formulaire', (tester) async {
    faux.repond('GET', '/exam-coach/active', {
      'id': 3,
      'examType': 'BAC_C',
      'examDate': DateTime.now().add(const Duration(days: 40)).toUtc().toIso8601String(),
      'planJson': _planJson(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    faux.repond('DELETE', '/exam-coach/3', {});
    final abo = await abonnementAvecDroits(tester, faux, {'ai.feature.exam_coach': true});
    await monterEcran(tester, const ExamCoachScreen(), abonnement: abo);
    final b = _bouton(L10n.current.studentCoachDeletePlan);
    await tester.ensureVisible(b);
    await tester.tap(b);
    await pomper(tester, const Duration(milliseconds: 400));
    expect(find.text(L10n.current.studentCoachDeleteTitle), findsOneWidget);
    await tester.tap(find.text(L10n.current.commonDelete));
    await reseau(tester);
    expect(faux.recues('DELETE', '/exam-coach/3'), hasLength(1));
    expect(find.text(L10n.current.studentCoachTargetExam), findsOneWidget);
  });
}
