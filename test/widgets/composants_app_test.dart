import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winplus/app_state.dart';
import 'package:winplus/l10n/l10n.dart';
import 'package:winplus/services/chatbot_service.dart';
import 'package:winplus/widgets/knowledge_base_toggle.dart';
import 'package:winplus/widgets/language_selector.dart';
import 'package:winplus/widgets/offline_banner.dart';
import 'package:winplus/widgets/win_widgets.dart';

import '../helpers/appli.dart';
import '../helpers/faux_reseau.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void main() {
  setUpAll(initialiserDates);
  setUp(() {
    preparerEnvironnement();
    ChatbotService.instance.knowledgeBase.value = false;
  });
  tearDown(() {
    L10n.locale = const Locale('fr');
    ChatbotService.instance.knowledgeBase.value = false;
  });

  group('OfflineBanner', () {
    testWidgets('sans date connue, indique « inconnue »', (tester) async {
      await monter(tester, appli(const SizedBox(width: 400, child: OfflineBanner(updatedAt: null))));
      final attendu = L10n.current.widgetOfflineBanner(L10n.current.widgetOfflineUnknown);
      expect(find.text(attendu), findsOneWidget);
      expect(attendu, contains('inconnue'));
      expect(find.byIcon(PhosphorIconsRegular.wifiSlash), findsOneWidget);
    });

    testWidgets('avec une date, affiche le jour et l\'heure de la derniere mise a jour', (tester) async {
      await monter(tester, appli(SizedBox(width: 400, child: OfflineBanner(updatedAt: DateTime(2026, 1, 5, 14, 5)))));
      expect(find.textContaining('5 janvier à 14:05'), findsOneWidget);
    });

    testWidgets('la banniere est une alerte neutre', (tester) async {
      await monter(tester, appli(const SizedBox(width: 400, child: OfflineBanner(updatedAt: null))));
      expect(find.byType(WinAlert), findsOneWidget);
      expect(tester.widget<WinAlert>(find.byType(WinAlert)).type, BadgeColor.neutral);
    });
  });

  group('LanguageToggle', () {
    testWidgets('propose FR et EN', (tester) async {
      await monter(tester, appli(const LanguageToggle()));
      expect(find.text('FR'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('toucher EN change la langue de l\'application et la memorise', (tester) async {
      final etat = WinAppState();
      await monter(tester, appli(const LanguageToggle(), etat: etat));
      expect(etat.locale.languageCode, 'fr');
      await tester.tap(find.text('EN'));
      await pomper(tester);
      expect(etat.locale.languageCode, 'en');
      expect(L10n.isEn, isTrue);
      await tester.runAsync(laisserFinir);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(prefs!.getString(kLocalePrefKey), 'en');
    });

    testWidgets('toucher FR depuis l\'anglais revient au francais', (tester) async {
      final etat = WinAppState();
      await tester.runAsync(() => etat.setLocale('en'));
      await monter(tester, appli(const LanguageToggle(), etat: etat));
      await tester.tap(find.text('FR'));
      await pomper(tester);
      expect(etat.locale.languageCode, 'fr');
      expect(L10n.isEn, isFalse);
    });
  });

  group('KnowledgeBaseToggle', () {
    testWidgets('desactive par defaut : le texte explique le surcout et l\'interrupteur est eteint', (tester) async {
      await monter(tester, appli(const SizedBox(width: 400, child: KnowledgeBaseToggle())));
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.textContaining('désactivée', findRichText: true), findsOneWidget);
      expect(find.textContaining(L10n.current.widgetKbTitle, findRichText: true), findsOneWidget);
    });

    testWidgets('toucher l\'interrupteur active le mode partage par tous les ecrans de chat', (tester) async {
      await monter(tester, appli(const SizedBox(width: 400, child: KnowledgeBaseToggle())));
      await tester.tap(find.byType(Switch));
      await pomper(tester);
      expect(ChatbotService.instance.knowledgeBase.value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.textContaining('activée : chaque message', findRichText: true), findsOneWidget);
    });

    testWidgets('un changement venu d\'ailleurs est reflete dans l\'interrupteur', (tester) async {
      await monter(tester, appli(const SizedBox(width: 400, child: KnowledgeBaseToggle())));
      ChatbotService.instance.knowledgeBase.value = true;
      await pomper(tester);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });
  });
}
