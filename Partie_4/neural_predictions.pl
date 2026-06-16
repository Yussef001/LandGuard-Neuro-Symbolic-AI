:- set_prolog_flag(encoding, utf8).
% ============================================================
%  neural_predictions.pl — Généré automatiquement par neural_model.py
%  Contient les prédictions du modèle PyTorch pour chaque acteur.
%  neural_class(Acteur, Classe) : classe prédite par le MLP.
%  neural_proba(Acteur, Classe, P) : probabilité associée.
% ============================================================

% --- yussef ---
neural_class(yussef, atypique).
neural_proba(yussef, standard, 0.078084).
neural_proba(yussef, atypique, 0.908495).
neural_proba(yussef, speculateur, 0.006134).
neural_proba(yussef, fraudeur_probable, 0.007287).

% --- othniel ---
neural_class(othniel, standard).
neural_proba(othniel, standard, 0.962887).
neural_proba(othniel, atypique, 0.020615).
neural_proba(othniel, speculateur, 0.012951).
neural_proba(othniel, fraudeur_probable, 0.003547).

% --- hakim ---
neural_class(hakim, atypique).
neural_proba(hakim, standard, 0.007574).
neural_proba(hakim, atypique, 0.991668).
neural_proba(hakim, speculateur, 0.000219).
neural_proba(hakim, fraudeur_probable, 0.000539).

% --- cedric ---
neural_class(cedric, atypique).
neural_proba(cedric, standard, 0.009176).
neural_proba(cedric, atypique, 0.986136).
neural_proba(cedric, speculateur, 0.000525).
neural_proba(cedric, fraudeur_probable, 0.004163).

% --- christian ---
neural_class(christian, atypique).
neural_proba(christian, standard, 0.010190).
neural_proba(christian, atypique, 0.984154).
neural_proba(christian, speculateur, 0.000634).
neural_proba(christian, fraudeur_probable, 0.005022).

% --- barkissa ---
neural_class(barkissa, atypique).
neural_proba(barkissa, standard, 0.009149).
neural_proba(barkissa, atypique, 0.988923).
neural_proba(barkissa, speculateur, 0.000407).
neural_proba(barkissa, fraudeur_probable, 0.001520).

% --- pascal ---
neural_class(pascal, standard).
neural_proba(pascal, standard, 0.962862).
neural_proba(pascal, atypique, 0.020258).
neural_proba(pascal, speculateur, 0.013319).
neural_proba(pascal, fraudeur_probable, 0.003560).

% --- konan ---
neural_class(konan, standard).
neural_proba(konan, standard, 0.650816).
neural_proba(konan, atypique, 0.306710).
neural_proba(konan, speculateur, 0.028280).
neural_proba(konan, fraudeur_probable, 0.014193).

% --- ouedraogo ---
neural_class(ouedraogo, standard).
neural_proba(ouedraogo, standard, 0.680372).
neural_proba(ouedraogo, atypique, 0.260152).
neural_proba(ouedraogo, speculateur, 0.038205).
neural_proba(ouedraogo, fraudeur_probable, 0.021271).

% --- sawadogo ---
neural_class(sawadogo, fraudeur_probable).
neural_proba(sawadogo, standard, 0.037784).
neural_proba(sawadogo, atypique, 0.044283).
neural_proba(sawadogo, speculateur, 0.014948).
neural_proba(sawadogo, fraudeur_probable, 0.902985).

% --- zongo ---
neural_class(zongo, standard).
neural_proba(zongo, standard, 0.619589).
neural_proba(zongo, atypique, 0.294324).
neural_proba(zongo, speculateur, 0.050785).
neural_proba(zongo, fraudeur_probable, 0.035302).
