# 06 - Execution d'une seance

## Objectif

Permettre de lancer une seance de salle et de suivre les exercices, series et repos dans l'ordre.

## Validation avant lancement

Avant de lancer :

- verifier que la seance contient au moins un exercice ;
- verifier que chaque exercice contient au moins une serie ;
- verifier les valeurs obligatoires selon le type ;
- verifier les repos ;
- verifier les references vers exercices globaux ;
- afficher une alerte ou un ecran listant les problemes bloquants.

On ne lance pas une seance invalide.

## Generation de sequence

Transformer la seance en sequence executable :

- exercice courant ;
- serie courante ;
- repos apres serie si present et si pas derniere serie ;
- repos entre exercices si present ;
- fin de seance.

Regles :

- un repos vide passe directement a la suite ;
- `restAfterSetSeconds` de la derniere serie est ignore ou doit etre vide ;
- le repos entre exercices vient de l'item `rest`.

## Execution des exercices en repetitions

Types :

- `repetitions` ;
- `poids_repetitions`.

Comportement :

- l'utilisateur fait la serie ;
- il valide quand elle est terminee ;
- l'application lance le repos suivant si necessaire ;
- l'utilisateur peut passer a la suite.

## Execution des exercices en duree

Types :

- `duree` ;
- `poids_duree`.

Comportement :

- si `timedSetStartMode = automatic`, le chrono demarre quand on arrive sur la serie ;
- si `timedSetStartMode = manual`, l'utilisateur appuie sur demarrer ;
- l'utilisateur peut passer a la suite avant la fin ;
- l'utilisateur peut valider quand la serie est terminee.

## Controles

Conserver l'esprit des controles existants :

- pause ;
- reprise ;
- precedent ;
- passer ;
- arret.

Regles :

- quitter une seance ne sauvegarde pas l'etat pour reprise ;
- pas de modification des valeurs realisees pendant l'execution ;
- l'utilisateur ne doit jamais etre bloque par un chrono.

## Affichage pendant execution

Afficher :

- nom de la seance ;
- exercice courant ;
- type ;
- serie courante / total ;
- poids, repetitions ou duree selon type ;
- instructions de l'exercice ;
- video ou lien si disponible ;
- prochain repos ou prochaine etape.

## Alertes

Options globales utilisateur :

- bip active/desactive ;
- voix active/desactive.

Fin de repos :

- annoncer ou afficher que l'utilisateur doit repartir ;
- possible phrase : `Depart dans 10 secondes` ;
- bip ou annonce finale.

## Fichiers probables

- `lib/features/gym_execution/domain/gym_execution_engine.dart`
- `lib/features/gym_execution/domain/gym_execution_state.dart`
- `lib/features/gym_execution/application/gym_execution_provider.dart`
- `lib/features/gym_execution/presentation/active_gym_session_screen.dart`

Possibilite aussi de reutiliser des parties de `lib/features/timer`.

## Tests a ajouter

Tests unitaires :

- generation sequence simple ;
- generation avec repos entre series ;
- generation avec repos entre exercices ;
- pas de repos apres derniere serie ;
- repos vide ignore ;
- exercice duree automatique ;
- exercice duree manuel ;
- actions suivant, precedent, pause, reprise, passer, arret.

Tests widgets :

- affichage serie repetitions ;
- affichage serie poids + repetitions ;
- affichage serie duree ;
- bouton validation ;
- bouton passer ;
- affichage repos ;
- alerte avant lancement si seance invalide.

## Criteres d'acceptation

- [ ] Une seance valide peut etre lancee.
- [ ] Une seance invalide est bloquee avec explication.
- [ ] Les series s'enchainent dans le bon ordre.
- [ ] Les repos entre series fonctionnent.
- [ ] Les repos entre exercices fonctionnent.
- [ ] Les controles principaux fonctionnent.
- [ ] Les exercices en duree peuvent etre automatiques ou manuels.
- [ ] L'utilisateur peut passer une etape.
- [ ] Les instructions sont visibles.
- [ ] Les tests passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer aux videos tant que :

- l'execution fonctionne sans video ;
- la sequence est testee ;
- les controles ne bloquent jamais l'utilisateur.
