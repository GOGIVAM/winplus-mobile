import 'package:flutter/material.dart';

/// WINPLUS — Modèles de données.

enum WinRole { student, parent, teacher, institution }

enum ContentType { epreuve, correction, quiz, livre, pack }

String contentTypeLabel(ContentType t) => switch (t) {
      ContentType.epreuve => 'Épreuve',
      ContentType.correction => 'Correction',
      ContentType.quiz => 'Quiz',
      ContentType.livre => 'Livre',
      ContentType.pack => 'Pack',
    };

class Subject {
  final String id, name, short;
  final Color color;
  final IconData icon;
  const Subject(this.id, this.name, this.short, this.color, this.icon);
}

class Content {
  final String id, title, subjectId, exam, level;
  final ContentType type;
  final int year, price, rating100, ratings, downloads;
  final bool free;
  bool fav;
  final String? aiReco;
  final int difficulty;
  Content({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.exam,
    required this.level,
    required this.type,
    required this.year,
    required this.price,
    required this.rating100,
    required this.ratings,
    required this.downloads,
    required this.free,
    this.fav = false,
    this.aiReco,
    this.difficulty = 3,
  });

  double get rating => rating100 / 10.0;
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explain;
  const QuizQuestion(this.question, this.options, this.answer, this.explain);
}

class Quiz {
  final String id, title, subjectId;
  final List<QuizQuestion> questions;
  const Quiz({required this.id, required this.title, required this.subjectId, required this.questions});
}

class Child {
  final String id, name, level, lastActive, studyWeek;
  final int streak, weekScore, quizDone, progress;
  final String trend;
  final String alertType, alertMsg;
  const Child({
    required this.id,
    required this.name,
    required this.level,
    required this.lastActive,
    required this.studyWeek,
    required this.streak,
    required this.weekScore,
    required this.quizDone,
    required this.progress,
    required this.trend,
    required this.alertType,
    required this.alertMsg,
  });
}

class AppNotification {
  final String id, type, title, body, time, group;
  final bool unread;
  const AppNotification(this.id, this.type, this.title, this.body, this.time, this.group, this.unread);
}

class RoleInfo {
  final WinRole role;
  final String label, description;
  final IconData icon;
  final Color color;
  const RoleInfo(this.role, this.label, this.description, this.icon, this.color);
}

class ProfContent {
  final String title, type, status;
  final int downloads;
  final double rating;
  final int revenue;
  const ProfContent(this.title, this.type, this.status, this.downloads, this.rating, this.revenue);
}

class Group {
  final String id, name, level;
  final int students, activity, avgScore;
  const Group(this.id, this.name, this.students, this.activity, this.avgScore, this.level);
}

/// Formate un entier en XAF avec séparateur insécable (ex: 8 000).
String fmtXaf(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u00a0');
    buf.write(s[i]);
  }
  return buf.toString();
}
