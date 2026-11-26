import 'dart:async';
import 'package:flutter/material.dart';
import '../teacher/affiliate_screen.dart';
import '../shared/verify_certificate_screen.dart';
import '../institution/announcements_screen.dart';
import '../parent/barometer_tab.dart';
import '../shared/visio/live_classes_screen.dart';
import '../teacher/dropout_alerts_screen.dart';
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
import '../institution/regional_comparison_screen.dart';
import '../teacher/teacher_library_screen.dart';
import '../teacher/tutor_coaching_screen.dart';
import '../shared/concours_screen.dart';
import '../shared/bulletin_view.dart';
import '../institution/mock_exams_screen.dart';
import '../institution/bulletins_screen.dart';
import '../institution/teachers_screen.dart';
import '../institution/homework_screen.dart';
import '../institution/class_prediction_screen.dart';
import '../teacher/class_analysis_screen.dart';
import '../institution/license_screen.dart';
import '../institution/at_risk_screen.dart';
import '../teacher/tutor_profile_screen.dart';
import '../teacher/tutor_bookings_screen.dart';
import '../teacher/teacher_links_screen.dart';
import '../teacher/teacher_courses_screen.dart';
import '../teacher/correction_queue_screen.dart';
import '../shared/shop/cart_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_logo.dart';
import '../services/messaging_service.dart';
import '../widgets/win_widgets.dart';

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

  /// Navigateur interne : les écrans secondaires s'ouvrent dans la coque,
  /// sous la barre du bas et le bouton WinAI, qui restent toujours visibles.
  final _inner = GlobalKey<NavigatorState>();

  /// Redessine la page d'accueil de la coque (logée dans le navigateur
  /// interne) à chaque changement d'état de la coque.
  final _tick = ValueNotifier<int>(0);

  /// Feuille du bas ou menu ouvert dans la coque : le bouton WinAI s'efface.
  final _popup = ValueNotifier<bool>(false);
  final _routes = ValueNotifier<int>(0);
  late final _observer = _PopupObserver(_popup, _routes);

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _tick.value++;
  }
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
  Future<void> _loadUnread() async {
    await Future.wait([
      UserService.instance.refreshUnreadCount(),
      MessagingService.instance.refreshUnread(),
    ]);
  }

  /// Sens du dernier changement d'onglet : 1 vers la droite, -1 vers la gauche.
  double _direction = 1;

  void _goTab(int i) {
    // Un écran secondaire est ouvert : on revient d'abord à l'onglet.
    final nav = _inner.currentState;
    if (nav != null && nav.canPop()) nav.popUntil((r) => r.isFirst);
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

  NavigatorState get _nav => _inner.currentState ?? Navigator.of(context);

  void _push(Widget page) => _nav.push(WinPageRoute(builder: (_) => page));

  Future<void> _openNotifications() async {
    await _nav
        .push(WinPageRoute(builder: (_) => const NotificationsScreen()));
    _loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final role = WinAppScope.of(context).role;
    final tabs = _tabsFor(role, context.l10n);
    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: s.bg,
      body: ShellNav(
        goTab: _goLegacy,
        child: WinAIFloatingWidget(
          role: role,
          navigatorKey: _inner,
          hidden: _popup,
          routeChanged: _routes,
          // Lu ici, au-dessus du Scaffold : dessous, il retire déjà la
          // hauteur du clavier.
          keyboardOpen: MediaQuery.viewInsetsOf(context).bottom > 0,
          // Retour d'Android : ferme d'abord l'écran secondaire ouvert.
          child: NavigatorPopHandler(
            onPopWithResult: (_) => _inner.currentState?.maybePop(),
            child: Navigator(
              key: _inner,
              observers: [_observer],
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => ListenableBuilder(
                    listenable: _tick, builder: (ctx, _) => _home(ctx)),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        index: safeIndex,
        onTap: _goTab,
        // Onglet Messages : avant-dernier pour tous les rôles.
        messagesIndex: tabs.length - 2,
      ),
    );
  }

  /// Page d'accueil de la coque : la barre du haut et l'onglet courant. Les
  /// écrans secondaires la recouvrent, sans toucher à la barre du bas.
  Widget _home(BuildContext context) {
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
            ? const Align(
                alignment: Alignment.centerLeft,
                child: WinLogo(size: 38, shadow: false))
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
          Expanded(
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
        ]),
      ),
    );
  }

  bool _isCatalogTab(WinRole role, int i) => switch (role) {
        WinRole.student => i == 1,
        _ => false,
      };

  Widget _avatarFor(WinRole role) {
    final s = WinTheme.of(context);
    // En sombre : voile et ton eclairci au lieu d'un disque pale.
    Color bg(Color light, BadgeColor tone) =>
        s.dark ? winTone(s, tone).bg : light;
    Color fg(Color light, BadgeColor tone) =>
        s.dark ? winTone(s, tone).fg : light;
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
            decoration: BoxDecoration(
              color: bg(WinColors.teal100, BadgeColor.teal),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _avatarInitials ?? '',
              style: WinType.manrope(
                  size: 12, weight: FontWeight.w600, color: fg(WinColors.teal700, BadgeColor.teal)),
            ),
          ),
        WinRole.parent => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bg(WinColors.blue100, BadgeColor.blue),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _avatarInitials ?? '',

              style: WinType.manrope(
                  size: 12, weight: FontWeight.w600, color: fg(WinColors.teal700, BadgeColor.teal)),
            ),
          ),
        WinRole.teacher => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bg(WinColors.ink100, BadgeColor.neutral),
                shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(_avatarInitials ?? '…',
                style: WinType.manrope(
                    size: 12,
                    weight: FontWeight.w600,
                    color: fg(WinColors.teal700, BadgeColor.teal))),
          ),
        WinRole.institution => Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bg(WinColors.goldBg, BadgeColor.gold),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(PhosphorIconsRegular.buildings,
                size: 18, color: fg(WinColors.gold, BadgeColor.gold)),
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
          // Le catalogue complet (recommandés en tête), nommé comme sur le site.
          NavItem(l10n.shellTabCatalog, PhosphorIconsRegular.books,
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
        WinRole.student => [
            const StudentHomeTab(),
            const StudentCatalogTab(),
            const StudentSpaceTab(),
            const MessagingScreen(),
            // Profil et outils de l'élève (sa page existante), puis Paramètres.
            MoreScreen(entries: [
              MoreEntry(
                  l.shellTabProfile,
                  PhosphorIconsRegular.userCircle,
                  (_) => MorePage(
                      title: l.shellTabProfile, child: const ProfileHubTab())),
              MoreEntry(l.liveTitle, PhosphorIconsRegular.videoCamera,
                  (_) => const LiveClassesScreen()),
            ]),
          ],
        WinRole.parent => [
            const ParentDashTab(),
            const ParentChildrenTab(),
            const ParentResourcesTab(),
            const MessagingScreen(),
            // Compte et abonnement du parent (sa page existante), puis Paramètres.
            MoreScreen(groupOrder: [
              l.moreGroupChildren,
              l.moreGroupAccount
            ], groups: {
              l.barometerTitle: l.moreGroupChildren,
              l.liveTitle: l.moreGroupChildren,
              l.concTitle: l.moreGroupChildren,
              l.bullMineTitle: l.moreGroupChildren,
              l.shellTabProfile: l.moreGroupAccount,
            }, entries: [
              MoreEntry(
                  l.shellTabProfile,
                  PhosphorIconsRegular.userCircle,
                  (_) => MorePage(
                      title: l.shellTabProfile, child: const ParentProfileTab())),
              MoreEntry(l.liveTitle, PhosphorIconsRegular.videoCamera,
                  (_) => const LiveClassesScreen()),
              // Lot 7 : baromètre de bien-être, enfant choisi en haut.
              MoreEntry(l.barometerTitle, PhosphorIconsRegular.gauge,
                  (_) => const BarometerScreen()),
              // Lot 7 : concours et examens de l'enfant (calendrier, épreuves).
              MoreEntry(l.concTitle, PhosphorIconsRegular.graduationCap,
                  (_) => const ConcoursHubScreen()),
              // Lot 7 : bulletins des enfants partagés par leur établissement.
              MoreEntry(l.bullMineTitle, PhosphorIconsRegular.scroll,
                  (_) => const MyBulletinsScreen()),
            ]),
          ],
        WinRole.teacher => [
            const TeacherDashTab(),
            const TeacherContentTab(),
            const TeacherStudentsTab(),
            const MessagingScreen(),
            MoreScreen(groupOrder: [
              l.moreGroupTeach,
              l.moreGroupFollow,
              l.moreGroupTutoring,
              l.moreGroupEarnings
            ], groups: {
              l.mobileHomeSessions: l.moreGroupTeach,
              l.liveTitle: l.moreGroupTeach,
              l.studentMyCoursesTitle: l.moreGroupTeach,
              l.shellTabCatalog: l.moreGroupTeach,
              l.libTitle: l.moreGroupTeach,
              l.dpTitle: l.moreGroupFollow,
              l.canTitle: l.moreGroupFollow,
              l.mobileHomeCorrections: l.moreGroupFollow,
              l.teacherClassesMyLinks: l.moreGroupFollow,
              l.teacherProfileTitle: l.moreGroupTutoring,
              l.teacherClassesMyBookings: l.moreGroupTutoring,
              l.coachTitle: l.moreGroupTutoring,
              l.shellTabEarnings: l.moreGroupEarnings,
              l.affTitle: l.moreGroupEarnings,
            }, entries: [
              MoreEntry(
                  l.shellTabCatalog,
                  PhosphorIconsRegular.books,
                  (_) => MorePage(
                      title: l.shellTabCatalog,
                      child: const StudentCatalogTab())),
              // Lot 7 : contenus achetés ou rangés, dossiers, assignation à une classe.
              MoreEntry(l.libTitle, PhosphorIconsRegular.bookBookmark,
                  (_) => const TeacherLibraryScreen()),
              MoreEntry(
                  l.mobileHomeSessions,
                  PhosphorIconsRegular.calendarDots,
                  (_) => MorePage(
                      title: l.mobileHomeSessions,
                      child: const TeacherSessionsTab())),
              MoreEntry(l.liveTitle, PhosphorIconsRegular.videoCamera,
                  (_) => const LiveClassesScreen()),
              // Lot 7 : élèves de ses formations qui décrochent, à relancer.
              MoreEntry(l.dpTitle, PhosphorIconsRegular.warningCircle,
                  (_) => const DropoutAlertsScreen()),
              // Lot 7 : analyse WinAI des élèves d'un contenu publié.
              MoreEntry(l.canTitle, PhosphorIconsRegular.chartPie,
                  (_) => const ClassAnalysisScreen()),
              MoreEntry(
                  l.shellTabEarnings,
                  PhosphorIconsRegular.wallet,
                  (_) => MorePage(
                      title: l.shellTabEarnings,
                      child: const TeacherRevenueTab())),
              // Lot 7 : programme d'affiliation (lien de parrainage, commissions).
              MoreEntry(l.affTitle, PhosphorIconsRegular.shareNetwork,
                  (_) => const AffiliateScreen()),
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
              // Lot 7 : rapport mensuel WinAI et fiches de révision par élève.
              MoreEntry(l.coachTitle, PhosphorIconsRegular.sparkle,
                  (_) => const TutorCoachingScreen()),
              MoreEntry(l.teacherClassesMyLinks, PhosphorIconsRegular.link,
                  (_) => const TeacherLinksScreen()),
            ]),
          ],
        WinRole.institution => [
            const InstitutionDashTab(),
            const InstitutionGroupsTab(),
            const InstitutionAnalyticsTab(),
            const MessagingScreen(),
            MoreScreen(groupOrder: [
              l.moreGroupSteer,
              l.moreGroupResources,
              l.moreGroupSchool
            ], groups: {
              l.instRiskTitle: l.moreGroupSteer,
              l.instReportsTitle: l.moreGroupSteer,
              l.regCmpTitle: l.moreGroupSteer,
              l.predTitle: l.moreGroupSteer,
              l.ihwTitle: l.moreGroupSteer,
              l.mockTitle: l.moreGroupSteer,
              l.bullTitle: l.moreGroupSteer,
              l.mobileHomeDirectory: l.moreGroupSteer,
              l.shellTabCatalog: l.moreGroupResources,
              l.liveTitle: l.moreGroupResources,
              l.teachTitle: l.moreGroupSchool,
              l.annTitle: l.moreGroupSchool,
              l.certVerifyTitle: l.moreGroupSchool,
              l.mobileHomeLicense: l.moreGroupSchool,
              l.shellTabAccount: l.moreGroupSchool,
            }, entries: [
              MoreEntry(
                  l.shellTabCatalog,
                  PhosphorIconsRegular.books,
                  (_) => MorePage(
                      title: l.shellTabCatalog,
                      child: const InstitutionCatalogTab())),
              MoreEntry(l.liveTitle, PhosphorIconsRegular.videoCamera,
                  (_) => const LiveClassesScreen()),
              MoreEntry(l.mobileHomeDirectory, PhosphorIconsRegular.addressBook,
                  (_) => const StudentDirectoryScreen()),
              MoreEntry(l.instRiskTitle, PhosphorIconsRegular.warning,
                  (_) => const AtRiskScreen()),
              MoreEntry(l.instReportsTitle, PhosphorIconsRegular.fileText,
                  (_) => const ReportsScreen()),
              // Lot 7 : rang anonyme parmi les établissements de la région.
              MoreEntry(l.regCmpTitle, PhosphorIconsRegular.ranking,
                  (_) => const RegionalComparisonScreen()),
              // Lot 7 : prévision de réussite par WinAI.
              MoreEntry(l.predTitle, PhosphorIconsRegular.trendUp,
                  (_) => const ClassPredictionScreen()),
              // Lot 7 : devoirs donnés aux classes et leur avancement.
              MoreEntry(l.ihwTitle, PhosphorIconsRegular.notebook,
                  (_) => const InstitutionHomeworkScreen()),
              // Lot 7 : examens blancs chronométrés et classement.
              MoreEntry(l.mockTitle, PhosphorIconsRegular.exam,
                  (_) => const MockExamsScreen()),
              // Lot 7 : bulletins calculés, appréciation WinAI, partage.
              MoreEntry(l.bullTitle, PhosphorIconsRegular.scroll,
                  (_) => const InstitutionBulletinsScreen()),
              // Lot 7 : enseignants affiliés, invitations, classes.
              MoreEntry(l.teachTitle, PhosphorIconsRegular.chalkboardTeacher,
                  (_) => const InstitutionTeachersScreen()),
              // Lot 7 : annonces aux élèves et aux parents, comme le site.
              MoreEntry(l.annTitle, PhosphorIconsRegular.megaphone,
                  (_) => const InstitutionAnnouncementsScreen()),
              // Lot 7 : vérifier un certificat présenté par un élève.
              MoreEntry(l.certVerifyTitle, PhosphorIconsRegular.sealCheck,
                  (_) => const VerifyCertificateScreen()),
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

/// Pastille du nombre de messages non lus sur l'icône de l'onglet Messages.
Widget _withUnread(bool messages, Widget icon) {
  if (!messages) return icon;
  return ValueListenableBuilder<int>(
    valueListenable: MessagingService.instance.unreadTotal,
    builder: (_, count, __) => count <= 0
        ? icon
        : Stack(clipBehavior: Clip.none, children: [
            icon,
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: WinColors.error, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  widthFactor: 1,
                  child: Text(count > 99 ? '99+' : '$count',
                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ]),
  );
}

/// Suit les feuilles du bas, menus et autres fenêtres ouverts dans le
/// navigateur de la coque.
class _PopupObserver extends NavigatorObserver {
  final ValueNotifier<bool> open;

  /// Incrémenté à chaque écran ouvert ou fermé.
  final ValueNotifier<int> routes;
  int _count = 0;
  _PopupObserver(this.open, this.routes);

  void _set(int delta, Route<dynamic>? route) {
    WidgetsBinding.instance.addPostFrameCallback((_) => routes.value++);
    if (route is! PopupRoute) return;
    _count = (_count + delta).clamp(0, 99);
    final value = _count > 0;
    // Hors du build en cours : la navigation peut être déclenchée pendant.
    WidgetsBinding.instance.addPostFrameCallback((_) => open.value = value);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(1, route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(-1, route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(-1, route);
}

class _BottomNav extends StatelessWidget {
  final List<NavItem> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final int messagesIndex;
  const _BottomNav(
      {required this.tabs, required this.index, required this.onTap, required this.messagesIndex});

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
                        _withUnread(
                            i == messagesIndex,
                            Icon(on ? t.activeIcon : t.icon,
                                size: 24, color: on ? s.primary : s.onFaint)),
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
