import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../services/background_notifications.dart';
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
import '../widgets/biometric_toggle.dart';
import '../widgets/offline_strip.dart';
import '../widgets/winai_floating_widget.dart';
import 'shell_nav.dart';
import 'more_screen.dart';
import '../institution/student_directory_screen.dart';
import '../institution/reports_screen.dart';
import '../institution/license_screen.dart';
import '../institution/at_risk_screen.dart';
import '../teacher/tutor_profile_screen.dart';
import '../teacher/tutor_bookings_screen.dart';
import '../teacher/teacher_links_screen.dart';
import '../teacher/teacher_courses_screen.dart';
import '../teacher/correction_queue_screen.dart';
import '../shared/shop/cart_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NavItem {
  final String label;

  /// Pictogramme au trait, et sa version pleine pour l'onglet ouvert.
  final IconData icon, activeIcon;
  const NavItem(this.label, this.icon, this.activeIcon);
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
    // Application ouverte : un évènement du flux ntfy rafraîchit le badge.
    PushService.instance.start(_loadUnread);
    // Application fermée (Android) : service d'écoute et vérification de
    // secours, sans Firebase (lot 2). Demande l'autorisation la première
    // fois.
    unawaited(BackgroundNotifications.startForAccount());
    // Après une connexion : proposer une fois le déverrouillage par empreinte.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(offerBiometricIfUseful(context));
    });
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

  /// Renvois des écrans (`ShellNav.go(context, n)`), écrits avec les indices
  /// de l'ancienne barre du bas : chacun mène soit à un onglet de la nouvelle
  /// barre, soit à la page correspondante ouverte par-dessus (elle se trouve
  /// désormais dans « Plus »).
  void _goLegacy(int legacy) {
    final role = WinAppScope.of(context).role;
    final l = context.l10n;
    switch (role) {
      case WinRole.student:
        // Accueil, Catalogue, Mon espace, [Messages], Plus (ancien profil).
        _goTab(legacy == 3 ? 4 : legacy.clamp(0, 2));
      case WinRole.parent:
        _goTab(legacy.clamp(0, 4));
      case WinRole.teacher:
        if (legacy == 3) {
          _push(MorePage(
              title: l.mobileHomeSessions, child: const TeacherSessionsTab()));
        } else if (legacy == 4) {
          _push(MorePage(
              title: l.shellTabEarnings, child: const TeacherRevenueTab()));
        } else {
          _goTab(legacy.clamp(0, 2));
        }
      case WinRole.institution:
        if (legacy == 2) {
          _push(MorePage(
              title: l.shellTabCatalog, child: const InstitutionCatalogTab()));
        } else if (legacy == 3) {
          _goTab(2);
        } else if (legacy == 4) {
          _goTab(4);
        } else {
          _goTab(legacy.clamp(0, 1));
        }
    }
  }

  void _push(Widget page) =>
      Navigator.push(context, WinPageRoute(builder: (_) => page));

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
    final pages = _pagesFor(role, context.l10n);
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
          // Panier : élève et parent achètent des contenus.
          if (role == WinRole.student || role == WinRole.parent)
            IconButton(
              icon: Icon(PhosphorIconsRegular.shoppingCart, color: s.onSurface),
              tooltip: context.l10n.mobileCatalogCart,
              onPressed: () => _push(const CartScreen()),
            ),
          Stack(
            children: [
              IconButton(
                icon: Icon(PhosphorIconsRegular.bell, color: s.onSurface),
                tooltip: context.l10n.studentNotifTitle,
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
        child: Column(children: [
          // Hors ligne, date des données, actions en attente (lot 3).
          const OfflineStrip(),
          Expanded(child: ShellNav(
          goTab: _goLegacy,
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
        )),
        ]),
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
        _ => false,
      };

  Widget _avatarFor(WinRole role) {
    // L'avatar ouvre « Plus » : compte, réglages (langue, mode sombre,
    // empreinte) et déconnexion, pour tous les espaces.
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => _goTab(4),
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

  /// Barre du bas, la même construction pour tous les espaces : Accueil,
  /// deux onglets propres à l'espace, Messages, Plus.
  List<NavItem> _tabsFor(WinRole role, AppLocalizations l10n) {
    final home = NavItem(l10n.shellTabHome, PhosphorIconsRegular.house,
        PhosphorIconsFill.house);
    final messages = NavItem(l10n.shellTabMessages,
        PhosphorIconsRegular.chatCircleDots, PhosphorIconsFill.chatCircleDots);
    final more = NavItem(l10n.shellTabMore,
        PhosphorIconsRegular.dotsThreeCircle, PhosphorIconsFill.dotsThreeCircle);
    final middle = switch (role) {
      WinRole.student => [
          NavItem(l10n.shellTabCatalog, PhosphorIconsRegular.books,
              PhosphorIconsFill.books),
          NavItem(l10n.shellTabMySpace, PhosphorIconsRegular.squaresFour,
              PhosphorIconsFill.squaresFour),
        ],
      WinRole.parent => [
          NavItem(l10n.shellTabChildren, PhosphorIconsRegular.usersThree,
              PhosphorIconsFill.usersThree),
          NavItem(l10n.shellTabResources, PhosphorIconsRegular.books,
              PhosphorIconsFill.books),
        ],
      WinRole.teacher => [
          NavItem(l10n.shellTabContent, PhosphorIconsRegular.files,
              PhosphorIconsFill.files),
          NavItem(l10n.shellTabStudents, PhosphorIconsRegular.student,
              PhosphorIconsFill.student),
        ],
      WinRole.institution => [
          NavItem(l10n.shellTabGroups, PhosphorIconsRegular.usersThree,
              PhosphorIconsFill.usersThree),
          NavItem(l10n.shellTabAnalytics, PhosphorIconsRegular.chartBar,
              PhosphorIconsFill.chartBar),
        ],
    };
    return [home, ...middle, messages, more];
  }

  List<Widget> _pagesFor(WinRole role, AppLocalizations l) => switch (role) {
        WinRole.student => const [
            StudentHomeTab(),
            StudentCatalogTab(),
            StudentSpaceTab(),
            MessagingScreen(),
            // Profil, outils, réglages et déconnexion de l'élève.
            ProfileHubTab(),
          ],
        WinRole.parent => const [
            ParentDashTab(),
            ParentChildrenTab(),
            ParentResourcesTab(),
            MessagingScreen(),
            // Compte, abonnement, réglages et déconnexion du parent.
            ParentProfileTab(),
          ],
        WinRole.teacher => [
            const TeacherDashTab(),
            const TeacherContentTab(),
            const TeacherStudentsTab(),
            const MessagingScreen(),
            MoreScreen(entries: [
              MoreEntry(
                  l.mobileHomeSessions,
                  PhosphorIconsRegular.calendarDots,
                  (_) => MorePage(
                      title: l.mobileHomeSessions,
                      child: const TeacherSessionsTab())),
              MoreEntry(
                  l.shellTabEarnings,
                  PhosphorIconsRegular.wallet,
                  (_) => MorePage(
                      title: l.shellTabEarnings,
                      child: const TeacherRevenueTab())),
              MoreEntry(l.mobileHomeCorrections,
                  PhosphorIconsRegular.checkSquareOffset,
                  (_) => const CorrectionQueueScreen()),
              MoreEntry(l.studentMyCoursesTitle,
                  PhosphorIconsRegular.graduationCap,
                  (_) => const TeacherCoursesScreen()),
              MoreEntry(l.teacherProfileTitle,
                  PhosphorIconsRegular.identificationBadge,
                  (_) => const TutorProfileScreen()),
              MoreEntry(l.teacherClassesMyBookings,
                  PhosphorIconsRegular.calendarCheck,
                  (_) => const TutorBookingsScreen()),
              MoreEntry(l.teacherClassesMyLinks, PhosphorIconsRegular.link,
                  (_) => const TeacherLinksScreen()),
            ]),
          ],
        WinRole.institution => [
            const InstitutionDashTab(),
            const InstitutionGroupsTab(),
            const InstitutionAnalyticsTab(),
            const MessagingScreen(),
            MoreScreen(entries: [
              MoreEntry(
                  l.shellTabCatalog,
                  PhosphorIconsRegular.books,
                  (_) => MorePage(
                      title: l.shellTabCatalog,
                      child: const InstitutionCatalogTab())),
              MoreEntry(l.mobileHomeDirectory, PhosphorIconsRegular.addressBook,
                  (_) => const StudentDirectoryScreen()),
              MoreEntry(l.instRiskTitle, PhosphorIconsRegular.warning,
                  (_) => const AtRiskScreen()),
              MoreEntry(l.instReportsTitle, PhosphorIconsRegular.fileText,
                  (_) => const ReportsScreen()),
              MoreEntry(l.mobileHomeLicense,
                  PhosphorIconsRegular.identificationCard,
                  (_) => const LicenseScreen()),
              MoreEntry(
                  l.shellTabAccount,
                  PhosphorIconsRegular.buildings,
                  (_) => MorePage(
                      title: l.shellTabAccount,
                      child: const InstitutionAccountTab())),
            ]),
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
                        Icon(on ? t.activeIcon : t.icon,
                            size: 24, color: on ? s.primary : s.onFaint),
                        const SizedBox(height: 3),
                        Text(t.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
