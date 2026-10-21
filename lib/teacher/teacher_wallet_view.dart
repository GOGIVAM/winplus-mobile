import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/login_screen.dart';
import '../data/models.dart';
import '../services/teacher_service.dart';
import '../services/wallet_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Portefeuille professeur (lot 2, Module 5) : parité avec le web
/// (RevenueOverview + WithdrawalFlow + WalletRecharge).
///
/// Toutes les valeurs viennent du serveur (journal de portefeuille) ; aucune
/// donnée simulée, aucun calcul de solde local. États couverts : chargement,
/// portefeuille vide, erreur réseau avec nouvel essai, session expirée,
/// retrait en cours (réaffiché au retour sur l'écran), succès, échec motivé.
class TeacherWalletView extends StatefulWidget {
  const TeacherWalletView({super.key});

  @override
  State<TeacherWalletView> createState() => _TeacherWalletViewState();
}

String _xaf(int n) => '${n < 0 ? '−' : ''}${fmtXaf(n.abs())} FCFA';

String _date(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

class _TeacherWalletViewState extends State<TeacherWalletView>
    with WidgetsBindingObserver {
  static const _pageSize = 20;
  static const _pollEvery = Duration(seconds: 5);

  WalletSummary? _summary;
  WalletApiException? _error;
  bool _loading = true;

  String _source = 'all';
  final List<WalletEntry> _entries = [];
  int _entriesTotal = 0;
  int _entriesPage = 1;
  bool _entriesLoading = false;
  String? _entriesError;

  List<Map<String, dynamic>> _contentRevenue = [];
  ({String? planName, double? teacherShare})? _share;

  WalletWithdrawal? _tracked;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  /// Application en arrière-plan : le suivi s'arrête (le transfert continue
  /// côté serveur) et reprend au retour, avec le statut réel.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_tracked != null && !_tracked!.isTerminal) _startPolling();
      _loadSummary();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSummary(), _loadEntries(reset: true), _loadExtras()]);
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loading = _summary == null;
      _error = null;
    });
    try {
      final s = await WalletService.instance.getSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
        _loading = false;
        // Retrait déjà en cours : on réaffiche son état réel, pas un formulaire vierge.
        if (s.activeWithdrawal != null &&
            (_tracked == null || _tracked!.id != s.activeWithdrawal!.id)) {
          _tracked = s.activeWithdrawal;
          _startPolling();
        }
      });
    } on WalletApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (_entriesLoading) return;
    final page = reset ? 1 : _entriesPage + 1;
    setState(() {
      _entriesLoading = true;
      _entriesError = null;
    });
    try {
      final res = await WalletService.instance
          .getEntries(source: _source, page: page, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        if (reset) _entries.clear();
        _entries.addAll(res.items);
        _entriesTotal = res.total;
        _entriesPage = page;
      });
    } on WalletApiException catch (e) {
      if (mounted) setState(() => _entriesError = e.message);
    } finally {
      if (mounted) setState(() => _entriesLoading = false);
    }
  }

  Future<void> _loadExtras() async {
    try {
      final r = await Future.wait([
        TeacherService.instance.getContentRevenue(),
        TeacherService.instance.getRevenueShare(),
      ]);
      if (!mounted) return;
      setState(() {
        _contentRevenue = r[0] as List<Map<String, dynamic>>;
        _share = r[1] as ({String? planName, double? teacherShare});
      });
    } catch (_) {
      // Sections secondaires : masquées en cas d'échec, jamais remplies de données inventées.
    }
  }

  void _startPolling() {
    _poll?.cancel();
    final tracked = _tracked;
    if (tracked == null || tracked.isTerminal) return;
    _poll = Timer.periodic(_pollEvery, (_) async {
      try {
        final w = await WalletService.instance.getWithdrawal(tracked.id);
        if (!mounted) return;
        setState(() => _tracked = w);
        if (w.isTerminal) {
          _poll?.cancel();
          _loadSummary();
          _loadEntries(reset: true);
        }
      } on WalletApiException catch (e) {
        if (e.sessionExpired) _poll?.cancel();
        // Réseau indisponible : nouvel essai au prochain cycle, sans issue inventée.
      }
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
        WinPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ── Retrait ─────────────────────────────────────────────────────────

  Future<void> _openWithdraw() async {
    final s = _summary;
    if (s == null) return;
    final result = await showModalBottomSheet<WalletWithdrawal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _WithdrawSheet(summary: s),
    );
    if (result != null && mounted) {
      setState(() => _tracked = result);
      if (result.isTerminal) {
        _loadEntries(reset: true);
      } else {
        _startPolling();
      }
      _loadSummary();
    }
  }

  Future<void> _openRecharge() async {
    final s = _summary;
    if (s == null) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RechargeSheet(minXaf: s.minRechargeXaf),
    );
    if (ok == true && mounted) {
      _loadSummary();
      _loadEntries(reset: true);
    }
  }

  // ── Affichage ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    final error = _error;
    if (error != null && _summary == null) {
      return _StateMessage(
        icon: error.sessionExpired ? Icons.lock_clock_outlined : Icons.wifi_off,
        title: error.sessionExpired ? 'Session expirée' : 'Solde indisponible',
        message: error.message,
        actionLabel: error.sessionExpired ? 'Se reconnecter' : 'Réessayer',
        onAction: error.sessionExpired ? _goToLogin : _loadAll,
      );
    }

    final summary = _summary!;
    final canWithdraw = summary.availableXaf >= summary.minWithdrawalXaf &&
        (_tracked == null || _tracked!.isTerminal);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(WinRadii.xl),
                gradient: LinearGradient(
                    colors: [s.heroFrom, s.heroTo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SOLDE DISPONIBLE',
                  style: WinType.labelS(WinColors.ink300).copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text(_xaf(summary.availableXaf),
                  style: WinType.archivo(size: 32, color: WinColors.cream50)),
              const SizedBox(height: 8),
              Text('En attente : ${_xaf(summary.pendingXaf)}',
                  style: WinType.labelM(WinColors.ink200)),
              Text('Engagé (retrait en cours) : ${_xaf(summary.engagedXaf)}',
                  style: WinType.labelM(WinColors.ink200)),
              Text('Retrait minimum ${_xaf(summary.minWithdrawalXaf)}, sans frais',
                  style: WinType.labelM(WinColors.ink300)),
              if (summary.isAnomaly) ...[
                const SizedBox(height: 6),
                Text('Anomalie de solde signalée au support WinPlus.',
                    style: WinType.labelM(WinColors.warnBg)),
              ],
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                WinButton('Retirer',
                    variant: WinButtonVariant.accent,
                    small: true,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: canWithdraw ? _openWithdraw : null),
                WinButton('Recharger',
                    variant: WinButtonVariant.outline,
                    small: true,
                    icon: Icons.add,
                    onTap: _openRecharge),
              ]),
            ]),
          ),
          if (summary.isEmpty && _tracked == null) ...[
            const SizedBox(height: 12),
            WinCard(
                child: Text(
                    'Ton portefeuille est vide pour l\'instant. Tes ventes, tes séances de cours particulier, tes commissions et tes recharges l\'alimenteront.',
                    style: WinType.bodyM(s.onMuted))),
          ],
          if (_tracked != null) ...[
            const SizedBox(height: 12),
            _WithdrawalStatusCard(
                withdrawal: _tracked!,
                onDismiss: _tracked!.isTerminal ? () => setState(() => _tracked = null) : null),
          ],
          if (_share != null && _share!.teacherShare != null) ...[
            const SizedBox(height: 16),
            WinCard(
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: WinColors.successBg, shape: BoxShape.circle),
                  child: const Icon(Icons.percent, size: 18, color: WinColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cours particuliers${_share!.planName != null ? ' · plan ${_share!.planName}' : ''}',
                      style: WinType.labelM(s.onMuted)),
                  Text(
                      '${(_share!.teacherShare! * 100).round()} % pour toi · ${(100 - (_share!.teacherShare! * 100).round())} % WinPlus',
                      style: WinType.titleM(s.onStrong)),
                ])),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          Text('Historique', style: WinType.archivo(size: 18, color: s.onStrong)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final src in walletSources)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(src.$2),
                    selected: _source == src.$1,
                    onSelected: (_) {
                      setState(() => _source = src.$1);
                      _loadEntries(reset: true);
                    },
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          _buildEntries(s),
          if (_contentRevenue.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Revenus par contenu', style: WinType.archivo(size: 18, color: s.onStrong)),
            const SizedBox(height: 12),
            WinCard(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(children: [
                for (int i = 0; i < _contentRevenue.length; i++)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: i < _contentRevenue.length - 1
                            ? Border(bottom: BorderSide(color: s.outline))
                            : null),
                    child: Row(children: [
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_contentRevenue[i]['title'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
                        Text('${_contentRevenue[i]['sales'] ?? 0} ventes',
                            style: WinType.labelM(s.onMuted)),
                      ])),
                      Text('+${_xaf((_contentRevenue[i]['revenue'] as num?)?.round() ?? 0)}',
                          style: WinType.archivo(size: 15, color: WinColors.success)),
                    ]),
                  ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntries(WinScheme s) {
    if (_entriesLoading && _entries.isEmpty) {
      return const Padding(
          padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    }
    if (_entriesError != null && _entries.isEmpty) {
      return WinCard(
        child: Column(children: [
          Text(_entriesError!, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          WinButton('Réessayer',
              variant: WinButtonVariant.outline,
              small: true,
              icon: Icons.refresh,
              onTap: () => _loadEntries(reset: true)),
        ]),
      );
    }
    if (_entries.isEmpty) {
      return WinCard(
          child: Text(
              _source == 'all'
                  ? 'Aucune opération pour l\'instant.'
                  : 'Aucune opération pour cette source.',
              style: WinType.bodyM(s.onMuted)));
    }
    return WinCard(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: [
        for (int i = 0; i < _entries.length; i++) _entryRow(s, _entries[i], i < _entries.length - 1),
        if (_entries.length < _entriesTotal)
          Padding(
            padding: const EdgeInsets.all(8),
            child: WinButton(
                _entriesLoading ? 'Chargement…' : 'Voir plus (${_entriesTotal - _entries.length})',
                variant: WinButtonVariant.ghost,
                small: true,
                loading: _entriesLoading,
                onTap: _entriesLoading ? null : () => _loadEntries()),
          ),
        if (_entriesError != null && _entries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_entriesError!, style: WinType.labelM(WinColors.error)),
          ),
      ]),
    );
  }

  Widget _entryRow(WinScheme s, WalletEntry e, bool divider) {
    final credit = e.amountXaf > 0;
    final statusLabel = switch (e.status) {
      'pending' => ' · en attente',
      'reversed' => ' · annulée',
      _ => '',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: s.outline)) : null),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: credit ? WinColors.successBg : s.surface2, shape: BoxShape.circle),
            child: Icon(credit ? Icons.trending_up : Icons.account_balance_wallet_outlined,
                size: 16, color: credit ? WinColors.success : s.onMuted)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: WinType.bodyM(s.onStrong).copyWith(fontWeight: FontWeight.w600)),
          Text('${_date(e.date)}$statusLabel', style: WinType.labelM(s.onMuted)),
        ])),
        Text(e.amountXaf == 0 ? 'Versé' : '${credit ? '+' : ''}${_xaf(e.amountXaf)}',
            style: WinType.archivo(size: 15, color: credit ? WinColors.success : s.onStrong)),
      ]),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title, message, actionLabel;
  final VoidCallback onAction;
  const _StateMessage(
      {required this.icon,
      required this.title,
      required this.message,
      required this.actionLabel,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: s.onMuted),
          const SizedBox(height: 12),
          Text(title, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 6),
          Text(message, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          WinButton(actionLabel, variant: WinButtonVariant.primary, onTap: onAction),
        ]),
      ),
    );
  }
}

class _WithdrawalStatusCard extends StatelessWidget {
  final WalletWithdrawal withdrawal;
  final VoidCallback? onDismiss;
  const _WithdrawalStatusCard({required this.withdrawal, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final w = withdrawal;
    final (title, color, icon) = w.isCompleted
        ? ('Retrait effectué', WinColors.success, Icons.check_circle)
        : w.isFailed
            ? ('Retrait non abouti', WinColors.error, Icons.error_outline)
            : ('Transfert en cours…', WinColors.warn, Icons.hourglass_top);
    final detail = w.isCompleted
        ? '${_xaf(w.amountXaf)} envoyés vers ${w.operatorLabel} ${w.phoneMasked}${w.processedAt != null ? ' le ${_date(w.processedAt)}' : ''}.'
        : w.isFailed
            ? '${w.failureReason ?? 'Le transfert a échoué.'} Les ${_xaf(w.amountXaf)} ont été remis sur ton solde.'
            : '${_xaf(w.amountXaf)} vers ${w.operatorLabel} ${w.phoneMasked}. L\'opération se poursuit même si tu quittes l\'application ; tu seras notifié de son issue.';
    return WinCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: WinType.titleS(s.onStrong)),
          const SizedBox(height: 4),
          Text(detail, style: WinType.bodyS(s.onMuted)),
        ])),
        if (onDismiss != null)
          IconButton(
              tooltip: 'Fermer', icon: const Icon(Icons.close, size: 18), onPressed: onDismiss),
      ]),
    );
  }
}

// ── Formulaire de retrait ─────────────────────────────────────────────────

class _WithdrawSheet extends StatefulWidget {
  final WalletSummary summary;
  const _WithdrawSheet({required this.summary});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _phone = TextEditingController();
  final _phoneConfirm = TextEditingController();
  final _amount = TextEditingController();
  String _operator = 'mtn';
  bool _recap = false;
  bool _submitting = false;
  String? _error;
  int? _available;
  // Un identifiant par soumission : renvoyer après une coupure réseau
  // réutilise le même, le serveur ne crée alors qu'une seule demande.
  String? _requestId;

  @override
  void initState() {
    super.initState();
    _available = widget.summary.availableXaf;
  }

  @override
  void dispose() {
    _phone.dispose();
    _phoneConfirm.dispose();
    _amount.dispose();
    super.dispose();
  }

  String _digits(String v) => v.replaceAll(RegExp(r'\D'), '');

  void _toRecap() {
    final phone = _digits(_phone.text);
    final amount = int.tryParse(_amount.text) ?? 0;
    String? err;
    if (!(phone.length == 9 || (phone.length == 12 && phone.startsWith('237')))) {
      err = 'Numéro Mobile Money invalide : 9 chiffres (ex. 6XXXXXXXX).';
    } else if (phone != _digits(_phoneConfirm.text)) {
      err = 'Les deux numéros saisis ne correspondent pas.';
    } else if (amount < widget.summary.minWithdrawalXaf) {
      err = 'Le montant minimum de retrait est de ${_xaf(widget.summary.minWithdrawalXaf)}.';
    } else if (_available != null && amount > _available!) {
      err = 'Solde insuffisant : ${_xaf(_available!)} disponibles.';
    }
    setState(() {
      _error = err;
      if (err == null) {
        _recap = true;
        _requestId ??= newClientRequestId();
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final w = await WalletService.instance.requestWithdrawal(
        operator: _operator,
        phone: _phone.text,
        amountXaf: int.parse(_amount.text),
        clientRequestId: _requestId ?? newClientRequestId(),
      );
      if (mounted) Navigator.of(context).pop(w);
    } on WalletApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
        if (e.insufficientBalance && e.availableXaf != null) {
          // Solde changé entre l'affichage et la validation : nouveau solde affiché.
          _available = e.availableXaf!.round();
          _recap = false;
        }
        // Erreur de règle : nouvelle saisie, nouvel identifiant. Erreur réseau :
        // même identifiant, renvoyer ne crée pas de doublon.
        if (!e.offline) _requestId = null;
        if (e.statusCode != null && e.statusCode! < 500) _recap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final amount = int.tryParse(_amount.text) ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(_recap ? 'Confirmer le retrait' : 'Retirer des fonds',
              style: WinType.archivo(size: 20, color: s.onStrong)),
          const SizedBox(height: 6),
          if (!_recap) ...[
            Text(
                'Minimum ${_xaf(widget.summary.minWithdrawalXaf)}, aucun frais, pas de plafond. Disponible : ${_xaf(_available ?? 0)}.',
                style: WinType.bodyS(s.onMuted)),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mtn', label: Text('MTN MoMo')),
                ButtonSegment(value: 'orange', label: Text('Orange Money')),
              ],
              selected: {_operator},
              onSelectionChanged: (v) => setState(() => _operator = v.first),
            ),
            const SizedBox(height: 12),
            WinTextField(label: 'Numéro Mobile Money', hint: '6XXXXXXXX', controller: _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            WinTextField(label: 'Confirme le numéro', hint: '6XXXXXXXX', controller: _phoneConfirm, keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Montant (FCFA)', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            if ((_available ?? 0) > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _amount.text = '${_available!}'),
                  child: Text('Tout retirer (${_xaf(_available!)})'),
                ),
              ),
          ] else ...[
            const SizedBox(height: 8),
            _recapRow(s, 'Montant reçu', _xaf(amount), strong: true),
            _recapRow(s, 'Frais', 'Aucun'),
            _recapRow(s, 'Opérateur', _operator == 'orange' ? 'Orange Money' : 'MTN MoMo'),
            _recapRow(s, 'Numéro', _phone.text),
            const SizedBox(height: 8),
            Text('Le montant est réservé sur ton solde dès la validation, puis envoyé automatiquement.',
                style: WinType.bodyS(s.onMuted)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: WinType.bodyS(WinColors.error)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: WinButton(_recap ? 'Modifier' : 'Annuler',
                    variant: WinButtonVariant.outline,
                    block: true,
                    onTap: _submitting
                        ? null
                        : () => _recap ? setState(() => _recap = false) : Navigator.of(context).pop())),
            const SizedBox(width: 10),
            Expanded(
                child: WinButton(_recap ? 'Retirer ${_xaf(amount)}' : 'Continuer',
                    variant: WinButtonVariant.primary,
                    block: true,
                    loading: _submitting,
                    onTap: _submitting ? null : (_recap ? _submit : _toRecap))),
          ]),
        ]),
      ),
    );
  }

  Widget _recapRow(WinScheme s, String label, String value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: WinType.bodyM(s.onMuted))),
          Text(value, style: strong ? WinType.titleM(s.onStrong) : WinType.bodyM(s.onStrong)),
        ]),
      );
}

// ── Recharge ──────────────────────────────────────────────────────────────

class _RechargeSheet extends StatefulWidget {
  final int minXaf;
  const _RechargeSheet({required this.minXaf});

  @override
  State<_RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends State<_RechargeSheet> {
  static const _maxPolls = 75; // 5 minutes à 4 s
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  String _operator = 'mtn';
  bool _submitting = false;
  bool _waiting = false;
  bool? _success;
  String? _error;
  final String _requestId = newClientRequestId();
  Timer? _poll;

  @override
  void dispose() {
    _poll?.cancel();
    _phone.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amount.text) ?? 0;
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (amount < widget.minXaf) {
      setState(() => _error = 'Le montant minimum de recharge est de ${_xaf(widget.minXaf)}.');
      return;
    }
    if (phone.length < 9) {
      setState(() => _error = 'Numéro Mobile Money invalide : 9 chiffres (ex. 6XXXXXXXX).');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final start = await WalletService.instance.startRecharge(
          operator: _operator, phone: _phone.text, amountXaf: amount, clientRequestId: _requestId);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _waiting = true;
      });
      var count = 0;
      _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
        count++;
        try {
          final (status, message) = await WalletService.instance.getPaymentStatus(start.paymentId);
          if (!mounted) return;
          if (status == 'completed') {
            _poll?.cancel();
            setState(() {
              _waiting = false;
              _success = true;
            });
          } else if (status == 'failed' || status == 'expired' || status == 'cancelled') {
            _poll?.cancel();
            setState(() {
              _waiting = false;
              _success = false;
              _error = message ?? 'Paiement refusé ou expiré. Aucun montant n\'a été crédité.';
            });
          }
        } catch (_) {/* réseau : nouvel essai */}
        if (count >= _maxPolls && _waiting && mounted) {
          _poll?.cancel();
          setState(() {
            _waiting = false;
            _success = false;
            _error = 'Délai dépassé. Si tu as confirmé sur ton téléphone, le montant apparaîtra dès confirmation.';
          });
        }
      });
    } on WalletApiException catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (_waiting || _success != null) {
      final ok = _success == true;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_waiting) const CircularProgressIndicator() else Icon(ok ? Icons.check_circle : Icons.error_outline, size: 40, color: ok ? WinColors.success : WinColors.error),
          const SizedBox(height: 12),
          Text(_waiting ? 'Confirme le paiement sur ton téléphone…' : ok ? 'Recharge confirmée' : 'Recharge non aboutie',
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(_waiting || ok ? '${_xaf(int.tryParse(_amount.text) ?? 0)} via ${_operator == 'orange' ? 'Orange Money' : 'MTN MoMo'}' : (_error ?? ''),
              style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          WinButton(_waiting ? 'Fermer' : 'Terminé',
              variant: WinButtonVariant.primary, block: true, onTap: () => Navigator.of(context).pop(ok)),
        ]),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('Recharger mon portefeuille', style: WinType.archivo(size: 20, color: s.onStrong)),
          const SizedBox(height: 6),
          Text('Le montant est crédité dès la confirmation du paiement Mobile Money. Minimum ${_xaf(widget.minXaf)}.',
              style: WinType.bodyS(s.onMuted)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'mtn', label: Text('MTN MoMo')),
              ButtonSegment(value: 'orange', label: Text('Orange Money')),
            ],
            selected: {_operator},
            onSelectionChanged: (v) => setState(() => _operator = v.first),
          ),
          const SizedBox(height: 12),
          WinTextField(label: 'Numéro Mobile Money', hint: '6XXXXXXXX', controller: _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 10),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Montant (FCFA)', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: WinType.bodyS(WinColors.error)),
          ],
          const SizedBox(height: 16),
          WinButton('Recharger', variant: WinButtonVariant.primary, block: true, loading: _submitting, onTap: _submitting ? null : _submit),
        ]),
      ),
    );
  }
}
