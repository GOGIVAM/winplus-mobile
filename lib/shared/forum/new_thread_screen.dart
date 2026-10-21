import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/forum_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

/// Libellé affiché d'une catégorie du forum ; la valeur envoyée à l'API
/// reste le nom français (lot 10.11).
String forumCategoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'Questions' => l10n.forumCatQuestions,
      'Discussions' => l10n.forumCatDiscussions,
      'Ressources' => l10n.forumCatResources,
      'Aide' => l10n.forumCatHelp,
      _ => category,
    };

class NewThreadScreen extends StatefulWidget {
  const NewThreadScreen({super.key});
  @override
  State<NewThreadScreen> createState() => _NewThreadScreenState();
}

class _NewThreadScreenState extends State<NewThreadScreen> {
  static const _categories = ['Questions', 'Discussions', 'Ressources', 'Aide'];
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'Questions';
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty)
      return;
    setState(() => _loading = true);
    try {
      await ForumService.instance.createThread(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        category: _category,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.l10n.forumError(e)),
            backgroundColor: WinColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.close, color: s.onStrong),
            onPressed: () => Navigator.pop(context)),
        title: Text(l10n.forumNewThread, style: WinType.headlineS(s.onStrong)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.forumCategory, style: WinType.titleM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map((cat) => WinChip(
                      forumCategoryLabel(l10n, cat),
                      active: cat == _category,
                      onTap: () => setState(() => _category = cat),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          WinTextField(
              label: l10n.forumTitleField,
              hint: l10n.forumTitleHint,
              icon: Icons.title,
              controller: _titleCtrl),
          const SizedBox(height: 16),
          // Contenu multilignes  TextField natif car WinTextField ne supporte pas maxLines
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l10n.forumContentField,
                  style: WinType.labelM(s.onStrong)
                      .copyWith(fontWeight: FontWeight.w500)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s.surface,
                borderRadius: BorderRadius.circular(WinRadii.md),
                border: Border.all(color: s.outline, width: 1.5),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: Icon(Icons.edit_outlined, size: 18, color: s.onFaint),
                ),
                Expanded(
                  child: TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    minLines: 4,
                    style: WinType.bodyM(s.onStrong),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l10n.forumContentHint,
                      hintStyle: WinType.bodyM(s.onFaint),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 32),
          WinButton(l10n.forumPublish,
              block: true, loading: _loading, onTap: _loading ? null : _submit),
        ]),
      ),
    );
  }
}
