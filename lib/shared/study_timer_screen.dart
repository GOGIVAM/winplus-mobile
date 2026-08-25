import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

enum _TimerMode { pomodoro, shortBreak, longBreak }

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  _TimerMode _mode = _TimerMode.pomodoro;
  Timer? _timer;
  bool _running = false;
  int _secondsLeft = 25 * 60;
  int _completedPomodoros = 0;

  static const _durations = {
    _TimerMode.pomodoro: 25 * 60,
    _TimerMode.shortBreak: 5 * 60,
    _TimerMode.longBreak: 15 * 60,
  };

  static const _modeLabels = {
    _TimerMode.pomodoro: 'Pomodoro',
    _TimerMode.shortBreak: 'Pause courte',
    _TimerMode.longBreak: 'Pause longue',
  };

  static const _modeColors = {
    _TimerMode.pomodoro: WinColors.teal500,
    _TimerMode.shortBreak: WinColors.blue500,
    _TimerMode.longBreak: WinColors.gold,
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setMode(_TimerMode m) {
    _timer?.cancel();
    setState(() {
      _mode = m;
      _running = false;
      _secondsLeft = _durations[m]!;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          setState(() {
            _running = false;
            if (_mode == _TimerMode.pomodoro) _completedPomodoros++;
          });
          _showComplete();
        } else {
          setState(() => _secondsLeft--);
        }
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _durations[_mode]!;
    });
  }

  void _showComplete() {
    showDialog(
      context: context,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return AlertDialog(
          backgroundColor: s.surface,
          title: Text(_mode == _TimerMode.pomodoro ? 'Pomodoro terminé ! 🎉' : 'Pause terminée !',
              style: WinType.archivo(size: 18, color: s.onStrong)),
          content: Text(
            _mode == _TimerMode.pomodoro
                ? 'Bravo ! Tu as complété $_completedPomodoros pomodoro${_completedPomodoros > 1 ? 's' : ''} aujourd\'hui.'
                : 'Retour au travail !',
            style: WinType.bodyM(s.onMuted),
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); _setMode(_TimerMode.shortBreak); },
              child: const Text('Pause courte'),
            ),
            TextButton(
              onPressed: () { Navigator.pop(ctx); _setMode(_TimerMode.pomodoro); },
              child: const Text('Nouveau pomodoro'),
            ),
          ],
        );
      },
    );
  }

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _durations[_mode]!;
    return 1 - (_secondsLeft / total);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final color = _modeColors[_mode]!;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Timer Pomodoro', style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        // Mode selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: _TimerMode.values.map((m) {
            final active = m == _mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => _setMode(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? color : Colors.transparent,
                    border: Border.all(color: active ? color : s.outline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _modeLabels[m]!,
                    style: WinType.manrope(
                      size: 11,
                      weight: FontWeight.w600,
                      color: active ? Colors.white : s.onMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 40),

        // Clock ring
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 10,
                backgroundColor: s.outline,
                color: color,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_timeLabel, style: WinType.archivo(size: 52, color: s.onStrong)),
              Text(_modeLabels[_mode]!, style: WinType.labelM(s.onMuted)),
            ]),
          ]),
        ),
        const SizedBox(height: 40),

        // Controls
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: _reset,
            icon: Icon(Icons.refresh_rounded, size: 28, color: s.onMuted),
            tooltip: 'Réinitialiser',
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // placeholder to balance layout
          const SizedBox(width: 48),
        ]),
        const SizedBox(height: 36),

        // Pomodoros completed
        WinCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department_outlined, size: 20, color: WinColors.gold),
            const SizedBox(width: 8),
            Text(
              '$_completedPomodoros pomodoro${_completedPomodoros != 1 ? 's' : ''} aujourd\'hui',
              style: WinType.titleM(s.onStrong),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Tips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: WinCard(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const WinAIOrb(size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '25 min de focus + 5 min de pause = 1 pomodoro. Après 4 pomodoros, prends une pause longue de 15 min.',
                  style: WinType.bodyS(s.onMuted),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
