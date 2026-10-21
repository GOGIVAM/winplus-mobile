import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
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

  Map<_TimerMode, String> get _modeLabels => {
        _TimerMode.pomodoro: context.l10n.timerModePomodoro,
        _TimerMode.shortBreak: context.l10n.timerModeShortBreak,
        _TimerMode.longBreak: context.l10n.timerModeLongBreak,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(WinRadii.xl)),
          title: Text(
              _mode == _TimerMode.pomodoro
                  ? ctx.l10n.timerPomodoroDone
                  : ctx.l10n.timerBreakDone,
              style: WinType.archivo(size: 18, color: s.onStrong)),
          content: Text(
            _mode == _TimerMode.pomodoro
                ? ctx.l10n.timerDoneBody(_completedPomodoros)
                : ctx.l10n.timerBackToWork,
            style: WinType.bodyM(s.onMuted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _setMode(_TimerMode.shortBreak);
              },
              child: Text(ctx.l10n.timerModeShortBreak),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _setMode(_TimerMode.pomodoro);
              },
              child: Text(ctx.l10n.timerNewPomodoro),
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
        title: Text(context.l10n.timerTitle,
            style: WinType.headlineS(s.onStrong)),
      ),
      body: Column(children: [
        // Mode selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
              children: _TimerMode.values.map((m) {
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
                    borderRadius: BorderRadius.circular(WinRadii.full),
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
              Text(_timeLabel,
                  style: WinType.archivo(size: 52, color: s.onStrong)),
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
            tooltip: context.l10n.timerReset,
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
            const Icon(Icons.local_fire_department_outlined,
                size: 20, color: WinColors.gold),
            const SizedBox(width: 8),
            Text(
              context.l10n.timerTodayCount(_completedPomodoros),
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
                  context.l10n.timerTip,
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
