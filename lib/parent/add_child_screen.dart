import 'package:flutter/material.dart';
import '../app_config.dart';
import '../services/parent_service.dart';
import '../shared/subscription/subscription_notifier.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});
  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  String? _level, _filiere, _objectif, _genre;
  bool _success = false, _error = false;

  static const _levels = ['BEPC', 'Probatoire', 'BAC', 'BTS', 'Licence', 'Concours'];
  static const _filieres = ['Scientifique', 'Littéraire', 'Technique', 'Économique'];
  static const _objectifs = ['BAC A', 'BAC C', 'BAC D', 'BEPC', 'ENSP', 'Polytechnique', 'Autre'];
  static const _genres = ['Garçon', 'Fille', 'Non précisé'];

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = true);
      return;
    }
    setState(() => _error = false);
    final parts = _nameCtrl.text.trim().split(' ');
    final ok = await ParentService.instance.addChild(
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
      level: _level ?? '',
      schoolName: null,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
      Future.delayed(const Duration(milliseconds: 1800),
          () { if (mounted) Navigator.pop(context); });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ajout.')));
    }
  }

  Widget _chips(List<String> items, String? selected, ValueChanged<String> onTap) {
    final s = WinTheme.of(context);
    return Wrap(spacing: 8, runSpacing: 8, children: items.map((item) {
      final active = selected == item;
      return GestureDetector(
        onTap: () => setState(() => onTap(item)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? WinColors.ink800 : s.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: active ? WinColors.ink800 : s.outline, width: 1.5),
          ),
          child: Text(item, style: WinType.manrope(
              size: 13, weight: FontWeight.w600,
              color: active ? WinColors.cream50 : s.onSurface)),
        ),
      );
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isFree = !AppConfig.devMode && SubscriptionScope.of(context).isFree;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ajouter un enfant', style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isFree)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: WinAlert(
                'Le plan Boutique Libre n\'inclut pas le suivi parental. Passez au plan Famille pour accéder aux alertes WinAI.',
                type: BadgeColor.warn,
              ),
            ),
          if (_success)
            WinAlert('${_nameCtrl.text.trim()} a été ajouté à votre compte.',
                type: BadgeColor.success)
          else ...[
            WinTextField(
              label: 'Prénom de l\'enfant *',
              hint: 'Ahmed, Léa…',
              icon: Icons.person_outline,
              controller: _nameCtrl,
              onChanged: (_) => setState(() => _error = false),
            ),
            if (_error)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Le prénom est requis.',
                    style: WinType.labelM(WinColors.error)),
              ),
            const SizedBox(height: 20),
            Text('Niveau scolaire', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            _chips(_levels, _level, (v) { _level = v; }),
            const SizedBox(height: 20),
            Text('Filière', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            _chips(_filieres, _filiere, (v) { _filiere = v; }),
            const SizedBox(height: 20),
            Text('Objectif', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            _chips(_objectifs, _objectif, (v) { _objectif = v; }),
            const SizedBox(height: 20),
            Text('Genre', style: WinType.titleM(s.onStrong)),
            const SizedBox(height: 8),
            _chips(_genres, _genre, (v) { _genre = v; }),
            const SizedBox(height: 32),
            WinButton('Ajouter l\'enfant', block: true, onTap: _submit),
          ],
        ]),
      ),
    );
  }
}
