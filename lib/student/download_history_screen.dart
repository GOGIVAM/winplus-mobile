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
      body: _buildBody(s),
    );
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

    if (_entries!.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 12),
        Text('Aucun téléchargement pour l\'instant.',
            style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 4),
        Text('Télécharge des épreuves depuis le catalogue.',
            style: WinType.bodyS(s.onFaint)),
      ]));
    }

    final groups = <String, List<ApiDownloadEntry>>{};
    for (final e in _entries!) {
      final key = _formatDate(e.downloadedAt);
      groups.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('${_entries!.length} fichier${_entries!.length > 1 ? 's' : ''} téléchargé${_entries!.length > 1 ? 's' : ''}',
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
