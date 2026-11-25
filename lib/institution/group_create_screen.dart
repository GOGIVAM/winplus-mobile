import 'package:flutter/material.dart';
import '../services/institution_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});
  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameCtrl = TextEditingController();
  String? _level;
  bool _loading = false, _done = false;

  static const _levels = [
    'BEPC',
    'Probatoire',
    'BAC',
    'BTS',
    'Licence',
    'Concours'
  ];

  // Élèves réels de l'établissement (annuaire du serveur). Avant : douze
  // noms inventés, jamais envoyés au serveur, alors que la confirmation
  // annonçait « N élèves ajoutés ».
  List<ApiInstitutionStudent>? _students;
  bool _studentsError = false;
  String _query = '';
  int _added = 0;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _students = null;
      _studentsError = false;
    });
    try {
      final id = await InstitutionService.instance.getMyInstitutionId();
      if (id == null) throw StateError('etablissement introuvable');
      final list = await InstitutionService.instance
          .getStudentDirectory(id, pageSize: 200);
      if (mounted) setState(() => _students = list);
    } catch (_) {
      if (mounted) {
        setState(() {
          _students = const [];
          _studentsError = true;
        });
      }
    }
  }

  List<ApiInstitutionStudent> get _visible {
    final q = _query.trim().toLowerCase();
    final all = _students ?? const <ApiInstitutionStudent>[];
    if (q.isEmpty) return all;
    return all
        .where((st) => '${st.firstName} ${st.lastName} ${st.email}'
            .toLowerCase()
            .contains(q))
        .toList();
  }

  String _levelLabel(String lv) => switch (lv) {
        'Licence' => context.l10n.instGroupLevelLicence,
        'Concours' => context.l10n.authOptConcours,
        _ => lv,
      };

  final _selected = <int>{};

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _level == null) return;
    setState(() => _loading = true);
    final groupId = await InstitutionService.instance.createGroupWithId(
      name: _nameCtrl.text.trim(),
      level: _level!,
    );
    if (!mounted) return;
    if (groupId != null) {
      // Les élèves choisis sont réellement ajoutés, un par un ; la
      // confirmation annonce le nombre ajouté, pas le nombre coché.
      var added = 0;
      if (groupId > 0) {
        for (final st in (_students ?? const <ApiInstitutionStudent>[])
            .where((st) => _selected.contains(st.id))) {
          if (await InstitutionService.instance
              .addMemberToGroup(groupId, st.email)) {
            added++;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _added = added;
        _loading = false;
        _done = true;
      });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L10n.current.instGroupCreateError)));
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
        title: Text(context.l10n.studentGroupsCreate),
      ),
      body: _done
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.group_add, size: 64, color: WinColors.success),
                const SizedBox(height: 16),
                Text(context.l10n.instGroupCreated, style: WinType.displayS(s.onStrong)),
                const SizedBox(height: 8),
                Text(
                  context.l10n.instGroupCreatedSummary(_nameCtrl.text.trim(), _added),
                  style: WinType.bodyM(s.onMuted),
                  textAlign: TextAlign.center,
                ),
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
                      label: context.l10n.instGroupNameLabel,
                      hint: 'TLE C 2027, BTS Info 2…',
                      icon: Icons.group_outlined,
                      controller: _nameCtrl,
                    ),
                    const SizedBox(height: 20),
                    Text(context.l10n.instGroupLevelLabel, style: WinType.titleM(s.onStrong)),
                    const SizedBox(height: 8),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _levels.map((lv) {
                          final active = _level == lv;
                          return GestureDetector(
                            onTap: () => setState(() => _level = lv),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? WinColors.ink800 : s.surface,
                                borderRadius:
                                    BorderRadius.circular(WinRadii.full),
                                border: Border.all(
                                    color:
                                        active ? WinColors.ink800 : s.outline,
                                    width: 1.5),
                              ),
                              child: Text(_levelLabel(lv),
                                  style: WinType.manrope(
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: active
                                          ? WinColors.cream50
                                          : s.onSurface)),
                            ),
                          );
                        }).toList()),
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(
                        child: Text(context.l10n.instGroupAddStudents,
                            style: WinType.headlineS(s.onStrong)),
                      ),
                      const SizedBox(width: 8),
                      Text(context.l10n.instGroupSelected(_selected.length),
                          style: WinType.labelM(s.primary)),
                    ]),
                    const SizedBox(height: 8),
                    WinTextField(
                      hint: context.l10n.instGroupSearchStudent,
                      icon: Icons.search,
                      onChanged: (v) => setState(() => _query = v),
                    ),
                    const SizedBox(height: 12),
                    if (_students == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_studentsError)
                      Row(children: [
                        Expanded(
                          child: Text(context.l10n.instGroupStudentsLoadError,
                              style: WinType.bodyM(s.onMuted)),
                        ),
                        TextButton(
                            onPressed: _loadStudents,
                            child: Text(context.l10n.commonRetry)),
                      ])
                    else if (_students!.isEmpty)
                      Text(context.l10n.instGroupNoStudents,
                          style: WinType.bodyM(s.onMuted))
                    else
                      ..._visible.map((st) {
                        final name = '${st.firstName} ${st.lastName}'.trim();
                        final sel = _selected.contains(st.id);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              _selected.remove(st.id);
                            } else {
                              _selected.add(st.id);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: sel ? s.primaryContainer : s.cardBg,
                              borderRadius: BorderRadius.circular(WinRadii.md),
                              border: Border.all(
                                color: sel ? s.primary : s.cardBorder,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              WinAvatar(name.isEmpty ? st.email : name, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name.isEmpty ? st.email : name,
                                          style: WinType.titleM(s.onStrong)),
                                      if (st.level != null && st.level!.isNotEmpty)
                                        Text(st.level!,
                                            style: WinType.bodyS(s.onMuted)),
                                    ]),
                              ),
                              if (sel)
                                Icon(Icons.check_circle,
                                    size: 20, color: s.primary)
                              else
                                Icon(Icons.radio_button_unchecked,
                                    size: 20, color: s.onFaint),
                            ]),
                          ),
                        );
                      }),
                    const SizedBox(height: 28),
                    WinButton(context.l10n.instGroupCreateSubmit,
                        block: true,
                        loading: _loading,
                        icon: Icons.group_add,
                        onTap: _submit),
                  ]),
            ),
    );
  }
}
