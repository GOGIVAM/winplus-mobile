import 'package:flutter/material.dart';
import '../services/teacher_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

class SessionCreateScreen extends StatefulWidget {
  const SessionCreateScreen({super.key});
  @override
  State<SessionCreateScreen> createState() => _SessionCreateScreenState();
}

class _SessionCreateScreenState extends State<SessionCreateScreen> {
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  int _duration = 60;
  int _maxStudents = 30;
  bool _loading = false, _done = false;

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final ok = await TeacherService.instance.createSession(
      title: _titleCtrl.text.trim(),
      date: _dateCtrl.text.trim(),
      link: _linkCtrl.text.trim(),
      durationMinutes: _duration,
      maxStudents: _maxStudents,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _loading = false;
        _done = true;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.current.teacherSessionCreateError)));
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.teacherSessionCreateTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: _done
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.video_call_outlined,
                    size: 64, color: WinColors.success),
                const SizedBox(height: 16),
                Text(context.l10n.teacherSessionCreated, style: WinType.displayS(s.onStrong)),
                const SizedBox(height: 8),
                Text(context.l10n.teacherSessionCreatedHint,
                    style: WinType.bodyM(s.onMuted),
                    textAlign: TextAlign.center),
                const SizedBox(height: 28),
                WinButton(context.l10n.commonBack,
                    block: true,
                    variant: WinButtonVariant.outline,
                    onTap: () => Navigator.pop(context)),
              ]),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WinTextField(
                        label: context.l10n.teacherSessionTitleLabel,
                        hint: context.l10n.teacherSessionTitleHint,
                        icon: Icons.title,
                        controller: _titleCtrl),
                    const SizedBox(height: 16),
                    WinTextField(
                        label: context.l10n.teacherSessionDateLabel,
                        hint: context.l10n.teacherSessionDateHint,
                        icon: Icons.calendar_today_outlined,
                        controller: _dateCtrl),
                    const SizedBox(height: 16),
                    WinTextField(
                        label: context.l10n.teacherSessionLinkLabel,
                        hint: 'https://meet.google.com/…',
                        icon: Icons.link,
                        controller: _linkCtrl),
                    const SizedBox(height: 24),
                    Text(context.l10n.teacherSessionDuration(_duration),
                        style: WinType.titleM(s.onStrong)),
                    Slider(
                      value: _duration.toDouble(),
                      min: 30,
                      max: 180,
                      divisions: 10,
                      activeColor: s.primary,
                      inactiveColor: s.outline2,
                      onChanged: (v) => setState(() => _duration = v.round()),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.l10n.teacherSession30Min, style: WinType.labelM(s.onFaint)),
                          Text(context.l10n.teacherSession3h, style: WinType.labelM(s.onFaint)),
                        ]),
                    const SizedBox(height: 16),
                    Text(context.l10n.teacherSessionMaxStudents(_maxStudents),
                        style: WinType.titleM(s.onStrong)),
                    Slider(
                      value: _maxStudents.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      activeColor: s.primary,
                      inactiveColor: s.outline2,
                      onChanged: (v) =>
                          setState(() => _maxStudents = v.round()),
                    ),
                    const SizedBox(height: 32),
                    WinButton(context.l10n.teacherSessionCreateButton,
                        block: true,
                        loading: _loading,
                        icon: Icons.video_call_outlined,
                        onTap: _submit),
                  ]),
            ),
    );
  }
}
