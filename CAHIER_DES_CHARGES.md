# Cahier des charges — App de suivi sportif compétitif (XEFI)

## 1. Vision

Application mobile Flutter permettant aux collaborateurs XEFI de suivre leurs
activités sportives, de se comparer entre collègues, et de créer une
émulation collective via un système de classements individuels et d'équipes.
L'app doit être **simple, belle, performante**, et respecter l'identité
visuelle XEFI.

Nom de travail : **XEFI Sport** (à confirmer/changer librement).

## 2. Contraintes obligatoires

- **Le projet est 100% Flutter côté code applicatif.** On n'écrit pas de
  backend dans un autre langage. Les données partagées (comptes,
  classements, contacts) vivent dans **Supabase** (backend-as-a-service :
  Postgres + Auth + API REST auto-générée + Realtime), configuré via du SQL
  (schéma, policies) plutôt que du code serveur qu'on développe nous-mêmes.
  Aucune persistance uniquement locale (pas de "tout en Hive/SQLite embarqué
  sans backend") : Supabase est la source de vérité, le mobile s'y connecte
  directement avec le SDK `supabase_flutter`.
- **La contrainte imposée de base : intégrer une API externe tierce**, sur
  le principe d'une app de stats League of Legends qui consomme l'API Riot
  Games — une vraie fonctionnalité doit s'appuyer sur un service tiers
  plutôt que tout recalculer nous-mêmes. Deux retenues, chacune sur un
  rôle différent — voir section 4 :
  - **wger.de** — catalogue de sports/exercices (gratuite, sans clé).
  - **Calories Burned API (api-ninjas.com)** — calcul des calories brûlées
    par séance (clé gratuite requise, appelée depuis une Supabase Edge
    Function pour ne jamais exposer la clé côté mobile).
- Cible principale : **Android** (testé sur émulateur), l'app doit rester
  compatible iOS sans usage d'API spécifique à une plateforme.
- Respect strict de l'identité visuelle XEFI (section 8).
- Code cohérent entre les deux contributeurs : ce document fait foi pour les
  deux — toute déviation d'architecture doit être discutée avant d'être
  codée, pas décidée en solo dans une PR.
- **Tout le code est en anglais** : noms de fichiers, de classes, de
  fonctions, de variables, de tables/colonnes SQL, messages de commit. Seul
  le texte affiché à l'utilisateur final (labels UI) peut rester en
  français, puisque l'app s'adresse à des collaborateurs francophones. Voir
  section 9 pour le détail.
- **Nommage explicite plutôt que commentaires.** Le code doit se lire sans
  commentaire : un nom de variable/fonction/classe doit dire ce qu'il fait.
  Un commentaire n'est acceptable que pour expliquer un "pourquoi" non
  évident (contrainte externe, contournement, piège), jamais pour décrire
  un "quoi" que le nommage aurait pu porter.

## 3. Fonctionnalités

### Socle commun (V1, obligatoire)

- Création de compte / connexion (email + mot de passe, via Supabase Auth).
- Rejoindre une équipe est **optionnel** (l'app est utilisable sans jamais
  en rejoindre une — voir "Contacts" ci-dessous pour l'alternative).
- Ajout de collègues en **contacts** : recherche par nom/email, envoi d'une
  demande, acceptation par l'autre. Relation neutre entre professionnels
  ("contact"), pas un système "ami" façon réseau social.
- Enregistrement d'une séance de sport : sport pratiqué, durée ou nombre de
  séances, date.
- Historique personnel des séances.
- Système de points : chaque séance rapporte des points (barème simple,
  voir section 5).

### Lot A — Suivi & profil individuel

- Catalogue de sports peuplé depuis **wger.de** plutôt qu'écrit à la main
  (voir section 4 pour le mécanisme de synchronisation) + éventuel ajout
  libre par un utilisateur.
- Écran de saisie d'une séance (formulaire rapide, optimisé mobile).
- **Suivi GPS pour les sports outdoor** (course à pied, vélo, marche —
  déterminé par `sports.is_gps_trackable`) : carte en direct qui trace le
  parcours pendant la séance, distance, vitesse instantanée et dénivelé
  calculés à la volée. À la fin de la séance, le tracé, la distance et le
  dénivelé sont envoyés avec la séance (voir section 5 et 6).
- Intégration de la Calories Burned API : à l'enregistrement d'une séance,
  l'app appelle l'Edge Function `calculate-calories` (activité + poids de
  l'utilisateur + durée) qui relaie vers l'API externe et renvoie le nombre
  de calories brûlées, stocké avec la séance.
- Écran "Mon profil" : historique, total de points, calories brûlées
  cumulées, séries (streaks), répartition par sport (graphique simple).
- Gestion du compte (inscription, connexion, déconnexion, édition profil —
  le poids de l'utilisateur est requis pour le calcul de calories).
- Écran "Contacts" : rechercher un collègue, envoyer/accepter une demande,
  lister ses contacts, en retirer un.

### Lot B — Classements & compétition

- Classement individuel **par sport** (ex: top coureurs, top nageurs...).
- Classement individuel **global** (tous sports confondus, somme des points).
- Classement **par équipe**, uniquement pour les utilisateurs qui en ont
  rejoint une (n'apparaît pas comme un onglet obligatoire pour tout le monde).
- Classement **parmi mes contacts** : mêmes points/périodes, mais filtré
  aux seuls contacts acceptés de l'utilisateur — l'alternative à l'équipe
  pour quelqu'un qui n'en a pas rejoint.
- Écran "Classements" avec onglets (Global / Par sport / Mes contacts /
  Équipes — ce dernier caché si l'utilisateur n'a pas d'équipe).
- Mise en avant du rang de l'utilisateur connecté (ex: "Tu es 4e sur 32").

> Cette séparation en deux lots est une proposition de base pour répartir le
> travail à deux. Le schéma de données partagé (section 5) et les vues/RPC
> de classement (section 6) sont **partagés et ne doivent pas être modifiés
> unilatéralement** par un seul lot — toute évolution passe par une PR
> dédiée, revue par les deux devs.

### V2 (hors périmètre initial, backlog)

- Badges / paliers de récompense.
- Notifications (rappel quotidien, changement de classement).
- Défis entre équipes sur une période donnée.
- Photo de profil, avatars.

## 4. Architecture technique

Projet **100% Flutter** côté code applicatif — pas de backend qu'on
développe nous-mêmes dans un autre langage. Les données partagées vivent
dans **Supabase**, configuré en SQL (schéma, Row Level Security, vues) et
via une Edge Function minimale pour cacher une clé API. Tout le reste est
du Dart.

```
repo/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/                   # thème, constantes, client Supabase, config env
│   ├── models/                 # classes de données (User, Team, Sport, Session)
│   ├── data/                   # repositories (appels supabase_flutter)
│   ├── providers/               # state management (Riverpod)
│   ├── screens/                  # écrans (un dossier par feature)
│   └── widgets/                   # composants réutilisables
├── test/
├── supabase/
│   ├── migrations/               # schéma SQL (tables, policies, vues, RPC)
│   ├── functions/
│   │   └── calculate-calories/    # Edge Function (Deno/TS) — appel à la Calories Burned API
│   └── seed/sports_from_wger.sql  # généré une fois par tool/sync_sports_from_wger.dart
└── tool/
    └── sync_sports_from_wger.dart # script Dart ponctuel, pas un service qui tourne en continu
```

**Stack retenue :**

- **Flutter** (Dart) — state management : **Riverpod** (`flutter_riverpod`).
  Pas de setState global, pas de mélange de state managers.
- **Supabase** comme backend, via le package `supabase_flutter` : auth,
  requêtes Postgres (CRUD direct sur les tables avec son query builder,
  filtré par Row Level Security), et Realtime pour que les classements se
  mettent à jour en direct sans qu'on ait à coder du polling.
- **Base de données : Postgres géré par Supabase.** Le schéma (section 5)
  est défini en SQL dans `supabase/migrations/`, avec **Row Level Security
  activée sur chaque table** — chacun ne peut modifier que ses propres
  données (`user_id = auth.uid()`), la lecture des classements reste
  publique en lecture seule.
- **Auth : Supabase Auth** (email + mot de passe intégré, gère les tokens
  et les sessions — pas de JWT à coder nous-mêmes).
- **Classements : vues/fonctions SQL** (`rankings_global`,
  `rankings_by_sport`, `rankings_teams`, `rankings_contacts`) définies dans
  les migrations et exposées automatiquement en REST par Supabase
  (PostgREST) — pas de route à coder, juste du SQL versionné.
- **API externe #1 (calories) :** une **Supabase Edge Function**
  (`calculate-calories`, quelques lignes de TypeScript/Deno — pas un
  backend applicatif) reçoit `{activity, weightKg, durationMin}`, appelle
  `api.api-ninjas.com` avec la clé stockée en secret Supabase
  (`CALORIES_API_KEY`), et renvoie `caloriesBurned`. C'est le seul bout de
  code qui n'est pas du Dart, et il n'existe que pour ne jamais exposer la
  clé API dans le bundle Flutter.
- **API externe #2 (catalogue de sports) :** `tool/sync_sports_from_wger.dart`
  est un script Dart exécuté **une fois** (pas un service qui tourne en
  continu) pour appeler `wger.de/api/v2/exercisecategory` et `/exercise`,
  et générer `supabase/seed/sports_from_wger.sql`, appliqué à la base au
  démarrage du projet. Ça nous laisse ajouter nos propres colonnes
  (`emoji`, `points_per_unit`) que wger n'a pas.
- **Suivi GPS :** `geolocator` pour le flux de position, `flutter_map` +
  `latlong2` pour la carte, avec des tuiles **OpenStreetMap** — gratuites et
  sans clé API, contrairement à Google Maps qui demande une facturation
  activée dès le premier appel. Distance (formule de Haversine entre points
  consécutifs) et dénivelé (somme des montées) calculés côté Flutter pendant
  l'enregistrement, envoyés avec la séance.
- Pas de dépendance native lourde côté Flutter sans raison forte (ex: évitez
  tout package qui tire `path_provider`/JNI si un équivalent HTTP simple
  existe — source de plantages Gradle constatée sur ce projet).

## 5. Modèle de données (base commune, ne pas dévier sans concertation)

Tables Postgres (Supabase), noms en `snake_case` anglais. `profiles.id`
référence `auth.users.id` (Supabase Auth gère le mot de passe, on ne stocke
jamais de hash nous-mêmes).

```
profiles
  id              uuid (PK, = auth.users.id)
  name            text
  weight_kg       numeric        # requis pour le calcul de calories brûlées
  team_id         uuid (FK teams, nullable)
  created_at      timestamptz

teams
  id              uuid (PK)
  name            text
  color_value     integer        # couleur d'équipe, cohérente avec la charte
  created_at      timestamptz

contacts
  id              uuid (PK)
  requester_id    uuid (FK profiles)
  addressee_id    uuid (FK profiles)
  status          text check (status in ('pending', 'accepted'))
  created_at      timestamptz

sports
  id                uuid (PK)
  name              text
  emoji             text
  points_per_unit   integer      # points attribués par séance ou par tranche de temps
  wger_id           integer (nullable)   # id d'origine côté wger.de, pour re-synchroniser
  is_gps_trackable  boolean      # true pour course à pied, vélo, marche...

sessions
  id                 uuid (PK)
  user_id            uuid (FK profiles)
  sport_id           uuid (FK sports)
  date               date
  duration_min       integer
  points             integer          # calculé côté client à l'enregistrement
  calories_burned    numeric          # rempli via l'Edge Function calculate-calories
  distance_km        numeric (nullable)   # uniquement si sports.is_gps_trackable
  elevation_gain_m    numeric (nullable)  # dénivelé positif cumulé
  route              jsonb (nullable)     # [{lat, lng, altitude, timestampMs}, ...]
  created_at         timestamptz
```

**Barème de points (V1, simple) :** `points = duration_min` (1 minute = 1
point). Facile à comprendre, ajustable plus tard par sport si besoin
(`points_per_unit` est déjà prévu pour ça).

**Row Level Security (principe pour chaque table) :** un utilisateur peut
lire toutes les lignes utiles aux classements (`sessions`, `profiles` en
lecture publique restreinte aux champs nécessaires), mais ne peut
insérer/modifier/supprimer que les lignes où `user_id = auth.uid()` (ou
`requester_id` pour `contacts`). Les policies exactes sont définies dans
les migrations SQL, pas laissées à l'appréciation de chaque dev.

## 6. Accès aux données (Supabase, pas de routes à coder)

Pas de contrat de routes REST à écrire : `supabase_flutter` interroge
directement les tables (CRUD via le query builder, filtré par Row Level
Security), et les classements/actions qui demandent un calcul passent par
du SQL versionné ou l'Edge Function ci-dessous.

| Besoin                              | Mécanisme Supabase                                         |
|--------------------------------------|--------------------------------------------------------------|
| Inscription / connexion              | `supabase.auth.signUp()` / `signInWithPassword()`            |
| Profil connecté                      | `supabase.from('profiles').select().eq('id', uid)`            |
| Liste / création d'équipes           | CRUD direct sur `teams` (lecture publique, écriture authentifiée) |
| Contacts (demande, accepter, lister, retirer) | CRUD direct sur `contacts`, filtré par RLS sur `requester_id`/`addressee_id` |
| Liste / ajout libre de sports        | CRUD direct sur `sports`                                     |
| Historique de séances                | `supabase.from('sessions').select().eq('user_id', uid)`       |
| Enregistrer une séance               | 1) appel à l'Edge Function `calculate-calories` pour obtenir `caloriesBurned`, 2) insert dans `sessions` avec ce résultat |
| Classement global / par sport / équipes / contacts | `SELECT` sur les vues SQL `rankings_global`, `rankings_by_sport`, `rankings_teams`, `rankings_contacts` |

L'Edge Function `calculate-calories` est le seul point de passage vers
l'API externe de calories : le Flutter n'appelle jamais
`api.api-ninjas.com` directement, la clé reste secrète côté Supabase.

Ce document (schéma + vues) est le point de synchronisation entre les deux
lots : le Lot A peut développer son UI contre le schéma de `sessions`/
`profiles` pendant que le Lot B écrit les vues de classement, et
inversement.

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
- Avant toute PR : `flutter analyze` + `flutter test` doivent passer sans
  erreur. Toute migration SQL (`supabase/migrations/`) doit s'appliquer
  proprement sur une base vide (`supabase db reset` en local).
- Le schéma de données et les vues de classement (sections 5 et 6) ne se
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
  couleurs d'équipe (`teams.color_value`) utilisées uniquement pour des
  badges/étiquettes, jamais en fond plein écran.

## 9. Conventions de code

**Langue et nommage (obligatoire, les deux lots)**

- Code 100% en anglais : `sessionRepository`, `computeStreak()`,
  `TeamRankingScreen`, tables/colonnes SQL (`duration_min`, `team_id`...),
  noms de fichiers (`session_repository.dart`, `team_ranking_screen.dart`,
  `20260910_create_sessions_table.sql`...). Aucun mot français dans le
  code, y compris dans les noms de variables temporaires ou de tests.
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
- Aucune clé secrète en dur dans le code Dart (clé Supabase anon key
  publique OK, mais jamais de clé d'API tierce type `CALORIES_API_KEY`).

**Supabase (SQL / Edge Functions)**

- Une migration = un changement cohérent (une table, ou une évolution
  claire), jamais un gros dump fourre-tout.
- Row Level Security activée sur **toutes** les tables dès leur création —
  pas de table "on sécurisera plus tard".
- Vues de classement en SQL pur, testées manuellement avec des données de
  seed avant d'être branchées à l'UI.
- L'Edge Function `calculate-calories` ne fait que relayer l'appel externe
  et formatter la réponse — aucune autre logique métier dedans.

## 10. Definition of Done (V1)

- [ ] Un utilisateur peut créer un compte, se connecter, et éventuellement
      rejoindre une équipe ou ajouter des contacts (aucun des deux n'est
      obligatoire pour utiliser l'app).
- [ ] Un utilisateur peut enregistrer une séance de sport (avec suivi GPS
      pour un sport outdoor).
- [ ] Les classements individuel global, par sport, et parmi mes contacts
      s'affichent et se mettent à jour après une nouvelle séance ; le
      classement par équipe fonctionne pour un utilisateur qui en a une.
- [ ] L'app respecte la charte XEFI (couleurs, police, logo).
- [ ] `flutter analyze` et `flutter test` passent sans erreur.
- [ ] L'app tourne sur l'émulateur Android sans crash sur le parcours
      principal (inscription → séance → classement).
- [ ] Les migrations Supabase s'appliquent proprement sur une base vide.
- [ ] Une séance enregistrée affiche bien des calories brûlées cohérentes
      (issues de la Calories Burned API via l'Edge Function, pas une valeur
      inventée/statique).

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

**Stack technique**

- https://github.com/xefi (organisation GitHub publique XEFI, 32 dépôts) et
  https://github.com/xefi/laravel-rest-api-flutter (package officiel XEFI :
  Flutter ↔ API REST Laravel) avaient initialement motivé un choix de
  backend Laravel. **Ce choix a été abandonné** : le périmètre du projet
  est explicitement Flutter uniquement, donc le backend est un BaaS
  (Supabase) plutôt qu'un serveur qu'on développe nous-mêmes. Gardé ici
  comme trace de la décision, pas comme choix retenu.

**API externe**

- https://api-ninjas.com/api/caloriesburned (Calories Burned API — clé
  gratuite sans carte bancaire, endpoint `GET /v1/caloriesburned`)
- https://wger.de/api/v2/ (wger — open source, endpoints publics testés
  sans clé le 2026-09-10, ex. `GET /api/v2/exercisecategory/?format=json`
  → 8 catégories retournées en direct) ; dépôt :
  https://github.com/wger-project/wger

**Backend**

- https://supabase.com/docs (Auth, Postgres, Row Level Security, Edge
  Functions, package Flutter `supabase_flutter`)
