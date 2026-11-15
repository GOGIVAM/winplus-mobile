import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart' show fmtXaf;
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/widgets/mobile_home.dart';
import 'package:winplus/shared/subscription/subscription_notifier.dart';
import 'package:winplus/teacher/correction_queue_screen.dart';
import 'package:winplus/teacher/teacher_tabs.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Accueil du professeur (MobileHomeView) : « Pour toi », acces rapide,
/// bande de chiffres reels, revenus des quatre semaines et contenus recents.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  void routes({
    List<Map<String, dynamic>>? contenus,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>> copies = const [],
  }) {
    faux.repond('GET', '/teacher/contents/mine', contenus ?? []);
    faux.repond('GET', '/teacher/stats', stats ?? {'thisMonthRevenue': 0, 'activeStudents': 0});
    faux.repond('GET', '/teacher/corrections/pending', copies);
  }

  /// Ecran haut : les blocs du bas sont construits (et reveles) sans defilement.
  Future<void> monterHaut(WidgetTester tester, {SubscriptionNotifier? abonnement}) async {
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const TeacherDashTab(), abonnement: abonnement));
    await reseau(tester);
  }

  /// Fait defiler la bande des chiffres jusqu'a [cible].
  Future<void> chiffre(WidgetTester tester, Finder cible) async {
    final bande = find.descendant(
      of: find.byType(MobileStatsStrip),
      matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right),
    );
    await tester.scrollUntilVisible(cible, 120, scrollable: bande.first);
  }

  testWidgets('chargement : « — » et indicateur des contenus avant les reponses', (tester) async {
    routes();
    telephone(tester);
    tester.view.physicalSize = const Size(800, 3200);
    await monter(tester, ecran(const TeacherDashTab()));
    expect(find.text('—'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await reseau(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('chiffres reels : publies, revenu du mois, telechargements, note et eleves actifs', (tester) async {
    routes(
      contenus: [
        {'id': 1, 'title': 'Epreuve maths', 'status': 'published', 'downloadCount': 30, 'averageRating': 4.0, 'revenue': 2500},
        {'id': 2, 'title': 'Cours physique', 'status': 'published', 'downloadCount': 10, 'averageRating': 5.0},
        {'id': 3, 'title': 'Brouillon', 'status': 'draft', 'downloadCount': 0},
      ],
      stats: {'thisMonthRevenue': 45000, 'weeklyRevenue': [1000, 2000, 500, 3000], 'activeStudents': 12},
    );
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text('2'), findsWidgets, reason: 'deux contenus publies');
    expect(find.text('${fmtXaf(45000)} XAF'), findsOneWidget);
    await chiffre(tester, find.text('40'));
    expect(find.text('40'), findsOneWidget);
    await chiffre(tester, find.text('4.5'));
    expect(find.text('4.5'), findsOneWidget);
    await chiffre(tester, find.text('12'));
    expect(find.text('12'), findsOneWidget);
    expect(find.text(l.studentReportsWeekShort(4)), findsOneWidget);
  });

  testWidgets('contenus recents : trois au plus, avec revenu et telechargements', (tester) async {
    routes(contenus: [
      {'id': 1, 'title': 'A', 'status': 'published', 'downloadCount': 3, 'revenue': 1500},
      {'id': 2, 'title': 'B', 'status': 'draft'},
      {'id': 3, 'title': 'C', 'status': 'published'},
      {'id': 4, 'title': 'D', 'status': 'published'},
    ]);
    await monterHaut(tester);
    expect(find.text(L10n.current.teacherDashRecentContent), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('${fmtXaf(1500)} XAF'), findsOneWidget);
    expect(find.text(L10n.current.teacherDashDownloadsCount(3)), findsOneWidget);
  });

  testWidgets('aucun contenu : message dedie', (tester) async {
    routes();
    await monterHaut(tester);
    expect(find.text(L10n.current.teacherDashNoContent), findsOneWidget);
  });

  testWidgets('serveur en erreur : accueil vide, sans plantage ni indicateur perpetuel', (tester) async {
    await monterHaut(tester);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(L10n.current.teacherDashMonthRevenue), findsOneWidget);
    expect(find.text(L10n.current.teacherDashNoContent), findsOneWidget);
  });

  testWidgets('part du professeur : « — » sans le droit', (tester) async {
    routes();
    await monterHaut(tester);
    final l = L10n.current;
    await chiffre(tester, find.text(l.mobileHomeShare));
    expect(find.textContaining(' %'), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('avec le droit « part de revenus » : pourcentage et nom du plan', (tester) async {
    routes();
    final abo = await abonnementAvecDroits(tester, faux, {'teacher.revenue_share': 70}, plan: 'Pro');
    await monterHaut(tester, abonnement: abo);
    await chiffre(tester, find.text('70 %'));
    expect(find.text('70 %'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
  });

  testWidgets('copies a corriger : « Pour toi » les annonce, l\'acces rapide ouvre la file', (tester) async {
    routes(copies: [
      {'id': 1, 'studentName': 'Ada', 'contentTitle': 'T', 'corrected': false},
      {'id': 2, 'studentName': 'Bob', 'contentTitle': 'T', 'corrected': true, 'score': 12},
    ]);
    await monterHaut(tester);
    final l = L10n.current;
    expect(find.text(l.mobileHomeCorrectTitle(1)), findsOneWidget);
    await tester.tap(find.text(l.mobileHomeCorrections).first);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await reseau(tester);
    expect(find.byType(CorrectionQueueScreen), findsOneWidget);
  });

  testWidgets('aucune copie : « Pour toi » propose de publier', (tester) async {
    routes();
    await monterHaut(tester);
    expect(find.text(L10n.current.mobileHomePublishTitle), findsOneWidget);
  });
}
