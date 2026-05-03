# 08 - Validation finale et recette

## Objectif

Verifier toute la fonctionnalite de bout en bout avant de considerer l'implementation terminee.

## Checklist technique

- [ ] `make app-analyze` passe.
- [ ] `make app-test` passe.
- [ ] `make check` passe.
- [ ] Aucun test existant n'est casse.
- [ ] Les nouveaux tests couvrent les modeles.
- [ ] Les nouveaux tests couvrent le stockage.
- [ ] Les nouveaux tests couvrent l'import/export JSON.
- [ ] Les nouveaux tests couvrent le moteur d'execution.
- [ ] Les widgets principaux ont au moins des tests de rendu/validation.

## Checklist navigation

- [ ] L'app demarre.
- [ ] L'onglet `Minuteurs` affiche l'existant.
- [ ] Les minuteurs existants fonctionnent toujours.
- [ ] L'onglet `Seances` est accessible.
- [ ] L'ecran `Exercices` est accessible.

## Checklist bibliotheque exercices

- [ ] Creer un exercice `poids_repetitions`.
- [ ] Creer un exercice `repetitions`.
- [ ] Creer un exercice `duree`.
- [ ] Creer un exercice `poids_duree`.
- [ ] Modifier les instructions d'un exercice.
- [ ] Verifier que la modification est visible dans les seances qui l'utilisent.
- [ ] Bloquer un doublon `nom normalise + type`.
- [ ] Autoriser meme nom avec type different.
- [ ] Supprimer un exercice non utilise.
- [ ] Supprimer un exercice utilise avec confirmation et nettoyage des seances.

## Checklist editeur de seances

- [ ] Creer une seance.
- [ ] Modifier une seance.
- [ ] Ajouter un exercice existant.
- [ ] Ajouter plusieurs fois le meme exercice.
- [ ] Configurer des series `poids_repetitions`.
- [ ] Configurer des series `repetitions`.
- [ ] Configurer des series `duree`.
- [ ] Configurer des series `poids_duree`.
- [ ] Configurer un repos apres serie.
- [ ] Configurer un repos entre exercices.
- [ ] Reordonner les exercices.
- [ ] Verifier que le repos suit l'exercice precedent.
- [ ] Dupliquer une seance.
- [ ] Supprimer une seance.

## Checklist JSON

- [ ] Importer un JSON valide.
- [ ] Creer automatiquement les exercices manquants.
- [ ] Detecter les exercices existants.
- [ ] Gerer un conflit instructions/video action par action.
- [ ] Ignorer les champs inconnus.
- [ ] Bloquer un JSON sans champ obligatoire.
- [ ] Bloquer une serie incomplete.
- [ ] Exporter une seance.
- [ ] Reimporter l'export.
- [ ] Verifier que l'export ne contient pas d'IDs internes.

## Checklist execution

- [ ] Lancer une seance valide.
- [ ] Bloquer une seance invalide avec message clair.
- [ ] Valider une serie en repetitions.
- [ ] Valider une serie poids + repetitions.
- [ ] Lancer une serie en duree automatique.
- [ ] Lancer une serie en duree manuelle.
- [ ] Passer une serie avant la fin.
- [ ] Pause/reprise.
- [ ] Precedent.
- [ ] Passer.
- [ ] Arret.
- [ ] Repos entre series.
- [ ] Repos entre exercices.
- [ ] Repos vide passe directement a la suite.
- [ ] Fin de seance.

## Checklist videos

- [ ] Ajouter une video locale.
- [ ] Lire une video locale.
- [ ] Supprimer une video locale.
- [ ] Ajouter une URL directe lisible.
- [ ] Bloquer une URL directe invalide.
- [ ] Ajouter une URL YouTube.
- [ ] Afficher YouTube via player officiel si possible.
- [ ] Ajouter une URL Instagram/TikTok.
- [ ] Ouvrir Instagram/TikTok en vue web ou externe.
- [ ] Verifier qu'aucune plateforme n'est telechargee automatiquement.

## Scenarios de recette

### Scenario 1 - Creation manuelle complete

1. Creer quatre exercices, un par type.
2. Creer une seance.
3. Ajouter les quatre exercices.
4. Configurer series et repos.
5. Sauvegarder.
6. Relancer l'application.
7. Verifier que la seance est toujours presente.
8. Lancer la seance.
9. Terminer la seance.

### Scenario 2 - Import JSON

1. Importer un JSON avec exercices nouveaux.
2. Verifier la creation automatique des exercices.
3. Modifier un exercice global.
4. Verifier que la seance importee affiche la modification.
5. Exporter la seance.
6. Reimporter l'export.

### Scenario 3 - Suppression impactante

1. Creer un exercice utilise dans deux seances.
2. Demander sa suppression.
3. Verifier que les deux seances impactees sont listees.
4. Confirmer.
5. Verifier que l'exercice est supprime.
6. Verifier qu'il est retire des deux seances.
7. Verifier que les seances invalides sont bloquees au lancement si elles n'ont plus d'exercice.

## Definition finale de fini

- [ ] Toutes les checklists sont validees.
- [ ] Les tests passent.
- [ ] L'analyse passe.
- [ ] Le comportement correspond au cadrage.
- [ ] Aucune regression visible sur les minuteurs existants.
