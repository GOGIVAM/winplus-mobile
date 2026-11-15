import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'session_manager.dart';
import 'user_service.dart';

/// Notifications du système (barre d'état), sans Firebase (lot 2, Communs 2).
///
/// Le serveur ne pousse rien vers le téléphone : l'application lit elle-même
/// GET /notifications, soit à chaque signal du flux ntfy (service au premier
/// plan), soit toutes les 15 minutes environ (tâche WorkManager de secours).
/// [NotificationSync] décide quoi afficher ; cette classe l'affiche.
class SystemNotifications {
  SystemNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Canal des notifications du compte (messages, corrections, alertes).
  static const channelId = 'winplus_notifications';

  /// Prépare l'affichage. Sans effet hors Android et iOS (tests, Windows).
  static Future<void> init() async {
    if (_ready || !(Platform.isAndroid || Platform.isIOS)) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // L'autorisation est demandée plus tard, à l'ouverture de l'espace
        // du compte, pas dès le premier lancement.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Android 13 et plus, iOS : demande l'autorisation d'afficher des
  /// notifications. Renvoie faux si la personne refuse.
  static Future<bool> requestPermission() async {
    await init();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  static Future<void> show(ApiNotification n) async {
    await init();
    if (!_ready) return;
    final l = L10n.current;
    await _plugin.show(
      // Identifiant serveur : une même notification n'est jamais affichée
      // deux fois, elle remplace la précédente.
      id: n.id,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          l.notifChannelName,
          channelDescription: l.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: '${n.id}',
    );
  }
}

/// Choisit les notifications à afficher dans la barre d'état.
///
/// Règle : seules les notifications non lues, plus récentes que la dernière
/// déjà affichée (numéro mémorisé), sont montrées. Au tout premier passage,
/// rien n'est affiché : on mémorise seulement où l'on en est, pour ne pas
/// déverser d'un coup l'historique du compte.
class NotificationSync {
  NotificationSync._();

  static const lastShownKey = 'notif_last_shown_id';

  /// Au plus quelques notifications par passage : un retour après une longue
  /// coupure ne doit pas remplir la barre d'état.
  static const maxPerCheck = 5;

  /// Relit les notifications du serveur et affiche les nouvelles. Renvoie le
  /// nombre affiché. Ne lève jamais : une panne réseau attend le passage
  /// suivant.
  static Future<int> checkAndNotify({
    Future<List<ApiNotification>> Function()? fetch,
    Future<void> Function(ApiNotification)? display,
  }) async {
    try {
      if (!await SessionManager.isLoggedIn()) return 0;
      final items = await (fetch ??
          () async => (await UserService.instance
                  .getNotificationsPage(page: 1, limit: 20))
              .items)();
      final prefs = await SharedPreferences.getInstance();
      // Un autre isolat a pu avancer le numéro entre-temps.
      await prefs.reload();
      final last = prefs.getInt(lastShownKey);
      if (items.isEmpty) {
        if (last == null) await prefs.setInt(lastShownKey, 0);
        return 0;
      }
      final newest = items.map((n) => n.id).reduce((a, b) => a > b ? a : b);
      if (last == null) {
        await prefs.setInt(lastShownKey, newest);
        return 0;
      }
      final fresh = items.where((n) => !n.isRead && n.id > last).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final shown = fresh.length > maxPerCheck
          ? fresh.sublist(fresh.length - maxPerCheck)
          : fresh;
      final show = display ?? SystemNotifications.show;
      for (final n in shown) {
        await show(n);
      }
      if (newest > last) await prefs.setInt(lastShownKey, newest);
      return shown.length;
    } catch (e) {
      debugPrint('NotificationSync: $e');
      return 0;
    }
  }

  /// À la déconnexion : le compte suivant repart de zéro.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastShownKey);
  }
}
