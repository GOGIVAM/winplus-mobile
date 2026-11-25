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
  late FauxReseau faux;
  late List<Uri> ouverts;
  late bool reussite;

  setUp(() {
    faux = preparerEnvironnement(prefs: {'user_email': 'zoe@exemple.cm', 'user_role': 'student', 'user_name': 'Zoe Eto'});
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

  // Champs dans l'ordre : nom, e-mail, sujet, message.
  Future<void> remplir(WidgetTester tester, {String sujet = 'Paiement bloque', String message = 'Mon paiement Mobile Money ne passe pas.'}) async {
    await tester.enterText(find.byType(TextField).at(2), sujet);
    await tester.enterText(find.byType(TextField).at(3), message);
  }

  Future<void> envoyer(WidgetTester tester) async {
    final bouton = find.text(L10n.current.commonSend);
    await tester.ensureVisible(bouton);
    await pomper(tester);
    await tester.tap(bouton);
    await reseau(tester);
  }

  testWidgets('formulaire : nom et e-mail du compte deja remplis, envoi puis confirmation dans l\'ecran', (tester) async {
    faux.repond('POST', '/support/contact', {'success': true, 'id': 7}, statut: 201);
    await monterEcran(tester, const HelpScreen());
    final l = L10n.current;
    expect(find.text('Zoe Eto'), findsOneWidget);
    expect(find.text('zoe@exemple.cm'), findsWidgets);
    await remplir(tester);
    await envoyer(tester);
    final d = faux.recues('POST', '/support/contact').single.data as Map;
    expect(d['name'], 'Zoe Eto');
    expect(d['email'], 'zoe@exemple.cm');
    expect(d['subject'], 'Paiement bloque');
    expect(d['source'], 'mobile');
    expect(d.containsKey('website'), isFalse);
    expect(find.text(l.helpSentTitle), findsOneWidget);
  });

  testWidgets('formulaire incomplet : erreurs sous les champs, rien n\'est envoye', (tester) async {
    await monterEcran(tester, const HelpScreen());
    final l = L10n.current;
    await remplir(tester, sujet: 'a', message: 'court');
    await envoyer(tester);
    expect(faux.recues('POST', '/support/contact'), isEmpty);
    expect(find.text(l.helpErrSubject), findsOneWidget);
    expect(find.text(l.helpErrMessage), findsOneWidget);
  });

  testWidgets('refus du serveur : erreurs par champ (400), trop d\'envois (429), route absente (404)', (tester) async {
    final l = L10n.current;
    faux.repond('POST', '/support/contact', {'errors': {'Email': ['Adresse refusee par le serveur.']}}, statut: 400);
    await monterEcran(tester, const HelpScreen());
    await remplir(tester);
    await envoyer(tester);
    expect(find.text('Adresse refusee par le serveur.'), findsOneWidget);

    faux.repond('POST', '/support/contact', {'error': 'x'}, statut: 429);
    await envoyer(tester);
    expect(find.text(l.helpTooMany), findsOneWidget);

    faux.repond('POST', '/support/contact', {'error': 'x'}, statut: 404);
    await envoyer(tester);
    expect(find.text(l.helpUnavailable), findsOneWidget);
    expect(find.text(l.helpSentTitle), findsNothing);
  });
}
