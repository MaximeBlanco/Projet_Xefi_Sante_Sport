# XEFI Sport Constitution

## Core Principles

### I. L'app survit à la panne de ses dépendances externes

Le projet consomme trois API qu'il ne contrôle pas : la Calories Burned API
d'api-ninjas, Overpass pour les lieux, et les tuiles OpenStreetMap. Aucune
d'elles ne doit pouvoir empêcher d'enregistrer une séance.

Quand une API ne répond pas, l'app calcule ce qu'elle peut elle-même — les
calories tombent sur `MET × poids × durée` — et **marque la valeur dégradée**
plutôt que de la laisser passer pour une mesure : l'historique préfixe un `≈`,
et `calories_estimated` le dit en base. Une estimation locale présentée comme
une mesure est un mensonge, pas un repli.

Ce qui ne dépend pas d'une API externe — les points, le classement — ne doit
jamais être rendu indisponible par l'une d'elles.

### II. Une règle qui ne vit que dans le formulaire n'est pas une règle

PostgREST expose les tables directement : un client peut écrire sans jamais
ouvrir l'app. Toute contrainte métier est donc posée côté serveur et le
formulaire n'en est que la politesse.

Les points sont calculés par un trigger, pas envoyés par le client. La durée
est plafonnée en base. Une séance datée dans le futur est rejetée par la base.
Le row level security est activé sur chaque table, et la clé `service_role`,
qui le contourne, n'apparaît nulle part dans le dépôt.

### III. Une seule langue de design

L'interface appartient à celui qui l'a dessinée. Une fonctionnalité nouvelle se
**greffe dans** la mise en page existante, elle ne se pose pas **par-dessus** :
on réutilise ses composants — ses panneaux, ses cellules, ses séparateurs — pour
que deux écrans voisins ne donnent jamais l'impression de deux applications.

Un écran est pensé pour un téléphone ; en navigateur il est plafonné et centré,
pas étiré. Un plafond par écran dérive, un plafond partagé tient.

### IV. Le code dit quoi, le commit dit pourquoi

L'explication vit dans le nommage, le message de commit et la description de
merge request — jamais dans un fichier de prose à côté du code, qui dérive sans
que rien ne le compile ni ne le teste.

Le dépôt accepte un README, parce qu'installer et lancer le projet ne se lit pas
dans le code. Il n'accepte ni dossier `docs/`, ni journal des changements, ni
page de conventions. Un commentaire dit pourquoi une ligne existe, jamais ce
qu'elle fait.

### V. Un défaut se prouve avant d'être corrigé

Un bug qu'aucun test n'attrape reviendra. Le test qui échoue s'écrit d'abord, il
désigne le défaut, et c'est lui qui atteste la correction.

Cette règle a déjà payé : le filtre de période épinglait la date pour le calcul
mais laissait la fenêtre retomber sur l'horloge système — personne ne l'avait vu
à l'œil, c'est un test de provider qui l'a sorti.

`flutter analyze` sans avertissement et la suite verte sont la condition d'entrée
sur `main`, pas un objectif.

## Contraintes techniques

Flutter avec Riverpod pour l'état, Supabase pour la base, l'authentification et
l'Edge Function. La stack locale tourne en conteneurs Docker : elle est la
cible par défaut du code, de sorte qu'un clone neuf démarre sans fichier à
créer.

Le schéma vit dans `supabase/migrations/`. Chaque migration porte un numéro
**unique** : le tracker de Supabase indexe sur ce préfixe, donc deux fichiers qui
le partagent font disparaître l'un des deux en silence. Le jeu de démonstration
est rejoué par `supabase/seed_demo.sql`, à dates relatives pour qu'il ne
vieillisse pas.

Aucune clé d'API payante ou privée dans le code Dart : la clé api-ninjas vit en
secret Supabase, et seule l'Edge Function y accède.

## Workflow de développement

Une modification part d'une branche, jamais de `main` directement. Elle arrive
sur `main` par une merge request dont la description porte le raisonnement.

`main` est toujours démontrable : analyse propre, tests verts, et l'app se lance.
Un correctif qui casse un écran pour en réparer un autre n'est pas un correctif.

Une fonctionnalité qui traverse plusieurs écrans ou qui porte une vraie
ambiguïté passe par le cycle Spec Kit — spec, plan, tâches — avant d'être
écrite. Un correctif évident ne le mérite pas : le cycle coûte des relectures,
et les dépenser sur une coquille les rend moins crédibles là où elles comptent.

## Governance

Cette constitution prime sur les habitudes prises en cours de route. Quand une
pratique la contredit, c'est la pratique qui change, ou c'est la constitution
qui est amendée — explicitement, pas par usage.

Un amendement se fait par merge request, au même titre que du code : il dit quel
principe change, et pourquoi la règle précédente ne tenait plus. La version suit
le versionnage sémantique — MAJEURE pour un principe retiré ou redéfini de façon
incompatible, MINEURE pour un principe ajouté ou élargi, CORRECTIVE pour une
clarification.

Toute merge request se relit contre ces principes. Une complexité qui n'en
découle pas se justifie dans la description, ou se retire. Le `README.md` reste
la référence pour installer et lancer le projet.

**Version**: 1.0.0 | **Ratified**: 2026-09-10 | **Last Amended**: 2026-10-05
