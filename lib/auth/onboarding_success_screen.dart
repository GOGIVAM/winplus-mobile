import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shell/role_shell.dart';

class OnboardingSuccessScreen extends StatefulWidget {
  final String? firstName;
  final WinRole role;
  const OnboardingSuccessScreen({
    super.key,
    this.firstName,
    this.role = WinRole.student,
  });
  @override
  State<OnboardingSuccessScreen> createState() =>
      _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState extends State<OnboardingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  static Map<WinRole, List<String>> _features(AppLocalizations l10n) => {
        WinRole.student: [
          // Lot 9.7b (restes) : « 10 000+ ressources » et « certifications
          // reconnues » n'étaient pas vrais ; seuls des avantages réels restent.
          l10n.authFeatStudent1,
          l10n.authFeatStudent2,
          l10n.authFeatStudent3,
        ],
        WinRole.parent: [
          l10n.authFeatParent1,
          l10n.commonWinaiAlerts,
          l10n.authFeatParent3,
        ],
        WinRole.teacher: [
          l10n.authFeatTeacher1,
          l10n.authFeatTeacher2,
          l10n.authFeatTeacher3,
        ],
        WinRole.institution: [
          l10n.authFeatInst1,
          l10n.authFeatInst2,
          l10n.authFeatInst3,
        ],
      };

  static Map<WinRole, String> _subtitles(AppLocalizations l10n) => {
        WinRole.student: l10n.authSuccessStudent,
        WinRole.parent: l10n.authSuccessParent,
        WinRole.teacher: l10n.authSuccessTeacher,
        WinRole.institution: l10n.authSuccessInstitution,
      };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    final allFeatures = _features(l10n);
    final allSubtitles = _subtitles(l10n);
    final features = allFeatures[widget.role] ?? allFeatures[WinRole.student]!;
    final subtitle = allSubtitles[widget.role] ?? allSubtitles[WinRole.student]!;

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: WinColors.goldBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined,
                    size: 54, color: WinColors.gold),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.authWelcomeName(widget.firstName ?? l10n.authYouDefault),
              style: WinType.displayS(s.onStrong),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(subtitle,
                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Column(
                children: features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: WinColors.successBg,
                                borderRadius:
                                    BorderRadius.circular(WinRadii.sm),
                              ),
                              child: const Icon(Icons.check,
                                  size: 16, color: WinColors.success),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child:
                                    Text(f, style: WinType.bodyM(s.onStrong))),
                          ]),
                        ))
                    .toList()),
            const Spacer(),
            WinButton(
              l10n.authStart,
              block: true,
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                WinPageRoute(builder: (_) => const RoleShell()),
                (r) => false,
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
