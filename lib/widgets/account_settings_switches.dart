import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/user_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'win_widgets.dart';
import 'win_screen.dart';

enum AccountSettingsKind { notifications, privacy }

/// Page autonome des préférences (profil parent, écran « Plus »).
class AccountSettingsScreen extends StatelessWidget {
  final AccountSettingsKind kind;
  final String title;
  const AccountSettingsScreen({super.key, required this.kind, required this.title});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [AccountSettingsSwitches(kind: kind)],
      ),
    );
  }
}

/// Préférences du compte enregistrées sur le serveur, comme la page Profil
/// du site : 6 réglages de notifications ou 4 de confidentialité, enregistrés
/// automatiquement à chaque changement. Remplace des interrupteurs qui ne
/// changeaient que l'écran (jamais enregistrés, revenus à leur valeur au
/// prochain lancement).
class AccountSettingsSwitches extends StatefulWidget {
  final AccountSettingsKind kind;
  const AccountSettingsSwitches({super.key, required this.kind});

  @override
  State<AccountSettingsSwitches> createState() =>
      _AccountSettingsSwitchesState();
}

class _AccountSettingsSwitchesState extends State<AccountSettingsSwitches> {
  Map<String, bool>? _values;
  bool _error = false;

  String get _route =>
      widget.kind == AccountSettingsKind.notifications ? 'notifications' : 'privacy';

  /// Réglages affichés, dans l'ordre du site (champs du serveur).
  List<String> get _keys => widget.kind == AccountSettingsKind.notifications
      ? const [
          'emailNotifications',
          'pushNotifications',
          'courseCommunity',
          'promotions',
          'newsletters',
          'learningReminders',
        ]
      : const ['profileVisible', 'showProgressPublic', 'allowMessages', 'allowFriends'];

  (String, String) _label(AppLocalizations l, String key) => switch (key) {
        'emailNotifications' => (l.settingsEmailNotif, l.settingsEmailNotifDesc),
        'pushNotifications' => (l.settingsPushNotif, l.settingsPushNotifDesc),
        'courseCommunity' => (l.settingsCommunity, l.settingsCommunityDesc),
        'promotions' => (l.settingsPromotions, l.settingsPromotionsDesc),
        'newsletters' => (l.settingsNewsletter, l.settingsNewsletterDesc),
        'learningReminders' => (l.settingsReminders, l.settingsRemindersDesc),
        'profileVisible' => (l.settingsProfileVisible, l.settingsProfileVisibleDesc),
        'showProgressPublic' => (l.settingsProgressPublic, l.settingsProgressPublicDesc),
        'allowMessages' => (l.settingsAllowMessages, l.settingsAllowMessagesDesc),
        _ => (l.settingsAllowFriends, l.settingsAllowFriendsDesc),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _values = null;
      _error = false;
    });
    try {
      final v = await UserService.instance.getAccountSettings(_route);
      if (mounted) setState(() => _values = v);
    } catch (_) {
      if (mounted) {
        setState(() {
          _values = const {};
          _error = true;
        });
      }
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final before = Map<String, bool>.from(_values!);
    final next = {...before, key: value};
    setState(() => _values = next);
    final ok = await UserService.instance.saveAccountSettings(_route, next);
    if (!mounted || ok) return;
    // Échec : la valeur revient, la personne le voit.
    setState(() => _values = before);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaveError)));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final values = _values;
    if (values == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: const WinLoading(),
      );
    }
    if (_error) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(l.settingsLoadError,
              textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 12),
          WinButton(l.commonRetry, variant: WinButtonVariant.outline, onTap: _load),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final key in _keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_label(l, key).$1, style: WinType.titleM(s.onStrong)),
                Text(_label(l, key).$2, style: WinType.bodyS(s.onMuted)),
              ]),
            ),
            Switch(
              value: values[key] ?? false,
              activeTrackColor: s.primary,
              onChanged: (v) => _toggle(key, v),
            ),
          ]),
        ),
      Text(l.settingsAutoSave, style: WinType.bodyS(s.onFaint)),
    ]);
  }
}
