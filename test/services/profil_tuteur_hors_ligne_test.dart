import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winplus/services/course_offline_service.dart';
import 'package:winplus/services/local_downloads_service.dart';
import 'package:winplus/services/push_service.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/services/tutor_profile_service.dart';

import '../helpers/faux_reseau.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  group('TutorProfile et modeles associes', () {
    test('profil vide : valeurs par defaut (inactif, presentiel autorise, remboursement 24 h / 50 % / 2 h)', () {
      final p = TutorProfile.fromJson(<String, dynamic>{});
      expect(p.id, 0);
      expect(p.isActive, isFalse);
      expect(p.noticeHours, 24);
      expect(p.inPersonAllowed, isTrue);
      expect(p.offersOnline, isFalse);
      expect(p.fullRefundHours, 24);
      expect(p.partialRefundPercent, 50);
      expect(p.noRefundHours, 2);
      expect(p.maxGroupSize, 1);
      expect(p.monthlyEnabled, isFalse);
      expect(p.monthlyMaxDiscountPercent, 30);
      expect(p.subjects, isEmpty);
      expect(p.pendingOrLatestDocument, isNull);
    });

    test('profil complet : listes, document et notes', () {
      final p = TutorProfile.fromJson({
        'id': 3,
        'userId': 9,
        'fullName': 'Mme Ngo',
        'subjects': ['Maths'],
        'levels': ['BAC'],
        'offersOnline': true,
        'isActive': true,
        'averageRating': 4.5,
        'reviewCount': 12,
        'pendingOrLatestDocument': {'id': 1, 'documentUrl': 'u', 'status': 'approved'},
        'hourlyRateXaf': 5000,
      });
      expect(p.fullName, 'Mme Ngo');
      expect(p.subjects, ['Maths']);
      expect(p.offersOnline, isTrue);
      expect(p.averageRating, 4.5);
      expect(p.pendingOrLatestDocument!.status, 'approved');
      expect(p.hourlyRateXaf, 5000);
    });

    test('TutorVerificationDocument et TutorProfileCompletion', () {
      expect(TutorVerificationDocument.fromJson(<String, dynamic>{}).status, 'pending');
      final c = TutorProfileCompletion.fromJson({
        'score': 70,
        'missingItems': [
          {'code': 'bio', 'label': 'Biographie'},
        ],
      });
      expect(c.score, 70);
      expect(c.missingItems.single['label'], 'Biographie');
      expect(TutorProfileCompletion.fromJson(<String, dynamic>{}).missingItems, isEmpty);
    });

    test('TutorRateSuggestion lit les champs en snake_case', () {
      final s = TutorRateSuggestion.fromJson({'suggested_rate_xaf': 4000, 'range_low_xaf': 3000, 'range_high_xaf': 5000, 'based_on': 'marche', 'explanation': 'E'});
      expect(s.suggestedRateXaf, 4000);
      expect(s.rangeLowXaf, 3000);
      expect(s.rangeHighXaf, 5000);
      expect(s.basedOn, 'marche');
      expect(TutorRateSuggestion.fromJson(<String, dynamic>{}).basedOn, 'estimation');
    });

    test('TutorSearchResult : listes et valeurs par defaut', () {
      final r = TutorSearchResult.fromJson({'userId': 4, 'fullName': 'Paul', 'subjects': ['Maths'], 'matchedTopics': ['Algebre'], 'averageRating': 4, 'offersInPerson': true});
      expect(r.userId, 4);
      expect(r.subjects, ['Maths']);
      expect(r.matchedTopics, ['Algebre']);
      expect(r.averageRating, 4.0);
      expect(r.offersInPerson, isTrue);
      final v = TutorSearchResult.fromJson(<String, dynamic>{});
      expect(v.fullName, '');
      expect(v.reviewCount, 0);
      expect(v.isInPersonVerified, isFalse);
    });
  });

  group('TutorProfileService', () {
    test('profil personnel : lecture et mise a jour', () async {
      faux.repond('GET', '/tutor-profile/me', {'id': 1, 'userId': 2, 'title': 'Prof'});
      expect((await TutorProfileService.instance.getMine()).title, 'Prof');
      faux.repond('PUT', '/tutor-profile/me', {'id': 1, 'title': 'Nouveau'});
      final p = await TutorProfileService.instance.update({'title': 'Nouveau'});
      expect(p.title, 'Nouveau');
      expect(faux.recues('PUT', '/tutor-profile/me').single.data, {'title': 'Nouveau'});
    });

    test('completion, activation, vacances (le booleen est le corps) et document', () async {
      faux.repond('GET', '/tutor-profile/me/completion', {'score': 55});
      expect((await TutorProfileService.instance.getCompletion()).score, 55);
      faux.repond('POST', '/tutor-profile/me/activate', {'isActive': true});
      expect((await TutorProfileService.instance.activate()).isActive, isTrue);
      faux.repond('POST', '/tutor-profile/me/vacation', {'isOnVacation': true});
      expect((await TutorProfileService.instance.setVacation(true)).isOnVacation, isTrue);
      expect(faux.recues('POST', '/tutor-profile/me/vacation').single.data, true);
      faux.repond('POST', '/tutor-profile/me/verification-document', {'id': 4, 'documentUrl': 'https://x/doc.pdf'});
      final d = await TutorProfileService.instance.submitVerificationDocument('https://x/doc.pdf');
      expect(d.id, 4);
      expect(faux.recues('POST', '/tutor-profile/me/verification-document').single.data, {'documentUrl': 'https://x/doc.pdf'});
    });

    test('suggestions de tarif : simple, grille et groupe (null si absents)', () async {
      faux.repond('POST', '/tutor-profile/me/suggest-rate', {'suggested_rate_xaf': 4000});
      final s = await TutorProfileService.instance.suggestRate('Maths', level: 'BAC');
      expect(s.suggestedRateXaf, 4000);
      expect(faux.requetes.last.data, {'subject': 'Maths', 'level': 'BAC'});
      expect(await TutorProfileService.instance.suggestRateGrid(['Maths', 'Physique'], ['online']), isNull);
      final d = faux.requetes.last.data as Map;
      expect(d['subject'], 'Maths');
      expect(d['include_grid'], true);
      expect(d['modes'], ['online']);
      expect(await TutorProfileService.instance.suggestGroupPricing('Maths'), isNull);
      expect((faux.requetes.last.data as Map)['include_group'], true);
    });

    test('recherche : seuls les filtres renseignes sont envoyes', () async {
      faux.repond('GET', '/tutor-profile/search', [
        {'userId': 1, 'fullName': 'Paul'},
      ]);
      final l = await TutorProfileService.instance.search(subject: 'Maths', topics: ['A', 'B'], verifiedOnly: true, inPersonVerifiedOnly: false, city: '');
      expect(l.single.fullName, 'Paul');
      expect(faux.requetes.single.queryParameters, {'topics': 'A,B', 'subject': 'Maths', 'verifiedOnly': true, 'page': 1, 'pageSize': 20});
    });

    test('fiche publique : lecture, 404 en DioException', () async {
      faux.repond('GET', '/tutor-profile/5', {'id': 5, 'userId': 5});
      expect((await TutorProfileService.instance.getPublicProfile(5)).userId, 5);
      await expectLater(TutorProfileService.instance.getPublicProfile(6), throwsA(isA<DioException>()));
    });
  });

  group('PushService', () {
    tearDown(() => PushService.instance.stop());

    test('un flux « data: » declenche l\'evenement, d\'abord a la connexion puis a chaque message', () async {
      await SharedPreferencesFaux.session();
      faux.repond('GET', '/notifications/sse', 'data: {}\n\n');
      var evenements = 0;
      await PushService.instance.start(() => evenements++);
      await laisserFinir();
      expect(evenements, greaterThanOrEqualTo(1));
      expect(faux.recues('GET', '/notifications/sse'), isNotEmpty);
      expect(faux.recues('GET', '/notifications/sse').first.headers['Accept'], 'text/event-stream');
      expect(faux.recues('GET', '/notifications/sse').first.responseType, ResponseType.stream);
    });

    test('stop() arrete la boucle : plus aucune connexion apres l\'arret', () async {
      await SharedPreferencesFaux.session();
      faux.repond('GET', '/notifications/sse', '');
      await PushService.instance.start(() {});
      await laisserFinir();
      PushService.instance.stop();
      final avant = faux.recues('GET', '/notifications/sse').length;
      await laisserFinir();
      expect(faux.recues('GET', '/notifications/sse').length, avant);
    });

    test('sans session : aucune connexion n\'est ouverte', () async {
      var evenements = 0;
      await PushService.instance.start(() => evenements++);
      await laisserFinir();
      expect(faux.recues('GET', '/notifications/sse'), isEmpty);
      expect(evenements, 0);
    });
  });

  group('Parties Hive : telechargements', () {
    late Directory dossier;

    setUp(() => dossier = ouvrirDossierHive());
    tearDown(() => fermerHive(dossier));

    test('LocalDownloadsService : purge l\'index herite des anciennes versions', () async {
      final box = await Hive.openBox('DownloadedFilesBox');
      await box.put('12', {'path': '/x/y.pdf'});
      await box.close();
      await LocalDownloadsService.instance.purgeLegacyCatalogFiles();
      expect(await Hive.boxExists('DownloadedFilesBox'), isTrue);
      final relue = await Hive.openBox('DownloadedFilesBox');
      expect(relue.isEmpty, isTrue);
    });

    test('LocalDownloadsService : sans rien a effacer, ne leve jamais', () async {
      await LocalDownloadsService.instance.purgeLegacyCatalogFiles();
    });

    test('CourseOfflineService.listDownloads : rend les lecons deja enregistrees', () async {
      final box = await Hive.openBox('CourseOfflineBox');
      await box.put('1_2', {'courseId': 1, 'lessonId': 2, 'path': '/x/1_2.enc'});
      final l = await CourseOfflineService.instance.listDownloads();
      expect(l, hasLength(1));
      expect(l.single['lessonId'], 2);
      await box.clear();
      expect(await CourseOfflineService.instance.listDownloads(), isEmpty);
    });

    test('CourseOfflineService.wipeForLogout : sans utilisateur connecte, ne leve pas et ne touche a rien', () async {
      final box = await Hive.openBox('CourseOfflineBox');
      await box.put('1_2', {'path': '/x/course_offline/7/1_2.enc'});
      await CourseOfflineService.instance.wipeForLogout();
      expect(box.length, 1);
    });
  });
}

/// Pose une session (jeton d'acces) dans les preferences simulees.
class SharedPreferencesFaux {
  static Future<void> session() => SessionManager.save(accessToken: 'jeton', refreshToken: 'r', userId: 7, email: 'a@b.cm', role: 'student', name: 'Ada');
}
