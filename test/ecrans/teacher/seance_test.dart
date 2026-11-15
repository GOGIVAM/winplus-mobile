import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/teacher/session_create_screen.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../../helpers/ecran.dart';
import '../../helpers/faux_reseau.dart';

Finder _creer() => find.widgetWithText(WinButton, L10n.current.teacherSessionCreateButton);

void main() {
  late FauxReseau faux;

  setUp(() => faux = preparerEnvironnement());

  testWidgets('formulaire : trois champs, duree 60 min et 30 places par defaut', (tester) async {
    await monterEcran(tester, const SessionCreateScreen());
    final l = L10n.current;
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text(l.teacherSessionDuration(60)), findsOneWidget);
    expect(find.text(l.teacherSessionMaxStudents(30)), findsOneWidget);
    expect(find.text(l.teacherSession30Min), findsOneWidget);
    expect(find.text(l.teacherSession3h), findsOneWidget);
  });

  testWidgets('titre vide : rien n\'est envoye', (tester) async {
    await monterEcran(tester, const SessionCreateScreen());
    await tester.ensureVisible(_creer());
    await tester.tap(_creer());
    await reseau(tester);
    expect(faux.requetes, isEmpty);
  });

  testWidgets('les curseurs modifient la duree et le nombre de places', (tester) async {
    await monterEcran(tester, const SessionCreateScreen());
    final curseurs = find.byType(Slider);
    expect(curseurs, findsNWidgets(2));
    final duree = tester.widget<Slider>(curseurs.at(0));
    duree.onChanged!(90);
    await pomper(tester);
    expect(find.text(L10n.current.teacherSessionDuration(90)), findsOneWidget);
    tester.widget<Slider>(curseurs.at(1)).onChanged!(50);
    await pomper(tester);
    expect(find.text(L10n.current.teacherSessionMaxStudents(50)), findsOneWidget);
  });

  testWidgets('creation reussie : envoi des valeurs puis ecran de confirmation', (tester) async {
    faux.repond('POST', '/sessions', {});
    await monterEcran(tester, const SessionCreateScreen());
    await tester.enterText(find.byType(TextField).at(0), '  Revision BAC ');
    await tester.enterText(find.byType(TextField).at(1), '2026-04-01T09:00:00');
    await tester.enterText(find.byType(TextField).at(2), 'https://meet.x/abc');
    await tester.ensureVisible(_creer());
    await tester.tap(_creer());
    await reseau(tester);
    final d = faux.recues('POST', '/sessions').single.data as Map;
    expect(d['title'], 'Revision BAC');
    expect(d['startDate'], '2026-04-01T09:00:00.000');
    expect(d['externalLink'], 'https://meet.x/abc');
    expect(d['durationMinutes'], 60);
    expect(d['maxParticipants'], 30);
    expect(find.text(L10n.current.teacherSessionCreated), findsOneWidget);
  });

  testWidgets('echec serveur : message d\'erreur, le formulaire reste', (tester) async {
    faux.repond('POST', '/sessions', {}, statut: 500);
    await monterEcran(tester, const SessionCreateScreen());
    await tester.enterText(find.byType(TextField).at(0), 'Revision');
    await tester.ensureVisible(_creer());
    await tester.tap(_creer());
    await reseau(tester);
    expect(find.text(L10n.current.teacherSessionCreateError), findsOneWidget);
    expect(find.text(L10n.current.teacherSessionCreated), findsNothing);
  });
}
