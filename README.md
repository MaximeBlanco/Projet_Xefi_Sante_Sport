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
marche quand même : l'app bascule sur la formule MET (voir ci-dessous) et
l'historique préfixe la valeur d'un `≈`. Les points (= durée en minutes) et le
classement ne dépendent pas de l'API. Le poids saisi à l'inscription sert au
calcul : un profil sans poids ne déclenche ni l'appel ni l'estimation, et la
séance est alors stockée sans calories (l'historique affiche un tiret).

### Repli local quand l'API ne répond pas

Chaque sport porte son MET (`sports.met`, valeurs du Compendium of Physical
Activities). Dès que l'Edge Function échoue — API en panne, quota épuisé, ou
tout simplement aucune clé configurée — l'app calcule elle-même :

```
kcal = MET x poids_kg x durée_heures
```

La séance stocke alors `calories_estimated = true`, et l'historique affiche
`≈ 368 kcal` au lieu de `368 kcal` : une estimation locale ne doit jamais
passer pour une valeur mesurée. C'est ce qui permet de faire une démo complète
sans clé api-ninjas et sans réseau.

## Développement 100 % local (sans compte Supabase)

Alternative au projet cloud : la CLI Supabase monte toute la stack en
conteneurs Docker sur ta machine. Même schéma, mêmes migrations, aucun compte
à créer. Il faut Docker Desktop démarré.

```
npx supabase@latest start
```

Les migrations de `supabase/migrations/` s'appliquent automatiquement, donc les
10 sports sont là dès le premier démarrage. La commande affiche à la fin
`API_URL` et `PUBLISHABLE_KEY` : reporte-les dans `dart_define.json`, mais
**avec l'hôte `10.0.2.2` au lieu de `127.0.0.1`** — c'est l'alias par lequel
l'émulateur Android joint la machine hôte :

```json
{
  "SUPABASE_URL": "http://10.0.2.2:54321",
  "SUPABASE_ANON_KEY": "<PUBLISHABLE_KEY affichee par supabase start>"
}
```

La stack locale sert aussi l'Edge Function. Pour avoir de vraies calories,
copie `supabase/functions/.env.example` en `supabase/functions/.env` (ignoré
par git), colle ta clé api-ninjas dedans, puis redémarre la stack :

```
CALORIES_API_KEY=<ta-cle>
```

```
npx supabase stop && npx supabase start
```

Pour vérifier que l'appel externe aboutit vraiment, sans passer par l'app —
c'est la commande à avoir sous la main en soutenance :

```bash
ANON=$(npx supabase status -o json | grep -o '"ANON_KEY": *"[^"]*"' | cut -d'"' -f4)
curl -s -X POST http://127.0.0.1:54321/functions/v1/calculate-calories \
  -H "Authorization: Bearer $ANON" -H "Content-Type: application/json" \
  -d '{"activity":"cycling","weightKg":75,"durationMin":60}'
```

Une réponse `{"caloriesBurned":...}` prouve que la chaîne complète fonctionne :
app → Edge Function → API externe. Un `{"error":"The calories provider is not
configured."}` signifie que la clé n'est pas lue.

Sans cette clé la fonction répond « not configured », et l'app retombe sur la
formule MET : les séances gardent des calories, simplement préfixées d'un `≈`.
Rien n'est bloqué.

Commandes utiles : `npx supabase status` (URL et clés), `npx supabase stop`
(arrêt, les données sont conservées), `npx supabase db reset` (rejoue les
migrations sur une base vide). Le Studio est sur http://127.0.0.1:54323.

À savoir : la stack locale parle en HTTP simple, qu'Android bloque depuis
l'API 28. `android/app/src/debug/res/xml/network_security_config.xml` lève
l'interdiction pour les seuls hôtes de loopback, et uniquement en build debug —
la release reste sans cleartext.

## Suivi GPS du parcours

Sur un sport marqué `is_gps_trackable`, le formulaire propose « Suivre le
parcours en direct » : l'app enregistre les positions, trace le parcours sur la
carte, et à l'arrêt renvoie la durée, la distance et le dénivelé au formulaire.
Les points bruts sont stockés dans `sessions.route` (jsonb), et l'historique
affiche la carte au détail d'une séance.

Les fonds de carte viennent d'**OpenStreetMap** via `flutter_map` : aucune clé,
aucun compte de facturation, contrairement à Google Maps.

Deux choix qui méritent une explication :

- **Distance et dénivelé sont recalculés depuis les points**, jamais lus depuis
  la vitesse ou l'odomètre du téléphone, qui dérivent. Un seuil ignore le bruit
  GPS (5 m à l'horizontale, 3 m à la verticale) : sans lui, un téléphone posé
  sur une table invente des centaines de mètres.
- **Android lit le GPS via `LocationManager`**, pas via le fused provider de
  Play Services (`forceLocationManager: true`). Fused est meilleur en intérieur,
  mais cette fonctionnalité ne sert qu'en extérieur, où fused retombe de toute
  façon sur le GPS brut — et surtout, le fused provider de l'émulateur ignore
  `adb emu geo fix`, ce qui rendrait toute démo impossible.

### Simuler un parcours dans l'émulateur

L'émulateur ne bouge pas, mais on peut lui envoyer des positions. Démarre le
suivi dans l'app, puis envoie une suite de points espacés de plus de 5 m :

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$lat = 45.7500; $lng = 4.8500
for ($i = 0; $i -lt 20; $i++) {
  $lat += 0.00025; $lng += 0.00008
  & $adb emu geo fix $lng.ToString("F6") $lat.ToString("F6") 170
  Start-Sleep -Milliseconds 700
}
```

À savoir : l'émulateur impose sa propre altitude et ignore celle passée à
`geo fix`, donc le dénivelé reste à 0 en simulation. Le calcul lui-même est
couvert par `test/core/route_metrics_test.dart`.

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
- Enregistrer une séance : sport de la liste fixe, durée réglée sur deux
  molettes heures/minutes (la base ne stocke que des minutes), date
  (les dates futures sont refusées).
- Calories réelles issues de la Calories Burned API via l'Edge Function,
  stockées avec la séance, avec repli sur la formule MET (préfixe `≈`) quand
  l'API ne répond pas.
- Suivi GPS du parcours pour les sports marqués `is_gps_trackable` (course,
  vélo, marche) : tracé en direct sur une carte, distance et dénivelé calculés,
  durée pré-remplie à l'arrêt. Voir ci-dessous.
- Historique personnel des séances, de la plus récente à la plus ancienne, avec
  la carte du parcours au détail d'une séance qui en a un.
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
