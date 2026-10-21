import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../shared/subscription/pricing_screen.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Lot 9.7b (étude 1.4) : choix des enfants couverts par le plan du parent
/// (catalogue, bonus WinAI, alertes) quand il a plus d'enfants liés que son
/// plan n'en couvre. Sans choix, les liens acceptés les plus anciens sont
/// couverts. Un changement par période d'abonnement (règle du serveur).
class CoveredChildrenScreen extends StatefulWidget {
  const CoveredChildrenScreen({super.key});
  @override
  State<CoveredChildrenScreen> createState() => _CoveredChildrenScreenState();
}

class _CoveredChildrenScreenState extends State<CoveredChildrenScreen> {
  ApiCoveredChildren? _status;
  bool _loading = true;
  bool _saving = false;
  Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(ApiCoveredChildren? st) {
    _status = st;
    _selected = st == null
        ? {}
        : st.children.where((c) => c.covered).map((c) => c.studentId).toSet();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final st = await ParentService.instance.getCoveredChildren();
    if (!mounted) return;
    setState(() {
      _apply(st);
      _loading = false;
    });
  }

  void _toggle(int id) {
    final max = _status?.max ?? 0;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < max) {
        _selected.add(id);
      } else if (max == 1) {
        _selected = {id};
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final st = await ParentService.instance.setCoveredChildren(_selected.toList());
      if (!mounted) return;
      setState(() => _apply(st));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.current.parentCoveredSaved)));
    } on CoveredChildrenException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(context.l10n.parentCoveredTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(child: _body(s)),
    );
  }

  Widget _body(WinScheme s) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final st = _status;
    if (st == null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(context.l10n.parentCoveredLoadError,
                    style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                WinButton(context.l10n.commonRetry, icon: Icons.refresh, onTap: _load),
              ])));
    }
    if (!st.selectionNeeded) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        WinCard(
            child: Text(
                st.max == null
                    ? context.l10n.parentCoveredAll
                    : context.l10n.parentCoveredUpTo(st.max ?? 0),
                style: WinType.bodyM(s.onStrong))),
      ]);
    }
    final max = st.max ?? 0;
    final initial = st.children.where((c) => c.covered).map((c) => c.studentId).toSet();
    final dirty = !(initial.length == _selected.length && initial.containsAll(_selected));
    final next = st.nextChangeAt;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      Text(
          max > 1
              ? context.l10n.parentCoveredSubMany(max, st.children.length)
              : context.l10n.parentCoveredSubOne(max, st.children.length),
          style: WinType.bodyM(s.onStrong)),
      const SizedBox(height: 12),
      for (final c in st.children)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: st.canChange && !_saving ? () => _toggle(c.studentId) : null,
            borderRadius: BorderRadius.circular(WinRadii.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _selected.contains(c.studentId) ? s.surface2 : s.surface,
                  borderRadius: BorderRadius.circular(WinRadii.md),
                  border: Border.all(color: s.outline)),
              child: Row(children: [
                Icon(
                    _selected.contains(c.studentId)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: _selected.contains(c.studentId) ? s.primary : s.onFaint),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(c.name,
                        style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600))),
                if (c.covered) WinBadge(context.l10n.parentCoveredBadge),
              ]),
            ),
          ),
        ),
      const SizedBox(height: 4),
      Text(
          '${st.customSelection ? context.l10n.parentCoveredCustom : context.l10n.parentCoveredDefault} · ${context.l10n.parentCoveredOnePerPeriod}'
          '${!st.canChange && next != null ? ' · ${context.l10n.parentCoveredNextChange(WinFormat.date(next))}' : ''}',
          style: WinType.labelM(s.onMuted)),
      const SizedBox(height: 16),
      WinButton(_saving ? context.l10n.teacherProfileSaving : context.l10n.parentCoveredSave,
          block: true,
          loading: _saving,
          onTap: st.canChange && dirty && _selected.isNotEmpty && !_saving ? _save : null),
      const SizedBox(height: 8),
      WinButton(context.l10n.parentCoveredMore,
          block: true,
          variant: WinButtonVariant.outline,
          onTap: () => Navigator.push(
              context, WinPageRoute(builder: (_) => const PricingScreen()))),
    ]);
  }
}
