import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image distante de l'application (lot 8, réseau lent) :
/// - gardée sur le téléphone : une vignette n'est plus retéléchargée à
///   chaque ouverture (sur 2G/3G, c'était le plus gros des échanges) ;
/// - décodée à la taille affichée : une photo de 3000 px ne prend plus
///   36 Mo de mémoire pour une vignette de 80 px (appareils à 2 Go).
/// Même rendu qu'Image.network : [error] en cas d'échec, rien pendant le
/// chargement.
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder error;

  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height, required this.error});

  /// Faux dans les tests : le cache disque passe par des greffons absents
  /// des tests ; Image.network y échoue proprement (erreur affichée).
  static bool diskCache = true;

  /// Fournisseur pour un avatar ou un fond (CircleAvatar, DecorationImage),
  /// décodé à [size] points de côté.
  static ImageProvider provider(BuildContext context, String url, {double size = 96}) {
    // Double de la taille : une photo plus large que haute reste nette une
    // fois recadrée dans le cercle.
    final px = (size * 2 * MediaQuery.devicePixelRatioOf(context)).round();
    final ImageProvider<Object> base =
        diskCache ? CachedNetworkImageProvider(url) as ImageProvider<Object> : NetworkImage(url);
    return ResizeImage(base, width: px, policy: ResizeImagePolicy.fit);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // Largeur de décodage : celle de la boîte, majorée pour qu'une image
        // plus large que haute garde sa netteté en BoxFit.cover (la hauteur
        // y commande l'échelle).
        final w = width ?? (c.hasBoundedWidth ? c.maxWidth : null);
        final h = height ?? (c.hasBoundedHeight ? c.maxHeight : 0.0);
        final side = w == null || !w.isFinite || w <= 0 ? null : (h.isFinite && h > w ? h : w);
        final cacheW = side == null ? null : (side * dpr * 1.5).round();
        if (!diskCache) {
          return Image.network(url,
              fit: fit, width: width, height: height, cacheWidth: cacheW, errorBuilder: (ctx, _, __) => error(ctx));
        }
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: cacheW,
          fadeInDuration: const Duration(milliseconds: 150),
          errorWidget: (ctx, _, __) => error(ctx),
        );
      });
}
