import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

/// Rapports de l'établissement.
///
/// Lot 10.6 : l'ancien écran proposait quatre « Générer PDF » qui attendaient
/// 2,5 s puis annonçaient un rapport prêt alors que rien n'était produit.
/// Seul le rapport réellement disponible est proposé : le rapport mensuel de
/// direction, envoyé par e-mail le 1er de chaque mois, que l'on peut recevoir
/// tout de suite (POST /api/institution/monthly-report/send, comme le bouton
/// « Recevoir maintenant » du web).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _MailState { idle, sending, sent, error, noEmail }

class _ReportsScreenState extends State<ReportsScreen> {
  _MailState _state = _MailState.idle;

  Future<void> _sendNow() async {
    setState(() => _state = _MailState.sending);
    try {
      await ApiClient.instance.post('/institution/monthly-report/send', data: const {});
      if (mounted) setState(() => _state = _MailState.sent);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _state =
          e.response?.statusCode == 400 ? _MailState.noEmail : _MailState.error);
    } catch (_) {
      if (mounted) setState(() => _state = _MailState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final (String meta, Color metaColor) = switch (_state) {
      _MailState.sent => (l.instMonthlyReportSent, WinColors.success),
      _MailState.error => (l.instMonthlyReportError, WinColors.error),
      _MailState.noEmail => (l.instMonthlyReportNoEmail, WinColors.error),
      _ => (l.instMonthlyReportMeta, s.onMuted),
    };
    final sending = _state == _MailState.sending;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.instReportsTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          WinCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: WinColors.teal500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                  ),
                  child: const Icon(Icons.mail_outline, size: 22, color: WinColors.teal500),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.instMonthlyReportTitle, style: WinType.titleM(s.onStrong)),
                  const SizedBox(height: 2),
                  Text(l.instMonthlyReportSub, style: WinType.labelM(s.onMuted)),
                ])),
              ]),
              const SizedBox(height: 12),
              Text(meta, style: WinType.bodyS(metaColor)),
              const SizedBox(height: 14),
              WinButton(
                sending ? l.instMonthlyReportSending : l.instMonthlyReportSendNow,
                block: true,
                icon: Icons.send_outlined,
                onTap: sending ? null : _sendNow,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
