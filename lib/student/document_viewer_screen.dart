import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/subject_service.dart';
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
/// Les leçons de formation (Course, Module 6/27) ne passent pas par ici.
class DocumentViewerScreen extends StatefulWidget {
  final int subjectId;
  final String title;
  final ViewerDocumentKind kind;

  const DocumentViewerScreen({
    super.key,
    required this.subjectId,
    required this.title,
    this.kind = ViewerDocumentKind.document,
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
      final bytes = await SubjectService.instance.viewBytes(
        widget.subjectId,
        correction: widget.kind == ViewerDocumentKind.correction,
      );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
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
            'Votre session a expiré. Reconnectez-vous pour consulter ce document.',
          403 =>
            'Ce contenu n\'est pas inclus dans votre accès. Achetez-le ou abonnez-vous pour le consulter.',
          404 => widget.kind == ViewerDocumentKind.correction
              ? 'Le corrigé de cette épreuve n\'est pas encore disponible.'
              : 'Ce document n\'est pas disponible pour le moment.',
          null => 'Connexion impossible. Vérifiez votre réseau puis réessayez.',
          _ => 'Impossible de charger le document pour le moment.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _canRetry = true;
        _error = 'Impossible de charger le document pour le moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final title = widget.kind == ViewerDocumentKind.correction
        ? 'Corrigé · ${widget.title}'
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
                'Lecture seule : ni téléchargement, ni partage, ni impression',
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
            Text(_error ?? 'Impossible de charger le document pour le moment.',
                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
            if (_canRetry) ...[
              const SizedBox(height: 16),
              WinButton('Réessayer', icon: Icons.refresh, onTap: _load),
            ],
          ]),
        ),
      );
    }

    // Le document est entièrement en mémoire une fois chargé : une coupure
    // réseau pendant la lecture n'interrompt pas la consultation en cours.
    return PdfViewer.data(
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
  }
}

/// Ouvre la visionneuse intégrée d'un contenu du catalogue depuis n'importe
/// quel écran (fiche contenu, historique de consultation…).
void openDocumentViewer(
  BuildContext context, {
  required int subjectId,
  required String title,
  ViewerDocumentKind kind = ViewerDocumentKind.document,
}) {
  Navigator.push(
    context,
    WinPageRoute(
      builder: (_) => DocumentViewerScreen(
        subjectId: subjectId,
        title: title,
        kind: kind,
      ),
    ),
  );
}
