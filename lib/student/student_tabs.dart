import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'student_home.dart';

export 'student_home.dart' show StudentHomeTab;

/// ===================== CATALOGUE =====================
class StudentCatalogTab extends StatefulWidget {
  const StudentCatalogTab({super.key});
  @override
  State<StudentCatalogTab> createState() => _StudentCatalogTabState();
}

class _StudentCatalogTabState extends State<StudentCatalogTab> {
  String _type = 'Tout';
  final _types = const ['Tout', 'Épreuves', 'Corrections', 'Quiz', 'Livres', 'Packs'];
  final _map = const {'Épreuves': ContentType.epreuve, 'Corrections': ContentType.correction, 'Quiz': ContentType.quiz, 'Livres': ContentType.livre, 'Packs': ContentType.pack};

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final items = _type == 'Tout' ? WinData.catalog : WinData.catalog.where((c) => c.type == _map[_type]).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [Text('Catalogue', style: WinType.fraunces(size: 22, color: s.onStrong))]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: WinTextField(icon: Icons.search, hint: 'BAC C Maths 2023…'),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _types.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => WinChip(_types[i], active: _type == _types[i], onTap: () => setState(() => _type = _types[i])),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72),
          itemCount: items.length,
          itemBuilder: (_, i) => ContentCard(content: items[i]),
        ),
      ),
    ]);
  }
}

/// ===================== MON ESPACE =====================
class StudentSpaceTab extends StatelessWidget {
  const StudentSpaceTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Mon Espace', style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          Row(children: [
            Expanded(child: _MiniStat('${WinData.avgScore}%', 'Score moyen', Icons.trending_up)),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(WinData.studyToday, "Étude aujourd'hui", Icons.schedule)),
          ]),
          const SizedBox(height: 16),
          Text('Performance par matière', style: WinType.fraunces(size: 18, color: s.onStrong)),
          const SizedBox(height: 12),
          ...WinData.subjectScores.entries.map((e) {
            final subj = WinData.subjectById(e.key);
            final col = e.value < 50 ? WinColors.warn : (e.value < 75 ? s.secondary : s.primary);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                SizedBox(width: 80, child: Text(subj.short, style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
                Expanded(child: WinProgressBar(e.value.toDouble(), color: col)),
                const SizedBox(width: 8),
                SizedBox(width: 32, child: Text('${e.value}%', textAlign: TextAlign.right, style: WinType.labelM(s.onMuted))),
              ]),
            );
          }),
        ]),
      ),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _MiniStat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: s.primary),
      const SizedBox(height: 8),
      Text(value, style: WinType.fraunces(size: 22, color: s.onStrong)),
      Text(label, style: WinType.labelM(s.onMuted)),
    ]));
  }
}

/// ===================== WINAI =====================
class StudentWinAITab extends StatefulWidget {
  const StudentWinAITab({super.key});
  @override
  State<StudentWinAITab> createState() => _StudentWinAITabState();
}

class _StudentWinAITabState extends State<StudentWinAITab> {
  final _ctrl = TextEditingController();
  final List<({bool me, String text})> _msgs = [];

  void _send([String? preset]) {
    final t = preset ?? _ctrl.text;
    if (t.trim().isEmpty) return;
    setState(() { _msgs.add((me: true, text: t)); _ctrl.clear(); });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _msgs.add((me: false, text: "Bien sûr ! Voici une explication claire et structurée. Pose-moi une question plus précise et je détaille pas à pas.")));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final suggestions = ['Explique-moi les dérivées', 'Plan de révision BAC C', 'Mes matières faibles ?', 'Génère un quiz Chimie'];
    return Column(children: [
      Expanded(
        child: _msgs.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Spacer(),
                  const WinAIOrb(size: 80),
                  const SizedBox(height: 20),
                  Text('WinAI', style: WinType.fraunces(size: 28, color: s.onStrong)),
                  const SizedBox(height: 6),
                  Text('Ton assistant pédagogique personnel', style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6,
                    children: suggestions.map((q) => GestureDetector(
                      onTap: () => _send(q),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: WinColors.teal50, borderRadius: BorderRadius.circular(12), border: Border.all(color: WinColors.teal100)),
                        alignment: Alignment.centerLeft,
                        child: Text(q, style: WinType.manrope(size: 13, weight: FontWeight.w600, color: WinColors.teal700)),
                      ),
                    )).toList(),
                  ),
                  const Spacer(),
                ]),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  return Align(
                    alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.me ? WinColors.ink800 : s.cardBg,
                        border: m.me ? null : Border.all(color: s.cardBorder),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text, style: WinType.bodyM(m.me ? WinColors.cream50 : s.onSurface)),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(children: [
          Expanded(child: WinTextField(icon: Icons.attach_file, hint: 'Pose ta question à WinAI…', controller: _ctrl)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(width: 48, height: 50, decoration: BoxDecoration(color: s.primary, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.send, size: 20, color: s.onPrimary)),
          ),
        ]),
      ),
    ]);
  }
}

/// ===================== COMMUNAUTÉ =====================
class StudentCommunityTab extends StatelessWidget {
  const StudentCommunityTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final threads = [
      ('math', 'Comment résoudre une équation du 3e degré ?', 'Brenda M.', 12, true),
      ('pc', 'Différence entre tension et intensité (RC) ?', 'Yann T.', 8, false),
      ('chimie', 'Correction Chimie ENSP 2022 ?', 'Aïcha B.', 5, false),
      ('fr', 'Plan de dissertation sur la liberté', 'Steve N.', 15, true),
    ];
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Communauté', style: WinType.fraunces(size: 22, color: s.onStrong)))),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final t = threads[i];
            final subj = WinData.subjectById(t.$1);
            return WinCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [Icon(Icons.arrow_upward, size: 16, color: s.onFaint), Text('${t.$4 * 3}', style: WinType.fraunces(size: 16, color: s.onStrong))]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [WinBadge(subj.short), if (t.$5) ...[const SizedBox(width: 6), const WinBadge('Résolu', color: BadgeColor.success)]]),
                  const SizedBox(height: 6),
                  Text(t.$2, style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 8),
                  Row(children: [WinAvatar(t.$3, size: 22), const SizedBox(width: 8), Text('${t.$3} · ${t.$4} réponses', style: WinType.labelM(s.onMuted))]),
                ])),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}
