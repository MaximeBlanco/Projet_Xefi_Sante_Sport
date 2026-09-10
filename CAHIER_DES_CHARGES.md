# Cahier des charges — App de suivi sportif compétitif (XEFI)

## 1. Vision

Application mobile Flutter permettant aux collaborateurs XEFI de suivre leurs
activités sportives, de se comparer entre collègues, et de créer une
émulation collective via un système de classements individuels et d'équipes.
L'app doit être **simple, belle, performante**, et respecter l'identité
visuelle XEFI.

Nom de travail : **XEFI Sport** (à confirmer/changer librement).

## 2. Contraintes obligatoires

- **Une API REST est obligatoire.** Aucune persistance uniquement locale
  (pas de "tout en Hive/SQLite embarqué sans backend"). Le stockage central
  (base de données côté serveur) est la source de vérité ; le mobile
  consomme l'API en HTTP/JSON.
- **Une API externe tierce est obligatoire en plus de notre propre API**,
  sur le même principe qu'une app de stats League of Legends qui consomme
  l'API Riot Games : notre backend reste la source de vérité pour nos
  données (users, teams, sessions, rankings), mais une fonctionnalité doit
  enrichir ces données via un service tiers plutôt que tout recalculer
  nous-mêmes. Choix retenu : **Calories Burned API (api-ninjas.com)** — voir
  section 4.
- Cible principale : **Android** (testé sur émulateur), l'app doit rester
  compatible iOS sans usage d'API spécifique à une plateforme.
- Respect strict de l'identité visuelle XEFI (section 8).
- Code cohérent entre les deux contributeurs : ce document fait foi pour les
  deux — toute déviation d'architecture doit être discutée avant d'être
  codée, pas décidée en solo dans une PR.
- **Tout le code est en anglais** : noms de fichiers, de classes, de
  fonctions, de variables, de routes API, de champs JSON, messages de
  commit. Seul le texte affiché à l'utilisateur final (labels UI) peut
  rester en français, puisque l'app s'adresse à des collaborateurs
  francophones. Voir section 9 pour le détail.
- **Nommage explicite plutôt que commentaires.** Le code doit se lire sans
  commentaire : un nom de variable/fonction/classe doit dire ce qu'il fait.
  Un commentaire n'est acceptable que pour expliquer un "pourquoi" non
  évident (contrainte externe, contournement, piège), jamais pour décrire
  un "quoi" que le nommage aurait pu porter.

## 3. Fonctionnalités

### Socle commun (V1, obligatoire)

- Création de compte / connexion (email + mot de passe, JWT).
- Choix d'une équipe à l'inscription (liste d'équipes existantes, ou création
  si aucune ne convient).
- Enregistrement d'une séance de sport : sport pratiqué, durée ou nombre de
  séances, date.
- Historique personnel des séances.
- Système de points : chaque séance rapporte des points (barème simple,
  voir section 5).

### Lot A — Suivi & profil individuel

- CRUD des sports disponibles (liste prédéfinie + éventuel ajout libre).
- Écran de saisie d'une séance (formulaire rapide, optimisé mobile).
- Intégration de la Calories Burned API : à l'enregistrement d'une séance,
  le backend appelle l'API externe (activité + poids de l'utilisateur +
  durée) et stocke le nombre de calories brûlées retourné.
- Écran "Mon profil" : historique, total de points, calories brûlées
  cumulées, séries (streaks), répartition par sport (graphique simple).
- Gestion du compte (inscription, connexion, déconnexion, édition profil —
  le poids de l'utilisateur est requis pour le calcul de calories).

### Lot B — Classements & compétition

- Classement individuel **par sport** (ex: top coureurs, top nageurs...).
- Classement individuel **global** (tous sports confondus, somme des points).
- Classement **par équipe** (somme des points de tous les membres).
- Écran "Classements" avec onglets (Global / Par sport / Équipes).
- Mise en avant du rang de l'utilisateur connecté (ex: "Tu es 4e sur 32").

> Cette séparation en deux lots est une proposition de base pour répartir le
> travail à deux. Le contrat d'API (section 6) et le modèle de données
> (section 5) sont **partagés et ne doivent pas être modifiés unilatéralement**
> par un seul lot — toute évolution du contrat se fait via une PR dédiée,
> revue par les deux devs.

### V2 (hors périmètre initial, backlog)

- Badges / paliers de récompense.
- Notifications (rappel quotidien, changement de classement).
- Défis entre équipes sur une période donnée.
- Photo de profil, avatars.

## 4. Architecture technique

```
repo/
├── app/                       # Application Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/              # thème, constantes, client API, config env
│   │   ├── models/            # classes de données (User, Team, Sport, Session)
│   │   ├── data/               # repositories (laravel_rest_api_flutter)
│   │   ├── providers/          # state management (Riverpod)
│   │   ├── screens/            # écrans (un dossier par feature)
│   │   └── widgets/            # composants réutilisables
│   └── test/
└── server/                    # API Laravel
    ├── app/
    │   ├── Http/Controllers/Api/   # un contrôleur par ressource
    │   ├── Http/Requests/           # validation des entrées (Form Requests)
    │   ├── Http/Resources/          # formatage JSON des réponses
    │   ├── Models/                  # User, Team, Sport, Session
    │   └── Services/CaloriesBurnedService.php   # appel à l'API externe
    ├── routes/api.php
    ├── database/migrations/
    └── tests/
```

**Stack retenue :**

- **Flutter** (Dart) — state management : **Riverpod** (`flutter_riverpod`).
  Pas de setState global, pas de mélange de state managers. Côté accès
  réseau, utiliser le package officiel **XEFI `laravel_rest_api_flutter`**
  (https://pub.dev/packages/laravel_rest_api_flutter,
  doc : https://xefi.github.io/laravel-rest-api-flutter-doc/) plutôt que
  du `http`/`dio` brut — c'est l'outil que XEFI maintient publiquement pour
  connecter une app Flutter à une API Laravel (repositories typés, search,
  mutate, actions). L'utiliser nous met dans les clous de leurs pratiques
  réelles, pas juste dans un style "générique".
- **Laravel (PHP)** pour l'API — c'est le pendant naturel du package Flutter
  ci-dessus, et le stack que XEFI utilise réellement pour ses API mobiles
  (voir section 11). Construire les endpoints selon les conventions REST
  Laravel standard (Controllers + Form Requests + API Resources) pour que
  `laravel_rest_api_flutter` s'y branche sans friction.
- **Base de données : SQLite** en V1 (fichier unique, zéro configuration,
  suffisant pour deux devs qui développent chacun en local ; migrable vers
  MySQL/PostgreSQL plus tard via les migrations Laravel sans changer le
  code métier).
- **Auth : Laravel Sanctum** (tokens d'API, l'approche standard Laravel pour
  une API consommée par une app mobile — équivalent JWT mais intégré nativement).
- **API externe (calories) :** `CaloriesBurnedService` côté Laravel appelle
  `https://api.api-ninjas.com/v1/caloriesburned` avec la clé API stockée en
  `.env` (`CALORIES_API_KEY`), **jamais exposée côté Flutter**. Le mobile ne
  parle qu'à notre propre API, qui fait elle-même le relais vers le service
  externe — voir contrat d'API section 6.
- Pas de dépendance native lourde côté Flutter sans raison forte (ex: évitez
  tout package qui tire `path_provider`/JNI si un équivalent HTTP simple
  existe — source de plantages Gradle constatée sur ce projet).

## 5. Modèle de données (base commune, ne pas dévier sans concertation)

```
User
  id            String (uuid)
  name          String
  email         String (unique)
  passwordHash  String
  weightKg      Float       # requis pour le calcul de calories brûlées
  teamId        String (FK Team, nullable)
  createdAt     DateTime

Team
  id            String (uuid)
  name          String
  colorValue    Int         # couleur d'équipe, cohérente avec la charte
  createdAt     DateTime

Sport
  id            String (uuid)
  name          String
  emoji         String
  pointsPerUnit Int         # points attribués par séance ou par tranche de temps

Session
  id              String (uuid)
  userId          String (FK User)
  sportId         String (FK Sport)
  date            DateTime
  durationMin     Int
  points          Int          # calculé côté serveur à l'enregistrement
  caloriesBurned  Float        # rempli via l'appel à la Calories Burned API
  createdAt       DateTime
```

**Barème de points (V1, simple) :** `points = durationMin` (1 minute = 1
point). Facile à comprendre, ajustable plus tard par sport si besoin
(`pointsPerUnit` est déjà prévu pour ça).

## 6. Contrat d'API (V1)

Toutes les routes sous `/api`. Réponses en JSON. Erreurs au format
`{ "error": "message" }` avec le code HTTP adapté (400/401/404/500).

| Méthode | Route                        | Auth | Description                                  |
|---------|-------------------------------|------|-----------------------------------------------|
| POST    | `/auth/register`             | non  | Crée un compte `{name, email, password, teamId?}` |
| POST    | `/auth/login`                | non  | `{email, password}` → `{token, user}`         |
| GET     | `/me`                         | oui  | Profil de l'utilisateur connecté              |
| GET     | `/teams`                      | non  | Liste des équipes                             |
| POST    | `/teams`                      | oui  | Crée une équipe `{name, colorValue}`          |
| GET     | `/sports`                     | non  | Liste des sports disponibles                  |
| GET     | `/sessions?userId=`           | oui  | Historique de séances (soi-même par défaut)   |
| POST    | `/sessions`                   | oui  | Enregistre une séance `{sportId, date, durationMin}` → appelle en interne la Calories Burned API et renvoie la séance avec `caloriesBurned` rempli |
| GET     | `/rankings/global`            | non  | Classement individuel toutes activités confondues |
| GET     | `/rankings/sport/:sportId`    | non  | Classement individuel pour un sport donné     |
| GET     | `/rankings/teams`             | non  | Classement par équipe                         |

`POST /sessions` est la seule route qui touche l'API externe : le Flutter
n'appelle jamais `api.api-ninjas.com` directement, tout passe par notre
backend (clé API tenue secrète, et le calcul reste correct même si l'API
externe change de format un jour — un seul endroit à corriger).

Ce contrat est le point de synchronisation entre les deux lots : le Lot A
peut développer son UI contre des réponses mockées respectant ce format
pendant que le Lot B implémente les routes de classement, et inversement.

## 7. Git & workflow (GitHub, duo)

- Branche protégée : `main` (jamais de push direct, toujours via Pull
  Request).
- Nommage des branches : `feature/<lot>-<description>`, ex.
  `feature/lotA-ecran-saisie-seance`, `feature/lotB-classement-equipes`.
- Commits au format **Conventional Commits** :
  `feat: ajoute l'écran de classement global`,
  `fix: corrige le calcul du streak`,
  `chore: met à jour les dépendances`.
- Une PR = une fonctionnalité cohérente, pas un gros paquet fourre-tout.
  Description de PR : quoi, pourquoi, comment tester.
- **Revue croisée obligatoire** : chaque PR est relue par l'autre
  développeur avant merge, même en solo-review rapide — l'objectif est
  la cohérence de style et d'archi, pas juste "ça compile".
- Avant toute PR : `flutter analyze` + `flutter test` côté app,
  `php artisan test` côté serveur doivent passer sans erreur.
- Le contrat d'API (section 6) et le schéma de données (section 5) ne se
  modifient que dans une PR dédiée, explicitement signalée aux deux devs.

## 8. Identité visuelle XEFI (Design System)

Couleurs et typographies extraites directement du site officiel xefi.fr
(inspection CSS, pas une estimation) :

| Rôle                  | Couleur      | Usage                                  |
|-----------------------|--------------|------------------------------------------|
| Primaire (accent)     | `#E10600`    | CTA, éléments actifs, rang de l'utilisateur, badges de podium |
| Noir                  | `#000000`    | Header/AppBar, texte fort               |
| Blanc                 | `#FFFFFF`    | Fond principal                          |
| Texte secondaire      | `#2B2D42`    | Corps de texte, sous-titres             |

- **Typographie :** Montserrat (corps de texte). Les titres du site XEFI
  utilisent une police propriétaire ("Nomixa") non disponible publiquement —
  utiliser **Montserrat ExtraBold/700** en fallback pour les titres afin de
  rester dans le même esprit géométrique et impactant.
- **Ton visuel :** corporate, sobre, contrasté noir/blanc avec le rouge en
  ponctuation forte (pas de saturation excessive de couleurs). Boutons à
  bords arrondis (pill-shaped sur le site), beaucoup de blanc/espace.
- **Logo :** utiliser le logo officiel XEFI (SVG, version blanche pour fond
  sombre) — à récupérer depuis le site officiel ou demander l'asset en
  interne plutôt que le re-générer. Ne pas déformer/recolorer le logo.
- Application concrète dans l'app : AppBar noire avec logo, accent rouge
  réservé aux éléments d'action et à la mise en valeur du classement
  (médaille/couleur du rang 1-2-3), fond blanc, cartes avec ombre légère,
  couleurs d'équipe (`Team.colorValue`) utilisées uniquement pour des
  badges/étiquettes, jamais en fond plein écran.

## 9. Conventions de code

**Langue et nommage (obligatoire, les deux lots)**

- Code 100% en anglais : `sessionRepository`, `computeStreak()`,
  `TeamRankingScreen`, champs JSON (`durationMin`, `teamId`...), noms de
  fichiers (`session_repository.dart`, `team_ranking_screen.dart`,
  `rankings.route.js`...). Aucun mot français dans le code, y compris dans
  les noms de variables temporaires ou de tests.
- Seules les chaînes affichées à l'écran (`Text('Mes séances')`,
  messages d'erreur utilisateur) restent en français — elles sont data,
  pas identifiants de code.
- Noms longs et explicites plutôt que courts et ambigus :
  `hasReachedWeeklyGoal` plutôt que `flag`, `toggleSessionCompletion()`
  plutôt que `toggle()`. Un nom qui a besoin d'un commentaire pour être
  compris est un mauvais nom — le renommer plutôt que le commenter.
- Pas de commentaire descriptif ("// loop over users") : si le commentaire
  répète ce que dit déjà le code, il est supprimé au profit d'un meilleur
  nom. Un commentaire ne survit que s'il explique un pourquoi non déductible
  du code lui-même.

**Flutter/Dart**

- `flutter_lints` actif, `flutter analyze` sans warning avant toute PR.
- Un fichier = une classe publique principale, nommage `snake_case.dart`.
- Pas de `print()` en prod ; pas de logique métier dans les widgets
  (déléguer aux providers/repositories).
- State management : Riverpod partout, pas de `setState` pour de l'état
  partagé entre écrans.
- Toute couleur/police vient de `core/theme` — jamais de couleur en dur
  dans un widget d'écran.

**Laravel/API**

- Un contrôleur par ressource (`Http/Controllers/Api/SessionController.php`),
  méthodes fines (`index`, `store`, `show`...), pas de logique métier dedans.
- Validation via **Form Requests** dédiées (`StoreSessionRequest`), jamais de
  `$request->validate()` inline dans un contrôleur.
- Réponses formatées via **API Resources** (`SessionResource`) pour garder
  un JSON stable et cohérent, découplé du schéma de base de données.
- Appel à l'API externe encapsulé dans un **Service** dédié
  (`CaloriesBurnedService`), injecté dans le contrôleur — jamais d'appel
  HTTP direct depuis un contrôleur ou un modèle.
- Erreurs toujours au format `{ "error": "..." }`, jamais de stack trace
  renvoyée au client (gérer ça dans le handler d'exceptions Laravel).
- PSR-12 comme style de code PHP (respecté nativement par Laravel Pint).

## 10. Definition of Done (V1)

- [ ] Un utilisateur peut créer un compte, se connecter, choisir une équipe.
- [ ] Un utilisateur peut enregistrer une séance de sport.
- [ ] Le classement individuel global, par sport, et par équipe s'affichent
      et se mettent à jour après une nouvelle séance.
- [ ] L'app respecte la charte XEFI (couleurs, police, logo).
- [ ] `flutter analyze` et `flutter test` passent sans erreur.
- [ ] L'app tourne sur l'émulateur Android sans crash sur le parcours
      principal (inscription → séance → classement).
- [ ] Toutes les routes du contrat d'API (section 6) sont implémentées et
      testées manuellement (ex: via un fichier `.http` ou Postman).
- [ ] Une séance enregistrée affiche bien des calories brûlées cohérentes
      (issues de la Calories Burned API, pas une valeur inventée/statique).

## 11. Sources

**Identité visuelle**

- https://www.xefi.fr/fr/decouvrir-xefi/a-propos-de-nous/qui-sommes-nous/
  (couleurs extraites du CSS calculé, police body/h1, logo)
- https://brandfetch.com/xefi.fr (tentative de vérification croisée,
  inaccessible au moment de la rédaction — à revérifier si besoin d'assets
  supplémentaires)
- Recherche d'une charte graphique publique (GitHub org `xefi`, recherche
  web) : aucun document de charte publié publiquement trouvé — probablement
  un document interne. À demander en interne si des règles plus précises
  sont nécessaires (variantes de logo, marges de sécurité...).

**Stack technique XEFI**

- https://github.com/xefi (organisation GitHub publique XEFI, 32 dépôts)
- https://github.com/xefi/laravel-rest-api-flutter (package officiel XEFI :
  intégration Flutter ↔ API REST Laravel)
- https://xefi.github.io/laravel-rest-api-flutter-doc/ (documentation du
  package, a guidé le choix de Laravel + Sanctum comme backend)

**API externe**

- https://api-ninjas.com/api/caloriesburned (Calories Burned API — clé
  gratuite sans carte bancaire, endpoint `GET /v1/caloriesburned`)
