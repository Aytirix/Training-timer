# 03 - Bibliotheque globale d'exercices

## Objectif

Ajouter un ecran dedie `Exercices` pour gerer la bibliotheque globale.

Les exercices crees ici sont reutilisables dans toutes les seances.

## Fonctionnalites

### Liste des exercices

Afficher :

- nom ;
- type ;
- indication de video presente ou absente ;
- extrait court des instructions si utile.

Actions :

- creer ;
- modifier ;
- supprimer ;
- rechercher ou filtrer si simple a ajouter.

### Creation d'exercice

Champs :

- nom ;
- type ;
- instructions ;
- video optionnelle.

Validation :

- nom obligatoire ;
- type obligatoire ;
- combinaison `nom normalise + type` unique ;
- instructions optionnelles ou obligatoires a confirmer pendant implementation selon UX ;
- video optionnelle.

### Modification d'exercice

Regles :

- modifier un exercice global met a jour toutes les seances qui l'utilisent ;
- aucune surcharge locale dans une seance ;
- si le nom ou type change, verifier l'unicite `nom normalise + type`.

### Suppression d'exercice

Regles :

- si l'exercice n'est pas utilise, suppression directe avec confirmation simple ;
- si l'exercice est utilise, afficher les seances impactees ;
- demander une confirmation explicite ;
- supprimer l'exercice ;
- retirer toutes ses occurrences dans les seances.

## Navigation

L'ecran `Exercices` peut etre accessible :

- depuis l'onglet `Seances` ;
- depuis le formulaire d'ajout d'exercice a une seance ;
- eventuellement depuis une action de menu.

## Fichiers probables

- `lib/features/gym/presentation/exercise_library_screen.dart`
- `lib/features/gym/presentation/exercise_editor_screen.dart`
- `lib/features/gym/presentation/widgets/exercise_card.dart`
- `lib/features/gym/domain/gym_provider.dart`

## Tests a ajouter

Tests unitaires :

- creation avec nom/type valide ;
- blocage doublon `nom normalise + type` ;
- modification qui conserve l'unicite ;
- suppression avec nettoyage des seances.

Tests widgets :

- affichage liste vide ;
- affichage liste avec exercices ;
- formulaire creation ;
- erreurs de validation ;
- confirmation de suppression avec seances impactees.

## Criteres d'acceptation

- [ ] L'ecran `Exercices` est accessible.
- [ ] On peut creer un exercice global.
- [ ] On peut modifier un exercice global.
- [ ] On peut supprimer un exercice non utilise.
- [ ] On peut supprimer un exercice utilise apres confirmation.
- [ ] Les doublons `nom + type` sont bloques.
- [ ] Les tests passent.
- [ ] `flutter analyze` passe.

## Verification manuelle

Verifier sur l'application :

- creer `Developpe couche` en `poids_repetitions` ;
- creer `Developpe couche` en `duree` doit etre autorise ;
- recreer `developpe   couche` en `poids_repetitions` doit etre bloque ;
- modifier les instructions ;
- supprimer un exercice.

Ne pas passer a l'editeur de seances tant que ces points ne fonctionnent pas.
