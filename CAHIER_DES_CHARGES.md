# Cahier des charges — App de suivi sportif personnel (XEFI)

## 1. Vision

Application mobile Flutter de suivi sportif **personnel** : un seul
utilisateur, toutes ses données sur son téléphone, aucun serveur. On
enregistre une séance de sport, on suit son trajet en direct (GPS) pour la
course/vélo/marche, et l'app calcule les calories brûlées via une API
externe.

Nom de travail : **XEFI Sport** (à confirmer/changer librement).

**Pas de compte, pas de connexion, pas de comparaison entre utilisateurs,
pas de backend.** Ce périmètre a changé plusieurs fois avant d'arriver ici —
si une idée plus ambitieuse (classement, comptes, équipes) revient un jour,
elle repart d'une nouvelle réflexion, pas d'un ajout sur cette base.

## 2. Contraintes obligatoires

- **Contrainte imposée : intégrer une API externe tierce**, sur le principe
  d'une app de stats League of Legends qui consomme l'API Riot Games.
  Retenue : **Calories Burned API (api-ninjas.com)** — calcule les calories
  brûlées à partir du sport pratiqué, du poids, et de la durée.
- **Aucun backend, aucun compte.** Toutes les données (séances, poids)
  restent stockées localement sur le téléphone (Hive). Pas de Supabase, pas
  de serveur perso, pas d'auth.
- Cible : **Android** (testé sur émulateur ou téléphone).
- Respect de l'identité visuelle XEFI (section 6).
- **Tout le code est en anglais** (fichiers, classes, variables, commits).
  Seul le texte affiché à l'écran reste en français. Nommage explicite, pas
  de commentaire qui décrit un "quoi" que le nom aurait pu porter.

## 3. Fonctionnalités

- Enregistrer une séance : choisir un sport dans une liste fixe, durée en
  minutes (sports non-outdoor : natation, foot, yoga, muscu...).
- **Suivi GPS en direct** pour les sports outdoor (course à pied, vélo,
  marche) : carte qui trace le parcours pendant la séance, distance
  calculée en direct (formule de Haversine), durée mesurée automatiquement.
- À l'enregistrement (manuel ou GPS), appel à la Calories Burned API
  (sport + poids + durée) → calories stockées avec la séance. Si aucune clé
  API n'est configurée, la séance s'enregistre quand même, juste sans
  calories (l'app ne doit jamais bloquer sur l'API externe).
- Poids demandé une seule fois (au premier enregistrement), modifiable.
- Historique des séances (liste, plus récentes en premier).

### Backlog (hors V1)

- Statistiques/graphiques sur la durée.
- Édition/suppression d'une séance depuis l'historique.
- Choix d'unité (kg/lb, km/mi).
- Tout ce qui a été exploré puis abandonné (comptes, classements, équipes,
  contacts, backend Supabase/Laravel, sync wger.de) reste dans
  [CAHIER_DES_CHARGES_COMPLET.md](CAHIER_DES_CHARGES_COMPLET.md) — à ne
  reprendre que si le projet évolue vers du multi-utilisateur.

## 4. Architecture technique

```
lib/
├── main.dart
├── app.dart
├── theme/app_theme.dart        # couleurs/police XEFI
├── constants/sports.dart       # liste fixe de sports
├── models/
│   ├── sport_session.dart
│   └── route_point.dart
├── data/
│   ├── session_repository.dart # stockage local (Hive)
│   └── calories_api.dart       # appel à la Calories Burned API
├── screens/
│   ├── home_screen.dart
│   ├── add_session_screen.dart
│   ├── gps_tracking_screen.dart
│   └── weight_prompt_dialog.dart
└── widgets/session_card.dart
```

**Stack :**

- **Flutter** (Dart), pas de state management externe — `StatefulWidget`
  classique, l'app est assez petite pour ne pas en avoir besoin.
- **Stockage local : Hive** (`hive` + `hive_flutter`) — un fichier sur le
  téléphone, pas de serveur.
- **GPS et carte :** `geolocator` (position) + `flutter_map` + `latlong2`
  (carte), tuiles **OpenStreetMap** — gratuites, sans clé API (contrairement
  à Google Maps qui demande une facturation activée).
- **API externe :** appel direct depuis Flutter à
  `api.api-ninjas.com/v1/caloriesburned` avec une clé gratuite (voir
  `lib/data/calories_api.dart` — la clé se passe via
  `--dart-define=CALORIES_API_KEY=...`, jamais commitée en dur). Sans clé
  configurée, le calcul est simplement ignoré.

## 5. Definition of Done (V1)

- [ ] On peut enregistrer une séance manuelle (sport + durée).
- [ ] On peut démarrer un suivi GPS pour un sport outdoor, voir le tracé se
      dessiner sur la carte en direct, puis l'arrêter et l'enregistrer.
- [ ] La séance enregistrée affiche des calories brûlées (si une clé API
      est configurée) sans jamais bloquer l'enregistrement si l'API échoue.
- [ ] L'historique liste les séances passées.
- [ ] L'app respecte la charte XEFI (couleurs, police).
- [ ] `flutter analyze` et `flutter test` passent sans erreur.
- [ ] L'app tourne sur l'émulateur/téléphone Android sans crash sur le
      parcours complet (ajout séance → historique).

## 6. Identité visuelle XEFI

Couleurs extraites du site officiel xefi.fr (inspection CSS, pas une
estimation) :

| Rôle              | Couleur    | Usage                              |
|-------------------|------------|-------------------------------------|
| Primaire (accent) | `#E10600`  | CTA, accents                        |
| Noir              | `#000000`  | AppBar                              |
| Blanc             | `#FFFFFF`  | Fond principal                      |
| Texte secondaire  | `#2B2D42`  | Corps de texte                      |

AppBar noire, accent rouge réservé aux actions, fond blanc, cartes avec
ombre légère.

## 7. Conventions de code

- Code 100% en anglais (`sessionRepository`, `duration_min` →
  `durationMin` côté Dart, `session_repository.dart`...), seules les
  chaînes affichées à l'écran restent en français.
- Noms longs et explicites plutôt que courts et ambigus.
- Pas de commentaire qui répète ce que dit déjà le code.
- `flutter_lints` actif, pas de `print()` en prod.
- Aucune clé API en dur dans le code — toujours via `--dart-define`.

## 8. Sources

- https://www.xefi.fr/fr/decouvrir-xefi/a-propos-de-nous/qui-sommes-nous/
  (couleurs extraites du CSS calculé, police, logo)
- https://api-ninjas.com/api/caloriesburned (Calories Burned API — clé
  gratuite sans carte bancaire)
- https://openstreetmap.org (tuiles de carte, gratuites, sans clé)
