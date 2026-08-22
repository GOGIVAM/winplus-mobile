import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);

  ApiUserProfile? _profile;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _levelCtrl = TextEditingController();

  final _curPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confPwdCtrl = TextEditingController();

  bool _notifQuiz = true, _notifAI = true, _notifPromo = false,
      _notifExam = true, _notifCommunity = false;
  bool _profilePublic = true, _shareStats = false;
  bool _twoFactor = false;
  bool _savingProfile = false;
  bool _savingPwd = false;
  String? _pwdError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.instance.getProfile();
      if (mounted) {
        setState(() {
          _profile = p;
          _nameCtrl.text = p.fullName;
          _emailCtrl.text = p.email;
          _phoneCtrl.text = p.phone ?? '';
          _levelCtrl.text = p.level ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final parts = _nameCtrl.text.trim().split(' ');
    final ok = await UserService.instance.updateProfile(
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      level: _levelCtrl.text.trim().isEmpty ? null : _levelCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profil mis à jour.' : 'Erreur lors de la mise à jour.'),
    ));
  }

  Future<void> _changePwd() async {
    final cur = _curPwdCtrl.text;
    final next = _newPwdCtrl.text;
    final conf = _confPwdCtrl.text;
    if (cur.isEmpty || next.isEmpty || conf.isEmpty) {
      setState(() => _pwdError = 'Veuillez remplir tous les champs.');
      return;
    }
    if (next != conf) {
      setState(() => _pwdError = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() { _savingPwd = true; _pwdError = null; });
    final ok = await UserService.instance.changePassword(cur, next);
    if (!mounted) return;
    setState(() => _savingPwd = false);
    if (ok) {
      _curPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confPwdCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié.')));
    } else {
      setState(() => _pwdError = 'Mot de passe actuel incorrect.');
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profil', style: WinType.headlineS(s.onStrong)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: s.primary,
          unselectedLabelColor: s.onMuted,
          indicatorColor: s.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: WinType.manrope(size: 13, weight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Sécurité'),
            Tab(text: 'Notifications'),
            Tab(text: 'Confidentialité'),
            Tab(text: 'Compte'),
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // ---- PROFIL ----
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Column(children: [
              WinAvatar(_profile?.fullName ?? '…', size: 72),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Text('Modifier la photo',
                    style: WinType.labelM(s.primary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ])),
            const SizedBox(height: 24),
            WinTextField(label: 'Nom complet', controller: _nameCtrl, icon: Icons.person_outline),
            const SizedBox(height: 14),
            WinTextField(label: 'Email', controller: _emailCtrl, icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            WinTextField(label: 'Téléphone', controller: _phoneCtrl, icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            WinTextField(label: 'Niveau', controller: _levelCtrl, icon: Icons.school_outlined),
            const SizedBox(height: 28),
            WinButton('Enregistrer les modifications', block: true,
                loading: _savingProfile, onTap: _saveProfile),
          ]),
        ),

        // ---- SÉCURITÉ ----
        ListView(padding: const EdgeInsets.all(20), children: [
          Text('Changer le mot de passe', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 14),
          WinTextField(label: 'Mot de passe actuel', hint: '••••••••',
              icon: Icons.lock_outline, obscure: true, controller: _curPwdCtrl),
          const SizedBox(height: 12),
          WinTextField(label: 'Nouveau mot de passe', hint: '••••••••',
              icon: Icons.lock_outline, obscure: true, controller: _newPwdCtrl),
          const SizedBox(height: 12),
          WinTextField(label: 'Confirmer', hint: '••••••••',
              icon: Icons.lock_outline, obscure: true, controller: _confPwdCtrl),
          if (_pwdError != null) ...[
            const SizedBox(height: 10),
            WinAlert(_pwdError!, type: BadgeColor.error),
          ],
          const SizedBox(height: 20),
          WinButton('Changer le mot de passe', block: true,
              variant: WinButtonVariant.outline,
              loading: _savingPwd,
              onTap: _changePwd),
          const SizedBox(height: 28),
          const WinDivider(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Authentification à 2 facteurs', style: WinType.titleM(s.onStrong)),
              Text('Un code email à chaque connexion.', style: WinType.bodyS(s.onMuted)),
            ])),
            Switch(
              value: _twoFactor,
              activeTrackColor: s.primary,
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                final res = v
                    ? await AuthService.instance.enable2FA()
                    : await AuthService.instance.disable2FA();
                if (!mounted) return;
                if (res.success) {
                  setState(() => _twoFactor = v);
                } else {
                  messenger.showSnackBar(
                      SnackBar(content: Text(res.message ?? 'Erreur')));
                }
              },
            ),
          ]),
          const SizedBox(height: 28),
          const WinDivider(),
          const SizedBox(height: 20),
          Text('Sessions actives', style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          WinCard(child: Row(children: [
            Icon(Icons.phone_android, size: 24, color: s.onFaint),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Android · Yaoundé', style: WinType.titleM(s.onStrong)),
              Text('Maintenant · Session actuelle', style: WinType.labelM(s.onFaint)),
            ])),
            const WinBadge('Actif', color: BadgeColor.success),
          ])),
        ]),

        // ---- NOTIFICATIONS ----
        Builder(builder: (ctx) {
          final items = [
            ('quiz', _notifQuiz, 'Résultats de quiz', 'Recevoir vos scores après chaque quiz'),
            ('ai', _notifAI, 'Recommandations WinAI', 'Alertes et conseils personnalisés'),
            ('promo', _notifPromo, 'Offres et promotions', 'Nouveaux contenus, promotions'),
            ('exam', _notifExam, 'Rappels d\'examens', 'Compte à rebours avant vos examens'),
            ('community', _notifCommunity, 'Communauté', 'Réponses à vos questions'),
          ];
          return ListView(padding: const EdgeInsets.all(20), children: [
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.$3, style: WinType.titleM(s.onStrong)),
                  Text(item.$4, style: WinType.bodyS(s.onMuted)),
                ])),
                Switch(value: item.$2,
                    onChanged: (v) => setState(() {
                      switch (item.$1) {
                        case 'quiz': _notifQuiz = v;
                        case 'ai': _notifAI = v;
                        case 'promo': _notifPromo = v;
                        case 'exam': _notifExam = v;
                        case 'community': _notifCommunity = v;
                      }
                    }),
                    activeTrackColor: s.primary),
              ]),
            )),
          ]);
        }),

        // ---- CONFIDENTIALITÉ ----
        ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Profil visible', style: WinType.titleM(s.onStrong)),
              Text('Visible par la communauté WinPlus.', style: WinType.bodyS(s.onMuted)),
            ])),
            Switch(value: _profilePublic, onChanged: (v) => setState(() => _profilePublic = v),
                activeTrackColor: s.primary),
          ]),
          const SizedBox(height: 16),
          const WinDivider(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Statistiques anonymisées', style: WinType.titleM(s.onStrong)),
              Text('Aide à améliorer WinPlus.', style: WinType.bodyS(s.onMuted)),
            ])),
            Switch(value: _shareStats, onChanged: (v) => setState(() => _shareStats = v),
                activeTrackColor: s.primary),
          ]),
          const SizedBox(height: 24),
          const WinDivider(),
          const SizedBox(height: 20),
          WinButton('Politique de confidentialité',
              variant: WinButtonVariant.ghost, block: true, onTap: () {}),
          const SizedBox(height: 8),
          WinButton('Conditions d\'utilisation',
              variant: WinButtonVariant.ghost, block: true, onTap: () {}),
        ]),

        // ---- COMPTE ----
        _TabCompte(profile: _profile),
      ]),
    );
  }
}

class _TabCompte extends StatefulWidget {
  final ApiUserProfile? profile;
  const _TabCompte({this.profile});
  @override
  State<_TabCompte> createState() => _TabCompteState();
}

class _TabCompteState extends State<_TabCompte> {
  ApiActiveSubscription? _sub;

  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.getCurrent().then((sub) {
      if (mounted && sub != null) setState(() => _sub = sub);
    });
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = _sub;
    return ListView(padding: const EdgeInsets.all(20), children: [
      WinCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(sub != null ? 'Plan ${sub.planName}' : 'Chargement…',
              style: WinType.headlineS(s.onStrong)),
          const Spacer(),
          WinBadge(sub?.isActive == true ? 'Actif' : '…', color: BadgeColor.success),
        ]),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text('Expire le ${sub.expiresAt.day.toString().padLeft(2,'0')}/${sub.expiresAt.month.toString().padLeft(2,'0')}/${sub.expiresAt.year}',
              style: WinType.bodyS(s.onMuted)),
        ],
        const SizedBox(height: 14),
        WinButton('Gérer mon abonnement', block: true,
            variant: WinButtonVariant.outline,
            icon: Icons.credit_card_outlined, onTap: () {}),
      ])),
      const SizedBox(height: 24),
      const WinDivider(label: 'Zone dangereuse'),
      const SizedBox(height: 16),
      const WinAlert('La suppression de votre compte est irréversible.',
          type: BadgeColor.error),
      const SizedBox(height: 14),
      WinButton('Supprimer mon compte', block: true,
          variant: WinButtonVariant.danger,
          icon: Icons.delete_outline,
          onTap: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Supprimer le compte ?'),
              content: const Text('Cette action est irréversible. Toutes vos données seront perdues.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler')),
                TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('Supprimer',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          )),
      const SizedBox(height: 20),
      TextButton(
        onPressed: _signOut,
        child: Text('Se déconnecter',
            style: WinType.manrope(size: 14, weight: FontWeight.w600, color: Colors.red)),
      ),
    ]);
  }
}
