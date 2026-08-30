import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'content_publish_screen.dart';

class ContentActionsSheet extends StatelessWidget {
  final ApiPublishedContent content;
  final VoidCallback? onChanged;

  const ContentActionsSheet({super.key, required this.content, this.onChanged});

  static void show(
    BuildContext context,
    ApiPublishedContent content, {
    VoidCallback? onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ContentActionsSheet(content: content, onChanged: onChanged),
    );
  }

  BadgeColor get _badgeColor => switch (content.status) {
        'published' => BadgeColor.teal,
        'draft' => BadgeColor.neutral,
        'review' || 'pending' => BadgeColor.warn,
        _ => BadgeColor.neutral,
      };

  String get _statusLabel => switch (content.status) {
        'published' => 'Publié',
        'draft' => 'Brouillon',
        'review' || 'pending' => 'En révision',
        _ => content.status,
      };

  void _showStatusDialog(BuildContext context) {
    const statuses = ['Publié', 'Brouillon', 'Archivé'];
    String selected = _statusLabel;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final s = WinTheme.of(ctx);
          return AlertDialog(
            backgroundColor: s.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Changer le statut',
                style: WinType.archivo(size: 17, color: s.onStrong)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: statuses.map((st) {
                final active = selected == st;
                return GestureDetector(
                  onTap: () => setState(() => selected = st),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? s.primary : Colors.transparent,
                      border: Border.all(color: active ? s.primary : s.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      st,
                      style: WinType.manrope(
                        size: 12,
                        weight: FontWeight.w600,
                        color: active ? s.onPrimary : s.onMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: WinType.labelM(s.onMuted)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Statut changé : $selected')),
                  );
                  onChanged?.call();
                },
                child: Text('Confirmer', style: WinType.labelM(s.primary)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return AlertDialog(
          backgroundColor: s.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Supprimer ?',
              style: WinType.archivo(size: 17, color: s.onStrong)),
          content: Text(
            '« ${content.title} » sera définitivement supprimé.',
            style: WinType.bodyM(s.onMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: WinType.labelM(s.onMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await TeacherService.instance.deleteContent(content.id);
                onChanged?.call();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('Supprimer', style: WinType.labelM(WinColors.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = content;

    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: s.outline, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Titre + badge statut
            Row(children: [
              Expanded(
                child: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WinType.archivo(size: 16, color: s.onStrong),
                ),
              ),
              const SizedBox(width: 10),
              WinBadge(_statusLabel, color: _badgeColor),
            ]),
            const SizedBox(height: 14),

            // Mini-stats : téléchargements · note · revenus
            Row(children: [
              _MiniStat(
                  icon: Icons.download_outlined,
                  value: '${c.downloads}',
                  label: 'Téléch.',
                  color: WinColors.blue500),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.star_outline,
                value: c.rating > 0 ? c.rating.toStringAsFixed(1) : '',
                label: 'Note',
                color: WinColors.gold,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.account_balance_wallet_outlined,
                value: c.revenue > 0 ? '${fmtXaf(c.revenue)} XAF' : '',
                label: 'Revenus',
                color: WinColors.success,
              ),
            ]),
            const SizedBox(height: 16),

            Divider(color: s.outline, height: 1),
            const SizedBox(height: 12),

            // 4 actions liste
            _ActionRow(
              icon: Icons.bar_chart_outlined,
              label: 'Statistiques',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bientôt disponible'))),
            ),
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'Modifier les infos',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContentPublishScreen()));
              },
            ),
            _ActionRow(
              icon: Icons.swap_horiz_outlined,
              label: 'Changer le statut',
              onTap: () => _showStatusDialog(context),
            ),
            _ActionRow(
              icon: Icons.delete_outline,
              label: 'Supprimer',
              color: WinColors.error,
              onTap: () => _showDeleteDialog(context),
            ),
          ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _MiniStat(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: WinType.manrope(
                size: 12, weight: FontWeight.w700, color: s.onStrong),
            overflow: TextOverflow.ellipsis),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    ]);
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionRow(
      {required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final fg = color ?? s.onStrong;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 14),
          Text(label,
              style: WinType.bodyM(fg).copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.chevron_right, size: 18, color: s.onFaint),
        ]),
      ),
    );
  }
}
