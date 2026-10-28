import '../l10n/l10n.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/cart_service.dart';
import '../services/session_manager.dart';
import '../services/subject_service.dart';
import '../shared/shop/account_required_purchase_screen.dart';
import '../shared/shop/cart_screen.dart';
import '../shared/subscription/pricing_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'document_viewer_screen.dart';
import 'quiz_screen.dart';
import 'student_home.dart' show ContentCard;

class ContentDetailScreen extends StatefulWidget {
  final Content content;
  const ContentDetailScreen({super.key, required this.content});
  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _fav = false;
  List<Content> _similar = [];
  Set<String> _selectedTags = {};
  List<String> _notes = [];
  final _noteCtrl = TextEditingController();
  bool _showNoteInput = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fav = widget.content.fav;
    _loadSimilar();
    _loadPrefs();
  }

  /// Module 44 : épreuves, corrigés et livres ne se téléchargent plus ; ils
  /// s'ouvrent dans la visionneuse intégrée, filigranée au nom du compte.
  /// Le serveur applique la règle d'accès (gratuit, abonné, acheté).
  void _open({ViewerDocumentKind kind = ViewerDocumentKind.document}) {
    final id = int.tryParse(widget.content.id);
    if (id == null) {
      // Contenu de démonstration (WinData.catalog) : aucun document réel.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              context.l10n.studentDetailDemoNoDocument)));
      return;
    }
    openDocumentViewer(context,
        subjectId: id, title: widget.content.title, kind: kind);
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final rawNotes = p.getString('notes_${widget.content.id}');
    final rawTags = p.getString('tags_${widget.content.id}');
    if (!mounted) return;
    setState(() {
      if (rawNotes != null) {
        _notes = List<String>.from(jsonDecode(rawNotes) as List);
      }
      if (rawTags != null) {
        _selectedTags = Set<String>.from(jsonDecode(rawTags) as List);
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('notes_${widget.content.id}', jsonEncode(_notes));
    await p.setString(
        'tags_${widget.content.id}', jsonEncode(_selectedTags.toList()));
  }

  Future<void> _loadSimilar() async {
    try {
      final page = await SubjectService.instance.getAll(
        category: widget.content.subjectId,
        pageSize: 5,
      );
      if (mounted) {
        setState(() => _similar = page.items
            .map((s) => s.toContent())
            .where((c) => c.id != widget.content.id)
            .take(3)
            .toList());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = widget.content;
    final subj = WinData.subjectById(c.subjectId);
    final subScope = SubscriptionScope.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: s.surface,
            leading: WinCircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              WinCircleIconButton(
                icon: _fav ? Icons.favorite : Icons.favorite_border,
                iconColor: _fav ? WinColors.error : null,
                onTap: () => setState(() {
                  _fav = !_fav;
                  widget.content.fav = _fav;
                }),
              ),
              const SizedBox(width: 8),
              WinCircleIconButton(icon: Icons.share_outlined, onTap: () {}),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  color: subj.color.withValues(alpha: 0.12),
                  child: Center(
                      child: Icon(subj.icon, size: 72, color: subj.color)),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.free ? WinColors.success : Colors.white,
                      borderRadius: BorderRadius.circular(WinRadii.full),
                      boxShadow: WinShadows.sm,
                    ),
                    child: Text(c.free ? context.l10n.commonFree : '${fmtXaf(c.price)} XAF',
                        style: WinType.titleM(
                                c.free ? Colors.white : WinColors.ink800)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        WinBadge(contentTypeLabel(c.type)),
                        const SizedBox(width: 8),
                        WinBadge(c.exam, color: BadgeColor.teal),
                        const SizedBox(width: 8),
                        Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: i < c.difficulty
                                          ? s.primary
                                          : s.outline2,
                                    ))),
                      ]),
                      const SizedBox(height: 12),
                      Text(c.title, style: WinType.displayS(s.onStrong)),
                      const SizedBox(height: 14),
                      Row(children: [
                        WinAvatar(c.teacher ?? 'W', size: 32),
                        const SizedBox(width: 10),
                        Text(context.l10n.studentDetailBy(c.teacher ?? 'WinPlus'),
                            style: WinType.bodyM(s.onMuted)),
                        const SizedBox(width: 8),
                        WinBadge(context.l10n.studentDetailVerified, color: BadgeColor.teal),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < c.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: WinColors.warn,
                                )),
                        const SizedBox(width: 6),
                        Text(
                            context.l10n.studentDetailRatingCount(c.rating.toStringAsFixed(1), c.ratings),
                            style: WinType.bodyS(s.onMuted)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Icon(Icons.visibility_outlined,
                            size: 16, color: s.onFaint),
                        const SizedBox(width: 4),
                        Text(context.l10n.studentDetailViews(c.downloads),
                            style: WinType.labelM(s.onMuted)),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: s.onFaint),
                        const SizedBox(width: 4),
                        Text('${c.year}', style: WinType.labelM(s.onMuted)),
                      ]),
                      const SizedBox(height: 20),
                      const WinDivider(),
                      const SizedBox(height: 16),
                      Text(context.l10n.commonDescription, style: WinType.headlineS(s.onStrong)),
                      const SizedBox(height: 8),
                      Text(c.description ?? context.l10n.studentDetailDefaultDescription,
                          style: WinType.bodyM(s.onMuted)),
                      const SizedBox(height: 20),
                      if (c.aiReco != null) ...[
                        WinAlert(c.aiReco!,
                            type: BadgeColor.teal,
                            icon: winAIIconData),
                        const SizedBox(height: 20),
                      ],
                      const WinDivider(),
                      const SizedBox(height: 16),
                      WinSectionHeader(context.l10n.studentDetailReviewsHeader(c.reviews.length)),
                      const SizedBox(height: 12),
                      if (c.reviews.isEmpty)
                        Text(context.l10n.studentDetailNoReviews,
                            style: WinType.bodyM(s.onMuted))
                      else
                        ...c.reviews.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WinCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      WinAvatar(r.author, size: 36),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Row(children: [
                                              Text(r.author,
                                                  style: WinType.titleM(
                                                      s.onStrong)),
                                              const Spacer(),
                                              Text(r.date,
                                                  style: WinType.labelS(
                                                      s.onFaint)),
                                            ]),
                                            const SizedBox(height: 4),
                                            Row(
                                                children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                          i <
                                                                  (r.rating100 /
                                                                          10)
                                                                      .floor()
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border,
                                                          size: 13,
                                                          color: WinColors.warn,
                                                        ))),
                                            const SizedBox(height: 4),
                                            Text(r.text,
                                                style:
                                                    WinType.bodyS(s.onMuted)),
                                          ])),
                                    ]),
                              ),
                            )),
                      const SizedBox(height: 20),
                      const WinDivider(),
                      const SizedBox(height: 16),
                      WinSectionHeader(context.l10n.studentDetailMyNotes),
                      const SizedBox(height: 10),
                      // Tags rapides
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in [
                            'À réviser',
                            'Difficile',
                            'Maîtrisé',
                            'À acheter'
                          ])
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_selectedTags.contains(tag)) {
                                    _selectedTags.remove(tag);
                                  } else {
                                    _selectedTags.add(tag);
                                  }
                                });
                                _savePrefs();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 140),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _selectedTags.contains(tag)
                                      ? s.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: _selectedTags.contains(tag)
                                          ? s.primary
                                          : s.outline),
                                  borderRadius:
                                      BorderRadius.circular(WinRadii.full),
                                ),
                                child: Text(
                                    {
                                          'À réviser': context
                                              .l10n.studentDetailTagToRevise,
                                          'Difficile':
                                              context.l10n.studentDetailTagHard,
                                          'Maîtrisé': context
                                              .l10n.studentDetailTagMastered,
                                          'À acheter':
                                              context.l10n.studentDetailTagToBuy,
                                        }[tag] ??
                                        tag,
                                    style: WinType.manrope(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: _selectedTags.contains(tag)
                                            ? s.onPrimary
                                            : s.onMuted)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Existing notes
                      ..._notes.map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: WinCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.notes_outlined,
                                        size: 16, color: WinColors.teal500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(note,
                                            style: WinType.bodyS(s.onSurface))),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _notes.remove(note));
                                        _savePrefs();
                                      },
                                      child: Icon(Icons.close,
                                          size: 16, color: s.onFaint),
                                    ),
                                  ]),
                            ),
                          )),
                      // Add note toggle
                      if (_showNoteInput) ...[
                        TextField(
                          controller: _noteCtrl,
                          autofocus: true,
                          maxLines: 1,
                          maxLength: 150,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: context.l10n.studentDetailAddNoteHint,
                            hintStyle: WinType.bodyS(s.onFaint),
                            filled: true,
                            fillColor: s.surface2,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(WinRadii.md),
                                borderSide: BorderSide(color: s.outline)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(WinRadii.md),
                                borderSide: BorderSide(color: s.outline)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(WinRadii.md),
                                borderSide:
                                    BorderSide(color: s.primary, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: WinButton(context.l10n.commonSave,
                                icon: Icons.check,
                                block: true,
                                small: true, onTap: () {
                              final t = _noteCtrl.text.trim();
                              if (t.isNotEmpty) {
                                setState(() {
                                  _notes.add(t);
                                  _noteCtrl.clear();
                                });
                                _savePrefs();
                              }
                              setState(() => _showNoteInput = false);
                            }),
                          ),
                          const SizedBox(width: 10),
                          WinButton(context.l10n.commonCancel,
                              variant: WinButtonVariant.ghost,
                              small: true,
                              onTap: () => setState(() {
                                    _noteCtrl.clear();
                                    _showNoteInput = false;
                                  })),
                        ]),
                      ] else
                        GestureDetector(
                          onTap: () => setState(() => _showNoteInput = true),
                          child: Row(children: [
                            Icon(Icons.add_circle_outline,
                                size: 18, color: s.primary),
                            const SizedBox(width: 6),
                            Text(context.l10n.studentDetailAddNote,
                                style: WinType.bodyS(s.primary)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      if (_similar.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const WinDivider(),
                        const SizedBox(height: 16),
                        WinSectionHeader(context.l10n.studentDetailSimilar),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 210,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => SizedBox(
                                width: 150,
                                child: ContentCard(content: _similar[i])),
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ]),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        content: c,
        // Lot 9.7b : droit catalog.access (plan élève, plan parent, licence).
        isPremium: subScope.has(EntitlementKeys.catalogAccess),
        onOpen: () => _open(),
        onOpenCorrection: () => _open(kind: ViewerDocumentKind.correction),
      ),
    );
  }
}

class _BottomBar extends StatefulWidget {
  final Content content;
  final bool isPremium;
  final VoidCallback onOpen;
  final VoidCallback onOpenCorrection;
  const _BottomBar({
    required this.content,
    required this.isPremium,
    required this.onOpen,
    required this.onOpenCorrection,
  });

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  bool _adding = false;
  // Lot 9.7b : accès calculé par le serveur (achat, abonnement, parent,
  // licence) et aperçu des premières pages (droit catalog.preview_pages).
  SubjectViewAccess? _access;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final id = int.tryParse(widget.content.id);
    if (id == null || widget.content.free) return;
    if (!await SessionManager.isLoggedIn()) return;
    final access = await SubjectService.instance.viewAccess(id);
    if (mounted) setState(() => _access = access);
  }

  void _openPreview(BuildContext context) {
    final id = int.tryParse(widget.content.id);
    if (id == null) return;
    openDocumentViewer(context,
        subjectId: id,
        title: widget.content.title,
        onPurchase: () => _addToCart(context));
  }

  Future<void> _addToCart(BuildContext context) async {
    final loggedIn = await SessionManager.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      Navigator.push(
          context,
          WinPageRoute(
              builder: (_) =>
                  AccountRequiredPurchaseScreen(content: widget.content)));
      return;
    }
    final subjectId = int.tryParse(widget.content.id);
    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.current.studentDetailDemoNoSubject)));
      return;
    }
    setState(() => _adding = true);
    final cart = await CartService.instance.addItem(subjectId);
    if (!mounted) return;
    setState(() => _adding = false);
    if (cart != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L10n.current.studentDetailAddedToCart),
        action: SnackBarAction(
          label: L10n.current.studentDetailViewCart,
          onPressed: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const CartScreen())),
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.studentDetailAddToCartError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = widget.content;
    final isPremium = widget.isPremium || (_access?.canRead ?? false);
    final canReadCorrection = content.free || widget.isPremium || (_access?.canReadCorrection ?? false);
    final previewPages = _access?.hasPreview == true ? _access!.previewPages : 0;
    final onOpen = widget.onOpen;
    final onOpenCorrection = widget.onOpenCorrection;
    Widget btn;

    if (content.type == ContentType.quiz) {
      btn = WinButton(context.l10n.studentDetailStartQuiz,
          block: true,
          icon: Icons.play_arrow_rounded,
          onTap: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const QuizHubScreen())));
    } else if (content.free || isPremium) {
      // Lecture dans la visionneuse uniquement : plus de bouton de
      // téléchargement ni de copie hors ligne (Module 44).
      btn = Column(mainAxisSize: MainAxisSize.min, children: [
        WinButton(
            content.type == ContentType.livre
                ? context.l10n.studentDetailReadBook
                : context.l10n.studentDetailReadInApp,
            block: true,
            icon: Icons.menu_book_outlined,
            onTap: onOpen),
        if (content.hasCorrection && canReadCorrection) ...[
          const SizedBox(height: 8),
          WinButton(context.l10n.studentDetailViewAnswers,
              block: true,
              variant: WinButtonVariant.outline,
              icon: Icons.fact_check_outlined,
              onTap: onOpenCorrection),
        ],
      ]);
    } else {
      btn = Column(mainAxisSize: MainAxisSize.min, children: [
        if (previewPages > 0) ...[
          WinButton(context.l10n.studentDetailReadPreview(previewPages),
              block: true,
              variant: WinButtonVariant.outline,
              icon: Icons.visibility_outlined,
              onTap: () => _openPreview(context)),
          const SizedBox(height: 8),
        ],
        WinButton(context.l10n.studentDetailAddToCartPrice(fmtXaf(content.price)),
            block: true,
            loading: _adding,
            icon: Icons.shopping_cart_outlined,
            onTap: _adding ? null : () => _addToCart(context)),
        const SizedBox(height: 8),
        // Lot 9.7b : plus de prix écrit en dur ; les plans et leurs prix TTC
        // viennent de l'API sur l'écran des tarifs.
        GestureDetector(
          onTap: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const PricingScreen())),
          child: Text(context.l10n.studentDetailOrSubscriptions,
              style: WinType.bodyS(s.primary), textAlign: TextAlign.center),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
          color: s.surface, border: Border(top: BorderSide(color: s.outline))),
      child: btn,
    );
  }
}
