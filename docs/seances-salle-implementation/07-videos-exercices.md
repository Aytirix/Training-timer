# 07 - Videos d'exercices

## Objectif

Ajouter la gestion complete des videos d'exercices.

Les videos sont rattachees aux exercices globaux, jamais directement aux seances.

## Sources video supportees

### Fichier local du telephone

Comportement :

- l'utilisateur choisit un fichier video ;
- l'application copie le fichier dans son stockage ;
- l'exercice reference la copie locale ;
- si la video est supprimee de l'exercice, supprimer le fichier local s'il n'est plus utilise.

### URL directe

Comportement :

- l'utilisateur colle une URL ;
- l'application detecte que c'est une URL directe ou tente de la lire avec le player ;
- si elle n'est pas lisible, bloquer la sauvegarde pour ce type de video ;
- lire la video dans l'application si possible.

### YouTube

Comportement :

- l'utilisateur colle une URL YouTube ;
- l'application extrait l'ID de la video ;
- l'application utilise un player base sur l'API iFrame officielle si possible ;
- pas de cle API ni configuration lourde si le plugin choisi le permet ;
- pas de telechargement automatique.

### Instagram/TikTok/autres plateformes

Comportement :

- stocker le lien ;
- ouvrir dans une vue web ou dans l'application externe ;
- ne pas telecharger automatiquement ;
- ne pas bloquer la creation si le lien est ouvrable mais non lisible par le player natif.

## Interface

Un seul champ `URL de la video`.

L'application detecte le type :

- URL directe ;
- YouTube ;
- plateforme externe ;
- inconnu.

Afficher un message clair :

- `Cette video sera lue dans l'application.`
- `Cette video YouTube sera affichee via le player YouTube.`
- `Ce lien sera ouvert dans une vue web ou une application externe.`
- `Cette URL video directe n'est pas lisible.`

## Dependances probables

A confirmer au moment de l'implementation :

- `video_player` pour fichiers directs et locaux ;
- `youtube_player_iframe` pour YouTube ;
- `webview_flutter` ou `url_launcher` pour plateformes externes ;
- un picker de fichiers/media pour selectionner une video locale.

## Permissions Android

Verifier :

- permission lecture media/video selon version Android ;
- acces au fichier selectionne ;
- copie dans le stockage app ;
- nettoyage des fichiers inutilises.

## Tests a ajouter

Tests unitaires :

- detection URL YouTube ;
- extraction ID YouTube ;
- detection URL directe ;
- detection plateforme externe ;
- validation URL directe invalide ;
- reference counting ou verification d'utilisation d'un fichier local partage.

Tests widgets :

- champ URL affiche le bon message ;
- video locale selectionnee ;
- suppression video ;
- affichage video/lien dans l'ecran d'execution.

Tests manuels :

- fichier local depuis telephone ;
- URL `.mp4` valide ;
- URL `.mp4` invalide ;
- URL YouTube ;
- URL TikTok/Instagram ;
- suppression d'une video locale.

## Criteres d'acceptation

- [ ] On peut ajouter une video locale a un exercice.
- [ ] La video locale est copiee dans le stockage app.
- [ ] On peut supprimer une video locale.
- [ ] Les fichiers inutilises sont nettoyes.
- [ ] On peut ajouter une URL directe lisible.
- [ ] Une URL directe invalide bloque la sauvegarde.
- [ ] YouTube s'affiche via player officiel si possible.
- [ ] Instagram/TikTok/autres s'ouvrent en webview ou externe.
- [ ] Aucune plateforme n'est telechargee automatiquement.
- [ ] Les tests passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer a la validation finale tant que :

- les videos ne cassent pas la creation/modification d'exercices ;
- l'execution reste utilisable meme si une video externe ne s'ouvre pas ;
- les permissions Android sont verifiees.
