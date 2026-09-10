# XEFI Sport

App Flutter de suivi sportif compétitif pour les collaborateurs XEFI. Voir
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour la vision, l'architecture
et les conventions du projet.

## Prérequis

- Flutter (SDK `^3.13.3`, voir `pubspec.yaml`)
- Un projet [Supabase](https://supabase.com) (gratuit)
- La [CLI Supabase](https://supabase.com/docs/guides/cli), connectée à ton
  compte : elle applique les migrations **et** déploie l'Edge Function, les
  deux sont nécessaires pour que l'app tourne de bout en bout
- Une clé gratuite [api-ninjas.com](https://api-ninjas.com/api/caloriesburned)
  (compte gratuit, sans carte bancaire) pour le calcul des calories

## Configuration

L'app ne démarre pas sans les identifiants Supabase, passés via
`--dart-define-from-file` pour ne jamais les committer.

1. Copie `dart_define.example.json` en `dart_define.json` (déjà ignoré par
   git).
2. Remplis `SUPABASE_URL` et `SUPABASE_ANON_KEY` avec les valeurs de ton
   projet Supabase (Project Settings → API).
3. Lance l'app :

   ```
   flutter pub get
   flutter run --dart-define-from-file=dart_define.json
   ```

Sur un projet Supabase neuf, fais d'abord une fois les trois sections
ci-dessous (base de données, Edge Function, confirmation d'email) : sans
elles il n'y a ni sports à sélectionner, ni calories, ni connexion possible
juste après une inscription.

## Base de données

Le schéma partagé vit dans `supabase/migrations/`. Pour l'appliquer sur ton
projet Supabase :

```
supabase link --project-ref <ton-project-ref>
supabase db push
```

C'est suffisant : la liste fixe des 10 sports (cahier des charges section 3)
est insérée par la migration `20260910120000_v1_rankings_and_calories.sql`
elle-même, avec le nom d'activité anglais (`external_activity_name`) attendu
par l'API de calories. Rien à exécuter à la main après le `db push`.

La migration pose aussi les garde-fous côté serveur, parce que PostgREST
expose les tables directement et qu'une règle qui ne vit que dans le
formulaire Flutter n'en est pas une : `points` est calculé par un trigger (un
client ne peut pas l'envoyer), `duration_min` est plafonné à 1440 minutes et
une séance datée dans le futur est rejetée.

## Edge Function `calculate-calories`

Seul bout de code non-Dart du projet (Deno/TypeScript, dans
`supabase/functions/calculate-calories/`). Elle appelle la Calories Burned
API d'api-ninjas avec une clé stockée en secret Supabase : **la clé ne doit
jamais apparaître dans le code Dart ni dans `dart_define.json`**, seule la
fonction y a accès.

1. Crée un compte gratuit sur [api-ninjas.com](https://api-ninjas.com/api/caloriesburned)
   et récupère ta clé API dans ton profil.
2. Déploie la fonction :

   ```
   supabase functions deploy calculate-calories
   ```

3. Donne-lui la clé (à refaire seulement si la clé change, pas à chaque
   déploiement) :

   ```
   supabase secrets set CALORIES_API_KEY=<ta-cle-api-ninjas>
   ```

Si la fonction n'est pas déployée ou si l'API tombe, enregistrer une séance
marche quand même : la séance est stockée sans calories et l'historique
affiche un tiret plutôt qu'un faux `0`. Les points (= durée en minutes) et le
classement ne dépendent pas de l'API. Le poids saisi à l'inscription sert au
calcul : un profil sans poids ne déclenche pas l'appel.

## Auth en développement

Supabase demande une confirmation d'email par défaut : juste après une
inscription, la connexion échoue avec `Email not confirmed` tant que le lien
reçu par mail n'a pas été cliqué. Pour développer sans friction, désactive
**Confirm email** dans le dashboard Supabase :
Authentication → Sign In / Providers → Email. À réactiver avant toute mise en
production.

## Ce qui marche en V1

Miroir de la definition of done (cahier des charges, section 6) :

- Créer un compte (email, mot de passe, nom, poids) et se connecter.
- Enregistrer une séance : sport de la liste fixe, durée en minutes, date
  (les dates futures sont refusées).
- Calories réelles issues de la Calories Burned API via l'Edge Function,
  stockées avec la séance.
- Historique personnel des séances, de la plus récente à la plus ancienne.
- Classement global par points décroissants (`points = duration_min`, calculé
  côté base), avec le rang de l'utilisateur connecté mis en avant.
- Charte XEFI respectée : couleurs et Montserrat centralisés dans
  `lib/core/theme`.
- `flutter analyze` et `flutter test` passent sans erreur.

Hors périmètre V1 (section 7) : suivi GPS, catalogue de sports wger, contacts,
équipes, classements par sport, badges.

## Qualité

Avant toute PR :

```
flutter analyze
flutter test
```
