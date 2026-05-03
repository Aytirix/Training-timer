# Cadrage - Gestion des seances de salle

Ce document sert a clarifier la future fonctionnalite de gestion de seances de salle de sport.
Tu peux repondre directement dans les sections `Reponse :`.

## Objectif

Ajouter a l'application un nouvel espace permettant de creer, modifier, importer, lancer et suivre ses propres seances de salle de sport.

L'application contient deja les minuteurs et les seances actuelles orientees tractions/pyramides. La nouvelle fonctionnalite doit cohabiter avec l'existant via une navigation par onglets.

## Navigation proposee

### Onglet 1

Contient l'existant : minuteurs, seances actuelles, pyramides, tractions, historique fonctionnel actuel.

Noms possibles :

- `Minuteurs`
- `Entrainements`
- `Tractions`
- `Programmes`
- `Timers`

Proposition recommandee : `Minuteurs`, car l'existant semble surtout centre sur l'execution de timers.

Reponse : Je choisis `Minuteurs` pour l'onglet 1.

### Onglet 2

Nom propose : `Seances`

Contient les seances de salle personnalisees.

Reponse : Ok pour `Seances` pour l'onglet 2.

## Creation et modification d'une seance

Le formulaire de creation et le formulaire de modification doivent etre identiques.

Champs d'une seance :

- nom ;
- description ;
- video de la seance ;
- liste des exercices ;
- import JSON complet.

La video de la seance doit pouvoir etre ajoutee :

- depuis le telephone ;
- depuis une URL.

Si la video vient d'une URL, l'application doit essayer de la lire directement depuis l'URL.

Question : est-ce qu'on accepte seulement les URLs directes vers un fichier video lisible par le player, par exemple `.mp4`, ou aussi des plateformes comme YouTube, Instagram, TikTok ?

Reponse : On accepte les URLs directes vers des fichiers video lisible par le player, ainsi que les URLs de plateformes comme YouTube, Instagram, TikTok.

Question : si une URL ne peut pas etre lue, est-ce qu'on bloque la sauvegarde ou est-ce qu'on affiche seulement un avertissement ?

Reponse : une séance n'a pas de vidéo c'est seulement l'exercice qui a une vidéo.

## Gestion des exercices

Depuis une seance, l'utilisateur peut cliquer sur `Ajouter un exercice`.

L'application affiche alors :

- la liste des exercices deja disponibles ;
- une action pour creer un exercice manuellement si l'exercice souhaite n'existe pas.

### Creation d'un exercice

Champs d'un exercice :

- nom ;
- instructions ;
- video de l'exercice ;
- type d'exercice.

La video de l'exercice doit pouvoir etre ajoutee :

- depuis le telephone ;
- depuis une URL.

Types d'exercice proposes :

- `poids_repetitions` : chaque serie contient un poids et un nombre de repetitions ;
- `repetitions` : chaque serie contient seulement un nombre de repetitions ;
- `duree` : chaque serie contient une duree.

Question : tu as dit "si c'est que repetition, on affiche kilos et repetitions", mais ca ressemble plutot au type `poids_repetitions`. Pour le type `repetitions`, est-ce qu'on affiche uniquement les repetitions ?

Reponse : Oui, pour le type `repetitions`, on affiche uniquement les repetitions.

Question : est-ce qu'il faut prevoir un type `poids_duree`, par exemple gainage leste, marche farmer, sled push, etc. ?

Reponse : Oui, il faut prévoir un type `poids_duree` pour les exercices comme le gainage leste, la marche farmer, le sled push, etc.

Question : est-ce qu'un exercice doit etre global et reutilisable dans toutes les seances, ou seulement stocke dans la seance ou il a ete cree ?

Reponse : Il faut que les exercices soient globaux et réutilisables dans toutes les séances, afin d'éviter de recréer les mêmes exercices dans chaque séance et de permettre de modifier une vidéo ou des instructions une seule fois.

## Configuration d'un exercice dans une seance

Quand un exercice est ajoute dans une seance, il apparait dans la liste des exercices de la seance.

Quand on clique dessus, un panneau s'ouvre en dessous avec la configuration de l'exercice dans cette seance.

Par defaut :

- 2 series ;
- pour `poids_repetitions` : 0 kg et 10 repetitions ;
- pour `repetitions` : 10 repetitions ;
- pour `duree` : duree a definir, ou valeur par defaut a choisir.

Actions attendues :

- ajouter une serie ;
- modifier une serie ;
- supprimer une serie ;
- configurer le temps de repos entre les series ;
- configurer le temps de repos apres l'exercice, avant l'exercice suivant.

Regle importante :

- le temps de repos entre les series ne s'applique pas apres la derniere serie ;
- le repos apres la derniere serie est gere par le repos entre exercices ;
- par defaut, le repos entre exercices est vide.

Question : quelle duree par defaut veux-tu pour une serie de type `duree` ? Exemple : 30 secondes, 45 secondes, 60 secondes, ou vide.

Reponse : On met aucune valeur par défaut pour tout type d'exercice, y compris pour les séries de type `duree`, afin que l'utilisateur puisse définir la durée qui lui convient le mieux.

Question : le repos entre series est-il commun a tout l'exercice, ou configurable serie par serie ?

Reponse : Il est configurable série par série, afin de permettre des temps de repos différents entre les séries d'un même exercice si nécessaire.

Question : le repos entre exercices doit-il etre attache a l'exercice courant, par exemple "repos apres cet exercice", ou au lien entre deux exercices ?

Reponse : Au lien entre deux exercices

## Lancement d'une seance

Quand l'utilisateur lance une seance, l'application suit les exercices et les series dans l'ordre.

### Exercice en repetitions ou poids + repetitions

L'utilisateur valide manuellement chaque serie quand elle est terminee.

Apres validation :

- si ce n'est pas la derniere serie de l'exercice, le chrono de repos entre series se lance ;
- si c'est la derniere serie, le chrono de repos entre exercices se lance uniquement si un repos a ete configure ;
- l'application previent quand il faut repartir, par exemple avec un bip ou une annonce.

Idee d'annonce :

- "Depart dans 10 secondes" ;
- puis bip ou annonce finale.

### Exercice en duree

L'utilisateur peut lancer le chrono de la serie.

Il doit aussi pouvoir :

- passer a la suite manuellement ;
- valider la serie meme si le chrono n'est pas termine ;
- eviter d'etre bloque si un bug arrive.

Question : pour les exercices en duree, est-ce que le chrono doit demarrer automatiquement quand on arrive sur la serie, ou seulement quand l'utilisateur appuie sur demarrer ?

Reponse : Les deux soht possible il doit avoir un input qui lui permet de choisir entre un démarrage automatique du chrono lorsqu'on arrive sur la série ou un démarrage manuel lorsque l'utilisateur appuie sur "Démarrer". Cela permettra à l'utilisateur de choisir la méthode qui lui convient le mieux.

Question : veux-tu garder les controles existants du timer actuel, comme pause, reprise, precedent, passer, arret ?

Reponse : Oui

Question : veux-tu des annonces vocales via la voix existante, un simple bip, ou les deux ?

Reponse : les deux

## Import JSON

L'utilisateur doit pouvoir creer une seance directement avec un JSON.

Tout doit etre configurable dans le JSON :

- nom de la seance ;
- description ;
- video de la seance ; (donc pas de viéo pour une seance)
- exercices ;
- instructions des exercices ;
- video des exercices ;
- type des exercices ;
- series ;
- poids ;
- repetitions ;
- durees ;
- temps de repos entre series ;
- temps de repos entre exercices.

Si un exercice du JSON n'existe pas deja pour l'utilisateur, l'application doit le creer automatiquement.

Regle de correspondance :

- on se base sur le nom de l'exercice pour savoir s'il existe deja.

Question : la comparaison des noms doit-elle ignorer les majuscules, accents et espaces en trop ? Exemple : `Developpe couche` = `développé couché`.

Reponse : Oui on ignore les majuscules, les accents et les espaces en trop pour la comparaison des noms d'exercices.

Question : si un exercice existe deja mais que le JSON contient une video ou des instructions differentes, est-ce qu'on met a jour l'exercice existant ou est-ce qu'on garde l'existant ?

Reponse : On lui montre la comparaison entre les deux et on lui demande s'il veut mettre à jour l'exercice existant avec les nouvelles informations du JSON ou s'il veut créer un nouvel exercice avec un nom légèrement modifié pour différencier les deux.

Question : si le JSON contient deux exercices avec le meme nom mais des types differents, que doit faire l'application ?

Reponse : Un meme exos va être basé sur le nom + le type

## Exemple JSON

Proposition de format :

```json
{
  "version": 1,
  "session": {
    "name": "Haut du corps - Force",
    "description": "Seance orientee developpe couche, tractions et gainage.",
    "video": {
      "source": "url",
      "url": "https://example.com/videos/seance-haut-du-corps.mp4"
    },
    "exercises": [
      {
        "exercise": {
          "name": "Developpe couche",
          "instructions": "Garder les omoplates serrees, descendre controle, pousser fort sans decoller les fesses.",
          "type": "poids_repetitions",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/developpe-couche.mp4"
          }
        },
        "sets": [
          {
            "weightKg": 60,
            "repetitions": 10
          },
          {
            "weightKg": 65,
            "repetitions": 8
          },
          {
            "weightKg": 70,
            "repetitions": 6
          }
        ],
        "restBetweenSetsSeconds": 120,
        "restAfterExerciseSeconds": 180
      },
      {
        "exercise": {
          "name": "Tractions pronation",
          "instructions": "Depart bras tendus, poitrine vers la barre, controle de la descente.",
          "type": "repetitions",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/tractions-pronation.mp4"
          }
        },
        "sets": [
          {
            "repetitions": 8
          },
          {
            "repetitions": 8
          },
          {
            "repetitions": 6
          }
        ],
        "restBetweenSetsSeconds": 90,
        "restAfterExerciseSeconds": 120
      },
      {
        "exercise": {
          "name": "Gainage planche",
          "instructions": "Corps aligne, abdos serres, ne pas creuser le dos.",
          "type": "duree",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/gainage-planche.mp4"
          }
        },
        "sets": [
          {
            "durationSeconds": 45
          },
          {
            "durationSeconds": 45
          }
        ],
        "restBetweenSetsSeconds": 60,
        "restAfterExerciseSeconds": null
      }
    ]
  }
}
```

Question : ce format JSON te convient-il comme base ?

Reponse : Faudra juste le mettre à jour par rapport à mes reponses mais globalement oui ce format JSON me convient comme base.

Question : veux-tu aussi un export JSON des seances creees dans l'application ?

Reponse : Oui, cela permettrait de conserver les seances créées et de les réimporter plus tard.

## Ameliorations conseillees

### Bibliotheque d'exercices

Prevoir une vraie bibliotheque d'exercices reutilisable.

Interet :

- eviter de recreer les memes exercices dans chaque seance ;
- permettre de modifier une video ou des instructions une seule fois ;
- faciliter l'import JSON.

Reponse : Oui, une bibliothèque d'exercices réutilisable serait très bénéfique pour éviter la duplication des exercices dans chaque séance, permettre une gestion centralisée des vidéos et des instructions, et faciliter l'importation de séances via JSON.

### Duplication de seance

Ajouter une action `Dupliquer` sur une seance.

Interet :

- creer une variante rapidement ;
- garder une seance de base et l'adapter.

Reponse : Oui, cela permettrait de créer rapidement des variantes d'une séance existante.

### Validation du JSON avant import

Afficher un ecran de verification avant de sauvegarder :

- erreurs bloquantes ;
- exercices qui seront crees ;
- exercices deja existants ;
- videos non lisibles ;
- champs manquants.

Reponse : Oui, cela permettrait de s'assurer que le JSON est correctement formé avant l'importation.

### Historique d'execution

Plus tard, enregistrer les seances realisees :

- date ;
- poids/repetitions/durees faits reellement ;
- series sautees ;
- notes.

Reponse : Oui, cela permettrait de garder une trace des séances réalisées et des observations associées.

### Notes par exercice ou par seance

Permettre d'ajouter une note :

- pendant la preparation ;
- pendant ou apres l'execution.

Exemples :

- "monter a 70 kg la prochaine fois" ;
- "douleur epaule droite" ;
- "repos trop court".

Reponse : Oui, cela permettrait d'ajouter des notes personnalisées à chaque exercice ou séance.

## Points techniques a verifier

- Ajouter une dependance Flutter pour lire les videos locales et distantes.
- Verifier la gestion des permissions Android pour choisir une video depuis le telephone.
- Decider comment stocker les videos locales : chemin local, copie dans un dossier app, ou reference au fichier selectionne.
- Migrer la persistance locale actuelle si le modele de donnees change beaucoup.
- Ajouter des tests de parsing JSON.
- Ajouter des tests sur la generation de la sequence d'execution d'une seance.

Reponse : Oui, cela permettrait de s'assurer que la séquence d'exécution est générée correctement.

## Definition de fini proposee

La premiere version est terminee quand on peut :

- ouvrir l'onglet `Seances` ;
- creer une seance manuellement ;
- ajouter des exercices existants ;
- creer un exercice depuis la seance ;
- configurer les series selon le type d'exercice ;
- configurer les repos ;
- importer une seance depuis un JSON ;
- lancer la seance ;
- valider ou passer chaque serie ;
- entendre ou voir une alerte a la fin des repos ;
- sauvegarder les donnees localement.

Reponse : Oui, cela couvre les fonctionnalités de base nécessaires pour la gestion des séances de salle de sport.

## Questions complementaires apres relecture

Ces questions viennent apres lecture de tes reponses. Elles servent a verrouiller les points qui peuvent avoir un gros impact sur l'implementation.

### Videos d'exercices

Tu as precise qu'une seance n'a pas de video, seulement les exercices.

Question : est-ce qu'on supprime completement le champ video de la seance dans le modele, le formulaire et le JSON ?

Reponse : Oui

Question : pour YouTube, Instagram et TikTok, veux-tu que l'application lise vraiment la video dans l'app, ou est-ce qu'ouvrir la video dans une vue web / navigateur integre est acceptable ?

Contexte : les URLs directes `.mp4` sont simples a lire avec un player video classique. Les plateformes comme YouTube, Instagram et TikTok ne se comportent pas comme de simples fichiers video et demandent souvent un traitement specifique.

Reponse: Sinon on peux pas télécharger la vidéo ?

Question : si une video d'exercice n'est pas lisible, est-ce qu'on bloque la creation de l'exercice, ou est-ce qu'on sauvegarde quand meme avec un avertissement ?

Reponse : Oui on bloque

Question : pour une video ajoutee depuis le telephone, est-ce qu'on copie le fichier dans le stockage de l'application, ou est-ce qu'on garde seulement une reference vers le fichier choisi ?

Reponse : Oui on copie le fichier dans le stockage de l'application pour éviter les problèmes de suppression ou de déplacement du fichier source.

### Bibliotheque d'exercices

Les exercices sont globaux et reutilisables dans toutes les seances.

Question : est-ce qu'il faut un ecran dedie `Exercices` pour gerer la bibliotheque, ou seulement gerer les exercices depuis le formulaire d'une seance au debut ?

Reponse : On peux ajouter un écran dédié "Exercices" pour gérer la bibliothèque d'exercices, ce qui permettrait de créer, modifier et supprimer des exercices de manière centralisée, indépendamment des séances.

Question : si on modifie un exercice global, est-ce que les anciennes seances qui l'utilisent doivent afficher automatiquement les nouvelles instructions/video ?

Reponse : Oui, les anciennes séances qui utilisent cet exercice afficheront automatiquement les nouvelles instructions et la nouvelle vidéo, car l'exercice est global et réutilisable.

Question : est-ce qu'une seance doit pouvoir surcharger localement les instructions ou la video d'un exercice global, uniquement pour cette seance ?

Reponse : Non, pour éviter la confusion, une séance ne doit pas pouvoir surcharger localement les instructions ou la vidéo d'un exercice global. Si l'utilisateur souhaite une variante d'un exercice, il peut créer un nouvel exercice avec un nom légèrement modifié.

### Types d'exercice et series

Types retenus pour l'instant :

- `poids_repetitions`
- `repetitions`
- `duree`
- `poids_duree`

Question : faut-il aussi prevoir un type `distance_temps`, par exemple rameur, course, velo, marche ?

Reponse : Non

Question : faut-il prevoir un champ `unitePoids`, ou on force toujours les kilogrammes ?

Reponse : On force les kilogrammes pour simplifier l'interface et éviter les conversions.

Question : comme tu veux aucune valeur par defaut, est-ce qu'on autorise une serie incomplete pendant l'edition, mais on bloque le lancement tant que les valeurs obligatoires ne sont pas remplies ?

Reponse : on bloque la validation de la série tant que les valeurs obligatoires ne sont pas remplies, pour éviter les erreurs lors du lancement de la séance.

Question : pour le repos configurable serie par serie, est-ce que le repos est stocke sur chaque serie comme `restAfterSetSeconds`, sauf la derniere serie ou il peut etre vide ?

Reponse : Oui, le repos configurable série par série est stocké sur chaque série comme `restAfterSetSeconds`, sauf la dernière série où il peut être vide.

### Repos entre exercices

Tu as choisi que le repos entre exercices soit attache au lien entre deux exercices.

Question : dans l'interface, tu preferes afficher ce repos entre deux cartes d'exercices, ou dans le panneau ouvert de l'exercice precedent ?

Reponse : Entre deux cartes d'exercices, pour que ce soit plus clair que le repos fait partie de la transition entre les deux exercices.

Question : si on deplace l'ordre des exercices, le repos entre deux exercices doit-il rester avec le lien visuel entre eux, ou suivre l'exercice precedent ?

Reponse : Suivre l'exercice précédent, car le repos est généralement associé à la fin d'un exercice pour permettre de récupérer avant de commencer le suivant.

### Execution d'une seance

Question : pendant une seance, veux-tu afficher la video/instructions de l'exercice courant sur l'ecran d'execution ?

Reponse : Oui, afficher la vidéo et les instructions de l'exercice courant sur l'écran d'exécution permettrait à l'utilisateur de suivre facilement les consignes et de s'assurer qu'il réalise correctement l'exercice.

Question : pour les annonces, veux-tu une option globale par seance ou par utilisateur pour activer/desactiver bip et voix ?

Reponse : L'option global par utilisateur

Question : quand un repos est vide, est-ce qu'on passe directement a la suite sans ecran de repos ?

Reponse : Oui, lorsque le repos est vide, l'application passe directement à la suite sans afficher d'écran de repos, pour permettre une transition fluide entre les exercices.

Question : si l'utilisateur quitte une seance en cours, est-ce qu'on sauvegarde l'etat pour reprendre plus tard ?

Reponse : Non

Question : pendant l'execution, l'utilisateur peut-il modifier le poids, les repetitions ou la duree reellement faits avant de valider la serie ?

Reponse : Non

### Import et export JSON

Tu as dit qu'un exercice existant est base sur `nom + type`, avec comparaison du nom sans majuscules, accents et espaces en trop.

Question : si le nom est identique mais le type different, on considere donc que ce sont deux exercices differents. Est-ce bien la regle finale ?

Reponse : Oui

Question : dans l'ecran de comparaison d'import, veux-tu pouvoir choisir action par action pour chaque exercice, ou appliquer une decision globale a tous les conflits ?

Reponse : Action par action, pour plus de flexibilité.

Question : si l'import JSON contient des champs inconnus, est-ce qu'on les ignore ou est-ce qu'on bloque l'import ?

Reponse : On les ignore, mais s'il y a des champs obligatoires manquants ou des erreurs de format, on bloque l'import.

Question : veux-tu que l'export JSON contienne aussi les IDs internes de l'application, ou seulement des donnees portables basees sur les noms/types ?

Reponse : les données portables basées sur les noms/types, pour éviter les problèmes de compatibilité entre différentes installations de l'application.

## JSON mis a jour propose

Ce format retire la video de seance, ajoute `poids_duree`, met le repos entre series sur chaque serie, et represente le repos entre exercices comme un lien entre deux exercices.

```json
{
  "version": 1,
  "session": {
    "name": "Haut du corps - Force",
    "description": "Seance orientee developpe couche, tractions et gainage.",
    "items": [
      {
        "kind": "exercise",
        "exercise": {
          "name": "Developpe couche",
          "type": "poids_repetitions",
          "instructions": "Garder les omoplates serrees, descendre controle, pousser fort sans decoller les fesses.",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/developpe-couche.mp4"
          }
        },
        "timedSetStartMode": null,
        "sets": [
          {
            "weightKg": 60,
            "repetitions": 10,
            "restAfterSetSeconds": 120
          },
          {
            "weightKg": 65,
            "repetitions": 8,
            "restAfterSetSeconds": 120
          },
          {
            "weightKg": 70,
            "repetitions": 6,
            "restAfterSetSeconds": null
          }
        ]
      },
      {
        "kind": "rest",
        "durationSeconds": 180
      },
      {
        "kind": "exercise",
        "exercise": {
          "name": "Tractions pronation",
          "type": "repetitions",
          "instructions": "Depart bras tendus, poitrine vers la barre, controle de la descente.",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/tractions-pronation.mp4"
          }
        },
        "timedSetStartMode": null,
        "sets": [
          {
            "repetitions": 8,
            "restAfterSetSeconds": 90
          },
          {
            "repetitions": 8,
            "restAfterSetSeconds": 90
          },
          {
            "repetitions": 6,
            "restAfterSetSeconds": null
          }
        ]
      },
      {
        "kind": "rest",
        "durationSeconds": 120
      },
      {
        "kind": "exercise",
        "exercise": {
          "name": "Gainage leste",
          "type": "poids_duree",
          "instructions": "Corps aligne, abdos serres, ne pas creuser le dos.",
          "video": {
            "source": "url",
            "url": "https://example.com/videos/gainage-leste.mp4"
          }
        },
        "timedSetStartMode": "manual",
        "sets": [
          {
            "weightKg": 10,
            "durationSeconds": 45,
            "restAfterSetSeconds": 60
          },
          {
            "weightKg": 10,
            "durationSeconds": 45,
            "restAfterSetSeconds": null
          }
        ]
      }
    ]
  }
}
```

Question : tu preferes ce format avec une liste `items` qui alterne exercices et repos, ou l'ancien format avec `restAfterExerciseSeconds` sur chaque exercice ?

Reponse : Je préfère ce format avec une liste `items` qui alterne exercices et repos, car il est plus flexible et permet de représenter des repos de différentes durées entre les exercices.

## Dernieres clarifications avant implementation

Apres cette deuxieme relecture, la fonctionnalite est bien cadree. Il reste seulement quelques decisions finales, surtout autour des videos et de la suppression.

### Telechargement des videos de plateformes

Tu as demande : "Sinon on peux pas telecharger la video ?"

Point a trancher : pour YouTube, Instagram et TikTok, il vaut mieux eviter de telecharger automatiquement les videos depuis l'application.

Raison :

- techniquement, ce ne sont pas de simples fichiers video directs ;
- les plateformes changent souvent leurs protections et formats ;
- le telechargement automatique peut poser des problemes de conditions d'utilisation et de droits ;
- cela rendrait l'application fragile et plus difficile a maintenir.

Proposition recommandee :

- accepter les URLs directes vers fichiers video lisibles, par exemple `.mp4` ;
- accepter les fichiers video importes depuis le telephone, puis les copier dans le stockage de l'application ;
- pour YouTube/Instagram/TikTok, stocker le lien et l'ouvrir dans une vue web ou dans l'application externe ;
- ne pas bloquer la creation d'un exercice si le lien plateforme est ouvrable mais pas lisible par le player natif ;
- continuer a bloquer uniquement les videos directes invalides quand l'utilisateur choisit explicitement une URL video directe.

Question : est-ce que cette regle te convient ?

Reponse :Il existe pas des plugin qui permet de récupéré tout flux vidéo ?

Question : est-ce qu'on distingue deux types d'URL video dans le formulaire ?

- `URL video directe` : doit etre lisible dans le player de l'application ;
- `Lien plateforme` : YouTube, Instagram, TikTok, ouvert dans une vue web ou application externe.

Reponse : Non, pour simplifier l'interface, on peut avoir un seul champ `URL de la vidéo` avec une validation qui détecte si c'est une URL directe ou un lien de plateforme, et qui affiche un message d'information à l'utilisateur sur la façon dont la vidéo sera traitée en fonction du type d'URL.

### Suppression d'exercices globaux

Comme les exercices sont globaux, leur suppression peut impacter plusieurs seances.

Question : si un exercice est utilise dans une ou plusieurs seances, est-ce qu'on interdit sa suppression ?

Reponse : Oui, pour éviter de casser les séances qui utilisent cet exercice, on interdit la suppression d'un exercice global s'il est utilisé dans une ou plusieurs séances.

Question : alternative possible : autoriser la suppression seulement apres confirmation, puis retirer l'exercice de toutes les seances qui l'utilisent. Est-ce que tu preferes cette option ?

Reponse : Oui, cette option permettrait de garder une base de données plus propre en supprimant complètement l'exercice, mais il faudrait s'assurer que l'utilisateur comprend bien que cela affectera toutes les séances qui utilisent cet exercice, lui lister les séances impactées, et lui demander de confirmer cette action avant de procéder à la suppression.

### Suppression de fichiers video locaux

Les videos importees depuis le telephone seront copiees dans le stockage de l'application.

Question : quand l'utilisateur supprime une video d'un exercice, est-ce qu'on supprime aussi le fichier copie localement ?

Reponse : Oui, si l'utilisateur supprime une vidéo d'un exercice, on supprime également le fichier copié localement.

Question : si plusieurs exercices utilisent le meme fichier video local, est-ce qu'on garde une seule copie partagee ou une copie par exercice ?

Reponse : On garde une seule copie partagée, car cela permet de réduire l'utilisation de l'espace de stockage et d'éviter les duplications inutiles.
### Ordre et duplication des exercices dans une seance

Question : une meme seance peut-elle contenir plusieurs fois le meme exercice global ?

Exemple : 

- Developpe couche lourd au debut ;
- Developpe couche leger en fin de seance.

Reponse : Oui

Question : est-ce que l'utilisateur doit pouvoir reordonner les exercices par glisser-deposer ?

Reponse : oui

### Validation avant lancement

Question : avant de lancer une seance, veux-tu un ecran ou une alerte qui liste les problemes bloquants ?

Exemples :

- serie incomplete ;
- exercice sans nom ;
- video directe invalide ;
- repos negatif ;
- seance sans exercice.

Reponse : Oui

### Priorite de premiere version

Question : pour la premiere implementation, est-ce qu'on fait tout d'un coup, ou est-ce qu'on decoupe comme ceci ?

1. Bibliotheque d'exercices + creation/modification.
2. Creation/modification de seances avec exercices, series et repos.
3. Import/export JSON.
4. Execution de la seance.
5. Videos locales/distantes et affichage pendant l'execution.

Reponse : On vois sa après

## Synthese finale

Le cadrage est maintenant suffisant pour preparer l'implementation.

Decisions confirmees :

- onglet 1 : `Minuteurs` ;
- onglet 2 : `Seances` ;
- pas de video au niveau d'une seance ;
- videos uniquement au niveau des exercices ;
- exercices globaux et reutilisables ;
- ecran dedie `Exercices` pour gerer la bibliotheque ;
- pas de surcharge locale des instructions/video dans une seance ;
- types d'exercice : `poids_repetitions`, `repetitions`, `duree`, `poids_duree` ;
- poids toujours en kilogrammes ;
- repos entre series stocke sur chaque serie avec `restAfterSetSeconds` ;
- repos entre exercices affiche entre deux cartes ;
- repos entre exercices qui suit l'exercice precedent si on reordonne ;
- drag and drop pour reordonner les exercices ;
- une meme seance peut contenir plusieurs fois le meme exercice ;
- validation bloquante avant lancement si la seance contient des erreurs ;
- pas de reprise automatique si l'utilisateur quitte une seance en cours ;
- pas de modification des valeurs realisees pendant l'execution ;
- import/export JSON portable base sur `nom + type`, sans IDs internes ;
- champs JSON inconnus ignores ;
- champs obligatoires manquants ou mauvais formats bloquants.

### Decision finale - Plugins et flux video

Il existe des plugins Flutter pour lire certains formats ou integrer certaines plateformes :

- `video_player` pour les fichiers video directs et certains flux compatibles ;
- `youtube_player_iframe` pour afficher YouTube via l'API iFrame officielle ;
- `webview_flutter` pour ouvrir une plateforme dans une vue web.

En revanche, "recuperer tout flux video" ou telecharger automatiquement depuis YouTube, Instagram ou TikTok n'est pas une base fiable pour l'application.

Decision technique recommandee :

- URL directe lisible : lecture dans l'application ;
- YouTube : integration via player YouTube si possible, sinon vue web ;
- Instagram/TikTok : vue web ou ouverture externe ;
- pas de telechargement automatique des videos de plateformes ;
- video locale importee : copie dans le stockage de l'application.

Decision finale :

- pour YouTube, on utilise l'API officielle via un player compatible, sans cle API ni configuration lourde si le plugin le permet ;
- pour Instagram/TikTok/autres plateformes, on ouvre dans une vue web ou dans l'application externe ;
- on n'essaie pas de telecharger automatiquement les videos de plateformes ;
- les URLs directes vers fichiers video restent lisibles dans l'application si le player les supporte ;
- les videos importees depuis le telephone sont copiees dans le stockage de l'application.

### Decision finale - Suppression d'un exercice utilise

Tes deux reponses donnent deux comportements differents :

1. Interdire la suppression d'un exercice global s'il est utilise dans une ou plusieurs seances.
2. Autoriser la suppression apres confirmation, en listant les seances impactees, puis retirer l'exercice de toutes ces seances.

Decision finale :

- autoriser la suppression d'un exercice global meme s'il est utilise ;
- avant suppression, afficher la liste des seances impactees ;
- demander une confirmation explicite ;
- apres confirmation, supprimer l'exercice global ;
- retirer automatiquement cet exercice de toutes les seances qui l'utilisent.
