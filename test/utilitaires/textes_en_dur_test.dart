import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou du lot 5 : aucun texte affiché n'est écrit en dur dans le code.
///
/// Tout texte visible passe par lib/l10n/app_fr.arb et app_en.arb. Ce test
/// relève chaque chaîne accentuée de lib/ (hors l10n et commentaires) et
/// échoue si elle n'est pas une valeur technique connue : valeur envoyée au
/// serveur ou reçue de lui (matières, niveaux, statuts), dont le libellé
/// affiché est déjà traduit à côté.
///
/// Si ce test échoue : mettez le texte dans les fichiers de langue. S'il
/// s'agit vraiment d'une valeur échangée avec le serveur, ajoutez-la à
/// [_valeursTechniques] en disant pourquoi.
const _valeursTechniques = <String>{
  // Niveaux scolaires et concours, enregistrés tels quels côté serveur.
  '6ème', '5ème', '4ème', '3ème', 'Première', 'Prépa', 'FMSB Médecine',
  'ENS École Normale', 'Littéraire', 'Économique',
  // Matières, enregistrées en français côté serveur.
  'Mathématiques', 'Français', 'français', 'Histoire-Géo', 'Hist-Géo',
  'Économie',
  // Spécialités et style pédagogique du répétiteur (valeurs enregistrées).
  'Préparation concours', 'Structuré',
  // Ville proposée pour les zones d'intervention (nom propre).
  'Yaoundé',
  // Statuts et types de contenu renvoyés par le serveur.
  'Publié', 'En révision', 'Corrigé', 'Modéré', 'Épreuve', 'Épreuves',
  'épreuve', 'débutant', 'intermédiaire', 'avancé',
  // Étiquettes personnelles mémorisées sur le téléphone (clé de stockage).
  'À réviser', 'Maîtrisé', 'À acheter',
  // Profils : valeurs historiques de RoleInfo, libellés affichés traduits.
  'Étudiant / Apprenant', 'Du BEPC aux concours des grandes écoles',
  'Lycée, université ou centre de formation',
  // Journaux de diagnostic (jamais affichés).
  'Service de notifications non démarré : \$e',
  'Tâche périodique non enregistrée : \$e',
  'Vérification des notifications : \$e',
  'HttpCache : réponse non gardée (\$e)',
};

final _chaine = RegExp(
    r"""(['"])((?:\\.|(?!\1).)*?[àâäéèêëîïôöùûüçœÀÂÉÈÊÎÔÙÛÇ](?:\\.|(?!\1).)*?)\1""");

void main() {
  test('aucun texte accentue ecrit en dur hors des fichiers de langue', () {
    final fautes = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final chemin = f.path.replaceAll('\\', '/');
      if (chemin.contains('/l10n/')) continue;
      final lignes = f.readAsLinesSync();
      for (var i = 0; i < lignes.length; i++) {
        final l = lignes[i].trim();
        if (l.startsWith('//') || l.startsWith('*')) continue;
        for (final m in _chaine.allMatches(lignes[i])) {
          final texte = m.group(2)!;
          if (!_valeursTechniques.contains(texte)) {
            fautes.add('$chemin:${i + 1} : « $texte »');
          }
        }
      }
    }
    expect(fautes, isEmpty,
        reason: 'Textes à déplacer dans lib/l10n/app_fr.arb et app_en.arb :\n${fautes.join('\n')}');
  });
}
