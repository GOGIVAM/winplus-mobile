import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/announcement_service.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/mobile_home.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Pastille du type d'annonce : « Urgent » en rouge (avec son mot),
/// « Important » en avant, « Info » neutre.
Widget announcementTypeBadge(BuildContext context, String type) {
  final l = context.l10n;
  return switch (type) {
    'urgent' => WinBadge(l.annTypeUrgent, color: BadgeColor.error),
    'important' => WinBadge(l.annTypeImportant, color: BadgeColor.warn),
    _ => WinBadge(l.annTypeInfo),
  };
}

class _ReceivedCard extends StatelessWidget {
  final ApiReceivedAnnouncement a;
  const _ReceivedCard(this.a);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final from = [
      if ((a.institutionName ?? '').isNotEmpty) a.institutionName!,
      if ((a.groupName ?? '').isNotEmpty) a.groupName!,
      if (a.createdAt != null) WinFormat.dateShort(a.createdAt!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(a.title, style: WinType.titleM(s.onStrong))),
            const SizedBox(width: 8),
            announcementTypeBadge(context, a.type),
          ]),
          if (from.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(from, style: WinType.labelS(s.onMuted)),
          ],
          const SizedBox(height: 8),
          Text(a.content, style: WinType.bodyM(s.onStrong)),
        ]),
      ),
    );
  }
}

/// « Annonces » reçues des établissements (élève, parent), comme le flux du
/// tableau de bord du site (GET /institution/announcements/feed).
class AnnouncementsFeedScreen extends StatefulWidget {
  const AnnouncementsFeedScreen({super.key});

  @override
  State<AnnouncementsFeedScreen> createState() => _AnnouncementsFeedScreenState();
}

class _AnnouncementsFeedScreenState extends State<AnnouncementsFeedScreen> {
  List<ApiReceivedAnnouncement>? _items;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final list = await AnnouncementService.instance.feed();
      if (mounted) setState(() => _items = list);
    } catch (_) {
      if (mounted && _items == null) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget body;
    if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const WinLoading();
    } else if (items.isEmpty) {
      body = WinEmptyState(icon: PhosphorIconsRegular.megaphone, title: l.annFeedEmpty, message: l.annFeedEmptyHint);
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [for (final a in items) _ReceivedCard(a)],
        ),
      );
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(title: Text(l.annTitle)),
      body: SafeArea(child: body),
    );
  }
}

/// Carte d'accueil (élève, parent), comme le bloc du tableau de bord du
/// site : en-tête commun des blocs de l'accueil, trois annonces au plus,
/// « Tout voir ». N'apparaît que s'il y a au moins une annonce, quand la
/// réponse arrive : rien sinon, ni chargement ni état vide sur l'accueil.
/// (Le serveur ne dit pas si une annonce a été lue : pas de marque « non lue ».)
class AnnouncementsFeedCard extends StatefulWidget {
  const AnnouncementsFeedCard({super.key});

  @override
  State<AnnouncementsFeedCard> createState() => _AnnouncementsFeedCardState();
}

class _AnnouncementsFeedCardState extends State<AnnouncementsFeedCard> {
  List<ApiReceivedAnnouncement> _items = const [];

  @override
  void initState() {
    super.initState();
    AnnouncementService.instance.feed().then((list) {
      if (mounted) setState(() => _items = list);
    }).catchError((Object e) {
      debugPrint('Annonces : flux indisponible pour l\'accueil ($e)');
    });
  }

  void _seeAll() => Navigator.of(context)
      .push(WinPageRoute(builder: (_) => const AnnouncementsFeedScreen()));

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final s = WinTheme.of(context);
    final l = context.l10n;
    final shown = _items.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: MobileSection(
        title: l.annTitle,
        actionLabel: l.annSeeAll,
        onAction: _seeAll,
        child: WinCard(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) Divider(height: 1, color: s.outline),
              InkWell(
                onTap: _seeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: s.primaryContainer, borderRadius: BorderRadius.circular(18)),
                      child: Icon(PhosphorIconsRegular.megaphone, size: 18, color: s.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(shown[i].title,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: WinType.titleM(s.onStrong)),
                        Text(
                            [
                              if ((shown[i].institutionName ?? '').isNotEmpty) shown[i].institutionName!,
                              if (shown[i].createdAt != null) WinFormat.dateShort(shown[i].createdAt!),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WinType.labelM(s.onMuted)),
                      ]),
                    ),
                    if (shown[i].type == 'urgent') ...[
                      const SizedBox(width: 8),
                      announcementTypeBadge(context, 'urgent'),
                    ],
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
