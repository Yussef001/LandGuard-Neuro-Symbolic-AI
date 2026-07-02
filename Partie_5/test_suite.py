"""
LandGuard Neuro-Symbolic AI
Fichier : test_suite.py
Partie 5 — Suite de Tests Unitaires et d'Intégration

Couverture :
    - 15 tests unitaires sur les règles Prolog pures
    - 5  tests de bornes pour ProbLog
    - 5  tests d'intégration end-to-end (pipeline complet)

Usage :
    python3 -m pytest test_suite.py -v
    python3 test_suite.py          (mode standalone)
"""

import csv
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path

import torch

BASE_DIR = Path(__file__).parent
sys.path.insert(0, str(BASE_DIR))
from neural_model import FraudMLP, CLASS_NAMES, N_FEATURES

# ════════════════════════════════════════════════════════════════════════
# UTILITAIRES
# ════════════════════════════════════════════════════════════════════════

def prolog_query(goal, timeout=15):
    """
    Exécute un goal Prolog via SWI-Prolog et retourne stdout avec encodage UTF-8.
    """
    pl_script = BASE_DIR / "inference_engine.pl" 
    
    try:
        result = subprocess.run(
            [
                r"C:\Program Files\swipl\bin\swipl.exe", 
                "-q", 
                "--nodebug",
                "-f", "none",            
                "-s", str(pl_script), 
                "-g", goal, 
                "-t", "halt"
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",     
            cwd=str(BASE_DIR),
            timeout=timeout
        )
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", -1
    except Exception as e:
        return "", -2


def prolog_succeeds(goal, timeout=15):
    """Retourne True si le goal Prolog réussit (au moins une solution)."""
    wrapped = f"( {goal} -> true ; fail )"
    out, rc = prolog_query(wrapped, timeout)
    return rc == 0


def problog_query(query_term, timeout=30):
    """
    Exécute une requête ProbLog de manière isolée et retourne sa probabilité.
    Version blindée pour Windows avec capture des flux d'erreurs.
    """
    # Nettoyage et sécurisation du chemin pour le consult Prolog sous Windows
    safe_path = str(BASE_DIR / "probabilistic_rules.pl").replace('\\', '/')
    
    pl_content = f"""
:- consult('{safe_path}').
query({query_term}).
"""
    tmp = BASE_DIR / "_tmp_test_query.pl"
    tmp.write_text(pl_content, encoding="utf-8")
    
    try:
        # Copie et nettoyage de l'environnement système pour hériter des variables PATH
        env = os.environ.copy()
        
        result = subprocess.run(
            [sys.executable, "-m", "problog", str(tmp)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="ignore",
            env=env,
            timeout=timeout,
            cwd=str(BASE_DIR)
        )
        
        # --- DIAGNOSTIC EN CAS D'ÉCHEC ---
        # Si la sortie standard est vide mais qu'il y a une erreur dans stderr
        if not result.stdout.strip() and result.stderr.strip():
            print(f"\n[DEBUG PROBLOG] Erreur détectée : {result.stderr.strip()}", file=sys.stderr)
            return None

        # Analyse de la sortie standard
        for line in result.stdout.strip().split("\n"):
            if ":" in line:
                parts = line.rsplit(":", 1)
                if len(parts) == 2:
                    try:
                        return float(parts[1].strip())
                    except ValueError:
                        pass
        return None
        
    except Exception as e:
        print(f"\n[DEBUG PROBLOG] Exception Python : {str(e)}", file=sys.stderr)
        return None
    finally:
        # Nettoyage du fichier temporaire
        tmp.unlink(missing_ok=True)


# ════════════════════════════════════════════════════════════════════════
# GROUPE 1 — TESTS UNITAIRES : RÈGLES PROLOG (15 tests)
# ════════════════════════════════════════════════════════════════════════

class TestPrologRulesA(unittest.TestCase):
    """Catégorie A — Accaparement"""

    def test_A1_accapareur_urbain_yussef(self):
        """Yussef (5 PU) doit être détecté comme AccapareurUrbain."""
        self.assertTrue(
            prolog_succeeds("accapareur_urbain(yussef)"),
            "yussef avec 5 parcelles urbaines doit etre AccapareurUrbain"
        )

    def test_A1_non_accapareur_othniel(self):
        """Othniel (1 PU) NE doit PAS être AccapareurUrbain."""
        self.assertFalse(
            prolog_succeeds("accapareur_urbain(othniel)"),
            "othniel avec 1 parcelle ne doit pas etre AccapareurUrbain"
        )

    def test_A2_accapareur_rural_hakim(self):
        """Hakim (7 PR) doit être détecté comme AccapareurRural."""
        self.assertTrue(
            prolog_succeeds("accapareur_rural(hakim)"),
            "hakim avec 7 parcelles rurales doit etre AccapareurRural"
        )

    def test_A3_concentration_familiale_barkissa(self):
        """Barkissa (liée à yussef + 2 PU) doit déclencher concentration_familiale."""
        self.assertTrue(
            prolog_succeeds("concentration_familiale(barkissa)"),
            "barkissa liee a yussef et possedant 2 PU doit etre en concentration_familiale"
        )

    def test_A4_promoteur_accapareur_sawadogo(self):
        """Sawadogo (11 parcelles, sans projet) doit déclencher promoteur_accapareur."""
        self.assertTrue(
            prolog_succeeds("promoteur_accapareur(sawadogo)"),
            "sawadogo avec 11 parcelles sans projet doit etre promoteur_accapareur"
        )


class TestPrologRulesB(unittest.TestCase):
    """Catégorie B — Spéculation"""

    def test_B1_revente_rapide_sawadogo(self):
        """Sawadogo (revente p11 en 3 mois) doit déclencher revente_rapide."""
        self.assertTrue(
            prolog_succeeds("revente_rapide(sawadogo, p11)"),
            "sawadogo a revendu p11 en 3 mois, doit etre detecte"
        )

    def test_B2_plus_value_anormale_p11(self):
        """p11 (ratio 1.8) doit déclencher plus_value_anormale."""
        self.assertTrue(
            prolog_succeeds("plus_value_anormale(p11)"),
            "p11 avec ratio PV/PA=1.8 doit avoir plus_value_anormale"
        )

    def test_B3_speculateur_sawadogo(self):
        """Sawadogo (revente rapide + plus-value) doit être Speculateur."""
        self.assertTrue(
            prolog_succeeds("speculateur_revente(sawadogo)"),
            "sawadogo doit etre speculateur (revente rapide + plus-value)"
        )

    def test_B4_promoteur_sans_mise_en_valeur(self):
        """Sawadogo doit déclencher promoteur_sans_mise_en_valeur sur au moins une parcelle."""
        self.assertTrue(
            prolog_succeeds("promoteur_sans_mise_en_valeur(sawadogo, _)"),
            "sawadogo doit avoir des parcelles sans mise en valeur"
        )


class TestPrologRulesC(unittest.TestCase):
    """Catégorie C — Conflits d'intérêts"""

    def test_C1_conflit_direct_konan(self):
        """Konan (traite d1 + bénéficiaire aff1) doit déclencher conflit_interet_direct."""
        self.assertTrue(
            prolog_succeeds("conflit_interet_direct(konan)"),
            "konan doit etre en conflit d'interet direct"
        )

    def test_C2_conflit_familial_ouedraogo(self):
        """Ouedraogo (traite dossier d'othniel) doit déclencher conflit_interet_familial."""
        self.assertTrue(
            prolog_succeeds("conflit_interet_familial(ouedraogo)"),
            "ouedraogo doit etre en conflit d'interet familial"
        )

    def test_C3_auto_attribution_konan(self):
        """Konan (traite son propre dossier d6) doit déclencher auto_attribution."""
        self.assertTrue(
            prolog_succeeds("auto_attribution(konan)"),
            "konan doit etre detecte en auto-attribution (CI-1)"
        )

    def test_C4_favoritisme_ouedraogo(self):
        """Ouedraogo (3 dossiers familiaux) doit déclencher favoritisme_repetitif."""
        self.assertTrue(
            prolog_succeeds("favoritisme_repetitif(ouedraogo)"),
            "ouedraogo avec 3 dossiers familiaux doit etre AgentFavoritiste"
        )


class TestPrologRulesD(unittest.TestCase):
    """Catégorie D — Réseaux & Prête-noms"""

    def test_D1_prete_nom_telephone(self):
        """Cédric et Christian (téléphone partagé) doivent déclencher prete_nom_telephone."""
        self.assertTrue(
            prolog_succeeds("prete_nom_telephone(cedric, christian)"),
            "cedric et christian doivent etre detectes prete_nom_telephone"
        )

    def test_D4_reseau_circulaire(self):
        """sawadogo→christian→barkissa→sawadogo doit déclencher reseau_circulaire."""
        self.assertTrue(
            prolog_succeeds("reseau_circulaire(sawadogo, christian, barkissa)"),
            "le reseau circulaire sawadogo-christian-barkissa doit etre detecte"
        )

    def test_D5_notaire_complice_zongo(self):
        """Zongo (dossier suspect + lien financier sawadogo) doit déclencher notaire_complice."""
        self.assertTrue(
            prolog_succeeds("notaire_complice(zongo)"),
            "zongo doit etre detecte notaire_complice"
        )


# ════════════════════════════════════════════════════════════════════════
# GROUPE 2 — TESTS DE BORNES PROBLOG (5 tests)
# ════════════════════════════════════════════════════════════════════════

class TestProblogBounds(unittest.TestCase):
    """Vérifie que les probabilités ProbLog restent dans des bornes cohérentes."""

    def _get_prob(self, query):
        p = problog_query(query)
        self.assertIsNotNone(p, f"ProbLog n'a pas retourne de probabilite pour : {query}")
        return p

    def test_PB1_accaparement_urbain_yussef_critique(self):
        """P(accaparement_urbain(yussef)) doit être >= 0.80 (niveau CRITIQUE)."""
        p = self._get_prob("accaparement_urbain(yussef)")
        self.assertGreaterEqual(p, 0.80,
            f"P(accaparement_urbain(yussef))={p} doit etre >= 0.80")

    def test_PB2_prete_nom_fort_critique(self):
        """P(prete_nom_fort(cedric, christian)) doit être >= 0.60 (niveau ELEVE)."""
        p = self._get_prob("prete_nom_fort(cedric, christian)")
        self.assertGreaterEqual(p, 0.60,
            f"P(prete_nom_fort)={p} doit etre >= 0.60")

    def test_PB3_conflit_direct_konan_critique(self):
        """P(conflit_direct(konan)) doit être >= 0.80 (niveau CRITIQUE)."""
        p = self._get_prob("conflit_direct(konan)")
        self.assertGreaterEqual(p, 0.80,
            f"P(conflit_direct(konan))={p} doit etre >= 0.80")

    def test_PB4_notaire_complice_eleve(self):
        """P(notaire_complice(zongo)) doit être dans [0.60, 1.0] (niveau ELEVE)."""
        p = self._get_prob("notaire_complice(zongo)")
        self.assertGreaterEqual(p, 0.60,
            f"P(notaire_complice(zongo))={p} doit etre >= 0.60")
        self.assertLessEqual(p, 1.0)

    def test_PB5_probabilite_valide_bornee(self):
        """Toute probabilité ProbLog doit être dans [0.0, 1.0]."""
        queries = [
            "speculateur_confirme(sawadogo)",
            "blanchiment_circulaire(sawadogo, christian, barkissa)",
            "conflit_familial(ouedraogo, othniel)",
        ]
        for q in queries:
            p = self._get_prob(q)
            self.assertGreaterEqual(p, 0.0, f"P({q}) < 0")
            self.assertLessEqual(p, 1.0,    f"P({q}) > 1")


# ════════════════════════════════════════════════════════════════════════
# GROUPE 3 — TESTS D'INTÉGRATION END-TO-END (5 tests)
# ════════════════════════════════════════════════════════════════════════

class TestEndToEnd(unittest.TestCase):
    """Tests d'intégration sur le pipeline complet."""

    def test_E1_dataset_structure(self):
        """Le dataset doit contenir 50 dossiers avec les colonnes requises."""
        path = BASE_DIR / "dataset.csv"
        self.assertTrue(path.exists(), "dataset.csv doit exister")
        with open(path, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
        self.assertEqual(len(rows), 50, f"Le dataset doit avoir 50 dossiers, il en a {len(rows)}")
        required_cols = ["id", "nom", "role", "nb_parcelles_urbaines",
                         "frequence_revente", "ratio_plus_value",
                         "nb_liens_reseau", "partage_coordonnees",
                         "age_premier_achat", "label", "categorie"]
        for col in required_cols:
            self.assertIn(col, reader.fieldnames,
                          f"Colonne requise manquante : {col}")

    def test_E2_dataset_distribution(self):
        """Le dataset doit respecter la distribution imposée par le cahier des charges."""
        path = BASE_DIR / "dataset.csv"
        with open(path, encoding="utf-8") as f:
            rows = list(csv.DictReader(f))
        dist = {}
        for r in rows:
            dist[r["label"]] = dist.get(r["label"], 0) + 1
        self.assertGreaterEqual(dist.get("STANDARD", 0), 30,
            "Au moins 30 dossiers STANDARD requis")
        self.assertGreaterEqual(dist.get("SPECULATEUR", 0), 5,
            "Au moins 5 dossiers SPECULATEUR requis")
        self.assertGreaterEqual(dist.get("FRAUDEUR_PROBABLE", 0), 5,
            "Au moins 5 dossiers FRAUDEUR_PROBABLE requis")

    def test_E3_neural_model_loads_and_predicts(self):
        """Le modèle PyTorch doit se charger et prédire sans erreur."""
        weights = BASE_DIR / "model_weights.pth"
        self.assertTrue(weights.exists(), "model_weights.pth doit exister")
        checkpoint = torch.load(weights, weights_only=False)
        model = FraudMLP()
        model.load_state_dict(checkpoint["model_state_dict"])
        model.eval()
        dummy = torch.zeros(1, N_FEATURES)
        with torch.no_grad():
            out = model(dummy)
        self.assertEqual(out.shape, (1, len(CLASS_NAMES)),
            f"Sortie attendue : (1, {len(CLASS_NAMES)}), obtenu : {out.shape}")
        self.assertAlmostEqual(out.sum().item(), 1.0, places=4,
            msg="La somme des probabilites doit etre ~1.0 (softmax)")

    def test_E4_pipeline_runs_without_crash(self):
        """Le pipeline main.py doit s'exécuter sans erreur sur le dataset complet."""
        import sys
        result = subprocess.run(
            [sys.executable, str(BASE_DIR / "main.py"),  
             "--input",  str(BASE_DIR / "dataset.csv"),
             "--output", str(BASE_DIR / "_test_output.json"),
             "--no-problog"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",                           
            errors="ignore",
            timeout=60,
            cwd=str(BASE_DIR)
        )
        self.assertEqual(result.returncode, 0,
            f"main.py a echoue (code {result.returncode}) :\n{result.stderr[:500]}")
        out_path = BASE_DIR / "_test_output.json"
        self.assertTrue(out_path.exists(), "rapport_final.json doit etre cree")
        out_path.unlink(missing_ok=True)

    def test_E5_xai_report_structure(self):
        """Le rapport JSON doit contenir les sections XAI attendues."""
        import sys
        result = subprocess.run(
            [sys.executable, str(BASE_DIR / "main.py"),  # <-- Utilise sys.executable au lieu de "python3"
             "--input",  str(BASE_DIR / "dataset.csv"),
             "--output", str(BASE_DIR / "_test_xai.json"),
             "--no-problog", "--no-prolog"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",                            # <-- Sécurise l'encodage
            errors="ignore",
            timeout=60,
            cwd=str(BASE_DIR)
        )
        self.assertEqual(result.returncode, 0,
            f"main.py a echoue au test E5 (code {result.returncode}) :\n{result.stderr[:500]}")
        out_path = BASE_DIR / "_test_xai.json"
        with open(out_path, encoding="utf-8") as f:
            report = json.load(f)
        self.assertIn("metadata",    report, "Section 'metadata' manquante")
        self.assertIn("dossiers",    report, "Section 'dossiers' manquante")
        self.assertIn("statistiques",report, "Section 'statistiques' manquante")
        self.assertEqual(len(report["dossiers"]), 50,
            "Le rapport doit contenir 50 dossiers")
        first = report["dossiers"][0]
        for field in ["nom", "neural_class", "final_class",
                      "niveau_risque", "explication", "risk_score"]:
            self.assertIn(field, first,
                f"Champ XAI '{field}' manquant dans les dossiers")
        out_path.unlink(missing_ok=True)


# ════════════════════════════════════════════════════════════════════════
# RUNNER STANDALONE
# ════════════════════════════════════════════════════════════════════════

def run_all_tests():
    loader = unittest.TestLoader()
    suite  = unittest.TestSuite()
    groups = [
        ("GROUPE 1A — Accaparement (Prolog)",       TestPrologRulesA),
        ("GROUPE 1B — Speculation (Prolog)",         TestPrologRulesB),
        ("GROUPE 1C — Conflits d'interets (Prolog)", TestPrologRulesC),
        ("GROUPE 1D — Reseaux & Prete-noms (Prolog)",TestPrologRulesD),
        ("GROUPE 2  — Bornes ProbLog",               TestProblogBounds),
        ("GROUPE 3  — Integration End-to-End",       TestEndToEnd),
    ]
    total_pass = total_fail = total_err = 0
    for group_name, test_class in groups:
        print(f"\n{'='*62}")
        print(f"  {group_name}")
        print(f"{'='*62}")
        group_suite = loader.loadTestsFromTestCase(test_class)
        runner = unittest.TextTestRunner(verbosity=2, stream=sys.stdout)
        result = runner.run(group_suite)
        total_pass += result.testsRun - len(result.failures) - len(result.errors)
        total_fail += len(result.failures)
        total_err  += len(result.errors)

    print(f"\n{'='*62}")
    print(f"  BILAN FINAL : {total_pass} passes | "
          f"{total_fail} echecs | {total_err} erreurs")
    print(f"  Total : {total_pass + total_fail + total_err} tests")
    print(f"{'='*62}")


if __name__ == "__main__":
    run_all_tests()
