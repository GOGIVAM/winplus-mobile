import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ContentActionsSheet extends StatefulWidget {
  final ApiPublishedContent content;
  final VoidCallback? onChanged;

  const ContentActionsSheet({super.key, required this.content, this.onChanged});

  static Future<void> show(
    BuildContext context,
    ApiPublishedContent content, {
    VoidCallback? onChanged,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ContentActionsSheet(content: content, onChanged: onChanged),
      );

  @override
  State<ContentActionsSheet> createState() => _ContentActionsSheetState();
}

class _ContentActionsSheetState extends State<ContentActionsSheet> {
  static const _statuses = ['Publié', 'Brouillon', 'Archivé'];
  late String _status;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _status = switch (widget.content.status) {
      'published' => 'Publié',
      'draft' => 'Brouillon',
      'archived' => 'Archivé',
      _ => widget.content.status,
    };
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le contenu ?'),
        content: Text('« ${widget.content.title} » sera définitivement supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer', style: TextStyle(color: WinColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    await TeacherService.instance.deleteContent(widget.content.id);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('« ${widget.content.title} » supprimé.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = widget.content;

    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: s.outline, borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Text(c.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WinType.archivo(size: 17, color: s.onStrong)),
        const SizedBox(height: 16),

        // ── Stats inline ─────────────────────────────────────────
        WinCard(
          child: Row(children: [
            _StatCell(Icons.download_outlined, '${c.downloads}', 'Téléch.', WinColors.blue500),
            _vDivider(s),
            _StatCell(Icons.star_outline, c.rating > 0 ? c.rating.toStringAsFixed(1) : '—', 'Note', WinColors.gold),
            _vDivider(s),
            _StatCell(Icons.account_balance_wallet_outlined,
                c.revenue > 0 ? '${fmtXaf(c.revenue)} XAF' : '—', 'Revenus', WinColors.success),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Changer statut ───────────────────────────────────────
        Text('Statut', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 10),
        Row(children: _statuses.map((st) {
          final active = st == _status;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _status = st);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Statut changé : $st')),
                );
                widget.onChanged?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? s.primary : Colors.transparent,
                  border: Border.all(color: active ? s.primary : s.outline),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(st,
                    style: WinType.manrope(
                        size: 12,
                        weight: FontWeight.w600,
                        color: active ? s.onPrimary : s.onMuted)),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 20),

        // ── Actions ──────────────────────────────────────────────
        WinButton(
          'Modifier le contenu',
          block: true,
          variant: WinButtonVariant.outline,
          icon: Icons.edit_outlined,
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Éditeur de contenu — bientôt disponible')),
            );
          },
        ),
        const SizedBox(height: 10),
        WinButton(
          'Supprimer',
          block: true,
          variant: WinButtonVariant.outline,
          icon: Icons.delete_outline,
          loading: _deleting,
          onTap: _delete,
        ),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatCell(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: WinType.archivo(size: 14, weight: FontWeight.w700, color: s.onStrong),
            overflow: TextOverflow.ellipsis),
        Text(label, style: WinType.labelS(s.onMuted)),
      ]),
    );
  }
}

Widget _vDivider(WinScheme s) => Container(width: 1, height: 44, color: s.outline);
