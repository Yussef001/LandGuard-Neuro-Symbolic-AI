% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : queries.pl
%  Partie 3 — Requêtes d'Inférence Probabiliste (ProbLog)
%
%  Chaque query/1 demande au moteur ProbLog de calculer la
%  distribution de probabilité du prédicat cible.
%  Utilisation :
%     python3 -m problog queries.pl
% ============================================================

:- consult('probabilistic_rules.pl').

% ------------------------------------------------------------
% GROUPE 1 : Suspicion de prête-nom
% ------------------------------------------------------------

% Cedric et Christian partagent téléphone + IBAN -> prête-nom fort ?
query(prete_nom_fort(cedric, christian)).

% Suspicion par téléphone seul
query(prete_nom_telephone(cedric, christian)).

% Barkissa partage adresse avec Hakim -> prête-nom adresse ?
query(prete_nom_adresse(barkissa, hakim)).

% ------------------------------------------------------------
% GROUPE 2 : Spéculation foncière
% ------------------------------------------------------------

% Sawadogo spéculateur confirmé (revente rapide + plus-value) ?
query(speculateur_confirme(sawadogo)).

% Sawadogo spéculateur par revente seule ?
query(speculateur_revente(sawadogo)).

% Sawadogo rétention spéculative (promoteur sans mise en valeur) ?
query(speculateur_retention(sawadogo)).

% ------------------------------------------------------------
% GROUPE 3 : Réseaux frauduleux
% ------------------------------------------------------------

% Réseau circulaire sawadogo -> christian -> barkissa -> sawadogo ?
query(blanchiment_circulaire(sawadogo, christian, barkissa)).

% Concentration familiale : barkissa liée à yussef (accapareur) ?
query(concentration_familiale(barkissa)).

% Accaparement urbain : yussef (5 parcelles) ?
query(accaparement_urbain(yussef)).

% Accaparement urbain : sawadogo (11 parcelles) ?
query(accaparement_urbain(sawadogo)).

% ------------------------------------------------------------
% GROUPE 4 : Conflits d'intérêts
% ------------------------------------------------------------

% Konan : conflit d'intérêt direct (traite son propre dossier) ?
query(conflit_direct(konan)).

% Ouedraogo : conflit d'intérêt familial (dossier d'Othniel) ?
query(conflit_familial(ouedraogo, othniel)).

% ------------------------------------------------------------
% GROUPE 5 : Complicité notariale
% ------------------------------------------------------------

% Zongo : notaire complice de sawadogo ?
query(notaire_complice(zongo)).

% ------------------------------------------------------------
% GROUPE 6 : Score global FRAUDEUR_PROBABLE
% ------------------------------------------------------------

% Sawadogo : fraudeur probable (spéculateur confirmé + accaparement) ?
query(fraudeur_probable(sawadogo)).

% Cedric : fraudeur probable (prête-nom fort + blanchiment) ?
query(fraudeur_probable(cedric)).

% Konan : fraudeur probable (conflit direct + familial) ?
query(fraudeur_probable(konan)).

% Zongo : fraudeur probable (notaire complice + blanchiment) ?
query(fraudeur_probable(zongo)).
