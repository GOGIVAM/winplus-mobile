import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/services/winai_sources_service.dart';

import '../helpers/faux_reseau.dart';

/// Sources de l'atelier WinAI : 25 Mo par fichier depuis winplus-api 41b2fbe.
void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  test('plafond par fichier : valeur du serveur, sinon 25 Mo', () {
    expect(WinAISourceUsage.fromJson(const {}).maxFileBytes, 25 * 1024 * 1024);
    expect(const WinAISourceUsage().maxFileBytes, 25 * 1024 * 1024);
    expect(WinAISourceUsage.fromJson(const {'maxFileBytes': 26214400}).maxFileBytes, 26214400);
  });

  test('televersement : delai d envoi allonge pour un gros fichier sur reseau lent', () async {
    faux.repond('POST', '/winai/sources', {
      'source': {'id': 3, 'title': 'Cours', 'fileName': 'cours.pdf', 'status': 'pending'},
    });
    await WinAISourcesService.instance.upload(List.filled(10, 0), 'cours.pdf');
    final req = faux.recues('POST', '/winai/sources').single;
    expect(req.sendTimeout, const Duration(minutes: 5));
    expect(req.receiveTimeout, const Duration(minutes: 2));
  });
}
