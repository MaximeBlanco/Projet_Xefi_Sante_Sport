# Cahier des charges — App de suivi sportif compétitif (XEFI)

## 1. Vision

Application mobile Flutter permettant aux collaborateurs XEFI d'enregistrer
leurs séances de sport et de se comparer via un classement. **Portée
volontairement réduite : ce projet est fait à deux, en 2 jours, avec l'aide
de Claude Code.** Toute idée qui dépasse ce cadre va en section 5
(backlog) — elle n'est pas perdue, juste pas dans la version à livrer.

Nom de travail : **XEFI Sport** (à confirmer/changer librement).

## 2. Contraintes obligatoires

- **Contrainte imposée : intégrer une API externe tierce**, sur le principe
  d'une app de stats League of Legends qui consomme l'API Riot Games.
  Retenue : **Calories Burned API (api-ninjas.com)** — calcule les calories
  brûlées à l'enregistrement d'une séance. Voir section 3.
- **Le projet est 100% Flutter côté code applicatif.** Pas de backend dans
  un autre langage. Les données partagées (comptes, séances, classement)
  vivent dans **Supabase** (Postgres + Auth + API REST auto-générée),
  configuré en SQL plutôt qu'avec un serveur qu'on développe nous-mêmes.
- Cible : **Android** (testé sur émulateur).
- Respect de l'identité visuelle XEFI (section 6).
- **Tout le code est en anglais** (fichiers, classes, variables, tables/
  colonnes SQL, commits). Seul le texte affiché à l'écran reste en
  français. Nommage explicite, pas de commentaire qui décrit un "quoi" que
  le nom aurait pu porter.

## 3. Fonctionnalités — V1 (ce qui doit être fini)

Volontairement court. Chaque ligne doit pouvoir se coder en quelques heures.

- Création de compte / connexion (Supabase Auth, email + mot de passe).
- Enregistrer une séance : choisir un sport dans une **liste fixe** (~10
  sports codés en dur, pas de source externe pour ce V1), durée en minutes,
  date.
- À l'enregistrement, appel à la Calories Burned API (via une Supabase Edge
  Function, voir section 4) avec `{activity, weightKg, durationMin}` →
  calories brûlées stockées avec la séance.
- Historique personnel des séances.
- Système de points : `points = duration_min`.
- **Un seul classement : global**, toutes activités et tous utilisateurs
  confondus — écran qui liste les utilisateurs par points décroissants,
  avec le rang de l'utilisateur connecté mis en avant.

### Répartition à deux (pensée pour tourner en parallèle dès le jour 1)

**Personne A — App côté utilisateur**
- Écrans inscription / connexion.
- Écran "Enregistrer une séance" (sport, durée, date) + appel à l'Edge
  Function de calcul de calories.
- Écran "Historique" (liste des séances passées).

**Personne B — Backend & classement**
- Schéma Supabase (migrations SQL : `profiles`, `sports` avec le seed fixe,
  `sessions`, policies Row Level Security).
- Edge Function `calculate-calories`.
- Écran "Classement global".

Le schéma de données (section 4) est le point de contact entre les deux :
une fois posé (même vide de données), chacun code son écran contre ce
schéma sans attendre l'autre.

## 4. Architecture technique

```
repo/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/              # thème, constantes, client Supabase
│   ├── models/            # User, Sport, Session
│   ├── data/               # repositories (appels supabase_flutter)
│   ├── providers/           # state management (Riverpod)
│   ├── screens/              # un dossier par écran
│   └── widgets/
├── test/
└── supabase/
    ├── migrations/         # schéma SQL (tables, policies, vue de classement)
    └── functions/
        └── calculate-calories/   # Edge Function (Deno/TS)
```

**Stack :**

- **Flutter** (Dart), state management **Riverpod**.
- **Supabase** (`supabase_flutter`) : auth + CRUD direct sur les tables via
  son query builder, filtré par Row Level Security.
- **Base de données :** Postgres géré par Supabase, schéma versionné dans
  `supabase/migrations/`.
- **Auth :** Supabase Auth (email + mot de passe).
- **Classement :** une vue SQL `rankings_global`
  (`SELECT user_id, SUM(points) ... GROUP BY user_id ORDER BY ... DESC`),
  exposée automatiquement en lecture par Supabase.
- **API externe :** Edge Function `calculate-calories` (quelques lignes de
  TypeScript/Deno) reçoit `{activity, weightKg, durationMin}`, appelle
  `api.api-ninjas.com/v1/caloriesburned` avec la clé stockée en secret
  Supabase (`CALORIES_API_KEY`, jamais dans le code Flutter), renvoie
  `caloriesBurned`. Seul bout de code qui n'est pas du Dart.

## 5. Modèle de données (V1)

```
profiles
  id            uuid (PK, = auth.users.id)
  name          text
  weight_kg     numeric        # requis pour le calcul de calories
  created_at    timestamptz

sports
  id                uuid (PK)
  name              text
  emoji             text
  points_per_unit   integer     # = 1 pour tous en V1 (points = durée)

sessions
  id                uuid (PK)
  user_id           uuid (FK profiles)
  sport_id          uuid (FK sports)
  date              date
  duration_min      integer
  points            integer
  calories_burned   numeric
  created_at        timestamptz
```

**Row Level Security :** chacun lit tout ce qui sert au classement
(`sessions`, `profiles`), mais ne peut insérer/modifier que ses propres
lignes (`user_id = auth.uid()`).

## 6. Definition of Done (V1)

- [ ] Un utilisateur peut créer un compte et se connecter.
- [ ] Un utilisateur peut enregistrer une séance (sport de la liste fixe,
      durée, date).
- [ ] La séance enregistrée affiche des calories brûlées réelles (issues
      de la Calories Burned API via l'Edge Function).
- [ ] Le classement global s'affiche et se met à jour après une séance.
- [ ] L'app respecte la charte XEFI (couleurs, police).
- [ ] `flutter analyze` et `flutter test` passent sans erreur.
- [ ] L'app tourne sur l'émulateur Android sans crash sur le parcours
      complet (inscription → séance → classement).

## 7. Backlog (hors V1 — à ne pas coder avant que tout ci-dessus fonctionne)

Ces idées restent bonnes, mais chacune dépasse à elle seule le temps
disponible pour ce projet. Ne pas commencer avant que la V1 soit
entièrement finie et fonctionnelle :

- **Suivi GPS** (course/vélo) avec carte en direct, distance, dénivelé —
  `geolocator` + `flutter_map`/OpenStreetMap. Un mini-projet à lui seul.
- **Catalogue de sports depuis wger.de** (https://wger.de/api/v2/, gratuite
  sans clé) plutôt qu'une liste fixe.
- **Contacts** (ajouter des collègues, classement filtré dessus).
- **Équipes** (rejoindre/créer, classement par équipe).
- **Classements par sport**, en plus du classement global.
- Badges, notifications, défis entre équipes.

## 8. Git & workflow (GitHub, duo)

- Branche protégée : `main`, toujours via Pull Request.
- Branches : `feature/<personne>-<description>`.
- Commits en **Conventional Commits** (`feat: ...`, `fix: ...`).
- Revue croisée avant merge, même rapide.
- Avant PR : `flutter analyze` + `flutter test` doivent passer.

## 9. Identité visuelle XEFI

Couleurs et typographies extraites du site officiel xefi.fr (inspection
CSS, pas une estimation) :

| Rôle              | Couleur    | Usage                              |
|-------------------|------------|-------------------------------------|
| Primaire (accent) | `#E10600`  | CTA, éléments actifs, rang de l'utilisateur |
| Noir              | `#000000`  | Header/AppBar, texte fort           |
| Blanc             | `#FFFFFF`  | Fond principal                      |
| Texte secondaire  | `#2B2D42`  | Corps de texte, sous-titres         |

Typographie : **Montserrat** (corps de texte et titres, en ExtraBold pour
les titres — le site utilise une police propriétaire "Nomixa" non
disponible publiquement). AppBar noire, accent rouge réservé aux actions et
au rang de l'utilisateur, fond blanc.

## 10. Conventions de code

- Code 100% en anglais (`sessionRepository`, `duration_min`,
  `session_repository.dart`...), seules les chaînes affichées à l'écran
  restent en français.
- Noms longs et explicites plutôt que courts et ambigus — un nom qui a
  besoin d'un commentaire pour être compris est un mauvais nom.
- Pas de commentaire qui répète ce que dit déjà le code.
- Flutter : `flutter_lints` actif, pas de `print()` en prod, logique
  métier dans les providers/repositories (pas dans les widgets), Riverpod
  partout, couleurs/polices dans `core/theme` uniquement.
- Supabase : Row Level Security activée dès la création de chaque table,
  aucune clé secrète tierce en dur dans le code Dart.

## 11. Sources

- https://www.xefi.fr/fr/decouvrir-xefi/a-propos-de-nous/qui-sommes-nous/
  (couleurs extraites du CSS calculé, police, logo)
- https://api-ninjas.com/api/caloriesburned (Calories Burned API — clé
  gratuite sans carte bancaire)
- https://supabase.com/docs (Auth, Postgres, Row Level Security, Edge
  Functions, package Flutter `supabase_flutter`)
- https://wger.de/api/v2/ et https://github.com/xefi/laravel-rest-api-flutter
  — pistes explorées pour le backlog (section 7) / le vrai stack XEFI, mais
  hors périmètre du V1 à 2 jours.
