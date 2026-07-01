# LandGuard Neuro-Symbolic AI 🏛️

> **Régulation foncière intelligente par Logique de Description, Prolog, ProbLog et DeepProbLog**  
> Master 1 Informatique — IA Symbolique, Probabiliste & Neuro-Symbolique

---

## 📋 Description du Projet

LandGuard est un système hybride **neuro-symbolique** de détection de fraudes foncières. Il combine :

- **Logique de Description (DL)** — modélisation formelle du domaine foncier (ontologie)
- **SWI-Prolog** — moteur d'inférence déductif avec 17 règles métier
- **ProbLog** — raisonnement sous incertitude et quantification du risque
- **DeepProbLog + PyTorch** — fusion apprentissage neuronal / raisonnement logique
- **XAI** — explicabilité complète de chaque décision générée

### Fraudes détectées
| Catégorie | Type |
|-----------|------|
| A | Accaparement urbain / rural |
| B | Spéculation foncière (revente rapide, plus-value anormale) |
| C | Conflits d'intérêts (direct, familial, favoritisme) |
| D | Réseaux de prête-noms, blanchiment foncier circulaire |

---

## 🗂️ Structure du Dépôt

```
LandGuard-Neuro-Symbolic-AI/
│
├── Partie_1/                        # Logique de Description
│   ├── knowledge_base.pl            # Concepts, rôles, axiomes DL, ABox
│   ├── description_logic.md         # Formalisation DL (12 axiomes, 10 CI)
│   └── diagramme_concepts.pdf       # Diagramme visuel de l'ontologie
│
├── Partie_2/                        # Raisonnement Symbolique Prolog
│   ├── rules.pl                     # 17 règles (catégories A, B, C, D)
│   ├── inference_engine.pl          # Moteur d'inférence + orchestration
│   └── explainability.pl            # Module XAI (journal des traces)
│
├── Partie_3/                        # Raisonnement Probabiliste ProbLog
│   ├── probabilistic_rules.pl       # 13 règles probabilistes annotées
│   ├── queries.pl                   # 18 requêtes d'inférence
│   └── rapport_inference_prob.txt   # Résultats d'exécution ProbLog
│
├── Partie_4/                        # Architecture Neuro-Symbolique
│   ├── neural_model.py              # MLP PyTorch (4 classes de fraude)
│   ├── deepproblog_model.pl         # Règles hybrides DeepProbLog
│   ├── neural_predictions.pl        # Bridge : prédictions → Prolog
│   └── model_weights.pth            # Poids du modèle entraîné
│
├── Partie_5/                        # Pipeline & Validation
│   ├── main.py                      # Orchestration complète du pipeline
│   ├── dataset.csv                  # 50 dossiers synthétiques annotés
│   └── test_suite.py                # 26 tests (unitaires + intégration)
│
└── README.md
```

---

## ⚙️ Prérequis

### Logiciels requis
| Outil | Version minimale | Installation |
|-------|-----------------|--------------|
| Python | 3.10+ | [python.org](https://python.org) |
| SWI-Prolog | 9.0+ | [swi-prolog.org](https://swi-prolog.org) |
| Git | 2.x | [git-scm.com](https://git-scm.com) |

### Librairies Python
```bash
pip install torch problog deepproblog reportlab
```

---

## 🚀 Installation

```bash
# 1. Cloner le dépôt
git clone https://github.com/VOTRE_USERNAME/LandGuard-Neuro-Symbolic-AI.git
cd LandGuard-Neuro-Symbolic-AI

# 2. Installer les dépendances Python
pip install torch problog deepproblog reportlab

# 3. Vérifier SWI-Prolog
swipl --version
```

---

## ▶️ Exécution

### Partie 1 — Logique de Description
```bash
# Consulter la base de connaissances
swipl -q Partie_1/knowledge_base.pl
?- lister_axiomes.
?- lister_contraintes.
```

### Partie 2 — Moteur Prolog
```bash
# Lancer l'inférence symbolique complète
swipl -q Partie_2/inference_engine.pl

# Requête interactive
swipl -q Partie_2/inference_engine.pl
?- accapareur_urbain(X).
?- reseau_circulaire(X, Y, Z).
?- print_traces.
```

### Partie 3 — ProbLog
```bash
# Inférence probabiliste
python3 -m problog Partie_3/queries.pl
```

### Partie 4 — Module Neuronal
```bash
# Entraîner le modèle et exporter les poids
python3 Partie_4/neural_model.py

# Tester les règles hybrides DeepProbLog
swipl -q Partie_4/deepproblog_model.pl
```

### Partie 5 — Pipeline complet
```bash
# Lancer l'orchestration complète
python3 Partie_5/main.py

# Avec options
python3 Partie_5/main.py --input Partie_5/dataset.csv --output rapport_final.json

# Lancer tous les tests (26 tests)
python3 Partie_5/test_suite.py
# ou
python3 -m pytest Partie_5/test_suite.py -v
```

---

## 📊 Résultats Clés

### Détections symboliques (Prolog)
| Acteur | Verdict |
|--------|---------|
| sawadogo | AccapareurUrbain + Spéculateur + ReseauFrauduleux |
| yussef | AccapareurUrbain (5 PU) |
| hakim | AccapareurRural (7 PR) |
| konan | ConflitInteret direct + Auto-attribution (CI-1) |
| ouedraogo | AgentFavoritiste (3 dossiers familiaux) |
| cedric / christian | PretaNomSuspect (tél + IBAN) |
| zongo | Notaire complice |

### Scores ProbLog (top 5)
| Requête | P | Criticité |
|---------|---|-----------|
| conflit_direct(konan) | 0.9025 | 🔴 CRITIQUE |
| accaparement_urbain(yussef) | 0.9200 | 🔴 CRITIQUE |
| conflit_familial(ouedraogo) | 0.8100 | 🔴 CRITIQUE |
| notaire_complice(zongo) | 0.6724 | 🟠 ÉLEVÉ |
| prete_nom_fort(cedric,christian) | 0.7115 | 🟠 ÉLEVÉ |

### Tests (26/26 ✅)
```
Groupe 1A — Accaparement Prolog    : 5/5  ✅
Groupe 1B — Spéculation Prolog     : 4/4  ✅
Groupe 1C — Conflits d'intérêts    : 4/4  ✅
Groupe 1D — Réseaux & Prête-noms   : 3/3  ✅
Groupe 2  — Bornes ProbLog         : 5/5  ✅
Groupe 3  — Intégration E2E        : 5/5  ✅
```

---

## 🏗️ Architecture du Système

```
┌─────────────────────────────────────────────────────────────┐
│                   LANDGUARD AI — PIPELINE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  dataset.csv                                                │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────┐    ┌──────────────────────────────────┐   │
│  │  PyTorch    │    │  Description Logic (TBox)        │   │
│  │  FraudMLP   │    │  12 Axiomes + 10 Contraintes     │   │
│  │  4 classes  │    └──────────────┬───────────────────┘   │
│  └──────┬──────┘                   │                       │
│         │                          ▼                       │
│         │           ┌──────────────────────────────────┐   │
│         │           │  SWI-Prolog — 17 Règles Métier   │   │
│         │           │  Catégories A, B, C, D           │   │
│         │           └──────────────┬───────────────────┘   │
│         │                          │                       │
│         ▼                          ▼                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         DeepProbLog — Fusion Neuro-Symbolique        │   │
│  │   nn(fraud_model, [X], Classe, [classes])            │   │
│  │   + règles hybrides (10 règles H1-H10)               │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │                              │
│                             ▼                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              ProbLog — Quantification du Risque       │  │
│  │   Échelle : FAIBLE / MOYEN / ÉLEVÉ / CRITIQUE        │  │
│  └──────────────────────────┬─────────────────────────── ┘  │
│                             │                              │
│                             ▼                              │
│              Rapport XAI + Journal des Traces              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📄 Licence

Projet académique — Master 1 Informatique Université Joseph Ki Zerbo 
IA Symbolique, Probabiliste & Neuro-Symbolique
