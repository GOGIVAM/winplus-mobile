import 'package:flutter/material.dart';

import '../../services/tutor_booking_service.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Lot 9.3 (suivi 17.4) : « Pour qui ? » dans la réservation mobile. Le
/// parent choisit ses enfants liés, l'institution ses élèves (par classe),
/// l'élève lui-même ou des membres de son groupe d'étude. Le serveur revérifie
/// chaque lien : cette liste ne propose que ce que le compte peut choisir.
class ForWhomValue {
  final String payerType; // student | parent | institution | study_group
  final List<int> participantIds;
  final int? studyGroupId;
  const ForWhomValue({this.payerType = 'student', this.participantIds = const [], this.studyGroupId});

  /// Nombre d'élèves de la séance (l'élève seul = 1).
  int get count => payerType == 'student' ? 1 : participantIds.length;

  bool isValid(int maxGroupSize) =>
      payerType == 'student' ||
      (participantIds.isNotEmpty && (participantIds.length == 1 || participantIds.length <= maxGroupSize));

  ForWhomValue copyWith({String? payerType, List<int>? participantIds, int? studyGroupId, bool clearGroup = false}) =>
      ForWhomValue(
        payerType: payerType ?? this.payerType,
        participantIds: participantIds ?? this.participantIds,
        studyGroupId: clearGroup ? null : (studyGroupId ?? this.studyGroupId),
      );

  /// Choix initial selon le rôle (et les bénéficiaires d'une attribution).
  static ForWhomValue initial(TutorBookingContext? ctx, {List<int>? preset}) {
    if (ctx?.isParent == true) {
      return ForWhomValue(
        payerType: 'parent',
        participantIds: (preset != null && preset.isNotEmpty)
            ? preset
            : (ctx!.children.length == 1 ? [ctx.children.first.userId] : const []),
      );
    }
    if (ctx?.isInstitution == true) {
      return ForWhomValue(payerType: 'institution', participantIds: preset ?? const []);
    }
    return const ForWhomValue();
  }
}

class TutorBookingForWhom extends StatefulWidget {
  final TutorBookingContext context;
  final ForWhomValue value;
  final ValueChanged<ForWhomValue> onChanged;
  final int? currentUserId;
  final int maxGroupSize;

  const TutorBookingForWhom({
    super.key,
    required this.context,
    required this.value,
    required this.onChanged,
    required this.maxGroupSize,
    this.currentUserId,
  });

  /// Rien à choisir : élève sans groupe d'étude.
  static bool hasChoice(TutorBookingContext ctx) =>
      ctx.allowedPayerTypes.any((t) => t != 'student') || ctx.studyGroups.isNotEmpty;

  @override
  State<TutorBookingForWhom> createState() => _TutorBookingForWhomState();
}

class _TutorBookingForWhomState extends State<TutorBookingForWhom> {
  String _className = '';
  String _search = '';

  void _toggle(int id) {
    final ids = [...widget.value.participantIds];
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    widget.onChanged(widget.value.copyWith(participantIds: ids));
  }

  Widget _chip(int id, String label) =>
      WinChip(label, active: widget.value.participantIds.contains(id), onTap: () => _toggle(id));

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final ctx = widget.context;
    final v = widget.value;
    final count = v.count;
    final warning = count > 1 && widget.maxGroupSize < 2
        ? 'Ce tuteur ne propose pas de séances de groupe : choisis un seul élève.'
        : (count > widget.maxGroupSize && widget.maxGroupSize >= 2)
            ? 'Ce tuteur accepte au plus ${widget.maxGroupSize} élèves par séance.'
            : null;

    final children = <Widget>[
      Text('Pour qui ?', style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 8),
    ];

    if (v.payerType == 'parent') {
      if (ctx.children.isEmpty) {
        children.add(Text('Aucun enfant lié à ton compte (le lien doit être accepté par l\'enfant).',
            style: WinType.bodyS(s.onMuted)));
      } else {
        children.addAll([
          Wrap(spacing: 8, runSpacing: 8, children: ctx.children.map((c) => _chip(c.userId, c.label)).toList()),
          const SizedBox(height: 4),
          Text('Tu paies avec ton portefeuille parent ou Mobile Money ; tes enfants voient la séance dans leur espace.',
              style: WinType.labelS(s.onFaint)),
        ]);
      }
    } else if (v.payerType == 'institution') {
      final classes = ctx.institutionStudents.map((e) => e.groupName).whereType<String>().toSet().toList()..sort();
      final visible = ctx.institutionStudents
          .where((e) =>
              (_className.isEmpty || e.groupName == _className) &&
              (_search.isEmpty || e.label.toLowerCase().contains(_search.toLowerCase())))
          .take(60)
          .toList();
      if (classes.isNotEmpty) {
        children.add(Wrap(spacing: 8, runSpacing: 8, children: [
          WinChip('Toutes les classes', active: _className.isEmpty, onTap: () => setState(() => _className = '')),
          ...classes.map((c) => WinChip(c, active: _className == c, onTap: () => setState(() => _className = c))),
        ]));
        children.add(const SizedBox(height: 8));
      }
      children.addAll([
        TextField(
          decoration: const InputDecoration(hintText: 'Rechercher un élève', isDense: true, prefixIcon: Icon(Icons.search)),
          onChanged: (t) => setState(() => _search = t.trim()),
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          Text('Aucun élève actif rattaché à ${ctx.institutionName ?? 'ton institution'}.', style: WinType.bodyS(s.onMuted))
        else
          Wrap(spacing: 8, runSpacing: 8, children: visible.map((e) => _chip(e.userId, e.label)).toList()),
        const SizedBox(height: 4),
        Text('${v.participantIds.length} élève(s) choisi(s). Payé par le portefeuille de l\'institution ou Mobile Money.',
            style: WinType.labelS(s.onFaint)),
      ]);
    } else {
      final group = ctx.studyGroups.where((g) => g.id == v.studyGroupId).firstOrNull;
      children.addAll([
        Wrap(spacing: 8, runSpacing: 8, children: [
          WinChip('Pour moi',
              active: v.payerType == 'student',
              onTap: () => widget.onChanged(const ForWhomValue())),
          ...ctx.studyGroups.map((g) => WinChip('Groupe : ${g.name}',
              active: v.studyGroupId == g.id,
              onTap: () => widget.onChanged(ForWhomValue(
                    payerType: 'study_group',
                    studyGroupId: g.id,
                    participantIds: g.members.map((m) => m.userId).where((id) => id == widget.currentUserId).toList(),
                  )))),
        ]),
        if (group != null) ...[
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.members
                  .map((m) => _chip(m.userId, m.userId == widget.currentUserId ? 'Moi' : m.label))
                  .toList()),
          const SizedBox(height: 4),
          Text('C\'est toi qui paies la séance du groupe (ton solde ou Mobile Money) et qui reçois un éventuel remboursement.',
              style: WinType.labelS(s.onFaint)),
        ],
      ]);
    }

    if (warning != null) {
      children.addAll([const SizedBox(height: 8), WinAlert(warning, type: BadgeColor.warn)]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
