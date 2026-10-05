# Implementation Plan: Contacts entre collègues

**Branch**: `001-contacts` | **Date**: 2026-10-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-contacts/spec.md`

## Summary

La fonctionnalité active une table `contacts` posée en V1 et laissée inutilisée,
y ajoute deux préférences de partage sur le profil, et ouvre une troisième
portée au classement.

L'essentiel du travail n'est pas l'interface : c'est que **les séances sont
aujourd'hui lisibles par n'importe quel compte authentifié**. La politique
`SELECT` sur `sessions` est `USING (true)`, donc une requête directe à l'API
renvoie déjà les lieux et les trajets de tout le monde. Ajouter des interrupteurs
dans l'écran compte sans refermer cette politique donnerait une confidentialité
de façade. Le plan la referme, et traite la conséquence : le classement général
agrège `sessions` et ne doit pas s'effondrer en même temps.

## Technical Context

**Language/Version**: Dart 3.13.3, Flutter 3.47.3

**Primary Dependencies**: `flutter_riverpod` (état), `supabase_flutter` (base,
auth, PostgREST), `flutter_map` (parcours). Aucune dépendance nouvelle.

**Storage**: PostgreSQL via Supabase. Migrations versionnées dans
`supabase/migrations/`, numéro unique obligatoire.

**Testing**: `flutter_test`, suite actuelle à 216 tests. Tests de modèle, de
provider et d'écran ; les règles d'accès se vérifient en SQL contre la stack
locale.

**Target Platform**: Android et web, même code.

**Project Type**: Application mobile à backend géré (Supabase), dépôt unique.

**Performance Goals**: Le classement contacts se charge comme les deux autres,
sans écran d'attente perceptible sur la dizaine de membres visée.

**Constraints**: Les règles d'accès vivent en base, pas dans l'app — PostgREST
expose les tables directement. Aucune donnée de lieu ne doit sortir de l'API pour
un membre qui ne la partage pas, y compris si le client la demande explicitement.

**Scale/Scope**: Une dizaine de membres, quelques centaines de séances. Deux
migrations, un dépôt, environ six écrans ou fragments d'écran touchés.

## Constitution Check

| Principe | Comment ce plan s'y tient |
|---|---|
| I. Survivre à la panne des dépendances | Aucune API externe en jeu. La fonctionnalité n'ajoute aucun point de panne. |
| II. Une règle qui ne vit que dans le formulaire n'est pas une règle | **C'est le cœur du plan.** Les deux préférences et le lien de contact sont appliqués par des politiques RLS et des vues, pas par ce que l'écran choisit d'afficher. Le critère SC-003 se vérifie avec `curl`, en dehors de l'app. |
| III. Une seule langue de design | La portée « Contacts » rejoint le sélecteur existant du classement. La fiche d'un membre réutilise `MemberCard`, les panneaux et les cellules du profil. Les réglages rejoignent l'onglet Réglages existant, en `_SettingRow`. |
| IV. Le code dit quoi, le commit dit pourquoi | Pas de document ajouté hors `specs/`. Le raisonnement va dans les messages de commit. |
| V. Un défaut se prouve avant d'être corrigé | Chaque règle d'accès a son test. Les quatre combinaisons des deux réglages sont couvertes, ainsi que les quatre états d'un lien. |

**Point de vigilance** : refermer `sessions` est un changement de comportement
qui touche du code existant. Il doit être livré avec ses tests, et le classement
général vérifié après, sous peine d'enfreindre « `main` est toujours
démontrable ».

## Project Structure

### Documentation (this feature)

```
specs/001-contacts/
├── spec.md
├── plan.md
└── tasks.md
```

### Source Code (repository root)

```
supabase/migrations/
├── 20261005100000_profile_sharing_preferences.sql   # 2 colonnes + defauts
└── 20261005110000_contact_access_rules.sql          # RLS + vues

lib/
├── models/
│   ├── contact.dart                 # existe, a completer (lien resolu, pair)
│   ├── profile.dart                 # + sharesHistory, sharesLocations
│   └── member_summary.dart          # nouveau : une ligne de recherche
├── data/
│   ├── contact_repository.dart      # nouveau
│   ├── profile_repository.dart      # + mise a jour des preferences
│   └── ranking_repository.dart      # + portee contacts
├── providers/
│   ├── contact_provider.dart        # nouveau
│   └── contact_controller.dart      # nouveau : envoyer, accepter, refuser, retirer
├── screens/
│   ├── contacts/
│   │   ├── contacts_screen.dart     # nouveau : contacts + demandes recues
│   │   ├── member_search_screen.dart# nouveau
│   │   └── member_detail_screen.dart# nouveau : fiche + historique d'un contact
│   ├── rankings/global_ranking_screen.dart  # + troisieme portee
│   └── profile/profile_screen.dart  # + deux reglages dans l'onglet Reglages
└── widgets/
    └── sharing_notice.dart          # nouveau : « ce membre ne partage pas »

test/
├── data/contact_repository_test.dart
├── providers/contact_controller_test.dart
├── screens/contacts/…
└── sql/contact_access_test.sql      # les regles d'acces, verifiees en SQL
```

**Structure Decision**: Dépôt unique, arborescence existante. Les contacts
prennent un dossier d'écrans à eux parce qu'ils en apportent trois ; tout le
reste se greffe dans les fichiers qui existent.

## Approche technique

### 1. Les préférences de partage

Deux colonnes sur `profiles` :

```sql
shares_history   boolean not null default true
shares_locations boolean not null default false
```

Le défaut est porté par la colonne, pas par le code client : un compte créé par
n'importe quel chemin — l'app, un script, Studio — ne diffuse aucun lieu.

### 2. Refermer les séances

La politique actuelle devient :

```sql
using (
  user_id = auth.uid()
  or exists (
    select 1 from contacts c join profiles p on p.id = sessions.user_id
    where c.status = 'accepted'
      and p.shares_history
      and ((c.requester_id = auth.uid() and c.addressee_id = sessions.user_id)
        or (c.addressee_id = auth.uid() and c.requester_id = sessions.user_id))
  )
)
```

### 3. Masquer les lieux sans masquer la séance

RLS filtre des lignes, pas des colonnes, et une préférence ne peut pas se poser
en `GRANT`. Le lieu et le parcours passent donc par une vue qui les annule quand
leur auteur ne les partage pas :

```sql
create view visible_sessions with (security_invoker = true) as
select s.id, s.user_id, s.sport_id, s.date, s.duration_min, s.points,
       s.calories_burned, s.calories_estimated, s.distance_km,
       case when owner.shares_locations or s.user_id = auth.uid()
            then s.venue_name end as venue_name,
       -- idem venue_kind, venue_osm_id, route, elevation_gain_m
from sessions s join profiles owner on owner.id = s.user_id;
```

L'app lit `visible_sessions` dès qu'elle affiche les séances de quelqu'un
d'autre, et continue de lire `sessions` pour les siennes. Un champ nul veut dire
« non partagé » : l'écran l'interprète, il ne le devine pas.

### 4. Le classement ne doit pas s'effondrer

`rankings_global` et `rankings_teams` sont en `security_invoker = true` : elles
agrègent `sessions` **avec les droits de l'appelant**. Refermer `sessions` les
viderait — chacun ne verrait plus que ses propres points.

Elles passent en `security_invoker = false`, c'est-à-dire exécutées avec les
droits de leur propriétaire. C'est correct et volontaire : **une vue de
classement n'expose que des totaux**, jamais une ligne de séance, et ces totaux
sont publics dans l'app depuis la V1 — c'est tout l'objet d'un classement.

`rankings_contacts` est une troisième vue, construite comme la globale mais
restreinte à `auth.uid()` et à ses contacts acceptés. Elle est en
`security_invoker = false` pour la même raison, et se filtre elle-même sur
l'appelant : elle n'a pas besoin de paramètre.

### 5. Côté application

`ContactRepository` porte les quatre opérations — envoyer, accepter, refuser,
retirer — et la recherche de membres. Un `contactsProvider` expose les contacts
acceptés et les demandes reçues ; un contrôleur porte les actions, sur le modèle
de `delete_session_controller.dart` qui existe déjà.

La portée du classement passe de deux à trois valeurs. L'écran d'un membre
réutilise `MemberCard` et les panneaux du profil plutôt que d'en redessiner.

### 6. Vérifier les règles là où elles vivent

Les tests Flutter couvrent les modèles, les contrôleurs et les écrans. Ils ne
prouvent rien sur les règles d'accès, qui sont en base. Un script SQL joué contre
la stack locale se fait passer pour chaque rôle et vérifie qu'une requête directe
ne renvoie ni ce qu'elle ne doit pas voir, ni un lieu que son auteur a fermé.
C'est ce script qui atteste SC-003, pas un test de widget.

## Complexity Tracking

| Écart | Pourquoi c'est nécessaire | L'alternative écartée |
|---|---|---|
| Une vue `visible_sessions` en plus de la table | RLS ne filtre pas les colonnes, et une préférence par membre ne peut pas se poser en `GRANT` | Masquer dans l'app : la donnée sortirait quand même de l'API, et le principe II tombe |
| Deux vues de classement passent en `security_invoker = false` | Sinon refermer `sessions` vide le classement général pour tout le monde | Garder `sessions` ouvert : la fonctionnalité n'aurait aucun effet réel |
| Un test en SQL à côté des tests Flutter | Les règles vivent en base ; un test de widget ne peut pas les atteindre | Se fier à l'interface : c'est exactement ce que la constitution interdit |

## Affected Repos

`monapp` — dépôt unique. Aucune coordination inter-dépôts.
