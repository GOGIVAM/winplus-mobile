import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/shared/help_screen.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

/// Lot 7 : « Aide et contact » (questions fréquentes, e-mail au support).
void main() {
  final origine = HelpScreen.mailer;
  late List<Uri> ouverts;
  late bool reussite;

  setUp(() {
    preparerEnvironnement(prefs: {'user_email': 'zoe@exemple.cm', 'user_role': 'student'});
    ouverts = [];
    reussite = true;
    HelpScreen.mailer = (uri) async {
      ouverts.add(uri);
      return reussite;
    };
  });
  tearDown(() => HelpScreen.mailer = origine);

  testWidgets('questions frequentes : un panneau s\'ouvre, puis se referme', (tester) async {
    await monterEcran(tester, const HelpScreen());
    final l = L10n.current;
    expect(find.text(l.helpQ1), findsOneWidget);
    expect(find.text(l.helpA1), findsNothing);
    await tester.tap(find.text(l.helpQ1));
    await pomper(tester);
    expect(find.text(l.helpA1), findsOneWidget);
    await tester.tap(find.text(l.helpQ1));
    await pomper(tester);
    expect(find.text(l.helpA1), findsNothing);
  });

  testWidgets('ecrire au support : e-mail prerempli avec le compte et le profil', (tester) async {
    await monterEcran(tester, const HelpScreen());
    final l = L10n.current;
    final bouton = find.text(l.helpWriteButton);
    await tester.ensureVisible(bouton);
    await pomper(tester);
    await tester.tap(bouton);
    await reseau(tester);
    final uri = ouverts.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'support@winplus.cm');
    expect(uri.query, contains('subject=${Uri.encodeComponent(l.helpMailSubject)}'));
    expect(Uri.decodeComponent(uri.query), contains('zoe@exemple.cm'));
    expect(Uri.decodeComponent(uri.query), contains('student'));
    expect(find.text(l.helpNoMailApp), findsNothing);
  });

  testWidgets('aucune application e-mail : l\'adresse et « Copier »', (tester) async {
    reussite = false;
    await monterEcran(tester, const HelpScreen());
    String? copie;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copie = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final l = L10n.current;
    final bouton = find.text(l.helpWriteButton);
    await tester.ensureVisible(bouton);
    await pomper(tester);
    await tester.tap(bouton);
    await reseau(tester);
    expect(find.text(l.helpNoMailApp), findsOneWidget);
    final copier = find.text(l.helpCopy);
    await tester.ensureVisible(copier);
    await pomper(tester);
    await tester.tap(copier);
    await reseau(tester);
    expect(copie, 'support@winplus.cm');
    expect(find.text(l.helpCopied), findsOneWidget);
  });
}
