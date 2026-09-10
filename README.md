# XEFI Sport

App Flutter de suivi sportif compétitif pour les collaborateurs XEFI. Voir
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour la vision, l'architecture
et les conventions du projet.

## Lancer le projet

Aucune installation ni compte à créer : l'app pointe par défaut sur le
projet Supabase partagé de l'équipe (cloud, pas de Docker).

```
flutter pub get
flutter run
```

## Base de données

Le schéma partagé est déjà appliqué sur le projet Supabase de l'équipe. Le
SQL qui fait foi vit dans `supabase/migrations/` + `supabase/seed.sql` — si
tu dois le réappliquer (nouveau projet Supabase, reset), colle le contenu
de ces fichiers dans le **SQL Editor** du dashboard Supabase et exécute.

## Développer hors-ligne (optionnel)

Si tu veux tester des migrations sans toucher au projet partagé, tu peux
faire tourner un Supabase local avec sa CLI (nécessite Docker) :

```
supabase start
flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321 --dart-define=SUPABASE_ANON_KEY=<clé affichée par "supabase start">
```

Ou copie `dart_define.example.json` en `dart_define.json` (ignoré par git)
pour éviter de retaper les identifiants à chaque lancement.

## Qualité

Avant toute PR :

```
flutter analyze
flutter test
```
