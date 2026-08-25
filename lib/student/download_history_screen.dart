import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class DownloadHistoryScreen extends StatefulWidget {
  const DownloadHistoryScreen({super.key});
  @override
  State<DownloadHistoryScreen> createState() => _DownloadHistoryScreenState();
}

class _DownloadHistoryScreenState extends State<DownloadHistoryScreen> {
  List<ApiDownloadEntry>? _entries;
  String? _error;
  String _period = '30j';
  static const _periods = ['7j', '30j', '90j', '1 an'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await UserService.instance.getDownloadHistory();
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger l\'historique.');
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _categoryLabel(String? category) => switch (category) {
        'epreuve' => 'Épreuve',
        'cours' => 'Cours',
        'resume' => 'Résumé',
        'exercice' => 'Exercice',
        _ => 'Document',
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Historique des téléchargements',
            style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() { _entries = null; _error = null; });
              _load();
            },
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: _periods.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WinChip(p,
                  active: _period == p,
                  onTap: () => setState(() => _period = p)),
            )).toList(),
          ),
        ),
        Expanded(child: _buildBody(s)),
      ]),
    );
  }

  int get _periodDays => switch (_period) {
    '7j'   => 7,
    '30j'  => 30,
    '90j'  => 90,
    _      => 365,
  };

  List<ApiDownloadEntry> get _filtered {
    if (_entries == null) return [];
    final cutoff = DateTime.now().subtract(Duration(days: _periodDays));
    return _entries!.where((e) => e.downloadedAt.isAfter(cutoff)).toList();
  }

  Widget _buildBody(WinScheme s) {
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 12),
        Text(_error!, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 16),
        WinButton('Réessayer', onTap: () {
          setState(() { _entries = null; _error = null; });
          _load();
        }),
      ]));
    }

    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final visible = _filtered;

    if (visible.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 12),
        Text(_entries!.isEmpty
            ? 'Aucun téléchargement pour l\'instant.'
            : 'Aucun téléchargement sur $_period.',
            style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 4),
        if (_entries!.isEmpty)
          Text('Télécharge des épreuves depuis le catalogue.',
              style: WinType.bodyS(s.onFaint)),
      ]));
    }

    final groups = <String, List<ApiDownloadEntry>>{};
    for (final e in visible) {
      final key = _formatDate(e.downloadedAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('${visible.length} fichier${visible.length > 1 ? 's' : ''} · $_period',
              style: WinType.bodyS(s.onMuted)),
        ),
        ...groups.entries.map((entry) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(entry.key,
                  style: WinType.titleS(s.onFaint)
                      .copyWith(letterSpacing: 0.6)),
            ),
            ...entry.value.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: WinCard(
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    color: s.primaryContainer,
                    child: Icon(Icons.picture_as_pdf_outlined,
                        size: 22, color: s.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: WinType.titleM(s.onStrong),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        WinBadge(_categoryLabel(item.category)),
                        const SizedBox(width: 8),
                        Text(
                          '${item.downloadedAt.hour.toString().padLeft(2, '0')}:${item.downloadedAt.minute.toString().padLeft(2, '0')}',
                          style: WinType.labelS(s.onFaint),
                        ),
                      ]),
                    ],
                  )),
                  Icon(Icons.download_done_outlined,
                      size: 20, color: s.onFaint),
                ]),
              ),
            )),
          ],
        )),
      ],
    );
  }
}
