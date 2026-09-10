# XEFI Sport

App Flutter de suivi sportif compétitif pour les collaborateurs XEFI. Voir
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour la vision, l'architecture
et les conventions du projet.

## Prérequis

- Flutter (SDK `^3.13.3`, voir `pubspec.yaml`)
- Un projet [Supabase](https://supabase.com) (gratuit) et sa CLI si tu veux
  appliquer les migrations en local

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

## Base de données

Le schéma partagé vit dans `supabase/migrations/`. Pour l'appliquer sur ton
projet Supabase :

```
supabase link --project-ref <ton-project-ref>
supabase db push
```

Puis exécute `supabase/seed/sports_from_wger.sql` (SQL editor du dashboard
Supabase, ou `supabase db execute`) pour avoir des sports à sélectionner.

## Qualité

Avant toute PR :

```
flutter analyze
flutter test
```
