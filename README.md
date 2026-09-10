# XEFI Sport

App Flutter de suivi sportif **personnel** — un seul utilisateur, toutes
les données sur le téléphone, aucun serveur. Voir
[CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md) pour la vision, l'architecture
et les conventions du projet.

## Lancer le projet

```
flutter pub get
flutter run
```

Fonctionne sans rien configurer. Les calories brûlées ne s'affichent pas
tant qu'aucune clé Calories Burned API n'est fournie (voir ci-dessous) —
tout le reste marche déjà.

## Calories brûlées (optionnel)

1. Crée une clé gratuite sur https://api-ninjas.com (pas de carte requise).
2. Lance l'app avec :

   ```
   flutter run --dart-define=CALORIES_API_KEY=ta_clé
   ```

## Qualité

Avant toute PR :

```
flutter analyze
flutter test
```
