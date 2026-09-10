# XEFI Sport

App Flutter de suivi sportif compétitif pour les collaborateurs XEFI. Voir
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour la vision, l'architecture
et les conventions du projet.

## Prérequis

- Flutter (SDK `^3.13.3`, voir `pubspec.yaml`)
- Un projet [Supabase](https://supabase.com) (gratuit) et sa CLI si tu veux
  appliquer les migrations en local

## Configuration

Pour le développement local avec `supabase start` (Docker), `flutter run`
fonctionne **sans rien configurer** : l'app pointe par défaut sur le
Supabase local (`http://10.0.2.2:54321` depuis l'émulateur Android) avec sa
clé anon locale.

```
flutter pub get
flutter run
```

Pour cibler un vrai projet Supabase (staging/prod) à la place, passe tes
propres identifiants sans les committer :

1. Copie `dart_define.example.json` en `dart_define.json` (déjà ignoré par
   git).
2. Remplis `SUPABASE_URL` et `SUPABASE_ANON_KEY` avec les valeurs de ton
   projet Supabase (Project Settings → API).
3. `flutter run --dart-define-from-file=dart_define.json`

## Base de données

Le schéma partagé vit dans `supabase/migrations/`. Pour l'appliquer sur ton
projet Supabase :

```
supabase link --project-ref <ton-project-ref>
supabase db push
```

Puis exécute `supabase/seed.sql` (SQL editor du dashboard Supabase, ou
`supabase db execute -f supabase/seed.sql`) pour avoir la liste de sports
fixe du V1 à sélectionner.

## Qualité

Avant toute PR :

```
flutter analyze
flutter test
```
