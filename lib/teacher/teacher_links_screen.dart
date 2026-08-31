import 'package:flutter/material.dart';
import '../services/linking_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class TeacherLinksScreen extends StatefulWidget {
  const TeacherLinksScreen({super.key});
  @override
  State<TeacherLinksScreen> createState() => _TeacherLinksScreenState();
}

class _TeacherLinksScreenState extends State<TeacherLinksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<dynamic> _pending = [];
  List<dynamic> _linked = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  bool _inviting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pending = await LinkingService.instance.getPendingInvitations();
      final linked = await LinkingService.instance.getMyLinks();
      if (mounted) setState(() { _pending = pending; _linked = linked; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _searchResults = []); return; }
    setState(() => _searching = true);
    try {
      final results = await LinkingService.instance.searchUsers(q);
      if (mounted) setState(() { _searchResults = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _invite(int userId) async {
    setState(() => _inviting = true);
    try {
      await LinkingService.instance.invite(userId);
      _searchCtrl.clear();
      setState(() { _searchResults = []; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée !')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: WinColors.error));
      }
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _respond(int linkId, bool accept) async {
    try {
      if (accept) {
        await LinkingService.instance.acceptInvitation(linkId);
      } else {
        await LinkingService.instance.rejectInvitation(linkId);
      }
      await _load();
    } catch (_) {}
  }

  Future<void> _delete(int linkId) async {
    try {
      await LinkingService.instance.deleteLink(linkId);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text('Mes liaisons élèves', style: WinType.headlineS(s.onStrong)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: s.primary,
          unselectedLabelColor: s.onMuted,
          indicatorColor: s.primary,
          tabs: [
            Tab(text: 'En attente${_pending.isNotEmpty ? " (${_pending.length})" : ""}'),
            const Tab(text: 'Liés'),
          ],
        ),
      ),
      body: Column(children: [
        // Recherche pour inviter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            WinTextField(
              label: 'Inviter un élève',
              hint: 'Nom, email ou téléphone…',
              icon: Icons.person_search_outlined,
              controller: _searchCtrl,
              onChanged: _search,
            ),
            if (_searching) const LinearProgressIndicator(),
            if (_searchResults.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: s.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: s.outline),
                ),
                child: Column(
                  children: _searchResults.map((u) {
                    final user = u as Map<String, dynamic>;
                    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: s.surface2, child: Icon(Icons.person, color: s.onFaint)),
                      title: Text(name, style: WinType.bodyM(s.onStrong)),
                      subtitle: Text(user['email'] ?? '', style: WinType.labelM(s.onMuted)),
                      trailing: IconButton(
                        icon: _inviting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.person_add, color: s.primary),
                        onPressed: _inviting ? null : () => _invite(user['id'] as int),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ]),
        ),
        // Onglets
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabs, children: [
              // Onglet "En attente"
              _pending.isEmpty
                ? Center(child: Text('Aucune invitation en attente', style: WinType.bodyM(s.onMuted)))
                : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final inv = _pending[i] as Map<String, dynamic>;
                    final init = inv['initiator'] as Map<String, dynamic>? ?? {};
                    final name = '${init['firstName'] ?? ''} ${init['lastName'] ?? ''}'.trim();
                    return WinCard(child: Row(children: [
                      CircleAvatar(backgroundColor: s.surface2, child: Icon(Icons.person, color: s.onFaint)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name.isEmpty ? 'Utilisateur' : name, style: WinType.bodyM(s.onStrong))),
                      IconButton(
                        icon: const Icon(Icons.check, color: WinColors.success),
                        onPressed: () => _respond(inv['id'] as int, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: WinColors.error),
                        onPressed: () => _respond(inv['id'] as int, false),
                      ),
                    ]));
                  },
                ),
              // Onglet "Liés"
              _linked.isEmpty
                ? Center(child: Text('Aucun élève lié', style: WinType.bodyM(s.onMuted)))
                : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _linked.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final link = _linked[i] as Map<String, dynamic>;
                    final other = link['other'] as Map<String, dynamic>? ?? {};
                    final name = '${other['firstName'] ?? ''} ${other['lastName'] ?? ''}'.trim();
                    return WinCard(child: Row(children: [
                      CircleAvatar(backgroundColor: s.surface2, child: Icon(Icons.person, color: s.onFaint)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name.isEmpty ? 'Utilisateur' : name, style: WinType.bodyM(s.onStrong))),
                      IconButton(
                        icon: Icon(Icons.link_off, color: s.onFaint),
                        onPressed: () => _delete(link['id'] as int),
                      ),
                    ]));
                  },
                ),
            ]),
        ),
      ]),
    );
  }
}
