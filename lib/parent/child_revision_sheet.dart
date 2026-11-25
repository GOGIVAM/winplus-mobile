import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../data/reference_data.dart';
import '../l10n/l10n.dart';
import '../services/parent_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';

/// Ouvre la feuille « fiche de révision pour l'enfant » (lot 7), comme
/// GenerateRevisionForChildSheet du site : matière, chapitre, niveau, puis
/// WinAI prépare la fiche, qui apparaît dans les révisions de l'enfant.
Future<void> showChildRevisionSheet(BuildContext context, ApiChild child) =>
    showWinBottomSheet<void>(
      context: context,
      title: context.l10n.crTitle(child.firstName),
      child: ChildRevisionForm(child: child),
    );

/// Même disposition que les réglages de l'atelier WinAI.
class ChildRevisionForm extends StatefulWidget {
  final ApiChild child;
  const ChildRevisionForm({super.key, required this.child});

  @override
  State<ChildRevisionForm> createState() => _ChildRevisionFormState();
}

class _ChildRevisionFormState extends State<ChildRevisionForm> {
  String _subject = WinData.subjects.first.id;
  int _level = 1;
  bool _notify = true;
  bool _busy = false;
  String? _error;
  final _topic = TextEditingController();

  static const _difficulties = ['easy', 'medium', 'hard'];

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ParentService.instance.generateRevisionForChild(
        childId: widget.child.id,
        subject: WinData.subjectById(_subject).name,
        topic: _topic.text.trim(),
        difficulty: _difficulties[_level],
        notifyWithParentName: _notify,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(_notify
              ? l.crDoneNamed(widget.child.firstName)
              : l.crDoneAnonymous(widget.child.firstName))));
    } on ChildRevisionException catch (e) {
      if (mounted) setState(() => _error = e.message ?? l.crError);
    } catch (_) {
      if (mounted) setState(() => _error = l.commonLoadError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final levels = [l.tutoringMatEasy, l.tutoringMatMedium, l.tutoringMatHard];
    Widget label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: WinType.titleM(s.onStrong)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(l.crSub(widget.child.firstName), style: WinType.bodyM(s.onMuted)),
      const SizedBox(height: 18),
      label(l.commonSubject),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final sub in WinData.subjects)
          WinChip(sub.short, active: _subject == sub.id, onTap: () => setState(() => _subject = sub.id)),
      ]),
      const SizedBox(height: 18),
      label(l.winaiSettingsTopic),
      WinTextField(hint: l.winaiSettingsTopicHint, controller: _topic),
      const SizedBox(height: 18),
      label(l.commonLevel),
      Wrap(spacing: 8, children: [
        for (var i = 0; i < levels.length; i++)
          WinChip(levels[i], active: _level == i, onTap: () => setState(() => _level = i)),
      ]),
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _notify,
        onChanged: (v) => setState(() => _notify = v),
        title: Text(l.crNotify(widget.child.firstName), style: WinType.bodyM(s.onStrong)),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        WinAlert(_error!, type: BadgeColor.error),
      ],
      const SizedBox(height: 16),
      WinButton(l.winaiSettingsGenerate,
          block: true,
          icon: PhosphorIconsRegular.sparkle,
          loading: _busy,
          onTap: _busy ? null : _generate),
      const SizedBox(height: 8),
    ]);
  }
}
