"""
LandGuard Neuro-Symbolic AI
Fichier : main.py
Partie 5 — Pipeline d'Orchestration Complet

Flux d'exécution :
    1. Chargement du dataset (dataset.csv)
    2. Inférence neuronale (PyTorch → FraudMLP)
    3. Propagation dans DeepProbLog / ProbLog
    4. Évaluation des règles symboliques (SWI-Prolog via subprocess)
    5. Fusion des résultats et génération du rapport XAI consolidé

Usage :
    python3 main.py
    python3 main.py --input dataset.csv --output rapport_final.json
"""

import argparse
import csv
import json
import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import torch
import torch.nn as nn

# ── Import du modèle neuronal ────────────────────────────────
sys.path.insert(0, str(Path(__file__).parent))
from neural_model import FraudMLP, CLASS_NAMES, N_FEATURES

# ── Constantes ───────────────────────────────────────────────
BASE_DIR   = Path(__file__).parent
WEIGHTS    = BASE_DIR / "model_weights.pth"
DATASET    = BASE_DIR / "dataset.csv"
PROLOG_KB  = BASE_DIR / "inference_engine.pl"

RISK_SCALE = {
    "STANDARD":          ("AUCUN",    "✅"),
    "ATYPIQUE":          ("FAIBLE",   "🟡"),
    "SPECULATEUR":       ("MOYEN",    "🟠"),
    "FRAUDEUR_PROBABLE": ("CRITIQUE", "🔴"),
}

# ── Utilitaires ──────────────────────────────────────────────
def banner(title):
    w = 70
    print("\n" + "=" * w)
    print(f"  {title}")
    print("=" * w)

def step(n, label):
    print(f"\n[ETAPE {n}] {label}")
    print("-" * 50)


# ════════════════════════════════════════════════════════════
# ETAPE 1 — Chargement du dataset
# ════════════════════════════════════════════════════════════
def load_dataset(path=DATASET):
    step(1, f"Chargement du dataset : {path}")
    records = []
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            records.append(row)
    print(f"  {len(records)} dossiers charges.")
    dist = {}
    for r in records:
        dist[r["label"]] = dist.get(r["label"], 0) + 1
    for label, count in sorted(dist.items()):
        print(f"  {label:<22} : {count} dossiers")
    return records


def extract_features(record):
    """Extrait le vecteur de 6 features depuis une ligne CSV."""
    try:
        return [
            float(record["nb_parcelles_urbaines"]),
            float(record["frequence_revente"]),
            float(record["ratio_plus_value"]),
            float(record["nb_liens_reseau"]),
            float(record["partage_coordonnees"]),
            float(record["age_premier_achat"]) / 100.0,  # normalise 0-1
        ]
    except (KeyError, ValueError) as e:
        print(f"  [WARN] Feature manquante pour {record.get('nom','?')} : {e}")
        return [0.0] * N_FEATURES


# ════════════════════════════════════════════════════════════
# ETAPE 2 — Inférence neuronale (PyTorch)
# ════════════════════════════════════════════════════════════
def load_neural_model(weights_path=WEIGHTS):
    step(2, "Chargement du modele PyTorch")
    if not weights_path.exists():
        print(f"  [WARN] Poids introuvables ({weights_path}). Entrainement lance...")
        os.system(f"python3 {BASE_DIR / 'neural_model.py'}")
    checkpoint = torch.load(weights_path, weights_only=False)
    model = FraudMLP()
    model.load_state_dict(checkpoint["model_state_dict"])
    model.eval()
    print(f"  Modele charge depuis : {weights_path}")
    print(f"  Architecture : {N_FEATURES} -> 64 -> 128 -> 64 -> {len(CLASS_NAMES)} classes")
    return model


def run_neural_inference(model, records):
    step(2, "Inference neuronale sur tous les dossiers")
    results = []
    features_list = [extract_features(r) for r in records]
    X = torch.tensor(features_list, dtype=torch.float32)

    with torch.no_grad():
        probas = model(X)

    for i, (record, proba) in enumerate(zip(records, probas)):
        proba_list = proba.tolist()
        pred_idx   = int(torch.argmax(proba))
        pred_class = CLASS_NAMES[pred_idx]
        results.append({
            "id":         record["id"],
            "nom":        record["nom"],
            "role":       record["role"],
            "label_reel": record["label"],
            "categorie":  record["categorie"],
            "features":   features_list[i],
            "neural_probas": {
                CLASS_NAMES[j]: round(proba_list[j], 4) for j in range(len(CLASS_NAMES))
            },
            "neural_class": pred_class,
            "neural_conf":  round(float(proba[pred_idx]), 4),
        })

    correct = sum(1 for r in results if r["neural_class"] == r["label_reel"])
    print(f"  Precision neuronale : {correct}/{len(results)} "
          f"({correct/len(results)*100:.1f}%)")
    return results


# ════════════════════════════════════════════════════════════
# ETAPE 3 — Propagation ProbLog
# ════════════════════════════════════════════════════════════
def run_problog_inference():
    step(3, "Inférence probabiliste ProbLog")
    problog_file = BASE_DIR / "queries.pl"
    if not problog_file.exists():
        print("  [WARN] queries.pl introuvable, etape ignoree.")
        return {}

    try:
        result = subprocess.run(
            ["python3", "-m", "problog", str(problog_file)],
            capture_output=True, text=True, timeout=30,
            cwd=str(BASE_DIR)
        )
        prob_results = {}
        for line in result.stdout.strip().split("\n"):
            line = line.strip()
            if ":" in line and line:
                parts = line.rsplit(":", 1)
                if len(parts) == 2:
                    query = parts[0].strip()
                    try:
                        prob  = float(parts[1].strip())
                        prob_results[query] = prob
                    except ValueError:
                        pass

        print(f"  {len(prob_results)} probabilites calculees.")
        top = sorted(prob_results.items(), key=lambda x: x[1], reverse=True)[:5]
        for q, p in top:
            print(f"  {q:<50} P={p:.4f}")
        return prob_results

    except subprocess.TimeoutExpired:
        print("  [WARN] ProbLog timeout apres 30s.")
        return {}
    except Exception as e:
        print(f"  [WARN] ProbLog erreur : {e}")
        return {}


# ════════════════════════════════════════════════════════════
# ETAPE 4 — Raisonnement symbolique Prolog
# ════════════════════════════════════════════════════════════
def run_prolog_inference():
    step(4, "Raisonnement symbolique SWI-Prolog")
    if not PROLOG_KB.exists():
        print(f"  [WARN] {PROLOG_KB} introuvable.")
        return {}

    prolog_query = """
    run_full_analysis,
    traces_to_list(L),
    forall(member(alerte(ID, Vars, Motif), L),
           format("ALERTE|~w|~w|~w~n", [ID, Vars, Motif])).
    """
    try:
        result = subprocess.run(
            ["swipl", "-q", "-g", prolog_query.strip(), "-t", "halt",
             str(PROLOG_KB)],
            capture_output=True, text=True, timeout=30,
            cwd=str(BASE_DIR)
        )
        alerts = []
        for line in result.stdout.split("\n"):
            if line.startswith("ALERTE|"):
                parts = line.split("|", 3)
                if len(parts) == 4:
                    alerts.append({
                        "rule_id": parts[1],
                        "vars":    parts[2],
                        "motif":   parts[3],
                    })
        print(f"  {len(alerts)} alertes symboliques generees.")
        seen = set()
        unique_rules = []
        for a in alerts:
            if a["rule_id"] not in seen:
                seen.add(a["rule_id"])
                unique_rules.append(a["rule_id"])
                print(f"  [{a['rule_id']}]")
        return alerts
    except subprocess.TimeoutExpired:
        print("  [WARN] Prolog timeout.")
        return []
    except FileNotFoundError:
        print("  [WARN] swipl introuvable. Verifiez l'installation SWI-Prolog.")
        return []


# ════════════════════════════════════════════════════════════
# ETAPE 5 — Fusion et rapport XAI
# ════════════════════════════════════════════════════════════
def build_xai_report(neural_results, prob_results, prolog_alerts):
    step(5, "Fusion des resultats et generation du rapport XAI")

    # Index des alertes Prolog par acteur
    prolog_by_actor = {}
    for alert in prolog_alerts:
        vars_str = alert["vars"]
        for token in vars_str.split(","):
            if "=" in token:
                key, val = token.split("=", 1)
                val = val.strip().rstrip("]").lstrip("[")
                if val not in prolog_by_actor:
                    prolog_by_actor[val] = []
                prolog_by_actor[val].append(alert["rule_id"])

    report = {
        "metadata": {
            "projet":    "LandGuard Neuro-Symbolic AI",
            "version":   "1.0",
            "date":      datetime.now().isoformat(),
            "nb_dossiers": len(neural_results),
        },
        "dossiers": [],
        "statistiques": {},
        "alertes_symboliques": prolog_alerts,
        "probabilites_problog": prob_results,
    }

    verdicts = {"STANDARD": 0, "ATYPIQUE": 0, "SPECULATEUR": 0, "FRAUDEUR_PROBABLE": 0}

    for r in neural_results:
        nom          = r["nom"]
        neural_class = r["neural_class"]
        risk, icon   = RISK_SCALE.get(neural_class, ("INCONNU", "❓"))
        prolog_rules = prolog_by_actor.get(nom, [])

        # Décision finale : si Prolog confirme une fraude sévère, on escalade
        final_class = neural_class
        if any("fraude" in rule or "accapar" in rule or "circulaire" in rule
               for rule in prolog_rules):
            if neural_class in ("STANDARD", "ATYPIQUE"):
                final_class = "FRAUDEUR_PROBABLE"
        if any("speculateur" in rule or "revente" in rule
               for rule in prolog_rules) and neural_class == "STANDARD":
            final_class = "SPECULATEUR"

        risk_final, icon_final = RISK_SCALE.get(final_class, ("INCONNU", "❓"))
        verdicts[final_class] = verdicts.get(final_class, 0) + 1

        # Explication XAI
        explication = []
        explication.append(
            f"Le modele neuronal classe {nom} comme {neural_class} "
            f"avec une confiance de {r['neural_conf']*100:.1f}%."
        )
        if prolog_rules:
            explication.append(
                f"Le moteur symbolique a declenche {len(prolog_rules)} regle(s) : "
                f"{', '.join(set(prolog_rules))}."
            )
        if final_class != neural_class:
            explication.append(
                f"ESCALADE : la decision finale est rehaussee de {neural_class} "
                f"a {final_class} par confirmation symbolique."
            )

        # Score de risque composite (neural + prolog)
        proba_fraude = r["neural_probas"].get("FRAUDEUR_PROBABLE", 0)
        proba_spec   = r["neural_probas"].get("SPECULATEUR", 0)
        n_prolog     = min(len(prolog_rules), 5)
        risk_score   = round(
            0.6 * proba_fraude + 0.2 * proba_spec + 0.2 * (n_prolog / 5), 4
        )

        report["dossiers"].append({
            "id":            r["id"],
            "nom":           nom,
            "role":          r["role"],
            "categorie":     r["categorie"],
            "label_reel":    r["label_reel"],
            "neural_class":  neural_class,
            "neural_conf":   r["neural_conf"],
            "final_class":   final_class,
            "niveau_risque": risk_final,
            "icone":         icon_final,
            "risk_score":    risk_score,
            "probas_neural": r["neural_probas"],
            "prolog_rules":  list(set(prolog_rules)),
            "explication":   " ".join(explication),
        })

    report["statistiques"] = {
        "verdicts":           verdicts,
        "precision_neurale":  round(
            sum(1 for r in neural_results if r["neural_class"] == r["label_reel"])
            / len(neural_results) * 100, 1
        ),
        "nb_alertes_prolog":  len(prolog_alerts),
        "nb_proba_problog":   len(prob_results),
    }

    return report


def print_report(report):
    banner("RAPPORT XAI CONSOLIDE — LANDGUARD NEURO-SYMBOLIC AI")

    stats = report["statistiques"]
    print(f"\n  Date        : {report['metadata']['date'][:19]}")
    print(f"  Dossiers    : {report['metadata']['nb_dossiers']}")
    print(f"  Precision neuronale : {stats['precision_neurale']}%")
    print(f"  Alertes Prolog      : {stats['nb_alertes_prolog']}")

    print("\n  DISTRIBUTION DES VERDICTS FINAUX :")
    for label, count in stats["verdicts"].items():
        icon = RISK_SCALE[label][1]
        bar  = "█" * count
        print(f"    {icon} {label:<22} : {count:>2}  {bar}")

    banner("DOSSIERS A RISQUE ELEVE OU CRITIQUE")
    high_risk = [d for d in report["dossiers"]
                 if d["niveau_risque"] in ("MOYEN", "CRITIQUE", "ELEVE")]
    high_risk.sort(key=lambda x: x["risk_score"], reverse=True)

    for d in high_risk:
        print(f"\n  {d['icone']} [{d['final_class']}] {d['nom'].upper()} "
              f"(id={d['id']}, role={d['role']})")
        print(f"     Niveau de risque  : {d['niveau_risque']}")
        print(f"     Score composite   : {d['risk_score']:.4f}")
        print(f"     Confiance neurale : {d['neural_conf']*100:.1f}%")
        if d["prolog_rules"]:
            print(f"     Regles Prolog     : {', '.join(d['prolog_rules'])}")
        print(f"     XAI               : {d['explication']}")

    banner("PROBABILITES PROBLOG (Top 5)")
    top5 = sorted(report["probabilites_problog"].items(),
                  key=lambda x: x[1], reverse=True)[:5]
    for q, p in top5:
        level = ("CRITIQUE" if p >= 0.80 else
                 "ELEVE"    if p >= 0.60 else
                 "MOYEN"    if p >= 0.30 else "FAIBLE")
        print(f"  {q:<50} P={p:.4f}  [{level}]")


def save_report(report, output_path="rapport_final.json"):
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"\n[OK] Rapport JSON exporte -> {output_path}")


# ════════════════════════════════════════════════════════════
# POINT D'ENTREE
# ════════════════════════════════════════════════════════════
def main():
    parser = argparse.ArgumentParser(description="LandGuard AI — Pipeline principal")
    parser.add_argument("--input",  default=str(DATASET),
                        help="Chemin vers le dataset CSV")
    parser.add_argument("--output", default="rapport_final.json",
                        help="Chemin du rapport JSON de sortie")
    parser.add_argument("--no-prolog",  action="store_true",
                        help="Desactiver l'etape Prolog")
    parser.add_argument("--no-problog", action="store_true",
                        help="Desactiver l'etape ProbLog")
    args = parser.parse_args()

    banner("LANDGUARD NEURO-SYMBOLIC AI — PIPELINE D'ORCHESTRATION")
    t0 = time.time()

    # 1. Chargement
    records = load_dataset(args.input)

    # 2. Neural
    model          = load_neural_model()
    neural_results = run_neural_inference(model, records)

    # 3. ProbLog
    prob_results = {} if args.no_problog else run_problog_inference()

    # 4. Prolog
    prolog_alerts = [] if args.no_prolog else run_prolog_inference()

    # 5. Fusion + rapport
    report = build_xai_report(neural_results, prob_results, prolog_alerts)
    print_report(report)
    save_report(report, args.output)

    elapsed = time.time() - t0
    print(f"\n[OK] Pipeline termine en {elapsed:.2f}s")
    banner("FIN DE L'ANALYSE LANDGUARD AI")


if __name__ == "__main__":
    main()
