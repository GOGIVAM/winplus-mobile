import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Accueil des espaces (élève, parent, professeur, établissement), même
/// construction que la version téléphone du site :
///   1. une barre de recherche et son bouton de filtres ;
///   2. « Pour toi » : un carrousel de cartes photo (étiquette, titre, bouton),
///      la première étant l'action à faire tout de suite ;
///   3. « Accès rapide » : des pastilles rondes teintées portant chacune un
///      pictogramme bicolore (vert presque noir et sarcelle), libellé dessous ;
///   4. les chiffres en bande compacte qui défile de côté, avec « Voir le
///      détail » qui ouvre une feuille plein écran.
/// Tout bloc placé ensuite apparaît au défilement, en cascade. Chaque
/// animation s'efface si l'appareil demande moins d'animations.
class MobileHomeColors {
  MobileHomeColors._();

  /// Vert presque noir des cartes sombres et du trait des pictogrammes.
  static const abyss = Color(0xFF021510);

  /// Teinte des pastilles d'accès rapide, et sa version enfoncée.
  static const tint = Color(0xFFDDF2EE);
  static const tintPressed = Color(0xFFC7EAE4);
}

const _ease = Cubic(.2, .8, .2, 1);

// ─────────────────────────────────────────────────────────────────────────
// Mouvements
// ─────────────────────────────────────────────────────────────────────────

/// Élément tapable : il s'enfonce légèrement à la pression et une onde part
/// du point touché, par-dessus son contenu.
class WinPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? shape;
  final double pressedScale;
  final Color? splashColor;
  final String? semanticLabel;
  const WinPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.shape,
    this.pressedScale = 0.96,
    this.splashColor,
    this.semanticLabel,
  });

  @override
  State<WinPressable> createState() => _WinPressableState();
}

class _WinPressableState extends State<WinPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = winReducedMotion(context);
    final splash = widget.splashColor ?? WinColors.teal500.withValues(alpha: 0.18);
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && !reduced ? widget.pressedScale : 1,
        duration: WinDurations.fast,
        curve: WinCurves.tap,
        child: Stack(fit: StackFit.passthrough, children: [
          widget.child,
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                borderRadius: widget.borderRadius,
                customBorder: widget.shape,
                splashColor: reduced ? Colors.transparent : splash,
                highlightColor: splash.withValues(alpha: 0.08),
                splashFactory: reduced
                    ? NoSplash.splashFactory
                    : InkRipple.splashFactory,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Entrée jouée une fois au montage : fondu, glissement de [from] (en
/// pixels) et léger grossissement depuis [scaleFrom], après [delay].
class WinEnter extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset from;
  final double scaleFrom;
  const WinEnter({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.from = const Offset(0, 14),
    this.scaleFrom = 1,
  });

  @override
  State<WinEnter> createState() => _WinEnterState();
}

class _WinEnterState extends State<WinEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: _ease);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (winReducedMotion(context)) {
      _c.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.from * (1 - v),
            child: Transform.scale(
                scale: widget.scaleFrom + (1 - widget.scaleFrom) * v,
                child: child),
          ),
        );
      },
    );
  }
}

/// Mémoire des blocs déjà apparus sur une page : un bloc ne rejoue pas son
/// entrée quand la liste le reconstruit après un aller-retour au défilement.
class WinRevealScope extends StatefulWidget {
  final Widget child;
  const WinRevealScope({super.key, required this.child});
  @override
  State<WinRevealScope> createState() => _WinRevealScopeState();
}

class _WinRevealScopeState extends State<WinRevealScope> {
  final Set<Object> seen = {};
  final DateTime born = DateTime.now();
  @override
  Widget build(BuildContext context) =>
      _RevealData(state: this, child: widget.child);
}

class _RevealData extends InheritedWidget {
  final _WinRevealScopeState state;
  const _RevealData({required this.state, required super.child});
  @override
  bool updateShouldNotify(_RevealData oldWidget) => false;
}

/// Apparition au défilement : la liste ne construit un bloc qu'à son
/// approche, il entre alors en fondu en remontant de 34 px. Les blocs déjà
/// visibles au chargement entrent en cascade ([index] × 90 ms).
class WinReveal extends StatefulWidget {
  final Object id;
  final int index;
  final Widget child;
  const WinReveal(
      {super.key, required this.id, this.index = 0, required this.child});
  @override
  State<WinReveal> createState() => _WinRevealState();
}

class _WinRevealState extends State<WinReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: _ease);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final scope =
        context.getInheritedWidgetOfExactType<_RevealData>()?.state;
    if (winReducedMotion(context) || (scope?.seen.contains(widget.id) ?? false)) {
      _c.value = 1;
      return;
    }
    scope?.seen.add(widget.id);
    final early = scope == null ||
        DateTime.now().difference(scope.born) < const Duration(milliseconds: 900);
    final delay = early
        ? Duration(milliseconds: 260 + widget.index.clamp(0, 8) * 90)
        : const Duration(milliseconds: 40);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 34 * (1 - v)),
            child: Transform.scale(scale: .96 + .04 * v, child: child),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Page d'accueil
// ─────────────────────────────────────────────────────────────────────────

/// Page complète : recherche, « Pour toi », « Accès rapide », chiffres, puis
/// les blocs propres à l'espace ([below]), chacun révélé au défilement.
class MobileHomeView extends StatelessWidget {
  final Widget search;
  final Widget forYou;
  final Widget quick;
  final Widget? stats;
  final List<Widget> top;
  final List<Widget> below;
  final Future<void> Function()? onRefresh;
  const MobileHomeView({
    super.key,
    required this.search,
    required this.forYou,
    required this.quick,
    this.stats,
    this.top = const [],
    this.below = const [],
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    var i = 0;
    final list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      // Petite marge de préconstruction : un bloc n'est construit, donc
      // révélé, qu'au moment où il approche de l'écran.
      cacheExtent: 80,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...top,
        search,
        const SizedBox(height: 22),
        forYou,
        const SizedBox(height: 22),
        quick,
        if (stats != null) ...[
          const SizedBox(height: 22),
          WinReveal(id: 'stats', index: i++, child: stats!),
        ],
        for (final b in below) ...[
          const SizedBox(height: 22),
          WinReveal(id: b.key ?? 'below$i', index: i++, child: b),
        ],
      ],
    );
    return WinRevealScope(
      child: onRefresh == null
          ? list
          : RefreshIndicator(
              color: WinColors.teal600, onRefresh: onRefresh!, child: list),
    );
  }
}

/// Titre de bloc, avec à droite une action (« Tout voir »).
class MobileBlockHead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const MobileBlockHead(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Text(title,
            style: WinType.archivo(size: 19, color: s.onStrong)
                .copyWith(letterSpacing: -0.2)),
      ),
      if (actionLabel != null)
        WinPressable(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(actionLabel!,
                style: WinType.manrope(
                    size: 13.5,
                    weight: FontWeight.w600,
                    color: s.dark ? WinColors.teal400 : WinColors.teal700)),
          ),
        ),
    ]);
  }
}

// ── 1. Recherche + filtres ────────────────────────────────────────────────

class MobileSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onSubmit;
  final VoidCallback onFilters;
  const MobileSearchBar(
      {super.key,
      required this.hint,
      required this.onSubmit,
      required this.onFilters});
  @override
  State<MobileSearchBar> createState() => _MobileSearchBarState();
}

class _MobileSearchBarState extends State<MobileSearchBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSubmit(_ctrl.text.trim());
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final focused = _focus.hasFocus;
    return WinEnter(
      duration: const Duration(milliseconds: 450),
      child: Row(children: [
        Expanded(
          child: AnimatedContainer(
            duration: WinDurations.base,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: focused ? WinColors.teal600 : s.outline),
              boxShadow: focused
                  ? [
                      BoxShadow(
                          color: WinColors.teal600.withValues(alpha: 0.15),
                          spreadRadius: 3)
                    ]
                  : const [],
            ),
            child: Row(children: [
              PhosphorIcon(PhosphorIconsRegular.magnifyingGlass,
                  size: 19, color: s.onMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  style: WinType.manrope(size: 15, color: s.onStrong),
                  cursorColor: WinColors.teal600,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: WinType.manrope(size: 15, color: s.onFaint),
                  ),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        WinPressable(
          onTap: widget.onFilters,
          pressedScale: 0.92,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          semanticLabel: context.l10n.mobileHomeFilters,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: WinColors.teal600,
                borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: const PhosphorIcon(PhosphorIconsRegular.slidersHorizontal,
                size: 21, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

// ── 2. « Pour toi » : carrousel de cartes photo ───────────────────────────

class MobileSlide {
  final String tag;
  final String title;
  final String? meta;
  final String cta;
  final VoidCallback onCta;
  final String image;
  const MobileSlide({
    required this.tag,
    required this.title,
    this.meta,
    required this.cta,
    required this.onCta,
    required this.image,
  });
}

class MobileForYou extends StatefulWidget {
  final List<MobileSlide> slides;
  const MobileForYou({super.key, required this.slides});
  @override
  State<MobileForYou> createState() => _MobileForYouState();
}

class _MobileForYouState extends State<MobileForYou> {
  final _pc = PageController(viewportFraction: 0.88);
  int _active = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (winReducedMotion(context)) {
      _pc.jumpToPage(i);
    } else {
      _pc.animateToPage(i,
          duration: const Duration(milliseconds: 420), curve: _ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final slides = widget.slides;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MobileBlockHead(context.l10n.mobileHomeForYou),
      const SizedBox(height: 12),
      SizedBox(
        height: 206,
        // Le carrousel déborde des marges de la page, comme sur le site.
        child: OverflowBox(
          maxWidth: MediaQuery.sizeOf(context).width,
          child: PageView.builder(
            controller: _pc,
            padEnds: false,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _active = i),
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(
                  left: 16, right: i == slides.length - 1 ? 16 : 0),
              child: WinEnter(
                delay: Duration(milliseconds: 80 * i.clamp(0, 3)),
                duration: const Duration(milliseconds: 600),
                from: const Offset(40, 0),
                scaleFrom: 0.96,
                child: _SlideCard(slide: slides[i]),
              ),
            ),
          ),
        ),
      ),
      if (slides.length > 1) ...[
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final on = i == _active;
            return Semantics(
              button: true,
              selected: on,
              label: context.l10n.mobileHomeSlide(i + 1, slides.length),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _goTo(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  child: AnimatedContainer(
                    duration: winReducedMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: _ease,
                    width: on ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: on
                          ? WinColors.teal600
                          : (s.dark ? WinColors.ink600 : WinColors.ink200),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ]);
  }
}

class _SlideCard extends StatelessWidget {
  final MobileSlide slide;
  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final reduced = winReducedMotion(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: MobileHomeColors.abyss,
        child: Stack(fit: StackFit.expand, children: [
          // Photo qui se resserre doucement à l'arrivée.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1 : 1.14, end: 1),
            duration: const Duration(milliseconds: 1600),
            curve: _ease,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Image.asset(slide.image,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3),
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .45, 1],
                colors: [
                  Color(0x33021510),
                  Color(0x8C021510),
                  Color(0xF2021510),
                ],
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(99)),
              child: Text(slide.tag,
                  style: WinType.manrope(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: MobileHomeColors.abyss)),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FractionallySizedBox(
                    widthFactor: .9,
                    alignment: Alignment.centerLeft,
                    child: Text(slide.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.archivo(
                            size: 21, color: Colors.white, height: 1.18)),
                  ),
                  const SizedBox(height: 10),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: slide.meta == null
                          ? const SizedBox.shrink()
                          : Text(slide.meta!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: WinType.manrope(
                                  size: 12,
                                  height: 1.4,
                                  color: Colors.white.withValues(alpha: .78))),
                    ),
                    const SizedBox(width: 12),
                    WinPressable(
                      onTap: slide.onCta,
                      pressedScale: 0.94,
                      borderRadius: BorderRadius.circular(99),
                      splashColor: Colors.white24,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: WinColors.teal600,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                                color: WinColors.teal600.withValues(alpha: .55),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                                spreadRadius: -8),
                          ],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(slide.cta,
                              style: WinType.manrope(
                                  size: 13.5,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(width: 6),
                          const PhosphorIcon(PhosphorIconsBold.arrowRight,
                              size: 14, color: Colors.white),
                        ]),
                      ),
                    ),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── 3. « Accès rapide » : pastilles rondes, pictogrammes bicolores ────────

class MobileShortcut {
  final String label;

  /// Pictogramme Phosphor au poids « duotone » (PhosphorIconsDuotone.*).
  final PhosphorIconData icon;
  final VoidCallback onTap;

  /// Nombre d'éléments à traiter, affiché en pastille sur le rond.
  final int count;
  const MobileShortcut(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.count = 0});
}

/// Pictogramme bicolore : trait vert presque noir, surface sarcelle franche
/// (Phosphor dessine la surface à 20 % d'opacité ; on la rend pleine).
class WinDuoIcon extends StatelessWidget {
  final PhosphorIconData icon;
  final double size;
  const WinDuoIcon(this.icon, {super.key, this.size = 32});
  @override
  Widget build(BuildContext context) => PhosphorIcon(icon,
      size: size,
      color: MobileHomeColors.abyss,
      duotoneSecondaryColor: WinColors.teal500,
      duotoneSecondaryOpacity: 1);
}

class MobileQuickAccess extends StatelessWidget {
  final String title;
  final List<MobileShortcut> shortcuts;

  /// Raccourcis supplémentaires montrés par « Tout voir », après [shortcuts].
  final List<MobileShortcut> more;
  const MobileQuickAccess(
      {super.key,
      required this.title,
      required this.shortcuts,
      this.more = const []});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MobileBlockHead(title,
          actionLabel: context.l10n.mobileHomeSeeAll,
          onAction: () => showAllShortcuts(context, [...shortcuts, ...more])),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, c) {
        const gap = 10.0;
        final n = shortcuts.length;
        // Quatre pastilles tiennent sur la largeur ; au-delà, la rangée défile
        // et laisse dépasser la suivante pour le signaler.
        final itemW = (c.maxWidth - 3 * gap) / (n <= 4 ? 4 : 4.35);
        final items = [
          for (var i = 0; i < n; i++)
            WinEnter(
              delay: Duration(milliseconds: 200 + 60 * i.clamp(0, 4)),
              child: SizedBox(
                  width: itemW, child: _QuickItem(shortcut: shortcuts[i])),
            ),
        ];
        if (n <= 4) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                items[i],
              ],
            ],
          );
        }
        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (_, i) => items[i],
          ),
        );
      }),
    ]);
  }
}

class _QuickItem extends StatefulWidget {
  final MobileShortcut shortcut;
  const _QuickItem({required this.shortcut});
  @override
  State<_QuickItem> createState() => _QuickItemState();
}

class _QuickItemState extends State<_QuickItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sc = widget.shortcut;
    final reduced = winReducedMotion(context);
    return Semantics(
      button: true,
      label: sc.label,
      excludeSemantics: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedScale(
          scale: _pressed && !reduced ? 0.9 : 1,
          duration: const Duration(milliseconds: 200),
          curve: _ease,
          child: Stack(clipBehavior: Clip.none, children: [
            Material(
              color: _pressed
                  ? MobileHomeColors.tintPressed
                  : MobileHomeColors.tint,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: sc.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                splashColor: reduced
                    ? Colors.transparent
                    : WinColors.teal500.withValues(alpha: .25),
                splashFactory:
                    reduced ? NoSplash.splashFactory : InkRipple.splashFactory,
                highlightColor: Colors.transparent,
                child: SizedBox(
                    width: 66,
                    height: 66,
                    child: Center(child: WinDuoIcon(sc.icon))),
              ),
            ),
            if (sc.count > 0)
              Positioned(
                top: -2,
                right: -4,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: WinColors.error,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: s.bg, width: 2.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(sc.count > 99 ? '99+' : '${sc.count}',
                        style: WinType.manrope(
                            size: 11,
                            weight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: sc.onTap,
          child: Builder(builder: (_) {
            final label = Text(sc.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: WinType.manrope(
                    size: 12.5,
                    weight: FontWeight.w600,
                    height: 1.25,
                    color: s.dark ? WinColors.cream100 : WinColors.ink800));
            // Un mot seul (« Abonnement ») se resserre au lieu d'être coupé.
            return sc.label.contains(' ')
                ? label
                : FittedBox(fit: BoxFit.scaleDown, child: label);
          }),
        ),
      ]),
    );
  }
}

/// « Tout voir » : tous les raccourcis de l'espace dans une feuille qui
/// monte du bas, quatre par rangée.
Future<void> showAllShortcuts(
    BuildContext context, List<MobileShortcut> all) {
  final s = WinTheme.of(context);
  return showModalBottomSheet(
    context: context,
    backgroundColor: s.bg,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.mobileHomeAllShortcuts,
                  style: WinType.archivo(size: 19, color: s.onStrong)),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (_, c) {
                final w = (c.maxWidth - 3 * 10) / 4;
                return Wrap(
                  spacing: 10,
                  runSpacing: 16,
                  children: [
                    for (var i = 0; i < all.length; i++)
                      WinEnter(
                        delay: Duration(milliseconds: 40 * i.clamp(0, 10)),
                        child: SizedBox(
                          width: w,
                          child: _QuickItem(
                            shortcut: MobileShortcut(
                              label: all[i].label,
                              icon: all[i].icon,
                              count: all[i].count,
                              onTap: () {
                                Navigator.pop(sheet);
                                all[i].onTap();
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ]),
      ),
    ),
  );
}

// ── 4. Chiffres : bande compacte + feuille plein écran ────────────────────

enum MobileStatTone { teal, white, gold, ink }

class MobileStat {
  final String label;
  final String value;
  final String? caption;
  final MobileStatTone tone;
  final VoidCallback? onTap;
  const MobileStat({
    required this.label,
    required this.value,
    this.caption,
    this.tone = MobileStatTone.white,
    this.onTap,
  });
}

class MobileStatsStrip extends StatelessWidget {
  final List<MobileStat> items;
  const MobileStatsStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 104,
        child: OverflowBox(
          maxWidth: MediaQuery.sizeOf(context).width,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(
                width: 150, child: _StatCard(stat: items[i], compact: true)),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: WinPressable(
          onTap: () => showMobileStatsSheet(context, items),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(context.l10n.mobileHomeStatsDetail,
                  style: WinType.manrope(
                      size: 13,
                      weight: FontWeight.w600,
                      color: s.dark ? WinColors.teal400 : WinColors.teal700)),
              const SizedBox(width: 4),
              PhosphorIcon(PhosphorIconsBold.arrowRight,
                  size: 13,
                  color: s.dark ? WinColors.teal400 : WinColors.teal700),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final MobileStat stat;
  final bool compact;
  final VoidCallback? onTap;
  const _StatCard({required this.stat, this.compact = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final (Color bg, Color border, Color label, Color value) = switch (stat.tone) {
      MobileStatTone.ink => (
          MobileHomeColors.abyss,
          MobileHomeColors.abyss,
          WinColors.ink200,
          Colors.white
        ),
      MobileStatTone.teal => (
          s.dark ? WinColors.teal700.withValues(alpha: .25) : WinColors.teal50,
          s.dark ? WinColors.teal700 : WinColors.teal100,
          s.onMuted,
          s.dark ? WinColors.teal300 : WinColors.teal700
        ),
      MobileStatTone.gold => (
          s.dark ? WinColors.gold.withValues(alpha: .18) : WinColors.goldBg,
          s.dark ? WinColors.gold.withValues(alpha: .4) : const Color(0xFFEBDDB8),
          s.onMuted,
          s.dark ? WinColors.warn : WinColors.gold
        ),
      MobileStatTone.white => (s.surface, s.outline, s.onMuted, s.onStrong),
    };
    final tap = onTap ?? stat.onTap;
    final card = Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(stat.label,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: WinType.manrope(
                    size: 12, weight: FontWeight.w600, color: label)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(stat.value,
                  style: WinType.archivo(
                      size: compact ? 22 : 28, color: value)),
            ),
            if (stat.caption != null) ...[
              const SizedBox(height: 4),
              Text(stat.caption!,
                  maxLines: compact ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.manrope(
                      size: 11, color: label.withValues(alpha: .9))),
            ],
          ]),
    );
    if (tap == null) return card;
    return WinPressable(
      onTap: tap,
      borderRadius: BorderRadius.circular(14),
      child: card,
    );
  }
}

/// Feuille plein écran des chiffres : elle glisse depuis le bas ; toucher une
/// carte la referme et ouvre l'écran correspondant.
Future<void> showMobileStatsSheet(
    BuildContext context, List<MobileStat> items) {
  return Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black38,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => _StatsSheet(items: items),
    transitionsBuilder: (ctx, a, _, child) {
      if (winReducedMotion(ctx)) return child;
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: a, curve: _ease, reverseCurve: Curves.easeInCubic)),
        child: child,
      );
    },
  ));
}

class _StatsSheet extends StatelessWidget {
  final List<MobileStat> items;
  const _StatsSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: s.outline, borderRadius: BorderRadius.circular(99)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(children: [
              Expanded(
                child: Text(context.l10n.mobileHomeStatsTitle,
                    style: WinType.archivo(size: 22, color: s.onStrong)),
              ),
              IconButton(
                tooltip: context.l10n.mobileHomeClose,
                onPressed: () => Navigator.pop(context),
                icon: PhosphorIcon(PhosphorIconsBold.x,
                    size: 20, color: s.onStrong),
              ),
            ]),
          ),
          Expanded(
            child: WinRevealScope(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05),
                itemCount: items.length,
                itemBuilder: (_, i) => WinReveal(
                  id: i,
                  index: i,
                  child: _StatCard(
                    stat: items[i],
                    onTap: items[i].onTap == null
                        ? null
                        : () {
                            Navigator.pop(context);
                            items[i].onTap!();
                          },
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Bloc carte simple pour les sections sous l'accueil (titre de bloc puis
/// contenu), même rythme que les blocs du haut.
class MobileSection extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  const MobileSection(
      {super.key,
      required this.title,
      this.actionLabel,
      this.onAction,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      MobileBlockHead(title, actionLabel: actionLabel, onAction: onAction),
      const SizedBox(height: 12),
      child,
    ]);
  }
}
