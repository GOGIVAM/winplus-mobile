import 'package:flutter/material.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

enum LegalDoc { cgu, confidentialite }

class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  static Future<void> showCgu(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LegalScreen(doc: LegalDoc.cgu)),
      );

  static Future<void> showPrivacy(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LegalScreen(doc: LegalDoc.confidentialite)),
      );

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final isCgu = doc == LegalDoc.cgu;

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCgu ? 'Conditions Générales d\'Utilisation' : 'Politique de Confidentialité',
          style: WinType.headlineS(s.onStrong),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: isCgu ? _cguSections(s) : _privacySections(s),
      ),
    );
  }

  List<Widget> _cguSections(WinScheme s) => [
    _meta(s, 'Dernière mise à jour : 1er juin 2025'),
    _section(s, '1. Objet',
        'Les présentes Conditions Générales d\'Utilisation (CGU) régissent l\'accès et '
        'l\'utilisation de la plateforme WinPlus, application mobile éducative destinée '
        'aux élèves, parents et enseignants du système scolaire camerounais.'),
    _section(s, '2. Accès à la plateforme',
        'L\'accès à WinPlus est ouvert à toute personne disposant d\'un appareil compatible '
        'et d\'une connexion internet. Certaines fonctionnalités nécessitent la création d\'un '
        'compte. L\'inscription est gratuite pour le plan de base.'),
    _section(s, '3. Comptes utilisateurs',
        'Vous êtes responsable de la confidentialité de vos identifiants. Toute activité '
        'effectuée depuis votre compte vous est attribuée. En cas de compromission, '
        'contactez-nous immédiatement à support@winplus.cm.'),
    _section(s, '4. Contenu et propriété intellectuelle',
        'Les contenus publiés sur WinPlus (épreuves, corrections, quiz) sont protégés par '
        'le droit d\'auteur. Leur reproduction, redistribution ou revente sans autorisation '
        'est strictement interdite.'),
    _section(s, '5. Abonnements et paiements',
        'Les plans payants (Starter, Expert, Institution) sont facturés mensuellement via '
        'Mobile Money (MTN MoMo, Orange Money) ou carte bancaire. Les tarifs sont affichés '
        'en francs CFA (XAF) et peuvent évoluer avec préavis de 30 jours.'),
    _section(s, '6. Résiliation',
        'Vous pouvez résilier votre abonnement à tout moment depuis votre profil. '
        'La résiliation prend effet à la fin de la période de facturation en cours. '
        'Aucun remboursement partiel n\'est accordé.'),
    _section(s, '7. Responsabilité',
        'WinPlus s\'efforce de maintenir la plateforme disponible 24h/24, mais ne saurait '
        'être tenue responsable des interruptions de service, pertes de données ou '
        'inexactitudes dans les contenus.'),
    _section(s, '8. Droit applicable',
        'Les présentes CGU sont soumises au droit camerounais. Tout litige sera porté '
        'devant les juridictions compétentes de Yaoundé, Cameroun.'),
    _contact(s),
  ];

  List<Widget> _privacySections(WinScheme s) => [
    _meta(s, 'Dernière mise à jour : 1er juin 2025'),
    _section(s, '1. Données collectées',
        'WinPlus collecte les données suivantes :\n'
        '• Données d\'identification : nom, prénom, adresse e-mail\n'
        '• Données de navigation : contenus consultés, résultats de quiz\n'
        '• Données de paiement : transmises directement à nos prestataires (MTN, Orange)\n'
        '• Données d\'appareil : modèle, système d\'exploitation, identifiant publicitaire'),
    _section(s, '2. Finalités du traitement',
        'Vos données sont utilisées pour :\n'
        '• Fournir et personnaliser les services WinPlus\n'
        '• Générer des recommandations pédagogiques via WinAI\n'
        '• Traiter vos paiements et gérer votre abonnement\n'
        '• Améliorer la plateforme via des analyses agrégées anonymisées'),
    _section(s, '3. Base légale',
        'Le traitement repose sur votre consentement (art. 4 loi n° 2010/012 du Cameroun '
        'sur les communications électroniques) et sur l\'exécution du contrat de service '
        'que représentent les présentes CGU.'),
    _section(s, '4. Conservation des données',
        'Vos données sont conservées pendant la durée de votre relation contractuelle avec '
        'WinPlus, augmentée de 3 ans à des fins de preuve. Les données de navigation sont '
        'anonymisées après 13 mois.'),
    _section(s, '5. Partage des données',
        'WinPlus ne vend pas vos données. Elles peuvent être partagées avec :\n'
        '• Nos hébergeurs (serveurs sécurisés en Europe)\n'
        '• Nos prestataires de paiement (MTN, Orange, Stripe)\n'
        '• Les autorités compétentes en cas d\'obligation légale'),
    _section(s, '6. Vos droits',
        'Conformément à la législation applicable, vous disposez des droits d\'accès, '
        'de rectification, d\'effacement, de portabilité et d\'opposition. '
        'Exercez-les en écrivant à privacy@winplus.cm.'),
    _section(s, '7. Cookies et traceurs',
        'L\'application utilise des identifiants anonymes pour mesurer les performances '
        'et améliorer l\'expérience utilisateur. Vous pouvez les désactiver dans les '
        'paramètres de votre appareil.'),
    _contact(s),
  ];

  Widget _meta(WinScheme s, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(text, style: WinType.labelM(s.onMuted)),
  );

  Widget _section(WinScheme s, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: WinType.archivo(size: 15, color: s.onStrong)),
        const SizedBox(height: 8),
        Text(body, style: WinType.bodyS(s.onMuted)),
      ]),
    ),
  );

  Widget _contact(WinScheme s) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Contact', style: WinType.archivo(size: 15, color: s.onStrong)),
        const SizedBox(height: 8),
        Text('Pour toute question : support@winplus.cm\nWinPlus SAS — Yaoundé, Cameroun',
            style: WinType.bodyS(s.onMuted)),
      ]),
    ),
  );
}
