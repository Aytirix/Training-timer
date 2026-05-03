# 04 - Creation et modification de seances

## Objectif

Ajouter l'onglet `Seances` et permettre de creer/modifier une seance de salle.

## Navigation

Ajouter une navigation par onglets :

- `Minuteurs` : fonctionnalite existante ;
- `Seances` : nouvelles seances de salle.

L'existant doit rester disponible dans `Minuteurs`.

## Liste des seances

Afficher :

- nom ;
- description courte ;
- nombre d'exercices ;
- duree estimee si simple a calculer ;
- actions modifier, dupliquer, supprimer, lancer.

Etat vide :

- afficher une action claire pour creer une premiere seance ;
- proposer aussi l'import JSON si deja implemente plus tard.

## Formulaire seance

Creation et modification utilisent le meme formulaire.

Champs :

- nom ;
- description ;
- items de seance.

Important :

- pas de video sur la seance ;
- les videos sont seulement sur les exercices.

## Ajout d'exercice a une seance

Flux :

1. Cliquer `Ajouter un exercice`.
2. Afficher la liste des exercices globaux.
3. Selectionner un exercice.
4. Ajouter une configuration de cet exercice dans la seance.
5. Si l'exercice n'existe pas, permettre de le creer depuis la bibliotheque.

Regles :

- une meme seance peut contenir plusieurs fois le meme exercice ;
- la configuration des series appartient a la seance ;
- les instructions/video restent celles de l'exercice global.

## Configuration des series

Quand on clique sur un exercice dans la seance, ouvrir un panneau en dessous.

Actions :

- ajouter une serie ;
- modifier une serie ;
- supprimer une serie ;
- modifier `restAfterSetSeconds` pour chaque serie sauf la derniere ;
- choisir le mode de depart des series en duree : manuel ou automatique.

Champs selon type :

- `poids_repetitions` : poids kg + repetitions ;
- `repetitions` : repetitions ;
- `duree` : duree secondes ;
- `poids_duree` : poids kg + duree secondes.

Validation :

- valeurs obligatoires selon type ;
- pas de valeurs negatives ;
- repos positif ou vide ;
- au moins une serie par exercice.

## Repos entre exercices

Afficher un bloc de repos entre deux cartes d'exercices.

Regles :

- le repos est visuellement entre deux exercices ;
- si on reordonne, le repos suit l'exercice precedent ;
- repos vide = passage direct a la suite.

## Reordonner

L'utilisateur doit pouvoir reordonner les exercices par glisser-deposer.

Verifier que :

- les series restent attachees au bon exercice ;
- le repos entre exercices suit l'exercice precedent ;
- l'affichage reste coherent.

## Duplication de seance

Ajouter une action `Dupliquer`.

Regles :

- copier la configuration de seance ;
- garder les references vers les memes exercices globaux ;
- generer un nouvel ID ;
- adapter le nom, par exemple `Nom - copie`.

## Fichiers probables

- `lib/features/gym/presentation/gym_sessions_screen.dart`
- `lib/features/gym/presentation/gym_session_editor_screen.dart`
- `lib/features/gym/presentation/widgets/gym_session_card.dart`
- `lib/features/gym/presentation/widgets/session_exercise_card.dart`
- `lib/features/gym/presentation/widgets/session_rest_item.dart`
- `lib/app/router.dart`

## Tests a ajouter

Tests unitaires :

- validation seance sans exercice ;
- validation exercice sans serie ;
- validation series par type ;
- duplication de seance ;
- reordering et repos qui suit l'exercice precedent.

Tests widgets :

- onglets `Minuteurs` et `Seances` visibles ;
- creation seance ;
- modification seance ;
- ajout exercice existant ;
- ajout du meme exercice deux fois ;
- edition des series ;
- affichage repos entre cartes ;
- drag and drop si testable raisonnablement.

## Criteres d'acceptation

- [ ] L'onglet `Minuteurs` garde l'existant.
- [ ] L'onglet `Seances` affiche les seances.
- [ ] Creation et modification utilisent le meme formulaire.
- [ ] On peut ajouter des exercices globaux.
- [ ] On peut ajouter plusieurs fois le meme exercice.
- [ ] On peut configurer les series selon le type.
- [ ] On peut configurer les repos par serie.
- [ ] On peut configurer les repos entre exercices.
- [ ] On peut reordonner les exercices.
- [ ] On peut dupliquer une seance.
- [ ] Les tests passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer a l'import/export JSON tant que :

- une seance complete peut etre creee manuellement ;
- elle persiste apres redemarrage ;
- elle peut etre modifiee sans perdre les series ;
- les tests de validation passent.
