% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : probabilistic_rules.pl
%  Partie 3 — Raisonnement Probabiliste avec ProbLog
%
%  Chaque clause probabiliste est annotée d'un poids a priori
%  représentant la confiance dans la règle lorsque ses conditions
%  sont observées.  Le moteur ProbLog propage ces poids pour
%  calculer P(fraude | observations).
%
%  Échelle de criticité :
%    Faible    : P < 0.30
%    Moyen     : 0.30 <= P < 0.60
%    Élevé     : 0.60 <= P < 0.80
%    Critique  : P >= 0.80
% ============================================================

% ------------------------------------------------------------
% SECTION 1 : FAITS TERRAIN (ABox probabiliste)
%   Reprend les instances de knowledge_base.pl avec les
%   observables nécessaires aux règles probabilistes.
% ------------------------------------------------------------

% --- Acteurs ---
citoyen(yussef). citoyen(othniel). citoyen(hakim).
citoyen(cedric).  citoyen(christian). citoyen(barkissa).
citoyen(pascal).
agent_public(konan). agent_public(ouedraogo).
promoteur(sawadogo). notaire(zongo).

% --- Possession de parcelles (urbaines / rurales) ---
possede_urbaine(yussef, 5).
possede_urbaine(barkissa, 2).
possede_urbaine(sawadogo, 11).
possede_rurale(hakim, 7).

% --- Liens sociaux ---
partage_telephone(cedric, christian).
partage_adresse(barkissa, hakim).
partage_iban(cedric, christian).
lien_familial(ouedraogo, othniel).
lien_familial(barkissa, yussef).
lien_financier(zongo, sawadogo).

% --- Transactions suspectes ---
revente_rapide(sawadogo, p11).
plus_value_anormale(sawadogo, p11).
sans_mise_en_valeur(sawadogo).
transaction_circulaire(sawadogo, christian, barkissa).

% --- Dossiers ---
traite_dossier_propre(konan).
traite_dossier_familial(ouedraogo, othniel).
dossier_suspect_traite(zongo).
nb_dossiers_familiaux(ouedraogo, 3).

% ------------------------------------------------------------
% SECTION 2 : FAITS PROBABILISTES DE BASE
%   Ces faits expriment l'incertitude inhérente à chaque signal
%   d'alerte observé sur le terrain.
% ------------------------------------------------------------

% Signal : téléphone partagé entre deux acheteurs distincts
0.85::signal_telephone(X, Y) :- partage_telephone(X, Y).

% Signal : adresse partagée entre deux acheteurs distincts
0.80::signal_adresse(X, Y) :- partage_adresse(X, Y).

% Signal : IBAN partagé — signal plus fort (accès financier direct)
0.90::signal_iban(X, Y) :- partage_iban(X, Y).

% Signal : revente rapide sur une parcelle
0.75::signal_revente_rapide(X, P) :- revente_rapide(X, P).

% Signal : plus-value anormale sur une parcelle
0.70::signal_plus_value(X, P) :- plus_value_anormale(X, P).

% Signal : possession sans mise en valeur (promoteur)
0.65::signal_sans_mise_en_valeur(X) :- sans_mise_en_valeur(X).

% Signal : transaction circulaire entre trois acteurs
0.88::signal_circulaire(X, Y, Z) :- transaction_circulaire(X, Y, Z).

% Signal : lien financier notaire-promoteur
0.82::signal_lien_financier(X, Y) :- lien_financier(X, Y).

% Signal : agent traitant son propre dossier
0.95::signal_auto_traitement(X) :- traite_dossier_propre(X).

% Signal : agent traitant le dossier d'un proche
0.90::signal_traitement_familial(X, Y) :- traite_dossier_familial(X, Y).

% Signal : lien familial entre un accapareur et un autre propriétaire
0.72::signal_lien_accapareur(X, Y) :- lien_familial(X, Y), possede_urbaine(Y, N), N >= 4.

% ------------------------------------------------------------
% SECTION 3 : RÈGLES PROBABILISTES COMPOSITES
%   Chaque règle combine plusieurs signaux pour produire un
%   score de suspicion agrégé pour un type de fraude donné.
% ------------------------------------------------------------

% --- R1 : Suspicion de prête-nom par téléphone (AX-05) ---
% P(prête-nom | téléphone partagé) = 0.80
0.80::prete_nom_telephone(X, Y) :-
    signal_telephone(X, Y),
    possede_urbaine(X, _).

% --- R2 : Suspicion de prête-nom par adresse (AX-06) ---
% P(prête-nom | adresse partagée) = 0.75
0.75::prete_nom_adresse(X, Y) :-
    signal_adresse(X, Y),
    possede_urbaine(X, _).

% --- R3 : Prête-nom renforcé — IBAN + téléphone (CI-5 + CI-7) ---
% La conjonction IBAN + téléphone augmente fortement la certitude.
0.93::prete_nom_fort(X, Y) :-
    signal_telephone(X, Y),
    signal_iban(X, Y).

% --- R4 : Spéculateur par revente rapide (AX-07 / CI-4) ---
0.70::speculateur_revente(X) :-
    signal_revente_rapide(X, _).

% --- R5 : Spéculateur confirmé — revente + plus-value (AX-07) ---
% La conjonction des deux signaux renforce la certitude.
0.88::speculateur_confirme(X) :-
    signal_revente_rapide(X, P),
    signal_plus_value(X, P).

% --- R6 : Promoteur spéculateur sans mise en valeur (AX-08) ---
0.65::speculateur_retention(X) :-
    promoteur(X),
    signal_sans_mise_en_valeur(X).

% --- R7 : Blanchiment foncier par réseau circulaire (AX-10 / CI-8) ---
0.88::blanchiment_circulaire(X, Y, Z) :-
    signal_circulaire(X, Y, Z).

% --- R8 : Conflit d'intérêt direct — agent et dossier propre (CI-1) ---
0.95::conflit_direct(X) :-
    signal_auto_traitement(X).

% --- R9 : Conflit d'intérêt familial (AX-04 / CI-9) ---
0.90::conflit_familial(X, Y) :-
    signal_traitement_familial(X, Y).

% --- R10 : Notaire complice (AX-12) ---
0.82::notaire_complice(X) :-
    dossier_suspect_traite(X),
    signal_lien_financier(X, _).

% --- R11 : Concentration familiale (AX-11) ---
% Un citoyen lié à un accapareur et possédant des parcelles.
0.72::concentration_familiale(X) :-
    signal_lien_accapareur(X, _),
    possede_urbaine(X, N), N >= 2.

% --- R12 : Accaparement urbain (AX-01 / CI-2) ---
% Certitude élevée car fondée sur un comptage objectif.
0.92::accaparement_urbain(X) :-
    possede_urbaine(X, N), N >= 4.

% --- R13 : Score composite FRAUDEUR_PROBABLE ---
% Un acteur est classé FRAUDEUR_PROBABLE si au moins deux signaux
% forts indépendants convergent vers lui.
0.91::fraudeur_probable(X) :-
    speculateur_confirme(X),
    accaparement_urbain(X).

0.87::fraudeur_probable(X) :-
    prete_nom_fort(X, _),
    blanchiment_circulaire(_, X, _).

0.89::fraudeur_probable(X) :-
    conflit_direct(X),
    conflit_familial(X, _).

0.85::fraudeur_probable(X) :-
    notaire_complice(X),
    blanchiment_circulaire(_, _, X).
