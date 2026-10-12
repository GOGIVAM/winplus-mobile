import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/tutor_booking_service.dart';
import '../services/tutor_profile_service.dart';
import '../student/tutors/my_tutor_bookings_screen.dart';
import '../student/tutors/tutor_pricing_widgets.dart';
import '../student/tutors/tutor_public_profile_screen.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Lot 9.3 (suivi 17.4) : cours particuliers réservés et payés par un parent
/// pour ses enfants, ou par une institution pour ses élèves (parité web
/// /tutorat) :
///   - attributions d'un tuteur (création, suivi, fin), réservation en un clic
///     depuis une attribution active ;
///   - portefeuille institution : solde, recharge Mobile Money, historique
///     (jamais retirable).
/// Tous les liens sont revérifiés par le serveur.
class TutoringForStudentsScreen extends StatefulWidget {
  const TutoringForStudentsScreen({super.key});

  @override
  State<TutoringForStudentsScreen> createState() => _TutoringForStudentsScreenState();
}

class _TutoringForStudentsScreenState extends State<TutoringForStudentsScreen> with WidgetsBindingObserver {
  TutorBookingContext? _ctx;
  List<TutorAssignment> _assignments = [];
  bool _loading = true;
  bool _error = false;

  // Portefeuille institution (registre du lot 2, GET /wallet/me).
  num? _walletAvailable;
  num _minRecharge = 100;
  List<Map<String, dynamic>> _entries = [];

  // Suivi 17.14 : recharge en attente de confirmation Mobile Money. Le solde
  // est relu au retour dans l'application et par une interrogation légère du
  // paiement (toutes les 5 s, 3 min au plus) jusqu'à son issue.
  int? _pendingRechargePaymentId;
  Timer? _rechargePoll;
  DateTime? _rechargeStartedAt;
  static const _rechargePollEvery = Duration(seconds: 5);
  static const _rechargePollFor = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rechargePoll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retour après avoir validé le paiement sur le téléphone (USSD / appli opérateur).
    if (state == AppLifecycleState.resumed && _pendingRechargePaymentId != null) {
      _checkRecharge();
    }
  }

  void _startRechargePolling(int paymentId) {
    _rechargePoll?.cancel();
    _pendingRechargePaymentId = paymentId;
    _rechargeStartedAt = DateTime.now();
    _rechargePoll = Timer.periodic(_rechargePollEvery, (_) => _checkRecharge());
  }

  void _stopRechargePolling() {
    _rechargePoll?.cancel();
    _rechargePoll = null;
    _pendingRechargePaymentId = null;
  }

  Future<void> _checkRecharge() async {
    final id = _pendingRechargePaymentId;
    if (id == null || !mounted) return;
    String? status;
    try {
      final res = _unwrap((await ApiClient.instance.dio.get('/payments/$id/status')).data);
      status = res?['status']?.toString().toLowerCase();
    } catch (_) {
      // Réseau : on retente au prochain tour.
    }
    final expired = _rechargeStartedAt != null && DateTime.now().difference(_rechargeStartedAt!) > _rechargePollFor;
    if (status == 'completed' || status == 'failed' || status == 'expired' || status == 'cancelled' || expired) {
      _stopRechargePolling();
      await _loadWallet();
      if (!mounted) return;
      final msg = status == 'completed'
          ? 'Recharge confirmée : le solde de l\'institution est à jour.'
          : status == null || expired
              ? 'Recharge toujours en attente : tire vers le bas pour actualiser le solde plus tard.'
              : 'La recharge n\'a pas abouti : aucun montant n\'a été débité.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      await _loadWallet();
    }
  }

  Map<String, dynamic>? _unwrap(dynamic data) {
    if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data'] as Map);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final ctx = await TutorBookingService.instance.getBookingContext();
      final list = await TutorBookingService.instance.getMyAssignments();
      if (!mounted) return;
      setState(() {
        _ctx = ctx;
        _assignments = list;
      });
      if (ctx.isInstitution) await _loadWallet();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadWallet() async {
    try {
      final dio = ApiClient.instance.dio;
      final me = _unwrap((await dio.get('/wallet/me')).data);
      final page = _unwrap((await dio.get('/wallet/me/entries', queryParameters: {'source': 'all', 'page': 1, 'pageSize': 10})).data);
      if (!mounted) return;
      setState(() {
        _walletAvailable = me?['availableXaf'] as num?;
        _minRecharge = (me?['minRechargeXaf'] as num?) ?? 100;
        _entries = ((page?['items'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _walletAvailable = null);
    }
  }

  Future<void> _recharge() async {
    final amountCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String op = 'mtn';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Recharger le portefeuille'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              ChoiceChip(label: const Text('MTN MoMo'), selected: op == 'mtn', onSelected: (_) => setD(() => op = 'mtn')),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('Orange Money'), selected: op == 'orange', onSelected: (_) => setD(() => op = 'orange')),
            ]),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro (6XXXXXXXX)')),
            TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Montant (minimum ${fmtXaf(_minRecharge)} FCFA)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recharger')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiClient.instance.dio.post('/wallet/recharge', data: {
        'amount': num.tryParse(amountCtrl.text.trim()) ?? 0,
        'operator': op,
        'phone': phoneCtrl.text.trim(),
        'clientRequestId': '${DateTime.now().microsecondsSinceEpoch}',
      });
      final started = _unwrap(res.data);
      final paymentId = (started?['paymentId'] as num?)?.toInt();
      if (paymentId != null && paymentId > 0) _startRechargePolling(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Confirme le paiement sur ton téléphone ; le solde s\'actualise dès la confirmation.')));
      }
    } catch (e) {
      final data = (e as dynamic).response?.data;
      final msg = data is Map ? (data['error'] ?? data['message'])?.toString() : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'La recharge n\'a pas pu être lancée.')));
      }
    }
  }

  Future<void> _end(TutorAssignment a) async {
    try {
      final updated = await TutorBookingService.instance.respondAssignment(a.id, action: 'end');
      if (mounted) setState(() => _assignments = _assignments.map((x) => x.id == a.id ? updated : x).toList());
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible.')));
    }
  }

  Future<void> _create() async {
    final ctx = _ctx;
    if (ctx == null) return;
    final created = await Navigator.push<TutorAssignment>(
        context, MaterialPageRoute(builder: (_) => _AssignTutorScreen(context: ctx)));
    if (created != null && mounted) setState(() => _assignments = [created, ..._assignments]);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final ctx = _ctx;
    final isInstitution = ctx?.isInstitution == true;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        title: Text(isInstitution ? 'Tutorat de mes élèves' : 'Cours particuliers', style: WinType.headlineS(s.onStrong)),
        actions: [IconButton(icon: Icon(Icons.refresh_outlined, color: s.onMuted), onPressed: _load)],
      ),
      floatingActionButton: ctx != null && (ctx.isParent || ctx.isInstitution)
          ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Attribuer un tuteur'))
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(child: WinButton('Réessayer', onTap: _load))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
                    WinButton('Séances réservées',
                        block: true,
                        variant: WinButtonVariant.outline,
                        icon: Icons.event_available_outlined,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTutorBookingsScreen()))),
                    if (isInstitution) ...[
                      const SizedBox(height: 16),
                      WinCard(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Portefeuille de l\'institution', style: WinType.labelM(s.onStrong)),
                          const SizedBox(height: 6),
                          Text(_walletAvailable != null ? '${fmtXaf(_walletAvailable!)} XAF' : 'Solde indisponible',
                              style: WinType.archivo(size: 22, color: s.onStrong)),
                          const SizedBox(height: 4),
                          Text('Partagé par tous les comptes de l\'institution : il se recharge par Mobile Money, paie les séances et reçoit les remboursements. Il ne se retire pas vers Mobile Money.',
                              style: WinType.labelS(s.onFaint)),
                          const SizedBox(height: 10),
                          if (_pendingRechargePaymentId != null) ...[
                            Row(children: [
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Recharge en attente de confirmation sur le téléphone…', style: WinType.labelS(s.onMuted))),
                            ]),
                            const SizedBox(height: 8),
                          ],
                          WinButton('Recharger', small: true, onTap: _pendingRechargePaymentId != null ? null : _recharge),
                          if (_entries.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const WinDivider(),
                            ..._entries.map((e) {
                              final amount = (e['amountXaf'] as num?) ?? 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(children: [
                                  Expanded(child: Text(e['label']?.toString() ?? '', style: WinType.bodyS(s.onSurface))),
                                  Text('${amount >= 0 ? '+' : ''}${fmtXaf(amount)} XAF', style: WinType.labelM(s.onStrong)),
                                ]),
                              );
                            }),
                          ],
                        ]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('Répétiteurs attribués', style: WinType.labelM(s.onStrong)),
                    const SizedBox(height: 8),
                    if (_assignments.isEmpty)
                      WinCard(child: Text('Aucune attribution pour l\'instant.', style: WinType.bodyS(s.onMuted)))
                    else
                      ..._assignments.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: WinCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  WinAvatar(a.tutorName ?? '?', size: 36),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(a.tutorName ?? 'Répétiteur', style: WinType.titleM(s.onStrong))),
                                  WinBadge(a.statusLabel, color: a.isActive ? BadgeColor.success : a.isPending ? BadgeColor.warn : BadgeColor.neutral),
                                ]),
                                const SizedBox(height: 6),
                                Text(
                                    '${a.groupName != null ? 'Classe ${a.groupName} · ' : ''}${a.beneficiaries.length} élève(s) : '
                                    '${a.beneficiaries.take(8).map((b) => b.label).join(', ')}${a.beneficiaries.length > 8 ? '…' : ''}'
                                    '${a.subject != null ? ' · ${a.subject}' : ''}',
                                    style: WinType.labelM(s.onMuted)),
                                if (a.responseNote != null) Text('Réponse : « ${a.responseNote} »', style: WinType.labelS(s.onFaint)),
                                if (a.isActive || a.isPending) ...[
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    if (a.isActive) ...[
                                      Expanded(
                                        child: WinButton('Réserver',
                                            small: true,
                                            onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => TutorPublicProfileScreen(userId: a.tutorUserId, assignment: a)))),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                        child: WinButton('Mettre fin',
                                            small: true, variant: WinButtonVariant.outline, onTap: () => _end(a))),
                                  ]),
                                ],
                              ]),
                            ),
                          )),
                  ]),
                ),
    );
  }
}

/// Création d'une attribution : tuteur (recherche par matière), bénéficiaires
/// (enfants liés ou élèves / classe de l'institution), matière et note.
class _AssignTutorScreen extends StatefulWidget {
  final TutorBookingContext context;
  const _AssignTutorScreen({required this.context});

  @override
  State<_AssignTutorScreen> createState() => _AssignTutorScreenState();
}

class _AssignTutorScreenState extends State<_AssignTutorScreen> {
  final _subjectCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<TutorSearchResult> _results = [];
  bool _searching = false;
  TutorSearchResult? _tutor;
  final Set<int> _students = {};
  String _className = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    try {
      final r = await TutorProfileService.instance.search(
          subject: _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(), pageSize: 10);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submit() async {
    final ctx = widget.context;
    if (_tutor == null) return setState(() => _error = 'Choisis un répétiteur.');
    if (_students.isEmpty && _className.isEmpty) {
      return setState(() => _error = ctx.isInstitution ? 'Choisis des élèves ou une classe.' : 'Choisis au moins un enfant.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await TutorBookingService.instance.createAssignment(
        tutorUserId: _tutor!.userId,
        studentUserIds: _students.toList(),
        groupName: _className.isEmpty ? null : _className,
        subject: _subjectCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      final data = (e as dynamic).response?.data;
      if (mounted) {
        setState(() {
          _saving = false;
          _error = data is Map && data['message'] is String ? data['message'] as String : 'Attribution impossible.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final ctx = widget.context;
    final pool = ctx.isInstitution ? ctx.institutionStudents : ctx.children;
    final classes = ctx.institutionStudents.map((e) => e.groupName).whereType<String>().toSet().toList()..sort();
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(backgroundColor: s.bg, elevation: 0, title: Text('Attribuer un tuteur', style: WinType.headlineS(s.onStrong))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Le répétiteur reçoit la demande et l\'accepte ou la refuse. L\'attribution ne réserve rien : elle le met en avant et présélectionne les élèves pour réserver en un clic.',
            style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: WinTextField(hint: 'Matière (ex. Mathématiques)', controller: _subjectCtrl)),
          IconButton(icon: const Icon(Icons.search), onPressed: _searching ? null : _search),
        ]),
        const SizedBox(height: 8),
        if (_searching)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else if (_results.isEmpty)
          Text('Aucun répétiteur trouvé.', style: WinType.bodyS(s.onMuted))
        else
          ..._results.map((t) => ListTile(
                onTap: () => setState(() => _tutor = t),
                leading: Icon(_tutor?.userId == t.userId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _tutor?.userId == t.userId ? s.primary : s.onFaint),
                title: Text(t.fullName),
                subtitle: Text(t.subjects.take(3).join(', ')),
                contentPadding: EdgeInsets.zero,
              )),
        const SizedBox(height: 12),
        Text(ctx.isInstitution ? 'Élèves bénéficiaires' : 'Enfants bénéficiaires', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        if (ctx.isInstitution && classes.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            WinChip('Pas de classe entière', active: _className.isEmpty, onTap: () => setState(() => _className = '')),
            ...classes.map((c) => WinChip('Toute la classe $c', active: _className == c, onTap: () => setState(() => _className = c))),
          ]),
          const SizedBox(height: 8),
        ],
        if (ctx.isInstitution && ctx.institutionPendingConfirmationCount > 0) ...[
          Text(
              '${ctx.institutionPendingConfirmationCount} élève(s) rattaché(s) n\'ont pas encore confirmé leur rattachement : '
              'ils n\'apparaissent pas ici tant qu\'ils ne l\'ont pas accepté depuis leur compte.',
              style: WinType.labelS(s.onFaint)),
          const SizedBox(height: 8),
        ],
        if (pool.isEmpty)
          Text(ctx.isInstitution ? 'Aucun élève actif au rattachement confirmé dans ton institution.' : 'Aucun enfant lié (le lien doit être accepté par l\'enfant).',
              style: WinType.bodyS(s.onMuted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pool
                .where((p) => _className.isEmpty || p.groupName != _className)
                .take(80)
                .map((p) => WinChip(p.label,
                    active: _students.contains(p.userId),
                    onTap: () => setState(() => _students.contains(p.userId) ? _students.remove(p.userId) : _students.add(p.userId))))
                .toList(),
          ),
        const SizedBox(height: 12),
        WinTextField(hint: 'Un mot pour le répétiteur (objectifs, fréquence…)', controller: _noteCtrl),
        if (_error != null) ...[const SizedBox(height: 10), WinAlert(_error!, type: BadgeColor.error)],
        const SizedBox(height: 16),
        WinButton('Envoyer l\'attribution', block: true, loading: _saving, onTap: _saving ? null : _submit),
      ]),
    );
  }
}
