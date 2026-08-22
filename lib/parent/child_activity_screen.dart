import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ChildActivityScreen extends StatefulWidget {
  final ApiChild child;
  const ChildActivityScreen({super.key, required this.child});
  @override
  State<ChildActivityScreen> createState() => _ChildActivityScreenState();
}

class _ChildActivityScreenState extends State<ChildActivityScreen> {
  ApiChildStats? _stats;
  List<ApiChildActivity>? _activities;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await ParentService.instance.getChildStats(widget.child.id);
    final activities = await ParentService.instance.getChildActivity(widget.child.id);
    if (mounted) setState(() { _stats = stats; _activities = activities; });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          WinAvatar(widget.child.fullName, size: 32),
          const SizedBox(width: 10),
          Text(widget.child.fullName, style: WinType.headlineS(s.onStrong)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () { setState(() { _stats = null; _activities = null; }); _load(); },
          ),
        ],
      ),
      body: _stats == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(s),
    );
  }

  Widget _buildBody(WinScheme s) {
    final stats = _stats!;
    final activities = _activities ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(children: [
          Expanded(child: _StatBox(icon: Icons.download_outlined,
              value: '${stats.downloadsThisWeek}', label: 'Téléch./sem.', color: WinColors.blue500)),
          const SizedBox(width: 8),
          Expanded(child: _StatBox(icon: Icons.trending_up,
              value: '${stats.averageScore.round()}%', label: 'Score moy.', color: s.primary)),
          const SizedBox(width: 8),
          Expanded(child: _StatBox(icon: Icons.quiz_outlined,
              value: '${stats.quizzesThisWeek}', label: 'Quiz/sem.', color: WinColors.success)),
          const SizedBox(width: 8),
          Expanded(child: _StatBox(icon: Icons.auto_awesome_outlined,
              value: '${stats.aiSessionsThisWeek}', label: 'IA/sem.', color: s.secondary)),
        ]),
        const SizedBox(height: 20),
        Text('Activité récente', style: WinType.headlineS(s.onStrong)),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Aucune activité récente.', style: WinType.bodyM(s.onMuted)),
          )
        else
          ...activities.take(10).toList().asMap().entries.map((e) {
            final ev = e.value;
            final isLast = e.key == activities.take(10).length - 1;
            final Color dot = switch (ev.type) {
              'quiz' => s.primary,
              'download' => WinColors.blue500,
              'ai_chat' => WinColors.teal500,
              _ => s.onFaint,
            };
            final IconData icon = switch (ev.type) {
              'quiz' => Icons.quiz_outlined,
              'download' => Icons.download_outlined,
              'ai_chat' => Icons.auto_awesome_outlined,
              _ => Icons.circle_outlined,
            };
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: s.outline2)),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ev.description, style: WinType.titleM(s.onStrong)),
                      Text(_formatDate(ev.occurredAt), style: WinType.labelM(s.onMuted)),
                    ])),
                    if (ev.score != null)
                      WinBadge('${ev.score}/20', color: BadgeColor.success),
                    const SizedBox(width: 4),
                    Icon(icon, size: 16, color: dot),
                  ]),
                )),
              ]),
            );
          }),
        const SizedBox(height: 8),
        Row(children: [
          WinButton('Voir ressources', variant: WinButtonVariant.ghost,
              small: true, icon: Icons.library_books_outlined, onTap: () {}),
          const SizedBox(width: 8),
          WinButton('Générer un quiz', variant: WinButtonVariant.outline,
              small: true, icon: Icons.quiz_outlined, onTap: () {}),
        ]),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: WinType.archivo(size: 16, weight: FontWeight.w700, color: s.onStrong)),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    );
  }
}
