import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/institution_service.dart';
import 'package:winplus/services/reports_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('Etablissement : modeles', () {
    test('ApiInstitutionStudent : nom complet sans espace superflu', () {
      expect(ApiInstitutionStudent.fromJson({'firstName': 'Ada', 'lastName': 'Eto'}).fullName, 'Ada Eto');
      expect(ApiInstitutionStudent.fromJson({'firstName': 'Ada'}).fullName, 'Ada');
      final v = ApiInstitutionStudent.fromJson(<String, dynamic>{});
      expect(v.fullName, '');
      expect(v.isActive, isTrue);
      expect(v.averageScore, isNull);
    });

    test('ApiInstitutionKpis : reponse enveloppee du serveur, anciens noms encore lus, pas de moyenne sans quiz', () {
      final k = ApiInstitutionKpis.fromJson(<String, dynamic>{});
      expect(k.totalStudents, 0);
      expect(k.averageScore, isNull);
      final r = ApiInstitutionKpis.fromJson({
        'success': true,
        'data': {'studentsTotal': 7, 'activeToday': 3, 'avgScore': 62, 'avgSuccessRate': 50},
      });
      expect([r.totalStudents, r.activeStudents, r.averageScore], [7, 3, 62.0]);
      expect(ApiInstitutionKpis.fromJson({'averageScore': 12, 'totalStudents': 4}).averageScore, 12.0);
    });

    test('ApiAtRiskStudent : critique d\'apres le risque du serveur (0 a 1) ; sans lui, d\'apres la note et l\'inactivite', () {
      expect(ApiAtRiskStudent.fromJson({'riskScore': 0.75}).isCritical, isTrue);
      expect(ApiAtRiskStudent.fromJson({'riskScore': 0.5, 'globalScore': 10, 'hasScores': true}).isCritical, isFalse);
      // Risque donne sur 100 par un ancien serveur.
      expect(ApiAtRiskStudent.fromJson({'riskScore': 90}).riskScore, 0.9);
      // Sans quiz : ni note ni « critique » par defaut.
      final sansQuiz = ApiAtRiskStudent.fromJson({'riskScore': 0.5, 'hasScores': false, 'inactiveDays': 7});
      expect([sansQuiz.hasScores, sansQuiz.globalScore, sansQuiz.isCritical], [false, null, false]);
      // Ancien serveur, sans risque calcule.
      expect(ApiAtRiskStudent.fromJson({'globalScore': 39}).isCritical, isTrue);
      expect(ApiAtRiskStudent.fromJson({'globalScore': 40, 'inactiveDays': 7}).isCritical, isFalse);
      expect(ApiAtRiskStudent.fromJson({'globalScore': 60, 'inactiveDays': 8}).isCritical, isTrue);
    });

    test('ApiGroup et ApiGroupMember : valeurs par defaut', () {
      expect(ApiGroup.fromJson(<String, dynamic>{}).level, '');
      expect(ApiGroup.fromJson({'memberCount': 4}).memberCount, 4);
      final m = ApiGroupMember.fromJson({'firstName': 'Zoe', 'averageScore': 14, 'activityScore': 3});
      expect(m.fullName, 'Zoe');
      expect(m.averageScore, 14.0);
      expect(m.activityScore, 3);
    });

    test('ApiInstitutionAnalytics : activite par jour', () {
      final a = ApiInstitutionAnalytics.fromJson({
        'activityByDay': {'lun': 5, 'mar': null},
        'averageScore': 11,
      });
      expect(a.activityByDay, {'lun': 5, 'mar': 0});
      expect(a.averageScore, 11.0);
      expect(ApiInstitutionAnalytics.fromJson(<String, dynamic>{}).activityByDay, isEmpty);
    // Sans quiz, le serveur omet la moyenne : pas de « 0/20 » invente.
    expect(ApiInstitutionAnalytics.fromJson(<String, dynamic>{}).averageScore, isNull);
    expect(ApiInstitutionAnalytics.fromJson({'averageScore': 62.5}).averageScore, 62.5);
    });

    test('ApiActionPlan : contexte, semaine et actions vides retirees', () {
      final p = ApiActionPlan.fromJson({
        'week_label': 'Semaine 12',
        'context': {'student_count': 120, 'at_risk_count': 8, 'inactive_count': 15},
        'actions': [
          {'priority': 1, 'action': 'Appeler les familles', 'effort': 'faible', 'estimated_impact': 'fort'},
          {'priority': 2, 'action': ''},
          'invalide',
          {'priority': 3.0, 'action': 'Tutorat'},
        ],
      });
      expect(p.weekLabel, 'Semaine 12');
      expect(p.studentCount, 120);
      expect(p.atRiskCount, 8);
      expect(p.inactiveCount, 15);
      expect(p.actions.map((a) => a.action), ['Appeler les familles', 'Tutorat']);
      expect(p.actions.first.estimatedImpact, 'fort');
      expect(p.actions.last.priority, 3);
      final v = ApiActionPlan.fromJson({'message': 'Aucun eleve'});
      expect(v.message, 'Aucun eleve');
      expect(v.actions, isEmpty);
    });

    test('ApiInstitutionLicenseSummary : places utilisees', () {
      final l = ApiInstitutionLicenseSummary.fromJson({'tier': 'pro', 'status': 'active', 'studentSeats': 200, 'studentSeatsUsed': 150});
      expect(l.tier, 'pro');
      expect(l.studentSeats - l.studentSeatsUsed, 50);
      expect(ApiInstitutionLicenseSummary.fromJson(<String, dynamic>{}).tier, '');
    });
  });

  group('InstitutionService', () {
    test('getMyInstitutionName : nom enveloppe ou a plat, rogne ; null si vide ou erreur', () async {
      faux.repond('GET', '/institution/me', {'data': {'name': '  Lycee Leclerc  '}});
      expect(await InstitutionService.instance.getMyInstitutionName(), 'Lycee Leclerc');
      faux.repond('GET', '/institution/me', {'name': 'Ecole'});
      expect(await InstitutionService.instance.getMyInstitutionName(), 'Ecole');
      faux.repond('GET', '/institution/me', {'name': '   '});
      expect(await InstitutionService.instance.getMyInstitutionName(), isNull);
      faux.repond('GET', '/institution/me', {}, statut: 500);
      expect(await InstitutionService.instance.getMyInstitutionName(), isNull);
    });

    test('getMyInstitutionId lit l\'identifiant enveloppe', () async {
      faux.repond('GET', '/institution/me', {'data': {'id': 12}, 'success': true});
      expect(await InstitutionService.instance.getMyInstitutionId(), 12);
      faux.repond('GET', '/institution/me', {}, statut: 404);
      expect(await InstitutionService.instance.getMyInstitutionId(), isNull);
    });

    test('getLicenseSummary : null sans licence ou en erreur', () async {
      faux.repond('GET', '/institution/license', {'license': {'tier': 'pro', 'studentSeats': 10}});
      expect((await InstitutionService.instance.getLicenseSummary())!.studentSeats, 10);
      faux.repond('GET', '/institution/license', {'license': null});
      expect(await InstitutionService.instance.getLicenseSummary(), isNull);
      faux.repond('GET', '/institution/license', {}, statut: 500);
      expect(await InstitutionService.instance.getLicenseSummary(), isNull);
    });

    test('groupes : liste, creation (description facultative), suppression', () async {
      faux.repond('GET', '/institution/groups', [
        {'id': 1, 'name': '3eA', 'level': '3eme'},
      ]);
      expect((await InstitutionService.instance.getGroups()).single.name, '3eA');

      faux.repond('POST', '/institution/groups', {});
      expect(await InstitutionService.instance.createGroup(name: 'G', level: 'L'), isTrue);
      expect(faux.requetes.last.data, {'name': 'G', 'level': 'L'});
      await InstitutionService.instance.createGroup(name: 'G', level: 'L', description: 'D');
      expect((faux.requetes.last.data as Map)['description'], 'D');

      faux.repond('DELETE', '/institution/groups/1', {});
      expect(await InstitutionService.instance.deleteGroup(1), isTrue);
      expect(await InstitutionService.instance.deleteGroup(2), isFalse);
    });

    test('createGroup rend false si le serveur refuse', () async {
      faux.repond('POST', '/institution/groups', {'error': 'x'}, statut: 400);
      expect(await InstitutionService.instance.createGroup(name: 'G', level: 'L'), isFalse);
    });

    test('membres : liste, ajout par e-mail, retrait', () async {
      faux.repond('GET', '/institution/groups/1/members', [
        {'id': 9, 'firstName': 'Ada'},
      ]);
      expect((await InstitutionService.instance.getGroupMembers(1)).single.fullName, 'Ada');
      faux.repond('POST', '/institution/groups/1/members', {});
      expect(await InstitutionService.instance.addMemberToGroup(1, 'a@b.cm'), isTrue);
      expect(faux.requetes.last.data, {'email': 'a@b.cm'});
      faux.repond('DELETE', '/institution/groups/1/members/9', {});
      expect(await InstitutionService.instance.removeMemberFromGroup(1, 9), isTrue);
      expect(await InstitutionService.instance.removeMemberFromGroup(1, 10), isFalse);
      expect(await InstitutionService.instance.addMemberToGroup(2, 'x'), isFalse);
    });

    test('eleves a risque, analyses et plan d\'action', () async {
      faux.repond('GET', '/institution/at-risk', [
        {'id': 1, 'riskScore': 0.8},
      ]);
      expect((await InstitutionService.instance.getAtRiskStudents()).single.riskScore, 0.8);
      faux.repond('GET', '/institution/analytics', {'totalStudents': 40});
      expect((await InstitutionService.instance.getAnalytics()).totalStudents, 40);
      faux.repond('GET', '/institution/action-plan', {'week_label': 'S1'});
      expect((await InstitutionService.instance.getActionPlan()).weekLabel, 'S1');
    });

    test('getActionPlan : l\'erreur remonte a l\'ecran', () async {
      faux.repond('GET', '/institution/action-plan', {}, statut: 500);
      await expectLater(InstitutionService.instance.getActionPlan(), throwsA(anything));
    });

    test('annuaire des eleves : filtre search seulement s\'il est non vide, liste ou { items }', () async {
      faux.repond('GET', '/institution/4/students', {
        'items': [
          {'id': 1, 'firstName': 'A'},
        ],
      });
      expect(await InstitutionService.instance.getStudentDirectory(4, q: 'ad'), hasLength(1));
      expect(faux.requetes.last.queryParameters, {'search': 'ad', 'page': 1, 'pageSize': 50});
      faux.repond('GET', '/institution/4/students', [
        {'id': 1},
        {'id': 2},
      ]);
      expect(await InstitutionService.instance.getStudentDirectory(4, q: ''), hasLength(2));
      expect(faux.requetes.last.queryParameters, {'page': 1, 'pageSize': 50});
    });

    test('indicateurs : valeurs par defaut en cas d\'erreur', () async {
      faux.repond('GET', '/institution/4/kpis', {'totalStudents': 7});
      expect((await InstitutionService.instance.getInstitutionKpis(4)).totalStudents, 7);
      expect((await InstitutionService.instance.getInstitutionKpis(5)).totalStudents, 0);
    });

    test('ajout d\'un eleve : une ligne d\'import avec les champs fournis', () async {
      faux.repond('POST', '/institution/4/students/import', {});
      expect(await InstitutionService.instance.addInstitutionStudent(4, 'e@x.cm', level: '3eme', matricule: 'M1'), isTrue);
      expect(faux.requetes.last.data, {
        'rows': [
          {'email': 'e@x.cm', 'level': '3eme', 'matricule': 'M1'},
        ],
      });
      expect(await InstitutionService.instance.addInstitutionStudent(9, 'e@x.cm'), isFalse);
    });
  });

  group('Rapports parents : modeles', () {
    test('ApiParentReport : valeurs par defaut', () {
      final r = ApiParentReport.fromJson(<String, dynamic>{});
      expect(r.reportType, '');
      expect(r.isRead, isFalse);
      expect(r.childId, isNull);
      final p = ApiParentReport.fromJson({'id': 2, 'childId': 5, 'reportType': 'weekly', 'isRead': true, 'createdAt': '2026-03-01T00:00:00Z'});
      expect(p.createdAt.toUtc(), DateTime.utc(2026, 3, 1));
      expect(p.childId, 5);
    });

    test('ApiPortfolio : trois textes descriptifs facultatifs', () {
      final p = ApiPortfolio.fromJson({'regularite': 'R', 'updatedAt': '2026-03-01T00:00:00Z'});
      expect(p.regularite, 'R');
      expect(p.autonomie, isNull);
      expect(p.curiosite, isNull);
      expect(p.updatedAt.toUtc(), DateTime.utc(2026, 3, 1));
    });

    test('ApiAlbum : listes vides par defaut', () {
      final a = ApiAlbum.fromJson(<String, dynamic>{});
      expect(a.topContents, isEmpty);
      expect(a.intensityWeeks, isEmpty);
      expect(a.bulletin, isNull);
      final b = ApiAlbum.fromJson({'schoolYear': '2025-2026', 'topContents': ['Maths', 'Physique'], 'intensityWeeks': ['S3']});
      expect(b.schoolYear, '2025-2026');
      expect(b.topContents, ['Maths', 'Physique']);
      expect(b.intensityWeeks, ['S3']);
    });
  });
}
