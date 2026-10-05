# Feature Specification: Contacts entre collègues

**Feature Branch**: `001-contacts`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Ajouter des collègues en contact et comparer sa progression avec eux"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Se mesurer à ses collègues plutôt qu'à toute la société (Priority: P1)

Camille est 9e sur 10 au classement général et n'y trouve aucune motivation : les
premiers s'entraînent bien plus qu'elle. Elle ajoute en contact les trois
collègues de son étage, qui courent à peu près autant, et bascule le classement
sur « Contacts ». Elle y est 2e sur 4, à 40 points de la première. La semaine
suivante, elle regarde si elle est passée devant.

**Why this priority**: C'est la raison d'être de la fonctionnalité, et la seule
qui change quelque chose au produit. Un classement de dix inconnus ne motive
personne ; un classement de quatre collègues qu'on croise tous les jours, si.
Les autres récits sont du confort autour de celui-ci.

**Independent Test**: Avec deux comptes liés et des séances des deux côtés, le
classement « Contacts » n'affiche que ces deux personnes, dans le bon ordre, avec
leurs points réels. Sans cette histoire, les contacts ne servent à rien.

**Acceptance Scenarios**:

1. **Given** Camille a deux contacts acceptés, **When** elle ouvre le classement
   et choisit « Contacts », **Then** la liste contient exactement Camille et ses
   deux contacts, ordonnée par points décroissants.
2. **Given** Camille n'a aucun contact, **When** elle choisit « Contacts »,
   **Then** l'écran l'invite à en ajouter plutôt que d'afficher une liste vide
   sans explication.
3. **Given** une demande envoyée mais pas encore acceptée, **When** Camille
   consulte le classement « Contacts », **Then** la personne n'y figure pas.

---

### User Story 2 - Ajouter un collègue (Priority: P1)

Camille cherche « Théo » par son nom, trouve sa fiche et lui envoie une demande.
Théo la voit en attente, l'accepte, et chacun apparaît désormais dans le
classement de l'autre. Camille peut aussi ajouter quelqu'un directement depuis
le classement général, sans passer par la recherche.

**Why this priority**: Même priorité que l'histoire 1, parce qu'elle en est la
condition : sans moyen d'ajouter quelqu'un, le classement filtré est toujours
vide. Les deux forment ensemble le plus petit produit utilisable.

**Independent Test**: Un compte envoie une demande, l'autre la voit, l'accepte,
et le lien existe des deux côtés.

**Acceptance Scenarios**:

1. **Given** Camille saisit « Théo » dans la recherche, **When** des membres
   correspondent, **Then** elle voit leur nom et peut envoyer une demande depuis
   le résultat.
2. **Given** Camille consulte le classement général, **When** elle ouvre la
   fiche d'un membre qui n'est pas encore contact, **Then** elle peut lui envoyer
   une demande depuis cette fiche.
3. **Given** une demande reçue, **When** Théo l'accepte, **Then** chacun voit
   l'autre dans ses contacts et dans son classement filtré.
4. **Given** une demande déjà envoyée à Théo, **When** Camille rouvre sa fiche,
   **Then** elle voit l'état « en attente » et ne peut pas en envoyer une
   seconde.

---

### User Story 3 - Décider qui entre, et pouvoir revenir dessus (Priority: P2)

Théo reçoit une demande de quelqu'un qu'il ne connaît pas et la refuse. Plus
tard, il retire un contact avec qui il ne s'entraîne plus. Dans les deux cas le
lien disparaît des classements des deux côtés.

**Why this priority**: Sans refus ni retrait, la liste de contacts ne fait que
grossir et devient le classement général, ce qui annule l'intérêt de l'histoire
1. Mais la fonctionnalité a de la valeur avant d'avoir ça : on peut livrer les
deux premières histoires, puis celle-ci.

**Independent Test**: Un refus laisse les deux comptes sans lien ; un retrait
fait disparaître la personne des deux classements filtrés.

**Acceptance Scenarios**:

1. **Given** une demande en attente, **When** Théo la refuse, **Then** elle
   disparaît de ses demandes et aucun lien n'est créé.
2. **Given** une demande refusée, **When** la même personne redemande plus tard,
   **Then** la demande est recevable — un refus n'est pas un bannissement.
3. **Given** un contact accepté, **When** Théo le retire, **Then** chacun
   disparaît du classement filtré de l'autre, et des séances de l'autre.

---

### User Story 4 - Regarder comment un contact s'entraîne (Priority: P3)

Camille voit que Théo l'a dépassée. Elle ouvre sa fiche : son niveau, ses points,
son sport favori, ses records. Elle ouvre son historique et voit qu'il a couru
trois fois cette semaine, avec les parcours.

**Why this priority**: C'est ce qui donne du corps à la comparaison, mais le
classement motive déjà sans. C'est aussi l'histoire qui porte le plus de risque
sur la vie privée, donc celle qu'il vaut mieux livrer en dernier, une fois le
reste éprouvé.

**Independent Test**: Depuis la fiche d'un contact, ses statistiques et son
historique s'affichent ; depuis la fiche d'un non-contact, ils ne s'affichent
pas.

**Acceptance Scenarios**:

1. **Given** Théo est un contact accepté, **When** Camille ouvre sa fiche,
   **Then** elle voit son niveau, ses points, son sport favori et ses records.
2. **Given** Théo est un contact accepté, **When** Camille ouvre son historique,
   **Then** elle voit ses séances avec leur durée, leur dépense, leur lieu et
   leur parcours.
3. **Given** Théo n'est pas un contact, **When** Camille ouvre sa fiche depuis le
   classement général, **Then** elle ne voit que ce que le classement montre déjà
   — nom, points, rang — et le bouton pour l'ajouter.

---

### Edge Cases

- Quelqu'un s'envoie une demande à lui-même : refusé.
- Deux personnes s'envoient une demande en même temps : il ne doit en rester
  qu'un seul lien, accepté, et non deux liens symétriques en attente.
- Une demande envoyée à quelqu'un qui est déjà contact : refusée.
- Un compte supprimé alors qu'il était contact : le lien disparaît avec lui, il
  ne reste pas une ligne orpheline dans le classement de l'autre.
- Un contact qui n'a enregistré aucune séance : il apparaît au classement avec
  zéro point, il ne disparaît pas.
- La recherche ne renvoie rien : l'écran le dit, plutôt qu'une liste vide.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Un membre DOIT pouvoir chercher d'autres membres par leur nom et
  envoyer une demande de contact depuis un résultat de recherche.
- **FR-002**: Un membre DOIT pouvoir envoyer une demande de contact depuis le
  classement général, sans passer par la recherche.
- **FR-003**: Le système DOIT empêcher une demande vers soi-même, une demande en
  double, et une demande vers un contact déjà accepté.
- **FR-004**: Un membre DOIT voir les demandes qu'il a reçues et pouvoir les
  accepter ou les refuser.
- **FR-005**: Un lien de contact n'existe QUE lorsqu'il a été accepté ; une
  demande en attente ne donne accès à rien.
- **FR-006**: Un lien accepté DOIT être réciproque : chacun est contact de
  l'autre, sans qu'une seconde demande soit nécessaire.
- **FR-007**: Un membre DOIT pouvoir retirer un contact accepté, ce qui rompt le
  lien des deux côtés.
- **FR-008**: Un refus NE DOIT PAS empêcher une nouvelle demande ultérieure.
- **FR-009**: Le classement DOIT offrir une portée « Contacts », à côté de
  l'individuel et des équipes, limitée au membre et à ses contacts acceptés.
- **FR-010**: Un membre DOIT pouvoir consulter la fiche d'un contact accepté :
  niveau, points, sport favori, records.
- **FR-011**: Un membre DOIT pouvoir consulter l'historique des séances d'un
  contact accepté, y compris lieux et parcours.
- **FR-012**: Le système NE DOIT PAS exposer les statistiques détaillées ni les
  séances d'un membre qui n'est pas un contact accepté.
- **FR-013**: Les règles d'accès DOIVENT être appliquées côté serveur, et pas
  seulement par ce que l'interface choisit d'afficher.
- **FR-014**: Un écran de contacts ou un classement filtré vide DOIT expliquer
  comment le remplir plutôt que de n'afficher rien.

### Key Entities

- **Contact** : le lien entre deux membres. Porte qui a demandé, qui a reçu, son
  état (en attente, accepté) et sa date. Un seul lien par paire de membres,
  quel que soit le sens de la demande.
- **Membre** : un profil existant. Gagne la notion d'être trouvable par son nom,
  et celle d'avoir des contacts.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Depuis le classement, ajouter un collègue et le voir apparaître
  dans son classement filtré prend moins d'une minute, acceptation comprise.
- **SC-002**: Le classement « Contacts » contient exactement le membre et ses
  contacts acceptés — jamais une demande en attente, jamais un contact retiré.
- **SC-003**: Une requête directe à l'API, en dehors de l'application, ne renvoie
  ni les séances ni les statistiques détaillées d'un membre qui n'est pas un
  contact accepté.
- **SC-004**: Les quatre états d'un lien — inexistant, en attente, accepté,
  retiré — sont couverts par des tests, ainsi que le refus de la demande à
  soi-même et de la demande en double.

## Assumptions

- **Tous les membres sont des collègues.** L'app est interne à l'entreprise :
  n'importe qui peut chercher n'importe qui, sans restriction par équipe ni par
  site. Si l'app s'ouvrait au-delà, cette hypothèse tomberait la première.
- **Pas de blocage.** Un refus suffit dans un cadre de confiance. Le blocage a
  été écarté explicitement : il ajoute un état et des règles que ce contexte ne
  justifie pas encore.
- **Le partage des séances est total ou nul.** Un contact accepté voit tout
  l'historique, y compris lieux et parcours GPS ; un non-contact ne voit rien. Il
  n'y a pas de réglage par séance ni de mode privé. **Cette décision expose où et
  quand quelqu'un s'entraîne** — elle a été prise en connaissance de cause, et
  c'est la première à revoir si l'app sortait du cadre d'une équipe qui se
  connaît.
- **Pas de notification.** Une demande reçue se découvre en ouvrant l'app. Les
  notifications push ne font pas partie du produit aujourd'hui.
- **La recherche porte sur le nom affiché**, pas sur l'adresse e-mail, qui n'est
  pas une donnée que l'app expose.
- **Le schéma existe déjà.** La table `contacts` et le modèle correspondant ont
  été posés lors de la V1 puis laissés inutilisés ; cette fonctionnalité les
  active plutôt que d'en créer de nouveaux.
