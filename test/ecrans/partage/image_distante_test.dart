import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/shared/net_image.dart';

import '../../helpers/faux_reseau.dart';

/// Lot 8 (réseau lent, appareils à 2 Go) : images distantes décodées à la
/// taille affichée, repli en cas d'échec.
void main() {
  setUp(preparerEnvironnement);

  testWidgets('decodee a la taille de la boite, pas a celle du fichier', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: SizedBox(width: 100, height: 60, child: NetImage('https://exemple.test/a.jpg', error: _erreur)),
      ),
    ));
    final img = tester.widget<Image>(find.byType(Image));
    final dpr = tester.view.devicePixelRatio;
    expect(img.image, isA<ResizeImage>());
    expect((img.image as ResizeImage).width, (100 * dpr * 1.5).round());
  });

  testWidgets('echec du chargement : repli affiche', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SizedBox(width: 100, height: 60, child: NetImage('https://exemple.test/a.jpg', error: _erreur)),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('repli'), findsOneWidget);
  });

  testWidgets('avatar : fournisseur reduit', (tester) async {
    late ImageProvider p;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      p = NetImage.provider(context, 'https://exemple.test/b.jpg', size: 36);
      return const SizedBox();
    })));
    expect(p, isA<ResizeImage>());
    expect((p as ResizeImage).width, (36 * 2 * tester.view.devicePixelRatio).round());
  });
}

Widget _erreur(BuildContext _) => const Text('repli', textDirection: TextDirection.ltr);
