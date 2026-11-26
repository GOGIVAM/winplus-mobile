import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/course_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('Modeles de formation', () {
    test('CourseListItem : valeurs par defaut et duree lisible', () {
      final c = CourseListItem.fromJson(<String, dynamic>{});
      expect(c.id, 0);
      expect(c.title, '');
      expect(c.price, 0.0);
      expect(c.isFree, isFalse);
      expect(c.shortDescription, isNull);
      expect(c.durationStr, '', reason: 'duree nulle : masquee (lot 1)');
      expect(CourseListItem.fromJson({'totalDurationMin': 125}).durationStr, '2 h 05');
      expect(CourseListItem.fromJson({'totalDurationMin': 120}).durationStr, '2 h');
      expect(CourseListItem.fromJson({'totalDurationMin': 45}).durationStr, '45 min');
    });

    test('CourseListItem lit un prix entier ou decimal', () {
      expect(CourseListItem.fromJson({'price': 1500}).price, 1500.0);
      expect(CourseListItem.fromJson({'price': 99.5, 'avgRating': 4}).price, 99.5);
      expect(CourseListItem.fromJson({'avgRating': 4}).avgRating, 4.0);
    });

    test('CourseLesson : type video par defaut et duree m:ss', () {
      final l = CourseLesson.fromJson({'id': 3, 'title': 'Intro', 'videoDurationSec': 605});
      expect(l.lessonType, 'video');
      expect(l.durationStr, '10:05');
      expect(l.isPreview, isFalse);
      expect(l.videoUrl, isNull);
      expect(CourseLesson.fromJson({'videoDurationSec': 59}).durationStr, '0:59');
    });

    test('CourseDetail : instructeur imbrique, sections, total de lecons et achat', () {
      final d = CourseDetail.fromJson({
        'id': 7,
        'title': 'Algebre',
        'price': 5000,
        'isFree': false,
        'instructor': {'name': 'Mme Ngo'},
        'requirements': ['Calculatrice'],
        'objectives': ['Resoudre', 'Factoriser'],
        'sections': [
          {
            'id': 1,
            'title': 'S1',
            'lessons': [
              {'id': 1, 'title': 'A'},
              {'id': 2, 'title': 'B'},
            ],
          },
          {
            'id': 2,
            'title': 'S2',
            'lessons': [
              {'id': 3, 'title': 'C'},
            ],
          },
        ],
        'purchaseBlockCode': 'already_purchased',
        'isOwner': true,
      });
      expect(d.instructorName, 'Mme Ngo');
      expect(d.requirements, ['Calculatrice']);
      expect(d.objectives, hasLength(2));
      expect(d.sections, hasLength(2));
      expect(d.totalLessons, 3);
      expect(d.isPaid, isTrue);
      expect(d.isOwner, isTrue);
      expect(d.isPurchased, isFalse);
      expect(d.purchaseBlockCode, 'already_purchased');
      expect(d.certificateEnabled, isTrue, reason: 'certificat active par defaut');
    });

    test('CourseDetail : une formation gratuite ou a prix nul n\'est pas payante', () {
      expect(CourseDetail.fromJson({'price': 5000, 'isFree': true}).isPaid, isFalse);
      expect(CourseDetail.fromJson({'price': 0, 'isFree': false}).isPaid, isFalse);
      final vide = CourseDetail.fromJson(<String, dynamic>{});
      expect(vide.instructorName, '');
      expect(vide.sections, isEmpty);
      expect(vide.totalLessons, 0);
      expect(vide.isEnrolled, isFalse);
      expect(vide.durationStr, '', reason: 'duree nulle : masquee (lot 1)');
    });

    test('CourseCurriculum : leçons aplaties, examen final facultatif', () {
      final c = CourseCurriculum.fromJson({
        'courseId': 4,
        'title': 'Physique',
        'progressPercent': 50,
        'sections': [
          {
            'id': 1,
            'lessons': [
              {'id': 1, 'isCompleted': true, 'lastPositionSec': 30, 'videoDurationSec': 61},
              {'id': 2},
            ],
          },
          {
            'id': 2,
            'lessons': [
              {'id': 3},
            ],
          },
        ],
        'finalExam': {'quizId': 9, 'available': true, 'bestScore': 72.5},
      });
      expect(c.progressPercent, 50.0);
      expect(c.allLessons.map((l) => l.id), [1, 2, 3]);
      expect(c.allLessons.first.isCompleted, isTrue);
      expect(c.allLessons.first.lastPositionSec, 30);
      expect(c.allLessons.first.durationStr, '1:01');
      expect(c.finalExam, isNotNull);
      expect(c.finalExam!.quizId, 9);
      expect(c.finalExam!.passScore, 50, reason: 'seuil par defaut');
      expect(c.finalExam!.available, isTrue);
      expect(c.finalExam!.passed, isFalse);
      expect(c.finalExam!.bestScore, 72.5);
      expect(CourseCurriculum.fromJson(<String, dynamic>{}).finalExam, isNull);
    });

    test('CourseFinalExam arrondit le seuil de reussite', () {
      expect(CourseFinalExam.fromJson({'passScore': 59.6}).passScore, 60);
    });

    test('ExamRetakeStatus : restant borne a zero, points faibles et lecons', () {
      final s = ExamRetakeStatus.fromJson({
        'quizId': 2,
        'examTitle': 'Examen',
        'courseTitle': 'Chimie',
        'consecutiveFailures': 2,
        'failuresBeforePause': 3,
        'locked': false,
        'weakPoints': [
          {'question': 'Q1', 'explanation': 'E1', 'topic': 'Acides'},
          {'question': 'Q2'},
        ],
        'lessons': [
          {'id': 5, 'title': 'Les acides'},
        ],
        'lockedUntil': '2026-03-01T10:00:00Z',
      });
      expect(s.remaining, 1);
      expect(s.weakPoints, hasLength(2));
      expect(s.weakPoints[0].topic, 'Acides');
      expect(s.weakPoints[1].explanation, isNull);
      expect(s.lessons.single.title, 'Les acides');
      expect(s.lockedUntil, isNotNull);
      expect(s.lockedUntil!.toUtc(), DateTime.utc(2026, 3, 1, 10));
      final trop = ExamRetakeStatus.fromJson({'consecutiveFailures': 7});
      expect(trop.failuresBeforePause, 3);
      expect(trop.remaining, 0);
      expect(trop.passScore, 50.0);
      expect(trop.lockedUntil, isNull);
    });

    test('LessonContent : progression imbriquee et visionneuse seule', () {
      final l = LessonContent.fromJson({
        'id': 11,
        'title': 'Epreuve',
        'lessonType': 'file',
        'progress': {'isCompleted': true, 'lastPositionSec': 90},
        'sourceSubjectId': 21,
        'viewerOnly': true,
      });
      expect(l.isCompleted, isTrue);
      expect(l.lastPositionSec, 90);
      expect(l.sourceSubjectId, 21);
      expect(l.viewerOnly, isTrue);
      expect(l.fileUrl, isNull);
      final v = LessonContent.fromJson(<String, dynamic>{});
      expect(v.lessonType, 'video');
      expect(v.isCompleted, isFalse);
      expect(v.viewerOnly, isFalse);
      expect(v.quizId, isNull);
    });

    test('MyCourseCertificate : titre par defaut et date', () {
      final c = MyCourseCertificate.fromJson({'id': 1, 'verificationCode': 'ABC', 'grade': 15, 'issuedAt': '2026-02-03T00:00:00Z'});
      expect(c.courseTitle, 'Formation');
      expect(c.grade, 15.0);
      expect(c.issuedAt!.toUtc(), DateTime.utc(2026, 2, 3));
      expect(MyCourseCertificate.fromJson(<String, dynamic>{}).issuedAt, isNull);
    });

    test('MyEnrollment : cours imbrique, achevement et duree', () {
      final e = MyEnrollment.fromJson({
        'enrollmentId': 3,
        'progressPercent': 100,
        'course': {'id': 8, 'title': 'Anglais', 'totalDurationMin': 90, 'instructorName': 'Paul'},
      });
      expect(e.courseId, 8);
      expect(e.courseTitle, 'Anglais');
      expect(e.accessType, 'free');
      expect(e.isCompleted, isTrue, reason: '100 % suffit meme sans date');
      expect(e.durationStr, '1 h 30');
      expect(MyEnrollment.fromJson({'completedAt': '2026-01-01', 'course': {'totalDurationMin': 60}}).isCompleted, isTrue);
      final partiel = MyEnrollment.fromJson({'progressPercent': 40, 'course': {'totalDurationMin': 120}});
      expect(partiel.isCompleted, isFalse);
      expect(partiel.durationStr, '2 h');
      expect(MyEnrollment.fromJson(<String, dynamic>{}).durationStr, '', reason: 'duree nulle : masquee (lot 1)');
    });

    test('CourseReview : auteur anonyme selon la langue', () {
      expect(CourseReview.fromJson({'id': 1, 'rating': 5}).authorName, 'Utilisateur');
      expect(CourseReview.fromJson({'author': {'name': 'Ada', 'avatarUrl': 'u'}}).authorName, 'Ada');
      L10n.locale = const Locale('en');
      expect(CourseReview.fromJson({'rating': 4}).authorName, L10n.current.msgRoleUser);
      expect(L10n.current.msgRoleUser, isNot('Utilisateur'));
    });

    test('CourseActionRefused : toString rend le message', () {
      expect(const CourseActionRefused('x', 'Refuse').toString(), 'Refuse');
    });
  });

  group('CourseService', () {
    test('list envoie les filtres presents et lit total et pages', () async {
      faux.repond('GET', '/courses', {
        'data': [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
        'total': 25,
        'totalPages': 3,
      });
      final r = await CourseService.instance.list(category: 'Maths', free: true, page: 2);
      expect(r.items.map((c) => c.id), [1, 2]);
      expect(r.total, 25);
      expect(r.totalPages, 3);
      expect(faux.requetes.single.queryParameters, {'category': 'Maths', 'free': true, 'page': 2, 'pageSize': 12});
    });

    test('list sans total : le total vaut le nombre d\'elements, une seule page', () async {
      faux.repond('GET', '/courses', {
        'data': [
          {'id': 1},
        ],
      });
      final r = await CourseService.instance.list();
      expect(r.total, 1);
      expect(r.totalPages, 1);
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 12});
    });

    test('search envoie la requete et lit une liste brute', () async {
      faux.repond('GET', '/courses/search', [
        {'id': 4, 'title': 'Trigo'},
      ]);
      final r = await CourseService.instance.search('trigo');
      expect(r.single.title, 'Trigo');
      expect(faux.requetes.single.queryParameters, {'q': 'trigo', 'page': 1});
    });

    test('get lit le detail', () async {
      faux.repond('GET', '/courses/7', {'id': 7, 'title': 'Algebre'});
      expect((await CourseService.instance.get(7)).title, 'Algebre');
    });

    test('get propage l\'erreur du serveur', () async {
      faux.repond('GET', '/courses/9', {'error': 'x'}, statut: 404);
      await expectLater(CourseService.instance.get(9), throwsA(isA<DioException>()));
    });

    test('enroll : un refus 409 devient CourseActionRefused avec son code', () async {
      faux.repond('POST', '/courses/3/enroll', {'error': 'Deja inscrit', 'code': 'already_enrolled'}, statut: 409);
      await expectLater(
        CourseService.instance.enroll(3),
        throwsA(isA<CourseActionRefused>()
            .having((e) => e.code, 'code', 'already_enrolled')
            .having((e) => e.message, 'message', 'Deja inscrit')),
      );
    });

    test('enroll : une erreur 500 reste une DioException', () async {
      faux.repond('POST', '/courses/3/enroll', {'error': 'boom'}, statut: 500);
      await expectLater(CourseService.instance.enroll(3), throwsA(isA<DioException>()));
    });

    test('enroll : un 409 sans message n\'est pas un refus metier', () async {
      faux.repond('POST', '/courses/3/enroll', {'code': 'x'}, statut: 409);
      await expectLater(CourseService.instance.enroll(3), throwsA(isA<DioException>()));
    });

    test('enroll reussi : aucune erreur', () async {
      faux.repond('POST', '/courses/3/enroll', {});
      await CourseService.instance.enroll(3);
      expect(faux.recues('POST', '/courses/3/enroll'), hasLength(1));
    });

    test('payCartWithBalance : null en succes, message du serveur ou par defaut en echec', () async {
      faux.repond('POST', '/orders/pay-with-balance', {});
      expect(await CourseService.instance.payCartWithBalance(), isNull);
      faux.repond('POST', '/orders/pay-with-balance', {'error': 'Solde insuffisant'}, statut: 409);
      expect(await CourseService.instance.payCartWithBalance(), 'Solde insuffisant');
      faux.repond('POST', '/orders/pay-with-balance', {}, statut: 500);
      expect(await CourseService.instance.payCartWithBalance(), 'Le paiement par solde a échoué. Réessaie.');
    });

    test('purchaseForChild envoie l\'enfant et la formation', () async {
      faux.repond('POST', '/parent/purchase-for-child', {});
      expect(await CourseService.instance.purchaseForChild(5, 12), isNull);
      expect(faux.requetes.single.data, {'childId': 12, 'courseId': 5});
      faux.repond('POST', '/parent/purchase-for-child', {}, statut: 500);
      expect(await CourseService.instance.purchaseForChild(5, 12), 'L\'achat n\'a pas pu être finalisé.');
    });

    test('myCourseCertificates accepte une liste brute ou enveloppee', () async {
      faux.repond('GET', '/my-course-certificates', {
        'data': [
          {'id': 1, 'courseTitle': 'A'},
        ],
      });
      expect((await CourseService.instance.myCourseCertificates()).single.courseTitle, 'A');
      faux.repond('GET', '/my-course-certificates', [
        {'id': 2},
        {'id': 3},
      ]);
      expect(await CourseService.instance.myCourseCertificates(), hasLength(2));
    });

    test('myCourses lit les inscriptions', () async {
      faux.repond('GET', '/my-courses', [
        {'enrollmentId': 1, 'course': {'id': 2, 'title': 'T'}},
      ]);
      final l = await CourseService.instance.myCourses();
      expect(l.single.courseTitle, 'T');
    });

    test('getCurriculum, getExamRetake et getLesson appellent les bonnes routes', () async {
      faux.repond('GET', '/courses/4/play', {'courseId': 4, 'title': 'P'});
      faux.repond('GET', '/courses/4/play/exams/9/retake', {'quizId': 9, 'locked': true});
      faux.repond('GET', '/courses/4/play/6', {'id': 6, 'title': 'L'});
      expect((await CourseService.instance.getCurriculum(4)).title, 'P');
      expect((await CourseService.instance.getExamRetake(4, 9)).locked, isTrue);
      expect((await CourseService.instance.getLesson(4, 6)).title, 'L');
    });

    test('generateMyCertificate poste un corps vide', () async {
      faux.repond('POST', '/courses/4/certificate/generate', {});
      await CourseService.instance.generateMyCertificate(4);
      expect(faux.requetes.single.data, <String, dynamic>{});
    });

    test('saveProgress envoie les temps et lit la progression', () async {
      faux.repond('POST', '/courses/4/play/6/progress', {'progressPercent': 80, 'courseCompleted': true});
      final r = await CourseService.instance.saveProgress(4, 6, watchTimeSec: 120, lastPositionSec: 100, isCompleted: true);
      expect(r.progressPercent, 80.0);
      expect(r.courseCompleted, isTrue);
      expect(faux.requetes.single.data, {'watchTimeSec': 120, 'lastPositionSec': 100, 'isCompleted': true});
    });

    test('saveProgress : completion refusee (409) remonte le message', () async {
      faux.repond('POST', '/courses/4/play/6/progress', {'error': 'Video pas assez regardee', 'code': 'not_watched'}, statut: 409);
      await expectLater(
        CourseService.instance.saveProgress(4, 6, watchTimeSec: 1, lastPositionSec: 1, isCompleted: true),
        throwsA(isA<CourseActionRefused>().having((e) => e.message, 'message', 'Video pas assez regardee')),
      );
    });

    test('getReviews lit une page enveloppee ou brute avec page et taille', () async {
      faux.repond('GET', '/courses/4/reviews', {
        'data': [
          {'id': 1, 'rating': 5},
        ],
      });
      expect(await CourseService.instance.getReviews(4), hasLength(1));
      expect(faux.requetes.single.queryParameters, {'page': 1, 'pageSize': 10});
      faux.repond('GET', '/courses/4/reviews', [
        {'id': 1},
        {'id': 2},
      ]);
      expect(await CourseService.instance.getReviews(4), hasLength(2));
    });

    test('submitReview n\'envoie le commentaire que s\'il n\'est pas vide', () async {
      faux.repond('POST', '/courses/4/reviews', {});
      await CourseService.instance.submitReview(4, 5, comment: 'Super');
      await CourseService.instance.submitReview(4, 3, comment: '');
      await CourseService.instance.submitReview(4, 2);
      final r = faux.recues('POST', '/courses/4/reviews');
      expect(r[0].data, {'rating': 5, 'comment': 'Super'});
      expect(r[1].data, {'rating': 3});
      expect(r[2].data, {'rating': 2});
    });
  });
}
