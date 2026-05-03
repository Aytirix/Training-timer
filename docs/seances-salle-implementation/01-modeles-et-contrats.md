# 01 - Modeles et contrats de donnees

## Objectif

Creer les modeles metier qui serviront de base a toute la fonctionnalite `Seances`.

Cette etape doit etre faite avant l'interface. Le but est d'avoir des objets clairs, testables et stables.

## Donnees a modeliser

### Exercise

Exercice global reutilisable.

Champs attendus :

- `id` interne ;
- `name` ;
- `normalizedName` ou helper de normalisation ;
- `type` ;
- `instructions` ;
- `video` optionnelle ;
- dates optionnelles si le projet les utilise plus tard.

Types possibles :

- `poids_repetitions` ;
- `repetitions` ;
- `duree` ;
- `poids_duree`.

Regles :

- deux exercices sont fonctionnellement identiques si `nom normalise + type` correspond ;
- les accents, majuscules et espaces multiples sont ignores pour la comparaison ;
- le poids est toujours en kilogrammes.

### ExerciseVideo

Video rattachee a un exercice.

Champs attendus :

- `source` : `localFile`, `directUrl`, `youtube`, `platformLink` ;
- `url` optionnelle ;
- `localPath` optionnel ;
- `originalFileName` optionnel ;
- metadonnees minimales si utiles.

Regles :

- une video locale est copiee dans le stockage de l'application ;
- YouTube est lu via player officiel si possible ;
- Instagram/TikTok/autres plateformes sont ouvertes via webview ou app externe ;
- pas de telechargement automatique depuis les plateformes.

### GymSession

Seance de salle.

Champs attendus :

- `id` interne ;
- `name` ;
- `description` ;
- `items`.

Regles :

- pas de video au niveau de la seance ;
- une seance peut contenir plusieurs fois le meme exercice global ;
- l'ordre des items est important.

### GymSessionItem

Item de seance.

Variantes :

- exercice configure dans la seance ;
- repos entre exercices.

Format logique :

- `exercise` : contient `exerciseId`, `sets`, `timedSetStartMode` ;
- `rest` : contient `durationSeconds`.

Regles :

- le repos entre exercices est affiche entre deux cartes ;
- si on deplace un exercice, le repos suit l'exercice precedent ;
- un repos vide n'affiche pas d'ecran de repos pendant l'execution.

### GymSet

Serie configuree pour un exercice dans une seance.

Champs selon type :

- `weightKg` pour `poids_repetitions` et `poids_duree` ;
- `repetitions` pour `poids_repetitions` et `repetitions` ;
- `durationSeconds` pour `duree` et `poids_duree` ;
- `restAfterSetSeconds` optionnel.

Regles :

- aucune valeur metier par defaut obligatoire ;
- une serie incomplete peut exister pendant l'edition si l'UI en a besoin ;
- la validation bloque l'enregistrement ou le lancement si les champs obligatoires sont absents ;
- `restAfterSetSeconds` est vide sur la derniere serie ou ignore pendant l'execution.

### TimedSetStartMode

Pour les series en duree :

- `manual` ;
- `automatic`.

## Fichiers probables

Les noms exacts peuvent etre adaptes au style existant du projet.

- `lib/core/models/gym_exercise.dart`
- `lib/core/models/gym_session.dart`
- `lib/core/models/gym_session_item.dart`
- `lib/core/models/gym_set.dart`
- `lib/core/models/exercise_video.dart`
- `lib/core/services/exercise_name_normalizer.dart`

## Tests a ajouter

Tests unitaires :

- normalisation des noms avec accents, majuscules et espaces ;
- egalite fonctionnelle `nom normalise + type` ;
- validation des champs obligatoires par type ;
- serialization/deserialization JSON interne si les modeles l'exposent ;
- validation d'une seance vide ;
- validation d'une seance avec serie incomplete ;
- validation d'une seance valide.

Fichiers probables :

- `test/gym_exercise_model_test.dart`
- `test/gym_session_model_test.dart`
- `test/exercise_name_normalizer_test.dart`

## Criteres d'acceptation

- [ ] Les modeles representent tous les cas valides.
- [ ] Les modeles refusent ou signalent les cas invalides.
- [ ] Les types d'exercice sont strictement enumeres.
- [ ] La comparaison `nom + type` est testee.
- [ ] Les tests unitaires passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer au stockage tant que :

- les modeles ne sont pas stables ;
- les tests de validation ne passent pas ;
- le format interne n'est pas coherent avec le JSON prevu.
