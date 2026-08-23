import 'package:flutter/material.dart';
import '../app_config.dart';
import '../services/favorites_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ApiFavorite>? _favs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final favs = await FavoritesService.instance.getAll();
      if (mounted) setState(() { _favs = favs; _error = null; });
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les favoris.');
    }
  }

  Future<void> _remove(ApiFavorite fav) async {
    await FavoritesService.instance.remove(fav.id);
    if (mounted) setState(() => _favs?.remove(fav));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = SubscriptionScope.of(context);
    final favs = _favs ?? [];
    final atLimit = !AppConfig.devMode && sub.isFree && favs.length >= 3;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes Favoris', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() { _favs = null; _error = null; }); _load(); },
          ),
        ],
      ),
      body: _buildBody(s, favs, atLimit),
    );
  }

  Widget _buildBody(WinScheme s, List<ApiFavorite> favs, bool atLimit) {
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_outlined, size: 56, color: s.onFaint),
        const SizedBox(height: 12),
        Text(_error!, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 16),
        WinButton('Réessayer', onTap: () { setState(() { _favs = null; _error = null; }); _load(); }),
      ]));
    }

    if (_favs == null) return const Center(child: CircularProgressIndicator());

    if (favs.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite_border, size: 64, color: s.onFaint),
          const SizedBox(height: 12),
          Text('Aucun favori pour l\'instant', style: WinType.bodyM(s.onMuted)),
          const SizedBox(height: 20),
          WinButton('Explorer le catalogue',
              icon: Icons.explore_outlined,
              onTap: () => Navigator.pop(context)),
        ]),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('${favs.length} contenu(s) sauvegardé(s)', style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 8),
        if (atLimit)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: WinAlert(
              'Plan Libre : limité à 3 favoris. Passez à Standard pour en sauvegarder plus.',
              type: BadgeColor.warn,
            ),
          ),
        ...favs.map((fav) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WinCard(
            child: Row(children: [
              Container(
                width: 48, height: 48,
                color: s.primaryContainer,
                child: Icon(Icons.bookmark_outlined, size: 24, color: s.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fav.subjectTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 2),
                  Text(
                    'Ajouté le ${fav.addedAt.day.toString().padLeft(2,'0')}/${fav.addedAt.month.toString().padLeft(2,'0')}/${fav.addedAt.year}',
                    style: WinType.labelS(s.onFaint),
                  ),
                ],
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _remove(fav),
                child: const Icon(Icons.favorite, size: 22, color: WinColors.error),
              ),
            ]),
          ),
        )),
      ],
    );
  }
}
