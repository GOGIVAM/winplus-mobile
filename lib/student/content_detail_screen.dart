import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/subject_service.dart';
import '../shared/shop/guest_order_screen.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'quiz_screen.dart';
import '../app_config.dart';

class ContentDetailScreen extends StatefulWidget {
  final Content content;
  const ContentDetailScreen({super.key, required this.content});
  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  bool _fav = false;
  List<Content> _similar = [];
  bool _downloading = false;
  String? _noteTag;
  final List<String> _notes = ['Revoir les circuits RC avant le BAC.'];
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

  Future<void> _download() async {
    final id = int.tryParse(widget.content.id);
    if (id == null) return;
    setState(() => _downloading = true);
    final ok = await SubjectService.instance.download(id);
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Téléchargement lancé !' : 'Erreur lors du téléchargement.'),
    ));
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
            expandedHeight: 220,
            pinned: true,
            backgroundColor: s.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: s.onStrong),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(_fav ? Icons.favorite : Icons.favorite_border,
                    color: _fav ? WinColors.error : s.onStrong),
                onPressed: () => setState(() { _fav = !_fav; widget.content.fav = _fav; }),
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: s.onStrong),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: subj.color.withValues(alpha: 0.12),
                child: Center(child: Icon(subj.icon, size: 72, color: subj.color)),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    WinBadge(contentTypeLabel(c.type)),
                    const SizedBox(width: 8),
                    WinBadge(c.exam, color: BadgeColor.teal),
                    const SizedBox(width: 8),
                    Row(children: List.generate(5, (i) => Icon(
                      Icons.circle, size: 7,
                      color: i < c.difficulty ? s.primary : s.outline2,
                    ))),
                  ]),
                  const SizedBox(height: 12),
                  Text(c.title, style: WinType.displayS(s.onStrong)),
                  const SizedBox(height: 14),
                  Row(children: [
                    WinAvatar(c.teacher ?? 'W', size: 32),
                    const SizedBox(width: 10),
                    Text('Par ${c.teacher ?? 'WinPlus'}',
                        style: WinType.bodyM(s.onMuted)),
                    const SizedBox(width: 8),
                    const WinBadge('Vérifié', color: BadgeColor.teal),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    ...List.generate(5, (i) => Icon(
                      i < c.rating.floor() ? Icons.star : Icons.star_border,
                      size: 16, color: WinColors.warn,
                    )),
                    const SizedBox(width: 6),
                    Text('${c.rating.toStringAsFixed(1)} (${c.ratings} avis)',
                        style: WinType.bodyS(s.onMuted)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.download_outlined, size: 16, color: s.onFaint),
                    const SizedBox(width: 4),
                    Text('${c.downloads} téléchargements',
                        style: WinType.labelM(s.onMuted)),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined, size: 16, color: s.onFaint),
                    const SizedBox(width: 4),
                    Text('${c.year}', style: WinType.labelM(s.onMuted)),
                  ]),
                  const SizedBox(height: 20),
                  const WinDivider(),
                  const SizedBox(height: 16),
                  Text('Description', style: WinType.headlineS(s.onStrong)),
                  const SizedBox(height: 8),
                  Text(c.description ?? 'Contenu éducatif de qualité.',
                      style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 20),
                  if (c.aiReco != null) ...[
                    WinAlert(c.aiReco!, type: BadgeColor.teal,
                        icon: Icons.auto_awesome_outlined),
                    const SizedBox(height: 20),
                  ],
                  const WinDivider(),
                  const SizedBox(height: 16),
                  WinSectionHeader('Avis (${c.reviews.length})'),
                  const SizedBox(height: 12),
                  if (c.reviews.isEmpty)
                    Text('Aucun avis pour l\'instant.',
                        style: WinType.bodyM(s.onMuted))
                  else
                    ...c.reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WinCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          WinAvatar(r.author, size: 36),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(r.author, style: WinType.titleM(s.onStrong)),
                              const Spacer(),
                              Text(r.date, style: WinType.labelS(s.onFaint)),
                            ]),
                            const SizedBox(height: 4),
                            Row(children: List.generate(5, (i) => Icon(
                              i < (r.rating100 / 10).floor()
                                  ? Icons.star : Icons.star_border,
                              size: 13, color: WinColors.warn,
                            ))),
                            const SizedBox(height: 4),
                            Text(r.text, style: WinType.bodyS(s.onMuted)),
                          ])),
                        ]),
                      ),
                    )),
                  const SizedBox(height: 20),
                  const WinDivider(),
                  const SizedBox(height: 16),
                  const WinSectionHeader('Mes notes'),
                  const SizedBox(height: 10),
                  // Tags rapides
                  Row(children: [
                    for (final tag in ['À réviser', 'Difficile', 'Maîtrisé'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _noteTag = _noteTag == tag ? null : tag),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _noteTag == tag ? s.primary : Colors.transparent,
                              border: Border.all(color: _noteTag == tag ? s.primary : s.outline),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag,
                                style: WinType.manrope(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: _noteTag == tag ? s.onPrimary : s.onMuted)),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  // Existing notes
                  ..._notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: WinCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.notes_outlined, size: 16, color: WinColors.teal500),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note, style: WinType.bodyS(s.onSurface))),
                        GestureDetector(
                          onTap: () => setState(() => _notes.remove(note)),
                          child: Icon(Icons.close, size: 16, color: s.onFaint),
                        ),
                      ]),
                    ),
                  )),
                  // Add note toggle
                  if (_showNoteInput) ...[
                    TextField(
                      controller: _noteCtrl,
                      autofocus: true,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ajouter une note…',
                        hintStyle: WinType.bodyS(s.onFaint),
                        filled: true,
                        fillColor: s.surface2,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: s.outline)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: s.outline)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: s.primary, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: WinButton('Enregistrer',
                            icon: Icons.check,
                            block: true,
                            small: true,
                            onTap: () {
                              final t = _noteCtrl.text.trim();
                              if (t.isNotEmpty) setState(() { _notes.add(t); _noteCtrl.clear(); });
                              setState(() => _showNoteInput = false);
                            }),
                      ),
                      const SizedBox(width: 10),
                      WinButton('Annuler',
                          variant: WinButtonVariant.ghost,
                          small: true,
                          onTap: () => setState(() { _noteCtrl.clear(); _showNoteInput = false; })),
                    ]),
                  ] else
                    GestureDetector(
                      onTap: () => setState(() => _showNoteInput = true),
                      child: Row(children: [
                        Icon(Icons.add_circle_outline, size: 18, color: s.primary),
                        const SizedBox(width: 6),
                        Text('Ajouter une note', style: WinType.bodyS(s.primary)
                            .copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  if (_similar.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const WinDivider(),
                    const SizedBox(height: 16),
                    const WinSectionHeader('Contenus similaires'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => SizedBox(
                            width: 148,
                            child: _CompactCard(_similar[i])),
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
        isPremium: subScope.isPremium,
        downloading: _downloading,
        onDownload: _download,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Content content;
  final bool isPremium;
  final bool downloading;
  final VoidCallback onDownload;
  const _BottomBar({
    required this.content,
    required this.isPremium,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    Widget btn;

    if (content.type == ContentType.quiz) {
      btn = WinButton('Commencer le quiz',
          block: true, icon: Icons.play_arrow_rounded,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuizHubScreen())));
    } else if (content.free || AppConfig.devMode || isPremium) {
      btn = WinButton(
          content.free ? 'Télécharger gratuitement' : 'Télécharger',
          block: true, icon: Icons.download_outlined,
          loading: downloading, onTap: onDownload);
    } else {
      btn = Column(mainAxisSize: MainAxisSize.min, children: [
        WinButton('Acheter — ${fmtXaf(content.price)} XAF',
            block: true, icon: Icons.shopping_cart_outlined,
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GuestOrderScreen(content: content)))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: Text('ou abonnez-vous à partir de 2 500 XAF/mois',
              style: WinType.bodyS(s.primary),
              textAlign: TextAlign.center),
        ),
      ]);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
          color: s.surface,
          border: Border(top: BorderSide(color: s.outline))),
      child: btn,
    );
  }
}

class _CompactCard extends StatelessWidget {
  final Content content;
  const _CompactCard(this.content);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final subj = WinData.subjectById(content.subjectId);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ContentDetailScreen(content: content))),
      child: WinCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 80,
            color: subj.color.withValues(alpha: 0.12),
            child: Center(child: Icon(subj.icon, size: 32, color: subj.color)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.titleM(s.onStrong)),
              const SizedBox(height: 4),
              Text(content.free ? 'Gratuit' : '${fmtXaf(content.price)} XAF',
                  style: WinType.labelM(
                      content.free ? WinColors.success : s.primary)),
            ]),
          ),
        ]),
      ),
    );
  }
}
