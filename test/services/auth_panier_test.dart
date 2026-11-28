import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:winplus/data/models.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/achievement_service.dart';
import 'package:winplus/services/auth_service.dart';
import 'package:winplus/services/cart_service.dart';
import 'package:winplus/services/certificate_service.dart';
import 'package:winplus/services/favorites_service.dart';
import 'package:winplus/services/session_manager.dart';
import 'package:winplus/services/user_service.dart';
import 'package:winplus/theme/win_colors.dart';

import '../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());
  tearDown(() => L10n.locale = const Locale('fr'));

  group('AuthService.signIn', () {
    test('une connexion reussie enregistre la session et renvoie la langue du compte', () async {
      faux.repond('POST', '/auth/signin', {
        'accessToken': 'acces',
        'refreshToken': 'refresh',
        'user': {'id': 12, 'email': 'ada@winplus.cm', 'role': 'teacher', 'firstName': 'Ada', 'lastName': 'Lovelace', 'locale': 'en'},
      });
      final r = await AuthService.instance.signIn('ada@winplus.cm', 'secret');
      expect(r.success, isTrue);
      expect(r.locale, 'en');
      expect(faux.recues('POST', '/auth/signin').single.data, {'email': 'ada@winplus.cm', 'password': 'secret'});
      expect(await SessionManager.getAccessToken(), 'acces');
      expect(await SessionManager.getRefreshToken(), 'refresh');
      expect(await SessionManager.getUserId(), 12);
      expect(await SessionManager.getUserRole(), 'teacher');
      expect(await SessionManager.getUserName(), 'Ada Lovelace');
    });

    test('sans role ni prenom dans la reponse : role eleve et nom vide', () async {
      faux.repond('POST', '/auth/signin', {
        'accessToken': 'a',
        'refreshToken': 'r',
        'user': {'id': 1, 'email': 'x@y.cm'},
      });
      final r = await AuthService.instance.signIn('x@y.cm', 'p');
      expect(r.success, isTrue);
      expect(r.locale, isNull);
      expect(await SessionManager.getUserRole(), 'student');
      expect(await SessionManager.getUserName(), '');
    });

    test('un refus du serveur renvoie un message traduit et son code, sans session', () async {
      faux.repond('POST', '/auth/signin', {'error': 'Email not verified', 'errorCode': 'EMAIL_NOT_VERIFIED'}, statut: 401);
      final r = await AuthService.instance.signIn('x@y.cm', 'p');
      expect(r.success, isFalse);
      expect(r.message, L10n.current.authErrEmailNotVerified);
      expect(r.errorCode, 'EMAIL_NOT_VERIFIED');
      expect(await SessionManager.isLoggedIn(), isFalse);
    });

    test('un refus sans message utilise le message de connexion de la langue courante', () async {
      faux.repond('POST', '/auth/signin', {}, statut: 400);
      final r = await AuthService.instance.signIn('x@y.cm', 'p');
      expect(r.success, isFalse);
      expect(r.message, L10n.current.svcLoginFailed);
      expect(r.message, 'Connexion impossible');
      expect(r.errorCode, isNull);
    });

    test('hors ligne, le message reseau est rendu dans la langue de l\'application', () async {
      L10n.locale = const Locale('en');
      faux.coupure('POST', '/auth/signin');
      final r = await AuthService.instance.signIn('x@y.cm', 'p');
      expect(r.success, isFalse);
      expect(r.message, L10n.current.authErrNetwork);
      expect(r.message, isNot('Erreur réseau.'));
    });
  });

  group('AuthService.signUp', () {
    test('envoie le role, la langue de l\'application et le telephone facultatif', () async {
      L10n.locale = const Locale('en');
      faux.repond('POST', '/auth/signup', {});
      final r = await AuthService.instance.signUp(
        email: 'p@winplus.cm',
        password: 'mdp',
        firstName: 'Paul',
        lastName: 'Biya',
        phone: '677000000',
        role: WinRole.parent,
      );
      expect(r.success, isTrue);
      expect(faux.recues('POST', '/auth/signup').single.data, {
        'email': 'p@winplus.cm',
        'password': 'mdp',
        'firstName': 'Paul',
        'lastName': 'Biya',
        'phone': '677000000',
        'role': 'parent',
        'locale': 'en',
      });
    });

    test('sans telephone, la cle phone est absente et le role par defaut est eleve', () async {
      faux.repond('POST', '/auth/signup', {});
      await AuthService.instance.signUp(email: 'e@w.cm', password: 'm', firstName: 'E', lastName: 'L');
      final corps = faux.recues('POST', '/auth/signup').single.data as Map;
      expect(corps.containsKey('phone'), isFalse);
      expect(corps['role'], 'student');
      expect(corps['locale'], 'fr');
    });

    test('un echec rend le message du serveur, ou celui par defaut', () async {
      faux.repond('POST', '/auth/signup', {'error': 'Email deja utilise'}, statut: 409);
      var r = await AuthService.instance.signUp(email: 'e@w.cm', password: 'm', firstName: 'E', lastName: 'L');
      expect(r.success, isFalse);
      expect(r.message, 'Email deja utilise');

      faux.repond('POST', '/auth/signup', {}, statut: 400);
      r = await AuthService.instance.signUp(email: 'e@w.cm', password: 'm', firstName: 'E', lastName: 'L');
      expect(r.message, 'Inscription impossible');
    });
  });

  group('AuthService : verification, mot de passe, double authentification', () {
    test('verifyEmail envoie l\'email et le code', () async {
      faux.repond('POST', '/auth/verify-email', {});
      final r = await AuthService.instance.verifyEmail('e@w.cm', '123456');
      expect(r.success, isTrue);
      expect(faux.recues('POST', '/auth/verify-email').single.data, {'email': 'e@w.cm', 'verificationCode': '123456', 'code': '123456'});
    });

    test('verifyEmail refuse un mauvais code avec le message par defaut', () async {
      faux.repond('POST', '/auth/verify-email', {}, statut: 400);
      final r = await AuthService.instance.verifyEmail('e@w.cm', '000000');
      expect(r.success, isFalse);
      expect(r.message, 'Code invalide');
    });

    test('resendVerification et forgotPassword envoient l\'email', () async {
      faux.repond('POST', '/auth/resend-verification', {});
      faux.repond('POST', '/auth/forgot-password', {});
      expect((await AuthService.instance.resendVerification('e@w.cm')).success, isTrue);
      expect((await AuthService.instance.forgotPassword('e@w.cm')).success, isTrue);
      expect(faux.recues('POST', '/auth/resend-verification').single.data, {'email': 'e@w.cm'});
      expect(faux.recues('POST', '/auth/forgot-password').single.data, {'email': 'e@w.cm'});
    });

    test('resetPassword envoie le jeton et le nouveau mot de passe sous le nom newPassword', () async {
      faux.repond('POST', '/auth/reset-password', {});
      final r = await AuthService.instance.resetPassword('tok', 'nouveau');
      expect(r.success, isTrue);
      expect(faux.recues('POST', '/auth/reset-password').single.data, {'resetToken': 'tok', 'token': 'tok', 'newPassword': 'nouveau'});
    });

    test('hors ligne, ces appels rendent le message d\'erreur reseau', () async {
      faux.coupure('POST', '/auth/resend-verification');
      faux.coupure('POST', '/auth/forgot-password');
      faux.coupure('POST', '/auth/reset-password');
      final rs = [
        await AuthService.instance.resendVerification('e@w.cm'),
        await AuthService.instance.forgotPassword('e@w.cm'),
        await AuthService.instance.resetPassword('t', 'p'),
      ];
      for (final r in rs) {
        expect(r.success, isFalse);
        expect(r.message, 'Erreur réseau');
      }
    });
  });

  group('AuthService.signOut', () {
    test('previent le serveur, efface la session et remet les notifications a zero', () async {
      await SessionManager.save(accessToken: 'a', refreshToken: 'r', userId: 5, email: 'e@w.cm', role: 'student', name: 'E');
      UserService.instance.unreadNotifications.value = 4;
      faux.repond('POST', '/auth/logout', {});
      await AuthService.instance.signOut();
      expect(faux.recues('POST', '/auth/logout'), hasLength(1));
      expect(await SessionManager.isLoggedIn(), isFalse);
      expect(UserService.instance.unreadNotifications.value, 0);
    });

    test('meme si le serveur est injoignable, la session locale est effacee', () async {
      await SessionManager.save(accessToken: 'a', refreshToken: 'r', userId: 5, email: 'e@w.cm', role: 'student', name: 'E');
      faux.coupure('POST', '/auth/logout');
      await AuthService.instance.signOut();
      expect(await SessionManager.isLoggedIn(), isFalse);
    });
  });

  group('CartService', () {
    Map<String, dynamic> article({int id = 1, int subjectId = 7, int? courseId, double prix = 1000}) => {
          'id': id,
          'subjectId': subjectId,
          if (courseId != null) 'courseId': courseId,
          'title': 'Maths BAC',
          'price': prix,
          'addedAt': '2026-01-05T10:00:00Z',
        };

    test('getCart lit les articles et les totaux du serveur', () async {
      faux.repond('GET', '/cart', {
        'items': [article(), article(id: 2, subjectId: 0, courseId: 9, prix: 2500)],
        'itemsCount': 2,
        'subtotal': 3500,
        'discount': 500,
        'tax': 467.5,
        'total': 3000,
        'currency': 'XAF',
      });
      final c = await CartService.instance.getCart();
      expect(c.items, hasLength(2));
      expect(c.items.first.title, 'Maths BAC');
      expect(c.items.first.courseId, isNull);
      expect(c.items.last.courseId, 9);
      expect(c.items.last.price, 2500.0);
      expect(c.items.first.addedAt.toUtc(), DateTime.utc(2026, 1, 5, 10));
      expect(c.itemsCount, 2);
      expect(c.subtotal, 3500.0);
      expect(c.discount, 500.0);
      expect(c.tax, 467.5);
      expect(c.total, 3000.0);
      expect(c.currency, 'XAF');
    });

    test('une reponse vide donne un panier a zero en XAF', () async {
      faux.repond('GET', '/cart', <String, dynamic>{});
      final c = await CartService.instance.getCart();
      expect(c.items, isEmpty);
      expect(c.total, 0);
      expect(c.currency, 'XAF');
    });

    test('en cas d\'erreur reseau ou serveur, getCart rend le panier vide au lieu de lever', () async {
      faux.coupure('GET', '/cart');
      expect(identical(await CartService.instance.getCart(), ApiCart.empty), isTrue);
      faux.repond('GET', '/cart', {'error': 'panne'}, statut: 500);
      expect(identical(await CartService.instance.getCart(), ApiCart.empty), isTrue);
    });

    test('addItem envoie subjectId et renvoie le panier mis a jour, ou null en cas d\'echec', () async {
      faux.repond('POST', '/cart/items', {'items': [article()], 'itemsCount': 1, 'total': 1000});
      final c = await CartService.instance.addItem(7);
      expect(c, isNotNull);
      expect(c!.itemsCount, 1);
      expect(faux.recues('POST', '/cart/items').single.data, {'subjectId': 7});

      faux.repond('POST', '/cart/items', {'error': 'x'}, statut: 500);
      expect(await CartService.instance.addItem(7), isNull);
    });

    test('addCourse : null en cas de succes, message du serveur sinon', () async {
      faux.repond('POST', '/cart/items', {});
      expect(await CartService.instance.addCourse(9), isNull);
      expect(faux.recues('POST', '/cart/items').single.data, {'courseId': 9});

      faux.repond('POST', '/cart/items', {'error': 'Formation deja achetee'}, statut: 409);
      expect(await CartService.instance.addCourse(9), 'Formation deja achetee');
    });

    test('addCourse : message par defaut si le corps d\'erreur n\'est pas un objet ou sans reseau', () async {
      faux.repond('POST', '/cart/items', 'oups', statut: 500);
      expect(await CartService.instance.addCourse(9), L10n.current.svcCartAddCourseFailed);
      faux.coupure('POST', '/cart/items');
      expect(await CartService.instance.addCourse(9), 'Impossible d\'ajouter la formation au panier.');
    });

    test('removeItem et clear : true si le serveur accepte, false sinon', () async {
      faux.repond('DELETE', '/cart/items/3', null, statut: 204);
      faux.repond('DELETE', '/cart', null, statut: 204);
      expect(await CartService.instance.removeItem(3), isTrue);
      expect(await CartService.instance.clear(), isTrue);
      faux.repond('DELETE', '/cart/items/3', {}, statut: 404);
      faux.repond('DELETE', '/cart', {}, statut: 500);
      expect(await CartService.instance.removeItem(3), isFalse);
      expect(await CartService.instance.clear(), isFalse);
    });

    test('applyPromo : reduction et montant final, ou message d\'erreur', () async {
      faux.repond('POST', '/cart/promo', {'success': true, 'discount': 300, 'finalAmount': 2700});
      var r = await CartService.instance.applyPromo('PROMO10');
      expect(r.success, isTrue);
      expect(r.discount, 300.0);
      expect(r.finalAmount, 2700.0);
      expect(faux.recues('POST', '/cart/promo').single.data, {'code': 'PROMO10'});

      faux.repond('POST', '/cart/promo', {'error': 'Code expire'}, statut: 400);
      r = await CartService.instance.applyPromo('VIEUX');
      expect(r.success, isFalse);
      expect(r.error, 'Code expire');

      faux.repond('POST', '/cart/promo', {}, statut: 400);
      r = await CartService.instance.applyPromo('VIEUX');
      expect(r.error, 'Code promo invalide.');
    });

    test('removePromo appelle la route et n\'echoue jamais', () async {
      faux.repond('DELETE', '/cart/promo', null, statut: 204);
      await CartService.instance.removePromo();
      expect(faux.recues('DELETE', '/cart/promo'), hasLength(1));
      faux.coupure('DELETE', '/cart/promo');
      await CartService.instance.removePromo();
      expect(faux.recues('DELETE', '/cart/promo'), hasLength(2));
    });
  });

  group('CertificateService', () {
    test('lit la liste enveloppee dans data, avec les champs de CertificateDto', () async {
      faux.repond('GET', '/certificates/user/my-certificates', {
        'success': true,
        'data': [
          {'id': 3, 'subjectTitle': 'Algebre', 'issuedAt': '2026-02-01', 'fileUrl': 'https://x/c.pdf', 'grade': 17.5, 'verificationCode': '  AB12  '},
        ],
      });
      final l = await CertificateService.instance.getCertificates();
      expect(l, hasLength(1));
      expect(l.single.id, 3);
      expect(l.single.title, 'Algebre');
      expect(l.single.subjectName, 'Algebre');
      expect(l.single.pdfUrl, 'https://x/c.pdf');
      expect(l.single.score, 18);
      expect(l.single.verificationCode, 'AB12');
    });

    test('accepte aussi une liste brute et les anciens noms de champs', () async {
      faux.repond('GET', '/certificates/user/my-certificates', [
        {'id': 1, 'title': 'Ancien', 'subjectName': 'Physique', 'pdfUrl': 'u', 'score': 12},
      ]);
      final l = await CertificateService.instance.getCertificates();
      expect(l.single.title, 'Ancien');
      expect(l.single.subjectName, 'Physique');
      expect(l.single.pdfUrl, 'u');
      expect(l.single.score, 12);
      expect(l.single.issuedAt, '');
    });

    test('un code de verification vide ou absent donne null', () async {
      faux.repond('GET', '/certificates/user/my-certificates', {
        'data': [
          {'id': 1, 'verificationCode': '   '},
          {'id': 2},
        ],
      });
      final l = await CertificateService.instance.getCertificates();
      expect(l[0].verificationCode, isNull);
      expect(l[1].verificationCode, isNull);
      expect(l[1].score, isNull);
    });

    test('une reponse sans liste donne une liste vide, une erreur serveur est levee', () async {
      faux.repond('GET', '/certificates/user/my-certificates', {'success': true});
      expect(await CertificateService.instance.getCertificates(), isEmpty);
      faux.repond('GET', '/certificates/user/my-certificates', {'error': 'x'}, statut: 500);
      await expectLater(CertificateService.instance.getCertificates(), throwsA(isA<DioException>()));
    });
  });

  group('FavoritesService', () {
    test('getAll lit la reponse paginee du serveur (items, titre dans subject)', () async {
      faux.repond('GET', '/favorites', {
        'items': [
          {'id': 1, 'subjectId': 10, 'addedAt': '2026-01-05T10:00:00Z', 'subject': {'id': 10, 'title': 'Bac C 2023'}},
        ],
        'totalCount': 1, 'page': 1, 'pageSize': 100,
      });
      final l = await FavoritesService.instance.getAll();
      expect(l.single.subjectTitle, 'Bac C 2023');
    });

    test('getAll convertit la liste', () async {
      faux.repond('GET', '/favorites', [
        {'id': 1, 'subjectId': 10, 'subjectTitle': 'Maths', 'addedAt': '2026-01-05T10:00:00Z'},
        {'id': 2, 'subjectId': 11, 'addedAt': 'pas une date'},
      ]);
      final l = await FavoritesService.instance.getAll();
      expect(l, hasLength(2));
      expect(l[0].subjectTitle, 'Maths');
      expect(l[0].addedAt.toUtc(), DateTime.utc(2026, 1, 5, 10));
      expect(l[1].subjectTitle, '');
      // Une date illisible est remplacee par l'instant present, jamais par une erreur.
      expect(l[1].addedAt.difference(DateTime.now()).inMinutes.abs(), lessThan(5));
    });

    test('add et remove rendent true si le serveur accepte, false sinon', () async {
      faux.repond('POST', '/favorites/10', {});
      faux.repond('DELETE', '/favorites/1', null, statut: 204);
      expect(await FavoritesService.instance.add(10), isTrue);
      expect(await FavoritesService.instance.remove(1), isTrue);
      faux.repond('POST', '/favorites/10', {}, statut: 409);
      faux.coupure('DELETE', '/favorites/1');
      expect(await FavoritesService.instance.add(10), isFalse);
      expect(await FavoritesService.instance.remove(1), isFalse);
    });
  });

  group('AchievementService', () {
    test('releve les badges (icone et couleur par code) et la serie de jours', () async {
      faux.repond('GET', '/users/profile/statistics', {'currentStreak': 6});
      faux.repond('GET', '/badges', {
        'data': [
          {'code': 'streak_7', 'title': 'Une semaine', 'description': '7 jours', 'unlocked': true, 'unlockedAt': '2026-01-05'},
          {'code': 'inconnu', 'title': 'Autre', 'description': 'd'},
        ],
      });
      final r = await AchievementService.instance.getMyAchievements();
      expect(r.streak, 6);
      expect(r.badges, hasLength(2));
      final b = r.badges.first;
      expect(b.id, 'streak_7');
      expect(b.name, 'Une semaine');
      expect(b.unlocked, isTrue);
      expect(b.unlockedAt, '2026-01-05');
      expect(b.icon, PhosphorIconsRegular.fire);
      expect(b.color, WinColors.warn);
      final autre = r.badges.last;
      expect(autre.unlocked, isFalse);
      expect(autre.unlockedAt, isNull);
      expect(autre.icon, PhosphorIconsRegular.trophy);
      expect(autre.color, WinColors.teal500);
    });

    test('sans donnees, serie a 0 et aucun badge', () async {
      faux.repond('GET', '/users/profile/statistics', <String, dynamic>{});
      faux.repond('GET', '/badges', <String, dynamic>{});
      final r = await AchievementService.instance.getMyAchievements();
      expect(r.streak, 0);
      expect(r.badges, isEmpty);
    });
  });
}
