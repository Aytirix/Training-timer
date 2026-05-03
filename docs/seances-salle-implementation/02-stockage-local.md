# 02 - Stockage local et migrations

## Objectif

Sauvegarder localement les exercices globaux et les seances de salle sans casser l'existant.

Le projet utilise actuellement `SharedPreferences`. La premiere implementation peut rester sur ce mecanisme si cela reste raisonnable.

## Donnees a stocker

### Exercices globaux

Stocker :

- liste des exercices ;
- video associee ;
- instructions ;
- type ;
- ID interne.

### Seances

Stocker :

- liste des seances ;
- items ordonnes ;
- references vers exercices globaux par ID interne ;
- series ;
- repos.

## Regles de compatibilite

- Ne pas casser les seances existantes de type `Pyramide`.
- Garder l'ecran `Minuteurs` fonctionnel.
- Ajouter de nouvelles cles de stockage separees si possible.
- Prevoir une valeur vide si aucune seance de salle n'existe encore.

## Suppression d'exercice utilise

Decision finale :

- autoriser la suppression apres confirmation ;
- lister les seances impactees ;
- supprimer l'exercice global ;
- retirer automatiquement toutes les occurrences de cet exercice dans les seances.

Impact stockage :

- il faut une fonction capable de trouver les seances impactees ;
- il faut une fonction transactionnelle logique qui supprime l'exercice et nettoie les seances ;
- si une seance devient vide apres suppression, elle reste sauvegardee mais sera invalide au lancement tant qu'elle n'a pas d'exercice.

## Videos locales

Les videos importees depuis le telephone seront copiees dans le stockage de l'application.

Regles :

- stocker le chemin copie ;
- supprimer le fichier copie quand la video est supprimee d'un exercice ;
- si plusieurs exercices partagent le meme fichier, garder une seule copie partagee ;
- ne pas supprimer un fichier partage tant qu'il est encore reference.

Cette partie peut etre preparee dans le modele puis finalisee a l'etape videos.

## Fichiers probables

- `lib/core/storage/local_storage.dart`
- `lib/features/gym/data/gym_repository.dart`
- `lib/features/gym/domain/gym_provider.dart`

Les noms peuvent changer selon les conventions retenues.

## Tests a ajouter

Tests unitaires :

- sauvegarder et relire une liste d'exercices ;
- sauvegarder et relire une liste de seances ;
- supprimer un exercice non utilise ;
- supprimer un exercice utilise et nettoyer les seances ;
- trouver les seances impactees par un exercice ;
- ne pas casser les donnees existantes si les nouvelles cles sont absentes.

## Criteres d'acceptation

- [ ] Les exercices globaux persistent localement.
- [ ] Les seances persistent localement.
- [ ] Les donnees existantes de l'application restent compatibles.
- [ ] La suppression d'exercice utilise nettoie les seances.
- [ ] Les tests de stockage passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer a l'interface de bibliotheque tant que :

- les repositories ou providers exposent les operations necessaires ;
- les tests de lecture/ecriture passent ;
- aucune regression n'est introduite sur les tests existants.
