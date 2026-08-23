import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});
  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameCtrl = TextEditingController();
  String? _level;
  bool _loading = false, _done = false;

  static const _levels = ['BEPC', 'Probatoire', 'BAC', 'BTS', 'Licence', 'Concours'];

  static const _mockStudents = [
    'Ahmed Nkono', 'Sonia Kombe', 'Armand Talla', 'Fadel Moussa',
    'Carole Biya', 'Rodrigue Nkeng', 'Martine Abanda', 'Boris Nguyen',
    'Sylvie Meka', 'Jean-Paul Ekwalla', 'Hortense Ebang', 'Blanche Owona',
  ];

  final _selected = <String>{};

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _level == null) return;
    setState(() => _loading = true);
    final ok = await InstitutionService.instance.createGroup(
      name: _nameCtrl.text.trim(),
      level: _level!,
    );
    if (!mounted) return;
    if (ok) {
      setState(() { _loading = false; _done = true; });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création du groupe.')));
    }
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
        title: Text('Créer un groupe', style: WinType.headlineS(s.onStrong)),
      ),
      body: _done
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.group_add, size: 64, color: WinColors.success),
                const SizedBox(height: 16),
                Text('Groupe créé !', style: WinType.displayS(s.onStrong)),
                const SizedBox(height: 8),
                Text(
                  '${_nameCtrl.text.trim()} — ${_selected.length} élève(s) ajouté(s).',
                  style: WinType.bodyM(s.onMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                WinButton('Retour', block: true,
                    variant: WinButtonVariant.outline,
                    onTap: () => Navigator.pop(context)),
              ]),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WinTextField(
                  label: 'Nom du groupe *',
                  hint: 'TLE C 2027, BTS Info 2…',
                  icon: Icons.group_outlined,
                  controller: _nameCtrl,
                ),
                const SizedBox(height: 20),
                Text('Niveau *', style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: _levels.map((lv) {
                  final active = _level == lv;
                  return GestureDetector(
                    onTap: () => setState(() => _level = lv),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? WinColors.ink800 : s.surface,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: active ? WinColors.ink800 : s.outline, width: 1.5),
                      ),
                      child: Text(lv, style: WinType.manrope(
                          size: 13, weight: FontWeight.w600,
                          color: active ? WinColors.cream50 : s.onSurface)),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 24),
                Row(children: [
                  Text('Ajouter des élèves', style: WinType.headlineS(s.onStrong)),
                  const Spacer(),
                  Text('${_selected.length} sélectionné(s)',
                      style: WinType.labelM(s.primary)),
                ]),
                const SizedBox(height: 8),
                const WinTextField(
                  hint: 'Rechercher un élève…',
                  icon: Icons.search,
                ),
                const SizedBox(height: 12),
                ...(_mockStudents.map((name) {
                  final sel = _selected.contains(name);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) { _selected.remove(name); }
                      else { _selected.add(name); }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: sel ? s.primaryContainer : s.cardBg,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: sel ? s.primary : s.cardBorder,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        WinAvatar(name, size: 36),
                        const SizedBox(width: 12),
                        Expanded(child: Text(name, style: WinType.titleM(s.onStrong))),
                        if (sel)
                          Icon(Icons.check_circle, size: 20, color: s.primary)
                        else
                          Icon(Icons.radio_button_unchecked, size: 20, color: s.onFaint),
                      ]),
                    ),
                  );
                })),
                const SizedBox(height: 28),
                WinButton('Créer le groupe', block: true,
                    loading: _loading,
                    icon: Icons.group_add,
                    onTap: _submit),
              ]),
            ),
    );
  }
}
