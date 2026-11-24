import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/parent_service.dart';

/// Derniere activite d'un enfant, deduite des statistiques du serveur
/// (inactivityDays, currentStreak) : plus jamais « actif maintenant » d'office.
void main() {
  DateTime jour(int joursAvant) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day).subtract(Duration(days: joursAvant));
  }

  test('actif aujourd\'hui (serie en cours) : derniere activite aujourd\'hui', () {
    final s = ApiChildStats.fromJson({'inactivityDays': 0, 'currentStreak': 3});
    expect(s.lastActiveAt, jour(0));
  });

  test('inactif depuis 9 jours : derniere activite il y a 9 jours', () {
    final s = ApiChildStats.fromJson({'inactivityDays': 9, 'currentStreak': 0});
    expect(s.lastActiveAt, jour(9));
  });

  test('jamais actif (0 jour, aucune serie, rien cette semaine) : aucune date', () {
    final s = ApiChildStats.fromJson({'inactivityDays': 0, 'currentStreak': 0});
    expect(s.lastActiveAt, isNull);
  });

  test('quiz cette semaine mais serie cassee : il y a bien eu une activite', () {
    final s = ApiChildStats.fromJson({'inactivityDays': 0, 'currentStreak': 0, 'quizzesThisWeek': 2});
    expect(s.lastActiveAt, jour(0));
  });
}
