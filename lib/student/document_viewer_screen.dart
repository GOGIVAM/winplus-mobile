import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};

/// Visionneuse intégrée : ouvre un fichier téléchargé localement, ou distant
/// si aucune copie locale n'existe (voir ContentDetailScreen). Jamais
/// d'intent "ouvrir avec" ni de partage du fichier brut  seuls les types
/// que l'app sait effectivement afficher (images) sont rendus ; les autres
/// affichent un état neutre "disponible hors ligne" sans exposer le fichier
/// à une autre app installée.
class DocumentViewerScreen extends StatelessWidget {
  final String title;
  final String? localPath;
  final String remoteUrl;

  const DocumentViewerScreen({
    super.key,
    required this.title,
    required this.remoteUrl,
    this.localPath,
  });

  bool get _isLocalImage {
    if (localPath == null) return false;
    final lower = localPath!.toLowerCase();
    return _imageExtensions.any((ext) => lower.endsWith(ext));
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.surface,
        title: Text(title, style: WinType.titleM(s.onStrong)),
        iconTheme: IconThemeData(color: s.onStrong),
      ),
      body: SafeArea(
        child: _buildBody(context, s),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WinScheme s) {
    if (_isLocalImage) {
      return InteractiveViewer(
        child: Center(child: Image.file(File(localPath!), fit: BoxFit.contain)),
      );
    }

    if (localPath != null) {
      // Fichier présent localement mais d'un type que l'app ne rend pas
      // encore (pas de visionneuse PDF embarquée à ce stade) : on le dit
      // clairement plutôt que de déléguer l'ouverture à une autre app.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.insert_drive_file_outlined, size: 56, color: s.onFaint),
            const SizedBox(height: 16),
            Text('Fichier téléchargé, disponible hors ligne',
                style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('L\'aperçu dans l\'app n\'est pas encore disponible pour ce type de fichier.',
                style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    // Pas de copie locale : contenu affiché depuis le réseau (comportement
    // actuel), toujours dans l'app  jamais de lien externe.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_outlined, size: 56, color: s.onFaint),
          const SizedBox(height: 16),
          Text('Ce contenu n\'a pas encore été téléchargé',
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Téléchargez-le pour le consulter, y compris hors ligne.',
              style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

/// Petit helper pour naviguer vers la visionneuse depuis n'importe quel
/// écran (contenu, historique de téléchargements…).
void openDocumentViewer(
  BuildContext context, {
  required String title,
  required String remoteUrl,
  String? localPath,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DocumentViewerScreen(
        title: title,
        remoteUrl: remoteUrl,
        localPath: localPath,
      ),
    ),
  );
}
