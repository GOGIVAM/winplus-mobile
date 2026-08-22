import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final role = WinAppScope.of(context).role;
    final tabs = _tabsFor(role);
    final pages = _pagesFor(role);
    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(bottom: false, child: pages[safeIndex]),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        index: safeIndex,
        onTap: (i) => setState(() => _index = i),
      ),
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
            NavItem('Paiements', Icons.account_balance_wallet_outlined),
            NavItem('Profil', Icons.person_outline),
          ],
        WinRole.teacher => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Contenus', Icons.layers_outlined),
            NavItem('Étudiants', Icons.people_outline),
            NavItem('Sessions', Icons.event_outlined),
            NavItem('Revenus', Icons.account_balance_wallet_outlined),
          ],
        WinRole.institution => const [
            NavItem('Accueil', Icons.home_outlined),
            NavItem('Groupes', Icons.people_outline),
            NavItem('Catalogue', Icons.layers_outlined),
            NavItem('Analytics', Icons.bar_chart_outlined),
            NavItem('Compte', Icons.apartment_outlined),
          ],
      };

  List<Widget> _pagesFor(WinRole role) => switch (role) {
        WinRole.student => const [StudentHomeTab(), StudentCatalogTab(), StudentSpaceTab(), StudentWinAITab(), ProfileHubTab()],
        WinRole.parent => const [ParentDashTab(), ParentChildrenTab(), ParentResourcesTab(), ParentPaymentsTab(), ParentProfileTab()],
        WinRole.teacher => const [TeacherDashTab(), TeacherContentTab(), TeacherStudentsTab(), TeacherSessionsTab(), TeacherRevenueTab()],
        WinRole.institution => const [InstitutionDashTab(), InstitutionGroupsTab(), InstitutionCatalogTab(), InstitutionAnalyticsTab(), InstitutionAccountTab()],
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
