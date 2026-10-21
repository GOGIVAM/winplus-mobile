import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../auth/welcome_screen.dart';
import 'learning_style_quiz_screen.dart';

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

  bool _notifQuiz = true,
      _notifAI = true,
      _notifPromo = false,
      _notifExam = true,
      _notifCommunity = false;
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
      content:
          Text(ok ? L10n.current.studentProfileUpdated : L10n.current.studentProfileUpdateError),
    ));
  }

  Future<void> _changePwd() async {
    final cur = _curPwdCtrl.text;
    final next = _newPwdCtrl.text;
    final conf = _confPwdCtrl.text;
    if (cur.isEmpty || next.isEmpty || conf.isEmpty) {
      setState(() => _pwdError = L10n.current.fillAllFields);
      return;
    }
    if (next != conf) {
      setState(() => _pwdError = L10n.current.studentProfilePwdMismatch);
      return;
    }
    setState(() {
      _savingPwd = true;
      _pwdError = null;
    });
    final ok = await UserService.instance.changePassword(cur, next);
    if (!mounted) return;
    setState(() => _savingPwd = false);
    if (ok) {
      _curPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confPwdCtrl.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L10n.current.studentProfilePwdChanged)));
    } else {
      setState(() => _pwdError = L10n.current.studentProfilePwdWrong);
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
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.studentProfileTitle, style: WinType.headlineS(s.onStrong)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: s.primary,
          unselectedLabelColor: s.onMuted,
          indicatorColor: s.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: WinType.manrope(size: 13, weight: FontWeight.w600),
          tabs: [
            Tab(text: context.l10n.studentProfileTitle),
            Tab(text: context.l10n.studentProfileTabSecurity),
            Tab(text: context.l10n.studentNotifTitle),
            Tab(text: context.l10n.studentProfileTabPrivacy),
            Tab(text: context.l10n.studentHubAccount),
          ],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // ---- PROFIL ----
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
                child: Column(children: [
              WinAvatar(_profile?.fullName ?? '…', size: 72),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Text(context.l10n.studentProfileChangePhoto,
                    style: WinType.labelM(s.primary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ])),
            const SizedBox(height: 24),
            WinTextField(
                label: context.l10n.studentProfileFullName,
                controller: _nameCtrl,
                icon: Icons.person_outline),
            const SizedBox(height: 14),
            WinTextField(
                label: context.l10n.email,
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            WinTextField(
                label: context.l10n.studentProfilePhone,
                controller: _phoneCtrl,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            WinTextField(
                label: context.l10n.commonLevel,
                controller: _levelCtrl,
                icon: Icons.school_outlined),
            const SizedBox(height: 28),
            WinButton(context.l10n.studentProfileSaveChanges,
                block: true, loading: _savingProfile, onTap: _saveProfile),
            const SizedBox(height: 16),
            // Module 15 (lot 6) : parité mobile du questionnaire VARK, jusqu'ici
            // web uniquement (LearningStyleQuiz.tsx).
            WinButton(
              context.l10n.studentProfileLearningStyle,
              block: true,
              variant: WinButtonVariant.outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningStyleQuizScreen()),
              ),
            ),
          ]),
        ),

        // ---- SÉCURITÉ ----
        ListView(padding: const EdgeInsets.all(20), children: [
          // Module 40 (lot 8, décision 15.2) : changement d'adresse email,
          // parité avec l'onglet Sécurité web (demande → code → confirmation).
          _EmailChangeCard(
            currentEmail: _profile?.email ?? _emailCtrl.text,
            onChanged: (newEmail) {
              setState(() {
                _emailCtrl.text = newEmail;
                if (_profile != null) {
                  _profile = ApiUserProfile(
                    id: _profile!.id,
                    email: newEmail,
                    firstName: _profile!.firstName,
                    lastName: _profile!.lastName,
                    phone: _profile!.phone,
                    role: _profile!.role,
                    level: _profile!.level,
                    locale: _profile!.locale,
                    avatarUrl: _profile!.avatarUrl,
                    dateOfBirth: _profile!.dateOfBirth,
                  );
                }
              });
            },
          ),
          const SizedBox(height: 28),
          const WinDivider(),
          const SizedBox(height: 20),
          Text(context.l10n.studentProfileChangePwd, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 14),
          WinTextField(
              label: context.l10n.studentProfileCurrentPwd,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _curPwdCtrl),
          const SizedBox(height: 12),
          WinTextField(
              label: context.l10n.authNewPassword,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _newPwdCtrl),
          const SizedBox(height: 12),
          WinTextField(
              label: context.l10n.commonConfirm,
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _confPwdCtrl),
          if (_pwdError != null) ...[
            const SizedBox(height: 10),
            WinAlert(_pwdError!, type: BadgeColor.error),
          ],
          const SizedBox(height: 20),
          WinButton(context.l10n.studentProfileChangePwd,
              block: true,
              variant: WinButtonVariant.outline,
              loading: _savingPwd,
              onTap: _changePwd),
          const SizedBox(height: 28),
          const WinDivider(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentProfile2fa,
                      style: WinType.titleM(s.onStrong)),
                  Text(context.l10n.studentProfile2faHint,
                      style: WinType.bodyS(s.onMuted)),
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
                      SnackBar(content: Text(res.message ?? L10n.current.studentCourseError)));
                }
              },
            ),
          ]),
          const SizedBox(height: 28),
          const WinDivider(),
          const SizedBox(height: 20),
          Text(context.l10n.studentProfileActiveSessions, style: WinType.headlineS(s.onStrong)),
          const SizedBox(height: 12),
          WinCard(
              child: Row(children: [
            Icon(Icons.phone_android, size: 24, color: s.onFaint),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Android · Yaoundé', style: WinType.titleM(s.onStrong)),
                  Text(context.l10n.studentProfileCurrentSession,
                      style: WinType.labelM(s.onFaint)),
                ])),
            WinBadge(context.l10n.commonActive, color: BadgeColor.success),
          ])),
        ]),

        // ---- NOTIFICATIONS ----
        Builder(builder: (ctx) {
          final items = [
            (
              'quiz',
              _notifQuiz,
              ctx.l10n.studentProfileNotifQuiz,
              ctx.l10n.studentProfileNotifQuizSub
            ),
            (
              'ai',
              _notifAI,
              ctx.l10n.studentProfileNotifAi,
              ctx.l10n.studentProfileNotifAiSub
            ),
            (
              'promo',
              _notifPromo,
              ctx.l10n.studentProfileNotifPromo,
              ctx.l10n.studentProfileNotifPromoSub
            ),
            (
              'exam',
              _notifExam,
              ctx.l10n.studentProfileNotifExam,
              ctx.l10n.studentProfileNotifExamSub
            ),
            (
              'community',
              _notifCommunity,
              ctx.l10n.studentHubCommunity,
              ctx.l10n.studentProfileNotifCommunitySub
            ),
          ];
          return ListView(padding: const EdgeInsets.all(20), children: [
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.$3, style: WinType.titleM(s.onStrong)),
                          Text(item.$4, style: WinType.bodyS(s.onMuted)),
                        ])),
                    Switch(
                        value: item.$2,
                        onChanged: (v) => setState(() {
                              switch (item.$1) {
                                case 'quiz':
                                  _notifQuiz = v;
                                case 'ai':
                                  _notifAI = v;
                                case 'promo':
                                  _notifPromo = v;
                                case 'exam':
                                  _notifExam = v;
                                case 'community':
                                  _notifCommunity = v;
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
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentProfileVisible, style: WinType.titleM(s.onStrong)),
                  Text(context.l10n.studentProfileVisibleHint,
                      style: WinType.bodyS(s.onMuted)),
                ])),
            Switch(
                value: _profilePublic,
                onChanged: (v) => setState(() => _profilePublic = v),
                activeTrackColor: s.primary),
          ]),
          const SizedBox(height: 16),
          const WinDivider(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.l10n.studentProfileAnonStats,
                      style: WinType.titleM(s.onStrong)),
                  Text(context.l10n.studentProfileAnonStatsHint,
                      style: WinType.bodyS(s.onMuted)),
                ])),
            Switch(
                value: _shareStats,
                onChanged: (v) => setState(() => _shareStats = v),
                activeTrackColor: s.primary),
          ]),
          const SizedBox(height: 24),
          const WinDivider(),
          const SizedBox(height: 20),
          WinButton(context.l10n.studentHubPrivacy,
              variant: WinButtonVariant.ghost, block: true, onTap: () {}),
          const SizedBox(height: 8),
          WinButton(context.l10n.studentHubTerms,
              variant: WinButtonVariant.ghost, block: true, onTap: () {}),
        ]),

        // ---- COMPTE ----
        _TabCompte(profile: _profile),
      ]),
    );
  }
}

/// Module 40 (lot 8, décision 15.2) : bloc "Adresse e-mail" en 2 étapes
/// (demande → code), calqué sur frontend/src/pages/Profile.tsx (onglet
/// Sécurité). Aucun mot de passe redemandé : seule la nouvelle adresse, puis
/// le code à 6-10 caractères reçu par email (contrainte exacte du serveur,
/// UserDTOs.ConfirmEmailChangeRequest, plus large que les 6 chiffres affichés
/// par le web).
class _EmailChangeCard extends StatefulWidget {
  final String currentEmail;
  final ValueChanged<String> onChanged;
  const _EmailChangeCard({required this.currentEmail, required this.onChanged});

  @override
  State<_EmailChangeCard> createState() => _EmailChangeCardState();
}

enum _EmailChangeStep { collapsed, form, code }

class _EmailChangeCardState extends State<_EmailChangeCard> {
  _EmailChangeStep _step = _EmailChangeStep.collapsed;
  final _newEmailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _pendingEmail;
  String? _error;
  bool _loading = false;

  void _reset() {
    setState(() {
      _step = _EmailChangeStep.collapsed;
      _newEmailCtrl.clear();
      _codeCtrl.clear();
      _pendingEmail = null;
      _error = null;
    });
  }

  Future<void> _requestCode() async {
    final newEmail = _newEmailCtrl.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      setState(() => _error = L10n.current.studentProfileEmailInvalid);
      return;
    }
    if (newEmail.toLowerCase() == widget.currentEmail.toLowerCase()) {
      setState(() => _error = L10n.current.studentProfileEmailSame);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await UserService.instance.requestEmailChange(newEmail);
      if (!mounted) return;
      setState(() {
        _pendingEmail = newEmail;
        _step = _EmailChangeStep.code;
        _loading = false;
      });
    } on EmailChangeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _confirmCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) {
      setState(() => _error = L10n.current.studentProfileEnterCode);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final confirmed = await UserService.instance.confirmEmailChange(code);
      if (!mounted) return;
      widget.onChanged(confirmed.isNotEmpty ? confirmed : (_pendingEmail ?? widget.currentEmail));
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.studentProfileEmailChanged)));
      _reset();
    } on EmailChangeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    if (_step == _EmailChangeStep.collapsed) {
      return WinCard(
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(context.l10n.studentProfileEmailAddress, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 2),
                Text(context.l10n.studentProfileEmailCurrent(widget.currentEmail),
                    style: WinType.bodyS(s.onMuted)),
              ])),
          TextButton(
            onPressed: () => setState(() => _step = _EmailChangeStep.form),
            child: Text(context.l10n.studentProfileChange,
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    if (_step == _EmailChangeStep.form) {
      return WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.studentProfileNewEmailAddress, style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 12),
        WinTextField(
          label: context.l10n.studentProfileNewEmail,
          icon: Icons.email_outlined,
          controller: _newEmailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          WinAlert(_error!, type: BadgeColor.error),
        ],
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: WinButton(context.l10n.commonCancel,
                  variant: WinButtonVariant.ghost, onTap: _reset)),
          const SizedBox(width: 10),
          Expanded(
              child: WinButton(context.l10n.studentProfileGetCode,
                  loading: _loading, onTap: _requestCode)),
        ]),
      ]));
    }

    // _EmailChangeStep.code
    return WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.l10n.studentProfileConfirmCode, style: WinType.titleM(s.onStrong)),
      const SizedBox(height: 6),
      Text(
          context.l10n.studentProfileCodeSent(_pendingEmail ?? ''),
          style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 12),
      WinTextField(
        label: context.l10n.studentProfileCodeReceived,
        icon: Icons.pin_outlined,
        controller: _codeCtrl,
        keyboardType: TextInputType.number,
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        WinAlert(_error!, type: BadgeColor.error),
      ],
      const SizedBox(height: 14),
      WinButton(context.l10n.commonConfirm, block: true, loading: _loading, onTap: _confirmCode),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: WinButton(context.l10n.commonCancel,
                variant: WinButtonVariant.ghost, onTap: _reset)),
        const SizedBox(width: 10),
        Expanded(
            child: WinButton(context.l10n.authResendCode,
                variant: WinButtonVariant.outline,
                loading: _loading,
                onTap: _requestCode)),
      ]),
    ]));
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
      WinPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = _sub;
    return ListView(padding: const EdgeInsets.all(20), children: [
      WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(sub != null ? context.l10n.studentHubPlan(sub.planName) : context.l10n.commonLoading,
              style: WinType.headlineS(s.onStrong)),
          const Spacer(),
          WinBadge(sub == null ? '…' : sub.hasPlan ? context.l10n.commonActive : context.l10n.commonFree,
              color: BadgeColor.success),
        ]),
        if (sub != null && sub.expiresAt != null) ...[
          const SizedBox(height: 4),
          Text(
              context.l10n.studentProfilePeriodEnd(WinFormat.dateNumeric(sub.expiresAt!)),
              style: WinType.bodyS(s.onMuted)),
        ],
        const SizedBox(height: 14),
        WinButton(context.l10n.studentProfileManageSub,
            block: true,
            variant: WinButtonVariant.outline,
            icon: Icons.credit_card_outlined,
            onTap: () {}),
      ])),
      const SizedBox(height: 24),
      WinDivider(label: context.l10n.studentProfileDangerZone),
      const SizedBox(height: 16),
      WinAlert(context.l10n.studentProfileDeleteWarning,
          type: BadgeColor.error),
      const SizedBox(height: 14),
      WinButton(context.l10n.studentProfileDeleteAccount,
          block: true,
          variant: WinButtonVariant.danger,
          icon: Icons.delete_outline,
          onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WinRadii.xl)),
                  title: Text(context.l10n.studentProfileDeleteTitle),
                  content: Text(
                      context.l10n.studentProfileDeleteBody),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.commonCancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.l10n.commonDelete,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              )),
      const SizedBox(height: 20),
      TextButton(
        onPressed: _signOut,
        child: Text(context.l10n.commonLogout,
            style: WinType.manrope(
                size: 14, weight: FontWeight.w600, color: Colors.red)),
      ),
    ]);
  }
}
