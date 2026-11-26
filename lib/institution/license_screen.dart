import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/models.dart' show fmtXaf;
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/win_screen.dart';
import '../services/wallet_service.dart';

/// Lot 9.7b, étape 4 (étude 9.7b section 2.3, décision 18.21) : licence de
/// l'établissement sur mobile (parité web). Licence en cours et sièges
/// (élèves au rattachement accepté, enseignants à l'affiliation acceptée),
/// libération, renouvellement automatique par le portefeuille de
/// l'établissement, ou souscription au tarif par volume et essai gratuit.
/// Remplace la carte « Licences utilisées » qui affichait des données fictives.
class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});
  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _api = ApiClient.instance;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _quote;
  String? _error;
  // Solde du portefeuille de l'établissement ; null s'il n'a pas pu être lu.
  int? _wallet;
  final _seatsCtrl = TextEditingController(text: '20');
  final _promoCtrl = TextEditingController();
  String _term = 'year';
  bool _autoRenew = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _seatsCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  String _msg(Object e, String fallback) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] is String) return d['error'] as String;
    }
    return fallback;
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await _api.dio.get('/institution/license');
      if (!mounted) return;
      setState(() => _data = (res.data as Map).cast<String, dynamic>());
      if (_data?['license'] == null) {
        _loadQuote();
      } else {
        _loadWallet();
      }
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e, L10n.current.instLicenseUnavailable));
    }
  }

  /// Le renouvellement est prélevé sur le portefeuille : son solde dit s'il
  /// passera.
  Future<void> _loadWallet() async {
    try {
      final w = await WalletService.instance.getSummary();
      if (mounted) setState(() => _wallet = w.availableXaf);
    } catch (_) {
      // Sans solde, la carte du renouvellement reste affichée sans lui.
    }
  }

  Future<void> _loadQuote() async {
    final seats = int.tryParse(_seatsCtrl.text) ?? 0;
    try {
      final res = await _api.dio.get('/institution/license/quote', queryParameters: {
        'students': seats,
        'term': _term,
        if (_promoCtrl.text.trim().isNotEmpty) 'promoCode': _promoCtrl.text.trim().toUpperCase(),
      });
      if (mounted) setState(() => _quote = (res.data as Map).cast<String, dynamic>());
    } catch (e) {
      if (mounted) setState(() => _quote = {'error': _msg(e, L10n.current.tutoringEngQuoteUnavailable)});
    }
  }

  Future<void> _act(Future<Response<dynamic>> Function() call, String fallback) async {
    setState(() => _busy = true);
    try {
      final res = await call();
      final m = (res.data is Map) ? (res.data as Map)['message'] as String? : null;
      if (mounted && m != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg(e, fallback))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(dynamic v) {
    final d = DateTime.tryParse(v as String? ?? '');
    return d == null ? '' : WinFormat.date(d);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final license = _data?['license'] as Map?;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text(context.l10n.instLicenseTitle),
      ),
      body: _error != null
          ? WinErrorState(message: _error!, onRetry: _load)
          : _data == null
              ? const WinLoading()
              : ListView(padding: const EdgeInsets.all(16), children: license != null ? _current(s, license) : _subscribe(s)),
    );
  }

  /// Une jauge : libellé à gauche, « utilisé sur total » à droite, barre dessous.
  Widget _gauge(WinScheme s, String label, String value, double percent,
          {bool warn = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: WinType.bodyM(s.onSurface))),
          Text(value,
              style: WinType.bodyM(s.onStrong)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        WinProgressBar(percent,
            height: 6, color: warn ? winTone(s, BadgeColor.warn).fg : null),
      ]);

  List<Widget> _current(WinScheme s, Map license) {
    final l = context.l10n;
    final status = {'trialing': l.parentSubTrial, 'active': l.teacherVerifActive, 'past_due': l.parentSubPaymentPending, 'expired': l.tutoringStatusExpired, 'cancelled': l.instLicenseStatusEnded};
    final tone = switch (license['status']) {
      'active' => BadgeColor.success,
      'trialing' => BadgeColor.blue,
      'past_due' => BadgeColor.warn,
      _ => BadgeColor.error,
    };
    final seats = (_data?['seats'] as List? ?? []).cast<Map>();
    final end = DateTime.tryParse(license['endDate'] as String? ?? '')?.toLocal();
    final now = DateTime.now();
    // Jours pleins jusqu'à la fin, comptés de date à date.
    final daysLeft = end == null
        ? null
        : DateTime(end.year, end.month, end.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
    final studentSeats = (license['studentSeats'] as num? ?? 0);
    final studentUsed = (license['studentSeatsUsed'] as num? ?? 0);
    final teacherSeats = (license['teacherSeats'] as num? ?? 0);
    final teacherUsed = (license['teacherSeatsUsed'] as num? ?? 0);
    final ai = (license['aiBudgetUsedPercent'] as num? ?? 0);
    double part(num used, num total) => total <= 0 ? 0 : used / total * 100;
    final amount = (license['totalPriceTtc'] as num?)?.round();
    final autoRenew = license['autoRenew'] == true;
    final missing = autoRenew && amount != null && _wallet != null && _wallet! < amount
        ? amount - _wallet!
        : null;
    return [
      WinCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(l.instLicenseTitle, style: WinType.titleL(s.onStrong)),
            WinBadge('${status[license['status']] ?? license['status']}', color: tone),
            if (license['isNegotiated'] == true) WinBadge(l.instLicenseNegotiated, color: BadgeColor.blue),
          ]),
          const SizedBox(height: 8),
          Text(l.instLicensePeriod(_date(license['startDate']), _date(license['endDate'])), style: WinType.bodyS(s.onMuted)),
          if (daysLeft != null && daysLeft >= 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l.instLicenseDaysLeft(daysLeft),
                  style: WinType.bodyS(daysLeft <= 30 ? winTone(s, BadgeColor.warn).fg : s.onMuted)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          if (license['status'] == 'past_due')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WinAlert(l.instLicensePastDue(_date(license['graceUntil'])), type: BadgeColor.warn),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      WinCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _gauge(s, l.instLicenseStudentSeats, l.instLicenseUsedOf('$studentUsed', '$studentSeats'), part(studentUsed, studentSeats),
              warn: studentSeats > 0 && studentUsed >= studentSeats),
          const SizedBox(height: 14),
          _gauge(s, l.instLicenseTeacherSeats, l.instLicenseUsedOf('$teacherUsed', '$teacherSeats'), part(teacherUsed, teacherSeats),
              warn: teacherSeats > 0 && teacherUsed >= teacherSeats),
          const SizedBox(height: 14),
          _gauge(s, l.instLicenseAiBudgetLabel, WinFormat.percent(ai), ai.toDouble(), warn: ai >= 90),
        ]),
      ),
      if (license['status'] != 'trialing') ...[
        const SizedBox(height: 12),
        WinCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoRenew,
              onChanged: _busy
                  ? null
                  : (v) => _act(() => _api.dio.put('/institution/license/auto-renew', data: {'enabled': v}), l.instLicenseUpdateError),
              title: Text(l.instLicenseAutoRenewTitle),
            ),
            Text(
                !autoRenew
                    ? l.instLicenseRenewOff(_date(license['endDate']))
                    : amount != null
                        ? l.instLicenseRenewOn(_date(license['endDate']), fmtXaf(amount))
                        : l.instLicenseRenewOnNoAmount(_date(license['endDate'])),
                style: WinType.bodyS(s.onMuted)),
            if (_wallet != null) ...[
              const SizedBox(height: 8),
              Text(l.instLicenseWalletBalance(fmtXaf(_wallet!)), style: WinType.bodyS(s.onSurface)),
            ],
            if (missing != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: WinAlert(l.instLicenseWalletShort(fmtXaf(missing)), type: BadgeColor.warn),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      Text(l.instLicenseSeatsTitle, style: WinType.headlineS(s.onStrong)),
      const SizedBox(height: 4),
      Text(l.instLicenseSeatsInfo,
          style: WinType.labelM(s.onMuted)),
      const SizedBox(height: 8),
      ...seats.map((seat) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WinCard(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(seat['kind'] == 'teacher' ? PhosphorIconsRegular.graduationCap : PhosphorIconsRegular.user, size: 18, color: s.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('${seat['name'] ?? l.instLicenseAccount('${seat['userId']}')}', style: WinType.titleM(s.onStrong))),
                TextButton(
                  onPressed: _busy ? null : () => _act(() => _api.dio.delete('/institution/license/seats/${seat['id']}'), l.instLicenseReleaseError),
                  child: Text(l.instLicenseRelease),
                ),
              ]),
            ),
          )),
    ];
  }

  List<Widget> _subscribe(WinScheme s) {
    final grid = (_data?['grid'] as Map?) ?? {};
    final tiers = (grid['tiers'] as List? ?? []).cast<Map>();
    final q = _quote;
    final l = context.l10n;
    return [
      Text(l.instLicenseSubscribeTitle, style: WinType.headlineS(s.onStrong)),
      const SizedBox(height: 6),
      Text(
          '${l.instLicenseGridPrices(tiers.map((t) => l.instLicenseGridTier(fmtXaf((t['yearlyPerSeatTtc'] as num).round()), '${t['fromSeats']}')).join(' · '))} '
          '${l.instLicenseGridMin('${grid['minSeats']}', '${grid['studentsPerTeacherSeat']}')}',
          style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 14),
      WinTextField(controller: _seatsCtrl, label: l.instLicenseStudentSeats, keyboardType: TextInputType.number, onChanged: (_) => _loadQuote()),
      const SizedBox(height: 10),
      Wrap(spacing: 8, children: [
        WinChip(l.instLicenseTermYear, active: _term == 'year', onTap: () {
          setState(() => _term = 'year');
          _loadQuote();
        }),
        WinChip(l.instLicenseTermQuarter, active: _term == 'quarter', onTap: () {
          setState(() => _term = 'quarter');
          _loadQuote();
        }),
      ]),
      const SizedBox(height: 10),
      WinTextField(controller: _promoCtrl, label: l.instLicensePromo, onChanged: (_) => _loadQuote()),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _autoRenew,
        onChanged: (v) => setState(() => _autoRenew = v),
        title: Text(l.instLicenseAutoRenew, style: WinType.bodyS(s.onSurface)),
      ),
      if (q != null)
        (q['error'] ?? q['promoError']) != null
            ? WinAlert('${q['error'] ?? q['promoError']}', type: BadgeColor.error)
            : WinCard(
                padding: const EdgeInsets.all(12),
                child: Text(
                    '${l.instLicenseQuoteLine(fmtXaf((q['pricePerSeatTtc'] as num).round()), '${q['teacherSeats']}', _date(q['endsAt']))}\n'
                    '${l.instLicenseQuoteTotal(fmtXaf((q['amountDueTtc'] as num).round()))}',
                    style: WinType.bodyM(s.onSurface))),
      const SizedBox(height: 14),
      WinButton(_busy ? l.instLicenseWait : l.instLicensePurchase,
          block: true,
          onTap: _busy || q == null || (q['error'] ?? q['promoError']) != null
              ? null
              : () => _act(
                  () => _api.dio.post('/institution/license/purchase', data: {
                        'studentSeats': int.tryParse(_seatsCtrl.text) ?? 0,
                        'term': _term,
                        if (_promoCtrl.text.trim().isNotEmpty) 'promoCode': _promoCtrl.text.trim().toUpperCase(),
                        'autoRenew': _autoRenew,
                      }),
                  l.instLicensePurchaseError)),
      if (_data?['trialAvailable'] == true) ...[
        const SizedBox(height: 10),
        WinButton(l.instLicenseTrial('${grid['trialDays']}', '${grid['trialSeats']}'),
            block: true,
            variant: WinButtonVariant.outline,
            onTap: _busy ? null : () => _act(() => _api.dio.post('/institution/license/trial', data: {}), l.instLicenseTrialError)),
      ],
      const SizedBox(height: 12),
      Text(l.instLicenseSeatBenefits,
          style: WinType.labelM(s.onFaint)),
      const SizedBox(height: 4),
      Text(l.instLicensePaymentFrom, style: WinType.labelM(WinColors.ink400)),
    ];
  }
}
