"""
LandGuard Neuro-Symbolic AI
Fichier : neural_model.py
Partie 4 — Module Neuronal PyTorch

Réseau de neurones MLP (Multi-Layer Perceptron) qui classe chaque
dossier foncier en 4 catégories :
    0 : STANDARD         (aucune anomalie détectée)
    1 : ATYPIQUE         (profil inhabituel mais non frauduleux)
    2 : SPECULATEUR      (indices de spéculation foncière)
    3 : FRAUDEUR_PROBABLE (fraude composite hautement probable)

Features d'entrée (6 variables) :
    0 : nb_parcelles          — nombre total de parcelles détenues
    1 : frequence_revente     — reventes / an
    2 : ratio_plus_value      — prix_vente / prix_achat moyen
    3 : nb_liens_reseau       — connexions suspectes (tél/adresse/IBAN)
    4 : partage_coordonnees   — 1 si partage tél ou adresse, 0 sinon
    5 : age_premier_achat     — âge lors du 1er achat (normalise 0-1)
"""

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
import os

# ── Reproductibilité ────────────────────────────────────────
torch.manual_seed(42)
np.random.seed(42)

# ── Constantes ───────────────────────────────────────────────
N_FEATURES  = 6
N_CLASSES   = 4
CLASS_NAMES = ["STANDARD", "ATYPIQUE", "SPECULATEUR", "FRAUDEUR_PROBABLE"]

# Correspondance avec les acteurs du jeu de données LandGuard
ACTOR_FEATURES = {
    # nom          : [nb_parc, freq_rev, ratio_pv, nb_liens, partage, age_norm]
    "yussef"       : [5,  0.1, 1.05, 1, 0, 0.60],   # accapareur urbain
    "othniel"      : [1,  0.0, 1.00, 0, 0, 0.55],   # standard
    "hakim"        : [7,  0.1, 1.02, 1, 1, 0.50],   # accapareur rural + adresse
    "cedric"       : [1,  0.2, 1.10, 2, 1, 0.35],   # prête-nom fort
    "christian"    : [1,  0.3, 1.15, 2, 1, 0.30],   # prête-nom fort
    "barkissa"     : [3,  0.2, 1.08, 2, 1, 0.45],   # réseau familial
    "pascal"       : [1,  0.0, 1.00, 0, 0, 0.48],   # standard
    "konan"        : [2,  0.0, 1.00, 1, 0, 0.58],   # conflit direct
    "ouedraogo"    : [1,  0.0, 1.00, 1, 0, 0.62],   # conflit familial
    "sawadogo"     : [11, 0.8, 1.80, 3, 0, 0.40],   # fraude composite
    "zongo"        : [0,  0.0, 1.00, 1, 0, 0.65],   # notaire complice
}

# ── Jeu de données synthétique (50 dossiers) ─────────────────
# Répartition conforme au cahier des charges :
#   30 standard, 5 spéculateurs, 5 accapareurs, 5 limites, 5 fraudes complexes
def generate_dataset():
    X, y = [], []

    # 30 cas STANDARD (classe 0)
    for _ in range(30):
        x = [
            np.random.randint(1, 3),              # 1-2 parcelles
            round(np.random.uniform(0.0, 0.2), 2),
            round(np.random.uniform(0.95, 1.15), 2),
            np.random.randint(0, 1),
            0,
            round(np.random.uniform(0.35, 0.75), 2),
        ]
        X.append(x); y.append(0)

    # 5 cas SPECULATEUR (classe 2)
    specul_actors = [
        [4, 0.8, 1.85, 1, 0, 0.38],
        [3, 1.2, 2.10, 0, 0, 0.42],
        [5, 0.9, 1.70, 1, 0, 0.35],
        [6, 1.5, 2.30, 2, 0, 0.30],
        [3, 0.7, 1.60, 0, 0, 0.44],
    ]
    for x in specul_actors:
        X.append(x); y.append(2)

    # 5 cas ATYPIQUE/accaparement (classe 1)
    accap_actors = [
        [5, 0.1, 1.05, 1, 0, 0.60],   # yussef-like
        [7, 0.2, 1.10, 1, 1, 0.52],   # hakim-like
        [4, 0.0, 1.00, 0, 0, 0.68],
        [6, 0.1, 1.03, 1, 0, 0.55],
        [8, 0.2, 1.08, 2, 1, 0.48],
    ]
    for x in accap_actors:
        X.append(x); y.append(1)

    # 5 cas LIMITES (classe 1 — profil ambigu)
    limite_actors = [
        [3, 0.5, 1.40, 2, 1, 0.38],
        [2, 0.4, 1.35, 1, 1, 0.42],
        [4, 0.6, 1.50, 2, 0, 0.36],
        [3, 0.3, 1.25, 1, 1, 0.50],
        [5, 0.4, 1.30, 2, 1, 0.33],
    ]
    for x in limite_actors:
        X.append(x); y.append(1)

    # 5 cas FRAUDEUR_PROBABLE (classe 3)
    fraude_actors = [
        [11, 0.8, 1.80, 3, 0, 0.40],   # sawadogo-like
        [9,  1.2, 2.50, 3, 1, 0.28],
        [7,  1.5, 2.80, 4, 1, 0.25],
        [12, 0.9, 2.20, 3, 0, 0.32],
        [8,  1.1, 2.40, 4, 1, 0.27],
    ]
    for x in fraude_actors:
        X.append(x); y.append(3)

    return np.array(X, dtype=np.float32), np.array(y, dtype=np.int64)


# ── Architecture du réseau MLP ────────────────────────────────
class FraudMLP(nn.Module):
    """
    MLP à 3 couches cachées avec BatchNorm et Dropout.
    Sortie : distribution softmax sur 4 classes.
    """
    def __init__(self, n_features=N_FEATURES, n_classes=N_CLASSES):
        super().__init__()
        self.network = nn.Sequential(
            # Couche 1 : 6 -> 64
            nn.Linear(n_features, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.2),
            # Couche 2 : 64 -> 128
            nn.Linear(64, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.3),
            # Couche 3 : 128 -> 64
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.ReLU(),
            nn.Dropout(0.2),
            # Sortie : 64 -> 4
            nn.Linear(64, n_classes),
        )
        self.softmax = nn.Softmax(dim=1)

    def forward(self, x):
        logits = self.network(x)
        return self.softmax(logits)

    def predict_proba(self, x):
        """Retourne la distribution de probabilité sur les 4 classes."""
        self.eval()
        with torch.no_grad():
            return self.forward(x)

    def predict_class(self, x):
        """Retourne la classe prédite et son nom."""
        proba = self.predict_proba(x)
        idx = torch.argmax(proba, dim=1)
        return idx, [CLASS_NAMES[i] for i in idx.tolist()]


# ── Entraînement ─────────────────────────────────────────────
def train(model, X_train, y_train, epochs=200, lr=0.001, batch_size=16):
    dataset    = TensorDataset(torch.tensor(X_train), torch.tensor(y_train))
    loader     = DataLoader(dataset, batch_size=batch_size, shuffle=True)
    criterion  = nn.CrossEntropyLoss()
    optimizer  = optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler  = optim.lr_scheduler.StepLR(optimizer, step_size=50, gamma=0.5)

    print(f"Entrainement : {epochs} epochs, lr={lr}, batch={batch_size}")
    for epoch in range(1, epochs + 1):
        model.train()
        total_loss, correct = 0.0, 0
        for xb, yb in loader:
            optimizer.zero_grad()
            logits = model.network(xb)     # logits bruts pour CrossEntropy
            loss   = criterion(logits, yb)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            correct    += (logits.argmax(1) == yb).sum().item()
        scheduler.step()
        if epoch % 50 == 0 or epoch == 1:
            acc = correct / len(y_train) * 100
            print(f"  Epoch {epoch:>3}/{epochs}  Loss={total_loss/len(loader):.4f}  Acc={acc:.1f}%")
    return model


# ── Évaluation ───────────────────────────────────────────────
def evaluate(model, X, y):
    model.eval()
    with torch.no_grad():
        xt = torch.tensor(X)
        logits = model.network(xt)
        preds  = logits.argmax(1).numpy()
    acc = (preds == y).mean() * 100
    print(f"\nPrecision globale : {acc:.1f}%")
    print(f"{'Acteur/Classe':<22} {'Predit':<20} {'Reel'}")
    print("-" * 56)
    for i, (p, r) in enumerate(zip(preds, y)):
        print(f"  Dossier {i+1:<13} {CLASS_NAMES[p]:<20} {CLASS_NAMES[r]}")
    return acc


# ── Inférence sur les acteurs LandGuard ──────────────────────
def infer_actors(model):
    print("\n========== PREDICTIONS SUR LES ACTEURS LANDGUARD ==========")
    print(f"{'Acteur':<14} {'STANDARD':>10} {'ATYPIQUE':>10} {'SPECULATEUR':>13} {'FRAUDEUR':>10}  Classe predite")
    print("-" * 75)
    for actor, features in ACTOR_FEATURES.items():
        xt    = torch.tensor([features], dtype=torch.float32)
        proba = model.predict_proba(xt)[0]
        idx   = proba.argmax().item()
        print(f"  {actor:<12}  {proba[0]:>8.4f}  {proba[1]:>8.4f}  {proba[2]:>11.4f}  {proba[3]:>8.4f}   {CLASS_NAMES[idx]}")
    print("=" * 75)


# ── Export pour DeepProbLog ───────────────────────────────────
def export_for_deepproblog(model, output_path="model_weights.pth"):
    """
    Sauvegarde les poids du modèle pour intégration DeepProbLog.
    DeepProbLog charge ce fichier via nn(fraud_model, [X], Y, [classes]).
    """
    torch.save({
        "model_state_dict": model.state_dict(),
        "n_features":       N_FEATURES,
        "n_classes":        N_CLASSES,
        "class_names":      CLASS_NAMES,
        "actor_features":   ACTOR_FEATURES,
    }, output_path)
    print(f"\n[OK] Poids exportes -> {output_path}")


# ── Main ─────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  LANDGUARD AI — Module Neuronal PyTorch")
    print("=" * 60)

    # 1. Génération du dataset
    X, y = generate_dataset()
    print(f"\nDataset : {len(X)} dossiers, {N_FEATURES} features, {N_CLASSES} classes")
    print(f"  Distribution : STANDARD={sum(y==0)}, ATYPIQUE={sum(y==1)}, "
          f"SPECULATEUR={sum(y==2)}, FRAUDEUR={sum(y==3)}")

    # 2. Création et entraînement
    model = FraudMLP()
    print(f"\nArchitecture MLP :")
    print(f"  Entrée  : {N_FEATURES} features")
    print(f"  Couches : 64 -> 128 -> 64 (BatchNorm + Dropout)")
    print(f"  Sortie  : {N_CLASSES} classes (Softmax)\n")
    model = train(model, X, y, epochs=200)

    # 3. Évaluation
    evaluate(model, X, y)

    # 4. Inférence sur les acteurs LandGuard
    infer_actors(model)

    # 5. Export
    export_for_deepproblog(model, "model_weights.pth")
    print("\n[OK] neural_model.py termine.")
