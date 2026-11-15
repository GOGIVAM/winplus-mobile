import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/parent_service.dart';
import 'package:winplus/services/teacher_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('Parent : modeles', () {
    test('ApiUpcomingEvent : type par defaut et date locale', () {
      final e = ApiUpcomingEvent.fromJson({'title': 'Portes ouvertes', 'startDate': '2026-05-01T10:00:00Z'});
      expect(e.type, 'event');
      expect(e.startDate!.toUtc(), DateTime.utc(2026, 5, 1, 10));
      expect(ApiUpcomingEvent.fromJson(<String, dynamic>{}).startDate, isNull);
    });

    test('ApiChild : nom complet', () {
      expect(ApiChild.fromJson({'firstName': 'Ada', 'lastName': 'Eto'}).fullName, 'Ada Eto');
      expect(ApiChild.fromJson({'firstName': 'Ada'}).fullName, 'Ada');
      expect(ApiChild.fromJson(<String, dynamic>{}).id, 0);
    });

    test('profil, statistiques et activite : valeurs par defaut', () {
      expect(ApiParentProfile.fromJson(<String, dynamic>{}).email, '');
      final s = ApiChildStats.fromJson(<String, dynamic>{});
      expect(s.downloadsThisWeek, 0);
      expect(s.averageScore, 0.0);
      expect(const ApiChildStats().aiSessionsThisWeek, 0);
      final a = ApiChildActivity.fromJson({'description': 'Quiz', 'score': 80});
      expect(a.type, 'download');
      expect(a.score, 80);
    });

    test('scores par matiere et dernier quiz', () {
      final s = ApiChildSubjectScores.fromJson({
        'subjects': [
          {'subjectId': 1, 'averageScore': 14},
          {'subjectTitle': 'Maths', 'averageScore': 12.5},
        ],
        'lastQuiz': {'correctAnswers': 7, 'totalQuestions': 10, 'scorePercent': 70},
      });
      expect(s.subjects.first.subjectTitle, 'Matière');
      expect(s.subjects.last.averageScore, 12.5);
      expect(s.lastQuiz!.title, 'Quiz');
      expect(s.lastQuiz!.scorePercent, 70.0);
      expect(ApiChildSubjectScores.fromJson(<String, dynamic>{}).lastQuiz, isNull);
    });

    test('ApiPersistedAlert : l\'enfant par defaut est celui demande', () {
      final a = ApiPersistedAlert.fromJson(<String, dynamic>{}, fallbackChildId: 33);
      expect(a.childId, 33);
      expect(a.type, 'Inactivite');
      expect(a.severity, 'Low');
      expect(a.isRead, isFalse);
      expect(ApiPersistedAlert.fromJson({'childId': 4}, fallbackChildId: 33).childId, 4);
    });

    test('ApiGoal : goalId prime sur id', () {
      expect(ApiGoal.fromJson({'goalId': 5, 'id': 9}).id, 5);
      expect(ApiGoal.fromJson({'id': 9}).id, 9);
      final g = ApiGoal.fromJson(<String, dynamic>{});
      expect(g.id, 0);
      expect(g.status, 'Active');
      expect(g.progress, isNull);
    });

    test('portefeuille et paiements parent : valeurs par defaut', () {
      final w = ApiParentWalletSummary.fromJson({'creditsLeft': 1500});
      expect(w.creditsLeft, 1500.0);
      expect(w.currency, 'XAF');
      expect(w.planName, isNull);
      final p = ApiParentPayment.fromJson(<String, dynamic>{});
      expect(p.kind, 'order');
      expect(p.label, 'Paiement');
      expect(p.isDebit, isTrue);
      expect(p.status, 'paid');
      expect(ApiParentPayment.fromJson({'direction': 'credit'}).isDebit, isFalse);
    });

    test('enfants couverts', () {
      final c = ApiCoveredChildren.fromJson({
        'max': 2,
        'selectionNeeded': true,
        'children': [
          {'studentId': 1.0, 'name': 'Ada', 'covered': true},
        ],
        'nextChangeAt': '2026-07-01T00:00:00Z',
      });
      expect(c.max, 2);
      expect(c.selectionNeeded, isTrue);
      expect(c.customSelection, isFalse);
      expect(c.children.single.studentId, 1);
      expect(c.children.single.chosen, isFalse);
      expect(c.nextChangeAt!.toUtc(), DateTime.utc(2026, 7, 1));
      expect(ApiCoveredChildren.fromJson(<String, dynamic>{}).max, isNull);
      expect(const CoveredChildrenException('Non').toString(), 'Non');
    });
  });

  group('ParentService (sans cache)', () {
    test('getProfile : null si data absent ou en erreur', () async {
      faux.repond('GET', '/parent/profile', {'data': {'parentId': 3, 'name': 'Mme X', 'email': 'x@y.cm'}});
      expect((await ParentService.instance.getProfile())!.name, 'Mme X');
      faux.repond('GET', '/parent/profile', {'data': null});
      expect(await ParentService.instance.getProfile(), isNull);
      faux.repond('GET', '/parent/profile', {}, statut: 500);
      expect(await ParentService.instance.getProfile(), isNull);
    });

    test('getWalletSummary : null sans abonnement payant', () async {
      faux.repond('GET', '/parent/credits', {'data': {'creditsLeft': 500, 'planName': 'Famille'}});
      expect((await ParentService.instance.getWalletSummary())!.planName, 'Famille');
      faux.repond('GET', '/parent/credits', {'data': null});
      expect(await ParentService.instance.getWalletSummary(), isNull);
    });

    test('getUpcomingEvents ecarte les evenements sans titre ou sans date', () async {
      faux.repond('GET', '/parent/events/upcoming', {
        'data': [
          {'title': 'Reunion', 'startDate': '2026-05-01T10:00:00Z'},
          {'title': '  ', 'startDate': '2026-05-01T10:00:00Z'},
          {'title': 'Sans date'},
          'invalide',
        ],
      });
      final l = await ParentService.instance.getUpcomingEvents(limit: 3);
      expect(l.map((e) => e.title), ['Reunion']);
      expect(faux.requetes.single.queryParameters, {'limit': 3});
    });

    test('getUpcomingEvents : liste vide si data n\'est pas une liste ou en erreur', () async {
      faux.repond('GET', '/parent/events/upcoming', {'data': null});
      expect(await ParentService.instance.getUpcomingEvents(), isEmpty);
      faux.repond('GET', '/parent/events/upcoming', {}, statut: 500);
      expect(await ParentService.instance.getUpcomingEvents(), isEmpty);
    });

    test('getPayments lit les paiements et le total du mois ; null sans data', () async {
      faux.repond('GET', '/parent/payments', {
        'data': {
          'items': [
            {'label': 'Maths', 'amountXaf': 2000},
          ],
          'monthSpentXaf': 4500,
        },
      });
      final p = await ParentService.instance.getPayments();
      expect(p!.items.single.amountXaf, 2000.0);
      expect(p.monthSpentXaf, 4500.0);
      expect(faux.requetes.single.queryParameters, {'limit': 50});
      faux.repond('GET', '/parent/payments', {'data': null});
      expect(await ParentService.instance.getPayments(), isNull);
    });

    test('getCoveredChildren : null si la reponse n\'est pas un objet', () async {
      faux.repond('GET', '/parent/covered-children', {'max': 1});
      expect((await ParentService.instance.getCoveredChildren())!.max, 1);
      faux.repond('GET', '/parent/covered-children', [1]);
      expect(await ParentService.instance.getCoveredChildren(), isNull);
    });

    test('setCoveredChildren envoie les identifiants ; message du serveur ou par defaut en refus', () async {
      faux.repond('PUT', '/parent/covered-children', {'max': 2});
      await ParentService.instance.setCoveredChildren([1, 2]);
      expect(faux.requetes.single.data, {'studentIds': [1, 2]});
      faux.repond('PUT', '/parent/covered-children', {'error': 'Deja change'}, statut: 409);
      await expectLater(
        ParentService.instance.setCoveredChildren([1]),
        throwsA(isA<CoveredChildrenException>().having((e) => e.message, 'message', 'Deja change')),
      );
      faux.repond('PUT', '/parent/covered-children', {}, statut: 500);
      await expectLater(
        ParentService.instance.setCoveredChildren([1]),
        throwsA(isA<CoveredChildrenException>().having((e) => e.message, 'message', 'Le choix n\'a pas pu être enregistré.')),
      );
    });

    test('addChild : succes, puis refus avec le message du serveur conserve', () async {
      faux.repond('POST', '/parent/children', {});
      expect(await ParentService.instance.addChild(email: 'e@x.cm'), isTrue);
      expect(faux.requetes.single.data, {'email': 'e@x.cm'});
      expect(ParentService.instance.lastAddChildError, isNull);
      faux.repond('POST', '/parent/children', {'error': 'Limite atteinte'}, statut: 403);
      expect(await ParentService.instance.addChild(email: 'e@x.cm'), isFalse);
      expect(ParentService.instance.lastAddChildError, 'Limite atteinte');
      faux.repond('POST', '/parent/children', {'error': 'x'}, statut: 200);
      expect(await ParentService.instance.addChild(email: 'e@x.cm'), isTrue);
      expect(ParentService.instance.lastAddChildError, isNull, reason: 'effacee a chaque appel');
    });

    test('removeChild : true si accepte, false sinon', () async {
      faux.repond('DELETE', '/parent/children/4', {});
      expect(await ParentService.instance.removeChild(4), isTrue);
      expect(await ParentService.instance.removeChild(5), isFalse);
    });

    test('getChildStats lit les statistiques de la semaine', () async {
      faux.repond('GET', '/parent/children/4/stats', {'quizzesThisWeek': 3, 'averageScore': 15});
      final s = await ParentService.instance.getChildStats(4);
      expect(s.quizzesThisWeek, 3);
      expect(s.averageScore, 15.0);
    });

    test('markAlertRead avale l\'erreur sans la propager', () async {
      faux.repond('PATCH', '/parent-alerts/9/read', {});
      await ParentService.instance.markAlertRead(9);
      expect(faux.recues('PATCH', '/parent-alerts/9/read'), hasLength(1));
      await ParentService.instance.markAlertRead(10);
      expect(faux.recues('PATCH', '/parent-alerts/10/read'), hasLength(1));
    });
  });

  group('Enseignant : modeles', () {
    test('ApiPublishedContent : champs renommes et valeurs par defaut', () {
      final c = ApiPublishedContent.fromJson({'id': 1, 'downloadCount': 12, 'averageRating': 4, 'revenue': 3000, 'category': 'cours'});
      expect(c.downloads, 12);
      expect(c.rating, 4.0);
      expect(c.revenue, 3000);
      expect(c.type, 'cours');
      final v = ApiPublishedContent.fromJson(<String, dynamic>{});
      expect(v.status, 'draft');
      expect(v.type, 'epreuve');
    });

    test('ApiSubmission : non corrigee par defaut', () {
      final s = ApiSubmission.fromJson({'studentName': 'Ada', 'score': 14});
      expect(s.corrected, isFalse);
      expect(s.score, 14);
      expect(ApiSubmission.fromJson(<String, dynamic>{}).score, isNull);
    });

    test('ApiTeacherClass : actif par defaut', () {
      final c = ApiTeacherClass.fromJson(<String, dynamic>{});
      expect(c.isActive, isTrue);
      expect(c.classAverage, isNull);
      expect(c.pendingCount, 0);
    });

    test('ApiClassStudent.displayName : nom, a defaut e-mail, a defaut « Élève »', () {
      expect(ApiClassStudent.fromJson({'firstName': 'Ada', 'lastName': 'Eto'}).displayName, 'Ada Eto');
      expect(ApiClassStudent.fromJson({'firstName': 'Ada', 'lastName': ''}).displayName, 'Ada');
      expect(ApiClassStudent.fromJson({'email': 'a@b.cm'}).displayName, 'a@b.cm');
      expect(ApiClassStudent.fromJson(<String, dynamic>{}).displayName, 'Élève');
      L10n.locale = const Locale('en');
      expect(ApiClassStudent.fromJson(<String, dynamic>{}).displayName, L10n.current.roleStudent);
    });

    test('ApiAssignment : note maximale 20 par defaut', () {
      final a = ApiAssignment.fromJson(<String, dynamic>{});
      expect(a.maxScore, 20);
      expect(a.quizId, isNull);
      expect(ApiAssignment.fromJson({'maxScore': 10.5}).maxScore, 10.5);
    });
  });

  group('TeacherService', () {
    test('createSession envoie une seance en direct gratuite avec la date ISO fournie', () async {
      faux.repond('POST', '/sessions', {});
      expect(await TeacherService.instance.createSession(title: 'Revision', date: '2026-04-01T09:00:00', link: 'https://meet.x', maxStudents: 20), isTrue);
      final d = faux.requetes.single.data as Map;
      expect(d['title'], 'Revision');
      expect(d['type'], 'live');
      expect(d['startDate'], '2026-04-01T09:00:00.000');
      expect(d['durationMinutes'], 60);
      expect(d['maxParticipants'], 20);
      expect(d['externalLink'], 'https://meet.x');
      expect(d['isFree'], isTrue);
    });

    test('createSession : date illisible = lendemain ; refus serveur = false', () async {
      faux.repond('POST', '/sessions', {});
      await TeacherService.instance.createSession(title: 'T', date: 'demain matin');
      final debut = DateTime.parse((faux.requetes.single.data as Map)['startDate'] as String);
      expect(debut.isAfter(DateTime.now()), isTrue);
      faux.repond('POST', '/sessions', {}, statut: 500);
      expect(await TeacherService.instance.createSession(title: 'T', date: 'x'), isFalse);
    });

    test('publishContent poste vers /subjects sans le type de contenu', () async {
      faux.repond('POST', '/subjects', {});
      expect(
        await TeacherService.instance.publishContent(title: 'Sujet', type: 'epreuve', subjectCategory: 'Maths', level: '3eme', price: 500),
        isTrue,
      );
      expect(faux.requetes.single.data, {'title': 'Sujet', 'category': 'Maths', 'level': '3eme', 'price': 500});
      await TeacherService.instance.publishContent(title: 'S', type: 'x', subjectCategory: 'M', level: 'L', price: 0, description: 'D');
      expect((faux.requetes.last.data as Map)['description'], 'D');
    });

    test('publishContent : false si le serveur refuse', () async {
      faux.repond('POST', '/subjects', {'error': 'x'}, statut: 400);
      expect(await TeacherService.instance.publishContent(title: 'S', type: 'x', subjectCategory: 'M', level: 'L', price: 0), isFalse);
    });

    test('getMyContent et getSubmissions (liste brute ou { items })', () async {
      faux.repond('GET', '/teacher/contents/mine', [
        {'id': 1, 'title': 'A'},
      ]);
      expect((await TeacherService.instance.getMyContent()).single.title, 'A');
      faux.repond('GET', '/teacher/corrections/pending', {
        'items': [
          {'id': 2},
        ],
      });
      expect(await TeacherService.instance.getSubmissions(), hasLength(1));
      faux.repond('GET', '/teacher/corrections/pending', [
        {'id': 2},
        {'id': 3},
      ]);
      expect(await TeacherService.instance.getSubmissions(), hasLength(2));
    });

    test('correctSubmission poste la note vers /corrections/{id}', () async {
      faux.repond('POST', '/corrections/7', {});
      expect(await TeacherService.instance.correctSubmission(7, 15, 'Bien'), isTrue);
      expect(faux.requetes.single.data, {'note': 15, 'comment': 'Bien', 'status': 'submitted'});
      expect(await TeacherService.instance.correctSubmission(8, 10), isFalse);
    });

    test('revenus : resume vide en erreur, par contenu en liste brute ou enveloppee', () async {
      expect(await TeacherService.instance.getRevenueSummary(), isEmpty);
      faux.repond('GET', '/teacher/revenues', {'total': 9});
      expect((await TeacherService.instance.getRevenueSummary())['total'], 9);
      faux.repond('GET', '/teacher/revenue/by-content', {
        'data': [
          {'title': 'A', 'revenue': 100},
          'invalide',
        ],
      });
      expect(await TeacherService.instance.getContentRevenue(), hasLength(1));
      expect(faux.requetes.last.queryParameters, {'sort': 'revenue', 'dir': 'desc'});
    });

    test('getContentRevenue leve l\'erreur plutot qu\'une liste vide trompeuse', () async {
      faux.repond('GET', '/teacher/revenue/by-content', {}, statut: 500);
      await expectLater(TeacherService.instance.getContentRevenue(), throwsA(anything));
    });

    test('getRevenueShare : plan et part, enveloppes ou non', () async {
      faux.repond('GET', '/teacher/revenue-share', {'data': {'planName': 'Pro', 'teacherShare': 70}});
      final r = await TeacherService.instance.getRevenueShare();
      expect(r.planName, 'Pro');
      expect(r.teacherShare, 70.0);
      faux.repond('GET', '/teacher/revenue-share', {'planName': 'Basic'});
      expect((await TeacherService.instance.getRevenueShare()).planName, 'Basic');
      faux.repond('GET', '/teacher/revenue-share', {'data': {}});
      expect((await TeacherService.instance.getRevenueShare()).teacherShare, isNull);
    });

    test('deleteContent : true si accepte, false sinon', () async {
      faux.repond('DELETE', '/teacher/contents/3', {});
      expect(await TeacherService.instance.deleteContent(3), isTrue);
      expect(await TeacherService.instance.deleteContent(4), isFalse);
    });

    test('getStats : semaines a zero par defaut', () async {
      faux.repond('GET', '/teacher/stats', {'thisMonthRevenue': 9000.0, 'activeStudents': 12});
      final s = await TeacherService.instance.getStats();
      expect(s.thisMonthRevenue, 9000);
      expect(s.weeklyRevenue, [0, 0, 0, 0]);
      expect(s.activeStudents, 12);
      faux.repond('GET', '/teacher/stats', {'weeklyRevenue': [1, 2, 3, 4]});
      expect((await TeacherService.instance.getStats()).weeklyRevenue, [1, 2, 3, 4]);
    });

    test('classes : filtre des inactives, creation, archivage, reactivation, suppression', () async {
      faux.repond('GET', '/teacher/classes', [
        {'id': 1, 'name': '3eA'},
      ]);
      await TeacherService.instance.getClasses();
      expect(faux.requetes.last.queryParameters, isEmpty);
      await TeacherService.instance.getClasses(includeInactive: true);
      expect(faux.requetes.last.queryParameters, {'includeInactive': true});

      faux.repond('POST', '/teacher/classes', {'data': {'id': 5, 'name': 'Nouvelle'}});
      final c = await TeacherService.instance.createClass(name: 'Nouvelle', level: '3eme', academicYear: '2025-2026', description: '');
      expect(c.id, 5);
      expect(c.isActive, isTrue);
      expect(c.pendingCount, 0);
      expect(faux.requetes.last.data, {'name': 'Nouvelle', 'level': '3eme', 'academicYear': '2025-2026'});

      faux.repond('PATCH', '/teacher/classes/5/deactivate', {});
      await TeacherService.instance.deactivateClass(5);
      expect(faux.requetes.last.queryParameters, isEmpty);
      await TeacherService.instance.reactivateClass(5);
      expect(faux.requetes.last.queryParameters, {'reactivate': true});

      faux.repond('DELETE', '/teacher/classes/5', {});
      await TeacherService.instance.deleteClass(5);
      expect(faux.recues('DELETE', '/teacher/classes/5'), hasLength(1));
    });

    test('createClass : l\'erreur du serveur remonte (jamais une reussite simulee)', () async {
      faux.repond('POST', '/teacher/classes', {'error': 'Nom deja utilise'}, statut: 400);
      await expectLater(
        TeacherService.instance.createClass(name: 'X', level: 'L', academicYear: 'A'),
        throwsA(anything),
      );
    });

    test('deleteClass : le refus 400 remonte pour proposer la desactivation', () async {
      faux.repond('DELETE', '/teacher/classes/6', {'error': 'Eleves presents'}, statut: 400);
      await expectLater(TeacherService.instance.deleteClass(6), throwsA(anything));
    });

    test('eleves de la classe : liste, ajout par e-mail, retrait', () async {
      faux.repond('GET', '/teacher/classes/5/students', {
        'data': [
          {'studentId': 1, 'firstName': 'Ada'},
        ],
      });
      expect((await TeacherService.instance.getClassStudents(5)).single.displayName, 'Ada');
      faux.repond('POST', '/teacher/classes/5/students', {});
      await TeacherService.instance.addClassStudent(5, 'a@b.cm');
      expect(faux.requetes.last.data, {'email': 'a@b.cm'});
      faux.repond('DELETE', '/teacher/classes/5/students/1', {});
      await TeacherService.instance.removeClassStudent(5, 1);
      expect(faux.recues('DELETE', '/teacher/classes/5/students/1'), hasLength(1));
    });

    test('devoirs : liste puis creation avec champs facultatifs omis', () async {
      faux.repond('GET', '/teacher/assignments', [
        {'id': 1, 'title': 'D1'},
      ]);
      expect((await TeacherService.instance.getAssignments()).single.title, 'D1');
      faux.repond('POST', '/teacher/assignments', {'id': 2, 'title': 'D2', 'teacherClassId': 5});
      final a = await TeacherService.instance
          .createAssignment(teacherClassId: 5, title: 'D2', statementText: '', dueDate: DateTime.utc(2026, 4, 1));
      expect(a.id, 2);
      expect(faux.requetes.last.data, {
        'teacherClassId': 5,
        'title': 'D2',
        'dueDate': DateTime.utc(2026, 4, 1).toIso8601String(),
      });
    });
  });
}
