import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../services/reports_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Album de fin d'année  récit narratif généré une fois par an
/// (YearlyAlbumService), consulté uniquement dans l'app : aucun bouton
/// d'export ni de partage.
class AlbumTab extends StatefulWidget {
  final ApiChild child;
  const AlbumTab({super.key, required this.child});
  @override
  State<AlbumTab> createState() => _AlbumTabState();
}

class _AlbumTabState extends State<AlbumTab> {
  ApiAlbum? _album;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await ReportsService.instance.getAlbum(widget.child.id);
    if (mounted)
      setState(() {
        _album = a;
        _loaded = true;
      });
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    final a = _album;
    if (a == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_stories_outlined, size: 48, color: s.onFaint),
            const SizedBox(height: 12),
            Text(
                "L'album de ${widget.child.firstName} n'a pas encore été généré cette année.",
                style: WinType.bodyM(s.onMuted),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text("Album de l'année de ${widget.child.firstName}",
            style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 4),
        Text(
            'Année scolaire ${a.schoolYear ?? ''} · mis à jour le ${_fmtDate(a.updatedAt)}',
            style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 16),
        if (a.subjectsWorked != null)
          _AlbumSection(
              icon: Icons.menu_book_outlined,
              title: 'Matières travaillées',
              text: a.subjectsWorked!),
        if (a.progression != null) ...[
          const SizedBox(height: 10),
          _AlbumSection(
              icon: Icons.trending_up,
              title: 'Progression observée',
              text: a.progression!),
        ],
        if (a.topContents.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AlbumListSection(
              icon: Icons.star_outline,
              title: 'Contenus les plus consultés',
              items: a.topContents),
        ],
        if (a.goalsSummary != null) ...[
          const SizedBox(height: 10),
          _AlbumSection(
              icon: Icons.flag_outlined,
              title: "Objectifs de l'année",
              text: a.goalsSummary!),
        ],
        if (a.intensityWeeks.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AlbumListSection(
              icon: Icons.bolt_outlined,
              title: "Moments d'intensité",
              items: a.intensityWeeks),
        ],
        if (a.bulletin != null) ...[
          const SizedBox(height: 10),
          _AlbumSection(
              icon: Icons.school_outlined,
              title: 'Bulletin',
              text: a.bulletin!),
        ],
      ],
    );
  }
}

class _AlbumSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _AlbumSection(
      {required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 17, color: WinColors.teal600),
          const SizedBox(width: 8),
          Text(title, style: WinType.titleM(s.onStrong)),
        ]),
        const SizedBox(height: 8),
        Text(text, style: WinType.bodyM(s.onStrong)),
      ]),
    );
  }
}

class _AlbumListSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  const _AlbumListSection(
      {required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 17, color: WinColors.teal600),
          const SizedBox(width: 8),
          Text(title, style: WinType.titleM(s.onStrong)),
        ]),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('  ', style: WinType.bodyS(WinColors.teal600)),
                Expanded(child: Text(item, style: WinType.bodyS(s.onStrong))),
              ]),
            )),
      ]),
    );
  }
}
