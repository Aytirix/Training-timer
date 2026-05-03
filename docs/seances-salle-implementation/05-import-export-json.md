# 05 - Import et export JSON

## Objectif

Permettre de creer une seance depuis un JSON et d'exporter une seance existante en JSON portable.

## Format retenu

Le format utilise une liste `items` qui alterne :

- exercices ;
- repos entre exercices.

Exemple :

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
          "instructions": "Garder les omoplates serrees, descendre controle, pousser fort.",
          "video": {
            "source": "directUrl",
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
          "name": "Gainage leste",
          "type": "poids_duree",
          "instructions": "Corps aligne, abdos serres.",
          "video": {
            "source": "youtube",
            "url": "https://www.youtube.com/watch?v=example"
          }
        },
        "timedSetStartMode": "manual",
        "sets": [
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

## Import JSON

Regles :

- le JSON doit contenir `version` ;
- le JSON doit contenir `session.name` ;
- `session.description` peut etre vide ;
- `items` doit contenir au moins un exercice ;
- les champs inconnus sont ignores ;
- les champs obligatoires manquants bloquent l'import ;
- les mauvais formats bloquent l'import ;
- les exercices sont detectes par `nom normalise + type`.

## Gestion des exercices pendant l'import

Si l'exercice n'existe pas :

- creer l'exercice global ;
- utiliser cet exercice dans la seance importee.

Si l'exercice existe avec memes infos :

- reutiliser l'exercice global existant.

Si l'exercice existe avec instructions/video differentes :

- afficher une comparaison ;
- demander une decision action par action.

Actions possibles :

- garder l'exercice existant ;
- mettre a jour l'exercice existant ;
- creer un nouvel exercice avec nom modifie.

## Ecran de validation avant import

Afficher :

- erreurs bloquantes ;
- avertissements ;
- exercices qui seront crees ;
- exercices qui existent deja ;
- conflits instructions/video ;
- videos directes invalides ;
- resume de la seance importee.

## Export JSON

Regles :

- exporter des donnees portables ;
- ne pas exporter les IDs internes ;
- utiliser `nom + type` pour les exercices ;
- inclure instructions et video de chaque exercice ;
- inclure toutes les series ;
- inclure tous les repos ;
- inclure `version`.

## Fichiers probables

- `lib/features/gym/data/gym_session_json_codec.dart`
- `lib/features/gym/data/gym_import_service.dart`
- `lib/features/gym/presentation/gym_json_import_screen.dart`
- `lib/features/gym/presentation/gym_json_export_screen.dart`

## Tests a ajouter

Tests unitaires :

- importer JSON valide ;
- importer avec champs inconnus ;
- bloquer JSON sans nom ;
- bloquer JSON sans exercice ;
- bloquer serie incomplete ;
- detecter exercice existant par `nom normalise + type` ;
- detecter conflit instructions/video ;
- exporter puis reimporter ;
- verifier que l'export ne contient pas d'IDs internes.

Tests widgets :

- ecran coller JSON ;
- affichage erreurs ;
- affichage comparaison conflits ;
- choix action par action ;
- confirmation import.

## Criteres d'acceptation

- [ ] On peut coller/importer un JSON valide.
- [ ] Les exercices manquants sont crees.
- [ ] Les exercices existants sont detectes.
- [ ] Les conflits sont resolus action par action.
- [ ] Les erreurs bloquantes sont claires.
- [ ] On peut exporter une seance.
- [ ] Un export peut etre reimporte.
- [ ] Les tests passent.
- [ ] `flutter analyze` passe.

## Verification avant etape suivante

Ne pas passer a l'execution tant que :

- l'import cree une seance executable ;
- l'export/reimport conserve les series et repos ;
- les conflits sont geres proprement.
