import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../services/push_service.dart';
import '../services/user_service.dart';
import '../student/notifications_screen.dart';
import '../shared/messaging/messaging_screen.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../theme/win_colors.dart';
import '../student/student_tabs.dart';
import '../student/profile_hub_tab.dart';
import '../parent/parent_tabs.dart';
import '../teacher/teacher_tabs.dart';
import '../institution/institution_tabs.dart';
import '../widgets/language_selector.dart';
import '../widgets/winai_floating_widget.dart';
import 'shell_nav.dart';

class NavItem {
  final String label;
  final IconData icon;
  const NavItem(this.label, this.icon);
}

/// Coquille principale : barre de navigation basse propre à chaque rôle.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key});
  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> with WidgetsBindingObserver {
  int _index = 0;
  // Module 24 (lot 8) : initiales réelles pour l'avatar de la barre de
  // navigation, remplace WinData.userProfile/parentAccount (élève/parent) et
  // "MF" codé en dur (professeur) — aucun des trois n'était jamais la bonne
  // personne connectée.
  String? _avatarInitials;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnread();
    _loadProfile();
    // Module 27 (lot 8) : push ntfy, premier plan uniquement (décision
    // produit : aucune garantie de livraison app fermée, donc pas de
    // service natif FCM/APNs). Un évènement SSE rafraîchit juste le badge.
    PushService.instance.start(_loadUnread);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushService.instance.stop();
    super.dispose();
  }

  /// Retour au premier plan : lectures faites sur le web ou un autre
  /// appareil, notifications arrivées sans évènement ntfy.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadUnread();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await UserService.instance.getProfile();
      // Lot 10.11 : session reprise au démarrage, la langue suit le compte.
      if (mounted) unawaited(WinAppScope.of(context).applyAccountLocale(p.locale));
      final parts = p.fullName.trim().split(RegExp(r'\s+'));
      final initials = parts
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase())
          .take(2)
          .join();
      if (mounted && initials.isNotEmpty) {
        setState(() => _avatarInitials = initials);
      }
    } catch (_) {
      // Avatar sans initiales le temps d'une reconnexion.
    }
  }

  /// Compteur serveur (toutes pages), partagé avec le profil et l'écran
  /// Notifications via UserService.unreadNotifications.
  Future<void> _loadUnread() => UserService.instance.refreshUnreadCount();

  /// Sens du dernier changement d'onglet : 1 vers la droite, -1 vers la gauche.
  double _direction = 1;

  void _goTab(int i) {
    if (i == _index) return;
    setState(() {
      _direction = i > _index ? 1 : -1;
      _index = i;
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
        context, WinPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final role = WinAppScope.of(context).role;
    final tabs = _tabsFor(role, context.l10n);
    final pages = _pagesFor(role);
    final safeIndex = _index.clamp(0, tabs.length - 1);
    final tab = tabs[safeIndex];

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        // Accueil et catalogue : le logo seul, pas le nom de l'onglet
        // (la page commence par sa recherche, comme sur le site).
        title: safeIndex == 0 || _isCatalogTab(role, safeIndex)
            ? Image.asset('assets/winplus-logo.png', width: 36)
            : Text(tab.label,
                style: WinType.archivo(size: 20, color: s.onStrong)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: s.onSurface),
                onPressed: _openNotifications,
              ),
              ValueListenableBuilder<int>(
                valueListenable: UserService.instance.unreadNotifications,
                builder: (_, count, __) {
                  if (count <= 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 2,
                    top: 4,
                    child: IgnorePointer(
                      child: Container(
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: WinColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          _avatarFor(role),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ShellNav(
          goTab: _goTab,
          child: WinAIFloatingWidget(
            role: role,
            // L'onglet ouvert glisse depuis le côté de son bouton dans la
            // barre du bas (gauche ou droite de l'onglet quitté).
            child: AnimatedSwitcher(
              duration: winReducedMotion(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              switchInCurve: WinCurves.enter,
              switchOutCurve: WinCurves.exit,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(safeIndex);
                final dx = (incoming ? 0.06 : -0.06) * _direction;
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: Offset(dx, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                  key: ValueKey(safeIndex), child: pages[safeIndex]),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        index: safeIndex,
        onTap: _goTab,
      ),
    );
  }

  bool _isCatalogTab(WinRole role, int i) => switch (role) {
        WinRole.student => i == 1,
        WinRole.institution => i == 2,
        _ => false,
      };

  Widget _avatarFor(WinRole role) {
    // Lot 10.11 : l'avatar ouvre le réglage de la langue (le professeur n'a
    // pas d'écran de réglages ; les autres l'ont aussi dans leur profil).
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => showLanguageSheet(context),
        child: switch (role) {
        WinRole.student => Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: WinColors.teal100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _avatarInitials ?? '',
              style: WinType.manrope(
                  size: 12, weight: FontWeight.w600, color: WinColors.teal700),
            ),
          ),
        WinRole.parent => Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: WinColors.blue100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _avatarInitials ?? '',

              style: WinType.manrope(
                  size: 12, weight: FontWeight.w600, color: WinColors.teal700),
            ),
          ),
        WinRole.teacher => Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: WinColors.ink100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(_avatarInitials ?? '…',
                style: WinType.manrope(
                    size: 12,
                    weight: FontWeight.w600,
                    color: WinColors.teal700)),
          ),
        WinRole.institution => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: WinColors.goldBg,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment_outlined,
                size: 18, color: WinColors.gold),
          ),
        },
      ),
    );
  }

  List<NavItem> _tabsFor(WinRole role, AppLocalizations l10n) =>
      switch (role) {
        WinRole.student => [
            NavItem(l10n.shellTabHome, Icons.home_outlined),
            NavItem(l10n.shellTabCatalog, Icons.layers_outlined),
            NavItem(l10n.shellTabMySpace, Icons.grid_view_outlined),
            NavItem(l10n.shellTabMe, Icons.person_outline),
          ],
        WinRole.parent => [
            NavItem(l10n.shellTabHome, Icons.home_outlined),
            NavItem(l10n.shellTabChildren, Icons.people_outline),
            NavItem(l10n.shellTabResources, Icons.layers_outlined),
            NavItem(l10n.shellTabMessages, Icons.chat_bubble_outlined),
            NavItem(l10n.shellTabProfile, Icons.person_outline),
          ],
        WinRole.teacher => [
            NavItem(l10n.shellTabHome, Icons.home_outlined),
            NavItem(l10n.shellTabContent, Icons.layers_outlined),
            NavItem(l10n.shellTabStudents, Icons.people_outline),
            NavItem(l10n.shellTabSessions, Icons.event_outlined),
            NavItem(l10n.shellTabEarnings, Icons.account_balance_wallet_outlined),
          ],
        WinRole.institution => [
            NavItem(l10n.shellTabHome, Icons.home_outlined),
            NavItem(l10n.shellTabGroups, Icons.people_outline),
            NavItem(l10n.shellTabCatalog, Icons.layers_outlined),
            NavItem(l10n.shellTabAnalytics, Icons.bar_chart_outlined),
            NavItem(l10n.shellTabAccount, Icons.apartment_outlined),
          ],
      };

  List<Widget> _pagesFor(WinRole role) => switch (role) {
        WinRole.student => const [
            StudentHomeTab(),
            StudentCatalogTab(),
            StudentSpaceTab(),
            ProfileHubTab()
          ],
        WinRole.parent => const [
            ParentDashTab(),
            ParentChildrenTab(),
            ParentResourcesTab(),
            MessagingScreen(),
            ParentProfileTab()
          ],
        WinRole.teacher => const [
            TeacherDashTab(),
            TeacherContentTab(),
            TeacherStudentsTab(),
            TeacherSessionsTab(),
            TeacherRevenueTab()
          ],
        WinRole.institution => const [
            InstitutionDashTab(),
            InstitutionGroupsTab(),
            InstitutionCatalogTab(),
            InstitutionAnalyticsTab(),
            InstitutionAccountTab()
          ],
      };
}

class _BottomNav extends StatelessWidget {
  final List<NavItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav(
      {required this.tabs, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: s.navBg, border: Border(top: BorderSide(color: s.outline))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final on = i == index;
              final t = tabs[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.icon,
                            size: 22, color: on ? s.primary : s.onFaint),
                        const SizedBox(height: 3),
                        Text(t.label,
                            style: WinType.manrope(
                                size: 10,
                                weight: on ? FontWeight.w600 : FontWeight.w500,
                                color: on ? s.primary : s.onFaint)),
                      ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
