import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/student/achievements_screen.dart';
import 'package:winplus/student/download_history_screen.dart';
import 'package:winplus/student/favorites_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Date relative a l'horloge de la machine : la regle d'affichage testee
/// (« aujourd'hui », « il y a N jours ») ne depend que de l'ecart, jamais de la
/// date du jour elle-meme.
String _ilYa(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

void main() {
  late FauxReseau faux;

  setUpAll(initialiserDates);
  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('FavoritesScreen', () {
    testWidgets('chargement : un indicateur de progression avant la reponse', (tester) async {
      faux.repond('GET', '/favorites', []);
      telephone(tester);
      await monter(tester, ecran(const FavoritesScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      expect(chargement, findsNothing);
    });

    testWidgets('liste vide : message et bouton « Explorer »', (tester) async {
      faux.repond('GET', '/favorites', []);
      await monterEcran(tester, const FavoritesScreen());
      expect(find.text(L10n.current.studentFavEmpty), findsOneWidget);
      expect(find.widgetWithText(WinButton, L10n.current.studentFavExplore), findsOneWidget);
    });

    testWidgets('erreur serveur : message et « Reessayer » qui recharge', (tester) async {
      faux.repond('GET', '/favorites', {'error': 'x'}, statut: 500);
      await monterEcran(tester, const FavoritesScreen());
      expect(find.text(L10n.current.studentFavLoadError), findsOneWidget);
      faux.repond('GET', '/favorites', [
        {'id': 1, 'subjectId': 4, 'subjectTitle': 'Maths BAC', 'addedAt': '2026-01-05T10:00:00Z'},
      ]);
      await tester.tap(find.widgetWithText(WinButton, L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text('Maths BAC'), findsOneWidget);
      expect(find.text(L10n.current.studentFavLoadError), findsNothing);
    });

    testWidgets('favoris : compteur, titres et date d\'ajout', (tester) async {
      faux.repond('GET', '/favorites', [
        {'id': 1, 'subjectId': 4, 'subjectTitle': 'Maths BAC', 'addedAt': '2026-01-05T10:00:00Z'},
        {'id': 2, 'subjectId': 5, 'subjectTitle': 'Physique BEPC', 'addedAt': '2026-01-06T10:00:00Z'},
      ]);
      final abo = await abonnementAvecDroits(tester, faux, {'favorites.max': -1});
      await monterEcran(tester, const FavoritesScreen(), abonnement: abo);
      expect(find.text(L10n.current.studentFavCount(2)), findsOneWidget);
      expect(find.text('Maths BAC'), findsOneWidget);
      expect(find.text('Physique BEPC'), findsOneWidget);
      expect(find.text(L10n.current.studentFavAddedOn('05/01/2026')), findsOneWidget);
      expect(find.text(L10n.current.studentFavLimit(-1)), findsNothing);
    });

    testWidgets('limite du plan atteinte : avertissement avec le maximum', (tester) async {
      faux.repond('GET', '/favorites', [
        {'id': 1, 'subjectId': 4, 'subjectTitle': 'A', 'addedAt': '2026-01-05T10:00:00Z'},
        {'id': 2, 'subjectId': 5, 'subjectTitle': 'B', 'addedAt': '2026-01-05T10:00:00Z'},
      ]);
      final abo = await abonnementAvecDroits(tester, faux, {'favorites.max': 2});
      await monterEcran(tester, const FavoritesScreen(), abonnement: abo);
      expect(find.text(L10n.current.studentFavLimit(2)), findsOneWidget);
    });

    testWidgets('retirer un favori appelle le serveur et le fait disparaitre', (tester) async {
      faux.repond('GET', '/favorites', [
        {'id': 7, 'subjectId': 4, 'subjectTitle': 'Maths BAC', 'addedAt': '2026-01-05T10:00:00Z'},
      ]);
      faux.repond('DELETE', '/favorites/7', {});
      final abo = await abonnementAvecDroits(tester, faux, {'favorites.max': -1});
      await monterEcran(tester, const FavoritesScreen(), abonnement: abo);
      await tester.tap(find.byIcon(PhosphorIconsFill.heart));
      await reseau(tester);
      expect(faux.recues('DELETE', '/favorites/7'), hasLength(1));
      expect(find.text('Maths BAC'), findsNothing);
    });

    testWidgets('le bouton d\'actualisation relance le chargement', (tester) async {
      faux.repond('GET', '/favorites', []);
      await monterEcran(tester, const FavoritesScreen());
      expect(faux.recues('GET', '/favorites'), hasLength(1));
      await tester.tap(find.byIcon(PhosphorIconsRegular.arrowClockwise));
      await reseau(tester);
      expect(faux.recues('GET', '/favorites'), hasLength(2));
    });
  });

  group('AchievementsScreen', () {
    void repondre(FauxReseau f, {int serie = 4, List<Map<String, dynamic>> badges = const []}) {
      f.repond('GET', '/users/profile/statistics', {'currentStreak': serie});
      f.repond('GET', '/badges', {'data': badges});
    }

    testWidgets('chargement puis serie, compteur de badges et badges debloques / verrouilles', (tester) async {
      repondre(faux, badges: [
        {'code': 'first_quiz_passed', 'title': 'Premier quiz', 'description': 'Reussis un quiz', 'unlocked': true, 'unlockedAt': '5 janvier'},
        {'code': 'streak_30', 'title': 'Serie de 30', 'description': 'Reviens 30 jours', 'unlocked': false},
      ]);
      telephone(tester);
      await monter(tester, ecran(const AchievementsScreen()));
      expect(chargement, findsOneWidget);
      await reseau(tester);
      final l = L10n.current;
      expect(find.text(l.studentAchBadgesUnlocked(1, 2)), findsOneWidget);
      expect(find.text(l.studentAchStreakDays(4)), findsOneWidget);
      expect(find.text('Premier quiz'), findsOneWidget);
      expect(find.text('Serie de 30'), findsOneWidget);
      expect(find.text(l.studentAchUnlocked), findsOneWidget);
      expect(find.text(l.studentAchLocked), findsOneWidget);
      expect(find.byIcon(PhosphorIconsFill.lock), findsOneWidget);
      expect(find.text('5 janvier'), findsOneWidget);
    });

    testWidgets('aucun badge : 0 / 0 et pas d\'avertissement', (tester) async {
      repondre(faux, serie: 0);
      await monterEcran(tester, const AchievementsScreen());
      expect(find.text(L10n.current.studentAchBadgesUnlocked(0, 0)), findsOneWidget);
      expect(find.text(L10n.current.studentAchStreakLoadError), findsNothing);
    });

    testWidgets('erreur reseau : avertissement explicite, jamais de badges de demonstration', (tester) async {
      faux.repond('GET', '/users/profile/statistics', {}, statut: 500);
      faux.repond('GET', '/badges', {}, statut: 500);
      await monterEcran(tester, const AchievementsScreen());
      expect(find.text(L10n.current.studentAchStreakLoadError), findsOneWidget);
      expect(find.text(L10n.current.studentAchBadgesUnlocked(0, 0)), findsOneWidget);
      expect(find.byType(WinCard), findsOneWidget, reason: 'seule la carte d\'en-tete reste');
    });
  });

  group('DownloadHistoryScreen', () {
    testWidgets('historique vide : message et indication', (tester) async {
      faux.repond('GET', '/users/me/downloads', []);
      await monterEcran(tester, const DownloadHistoryScreen());
      expect(find.text(L10n.current.studentHistEmpty), findsOneWidget);
      expect(find.text(L10n.current.studentHistEmptyHint), findsOneWidget);
    });

    testWidgets('erreur : message puis rechargement par « Reessayer »', (tester) async {
      faux.repond('GET', '/users/me/downloads', {}, statut: 500);
      await monterEcran(tester, const DownloadHistoryScreen());
      expect(find.text(L10n.current.studentHistLoadError), findsOneWidget);
      faux.repond('GET', '/users/me/downloads', []);
      await tester.tap(find.widgetWithText(WinButton, L10n.current.commonRetry));
      await reseau(tester);
      expect(find.text(L10n.current.studentHistLoadError), findsNothing);
      expect(find.text(L10n.current.studentHistEmpty), findsOneWidget);
    });

    testWidgets('documents regroupes par jour : aujourd\'hui et hier', (tester) async {
      faux.repond('GET', '/users/me/downloads', [
        {'subjectId': 1, 'title': 'Epreuve de maths', 'downloadedAt': _ilYa(const Duration(hours: 2)), 'category': 'epreuve'},
        {'subjectId': 2, 'title': 'Cours de physique', 'downloadedAt': _ilYa(const Duration(hours: 30)), 'category': 'cours'},
      ]);
      await monterEcran(tester, const DownloadHistoryScreen());
      final l = L10n.current;
      expect(find.text('Epreuve de maths'), findsOneWidget);
      expect(find.text('Cours de physique'), findsOneWidget);
      expect(find.text(l.commonToday), findsOneWidget);
      expect(find.text(l.commonYesterday), findsOneWidget);
      expect(find.text(l.studentHistFileCount(2, l.studentHistPeriod30d)), findsOneWidget);
    });

    testWidgets('le filtre « 7 jours » masque un document plus ancien et l\'etat vide cite la periode', (tester) async {
      faux.repond('GET', '/users/me/downloads', [
        {'subjectId': 1, 'title': 'Ancien document', 'downloadedAt': _ilYa(const Duration(days: 20))},
      ]);
      await monterEcran(tester, const DownloadHistoryScreen());
      expect(find.text('Ancien document'), findsOneWidget);
      await tester.tap(find.text(L10n.current.studentHistPeriod7d));
      await pomper(tester);
      expect(find.text('Ancien document'), findsNothing);
      expect(find.text(L10n.current.studentHistEmptyPeriod(L10n.current.studentHistPeriod7d)), findsOneWidget);
    });
  });
}
