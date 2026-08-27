# Suivi Mobile Money / Orange Money — Phase 1 (Android, 100% local)

## ⚠️ À savoir avant de commencer

Ce code a été écrit dans un environnement **sans Flutter, sans SDK Android et
sans accès réseau** — il n'a donc pas pu être compilé ni exécuté avant de
t'être livré. Il est structuré et raisonné avec soin, mais traite-le comme un
premier jet à valider, pas comme un binaire testé. Les zones les plus
susceptibles de demander un ajustement mineur :
- l'API exacte du package `telephony` (versions récentes parfois différentes) ;
- les regex de parsing, si tes SMS réels varient légèrement des formats fournis ;
- le nommage des dépendances dans `pubspec.yaml` (versions à jour au moment
  où tu lanceras `flutter pub get`).

Lance `flutter analyze` juste après l'installation (étape 3 ci-dessous) : ça
remontera immédiatement toute erreur avant même de compiler.

## Ce que contient ce zip

```
mobile_money_tracker/
├── lib/
│   ├── main.dart                      # point d'entrée, navigation
│   ├── models/                        # Transaction, CategoryRule
│   ├── db/                            # base SQLite locale + données de démo
│   ├── parsing/                       # moteur de parsing SMS + écoute Android
│   ├── services/                      # catégorisation, rapports, export
│   ├── screens/                       # onboarding, liste, détail, dashboard
│   └── widgets/
├── test/
│   └── sms_parser_test.dart           # tests unitaires du moteur de parsing
├── android_manifest_snippet/
│   └── PERMISSIONS_A_AJOUTER.xml      # permissions à copier après flutter create
├── pubspec.yaml
└── README.md                          # ce fichier
```

Notes de conception :
- **SQLite via `sqflite`** plutôt que Drift : Drift demande une génération de
  code (`build_runner`) que je ne pouvais pas exécuter ici pour vérifier le
  résultat. `sqflite` est plus simple à écrire "à la main" de façon fiable et
  reste bien de la vraie base SQLite locale, conforme à ce qu'on avait prévu.
  Rien n'empêche de migrer vers Drift plus tard si tu veux un ORM plus riche.
- **~100 transactions fictives** sont générées automatiquement au premier
  lancement (`SeedDataService`), réparties sur les 90 derniers jours, pour
  que les écrans de liste et de rapports aient tout de suite du contenu
  réaliste (catégories, montants, contacts variés).
- La lecture SMS réelle (`sms_listener.dart`) est écrite et branchée sur le
  moteur de parsing, mais n'a pu être testée sur aucun appareil — prévois un
  test dédié sur un vrai téléphone Android avant de t'y fier.

## Étape 1 — Installer Flutter (si pas déjà fait)

Suis le guide officiel : https://docs.flutter.dev/get-started/install

Vérifie ensuite que tout est en ordre :
```bash
flutter doctor
```
Corrige les éventuels ⚠️/❌ signalés (SDK Android, licences à accepter avec
`flutter doctor --android-licenses`, etc.) avant de continuer.

## Étape 2 — Générer les dossiers de plateforme (android/, ios/)

Ce zip ne contient **que le code Dart** (`lib/`, `test/`, `pubspec.yaml`) : les
dossiers `android/` et `ios/` doivent être générés par ta propre installation
de Flutter, pour être certains qu'ils correspondent exactement à ta version du
SDK (les fichiers binaires du Gradle wrapper, notamment, ne peuvent pas être
fournis à la main de façon fiable).

```bash
cd mobile_money_tracker
flutter create . --project-name mobile_money_tracker --platforms=android
```

Cette commande ne touche pas à `lib/` ni à `pubspec.yaml` existants — elle ne
fait que créer `android/` (et régénère un `pubspec.yaml` par défaut : si ça
arrive, remets celui fourni dans ce zip par-dessus).

Puis ajoute les permissions Android : ouvre
`android/app/src/main/AndroidManifest.xml` et colle-y le contenu de
`android_manifest_snippet/PERMISSIONS_A_AJOUTER.xml` (voir les instructions
dans ce fichier).

## Étape 3 — Installer les dépendances

```bash
flutter pub get
flutter analyze
```

Corrige les erreurs signalées par `flutter analyze` avant de continuer — vu
que ce code n'a pas été compilé avant livraison, c'est l'étape la plus
importante.

## Étape 4 — Lancer les tests du moteur de parsing

```bash
flutter test
```

Tous les tests de `test/sms_parser_test.dart` doivent passer : ils valident
que chaque format de SMS Orange Money / MTN Mobile Money est correctement
reconnu, et que les messages à ignorer (OTP, promos, consultation de solde)
sont bien filtrés.

## Étape 5 — Lancer l'app

Branche un téléphone Android en USB (mode débogage USB activé) ou démarre un
émulateur, puis :

```bash
flutter devices        # vérifier que l'appareil/émulateur est détecté
flutter run
```

Au premier lancement, l'écran d'accueil t'explique l'usage des permissions
SMS et te propose de charger les données de démonstration — accepte pour
explorer immédiatement les écrans Transactions et Rapports.

## Étape 6 — Générer un APK installable

```bash
flutter build apk --release
```

L'APK généré se trouve dans :
```
build/app/outputs/flutter-apk/app-release.apk
```
Transfère-le sur un téléphone Android (autoriser "Sources inconnues" dans les
réglages) pour l'installer directement, en dehors du Play Store.

## Si tu veux aller plus vite : Claude Code

Si tu as Claude Code installé sur ta machine (avec accès réseau, lui), tu
peux lui donner ce zip et lui demander : *"lance flutter create ., corrige les
éventuelles erreurs de flutter analyze, et build-moi l'APK"* — il pourra
exécuter lui-même les commandes ci-dessus et corriger tout problème rencontré
en route, ce que je ne peux pas faire depuis mon environnement actuel.

## Prochaine étape (Phase 2)

Une fois cette Phase 1 validée sur ton téléphone (SMS réels bien reconnus,
édition et rapports fonctionnels), reviens avec le prompt de la Phase 2 :
ajout de la synchronisation Supabase, avec la contrainte de résilience
réseau qu'on avait détaillée (l'app doit rester 100% utilisable hors-ligne).
