import 'package:flutter/material.dart';

/// WINPLUS  Modèles de données.

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
  final String? aiReco, description, teacher;
  final int difficulty;
  final List<ContentReview> reviews;
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
    this.description,
    this.teacher,
    this.difficulty = 3,
    this.reviews = const [],
  });

  double get rating => rating100 / 10.0;
}

class ContentReview {
  final String author, text;
  final int rating100;
  final String date;
  const ContentReview(this.author, this.text, this.rating100, this.date);
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
  final int durationMinutes;
  const Quiz(
      {required this.id,
      required this.title,
      required this.subjectId,
      required this.questions,
      this.durationMinutes = 15});
}

class QuizSession {
  final String quizId;
  final List<int?> answers; // null = pas encore répondu
  final int currentIndex;
  final bool finished;
  const QuizSession({
    required this.quizId,
    required this.answers,
    this.currentIndex = 0,
    this.finished = false,
  });
}

class QuizResult {
  final String quizId, quizTitle;
  final int correct, total, durationSeconds;
  final List<int?> answers;
  final String date;
  const QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.correct,
    required this.total,
    required this.durationSeconds,
    required this.answers,
    required this.date,
  });
  double get score => total == 0 ? 0 : correct / total * 100;
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
  const AppNotification(this.id, this.type, this.title, this.body, this.time,
      this.group, this.unread);
}

class RoleInfo {
  final WinRole role;
  final String label, description;
  final IconData icon;
  final Color color;
  const RoleInfo(
      this.role, this.label, this.description, this.icon, this.color);
}

class ProfContent {
  final String title, type, status;
  final int downloads;
  final double rating;
  final int revenue;
  const ProfContent(this.title, this.type, this.status, this.downloads,
      this.rating, this.revenue);
}

class Group {
  final String id, name, level;
  final int students, activity, avgScore;
  const Group(this.id, this.name, this.students, this.activity, this.avgScore,
      this.level);
}

// ---- ABONNEMENT ----

enum PlanTier { libre, standard, premium, famille }

class PricingFeature {
  final String label;
  final bool included;
  final String? detail;
  const PricingFeature(this.label, {this.included = true, this.detail});
}

class PricingPlan {
  final PlanTier tier;
  final String name, tagline;
  final int priceMonthly; // XAF
  final int priceYearly; // XAF
  final bool popular;
  final List<PricingFeature> features;
  final int? downloadLimit; // null = illimité
  final int? quizDailyLimit;
  final int? aiMessages;
  const PricingPlan({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    this.popular = false,
    required this.features,
    this.downloadLimit,
    this.quizDailyLimit,
    this.aiMessages,
  });
}

class ActiveSubscription {
  final PlanTier tier;
  final String planName;
  final String expiresAt;
  final bool autoRenew;
  final int downloadsUsed, downloadsLimit;
  final int quizUsedToday, quizDailyLimit;
  final int aiMessagesUsed, aiMessagesLimit;
  const ActiveSubscription({
    required this.tier,
    required this.planName,
    required this.expiresAt,
    required this.autoRenew,
    this.downloadsUsed = 0,
    this.downloadsLimit = 5,
    this.quizUsedToday = 0,
    this.quizDailyLimit = 3,
    this.aiMessagesUsed = 0,
    this.aiMessagesLimit = 50,
  });

  bool get isPremium =>
      tier == PlanTier.premium || tier == PlanTier.famille;
  bool get isFree => tier == PlanTier.libre;
  double get downloadRatio =>
      downloadsLimit == 0 ? 0 : downloadsUsed / downloadsLimit;
}

// ---- CONTENU EN COURS / APPRENTISSAGE ----

class InProgressContent {
  final String contentId, title, subjectId;
  final int progressPct;
  final String lastOpened;
  const InProgressContent(this.contentId, this.title, this.subjectId,
      this.progressPct, this.lastOpened);
}

// ---- RECOMMANDATIONS IA ----

enum RecoType { weakSubject, suggestedQuiz, suggestedContent, examPlan }

class AiRecommendation {
  final RecoType type;
  final String title, body;
  final String? contentId;
  const AiRecommendation(this.type, this.title, this.body, {this.contentId});
}

// ---- ACTIVITÉ ----

enum ActivityType { quiz, download, session, badge, purchase }

class ActivityEvent {
  final ActivityType type;
  final String title, detail, time;
  const ActivityEvent(this.type, this.title, this.detail, this.time);
}

// ---- PLANNING ----

class StudyDay {
  final String label; // Lun, Mar…
  final int minutes;
  final int goalMinutes;
  const StudyDay(this.label, this.minutes, this.goalMinutes);
}

class StudyWeek {
  final List<StudyDay> days;
  const StudyWeek(this.days);
  int get totalMinutes => days.fold(0, (s, d) => s + d.minutes);
}

class StudyPlan {
  final String examName;
  final String examDate;
  final int hoursPerDay;
  final List<StudyWeekPlan> weeks;
  const StudyPlan(this.examName, this.examDate, this.hoursPerDay, this.weeks);
}

class StudyWeekPlan {
  final String label; // "Semaine 1"
  final List<String> topics;
  final bool done;
  const StudyWeekPlan(this.label, this.topics, {this.done = false});
}

// ---- PANIER / ACHAT ----

class CartItem {
  final String contentId, title;
  final int price;
  const CartItem(this.contentId, this.title, this.price);
}

class OrderResult {
  final bool success;
  final String? transactionId, message;
  final int amount;
  const OrderResult(
      {required this.success,
      this.transactionId,
      this.message,
      required this.amount});
}

// ---- CERTIFICATS ----

class Certificate {
  final String id, title, issuedAt, verifyUrl;
  final int score;
  const Certificate(
      this.id, this.title, this.issuedAt, this.verifyUrl, this.score);
}

// ---- PROFESSEUR : CORRECTIONS ----

class Submission {
  final String id, studentName, contentTitle, submittedAt;
  final bool corrected;
  final int? score;
  const Submission(this.id, this.studentName, this.contentTitle,
      this.submittedAt, this.corrected,
      {this.score});
}

// ---- INSTITUTION : ÉLÈVES À RISQUE ----

class AtRiskStudent {
  final String id, name, level;
  final int score, absences;
  final String risk; // 'high', 'medium'
  final String alert;
  const AtRiskStudent(this.id, this.name, this.level, this.score,
      this.absences, this.risk, this.alert);
}

// ---- GAMIFICATION ----

class AchievementBadge {
  final String id, name, description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final String? unlockedAt;
  const AchievementBadge(this.id, this.name, this.description, this.icon, this.color,
      {this.unlocked = false, this.unlockedAt});
}

// ---- PROFIL UTILISATEUR ----

class UserProfile {
  final String id, name, email, phone;
  final WinRole role;
  final String level, filiere, examObjectif;
  final String avatarInitials;
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.level,
    required this.filiere,
    required this.examObjectif,
    required this.avatarInitials,
  });
}

// ---- EXAMENS À VENIR ----

class ExamCountdown {
  final String name, date;
  final int daysLeft;
  final String subject;
  const ExamCountdown(this.name, this.date, this.daysLeft, this.subject);
}

// ---- PARENT : ÉVÈNEMENTS ----

class ChildEvent {
  final String childName, title, date, type;
  const ChildEvent(this.childName, this.title, this.date, this.type);
}

// ---- ENGAGEMENT SCORE ----

class EngagementScore {
  final String childId;
  final int score; // 0–100
  final int prevScore;
  final String trend; // 'up', 'down', 'stable'
  const EngagementScore(this.childId, this.score, this.prevScore, this.trend);
}

/// Formate un entier en XAF avec séparateur insécable (ex: 8 000).
String fmtXaf(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
