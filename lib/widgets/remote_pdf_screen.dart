import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../l10n/l10n.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// Affiche un PDF servi par un lien présigné (certificat, pièce jointe d'une
/// leçon). Jamais utilisé pour les épreuves ni les livres du catalogue, qui
/// passent par la visionneuse sécurisée (DocumentViewerScreen).
class RemotePdfScreen extends StatefulWidget {
  final String title;
  final String url;

  /// Message en cas d'échec du chargement (par défaut : document générique).
  final String? errorText;
  const RemotePdfScreen({super.key, required this.title, required this.url, this.errorText});

  @override
  State<RemotePdfScreen> createState() => _RemotePdfScreenState();
}

class _RemotePdfScreenState extends State<RemotePdfScreen> {
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Lien présigné S3 : requête sans en-tête d'authentification.
      final res = await Dio().get<List<int>>(widget.url,
          options: Options(responseType: ResponseType.bytes));
      if (!mounted) return;
      setState(() => _bytes = Uint8List.fromList(res.data ?? const []));
    } catch (_) {
      if (mounted) setState(() => _error = widget.errorText ?? L10n.current.studentPdfLoadError);
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
        foregroundColor: s.onStrong,
        title: Text(widget.title, style: WinType.titleM(s.onStrong)),
      ),
      body: _error != null
          ? Center(
              child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!,
                  textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted)),
            ))
          : _bytes == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewer.data(_bytes!,
                  sourceName:
                      'winplus-pdf-${widget.url.hashCode}-${DateTime.now().microsecondsSinceEpoch}',
                  params: PdfViewerParams(backgroundColor: s.bg)),
    );
  }
}
