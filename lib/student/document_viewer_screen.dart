import '../l10n/l10n.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/subject_service.dart';
import '../shared/subscription/pricing_screen.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Énoncé (épreuve ou livre) ou corrigé d'une épreuve.
enum ViewerDocumentKind { document, correction }

/// Visionneuse intégrée des épreuves, corrigés et livres du catalogue
/// (Module 44, décisions §11.1 à §11.4).
///
/// - Le PDF est demandé au serveur (GET /subjects/{id}/view) qui applique la
///   règle d'accès et incruste dans chaque page un filigrane nominatif (nom,
///   e-mail et identifiant du compte connecté) : toute capture d'écran en
///   porte la trace. Le filigrane fait partie du document rendu, ce n'est
///   pas un widget superposé.
/// - Les octets restent en mémoire, le temps de l'affichage : rien n'est
///   écrit sur l'appareil, et la fermeture de l'écran les libère.
/// - Aucune action de téléchargement, de partage, d'impression ni de
///   sélection/copie de texte n'est proposée.
///
/// Les fichiers propres aux leçons de formation (Course, Module 6/27) ne
/// passent pas par ici ; seules les épreuves et les livres du catalogue
/// ajoutés à une formation s'y ouvrent, avec [courseId] (lot 9.7b, F13).
class DocumentViewerScreen extends StatefulWidget {
  final int subjectId;
  final String title;
  final ViewerDocumentKind kind;

  /// Formation suivie qui contient ce document (accès par l'inscription).
  final int? courseId;

  /// Lot 9.7b (aperçu du catalogue) : ajout au panier proposé dans le
  /// bandeau d'aperçu ; sans lui, seule l'invitation à s'abonner apparaît.
  final VoidCallback? onPurchase;

  const DocumentViewerScreen({
    super.key,
    required this.subjectId,
    required this.title,
    this.kind = ViewerDocumentKind.document,
    this.courseId,
    this.onPurchase,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  Uint8List? _bytes;
  String? _error;
  bool _canRetry = true;
  bool _loading = true;
  int _page = 1;
  int _pageCount = 0;
  // Aperçu décidé et découpé par le serveur (seules ces pages sont reçues).
  int? _previewPages;
  int? _totalPages;

  // Identifiant de source unique par ouverture : pdfrx s'en sert comme clé
  // interne, il ne doit pas réutiliser un document d'une ouverture précédente.
  late final String _sourceName =
      'winplus-subject-${widget.subjectId}-${widget.kind.name}-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bytes = null;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await SubjectService.instance.view(
        widget.subjectId,
        correction: widget.kind == ViewerDocumentKind.correction,
        courseId: widget.courseId,
      );
      if (!mounted) return;
      setState(() {
        _bytes = doc.bytes;
        _previewPages = doc.previewPages;
        _totalPages = doc.totalPages;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      setState(() {
        _loading = false;
        _canRetry = status == null || status >= 500;
        _error = switch (status) {
          401 =>
            L10n.current.studentViewerSessionExpired,
          403 =>
            L10n.current.studentViewerNoAccess,
          404 => widget.kind == ViewerDocumentKind.correction
              ? L10n.current.studentViewerNoCorrection
              : L10n.current.studentViewerNoDocument,
          null => L10n.current.studentViewerNoConnection,
          _ => L10n.current.studentViewerLoadFailed,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _canRetry = true;
        _error = L10n.current.studentViewerLoadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final title = widget.kind == ViewerDocumentKind.correction
        ? context.l10n.studentViewerCorrectionTitle(widget.title)
        : widget.title;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(title,
            style: WinType.titleM(s.onStrong),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          if (_pageCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('$_page / $_pageCount',
                    style: WinType.labelM(s.onMuted)),
              ),
            ),
          Tooltip(
            message:
                context.l10n.studentViewerReadOnly,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.lock_outline, size: 20, color: s.onMuted),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(s)),
    );
  }

  Widget _buildBody(WinScheme s) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.picture_as_pdf_outlined, size: 56, color: s.onFaint),
            const SizedBox(height: 16),
            Text(_error ?? context.l10n.studentViewerLoadFailed,
                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
            if (_canRetry) ...[
              const SizedBox(height: 16),
              WinButton(context.l10n.commonRetry, icon: Icons.refresh, onTap: _load),
            ],
          ]),
        ),
      );
    }

    // Le document est entièrement en mémoire une fois chargé : une coupure
    // réseau pendant la lecture n'interrompt pas la consultation en cours.
    final viewer = PdfViewer.data(
      _bytes!,
      sourceName: _sourceName,
      params: PdfViewerParams(
        backgroundColor: s.bg,
        // Pas de sélection ni de copie du texte, pas de menu contextuel.
        textSelectionParams: const PdfTextSelectionParams(enabled: false),
        buildContextMenu: (context, params) => null,
        onViewerReady: (document, controller) {
          if (mounted) setState(() => _pageCount = document.pages.length);
        },
        onPageChanged: (pageNumber) {
          if (pageNumber != null && mounted) setState(() => _page = pageNumber);
        },
      ),
    );
    final preview = _previewPages;
    if (preview == null) return viewer;
    return Column(children: [
      _PreviewBanner(
        pages: preview,
        total: _totalPages,
        onPurchase: widget.onPurchase == null
            ? null
            : () {
                Navigator.pop(context);
                widget.onPurchase!();
              },
        onPlans: () => Navigator.pushReplacement(
            context, WinPageRoute(builder: (_) => const PricingScreen())),
      ),
      Expanded(child: viewer),
    ]);
  }
}

/// Bandeau « Aperçu : N pages sur M » (lot 9.7b, droit catalog.preview_pages).
class _PreviewBanner extends StatelessWidget {
  final int pages;
  final int? total;
  final VoidCallback? onPurchase;
  final VoidCallback onPlans;
  const _PreviewBanner({required this.pages, required this.total, required this.onPurchase, required this.onPlans});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final label = total != null
        ? context.l10n.studentViewerPreviewOf(pages, total!)
        : context.l10n.studentViewerPreviewFirst(pages);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
          color: s.surface2, border: Border(bottom: BorderSide(color: s.outline))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_outline, size: 16, color: s.onStrong),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: WinType.titleS(s.onStrong))),
        ]),
        const SizedBox(height: 4),
        Text(context.l10n.studentViewerUnlockRest,
            style: WinType.bodyS(s.onMuted)),
        const SizedBox(height: 10),
        Row(children: [
          if (onPurchase != null) ...[
            Expanded(
                child: WinButton(context.l10n.studentViewerAddToCart,
                    icon: Icons.shopping_cart_outlined, onTap: onPurchase)),
            const SizedBox(width: 8),
          ],
          Expanded(
              child: WinButton(context.l10n.studentViewerSubscriptions,
                  variant: WinButtonVariant.outline, onTap: onPlans)),
        ]),
      ]),
    );
  }
}

/// Ouvre la visionneuse intégrée d'un contenu du catalogue depuis n'importe
/// quel écran (fiche contenu, historique de consultation…).
void openDocumentViewer(
  BuildContext context, {
  required int subjectId,
  required String title,
  ViewerDocumentKind kind = ViewerDocumentKind.document,
  VoidCallback? onPurchase,
}) {
  Navigator.push(
    context,
    WinPageRoute(
      builder: (_) => DocumentViewerScreen(
        subjectId: subjectId,
        title: title,
        kind: kind,
        onPurchase: onPurchase,
      ),
    ),
  );
}
