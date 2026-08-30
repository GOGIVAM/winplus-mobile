import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
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

class _RoleShellState extends State<RoleShell> {
  int _index = 0;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final notifs = await UserService.instance.getNotifications();
      if (mounted) setState(() => _unreadCount = notifs.where((n) => !n.isRead).length);
    } catch (_) {
      if (mounted) {
        setState(() => _unreadCount = WinData.notifications.where((n) => n.unread).length);
      }
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final role = WinAppScope.of(context).role;
    final tabs = _tabsFor(role);
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
        title: safeIndex == 0
            ? Image.asset('assets/winplus-logo.png', width: 36)
            : Text(tab.label, style: WinType.archivo(size: 20, color: s.onStrong)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: s.onSurface),
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: WinColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _avatarFor(role),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(top: false, bottom: false, child: pages[safeIndex]),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        index: safeIndex,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  Widget _avatarFor(WinRole role) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
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
              WinData.userProfile.avatarInitials,
              style: WinType.manrope(size: 12, weight: FontWeight.w600, color: WinColors.teal700),
            ),
          ),
        WinRole.parent => Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: WinColors.blue100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              WinData.parentAccount.name.split(' ').map((w) => w[0]).take(2).join(),
              style: WinType.manrope(size: 12, weight: FontWeight.w600, color: WinColors.teal700),
            ),
          ),
        WinRole.teacher => Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: WinColors.cream200, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('MF', style: WinType.manrope(size: 12, weight: FontWeight.w600, color: WinColors.teal700)),
          ),
        WinRole.institution => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: WinColors.goldBg, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.apartment_outlined, size: 18, color: WinColors.gold),
          ),
      },
    );
  }

  List<NavItem> _tabsFor(WinRole role) => switch (role) {
        WinRole.student => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Catalogue', Icons.layers_outlined),
            NavItem('Mon Espace', Icons.grid_view_outlined),
            NavItem('WinAI', Icons.smart_toy_outlined),
            NavItem('Moi', Icons.person_outline),
          ],
        WinRole.parent => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Enfants', Icons.people_outline),
            NavItem('Ressources', Icons.layers_outlined),
            NavItem('WinAI', Icons.smart_toy_outlined),
            NavItem('Messages', Icons.chat_bubble_outlined),
            NavItem('Profil', Icons.person_outline),
          ],
        WinRole.teacher => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Contenus', Icons.layers_outlined),
            NavItem('Étudiants', Icons.people_outline),
            NavItem('WinAI', Icons.smart_toy_outlined),
            NavItem('Sessions', Icons.event_outlined),
            NavItem('Revenus', Icons.account_balance_wallet_outlined),
          ],
        WinRole.institution => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Groupes', Icons.people_outline),
            NavItem('WinAI', Icons.smart_toy_outlined),
            NavItem('Catalogue', Icons.layers_outlined),
            NavItem('Analytics', Icons.bar_chart_outlined),
            NavItem('Compte', Icons.apartment_outlined),
          ],
      };

  List<Widget> _pagesFor(WinRole role) => switch (role) {
        WinRole.student => const [StudentHomeTab(), StudentCatalogTab(), StudentSpaceTab(), StudentWinAITab(), ProfileHubTab()],
        WinRole.parent => const [ParentDashTab(), ParentChildrenTab(), ParentResourcesTab(), ParentWinAITab(), MessagingScreen(), ParentProfileTab()],
        WinRole.teacher => const [TeacherDashTab(), TeacherContentTab(), TeacherStudentsTab(), TeacherWinAITab(), TeacherSessionsTab(), TeacherRevenueTab()],
        WinRole.institution => const [InstitutionDashTab(), InstitutionGroupsTab(), InstitutionWinAITab(), InstitutionCatalogTab(), InstitutionAnalyticsTab(), InstitutionAccountTab()],
      };
}

class _BottomNav extends StatelessWidget {
  final List<NavItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.tabs, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.navBg, border: Border(top: BorderSide(color: s.outline))),
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
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(t.icon, size: 22, color: on ? s.primary : s.onFaint),
                    const SizedBox(height: 3),
                    Text(t.label, style: WinType.manrope(size: 10, weight: on ? FontWeight.w600 : FontWeight.w500, color: on ? s.primary : s.onFaint)),
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
