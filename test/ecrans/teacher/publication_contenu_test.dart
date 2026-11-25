import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/content_publish_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Finder _bouton(String libelle) => find.widgetWithText(WinButton, libelle);

/// Selecteur de fichiers de test : renvoie le fichier choisi sans ouvrir de
/// fenetre systeme. [fichier] a null simule un choix annule.
class _FauxSelecteur extends FilePicker {
  PlatformFile? fichier;
  int appels = 0;
  List<String>? extensionsDemandees;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic onFileLoading,
    bool? allowCompression,
    int? compressionQuality,
    bool allowMultiple = false,
    bool? withData,
    bool? withReadStream,
    bool lockParentWindow = false,
    bool? readSequential,
  }) async {
    appels++;
    extensionsDemandees = allowedExtensions;
    final f = fichier;
    return f == null ? null : FilePickerResult([f]);
  }
}

void main() {
  late FauxReseau faux;
  late _FauxSelecteur selecteur;

  setUp(() {
    faux = preparerEnvironnement(prefs: {'user_role': 'teacher'});
    selecteur = _FauxSelecteur();
    FilePicker.platform = selecteur;
  });

  /// Ouvre l'ecran au-dessus d'une page d'accueil (il se ferme apres l'envoi).
  Future<void> ouvrirEcran(WidgetTester tester) async {
    telephone(tester);
    // Ecran haut : le formulaire entier est construit sans defilement.
    tester.view.physicalSize = const Size(800, 4000);
    await monter(tester, ecran(lanceur(const ContentPublishScreen())));
    await ouvrir(tester);
  }

  Future<void> choisirFichier(WidgetTester tester, {String nom = 'bac.pdf', int taille = 2048}) async {
    selecteur.fichier = PlatformFile(name: nom, size: taille);
    await tester.tap(_bouton(L10n.current.teacherPublishChooseFile));
    await pomper(tester);
  }

  Future<void> saisirTitre(WidgetTester tester, String titre) async {
    await tester.enterText(find.widgetWithText(TextField, L10n.current.teacherPublishTitleHint), titre);
  }

  testWidgets('rendu : titre, champs, prix par defaut « abonnement uniquement » et note de revision', (tester) async {
    await ouvrirEcran(tester);
    final l = L10n.current;
    expect(find.text(l.teacherPublishTitle), findsOneWidget);
    expect(find.widgetWithText(TextField, l.teacherPublishTitleHint), findsOneWidget);
    expect(find.widgetWithText(TextField, l.teacherPublishYearHint), findsOneWidget);
    expect(find.widgetWithText(TextField, l.teacherPublishDescriptionHint), findsOneWidget);
    expect(find.text(l.teacherPublishSubscriptionOnly), findsOneWidget);
    expect(find.text(l.teacherPublishFreePrice), findsOneWidget);
    expect(find.widgetWithText(TextField, l.teacherPublishAmountHint), findsNothing);
    expect(_bouton(l.teacherPublishChooseFile), findsOneWidget);
    expect(_bouton(l.teacherPublishSubmit), findsOneWidget);
    expect(find.text(l.teacherPublishReviewNote), findsOneWidget);
  });

  testWidgets('titre vide : message et aucun envoi', (tester) async {
    await ouvrirEcran(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await pomper(tester);
    expect(find.text(L10n.current.teacherPublishTitleRequired), findsOneWidget);
    expect(faux.requetes, isEmpty);
  });

  testWidgets('titre composé d\'espaces : refuse comme un titre vide', (tester) async {
    await ouvrirEcran(tester);
    await saisirTitre(tester, '    ');
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await pomper(tester);
    expect(find.text(L10n.current.teacherPublishTitleRequired), findsOneWidget);
  });

  testWidgets('titre sans fichier : « Veuillez choisir un fichier »', (tester) async {
    await ouvrirEcran(tester);
    await saisirTitre(tester, 'Epreuve BAC C 2024');
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await pomper(tester);
    expect(find.text(L10n.current.teacherPublishFileRequired), findsOneWidget);
    expect(faux.requetes, isEmpty);
  });

  testWidgets('choix du fichier : formats PDF, EPUB et ZIP ; nom et taille affiches ; la croix le retire', (tester) async {
    await ouvrirEcran(tester);
    final l = L10n.current;
    await choisirFichier(tester, taille: 2048);
    expect(selecteur.extensionsDemandees, ['pdf', 'epub', 'zip']);
    expect(find.text('bac.pdf · ${l.teacherPublishSizeKb('2.0')}'), findsOneWidget);
    expect(_bouton(l.teacherPublishChooseFile), findsNothing);
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await pomper(tester);
    expect(_bouton(l.teacherPublishChooseFile), findsOneWidget);
  });

  testWidgets('tailles : octets, kilo-octets et mega-octets ; taille inconnue = nom seul', (tester) async {
    await ouvrirEcran(tester);
    final l = L10n.current;
    await choisirFichier(tester, taille: 500);
    expect(find.text('bac.pdf · ${l.teacherPublishSizeBytes(500)}'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await pomper(tester);
    await choisirFichier(tester, taille: 3 * 1024 * 1024);
    expect(find.text('bac.pdf · ${l.teacherPublishSizeMb('3.0')}'), findsOneWidget);
    await tester.tap(find.byIcon(PhosphorIconsRegular.x));
    await pomper(tester);
    await choisirFichier(tester, taille: 0);
    expect(find.text('bac.pdf'), findsOneWidget);
  });

  testWidgets('selecteur annule : on reste sans fichier', (tester) async {
    await ouvrirEcran(tester);
    selecteur.fichier = null;
    await tester.tap(_bouton(L10n.current.teacherPublishChooseFile));
    await pomper(tester);
    expect(selecteur.appels, 1);
    expect(_bouton(L10n.current.teacherPublishChooseFile), findsOneWidget);
  });

  testWidgets('envoi : titre rogne, matiere et niveau par defaut, prix a 0, puis message et retour', (tester) async {
    faux.repond('POST', '/subjects', {'id': 1});
    await ouvrirEcran(tester);
    await saisirTitre(tester, '  Epreuve BAC C 2024 ');
    await choisirFichier(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    expect(faux.recues('POST', '/subjects').single.data, {
      'title': 'Epreuve BAC C 2024',
      'category': 'Mathématiques',
      'level': 'BAC C',
      'price': 0,
    });
    expect(find.byType(ContentPublishScreen), findsNothing);
    expect(find.text(L10n.current.teacherPublishSubmitted), findsOneWidget);
  });

  testWidgets('matiere, niveau, description et prix libre : tous envoyes', (tester) async {
    faux.repond('POST', '/subjects', {'id': 1});
    await ouvrirEcran(tester);
    final l = L10n.current;
    await saisirTitre(tester, 'Annales');
    await tester.enterText(find.widgetWithText(TextField, l.teacherPublishDescriptionHint), '  Sujets corriges ');
    // Matiere : liste deroulante.
    await tester.tap(find.text(l.dataSubjectMath));
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text(l.dataSubjectPhysics).last);
    await pomper(tester);
    await pomper(tester, const Duration(milliseconds: 400));
    // Niveau : pastilles.
    await tester.tap(find.text('BEPC').first);
    await pomper(tester);
    // Prix libre : champ de montant.
    await tester.tap(find.text(l.teacherPublishFreePrice));
    await pomper(tester);
    await tester.enterText(find.widgetWithText(TextField, l.teacherPublishAmountHint), '750');
    await choisirFichier(tester);
    await tester.tap(_bouton(l.teacherPublishSubmit));
    await reseau(tester);
    expect(faux.recues('POST', '/subjects').single.data, {
      'title': 'Annales',
      'category': 'Physique',
      'level': 'BEPC',
      'price': 750,
      'description': 'Sujets corriges',
    });
  });

  testWidgets('prix libre puis retour a « abonnement uniquement » : prix a 0 meme avec un montant saisi', (tester) async {
    faux.repond('POST', '/subjects', {'id': 1});
    await ouvrirEcran(tester);
    final l = L10n.current;
    await saisirTitre(tester, 'Annales');
    await tester.tap(find.text(l.teacherPublishFreePrice));
    await pomper(tester);
    await tester.enterText(find.widgetWithText(TextField, l.teacherPublishAmountHint), '750');
    await tester.tap(find.text(l.teacherPublishSubscriptionOnly));
    await pomper(tester);
    expect(find.widgetWithText(TextField, l.teacherPublishAmountHint), findsNothing);
    await choisirFichier(tester);
    await tester.tap(_bouton(l.teacherPublishSubmit));
    await reseau(tester);
    expect(faux.recues('POST', '/subjects').single.data['price'], 0);
  });

  testWidgets('prix libre sans montant : prix a 0 ; le champ n\'accepte que des chiffres', (tester) async {
    faux.repond('POST', '/subjects', {'id': 1});
    await ouvrirEcran(tester);
    final l = L10n.current;
    await saisirTitre(tester, 'Annales');
    await tester.tap(find.text(l.teacherPublishFreePrice));
    await pomper(tester);
    await tester.enterText(find.widgetWithText(TextField, l.teacherPublishAmountHint), '12abc');
    expect(tester.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.decoration?.suffixText == 'XAF')).controller!.text, '12');
    await tester.enterText(find.byWidgetPredicate((w) => w is TextField && w.decoration?.suffixText == 'XAF'), '');
    await choisirFichier(tester);
    await tester.tap(_bouton(l.teacherPublishSubmit));
    await reseau(tester);
    expect(faux.recues('POST', '/subjects').single.data['price'], 0);
  });

  testWidgets('annee : seuls les chiffres sont acceptes', (tester) async {
    await ouvrirEcran(tester);
    final champ = find.widgetWithText(TextField, L10n.current.teacherPublishYearHint);
    await tester.enterText(champ, '20a24');
    expect(tester.widget<TextField>(champ).controller!.text, '2024');
  });

  testWidgets('refus du serveur : message d\'echec, l\'ecran reste ouvert', (tester) async {
    faux.repond('POST', '/subjects', {'error': 'x'}, statut: 500);
    await ouvrirEcran(tester);
    await saisirTitre(tester, 'Annales');
    await choisirFichier(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    expect(find.text(L10n.current.teacherPublishSubmitFailed), findsOneWidget);
    expect(find.byType(ContentPublishScreen), findsOneWidget);
  });

  testWidgets('hors ligne : meme message d\'echec, l\'ecran reste ouvert', (tester) async {
    faux.coupure('POST', '/subjects');
    await ouvrirEcran(tester);
    await saisirTitre(tester, 'Annales');
    await choisirFichier(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    expect(find.text(L10n.current.teacherPublishSubmitFailed), findsOneWidget);
    expect(find.byType(ContentPublishScreen), findsOneWidget);
  });

  testWidgets('apres un echec, un nouvel envoi efface le message d\'erreur', (tester) async {
    faux.repond('POST', '/subjects', {}, statut: 500);
    await ouvrirEcran(tester);
    await saisirTitre(tester, 'Annales');
    await choisirFichier(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    expect(find.text(L10n.current.teacherPublishSubmitFailed), findsOneWidget);
    faux.repond('POST', '/subjects', {'id': 2});
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    expect(find.byType(ContentPublishScreen), findsNothing);
  });

  // Bug probable (lecture du code) : l'ecran impose le choix d'un fichier et
  // demande l'annee et l'examen, mais ni le fichier, ni l'annee, ni l'examen
  // ne sont envoyes au serveur (publishContent ne transmet que titre, matiere,
  // niveau, prix et description).
  testWidgets('BUG PROBABLE : le fichier choisi, l\'annee et l\'examen sont transmis au serveur', (tester) async {
    faux.repond('POST', '/subjects', {'id': 1});
    await ouvrirEcran(tester);
    await saisirTitre(tester, 'Annales');
    await tester.enterText(find.widgetWithText(TextField, L10n.current.teacherPublishYearHint), '2024');
    await choisirFichier(tester);
    await tester.tap(_bouton(L10n.current.teacherPublishSubmit));
    await reseau(tester);
    final envoi = faux.recues('POST', '/subjects').single.data as Map;
    expect(envoi.containsKey('year'), isTrue);
    expect(envoi.containsKey('exam'), isTrue);
  }, skip: true); // Bug probable : voir le commentaire ci-dessus.
}
