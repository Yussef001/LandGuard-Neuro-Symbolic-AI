# LandGuard Neuro-Symbolic AI
## `description_logic.md` — Modélisation en Logique de Description

---

## 1. Introduction

La **Logique de Description (DL)** est un fragment décidable de la logique du premier ordre, utilisé pour représenter formellement les ontologies de domaine. Dans LandGuard AI, elle constitue la **couche terminologique (TBox)** : elle définit *ce que les concepts signifient* et *quelles relations les lient*, indépendamment des données terrain.

Le formalisme utilisé ici est **ALC** (Attributive Language with Complements), étendu avec des **restrictions de cardinalité** (≥n r.C) pour exprimer l'accaparement.

---

## 2. Syntaxe DL utilisée

| Constructeur | Notation | Signification |
|---|---|---|
| Conjonction | C ⊓ D | "est à la fois C et D" |
| Disjonction | C ⊔ D | "est C ou D" |
| Complément | ¬C | "n'est pas C" |
| Restriction existentielle | ∃r.C | "est lié par r à au moins un C" |
| Restriction universelle | ∀r.C | "tous les liés par r sont des C" |
| Restriction ≥ n | ≥n r.C | "est lié par r à au moins n C" |
| Inclusion | C ⊑ D | "tout C est un D" |
| Équivalence | C ≡ D | "C et D sont identiques" |

---

## 3. Taxonomie des Concepts (TBox — Hiérarchie)

```
Acteur
├── Citoyen
├── AgentPublic
├── Promoteur
└── Notaire

Parcelle
├── ParcelleUrbaine
└── ParcelleRurale

Affectation
├── Attribution
├── Revente
└── Heritage

Dossier
├── DossierActif
└── DossierSuspect

LienSocial
├── LienFamilial
├── LienProfessionnel
└── LienFinancier
```

---

## 4. Rôles (Relations binaires)

| Rôle | Domaine | Co-domaine | Signification |
|---|---|---|---|
| `possede` | Acteur | Parcelle | X détient la parcelle Y |
| `traite` | Acteur | Dossier | X instruit le dossier Y |
| `beneficiaire` | Acteur | Affectation | X reçoit le bénéfice de l'affectation Y |
| `lienFamilial` | Acteur | Acteur | X et Y sont liés familialement |
| `vendA` | Acteur | Acteur | X a vendu une parcelle à Y |
| `partageTelephone` | Acteur | Acteur | X et Y partagent le même numéro |
| `partageAdresse` | Acteur | Acteur | X et Y partagent la même adresse |
| `partageIBAN` | Acteur | Acteur | X et Y partagent le même compte |
| `instruitPar` | Dossier | Acteur | Ce dossier est traité par X |
| `concerne` | Dossier | Parcelle | Ce dossier porte sur la parcelle Y |

---

## 5. Axiomes DL (TBox — 12 axiomes formalisés)

### AX-01 : Accaparement Urbain
```
Citoyen ⊓ (≥4 possede.ParcelleUrbaine)  ⊑  AccapareurUrbain
```
> Tout citoyen possédant au moins 4 parcelles urbaines est classifié comme accapareur urbain.

---

### AX-02 : Accaparement Rural
```
Citoyen ⊓ (≥6 possede.ParcelleRurale)  ⊑  AccapareurRural
```
> Seuil plus élevé pour les parcelles rurales, tenant compte de leur superficie moindre.

---

### AX-03 : Conflit d'Intérêt Direct
```
AgentPublic ⊓ ∃traite.Dossier ⊓ ∃beneficiaire.Affectation  ⊑  ConflitInteret
```
> Un agent public qui traite un dossier ET est bénéficiaire d'une affectation liée est en conflit d'intérêt direct.

---

### AX-04 : Conflit d'Intérêt Familial (indirect)
```
AgentPublic ⊓ ∃traite.Dossier ⊓ ∃lienFamilial.(∃beneficiaire.Affectation)  ⊑  ConflitInteret
```
> L'agent traite un dossier dont le bénéficiaire est un membre de sa famille.

---

### AX-05 : Suspect Prête-Nom par Téléphone
```
Citoyen ⊓ ∃partageTelephone.Citoyen ⊓ ∃possede.Parcelle  ⊑  PretaNomSuspect
```
> Deux citoyens distinctspartageant un téléphone et chacun propriétaire d'une parcelle sont suspects de prête-nom.

---

### AX-06 : Suspect Prête-Nom par Adresse
```
Citoyen ⊓ ∃partageAdresse.Citoyen ⊓ ∃possede.Parcelle  ⊑  PretaNomSuspect
```
> Variante de AX-05 par co-domiciliation.

---

### AX-07 : Spéculateur Foncier
```
Acteur ⊓ ∃vendA.(∃possede.Parcelle) ⊓ ReventeRapide  ⊑  Speculateur
```
> Acteur qui revend des parcelles rapidement après acquisition, indice de spéculation.

---

### AX-08 : Promoteur Sans Mise en Valeur
```
Promoteur ⊓ ∃possede.Parcelle ⊓ ¬MiseEnValeur  ⊑  Speculateur
```
> Un promoteur qui détient des parcelles sans les mettre en valeur pratique la rétention spéculative.

---

### AX-09 : Agent Favoritiste Répétitif
```
AgentPublic ⊓ (≥3 traite.DossierFamilial)  ⊑  AgentFavoritiste
```
> Un agent ayant traité 3 dossiers ou plus appartenant à des proches est qualifié de favoritiste.

---

### AX-10 : Réseau Transactionnel Circulaire
```
Acteur ⊓ ∃vendA.(∃vendA.(∃vendA.Self))  ⊑  ReseauFrauduleux
```
> Toute chaîne circulaire de ventes (A → B → C → A) constitue un réseau frauduleux potentiel (blanchiment).

---

### AX-11 : Concentration Familiale de Parcelles
```
Citoyen ⊓ ∃lienFamilial.(AccapareurUrbain) ⊓ (≥2 possede.ParcelleUrbaine)  ⊑  ReseauFrauduleux
```
> Un citoyen lié familialement à un accapareur et qui détient lui-même des parcelles participe à un réseau.

---

### AX-12 : Notaire Complice
```
Notaire ⊓ ∃traite.DossierSuspect ⊓ ∃lienFinancier.Promoteur  ⊑  ConflitInteret
```
> Un notaire ayant des liens financiers avec un promoteur et instruisant des dossiers suspects est en conflit.

---

## 6. Contraintes d'Intégrité (CI — 10 contraintes)

Les contraintes d'intégrité expriment des **violations formelles** : elles ne définissent pas des classes, mais déclarent des situations **interdites ou alarmantes**.

| ID | Énoncé formel | Nature |
|---|---|---|
| CI-1 | `AgentPublic(x) ⊓ DossierPropre(x,d) ⊓ traite(x,d) → ⊥` | Interdiction absolue |
| CI-2 | `Citoyen(x) ⊓ (≥4 possede.ParcelleUrbaine)(x) → VIOLATION` | Seuil légal |
| CI-3 | `Notaire(x) ⊓ instruitPar(d,x) ⊓ beneficiaire(x,aff) ⊓ concerne(d,p) → ⊥` | Interdiction absolue |
| CI-4 | `possede(x,p) ⊓ delaiRevente(x,p) < 6mois → ALERTE` | Alerte spéculation |
| CI-5 | `x≠y ⊓ partageTelephone(x,y) ⊓ possede(x,_) ⊓ possede(y,_) → SUSPICION` | Suspicion prête-nom |
| CI-6 | `x≠y ⊓ partageAdresse(x,y) ⊓ possede(x,_) ⊓ possede(y,_) → SUSPICION` | Suspicion prête-nom |
| CI-7 | `x≠y ⊓ partageIBAN(x,y) ⊓ possede(x,_) ⊓ possede(y,_) → FRAUDE_PROBABLE` | Fraude probable |
| CI-8 | `vendA(x,y) ⊓ vendA(y,z) ⊓ vendA(z,x) → BLANCHIMENT` | Blanchiment foncier |
| CI-9 | `AgentPublic(x) ⊓ lienFamilial(x,y) ⊓ traite(x,dy) → ⊥` | Interdiction absolue |
| CI-10 | `Promoteur(x) ⊓ (≥10 possede.Parcelle)(x) ⊓ ¬ProjetDeclare(x) → ALERTE` | Alerte accaparement |

---

## 7. Correspondance DL ↔ Prolog

| Constructeur DL | Traduction Prolog |
|---|---|
| `C(x)` | `citoyen(x)` — fait unitaire |
| `∃r.C(x)` | `r(x, Y), c(Y)` — appel existentiel |
| `≥n r.C(x)` | `findall(Y, (r(x,Y), c(Y)), L), length(L, N), N >= n` |
| `C ⊑ D` | `d(X) :- c(X).` — règle de subsomption |
| `C ⊓ D` | corps de règle avec deux conditions conjointes |
| `¬C` | `\+ c(X)` — négation par échec |

---

## 8. Références

- Baader et al., *The Description Logic Handbook*, Cambridge University Press, 2003.
- Horrocks et al., *SROIQ Description Logic*, JAIR 2006.
- De Raedt et al., *ProbLog: A Probabilistic Prolog*, IJCAI 2007.
