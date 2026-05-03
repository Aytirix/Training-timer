# Implementation - Seances de salle

Ce dossier decrit le plan d'implementation de la fonctionnalite `Seances`.

Le document de cadrage source est : [`../seances-salle-cadrage.md`](../seances-salle-cadrage.md).

## Regle de travail obligatoire

On avance fonctionnalite par fonctionnalite.

Avant de passer a l'etape suivante :

- le code de l'etape courante doit etre termine ;
- les tests prevus pour l'etape doivent etre ajoutes ou adaptes ;
- `flutter analyze` doit passer ;
- les tests Flutter/Dart doivent passer ;
- la fonctionnalite doit etre verifiee manuellement quand elle touche l'interface ;
- les criteres d'acceptation de l'etape doivent etre coches.

Si une etape ne passe pas, on corrige avant de continuer.

## Ordre d'implementation

1. [Modeles et contrats de donnees](./01-modeles-et-contrats.md)
2. [Stockage local et migrations](./02-stockage-local.md)
3. [Bibliotheque globale d'exercices](./03-bibliotheque-exercices.md)
4. [Creation et modification de seances](./04-editeur-seances.md)
5. [Import et export JSON](./05-import-export-json.md)
6. [Execution d'une seance](./06-execution-seance.md)
7. [Videos d'exercices](./07-videos-exercices.md)
8. [Validation finale et recette](./08-validation-finale.md)

## Commandes de verification

Commandes a lancer regulierement :

```bash
make app-analyze
make app-test
make check
```

Si le `Makefile` n'est pas disponible dans un contexte donne, utiliser les equivalents Flutter :

```bash
flutter analyze
flutter test
```

## Definition globale de fini

La fonctionnalite complete est terminee quand on peut :

- ouvrir l'onglet `Seances` ;
- ouvrir l'ecran dedie `Exercices` ;
- creer, modifier et supprimer des exercices globaux ;
- creer et modifier une seance ;
- ajouter plusieurs fois le meme exercice dans une seance ;
- reordonner les exercices par glisser-deposer ;
- configurer les series selon le type d'exercice ;
- configurer les repos apres chaque serie ;
- configurer les repos entre exercices ;
- importer une seance depuis un JSON portable ;
- exporter une seance en JSON portable ;
- lancer une seance ;
- valider ou passer chaque serie ;
- afficher les instructions et la video/lien de l'exercice courant ;
- entendre ou voir une alerte a la fin des repos ;
- sauvegarder les donnees localement ;
- passer tous les tests.

## Decisions produit importantes

- Onglet 1 : `Minuteurs`.
- Onglet 2 : `Seances`.
- Une seance n'a pas de video.
- Les videos sont uniquement sur les exercices.
- Les exercices sont globaux et reutilisables.
- Modifier un exercice global met a jour toutes les seances qui l'utilisent.
- Une seance ne surcharge pas localement les instructions ou la video d'un exercice.
- Un exercice est identifie fonctionnellement par `nom normalise + type`.
- Les noms sont compares sans majuscules, accents ni espaces en trop.
- Le JSON exporte des donnees portables, sans IDs internes.
- Les champs JSON inconnus sont ignores.
- Les champs obligatoires manquants ou invalides bloquent l'import.
- Les poids sont toujours en kilogrammes.
- Les types d'exercice sont `poids_repetitions`, `repetitions`, `duree`, `poids_duree`.
- Les repos entre series sont stockes sur chaque serie avec `restAfterSetSeconds`.
- Les repos entre exercices sont des items separes dans la seance.
- Un repos vide passe directement a la suite.
- Une seance en cours n'est pas reprise si l'utilisateur quitte.
- Les valeurs realisees ne sont pas modifiables pendant l'execution.
- YouTube est integre via player/API officielle si possible.
- Instagram/TikTok/autres plateformes sont ouvertes via vue web ou application externe.
- Pas de telechargement automatique des videos de plateformes.

## Suivi d'avancement

- [ ] 01 - Modeles et contrats de donnees
- [ ] 02 - Stockage local et migrations
- [ ] 03 - Bibliotheque globale d'exercices
- [ ] 04 - Creation et modification de seances
- [ ] 05 - Import et export JSON
- [ ] 06 - Execution d'une seance
- [ ] 07 - Videos d'exercices
- [ ] 08 - Validation finale et recette
