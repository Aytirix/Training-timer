# Training Timer

Training Timer est une application Flutter pensée pour préparer, lancer et suivre facilement des timers de séances de sport en local, sans backend ni compte utilisateur.

Le but de l'application est simple : permettre de transformer une structure d'entraînement en séance exécutable, avec temps de repos, annonces vocales optionnelles, estimation de durée, et un écran de timer lisible pendant l'effort.

L'application est pensée pour des séances de sport en général. Aujourd'hui, le flux principal disponible est le type de séance `pyramide`, avec un exemple concret orienté tractions. L'application permet de :

- créer et modifier des séances ;
- structurer une séance en blocs et répétitions ;
- ajuster la durée cible et le temps moyen par répétition ;
- choisir entre enchaînement automatique ou validation manuelle des séries ;
- lancer une séance avec minuteur plein écran ;
- configurer une voix locale pour les annonces vocales ;
- sauvegarder les séances et réglages localement sur l'appareil.

## État actuel du produit

Ce qui est disponible maintenant :

- écran d'accueil avec liste des séances enregistrées ;
- création d'une nouvelle séance via un écran de choix du type ;
- type `Pyramide` disponible ;
- édition manuelle des blocs ;
- saisie rapide multi-lignes pour créer des blocs plus vite ;
- minuteur de séance avec pause, reprise, précédent, passer, arrêt ;
- voix optionnelle via `flutter_tts` ;
- persistance locale via `SharedPreferences`.

Ce qui n'est pas encore disponible :

- autres types de séances que `Pyramide` ;
- synchronisation cloud ;
- compte utilisateur ;
- export/import.

## Prérequis

Pour lancer l'application en local, il faut :

- Flutter SDK compatible avec le projet ;
- Dart inclus dans Flutter ;
- un appareil Android avec débogage USB activé, ou un émulateur Android ;
- ADB disponible si vous utilisez les commandes Android du `Makefile`.

Le projet cible actuellement Flutter `>=3.3.0 <4.0.0`.

## Lancer l'application en local

### Option recommandée : via le Makefile

Le dépôt contient déjà un `Makefile` avec les commandes les plus utiles.

1. Créer votre configuration locale des SDK :

```bash
cp .env.example .env
```

2. Ouvrir `.env` et ajuster les chemins si nécessaire :

```bash
FLUTTER_SDK=/chemin/absolu/vers/flutter
ANDROID_SDK_ROOT=/chemin/absolu/vers/android/sdk
```

3. Installer les dépendances Flutter :

```bash
make app-get
```

4. Vérifier que votre appareil Android est visible :

```bash
make app-adb-devices
```

5. Lancer l'application sur un appareil Android connecté :

```bash
make app-run-adb
```

6. Pour lancer l'analyse et les tests :

```bash
make check
```

Commandes utiles supplémentaires :

```bash
make app-analyze
make app-test
make app-install-adb
make app-devices
```

### Configurer les SDK via `.env`

Le `Makefile` charge automatiquement un fichier `.env` à la racine du projet.

Variables reconnues :

```bash
FLUTTER_SDK=/chemin/absolu/vers/flutter
ANDROID_SDK_ROOT=/chemin/absolu/vers/android/sdk
ANDROID_KEYSTORE_PATH=/chemin/absolu/vers/release-keystore.jks
ANDROID_KEYSTORE_PASSWORD=<mot-de-passe-keystore>
ANDROID_KEY_ALIAS=<alias-de-cle>
ANDROID_KEY_PASSWORD=<mot-de-passe-cle>
GITHUB_TOKEN=<token GitHub>
```

Le dépôt contient :

- `.env.example` : modèle versionné ;
- `.env` : fichier local à créer sur votre machine, ignoré par Git.

Le flux recommandé est :

```bash
cp .env.example .env
```

Puis éditer `.env` avec vos chemins locaux.

Pour publier une release GitHub avec le script de release, ajoutez aussi :

```bash
ANDROID_KEYSTORE_PATH=/chemin/absolu/vers/release-keystore.jks
ANDROID_KEYSTORE_PASSWORD=<mot-de-passe-keystore>
ANDROID_KEY_ALIAS=<alias-de-cle>
ANDROID_KEY_PASSWORD=<mot-de-passe-cle>
GITHUB_TOKEN=<token avec permission Contents: write>
```

Si vous n'avez pas encore de keystore release Android, vous pouvez aussi la générer directement via le `Makefile` :

```bash
make app-generate-keystore
```

Cette commande peut maintenant remplir automatiquement les valeurs manquantes dans `.env`, générer les mots de passe, puis créer la keystore release.

Par défaut, elle choisit :

- un chemin de keystore local dans le projet ;
- un alias par défaut ;
- des mots de passe aléatoires ;
- une durée de validité longue ;
- un `dname` par défaut pour éviter les questions interactives.

Les valeurs finales sont ensuite enregistrées dans `.env`.

Important :

- cette génération automatique fonctionne très bien pour créer une nouvelle keystore ;
- si une keystore existe déjà, le script ne peut pas retrouver son mot de passe automatiquement ;
- il faut donc conserver le fichier keystore et les valeurs enregistrées dans `.env` si vous voulez republier des mises à jour avec la même signature.

Variables concernées :

```bash
ANDROID_KEYSTORE_PATH=...
ANDROID_KEYSTORE_PASSWORD=...
ANDROID_KEY_ALIAS=...
ANDROID_KEY_PASSWORD=...
```

Options facultatives :

```bash
ANDROID_KEYSTORE_VALIDITY_DAYS=10000
ANDROID_KEYSTORE_DNAME=CN=Training Timer, OU=Mobile, O=Your Org, L=Paris, ST=Ile-de-France, C=FR
```

Vous pouvez donc ajuster vos chemins SDK une fois pour toutes dans `.env`, puis utiliser simplement :

```bash
make app-get
make app-run-adb
make check
```

L'override ponctuel en ligne de commande reste possible :

```bash
FLUTTER_SDK=/chemin/vers/flutter make app-get
```

### Publier une release GitHub

Le dépôt contient un script dédié :

```bash
scripts/release-github.sh
```

Ce script :

- charge `.env` ;
- build l'application Android en release ;
- crée ou réutilise une GitHub Release sur le remote `origin` ;
- upload les artefacts compilés ;
- ajoute aussi les fichiers de checksum `.sha256`.

Prérequis :

- `GITHUB_TOKEN` défini dans `.env` ;
- keystore release Android configurée dans `.env` ;
- branche courante poussée sur `origin` ;
- worktree Git propre, sauf si vous utilisez `--allow-dirty`.

Exemple minimal :

```bash
scripts/release-github.sh
```

Exemples utiles :

```bash
scripts/release-github.sh --tag v1.0.0+1
scripts/release-github.sh --artifact both
scripts/release-github.sh --draft
scripts/release-github.sh --notes-file RELEASE_NOTES.md
```

Depuis le `Makefile` :

```bash
make app-release-github
make app-release-github ARGS="--artifact both --draft"
```

Important :

- par défaut, le script publie un `apk` release ;
- `--artifact aab` ou `--artifact both` permet de publier un bundle Android aussi ;
- le script refuse maintenant de publier tant qu'une vraie signature release Android n'est pas configurée dans `.env`.

### Option manuelle : sans le Makefile

Si vous préférez lancer Flutter directement :

1. Récupérer les dépendances :

```bash
flutter pub get
```

2. Lister les appareils :

```bash
flutter devices
```

3. Lancer l'application :

```bash
flutter run -d <device-id>
```

4. Lancer l'analyse statique :

```bash
flutter analyze
```

5. Lancer les tests :

```bash
flutter test
```

## Premier lancement

Au premier démarrage :

- l'application injecte une séance d'exemple : `110 tractions / 30 min` ;
- un bandeau propose de configurer une voix, mais cela reste optionnel ;
- les données sont stockées localement sur l'appareil.

## Comment utiliser l'application

### 1. Écran d'accueil

L'écran d'accueil affiche :

- la liste des séances enregistrées ;
- un bouton `Nouvelle séance` ;
- un accès aux réglages de voix en haut à droite ;
- un bouton `Démarrer` sur chaque carte de séance ;
- un menu contextuel pour modifier ou supprimer une séance.

### 2. Créer une nouvelle séance

1. Appuyer sur `Nouvelle séance`.
2. L'écran `Type de séance` s'ouvre.
3. Choisir `Pyramide`.
4. Vous arrivez sur l'éditeur de séance.

L'écran de création dispose maintenant :

- d'un bouton `Retour` ;
- d'un bouton `Annuler` ;
- d'un bouton `Enregistrer`.

### 3. Remplir la séance pyramide

Dans l'éditeur, vous pouvez définir :

- le nom de la séance ;
- la durée cible en minutes ;
- le temps par répétition en secondes ;
- l'option `Enchaînement automatique`.

Le format actuellement disponible est la pyramide. L'exemple livré avec l'application utilise des tractions, ce qui explique certains libellés actuels dans l'interface.

### Temps par répétition

Dans l'interface actuelle, ce réglage apparaît comme `Temps par traction` car l'exemple par défaut est une séance de tractions.

Plus généralement, ce champ sert à définir le temps moyen alloué à une répétition. Il sert à :

- calculer la durée estimée de la séance ;
- piloter la durée automatique des séries pendant le timer.

La valeur par défaut est `3s`.

### Enchaînement automatique

Quand `Enchaînement automatique` est activé :

- la série passe toute seule au repos ;
- si l'utilisateur tarde ensuite à interagir, une partie du repos peut être rognée.

Quand il est désactivé :

- l'application attend l'action `Série terminée`.

### 4. Ajouter des blocs

Deux modes sont disponibles.

### Mode manuel

Vous pouvez ajouter des blocs puis régler, pour chaque bloc :

- son nom ;
- sa séquence de répétitions ;
- son nombre de répétitions du bloc ;
- son temps de transition ;
- son mode de repos.

Le mode de repos peut être :

- automatique ;
- précis, avec une valeur différente à chaque étape du bloc.

### Saisie rapide

Le bouton `Saisie rapide` permet de décrire plusieurs blocs en texte.

Le principe est générique pour des séances structurées en pyramide. L'exemple ci-dessous reprend simplement le cas des tractions.

Format supporté :

- une ligne = un bloc ;
- les répétitions sont séparées par des tirets ;
- `xN` permet de répéter un bloc ;
- les lignes vides sont ignorées ;
- les lignes commençant par `#` sont traitées comme des commentaires.

Exemple :

```text
1-2-3-4-3-2-1 x3
2-4-6-8-6-4-2
# Bloc final
2-3-5-3-2 x2
```

Une prévisualisation indique :

- les blocs détectés ;
- le nombre total de répétitions ;
- le nombre total de séries ;
- les éventuelles erreurs de syntaxe.

### 5. Régler la voix

Depuis l'accueil, appuyez sur l'icône de volume en haut à droite.

L'écran `Voix` permet de :

- charger les voix disponibles sur l'appareil ;
- rechercher une voix ;
- sélectionner une voix ;
- écouter un test ;
- confirmer une voix ;
- continuer sans voix ;
- désactiver une voix déjà choisie.

Important :

- la voix est optionnelle ;
- l'application fonctionne très bien sans voix ;
- selon l'appareil Android, les voix disponibles dépendent du moteur TTS installé.

### 6. Démarrer une séance

Depuis l'accueil :

1. sélectionner une séance ;
2. appuyer sur `Démarrer`.

L'écran de timer affiche :

- le nom de la séance ;
- la phase en cours ;
- le temps estimé restant ;
- l'affichage principal du timer ;
- la progression globale ;
- les contrôles de séance.

### 7. Utiliser le timer pendant l'entraînement

Les phases principales sont :

- préparation ;
- compte à rebours ;
- série active ;
- repos ;
- transition ;
- pause ;
- fin de séance.

Comportement notable :

- au tout début, la préparation dure `5s` et inclut le `3-2-1` final ;
- pendant une série active en mode manuel, le bouton principal est `Série terminée` ;
- le bouton `Passer` permet de sauter à l'étape suivante ;
- le bouton `Précédent` revient à la série précédente ;
- le bouton central permet de mettre en pause puis de reprendre ;
- `Arrêter la séance` demande une confirmation.

Quand la séance est terminée :

- un bouton `Retour à l'accueil` est affiché.

## Données locales

Les données sont stockées localement sur l'appareil via `SharedPreferences`.

Cela inclut :

- les séances enregistrées ;
- la voix sélectionnée ;
- l'état d'activation de la voix ;
- certains drapeaux de configuration locale.

Conséquences :

- pas de synchronisation entre appareils ;
- pas de compte utilisateur ;
- désinstaller l'application ou vider son stockage efface les données locales.

## Développement et qualité

Commandes utiles :

```bash
make app-get
make app-analyze
make app-test
make check
```

Le projet s'appuie notamment sur :

- `flutter_riverpod` pour l'état ;
- `go_router` pour la navigation ;
- `shared_preferences` pour la persistance locale ;
- `flutter_tts` pour la voix ;
- `uuid` pour les identifiants.

## Dépannage rapide

### Aucune voix n'apparaît

Vérifiez :

- qu'un moteur TTS est bien installé sur l'appareil ;
- qu'Android a téléchargé au moins une voix locale ;
- que le son multimédia du téléphone n'est pas coupé.

### L'appareil Android n'est pas détecté

Vérifiez :

- que le débogage USB est activé ;
- que la clé RSA ADB a bien été acceptée sur le téléphone ;
- que `adb devices` ou `make app-adb-devices` affiche bien l'appareil.

### Les séances ont disparu

Les données sont locales. Si le stockage de l'application a été vidé ou si l'application a été réinstallée, les séances précédentes ne sont plus disponibles.

## Résumé du flux utilisateur

1. Ouvrir l'application.
2. Choisir ou créer une séance.
3. Si besoin, configurer une voix.
4. Démarrer la séance.
5. Suivre le timer et les transitions.
6. Revenir à l'accueil en fin de séance.
