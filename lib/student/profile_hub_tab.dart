import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../widgets/language_selector.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../auth/welcome_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../shared/subscription/pricing_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/legal_screen.dart';
import '../shared/study_timer_screen.dart';
import 'achievements_screen.dart';
import 'study_groups_screen.dart';
import 'student_reports_screen.dart';
import 'quiz_revision_screen.dart';
import 'certificates_screen.dart';
import 'download_history_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'my_links_screen.dart';
import 'tutors/tutor_policy_widgets.dart';
import '../shared/forum/forum_screen.dart';

class ProfileHubTab extends StatefulWidget {
  const ProfileHubTab({super.key});
  @override
  State<ProfileHubTab> createState() => _ProfileHubTabState();
}

class _ProfileHubTabState extends State<ProfileHubTab> {
  ApiUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotifCount();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.instance.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  /// Compteur serveur partagé (UserService.unreadNotifications) : il suit
  /// les lectures faites dans l'écran Notifications sans recharger ce profil.
  Future<void> _loadNotifCount() => UserService.instance.refreshUnreadCount();

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.studentHubLogoutTitle),
        content: Text(context.l10n.studentHubLogoutBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.studentHubLogoutConfirm,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      WinPageRoute(builder: (_) => const WelcomeScreen()),
      (r) => false,
    );
  }

  void _soon() => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.studentHubSoon)));

  void _go(Widget screen) =>
      Navigator.push(context, WinPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final appState = WinAppScope.of(context);
    final sub = SubscriptionScope.of(context);
    final name = _profile?.fullName ?? context.l10n.studentHubDefaultName;
    final planName = sub.planName;

    return Column(children: [
      // ── Header ──
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: s.surface,
          border: Border(bottom: BorderSide(color: s.outline)),
        ),
        child: Row(children: [
          WinAvatar(name, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: WinType.archivo(
                      size: 17, weight: FontWeight.w700, color: s.onStrong)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: WinColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(WinRadii.full),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.workspace_premium_outlined,
                        size: 13, color: WinColors.gold),
                    const SizedBox(width: 4),
                    Text(context.l10n.studentHubPlan(planName),
                        style: WinType.manrope(
                            size: 12,
                            weight: FontWeight.w700,
                            color: WinColors.gold)),
                  ]),
                ),
              ]),
            ]),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 22, color: s.onMuted),
            onPressed: () => _go(const ProfileScreen()),
          ),
        ]),
      ),

      // ── Body ──
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SectionLabel(context.l10n.studentHubLearning),
            const SizedBox(height: 8),
            _HubTile(
              icon: Icons.emoji_events_outlined,
              color: WinColors.gold,
              label: context.l10n.studentAchMyBadges,
              subtitle: context.l10n.studentHubBadgesSub,
              onTap: () => _go(const AchievementsScreen()),
            ),
            _HubTile(
              icon: Icons.workspace_premium_outlined,
              color: WinColors.teal400,
              label: context.l10n.studentHubCertificates,
              subtitle: context.l10n.studentHubCertificatesSub,
              onTap: () => _go(const CertificatesScreen()),
            ),
            _HubTile(
              icon: Icons.favorite_border,
              color: WinColors.error,
              label: context.l10n.studentHubFavorites,
              subtitle: context.l10n.studentHubFavoritesSub,
              onTap: () => _go(const FavoritesScreen()),
            ),
            _HubTile(
              icon: Icons.download_outlined,
              color: WinColors.ink600,
              label: context.l10n.studentHubHistory,
              onTap: () => _go(const DownloadHistoryScreen()),
            ),
            _HubTile(
              icon: Icons.groups_outlined,
              color: s.primary,
              label: context.l10n.studentHubGroups,
              subtitle: context.l10n.studentHubGroupsSub,
              onTap: () => _go(const StudyGroupsScreen()),
            ),
            _HubTile(
              icon: Icons.bar_chart_outlined,
              color: s.secondary,
              label: context.l10n.studentHubReports,
              onTap: () => _go(const StudentReportsScreen()),
            ),
            _HubTile(
              icon: Icons.quiz_outlined,
              color: WinColors.warn,
              label: context.l10n.studentHubRevisionQuiz,
              subtitle: context.l10n.studentHubRevisionQuizSub,
              onTap: () => _go(const QuizRevisionScreen()),
            ),
            _HubTile(
              icon: Icons.timer_outlined,
              color: WinColors.teal500,
              label: context.l10n.timerTitle,
              subtitle: context.l10n.studentHubPomodoroSub,
              onTap: () => _go(const StudyTimerScreen()),
            ),
            const SizedBox(height: 16),

            _SectionLabel(context.l10n.studentHubCommunity),
            const SizedBox(height: 8),
            _HubTile(
              icon: Icons.forum_outlined,
              color: WinColors.teal600,
              label: context.l10n.studentHubForum,
              subtitle: context.l10n.studentHubForumSub,
              onTap: () => _go(const ForumScreen()),
            ),
            _HubTile(
              icon: Icons.link_outlined,
              color: WinColors.blue700,
              label: context.l10n.studentLinksTitle,
              subtitle: context.l10n.studentHubNetworkSub,
              onTap: () => _go(const MyLinksScreen()),
            ),
            _HubTile(
              icon: winAIIconData,
              color: s.primary,
              label: 'WinAI',
              subtitle: context.l10n.studentHubWinaiSub,
              onTap: _soon,
            ),
            const SizedBox(height: 16),

            _SectionLabel(context.l10n.studentHubAccount),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: UserService.instance.unreadNotifications,
              builder: (_, count, __) => _HubTile(
                icon: Icons.notifications_outlined,
                color: WinColors.warn,
                label: context.l10n.studentNotifTitle,
                badge: count > 0 ? (count > 99 ? '99+' : '$count') : null,
                onTap: () => _go(const NotificationsScreen()),
              ),
            ),
            _HubTile(
              icon: Icons.credit_card_outlined,
              color: s.primary,
              label: context.l10n.studentHubSubscription,
              subtitle: context.l10n.studentHubSubscriptionSub(planName),
              onTap: () => _go(const PricingScreen()),
            ),
            _HubTile(
              icon: Icons.tune_outlined,
              color: s.onMuted,
              label: context.l10n.studentHubProfileSettings,
              onTap: () => _go(const ProfileScreen()),
            ),
            _HubTile(
              icon: Icons.description_outlined,
              color: s.onFaint,
              label: context.l10n.studentHubTerms,
              onTap: () => LegalScreen.showCgu(context),
            ),
            _HubTile(
              icon: Icons.privacy_tip_outlined,
              color: s.onFaint,
              label: context.l10n.studentHubPrivacy,
              onTap: () => LegalScreen.showPrivacy(context),
            ),
            _HubTile(
              icon: Icons.policy_outlined,
              color: s.onFaint,
              label: context.l10n.studentHubTutorPolicy,
              onTap: () => openTutorPolicy(context),
            ),
            const SizedBox(height: 4),

            // Dark mode toggle inline
            WinCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: s.onMuted.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                  ),
                  child: Icon(Icons.dark_mode_outlined,
                      size: 20, color: s.onMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text(context.l10n.commonDarkMode, style: WinType.titleM(s.onStrong))),
                Switch(
                  value: appState.dark,
                  onChanged: (_) => appState.toggleTheme(),
                  activeTrackColor: s.primary,
                ),
              ]),
            ),
            const SizedBox(height: 8),
            // Lot 10.11 : langue de l'application (synchronisée sur User.Locale).
            WinCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: s.onMuted.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                  ),
                  child: Icon(Icons.language, size: 20, color: s.onMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(context.l10n.language,
                        style: WinType.titleM(s.onStrong))),
                const LanguageToggle(),
              ]),
            ),
            const SizedBox(height: 8),

            WinCard(
              onTap: _signOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: WinColors.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                  ),
                  child: const Icon(Icons.logout,
                      size: 20, color: WinColors.error),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(context.l10n.commonLogout,
                        style: WinType.titleM(WinColors.error))),
              ]),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Text(label.toUpperCase(),
        style:
            WinType.manrope(size: 11, weight: FontWeight.w700, color: s.onFaint)
                .copyWith(letterSpacing: 1.1));
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(WinRadii.sm),
            ),
            child: winIcon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: WinType.titleM(s.onStrong)),
              if (subtitle != null)
                Text(subtitle!, style: WinType.labelM(s.onMuted)),
            ]),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: WinColors.error,
                  borderRadius: BorderRadius.circular(WinRadii.full)),
              child: Text(badge!,
                  style: WinType.manrope(
                      size: 11, weight: FontWeight.w700, color: Colors.white)),
            )
          else
            Icon(Icons.chevron_right, size: 18, color: s.onFaint),
        ]),
      ),
    );
  }
}
