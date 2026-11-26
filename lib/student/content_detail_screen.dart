import '../l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/revision_notes_service.dart';
import '../theme/win_motion.dart';
import '../data/reference_data.dart';
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
import '../widgets/external_links.dart';
import '../app_config.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ContentDetailScreen extends StatefulWidget {
  final Content content;
  const ContentDetailScreen({super.key, required this.content});
  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _fav = false;
  List<Content> _similar = [];
  // Lot 7 : notes et étiquettes de révision gardées sur le serveur (comme
  // le site) ; _pendingNotes : notes encore sur le téléphone (anciennes, ou
  // écrites sans réseau), envoyées à la prochaine ouverture.
  Set<String> _selectedTags = {};
  List<ApiRevisionNote> _serverNotes = [];
  List<String> _pendingNotes = [];
  final _noteCtrl = TextEditingController();
  bool _savingNote = false;
  int? get _subjectId => int.tryParse(widget.content.id);

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
    _loadNotes();
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

  Future<void> _loadNotes() async {
    final id = _subjectId;
    if (id == null) return;
    final svc = RevisionNotesService.instance;
    try {
      var payload = await svc.load(id);
      final hadLocal = (await svc.pendingNotes(id)).isNotEmpty;
      await svc.syncLocal(id, serverTags: payload.tags);
      if (hadLocal) payload = await svc.load(id);
      final pending = await svc.pendingNotes(id);
      if (!mounted) return;
      setState(() {
        _serverNotes = payload.notes;
        _selectedTags = payload.tags.toSet();
        _pendingNotes = pending;
      });
    } catch (_) {
      // Sans réseau : les notes encore sur le téléphone restent visibles.
      final pending = await svc.pendingNotes(id);
      if (mounted) setState(() => _pendingNotes = pending);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleTag(String tag) async {
    final id = _subjectId;
    if (id == null) return;
    final before = Set<String>.from(_selectedTags);
    setState(() {
      if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
    });
    try {
      final tags = await RevisionNotesService.instance.toggleTag(id, tag);
      if (mounted) setState(() => _selectedTags = tags.toSet());
    } catch (_) {
      if (mounted) setState(() => _selectedTags = before);
      _toast(context.l10n.studentDetailTagError);
    }
  }

  Future<void> _addNote() async {
    final id = _subjectId;
    final text = _noteCtrl.text.trim();
    if (id == null || text.isEmpty) return;
    final l = context.l10n;
    setState(() => _savingNote = true);
    try {
      final note = await RevisionNotesService.instance.add(id, text);
      _noteCtrl.clear();
      if (mounted) setState(() => _serverNotes = [note, ..._serverNotes]);
    } on DioException catch (e) {
      if (e.response != null) {
        final d = e.response?.data;
        _toast(d is Map ? (d['error']?.toString() ?? l.studentDetailNoteError) : l.studentDetailNoteError);
      } else {
        // Pas de réseau : la note est gardée et partira plus tard.
        await RevisionNotesService.instance.keepPending(id, text);
        _noteCtrl.clear();
        if (mounted) setState(() => _pendingNotes = [..._pendingNotes, text]);
        _toast(l.studentDetailNoteKeptOffline);
      }
    } catch (_) {
      _toast(l.studentDetailNoteError);
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _deleteNote(ApiRevisionNote note) async {
    final before = _serverNotes;
    setState(() => _serverNotes = _serverNotes.where((n) => n.id != note.id).toList());
    try {
      await RevisionNotesService.instance.delete(note.id);
    } catch (_) {
      if (mounted) setState(() => _serverNotes = before);
      _toast(context.l10n.studentDetailNoteError);
    }
  }

  Future<void> _deletePending(String text) async {
    final id = _subjectId;
    if (id == null) return;
    await RevisionNotesService.instance.removePending(id, text);
    if (mounted) setState(() => _pendingNotes = [..._pendingNotes]..remove(text));
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
              icon: PhosphorIconsRegular.arrowLeft,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              WinCircleIconButton(
                icon: _fav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                iconColor: _fav ? WinColors.error : null,
                onTap: () => setState(() {
                  _fav = !_fav;
                  widget.content.fav = _fav;
                }),
              ),
              const SizedBox(width: 8),
              WinCircleIconButton(
                  icon: PhosphorIconsRegular.shareNetwork,
                  // Le lien du site : il ouvre le contenu, dans l'application
                  // si elle est installée.
                  onTap: () => ExternalLinks.share(
                      '${AppConfig.siteUrl}/subjects/${widget.content.id}',
                      subject: widget.content.title)),
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
                                      PhosphorIconsFill.circle,
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
                      // Lot 1 : une note sans avis ne s'affiche pas (« 0.0 (0 avis) »).
                      if (c.ratings > 0) ...[
                      Row(children: [
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < c.rating.floor()
                                      ? PhosphorIconsFill.star
                                      : PhosphorIconsRegular.star,
                                  size: 16,
                                  color: WinColors.warn,
                                )),
                        const SizedBox(width: 6),
                        Text(
                            context.l10n.studentDetailRatingCount(WinFormat.decimal(c.rating), c.ratings),
                            style: WinType.bodyS(s.onMuted)),
                      ]),
                      const SizedBox(height: 12),
                      ],
                      Row(children: [
                        Icon(PhosphorIconsRegular.eye,
                            size: 16, color: s.onFaint),
                        const SizedBox(width: 4),
                        Text(context.l10n.studentDetailViews(c.downloads),
                            style: WinType.labelM(s.onMuted)),
                        const SizedBox(width: 16),
                        Icon(PhosphorIconsRegular.calendarBlank,
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
                                                              ? PhosphorIconsFill.star
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
                      // Étiquettes rapides (serveur, comme le site).
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final (tag, label) in [
                          ('À réviser', context.l10n.studentDetailTagToRevise),
                          ('Difficile', context.l10n.studentDetailTagHard),
                          ('Maîtrisé', context.l10n.studentDetailTagMastered),
                          ('À acheter', context.l10n.studentDetailTagToBuy),
                        ])
                          WinChip(label,
                              active: _selectedTags.contains(tag),
                              onTap: () => _toggleTag(tag)),
                      ]),
                      const SizedBox(height: 10),
                      WinCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_serverNotes.isEmpty && _pendingNotes.isEmpty)
                                Text(context.l10n.studentDetailNotesEmpty,
                                    style: WinType.bodyS(s.onMuted)),
                              for (final n in _serverNotes)
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(n.content, style: WinType.bodyM(s.onStrong)),
                                      if (n.createdAt != null)
                                        Text(WinFormat.dateShort(n.createdAt!),
                                            style: WinType.labelM(s.onMuted)),
                                    ]),
                                  ),
                                  IconButton(
                                    tooltip: context.l10n.commonDelete,
                                    icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                                    onPressed: () => _deleteNote(n),
                                  ),
                                ]),
                              for (final t in _pendingNotes)
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(t, style: WinType.bodyM(s.onStrong)),
                                      Text(context.l10n.studentDetailNotePending,
                                          style: WinType.labelM(s.onMuted)),
                                    ]),
                                  ),
                                  IconButton(
                                    tooltip: context.l10n.commonDelete,
                                    icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                                    onPressed: () => _deletePending(t),
                                  ),
                                ]),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteCtrl,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: RevisionNotesService.maxLength,
                                decoration: InputDecoration(
                                    hintText: context.l10n.studentDetailAddNoteHint),
                              ),
                              WinButton(context.l10n.studentDetailAddNote,
                                  icon: PhosphorIconsRegular.plusCircle,
                                  small: true,
                                  loading: _savingNote,
                                  onTap: _savingNote ? null : _addNote),
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
          icon: PhosphorIconsFill.play,
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
            icon: PhosphorIconsRegular.bookOpen,
            onTap: onOpen),
        if (content.hasCorrection && canReadCorrection) ...[
          const SizedBox(height: 8),
          WinButton(context.l10n.studentDetailViewAnswers,
              block: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.listChecks,
              onTap: onOpenCorrection),
        ],
      ]);
    } else {
      btn = Column(mainAxisSize: MainAxisSize.min, children: [
        if (previewPages > 0) ...[
          WinButton(context.l10n.studentDetailReadPreview(previewPages),
              block: true,
              variant: WinButtonVariant.outline,
              icon: PhosphorIconsRegular.eye,
              onTap: () => _openPreview(context)),
          const SizedBox(height: 8),
        ],
        WinButton(context.l10n.studentDetailAddToCartPrice(fmtXaf(content.price)),
            block: true,
            loading: _adding,
            icon: PhosphorIconsRegular.shoppingCart,
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
