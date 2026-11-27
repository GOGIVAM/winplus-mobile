import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/data/reference_data.dart';

/// Audit du 27/11 : la matière d'un quiz arrive par son nom ; toutes les
/// cartes affichaient « Maths ».
void main() {
  test('matiere reconnue par son identifiant, son nom ou son nom court, sans accents', () {
    expect(WinData.subjectById('math').id, 'math');
    expect(WinData.subjectById('Mathématiques').id, 'math');
    expect(WinData.subjectById('mathematiques').id, 'math');
    expect(WinData.subjectById('Informatique').id, 'info');
    expect(WinData.subjectById('Français').id, 'fr');
    expect(WinData.subjectById('Physique-Chimie').id, 'pc');
    expect(WinData.subjectById('Culture generale').id, 'autre');
  });
}
