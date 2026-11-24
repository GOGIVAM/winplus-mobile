import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/visio_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/external_links.dart';
import '../../widgets/win_screen.dart';
import '../../widgets/win_widgets.dart';
import 'visio_screen.dart';

/// « Cours en direct » (lot 9.4), comme la page /cours-en-direct du site :
/// une seule liste pour tous les rôles (GET /visio/mes-cours), triée par le
/// serveur : salles ouvertes, puis à venir, puis terminées (30 jours).
/// Professeur et répétiteur démarrent, l'élève rejoint, le parent voit les
/// cours de ses enfants sans pouvoir entrer.
class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> {
  List<ApiLiveClass>? _classes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_error) setState(() => _error = false);
    try {
      final list = await VisioService.instance.myClasses();
      if (mounted) setState(() => _classes = list);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(l.liveTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(child: _body(s, l)),
    );
  }

  Widget _body(WinScheme s, AppLocalizations l) {
    if (_error) return WinErrorState(message: l.commonLoadError, onRetry: _load);
    final list = _classes;
    if (list == null) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return WinEmptyState(
          icon: Icons.videocam_outlined, title: l.liveEmpty, message: l.liveEmptyHint);
    }
    final sections = [
      (l.liveSectionOpen, list.where((c) => c.state == 'ouverte').toList()),
      (l.liveSectionUpcoming, list.where((c) => c.state == 'a_venir').toList()),
      (l.liveSectionEnded, list.where((c) => c.state == 'terminee').toList()),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
        for (final (title, items) in sections)
          if (items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(title, style: WinType.titleM(s.onStrong)),
            ),
            for (final c in items) _LiveClassCard(c),
          ],
      ]),
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final ApiLiveClass c;
  const _LiveClassCard(this.c);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final (badge, color) = switch (c.state) {
      'ouverte' => (l.liveStateOpen, BadgeColor.success),
      'terminee' => (l.liveStateEnded, BadgeColor.neutral),
      _ => (l.liveStateUpcoming, BadgeColor.blue),
    };
    final who = c.isHost
        ? l.visioHost
        : c.isChildView && c.child != null
            ? l.liveForChild(c.child!)
            : c.host.isNotEmpty
                ? l.liveWith(c.host)
                : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: c.state == 'ouverte' ? WinColors.successBg : s.surface2,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.videocam_outlined,
                  color: c.state == 'ouverte' ? WinColors.success : s.onMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.title, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 2),
                Text(
                    '${WinFormat.dateShort(c.start)} · ${WinFormat.time(c.start)} – ${WinFormat.time(c.end)}',
                    style: WinType.labelM(s.onMuted)),
                if (who != null)
                  Text(who, style: WinType.labelM(s.onMuted)),
              ]),
            ),
            const SizedBox(width: 8),
            WinBadge(badge, color: color),
          ]),
          if (c.pendingPayment) ...[
            const SizedBox(height: 10),
            WinAlert(l.livePendingPayment, icon: Icons.schedule),
          ],
          if (c.isChildView) ...[
            const SizedBox(height: 10),
            Text(l.liveChildReadOnly, style: WinType.bodyS(s.onMuted)),
          ],
          if (c.canEnter) ...[
            const SizedBox(height: 12),
            WinButton(c.isHost ? l.visioStart : l.visioJoin,
                block: true,
                small: true,
                variant: c.state == 'ouverte'
                    ? WinButtonVariant.accent
                    : WinButtonVariant.outline,
                icon: Icons.videocam_outlined,
                onTap: () => VisioScreen.open(context, c.type, c.id, title: c.title)),
          ],
          if (c.recordings > 0) ...[
            const SizedBox(height: 8),
            WinButton(l.liveRecordingsCount(c.recordings),
                block: true,
                small: true,
                variant: WinButtonVariant.ghost,
                icon: Icons.play_circle_outline,
                onTap: () => Navigator.of(context).push(WinPageRoute(
                    builder: (_) =>
                        VisioRecordingsScreen(type: c.type, id: c.id, title: c.title)))),
          ],
        ]),
      ),
    );
  }
}

/// Enregistrements d'une séance (GET /visio/enregistrements) : chaque vidéo
/// s'ouvre dans le navigateur par son lien présigné (6 heures).
class VisioRecordingsScreen extends StatefulWidget {
  final VisioType type;
  final int id;
  final String title;
  const VisioRecordingsScreen(
      {super.key, required this.type, required this.id, required this.title});

  @override
  State<VisioRecordingsScreen> createState() => _VisioRecordingsScreenState();
}

class _VisioRecordingsScreenState extends State<VisioRecordingsScreen> {
  List<ApiVisioRecording>? _items;
  bool _error = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = false;
      _notFound = false;
    });
    try {
      final list = await VisioService.instance.recordings(widget.type, widget.id);
      if (mounted) setState(() => _items = list);
    } on VisioException {
      if (mounted) setState(() => _notFound = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).round()} Mo';
    return '${(bytes / 1024).round()} Ko';
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final items = _items;
    Widget body;
    if (_notFound) {
      body = WinEmptyState(icon: Icons.videocam_off_outlined, title: l.visioNotFound);
    } else if (_error) {
      body = WinErrorState(message: l.commonLoadError, onRetry: _load);
    } else if (items == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      body = WinEmptyState(icon: Icons.video_library_outlined, title: l.liveRecordingsEmpty);
    } else {
      body = ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.title, style: WinType.titleL(s.onStrong)),
        const SizedBox(height: 4),
        Text(l.liveRecordingsHint, style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 12),
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WinCard(
              onTap: () => ExternalLinks.open(r.url),
              child: Row(children: [
                Icon(Icons.play_circle_outline, color: s.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.bodyM(s.onStrong)),
                    Text(
                        [
                          if (r.createdAt != null) WinFormat.dateShort(r.createdAt!),
                          _size(r.sizeBytes),
                        ].join(' · '),
                        style: WinType.labelS(s.onMuted)),
                  ]),
                ),
                Icon(Icons.open_in_new, size: 18, color: s.onMuted),
              ]),
            ),
          ),
      ]);
    }
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(l.liveRecordingsTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(child: body),
    );
  }
}
