import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/theme/win_colors.dart';
import 'package:winplus/theme/win_theme.dart';
import 'package:winplus/widgets/win_widgets.dart';
import 'package:winplus/widgets/win_mascot.dart';

import '../helpers/appli.dart';
import '../helpers/faux_reseau.dart';

Color? _fondDuBouton(WidgetTester tester) =>
    tester.widget<Material>(find.descendant(of: find.byType(WinButton), matching: find.byType(Material)).first).color;

Color? _fondDuBadge(WidgetTester tester) {
  final c = tester.widget<Container>(find.descendant(of: find.byType(WinBadge), matching: find.byType(Container)).first);
  return (c.decoration as BoxDecoration).color;
}

void main() {
  setUp(() => preparerEnvironnement());

  group('WinButton', () {
    testWidgets('affiche son libelle et appelle onTap au toucher', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinButton('Valider', onTap: () => appels++)));
      expect(find.text('Valider'), findsOneWidget);
      await tester.tap(find.text('Valider'));
      await pomper(tester);
      expect(appels, 1);
    });

    testWidgets('en chargement : un indicateur remplace le libelle et le toucher est ignore', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinButton('Valider', loading: true, onTap: () => appels++)));
      expect(find.text('Valider'), findsNothing);
      expect(find.byType(WinLoadingDots), findsOneWidget);
      await tester.tap(find.byType(WinButton));
      await pomper(tester);
      expect(appels, 0);
    });

    testWidgets('sans onTap, le toucher ne leve aucune erreur', (tester) async {
      await monter(tester, appli(const WinButton('Inactif')));
      await tester.tap(find.text('Inactif'));
      await pomper(tester);
      expect(find.text('Inactif'), findsOneWidget);
    });

    testWidgets('hauteur : 48 par defaut, minimum tactile de 44 en petit', (tester) async {
      await monter(tester, appli(const WinButton('Normal')));
      expect(tester.getSize(find.byType(WinButton)).height, 48);
      await monter(tester, appli(const WinButton('Petit', small: true)));
      expect(tester.getSize(find.byType(WinButton)).height, 44);
    });

    testWidgets('en bloc, le bouton prend toute la largeur', (tester) async {
      await monter(tester, appli(const WinButton('Large', block: true)));
      expect(tester.getSize(find.byType(WinButton)).width, tester.getSize(find.byType(MaterialApp)).width);
    });

    testWidgets('affiche son icone avant le libelle', (tester) async {
      await monter(tester, appli(const WinButton('Aimer', icon: Icons.favorite)));
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('couleur de fond selon la variante', (tester) async {
      await monter(tester, appli(WinButton('A', onTap: () {}, variant: WinButtonVariant.primary)));
      // Boutons sarcelle a texte blanc, comme sur le site (palette dd8d7b9).
      expect(_fondDuBouton(tester), WinColors.teal700);
      await monter(tester, appli(WinButton('A', onTap: () {}, variant: WinButtonVariant.danger)));
      expect(_fondDuBouton(tester), WinColors.error);
      await monter(tester, appli(WinButton('A', onTap: () {}, variant: WinButtonVariant.accent)));
      expect(_fondDuBouton(tester), WinColors.teal700);
      await monter(tester, appli(WinButton('A', onTap: () {}, variant: WinButtonVariant.outline)));
      expect(_fondDuBouton(tester), Colors.transparent);
    });

    testWidgets('la variante accent suit le theme sombre', (tester) async {
      await monter(tester, appli(WinButton('A', onTap: () {}), schema: WinScheme.dark_));
      expect(_fondDuBouton(tester), WinScheme.dark_.primary);
    });
  });

  group('WinCard', () {
    testWidgets('sans onTap, aucune zone tactile', (tester) async {
      await monter(tester, appli(const WinCard(child: Text('Contenu'))));
      expect(find.text('Contenu'), findsOneWidget);
      expect(find.descendant(of: find.byType(WinCard), matching: find.byType(InkWell)), findsNothing);
    });

    testWidgets('avec onTap, le toucher est transmis', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinCard(onTap: () => appels++, child: const Text('Contenu'))));
      await tester.tap(find.text('Contenu'));
      await pomper(tester);
      expect(appels, 1);
    });
  });

  group('WinChip', () {
    testWidgets('affiche son libelle et son icone, et transmet le toucher', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinChip('Maths', icon: Icons.functions, onTap: () => appels++)));
      expect(find.text('Maths'), findsOneWidget);
      expect(find.byIcon(Icons.functions), findsOneWidget);
      await tester.tap(find.text('Maths'));
      await pomper(tester);
      expect(appels, 1);
    });

    testWidgets('actif ou non, la puce garde son libelle', (tester) async {
      await monter(tester, appli(const WinChip('Physique', active: true)));
      expect(find.text('Physique'), findsOneWidget);
      await monter(tester, appli(const WinChip('Physique')));
      expect(find.text('Physique'), findsOneWidget);
    });
  });

  group('WinBadge', () {
    testWidgets('affiche son texte', (tester) async {
      await monter(tester, appli(const WinBadge('Nouveau')));
      expect(find.text('Nouveau'), findsOneWidget);
    });

    testWidgets('couleur de fond selon le type, neutre par defaut', (tester) async {
      await monter(tester, appli(const WinBadge('x')));
      expect(_fondDuBadge(tester), WinColors.ink50);
      await monter(tester, appli(const WinBadge('x', color: BadgeColor.success)));
      expect(_fondDuBadge(tester), WinColors.successBg);
      await monter(tester, appli(const WinBadge('x', color: BadgeColor.error)));
      expect(_fondDuBadge(tester), WinColors.errorBg);
      await monter(tester, appli(const WinBadge('x', color: BadgeColor.gold)));
      expect(_fondDuBadge(tester), WinColors.goldBg);
    });
  });

  group('WinProgressBar', () {
    double valeur(WidgetTester tester) => tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;

    testWidgets('convertit un pourcentage en fraction', (tester) async {
      await monter(tester, appli(const SizedBox(width: 200, child: WinProgressBar(50))));
      expect(valeur(tester), 0.5);
    });

    testWidgets('0 % et 100 % donnent une barre vide et une barre pleine', (tester) async {
      await monter(tester, appli(const SizedBox(width: 200, child: WinProgressBar(0))));
      expect(valeur(tester), 0.0);
      await monter(tester, appli(const SizedBox(width: 200, child: WinProgressBar(100))));
      expect(valeur(tester), 1.0);
    });
  });

  group('WinAvatar', () {
    testWidgets('initiales : deux premiers mots, en majuscules', (tester) async {
      await monter(tester, appli(const WinAvatar('ada lovelace')));
      expect(find.text('AL'), findsOneWidget);
      await monter(tester, appli(const WinAvatar('ada marie lovelace')));
      expect(find.text('AM'), findsOneWidget);
    });

    testWidgets('un seul mot, des espaces en trop ou un nom vide', (tester) async {
      await monter(tester, appli(const WinAvatar('  ada  ')));
      expect(find.text('A'), findsOneWidget);
      await monter(tester, appli(const WinAvatar('')));
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('avec une progression, un anneau en pourcentage entoure l\'avatar', (tester) async {
      await monter(tester, appli(const WinAvatar('Ada Lovelace', progress: 50)));
      final anneau = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(anneau.value, 0.5);
    });

    testWidgets('sans progression, pas d\'anneau', (tester) async {
      await monter(tester, appli(const WinAvatar('Ada Lovelace')));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('WinAlert', () {
    IconData icone(WidgetTester tester) => tester.widget<Icon>(find.descendant(of: find.byType(WinAlert), matching: find.byType(Icon))).icon!;

    testWidgets('affiche le message avec l\'icone du type', (tester) async {
      await monter(tester, appli(const WinAlert('Attention')));
      expect(find.text('Attention'), findsOneWidget);
      expect(icone(tester), Icons.warning_amber_outlined);
      await monter(tester, appli(const WinAlert('Ok', type: BadgeColor.success)));
      expect(icone(tester), Icons.check_circle_outline);
      await monter(tester, appli(const WinAlert('Ko', type: BadgeColor.error)));
      expect(icone(tester), Icons.error_outline);
      await monter(tester, appli(const WinAlert('Info', type: BadgeColor.neutral)));
      expect(icone(tester), Icons.info_outline);
    });

    testWidgets('une icone donnee remplace celle du type', (tester) async {
      await monter(tester, appli(const WinAlert('Hors ligne', type: BadgeColor.neutral, icon: Icons.wifi_off_outlined)));
      expect(icone(tester), Icons.wifi_off_outlined);
    });
  });

  group('WinStreakFlame', () {
    Color? couleur(WidgetTester tester) => tester.widget<Icon>(find.byType(Icon)).color;

    testWidgets('affiche le nombre de jours', (tester) async {
      await monter(tester, appli(const WinStreakFlame(12)));
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('serie nulle : flamme grise ; serie en cours : couleur de marque', (tester) async {
      await monter(tester, appli(const WinStreakFlame(0)));
      expect(couleur(tester), WinColors.ink300);
      await monter(tester, appli(const WinStreakFlame(3)));
      expect(couleur(tester), WinScheme.light.primary);
      await monter(tester, appli(const WinStreakFlame(3, light: true)));
      expect(couleur(tester), WinColors.teal400);
    });
  });

  group('WinDivider', () {
    testWidgets('sans libelle : un seul trait', (tester) async {
      await monter(tester, appli(const WinDivider()));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('avec libelle : deux traits autour du texte', (tester) async {
      await monter(tester, appli(const WinDivider(label: 'ou')));
      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('ou'), findsOneWidget);
    });
  });

  group('WinSectionHeader, WinStatCard, WinCircleIconButton', () {
    testWidgets('l\'en-tete affiche son action et la transmet au toucher', (tester) async {
      var appels = 0;
      await monter(tester, appli(SizedBox(width: 300, child: WinSectionHeader('Mes cours', action: 'Tout voir', onAction: () => appels++))));
      expect(find.text('Mes cours'), findsOneWidget);
      await tester.tap(find.text('Tout voir'));
      await pomper(tester);
      expect(appels, 1);
    });

    testWidgets('l\'en-tete sans action n\'affiche que le titre', (tester) async {
      await monter(tester, appli(const SizedBox(width: 300, child: WinSectionHeader('Mes cours'))));
      expect(find.text('Mes cours'), findsOneWidget);
      expect(find.descendant(of: find.byType(WinSectionHeader), matching: find.byType(GestureDetector)), findsNothing);
    });

    testWidgets('la carte de statistique affiche valeur, libelle et icone facultative', (tester) async {
      await monter(tester, appli(const WinStatCard('14,5', 'Moyenne', icon: Icons.school)));
      expect(find.text('14,5'), findsOneWidget);
      expect(find.text('Moyenne'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
      await monter(tester, appli(const WinStatCard('3', 'Quiz')));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('le bouton rond transmet le toucher', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinCircleIconButton(icon: Icons.share, onTap: () => appels++)));
      await tester.tap(find.byIcon(Icons.share));
      await pomper(tester);
      expect(appels, 1);
    });
  });

  group('WinTextField', () {
    testWidgets('affiche libelle, indication et prefixe, sans icone a gauche', (tester) async {
      await monter(tester, appli(const WinTextField(label: 'Telephone', hint: '6XX XXX XXX', prefix: '+237', icon: Icons.phone)));
      expect(find.text('Telephone'), findsOneWidget);
      expect(find.text('6XX XXX XXX'), findsOneWidget);
      expect(find.text('+237'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsNothing);
    });

    testWidgets('la saisie alimente le controleur et onChanged', (tester) async {
      final ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      final recus = <String>[];
      await monter(tester, appli(WinTextField(controller: ctrl, onChanged: recus.add)));
      await tester.enterText(find.byType(TextField), 'bonjour');
      await pomper(tester);
      expect(ctrl.text, 'bonjour');
      expect(recus, ['bonjour']);
    });

    testWidgets('mode mot de passe : texte masque, et l\'icone de fin est tactile', (tester) async {
      var appels = 0;
      await monter(tester, appli(WinTextField(obscure: true, suffixIcon: Icons.visibility, onSuffixTap: () => appels++)));
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
      await tester.tap(find.byIcon(Icons.visibility));
      await pomper(tester);
      expect(appels, 1);
    });

    testWidgets('par defaut le texte n\'est pas masque', (tester) async {
      await monter(tester, appli(const WinTextField()));
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    });
  });
}
