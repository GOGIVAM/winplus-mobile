import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/services/subject_service.dart';
import 'package:winplus/services/tutor_verification_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('ApiSubject et conversion en Content', () {
    test('valeurs par defaut', () {
      final s = ApiSubject.fromJson(<String, dynamic>{});
      expect(s.id, 0);
      expect(s.title, '');
      expect(s.isFree, isFalse);
      expect(s.price, 0.0);
      expect(s.language, 'fr');
      expect(s.hasCorrection, isFalse);
      expect(s.rating, 0.0);
    });

    test('toContent : note sur 100, prix arrondi, matiere et type reconnus', () {
      final c = ApiSubject.fromJson({
        'id': 12,
        'title': 'Epreuve de maths',
        'category': 'Épreuve',
        'subjectCategory': 'Maths',
        'level': 'BEPC',
        'year': 2023,
        'price': 1499.6,
        'averageRating': 4.25,
        'ratingsCount': 8,
        'downloadCount': 40,
        'isFree': false,
        'hasCorrection': true,
        'description': 'D',
      }).toContent();
      expect(c.id, '12');
      expect(c.subjectId, 'math');
      expect(c.type, ContentType.epreuve);
      expect(c.exam, 'BEPC');
      expect(c.level, 'BEPC');
      expect(c.year, 2023);
      expect(c.price, 1500);
      expect(c.rating100, 43);
      expect(c.rating, 4.3);
      expect(c.ratings, 8);
      expect(c.downloads, 40);
      expect(c.hasCorrection, isTrue);
      expect(c.description, 'D');
      expect(c.fav, isFalse);
    });

    test('toContent sans donnees : BAC, Terminale, annee courante, matiere math, epreuve', () {
      final c = ApiSubject.fromJson(<String, dynamic>{}).toContent();
      expect(c.exam, 'BAC');
      expect(c.level, 'Terminale');
      expect(c.subjectId, 'math');
      expect(c.type, ContentType.epreuve);
      expect(c.year, DateTime.now().year);
    });

    test('toContent : correspondance des matieres', () {
      String id(String cat) => ApiSubject.fromJson({'subjectCategory': cat}).toContent().subjectId;
      expect(id('Physique'), 'pc');
      expect(id('SVT'), 'svt');
      expect(id('Français'), 'fr');
      expect(id('Histoire'), 'hg');
      expect(id('Philo'), 'philo');
      expect(id('English'), 'en');
      expect(id('inconnue'), 'math');
    });

    test('toContent : la matiere retombe sur la categorie ; correspondance des types', () {
      expect(ApiSubject.fromJson({'category': 'anglais'}).toContent().subjectId, 'en');
      ContentType t(String cat) => ApiSubject.fromJson({'category': cat}).toContent().type;
      expect(t('correction'), ContentType.correction);
      expect(t('Quiz'), ContentType.quiz);
      expect(t('book'), ContentType.livre);
      expect(t('packs'), ContentType.pack);
      expect(t('autre'), ContentType.epreuve);
    });
  });

  group('SubjectService', () {
    test('getAll envoie les filtres presents et lit la pagination', () async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1, 'title': 'A'},
        ],
        'totalCount': 41,
        'page': 2,
        'totalPages': 3,
      });
      final p = await SubjectService.instance.getAll(q: 'maths', category: 'Sciences', contentLanguage: 'en', page: 2);
      expect(p.items.single.title, 'A');
      expect(p.totalCount, 41);
      expect(p.page, 2);
      expect(p.totalPages, 3);
      expect(faux.requetes.single.queryParameters, {
        'q': 'maths',
        'category': 'Sciences',
        'contentLanguage': 'en',
        'page': 2,
        'pageSize': 20,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      });
    });

    test('getAll sans filtre ni totaux : valeurs par defaut', () async {
      faux.repond('GET', '/subjects', {
        'items': [
          {'id': 1},
          {'id': 2},
        ],
      });
      final p = await SubjectService.instance.getAll(q: '');
      expect(p.totalCount, 2);
      expect(p.page, 1);
      expect(p.totalPages, 1);
      expect(faux.requetes.single.queryParameters.containsKey('q'), isFalse);
      expect(faux.requetes.single.queryParameters.containsKey('level'), isFalse);
    });

    test('getById lit une epreuve', () async {
      faux.repond('GET', '/subjects/5', {'id': 5, 'title': 'Sujet'});
      expect((await SubjectService.instance.getById(5)).title, 'Sujet');
    });

    test('view envoie le corrige et la formation, et rend les octets du document', () async {
      faux.repond('GET', '/subjects/5/view', 'contenu');
      final d = await SubjectService.instance.view(5, correction: true, courseId: 9);
      expect(d.bytes, isNotEmpty);
      expect(d.previewPages, isNull);
      expect(d.totalPages, isNull);
      expect(faux.requetes.single.queryParameters, {'kind': 'correction', 'courseId': 9});
      expect(faux.requetes.single.responseType, ResponseType.bytes);
      final b = await SubjectService.instance.viewBytes(5);
      expect(b, isNotEmpty);
      expect(faux.requetes.last.queryParameters, isEmpty);
    });

    test('view : un document vide leve une erreur', () async {
      faux.repond('GET', '/subjects/6/view', null);
      await expectLater(SubjectService.instance.view(6), throwsA(anything));
    });

    test('view : le refus du serveur remonte en DioException', () async {
      faux.repond('GET', '/subjects/7/view', {'error': 'Acces refuse'}, statut: 403);
      await expectLater(SubjectService.instance.view(7), throwsA(isA<DioException>()));
    });

    test('viewAccess : acces lu, null si illisible', () async {
      faux.repond('GET', '/subjects/5/view-access', {'document': 'preview', 'previewPages': 3});
      final a = await SubjectService.instance.viewAccess(5);
      expect(a!.hasPreview, isTrue);
      expect(a.canRead, isFalse);
      expect(a.canReadCorrection, isFalse);
      expect(await SubjectService.instance.viewAccess(6), isNull);
    });

    test('SubjectViewAccess : complet, ferme par defaut, apercu sans page', () {
      final plein = SubjectViewAccess.fromJson({'document': 'full', 'correction': 'full'});
      expect(plein.canRead, isTrue);
      expect(plein.canReadCorrection, isTrue);
      expect(plein.hasPreview, isFalse);
      final ferme = SubjectViewAccess.fromJson(<String, dynamic>{});
      expect(ferme.document, 'locked');
      expect(ferme.canRead, isFalse);
      expect(SubjectViewAccess.fromJson({'document': 'preview'}).hasPreview, isFalse);
    });
  });

  group('Verification des tuteurs : libelles et modeles', () {
    test('tables de libelles', () {
      expect(kVerificationRouteLabels.keys, ['identity', 'interview', 'institution']);
      expect(kVerificationRouteLabels['identity'], 'Pièce d\'identité et selfie');
      expect(kIdentityDocumentTypes.keys, ['cni', 'passport', 'residence_permit', 'driving_license', 'other']);
      expect(kIdentityDocumentTypes['cni'], 'Carte nationale d\'identité');
      expect(kInterviewStatusLabels.keys, hasLength(6));
      expect(kInterviewStatusLabels['requested'], 'Demandé');
      expect(kVerificationEventLabels, hasLength(17));
    });

    test('TutorVerificationEvent.label : libelle connu, sinon categorie · action', () {
      expect(TutorVerificationEvent.fromJson({'category': 'identity', 'action': 'approved'}).label, 'Pièce d\'identité validée');
      expect(TutorVerificationEvent.fromJson({'category': 'zzz', 'action': 'yyy'}).label, 'zzz · yyy');
    });

    test('TutorInterviewSummary.isOpen : demande ou planifie', () {
      expect(TutorInterviewSummary.fromJson(<String, dynamic>{}).isOpen, isTrue);
      expect(TutorInterviewSummary.fromJson({'status': 'scheduled'}).isOpen, isTrue);
      expect(TutorInterviewSummary.fromJson({'status': 'passed'}).isOpen, isFalse);
      expect(TutorInterviewSummary.fromJson({'status': 'cancelled'}).isOpen, isFalse);
      expect(TutorInterviewSummary.fromJson(<String, dynamic>{}).format, 'video');
    });

    test('TutorIdentityCheckSummary et TutorEndorsement : valeurs par defaut', () {
      final i = TutorIdentityCheckSummary.fromJson(<String, dynamic>{});
      expect(i.status, 'pending');
      expect(i.documentType, 'cni');
      expect(i.submittedAt, isNull);
      final e = TutorEndorsement.fromJson({'verifiedOn': '2026-01-05', 'isValid': true});
      expect(e.status, 'active');
      expect(e.isValid, isTrue);
      expect(e.verifiedOn, DateTime.parse('2026-01-05'));
      expect(TutorEndorsement.fromJson(<String, dynamic>{}).isValid, isFalse);
    });

    test('TutorVerificationStatus : defauts et conservation des fichiers (30 j / 7 j)', () {
      final s = TutorVerificationStatus.fromJson(<String, dynamic>{});
      expect(s.isVerified, isFalse);
      expect(s.inPersonAllowed, isFalse);
      expect(s.latestIdentity, isNull);
      expect(s.latestInterview, isNull);
      expect(s.endorsements, isEmpty);
      expect(s.retentionDaysAfterApproval, 30);
      expect(s.retentionDaysAfterRejection, 7);
      final p = TutorVerificationStatus.fromJson({
        'isVerified': true,
        'routes': ['identity'],
        'latestIdentity': {'id': 1, 'status': 'approved'},
        'latestInterview': {'id': 2, 'status': 'scheduled'},
        'endorsements': [
          {'id': 3},
        ],
        'history': [
          {'id': 4, 'category': 'status', 'action': 'verified'},
        ],
        'identityRetentionDaysAfterApproval': 10,
        'identityRetentionDaysAfterRejection': 2,
      });
      expect(p.routes, ['identity']);
      expect(p.latestIdentity!.status, 'approved');
      expect(p.latestInterview!.isOpen, isTrue);
      expect(p.endorsements, hasLength(1));
      expect(p.history.single.label, kVerificationEventLabels['status:verified']);
      expect(p.retentionDaysAfterApproval, 10);
      expect(p.retentionDaysAfterRejection, 2);
    });

    test('InstitutionTutorForEndorsement : engagement actif facultatif', () {
      final t = InstitutionTutorForEndorsement.fromJson({'tutorUserId': 3, 'activeEndorsement': {'id': 1}});
      expect(t.activeEndorsement!.id, 1);
      expect(t.hasTutorProfile, isFalse);
      expect(InstitutionTutorForEndorsement.fromJson(<String, dynamic>{}).activeEndorsement, isNull);
    });

    test('IdentityUpload.toMultipart conserve le nom et la taille du fichier', () {
      final m = const IdentityUpload([1, 2, 3], 'selfie.jpg').toMultipart();
      expect(m.filename, 'selfie.jpg');
      expect(m.length, 3);
    });

    test('kFallbackReportReasons : huit motifs, le dernier est « other »', () {
      final l = kFallbackReportReasons;
      expect(l, hasLength(8));
      expect(l.first.code, 'inappropriate_behavior');
      expect(l.last.code, 'other');
      expect(l.last.label, 'Autre');
      expect(l.firstWhere((r) => r.code == 'no_show').label, 'Absent à la séance');
    });
  });

  group('TutorVerificationService', () {
    test('getMine : statut lu, erreur avec le message du serveur ou par defaut', () async {
      faux.repond('GET', '/tutor-verification/me', {'isVerified': true});
      expect((await TutorVerificationService.instance.getMine()).isVerified, isTrue);
      faux.repond('GET', '/tutor-verification/me', {'message': 'Non autorise'}, statut: 403);
      await expectLater(
        TutorVerificationService.instance.getMine(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'texte', contains('Non autorise'))),
      );
      faux.repond('GET', '/tutor-verification/me', {}, statut: 500);
      await expectLater(
        TutorVerificationService.instance.getMine(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'texte', contains('Impossible de charger ta vérification.'))),
      );
    });

    test('submitIdentity envoie un formulaire avec recto, selfie et verso facultatif', () async {
      faux.repond('POST', '/tutor-verification/me/identity', {'isVerified': false});
      await TutorVerificationService.instance.submitIdentity(
        documentType: 'cni',
        front: const IdentityUpload([1], 'recto.jpg'),
        selfie: const IdentityUpload([2], 'selfie.jpg'),
        interviewId: 4,
      );
      final f = faux.requetes.single.data as FormData;
      final champs = {for (final e in f.fields) e.key: e.value};
      expect(champs, {'documentType': 'cni', 'interviewId': '4'});
      expect(f.files.map((e) => e.key), ['front', 'selfie']);
      expect(f.files.first.value.filename, 'recto.jpg');
    });

    test('requestInterview : ville et message omis quand ils sont vides', () async {
      faux.repond('POST', '/tutor-verification/me/interview', {});
      await TutorVerificationService.instance.requestInterview(format: 'video', availability: 'Soirs', city: '', message: 'Bonjour');
      expect(faux.requetes.single.data, {'format': 'video', 'availability': 'Soirs', 'message': 'Bonjour'});
    });

    test('cancelInterview et erreurs', () async {
      faux.repond('POST', '/tutor-verification/me/interview/3/cancel', {});
      await TutorVerificationService.instance.cancelInterview(3);
      expect(faux.recues('POST', '/tutor-verification/me/interview/3/cancel'), hasLength(1));
      await expectLater(TutorVerificationService.instance.cancelInterview(4), throwsA(isA<Exception>()));
    });

    test('institution : tuteurs, caution (date AAAA-MM-JJ) et retrait', () async {
      faux.repond('GET', '/tutor-verification/institution/tutors', [
        {'tutorUserId': 3},
      ]);
      expect(await TutorVerificationService.instance.institutionTutors(), hasLength(1));
      faux.repond('POST', '/tutor-verification/institution/endorsements', {});
      await TutorVerificationService.instance
          .endorse(tutorUserId: 3, statement: 'Connu', verifierName: 'M. Nkoa', verifiedOn: DateTime(2026, 1, 5));
      expect(faux.requetes.last.data, {'tutorUserId': 3, 'statement': 'Connu', 'verifierName': 'M. Nkoa', 'verifiedOn': '2026-01-05'});
      faux.repond('POST', '/tutor-verification/institution/endorsements/8/revoke', {});
      await TutorVerificationService.instance.revokeEndorsement(8, reason: 'Depart');
      expect(faux.requetes.last.data, {'reason': 'Depart'});
      await expectLater(TutorVerificationService.instance.revokeEndorsement(9), throwsA(isA<Exception>()));
    });

    test('reportReasons : liste du serveur, sinon motifs de secours', () async {
      faux.repond('GET', '/tutor-reports/reasons', [
        {'code': 'x', 'label': 'Motif X'},
      ]);
      final l = await TutorVerificationService.instance.reportReasons();
      expect(l.single.code, 'x');
      expect(l.single.label, 'Motif X');
      faux.repond('GET', '/tutor-reports/reasons', []);
      expect(await TutorVerificationService.instance.reportReasons(), hasLength(8));
      faux.repond('GET', '/tutor-reports/reasons', {}, statut: 500);
      expect(await TutorVerificationService.instance.reportReasons(), hasLength(8));
    });

    test('report : message du serveur, message par defaut, erreur', () async {
      faux.repond('POST', '/tutor-reports', {'message': 'Recu, merci.'});
      expect(await TutorVerificationService.instance.report(bookingId: 5, reason: 'no_show', description: ''), 'Recu, merci.');
      expect(faux.requetes.last.data, {'tutorBookingId': 5, 'reason': 'no_show'});
      faux.repond('POST', '/tutor-reports', {});
      expect(await TutorVerificationService.instance.report(bookingId: 5, reason: 'other', description: 'Detail'), 'Signalement transmis.');
      expect((faux.requetes.last.data as Map)['description'], 'Detail');
      faux.repond('POST', '/tutor-reports', {}, statut: 500);
      await expectLater(
        TutorVerificationService.instance.report(bookingId: 5, reason: 'other'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'texte', contains('Signalement impossible.'))),
      );
    });
  });
}
