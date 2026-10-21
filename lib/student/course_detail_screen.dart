import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../services/cart_service.dart';
import '../services/course_service.dart';
import '../services/parent_service.dart';
import '../services/session_manager.dart';
import '../shared/shop/checkout_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'course_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseDetail? _course;
  bool _loading = true;
  bool _enrolling = false;
  bool _buying = false;
  bool _isTeacher = false;
  bool _isParent = false;
  String? _error;
  final Set<int> _openSections = {0};

  List<CourseReview> _reviews = [];
  int _reviewRating = 5;
  final _reviewCtrl = TextEditingController();
  bool _submittingReview = false;
  bool _reviewSuccess = false;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    _load();
    SessionManager.getUserRole().then((r) {
      if (mounted) {
        setState(() {
          _isTeacher = r == 'teacher';
          _isParent = r == 'parent';
        });
      }
    });
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        CourseService.instance.get(widget.courseId),
        CourseService.instance.getReviews(widget.courseId),
      ]);
      if (mounted) {
        setState(() {
          _course = results[0] as CourseDetail;
          _reviews = results[1] as List<CourseReview>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = L10n.current.studentCourseNotFound;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      _submittingReview = true;
      _reviewError = null;
    });
    try {
      await CourseService.instance.submitReview(
        widget.courseId,
        _reviewRating,
        comment:
            _reviewCtrl.text.trim().isEmpty ? null : _reviewCtrl.text.trim(),
      );
      final reviews = await CourseService.instance.getReviews(widget.courseId);
      if (mounted)
        setState(() {
          _reviews = reviews;
          _reviewSuccess = true;
          _reviewCtrl.clear();
        });
    } catch (e) {
      if (mounted) {
        setState(() => _reviewError = L10n.current.studentCourseReviewSubmitError);
      }
    } finally {
      if (mounted) {
        setState(() => _submittingReview = false);
      }
    }
  }

  Future<void> _enroll() async {
    final c = _course;
    if (c == null) return;
    setState(() => _enrolling = true);
    try {
      await CourseService.instance.enroll(c.id);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          WinPageRoute(
            builder: (_) =>
                CoursePlayerScreen(courseId: c.id, courseTitle: c.title),
          ));
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e is CourseActionRefused
              ? e.message
              : L10n.current.studentCourseEnrolError;
          _enrolling = false;
        });
    }
  }

  /// Lot 9.7b (F2) : achat d'une formation payante sur mobile. La formation
  /// est ajoutée au panier serveur puis payée en Mobile Money (écran de
  /// paiement existant) ou, pour un professeur, avec son solde WinPlus.
  /// L'accès s'ouvre à la confirmation du paiement, côté serveur.
  Future<void> _buy({required bool withBalance}) async {
    final c = _course;
    if (c == null) return;
    setState(() {
      _buying = true;
      _error = null;
    });
    final addError = await CartService.instance.addCourse(c.id);
    if (!mounted) return;
    if (addError != null) {
      setState(() {
        _error = addError;
        _buying = false;
      });
      _load();
      return;
    }
    if (withBalance) {
      final payError = await CourseService.instance.payCartWithBalance();
      if (!mounted) return;
      setState(() {
        _error = payError;
        _buying = false;
      });
      if (payError == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.studentCoursePurchased)));
      }
      _load();
      return;
    }
    setState(() => _buying = false);
    await Navigator.push(
        context, WinPageRoute(builder: (_) => const CheckoutScreen()));
    if (mounted) _load();
  }

  /// Lot 9.7b (F14) : achat pour un enfant lié, débité du portefeuille parent.
  Future<void> _offerToChild(CourseDetail c) async {
    List<ApiChild> children;
    try {
      children = await ParentService.instance.getChildren();
    } catch (_) {
      children = [];
    }
    if (!mounted) return;
    if (children.isEmpty) {
      setState(() => _error = L10n.current.studentCourseNoChild);
      return;
    }
    final s = WinTheme.of(context);
    final child = await showModalBottomSheet<ApiChild>(
      context: context,
      backgroundColor: s.surface,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
                L10n.current.studentCourseOfferTitle(c.title, c.price.toInt()),
                style: WinType.titleM(s.onStrong)),
          ),
          ...children.map((ch) => ListTile(
                leading: const Icon(Icons.child_care),
                title: Text(ch.firstName, style: WinType.bodyM(s.onStrong)),
                onTap: () => Navigator.pop(ctx, ch),
              )),
        ]),
      ),
    );
    if (child == null || !mounted) return;
    setState(() {
      _buying = true;
      _error = null;
    });
    final err = await CourseService.instance.purchaseForChild(c.id, child.id);
    if (!mounted) return;
    setState(() {
      _buying = false;
      _error = err;
    });
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.current.studentCourseOffered(child.firstName))));
    }
  }

  void _openPurchaseSheet(CourseDetail c) {
    final s = WinTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: s.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.studentCourseBuy, style: WinType.headlineS(s.onStrong)),
                const SizedBox(height: 6),
                Text(
                    context.l10n.studentCourseBuyNote(c.price.toInt()),
                    style: WinType.bodyS(s.onMuted)),
                const SizedBox(height: 16),
                WinButton(
                  context.l10n.studentCoursePayMomo,
                  block: true,
                  icon: Icons.phone_android,
                  onTap: () {
                    Navigator.pop(ctx);
                    _buy(withBalance: false);
                  },
                ),
                if (_isTeacher) ...[
                  const SizedBox(height: 10),
                  WinButton(
                    context.l10n.studentCoursePayBalance,
                    block: true,
                    variant: WinButtonVariant.secondary,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      Navigator.pop(ctx);
                      _buy(withBalance: true);
                    },
                  ),
                ],
              ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (_loading)
      return Scaffold(
          backgroundColor: s.bg,
          body: const Center(child: CircularProgressIndicator()));
    if (_course == null)
      return Scaffold(
        backgroundColor: s.bg,
        appBar: AppBar(
            backgroundColor: s.surface,
            foregroundColor: s.onStrong,
            elevation: 0),
        body: Center(
            child: Text(_error ?? context.l10n.studentCourseError, style: WinType.bodyM(s.onMuted))),
      );

    final c = _course!;
    final totalLessons = c.sections.fold(0, (a, s) => a + s.lessons.length);

    return Scaffold(
      backgroundColor: s.bg,
      body: CustomScrollView(slivers: [
        // Hero AppBar
        SliverAppBar(
          expandedHeight: c.thumbnailUrl != null ? 220 : 120,
          pinned: true,
          backgroundColor: WinColors.ink900,
          foregroundColor: Colors.white,
          leading: WinCircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: c.thumbnailUrl != null
                ? Image.network(c.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: WinColors.ink900))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [WinColors.ink900, WinColors.ink700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            title: Text(c.title,
                style: WinType.titleM(Colors.white).copyWith(shadows: [
                  const Shadow(color: Colors.black54, blurRadius: 4),
                ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ),

        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Category + level chips
            Wrap(spacing: 8, children: [
              if (c.category != null) WinBadge(c.category!),
              if (c.level != null)
                WinBadge(c.level!, color: BadgeColor.neutral),
            ]),
            const SizedBox(height: 12),

            // Stats row
            Row(children: [
              Icon(Icons.people_outline, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text(context.l10n.studentCourseEnrolled(c.enrolledCount),
                  style: WinType.labelM(s.onMuted)),
              const SizedBox(width: 12),
              Icon(Icons.schedule_outlined, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text(c.durationStr, style: WinType.labelM(s.onMuted)),
              const SizedBox(width: 12),
              Icon(Icons.play_circle_outline, size: 15, color: s.onMuted),
              const SizedBox(width: 4),
              Text(context.l10n.studentCourseLessons(totalLessons), style: WinType.labelM(s.onMuted)),
            ]),

            if (c.avgRating > 0) ...[
              const SizedBox(height: 8),
              Row(children: [
                ...List.generate(
                    5,
                    (i) => Icon(
                          i < c.avgRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: WinColors.gold,
                        )),
                const SizedBox(width: 6),
                Text(
                    context.l10n.studentDetailRatingCount(c.avgRating.toStringAsFixed(1), c.reviewsCount),
                    style: WinType.labelM(s.onMuted)),
              ]),
            ],

            const SizedBox(height: 16),

            // Price + CTA
            WinCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Lot 9.7b : prix TTC (18.21) ; formation vendue seule,
                  // jamais incluse dans un abonnement (18.16).
                  Row(children: [
                    Text(
                      c.isPaid ? '${c.price.toInt()} XAF' : context.l10n.commonFree,
                      style: WinType.archivo(
                          size: 22,
                          color: c.isPaid ? s.onStrong : WinColors.teal600),
                    ),
                    if (c.isPaid && (c.isPurchased || c.isEnrolled)) ...[
                      const SizedBox(width: 8),
                      WinBadge(context.l10n.studentCoursePurchasedBadge),
                    ],
                  ]),
                  if (c.isPaid) ...[
                    const SizedBox(height: 2),
                    Text(context.l10n.studentCourseVatNote,
                        style: WinType.labelS(s.onMuted)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: WinType.bodyS(WinColors.error)),
                  ],
                  const SizedBox(height: 12),
                  if (c.isEnrolled)
                    WinButton(
                      context.l10n.studentCourseContinue,
                      block: true,
                      icon: Icons.play_arrow,
                      onTap: () => Navigator.push(
                          context,
                          WinPageRoute(
                            builder: (_) => CoursePlayerScreen(
                                courseId: c.id, courseTitle: c.title),
                          )),
                    )
                  else if (c.isOwner)
                    WinButton(context.l10n.studentCourseYours,
                        block: true, variant: WinButtonVariant.outline)
                  else if (c.isPurchased)
                    // Achetée, accès pas encore ouvert (paiement tout juste
                    // confirmé) : le serveur rattache l'inscription à l'achat.
                    WinButton(
                      context.l10n.studentCoursePurchasedStart,
                      block: true,
                      loading: _enrolling,
                      icon: Icons.check_circle_outline,
                      onTap: _enrolling ? null : _enroll,
                    )
                  else if (c.isPaid && _isParent)
                    WinButton(
                      context.l10n.studentCourseOfferChild,
                      block: true,
                      loading: _buying,
                      icon: Icons.card_giftcard_outlined,
                      onTap: _buying ? null : () => _offerToChild(c),
                    )
                  else if (c.isPaid)
                    WinButton(
                      context.l10n.studentCourseBuy,
                      block: true,
                      loading: _buying,
                      icon: Icons.shopping_bag_outlined,
                      onTap: _buying ? null : () => _openPurchaseSheet(c),
                    )
                  else
                    WinButton(
                      context.l10n.studentCourseStartFree,
                      block: true,
                      loading: _enrolling,
                      icon: Icons.school_outlined,
                      onTap: _enrolling ? null : _enroll,
                    ),
                  if (c.certificateEnabled) ...[
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.workspace_premium_outlined,
                          size: 14, color: s.onMuted),
                      const SizedBox(width: 6),
                      Text(context.l10n.studentCourseCertIncluded,
                          style: WinType.labelM(s.onMuted)),
                    ]),
                  ],
                ])),

            // Objectives
            if (c.objectives.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(context.l10n.studentCourseObjectives,
                  style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(
                  child: Column(
                      children: c.objectives
                          .map((o) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          size: 16, color: s.primary),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(o,
                                              style:
                                                  WinType.bodyM(s.onSurface))),
                                    ]),
                              ))
                          .toList())),
            ],

            // Requirements
            if (c.requirements.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(context.l10n.studentCourseRequirements, style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(
                  child: Column(
                      children: c.requirements
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.arrow_right,
                                          size: 18, color: s.onMuted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                          child: Text(r,
                                              style:
                                                  WinType.bodyM(s.onSurface))),
                                    ]),
                              ))
                          .toList())),
            ],

            // Description
            if (c.description != null && c.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(context.l10n.commonDescription, style: WinType.headlineS(s.onStrong)),
              const SizedBox(height: 10),
              WinCard(
                  child:
                      Text(c.description!, style: WinType.bodyM(s.onSurface))),
            ],

            // Curriculum
            const SizedBox(height: 20),
            Text(context.l10n.studentCourseContent, style: WinType.headlineS(s.onStrong)),
            const SizedBox(height: 4),
            Text(
                context.l10n.studentCourseCurriculumSummary(c.sections.length, totalLessons, c.durationStr),
                style: WinType.labelM(s.onMuted)),
            const SizedBox(height: 10),
            ...c.sections.asMap().entries.map((entry) {
              final i = entry.key;
              final sec = entry.value;
              final open = _openSections.contains(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: s.cardBg,
                  borderRadius: BorderRadius.circular(WinRadii.lg),
                  border: Border.all(color: s.cardBorder),
                ),
                child: Column(children: [
                  InkWell(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(WinRadii.lg)),
                    onTap: () => setState(() {
                      if (open) {
                        _openSections.remove(i);
                      } else {
                        _openSections.add(i);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Expanded(
                            child: Text(sec.title,
                                style: WinType.titleM(s.onStrong))),
                        Text('${sec.lessons.length}',
                            style: WinType.labelM(s.onMuted)),
                        const SizedBox(width: 4),
                        Icon(
                            open
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                            color: s.onMuted),
                      ]),
                    ),
                  ),
                  if (open) ...sec.lessons.map((l) => _LessonRow(lesson: l)),
                ]),
              );
            }),

            // Reviews
            const SizedBox(height: 20),
            Row(children: [
              const Icon(Icons.star_rounded, size: 18, color: WinColors.gold),
              const SizedBox(width: 6),
              Text(c.reviewsCount > 0 ? context.l10n.studentDetailReviewsHeader(c.reviewsCount) : context.l10n.studentCourseReviews,
                  style: WinType.headlineS(s.onStrong)),
            ]),
            const SizedBox(height: 10),

            // Formulaire si inscrit et pas encore soumis
            if (c.isEnrolled && !_reviewSuccess) ...[
              WinCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(context.l10n.studentCourseLeaveReview,
                        style: WinType.titleM(s.onStrong)),
                    const SizedBox(height: 10),
                    Row(
                        children: List.generate(
                            5,
                            (i) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _reviewRating = i + 1),
                                  child: Icon(
                                    i < _reviewRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 30,
                                    color: WinColors.gold,
                                  ),
                                ))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reviewCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.l10n.studentCourseReviewHint,
                        hintStyle: WinType.bodyM(s.onFaint),
                        filled: true,
                        fillColor: s.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WinRadii.md),
                          borderSide: BorderSide(color: s.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(WinRadii.md),
                          borderSide: BorderSide(color: s.outline),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (_reviewError != null) ...[
                      const SizedBox(height: 6),
                      Text(_reviewError!,
                          style: WinType.bodyS(WinColors.error)),
                    ],
                    const SizedBox(height: 12),
                    WinButton(
                      context.l10n.studentCoursePostReview,
                      block: true,
                      loading: _submittingReview,
                      onTap: _submittingReview ? null : _submitReview,
                    ),
                  ])),
              const SizedBox(height: 12),
            ],

            if (_reviewSuccess)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Icon(Icons.check_circle, size: 16, color: WinColors.success),
                  const SizedBox(width: 6),
                  Text(context.l10n.studentCourseReviewThanks,
                      style: WinType.bodyM(WinColors.success)),
                ]),
              ),

            // Liste des avis
            if (_reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(context.l10n.studentCourseNoReviews,
                    style: WinType.bodyM(s.onMuted)),
              )
            else
              ..._reviews.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WinCard(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: r.authorAvatarUrl != null
                                ? NetworkImage(r.authorAvatarUrl!)
                                : null,
                            backgroundColor: s.surface2,
                            child: r.authorAvatarUrl == null
                                ? Text(r.authorName[0].toUpperCase(),
                                    style: WinType.labelM(s.onMuted))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(r.authorName,
                                          style: WinType.bodyM(s.onStrong)
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600))),
                                  if (r.isVerified) ...[
                                    Icon(Icons.verified,
                                        size: 13, color: WinColors.success),
                                    const SizedBox(width: 2),
                                  ],
                                  ...List.generate(
                                      5,
                                      (i) => Icon(
                                            i < r.rating
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            size: 13,
                                            color: WinColors.gold,
                                          )),
                                ]),
                                if (r.comment != null &&
                                    r.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(r.comment!,
                                      style: WinType.bodyM(s.onSurface)),
                                ],
                              ])),
                        ])),
                  )),

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final CourseLesson lesson;
  const _LessonRow({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.outline2)),
      ),
      child: Row(children: [
        Icon(
          lesson.isPreview ? Icons.play_circle_outline : Icons.lock_outline,
          size: 16,
          color: lesson.isPreview ? s.primary : s.onFaint,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(lesson.title, style: WinType.bodyM(s.onSurface))),
        if (lesson.isPreview)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: WinColors.teal50,
              borderRadius: BorderRadius.circular(WinRadii.full),
            ),
            child: Text(context.l10n.studentCoursePreview, style: WinType.labelS(WinColors.teal600)),
          ),
        if (lesson.videoDurationSec > 0) ...[
          const SizedBox(width: 8),
          Text(lesson.durationStr, style: WinType.labelS(s.onMuted)),
        ],
      ]),
    );
  }
}
