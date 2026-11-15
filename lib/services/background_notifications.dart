import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../app_state.dart' show kLocalePrefKey;
import '../l10n/l10n.dart';
import 'api_client.dart';
import 'push_service.dart';
import 'session_manager.dart';
import 'system_notifications.dart';

/// Notifications application fermée sur Android, sans Firebase (lot 2,
/// Communs 2, décision du 14/11) :
///
/// - réception instantanée : un service au premier plan (type
///   `remoteMessaging`) garde ouvert le flux GET /notifications/sse, comme
///   PushService quand l'application est ouverte. Android impose une
///   notification fixe tant qu'il tourne ; la personne peut le couper dans
///   son profil. Il redémarre avec le téléphone ;
/// - secours : une tâche WorkManager relit /notifications toutes les 15
///   minutes environ, quand le service est coupé (par la personne ou par le
///   système, fréquent sur Tecno, Infinix, Xiaomi).
///
/// Les deux passent par [NotificationSync], qui n'affiche chaque
/// notification qu'une fois. Sur iOS, rien ici : seul APNs permet de
/// recevoir application fermée, à traiter avec la compilation iOS.
class BackgroundNotifications {
  BackgroundNotifications._();

  /// Préférence « notifications instantanées » (vrai par défaut). Gardée à
  /// la déconnexion, comme la langue.
  static const instantPrefKey = 'notif_instant_enabled';

  static const _periodicTask = 'winplus-notifications-check';
  static const _serviceId = 4271;

  /// Tests : force la présence du service (les tests tournent sous Windows).
  @visibleForTesting
  static bool? supportedOverride;

  /// Le service et la tâche de fond n'existent que sur Android.
  static bool get supported => supportedOverride ?? Platform.isAndroid;
  static bool get _supported => supported;

  /// À appeler une fois dans main(), avant runApp.
  static Future<void> initMainIsolate() async {
    if (!_supported) return;
    FlutterForegroundTask.initCommunicationPort();
    try {
      await Workmanager().initialize(notificationsCallbackDispatcher);
    } catch (e) {
      debugPrint('WorkManager indisponible : $e');
    }
  }

  static Future<bool> isInstantEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(instantPrefKey) ?? true;
  }

  /// À l'ouverture de l'espace du compte : demande l'autorisation, puis
  /// lance la vérification périodique et, si elle est choisie, l'écoute
  /// instantanée. Renvoie faux si les notifications sont refusées.
  static Future<bool> startForAccount() async {
    if (!_supported) return false;
    final allowed = await SystemNotifications.requestPermission();
    // Point de départ : rien de l'historique n'est affiché d'un coup.
    await NotificationSync.checkAndNotify(display: (_) async {});
    try {
      await Workmanager().registerPeriodicTask(
        _periodicTask,
        _periodicTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      debugPrint('Tâche périodique non enregistrée : $e');
    }
    if (allowed && await isInstantEnabled()) await _startService();
    return allowed;
  }

  /// À la déconnexion : plus rien n'écoute le compte précédent.
  static Future<void> stopForAccount() async {
    if (!_supported) return;
    await _stopService();
    try {
      await Workmanager().cancelByUniqueName(_periodicTask);
    } catch (_) {}
    await NotificationSync.reset();
  }

  /// Interrupteur du profil.
  static Future<void> setInstant(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(instantPrefKey, enabled);
    if (!_supported) return;
    if (enabled) {
      await _startService();
    } else {
      await _stopService();
    }
  }

  static void _initService() {
    final l = L10n.current;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'winplus_listener',
        channelName: l.notifServiceChannelName,
        channelDescription: l.notifServiceChannelDesc,
        // Discrète : pas de son ni de vibration pour la notification fixe.
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.MIN,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> _startService() async {
    try {
      _initService();
      if (await FlutterForegroundTask.isRunningService) return;
      final l = L10n.current;
      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: [ForegroundServiceTypes.remoteMessaging],
        notificationTitle: l.notifServiceTitle,
        notificationText: l.notifServiceText,
        callback: notificationsServiceStart,
      );
    } catch (e) {
      debugPrint('Service de notifications non démarré : $e');
    }
  }

  static Future<void> _stopService() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}

/// Prépare un isolat de fond : langue du compte, client réseau qui ne
/// déconnecte jamais et ne renouvelle pas le jeton pendant que
/// l'application est ouverte (elle s'en charge).
Future<void> _prepareBackgroundIsolate() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final code = prefs.getString(kLocalePrefKey);
  if (code == 'en' || code == 'fr') L10n.locale = Locale(code!);
  SessionManager.reload();
  ApiClient.instance.backgroundMode = true;
  ApiClient.instance.mayRefresh = () async => !await _appInForeground();
}

Future<bool> _appInForeground() async {
  try {
    return await FlutterForegroundTask.isAppOnForeground;
  } catch (_) {
    return false;
  }
}

/// Application ouverte : elle affiche déjà ses notifications (badge,
/// liste) ; la barre d'état n'en reçoit pas en double.
Future<void> _checkIfInBackground() async {
  if (await _appInForeground()) return;
  SessionManager.reload();
  await NotificationSync.checkAndNotify();
}

/// Tâche WorkManager (isolat de fond).
@pragma('vm:entry-point')
void notificationsCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await _prepareBackgroundIsolate();
      await _checkIfInBackground();
    } catch (e) {
      debugPrint('Vérification des notifications : $e');
    }
    // Toujours vrai : un échec réseau attend simplement le passage suivant,
    // sans relance accélérée par WorkManager.
    return true;
  });
}

/// Service au premier plan (isolat de fond).
@pragma('vm:entry-point')
void notificationsServiceStart() {
  FlutterForegroundTask.setTaskHandler(_NotificationsTaskHandler());
}

class _NotificationsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _prepareBackgroundIsolate();
    // PushService appelle le rappel à chaque connexion (rattrapage) puis à
    // chaque évènement du flux.
    await PushService.instance.start(() {
      _checkIfInBackground();
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    PushService.instance.stop();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
