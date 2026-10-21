import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../data/models.dart' show fmtXaf;
import '../services/api_client.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

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
      if (_data?['license'] == null) _loadQuote();
    } catch (e) {
      if (mounted) setState(() => _error = _msg(e, L10n.current.instLicenseUnavailable));
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
    return d == null ? '' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text(context.l10n.instLicenseTitle, style: WinType.headlineS(s.onStrong)),
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: WinType.bodyM(s.onMuted))))
          : _data == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(16), children: license != null ? _current(s, license) : _subscribe(s)),
    );
  }

  List<Widget> _current(WinScheme s, Map license) {
    final l = context.l10n;
    final status = {'trialing': l.parentSubTrial, 'active': l.teacherVerifActive, 'past_due': l.parentSubPaymentPending, 'expired': l.tutoringStatusExpired, 'cancelled': l.instLicenseStatusEnded};
    final seats = (_data?['seats'] as List? ?? []).cast<Map>();
    return [
      WinCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.instLicenseHeading('${status[license['status']] ?? license['status']}'), style: WinType.titleL(s.onStrong))),
            if (license['isNegotiated'] == true) WinBadge(l.instLicenseNegotiated, color: BadgeColor.blue),
          ]),
          const SizedBox(height: 6),
          Text(l.instLicensePeriod(_date(license['startDate']), _date(license['endDate'])), style: WinType.bodyS(s.onMuted)),
          if (license['status'] == 'past_due')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WinAlert(l.instLicensePastDue(_date(license['graceUntil'])), type: BadgeColor.warn),
            ),
          const SizedBox(height: 12),
          Text(l.instLicenseStudentSeatsUsed('${license['studentSeatsUsed']}', '${license['studentSeats']}'), style: WinType.bodyM(s.onSurface)),
          const SizedBox(height: 4),
          WinProgressBar(((license['studentSeatsUsed'] as num) / ((license['studentSeats'] as num).clamp(1, 1 << 30))) * 100),
          const SizedBox(height: 8),
          Text(l.instLicenseTeacherSeatsUsed('${license['teacherSeatsUsed']}', '${license['teacherSeats']}'), style: WinType.bodyM(s.onSurface)),
          const SizedBox(height: 8),
          Text(l.instLicenseAiBudget('${license['aiBudgetUsedPercent']}'), style: WinType.bodyS(s.onMuted)),
          if (license['status'] != 'trialing') ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: license['autoRenew'] == true,
              onChanged: _busy
                  ? null
                  : (v) => _act(() => _api.dio.put('/institution/license/auto-renew', data: {'enabled': v}), l.instLicenseUpdateError),
              title: Text(l.instLicenseRenewWallet, style: WinType.bodyS(s.onSurface)),
            ),
          ],
        ]),
      ),
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
                Icon(seat['kind'] == 'teacher' ? Icons.school_outlined : Icons.person_outline, size: 18, color: s.primary),
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
