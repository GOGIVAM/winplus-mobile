import 'package:flutter/material.dart';
import '../theme/win_theme.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int _step = 0;
  String? _level, _filiere, _objectif;

  static const _levels = ['BEPC', 'Probatoire', 'BAC', 'BTS', 'Licence', 'Concours'];
  static const _filieres = ['Scientifique', 'Littéraire', 'Technique', 'Économique'];
  static const _objectifs = ['BAC A', 'BAC C', 'BAC D', 'BEPC', 'ENSP', 'FMSB', 'Polytechnique', 'Autre'];

  bool get _canContinue => switch (_step) {
    0 => _level != null,
    1 => _filiere != null,
    _ => _objectif != null,
  };

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final steps = ['Niveau', 'Filière', 'Objectif'];
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 32),
            Row(children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    WinProgressBar(i <= _step ? 100 : 0, height: 3,
                        color: i < _step ? s.primary : (i == _step ? s.primary : s.outline)),
                    const SizedBox(height: 4),
                    Text(steps[i],
                        style: WinType.labelS(i == _step ? s.primary : s.onFaint)
                            .copyWith(fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500)),
                  ]),
                ),
              ],
            ]),
            const SizedBox(height: 40),
            Text(_stepTitle, style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(_stepSubtitle, style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 28),
            Expanded(child: _buildChips(s)),
            WinButton(
              _step < 2 ? 'Continuer' : 'Terminer',
              block: true,
              onTap: _canContinue ? _next : null,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
    0 => 'Quel est ton niveau ?',
    1 => 'Quelle est ta filière ?',
    _ => 'Quel est ton objectif ?',
  };

  String get _stepSubtitle => switch (_step) {
    0 => 'WinAI adapte le contenu à ton niveau scolaire.',
    1 => 'Pour mieux cibler les ressources disponibles.',
    _ => 'L\'exam pour lequel tu veux te préparer.',
  };

  Widget _buildChips(WinScheme s) {
    final (items, selected, onSelect) = switch (_step) {
      0 => (_levels, _level, (String v) => setState(() => _level = v)),
      1 => (_filieres, _filiere, (String v) => setState(() => _filiere = v)),
      _ => (_objectifs, _objectif, (String v) => setState(() => _objectif = v)),
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final active = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: active ? WinColors.ink800 : s.surface,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                  color: active ? WinColors.ink800 : s.outline, width: 1.5),
            ),
            child: Text(item,
                style: WinType.manrope(
                    size: 14,
                    weight: FontWeight.w600,
                    color: active ? WinColors.cream50 : s.onSurface)),
          ),
        );
      }).toList(),
    );
  }
}
