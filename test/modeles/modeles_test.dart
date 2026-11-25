import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';

import '../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Content _contenu({int rating100 = 45}) => Content(
      id: 'c1',
      title: 'Epreuve de maths',
      subjectId: 'math',
      exam: 'BAC',
      level: 'Terminale',
      type: ContentType.epreuve,
      year: 2024,
      price: 500,
      rating100: rating100,
      ratings: 10,
      downloads: 3,
      free: false,
    );

void main() {
  setUpAll(initialiserDates);
  setUp(() => L10n.locale = const Locale('fr'));
  tearDown(() => L10n.locale = const Locale('fr'));

  group('Content', () {
    test('valeurs par defaut : pas favori, difficulte 3, aucun avis, pas de corrige', () {
      final c = _contenu();
      expect(c.fav, isFalse);
      expect(c.difficulty, 3);
      expect(c.reviews, isEmpty);
      expect(c.hasCorrection, isFalse);
      expect(c.aiReco, isNull);
      expect(c.description, isNull);
      expect(c.teacher, isNull);
    });

    test('la note est la note sur 100 divisee par 10', () {
      expect(_contenu(rating100: 45).rating, 4.5);
      expect(_contenu(rating100: 0).rating, 0.0);
      expect(_contenu(rating100: 50).rating, 5.0);
    });

    test('le favori est modifiable', () {
      final c = _contenu();
      c.fav = true;
      expect(c.fav, isTrue);
    });
  });

  group('Subject', () {
    const maths = Subject('math', 'Mathématiques', 'Maths', Colors.red, PhosphorIconsRegular.plus);

    test('en francais, le nom affiche est le nom francais', () {
      expect(maths.name, 'Mathématiques');
      expect(maths.short, 'Maths');
    });

    test('en anglais, le nom complet est traduit et l\'abrege reste Maths', () {
      L10n.locale = const Locale('en');
      expect(maths.name, 'Mathematics');
      expect(maths.short, 'Maths');
    });

    test('une matiere inconnue est rendue telle quelle dans les deux langues', () {
      const zoo = Subject('zoo', 'Zoologie', 'Zoo', Colors.blue, PhosphorIconsRegular.pawPrint);
      expect(zoo.name, 'Zoologie');
      L10n.locale = const Locale('en');
      expect(zoo.name, 'Zoologie');
      expect(zoo.short, 'Zoo');
    });

    test('le nom francais d\'origine reste disponible pour l\'API', () {
      L10n.locale = const Locale('en');
      expect(maths.nameFr, 'Mathématiques');
    });
  });

  group('contentTypeLabel', () {
    test('libelles francais', () {
      expect(contentTypeLabel(ContentType.epreuve), 'Épreuve');
      expect(contentTypeLabel(ContentType.correction), 'Correction');
      expect(contentTypeLabel(ContentType.quiz), 'Quiz');
      expect(contentTypeLabel(ContentType.livre), 'Livre');
      expect(contentTypeLabel(ContentType.pack), 'Pack');
    });

    test('libelles anglais', () {
      L10n.locale = const Locale('en');
      expect(contentTypeLabel(ContentType.epreuve), 'Paper');
      expect(contentTypeLabel(ContentType.livre), 'Book');
      expect(contentTypeLabel(ContentType.correction), 'Correction');
    });
  });

  group('Quiz', () {
    test('un quiz dure 15 minutes par defaut et une question n\'a pas d\'identifiant serveur', () {
      const q = QuizQuestion('2+2 ?', ['3', '4'], 1, 'parce que');
      expect(q.id, isNull);
      const quiz = Quiz(id: 'q', title: 'T', subjectId: 'math', questions: [q]);
      expect(quiz.durationMinutes, 15);
      expect(quiz.questions.single.answer, 1);
    });

    test('une session demarre a la premiere question, non terminee', () {
      const s = QuizSession(quizId: 'q', answers: [null, 2]);
      expect(s.currentIndex, 0);
      expect(s.finished, isFalse);
      expect(s.answers, [null, 2]);
    });

    test('score d\'un resultat : pourcentage de bonnes reponses', () {
      const r = QuizResult(quizId: 'q', quizTitle: 'T', correct: 3, total: 4, durationSeconds: 60, answers: [], date: '2026-01-01');
      expect(r.score, 75.0);
    });

    test('score d\'un resultat sans question : 0 et jamais de division par zero', () {
      const r = QuizResult(quizId: 'q', quizTitle: 'T', correct: 0, total: 0, durationSeconds: 0, answers: [], date: '2026-01-01');
      expect(r.score, 0);
    });
  });

  group('ActiveSubscription', () {
    ActiveSubscription abo(PlanTier t, {int used = 0, int limit = 5}) => ActiveSubscription(
          tier: t,
          planName: 'Plan',
          expiresAt: '2026-12-31',
          autoRenew: false,
          downloadsUsed: used,
          downloadsLimit: limit,
        );

    test('premium et famille sont premium, libre et standard ne le sont pas', () {
      expect(abo(PlanTier.premium).isPremium, isTrue);
      expect(abo(PlanTier.famille).isPremium, isTrue);
      expect(abo(PlanTier.standard).isPremium, isFalse);
      expect(abo(PlanTier.libre).isPremium, isFalse);
    });

    test('seul le palier libre est gratuit', () {
      expect(abo(PlanTier.libre).isFree, isTrue);
      expect(abo(PlanTier.standard).isFree, isFalse);
    });

    test('valeurs par defaut des quotas', () {
      final a = abo(PlanTier.libre);
      expect(a.downloadsLimit, 5);
      expect(a.quizDailyLimit, 3);
      expect(a.aiUsageMultiplier, 1);
      expect(a.aiQuotaExhausted, isFalse);
    });

    test('ratio de telechargements : utilise sur limite, 0 si limite nulle', () {
      expect(abo(PlanTier.libre, used: 2, limit: 5).downloadRatio, closeTo(0.4, 1e-9));
      expect(abo(PlanTier.libre, used: 3, limit: 0).downloadRatio, 0);
    });
  });

  group('Planning', () {
    test('total de minutes de la semaine : somme des jours', () {
      const w = StudyWeek([StudyDay('Lun', 30, 60), StudyDay('Mar', 45, 60), StudyDay('Mer', 0, 60)]);
      expect(w.totalMinutes, 75);
    });

    test('une semaine vide totalise 0 minute', () {
      expect(const StudyWeek([]).totalMinutes, 0);
    });

    test('une semaine de plan n\'est pas terminee par defaut', () {
      expect(const StudyWeekPlan('Semaine 1', ['Algebre']).done, isFalse);
    });
  });

  group('Plans tarifaires et divers', () {
    test('un plan n\'est pas populaire et n\'a pas de limite par defaut', () {
      const p = PricingPlan(tier: PlanTier.standard, name: 'Standard', tagline: 't', priceMonthly: 2000, priceYearly: 20000, features: [PricingFeature('Quiz')]);
      expect(p.popular, isFalse);
      expect(p.downloadLimit, isNull);
      expect(p.quizDailyLimit, isNull);
      expect(p.aiMessages, isNull);
      expect(p.features.single.included, isTrue);
      expect(p.features.single.detail, isNull);
    });

    test('les roles ont les noms envoyes a l\'API lors de l\'inscription', () {
      expect(WinRole.values.map((r) => r.name), ['student', 'parent', 'teacher', 'institution']);
    });

    test('ordre des paliers', () {
      expect(PlanTier.values.map((t) => t.name), ['libre', 'standard', 'premium', 'famille']);
    });

    test('resultat de commande : message et transaction optionnels', () {
      const r = OrderResult(success: false, amount: 1500);
      expect(r.transactionId, isNull);
      expect(r.message, isNull);
      expect(r.amount, 1500);
    });

    test('un badge est verrouille par defaut', () {
      const b = AchievementBadge('b', 'Nom', 'Desc', PhosphorIconsFill.star, Colors.amber);
      expect(b.unlocked, isFalse);
      expect(b.unlockedAt, isNull);
    });

    test('une recommandation IA n\'a pas d\'identifiant de contenu par defaut', () {
      const r = AiRecommendation(RecoType.weakSubject, 'Titre', 'Corps');
      expect(r.contentId, isNull);
    });
  });

  group('fmtXaf', () {
    test('groupe les milliers avec une espace en francais', () {
      expect(fmtXaf(0), '0');
      expect(fmtXaf(999), '999');
      expect(fmtXaf(8000), '8 000');
      expect(fmtXaf(1234567), '1 234 567');
    });

    test('groupe les milliers avec une virgule en anglais', () {
      L10n.locale = const Locale('en');
      expect(fmtXaf(8000), '8,000');
    });
  });
}
