---

description: "Task list for 001-contacts"
---

# Tasks: Contacts entre collègues

**Input**: Design documents from `/specs/001-contacts/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md)

**Tests**: Oui. Les critères SC-003, SC-004 et SC-005 les exigent, et le principe
V de la constitution les rend non négociables.

## Format: `[ID] [P?] [Story] Description`

- **[P]** : parallélisable — fichiers différents, aucune dépendance
- **[Story]** : le récit auquel la tâche appartient

---

## Phase 1 : Préparation

Le projet existe, il n'y a rien à initialiser.

- [ ] T001 Vérifier que la stack locale est à jour : `npx supabase@latest db reset`, 9 migrations appliquées, seed chargé

---

## Phase 2 : Fondations (bloquant)

**But** : poser le schéma et refermer les accès. Aucun récit ne peut commencer
avant.

**⚠️ T004 change le comportement existant** : des séances aujourd'hui lisibles par
tous cessent de l'être. Elle se livre avec T005, sans quoi le classement général
se vide.

- [ ] T002 Migration `supabase/migrations/20261005100000_profile_sharing_preferences.sql` : ajouter `shares_history boolean not null default true` et `shares_locations boolean not null default false` sur `profiles`
- [ ] T003 [P] Dans la même migration, contraindre `contacts` : `check (requester_id <> addressee_id)` et unicité de la paire quel que soit le sens — `unique (least(requester_id, addressee_id), greatest(requester_id, addressee_id))`
- [ ] T004 Migration `supabase/migrations/20261005110000_contact_access_rules.sql` : remplacer la politique `SELECT` de `sessions` (`using (true)`) par « ses propres séances, ou celles d'un contact accepté qui partage son historique »
- [ ] T005 Dans la même migration, passer `rankings_global` et `rankings_teams` en `security_invoker = false`, pour qu'un classement continue d'agréger toutes les séances sans en exposer une seule ligne
- [ ] T006 Dans la même migration, créer la vue `visible_sessions` qui annule `venue_name`, `venue_kind`, `venue_osm_id`, `route` et `elevation_gain_m` quand leur auteur n'a pas ouvert ses lieux
- [ ] T007 Dans la même migration, créer la vue `rankings_contacts`, construite comme `rankings_global` mais restreinte à `auth.uid()` et à ses contacts acceptés
- [ ] T008 [P] `lib/models/profile.dart` : ajouter `sharesHistory` et `sharesLocations`, lecture et écriture JSON
- [ ] T009 [P] `lib/models/contact.dart` : compléter avec l'identifiant de l'autre membre et un accesseur disant si le lien est en attente ou accepté
- [ ] T010 [P] `lib/models/member_summary.dart` : une ligne de résultat de recherche — identifiant, nom, avatar
- [ ] T011 `test/sql/contact_access_test.sql` : le script qui se fait passer pour chaque rôle et vérifie T004 et T006 — c'est lui qui atteste SC-003

**Checkpoint** : `flutter analyze` propre, 216 tests toujours verts, classement général inchangé dans l'app.

---

## Phase 3 : Récit 2 — Ajouter un collègue (P1) 🎯 MVP

**But** : pouvoir envoyer une demande, la voir, l'accepter.

**Pourquoi avant le récit 1** : sans lien accepté, un classement filtré est
toujours vide. Le récit 2 est la condition du récit 1, même si le 1 porte la
valeur.

**Test indépendant** : un compte envoie, l'autre accepte, le lien existe des deux côtés.

- [ ] T012 [US2] `lib/data/contact_repository.dart` : `sendRequest`, `acceptRequest`, `pendingReceived`, `acceptedContacts`, `searchMembers(nom)`
- [ ] T013 [US2] `lib/providers/contact_provider.dart` : providers des contacts acceptés et des demandes reçues
- [ ] T014 [US2] `lib/providers/contact_controller.dart` : les actions, sur le modèle de `delete_session_controller.dart`
- [ ] T015 [P] [US2] `test/data/contact_repository_test.dart` : demande à soi-même refusée, demande en double refusée, demande vers un contact existant refusée
- [ ] T016 [US2] `lib/screens/contacts/contacts_screen.dart` : contacts acceptés et demandes reçues, avec l'état vide qui dit comment le remplir (FR-019)
- [ ] T017 [US2] `lib/screens/contacts/member_search_screen.dart` : recherche par nom, envoi d'une demande, état « aucun résultat »
- [ ] T018 [US2] `lib/screens/rankings/global_ranking_screen.dart` : rendre une ligne de classement ouvrable sur la fiche d'un membre
- [ ] T019 [P] [US2] `test/screens/contacts/contacts_screen_test.dart` : liste, demandes, acceptation, état vide
- [ ] T020 [US2] Donner accès à l'écran contacts depuis le shell ou le profil — à trancher en implémentant, sans ajouter d'onglet au `BottomNavigationBar` qui en compte déjà quatre

**Checkpoint** : deux comptes peuvent se lier de bout en bout.

---

## Phase 4 : Récit 1 — Le classement entre contacts (P1) 🎯 MVP

**But** : la raison d'être de la fonctionnalité.

**Test indépendant** : avec deux comptes liés et des séances des deux côtés, la portée « Contacts » n'affiche qu'eux, dans le bon ordre.

- [ ] T021 [US1] `lib/data/ranking_repository.dart` : lire `rankings_contacts`
- [ ] T022 [US1] `lib/models/ranking_entry.dart` : réutiliser tel quel si la vue renvoie les mêmes colonnes — ne pas dupliquer le modèle
- [ ] T023 [US1] `lib/screens/rankings/global_ranking_screen.dart` : troisième portée dans le sélecteur existant, sans redessiner le podium
- [ ] T024 [P] [US1] `test/screens/rankings/contacts_ranking_test.dart` : seulement les contacts acceptés, ordre par points, demande en attente absente
- [ ] T025 [US1] État vide du classement contacts : inviter à ajouter quelqu'un (FR-019)

**Checkpoint** : MVP livrable. On peut ajouter un collègue et se mesurer à lui.

---

## Phase 5 : Récit 5 — Choisir ce qu'on laisse voir (P2)

**But** : les deux interrupteurs. Passe avant le récit 4, sinon la carte d'un contact est vide pour tout le monde sans moyen de l'ouvrir.

- [ ] T026 [US5] `lib/data/profile_repository.dart` : mettre à jour les deux préférences
- [ ] T027 [US5] `lib/providers/profile_editing_controller.dart` : les actions correspondantes
- [ ] T028 [US5] `lib/screens/profile/profile_screen.dart` : deux `_SettingRow` dans l'onglet Réglages, avec un texte qui dit ce que chacun expose
- [ ] T029 [P] [US5] `test/screens/profile/sharing_settings_test.dart` : les deux interrupteurs, leur valeur par défaut, et l'effet de les basculer
- [ ] T030 [P] [US5] Étendre `test/sql/contact_access_test.sql` : les quatre combinaisons des deux réglages (SC-005)

**Checkpoint** : un membre peut fermer ses lieux, et ça se vérifie depuis l'autre compte.

---

## Phase 6 : Récit 3 — Refuser et retirer (P2)

- [ ] T031 [US3] `lib/data/contact_repository.dart` : `refuseRequest` et `removeContact`
- [ ] T032 [US3] `lib/providers/contact_controller.dart` : les deux actions, avec confirmation avant le retrait — le dialogue dit ce qu'on perd, comme celui de la suppression de séance
- [ ] T033 [US3] `lib/screens/contacts/contacts_screen.dart` : refuser une demande, retirer un contact
- [ ] T034 [P] [US3] `test/providers/contact_controller_test.dart` : refus puis nouvelle demande recevable, retrait qui rompt le lien des deux côtés

**Checkpoint** : la liste de contacts ne peut plus que grossir.

---

## Phase 7 : Récit 4 — Regarder comment un contact s'entraîne (P3)

- [ ] T035 [US4] `lib/data/session_repository.dart` : lire `visible_sessions` pour les séances d'autrui, garder `sessions` pour les siennes
- [ ] T036 [US4] `lib/widgets/sharing_notice.dart` : le message « ce membre ne partage pas… », réutilisable pour l'historique et pour la carte
- [ ] T037 [US4] `lib/screens/contacts/member_detail_screen.dart` : fiche d'un membre réutilisant `MemberCard` et les panneaux du profil ; non-contact → nom, points, rang et bouton d'ajout seulement
- [ ] T038 [US4] Historique d'un contact, et `lib/screens/sessions/session_detail_screen.dart` qui affiche le message quand lieu et parcours sont nuls plutôt qu'une carte vide (FR-016)
- [ ] T039 [P] [US4] `test/screens/contacts/member_detail_test.dart` : contact partageant tout, contact masquant ses lieux, contact masquant son historique, non-contact

**Checkpoint** : tous les récits sont livrés.

---

## Phase 8 : Finitions

- [ ] T040 `README.md` : la section confidentialité — ce qu'un contact voit, et les valeurs par défaut
- [ ] T041 `supabase/seed_demo.sql` : des contacts et des demandes entre les membres de démo, et au moins un membre aux lieux fermés pour que le cas se voie
- [ ] T042 `flutter analyze` propre et suite verte, puis vérification à la main sur le web et sur l'émulateur

---

## Dépendances

```
Phase 2 (fondations)  ──bloque──>  toutes les autres
Phase 3 (US2 ajouter) ──precede──>  Phase 4 (US1 classement)
Phase 5 (US5 reglages)──precede──>  Phase 7 (US4 consulter)
Phase 6 (US3)  independante une fois la phase 3 faite
```

T004, T005, T006 et T007 vivent dans la même migration et se livrent ensemble :
refermer les séances sans basculer les vues de classement casse l'app.

### Parallélisable

- T002 et T003 : même migration, écrites ensemble
- T008, T009, T010 : trois modèles, trois fichiers
- Les tâches marquées [P] d'un même récit
- Une fois la phase 4 terminée, les phases 5 et 6 peuvent avancer de front

---

## Stratégie de livraison

**MVP** : phases 1 à 4. On peut ajouter un collègue et se mesurer à lui — c'est
la valeur entière de la fonctionnalité. Les phases 5 à 7 ajoutent le contrôle et
le détail.

**Attention à ne pas livrer la phase 7 sans la phase 5** : les lieux sont fermés
par défaut, donc la carte d'un contact serait vide pour tout le monde et
passerait pour un défaut.
