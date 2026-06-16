% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : deepproblog_model.pl
%  Partie 4 — Intégration Hybride DeepProbLog
%
%  Ce fichier fusionne les prédictions du réseau neuronal
%  PyTorch (neural_model.py) avec le raisonnement logique
%  formel défini dans les Parties 1-3.
%
%  Fonctionnement :
%    1. Le prédicat neuronal nn/4 délègue la classification
%       au modèle PyTorch chargé (model_weights.pth).
%    2. Les règles hybrides combinent neural_class/2 avec
%       les prédicats symboliques (accaparement, réseau, etc.)
%    3. Le résultat final est une décision explicable avec
%       trace logique complète.
%
%  Utilisation (Python) :
%    from deepproblog.model import Model
%    model = Model('deepproblog_model.pl', [fraud_network])
% ============================================================

% ------------------------------------------------------------
% SECTION 1 : PRÉDICAT NEURONAL
%   nn(nom_reseau, [tenseur_input], Classe, [liste_classes])
%   Délègue l'inférence au modèle PyTorch enregistré.
% ------------------------------------------------------------

nn(fraud_model, [X], Classe,
   [standard, atypique, speculateur, fraudeur_probable]).

% ------------------------------------------------------------
% SECTION 2 : FAITS SYMBOLIQUES
%   Reprend les faits terrain de knowledge_base.pl utilisés
%   pour les règles hybrides.
% ------------------------------------------------------------

citoyen(yussef). citoyen(othniel). citoyen(hakim).
citoyen(cedric).  citoyen(christian). citoyen(barkissa).
citoyen(pascal).
agent_public(konan). agent_public(ouedraogo).
promoteur(sawadogo). notaire(zongo).

% Possession (nombre de parcelles)
nb_parcelles_urbaines(yussef,   5).
nb_parcelles_urbaines(barkissa, 2).
nb_parcelles_urbaines(sawadogo, 11).
nb_parcelles_rurales(hakim, 7).

% Signaux binaires terrain
partage_telephone(cedric, christian).
partage_adresse(barkissa, hakim).
partage_iban(cedric, christian).
lien_familial(barkissa, yussef).
lien_familial(ouedraogo, othniel).
lien_financier(zongo, sawadogo).
revente_rapide(sawadogo).
plus_value_anormale(sawadogo).
sans_mise_en_valeur(sawadogo).
ventes_circulaires(sawadogo, christian, barkissa).
traite_dossier_propre(konan).
traite_dossier_proche(ouedraogo, othniel).
dossier_suspect_traite(zongo).

% ------------------------------------------------------------
% SECTION 3 : PRÉDICATS SYMBOLIQUES DÉRIVÉS
%   Reprennent les règles de rules.pl sous forme compacte
%   pour être appelés depuis les règles hybrides.
% ------------------------------------------------------------

% Accaparement urbain : >= 4 parcelles urbaines (CI-2)
accaparement_urbain(X) :-
    nb_parcelles_urbaines(X, N), N >= 4.

% Accaparement rural : >= 6 parcelles rurales
accaparement_rural(X) :-
    nb_parcelles_rurales(X, N), N >= 6.

% Conflit d'interet direct : agent traite son propre dossier
conflit_direct(X) :-
    agent_public(X), traite_dossier_propre(X).

% Conflit d'interet familial
conflit_familial(X) :-
    agent_public(X), traite_dossier_proche(X, _).

% Reseau de prete-noms (telephone ou adresse ou IBAN partages)
reseau_prete_nom(X) :-
    partage_telephone(X, _) ; partage_telephone(_, X) ;
    partage_adresse(X, _)   ; partage_adresse(_, X)   ;
    partage_iban(X, _)      ; partage_iban(_, X).

% Speculateur symbolique (revente rapide + plus-value)
speculateur_symbolique(X) :-
    revente_rapide(X), plus_value_anormale(X).

% Reseau circulaire de transactions
blanchiment(X) :-
    ventes_circulaires(X, _, _) ;
    ventes_circulaires(_, X, _) ;
    ventes_circulaires(_, _, X).

% Notaire complice
notaire_complice(X) :-
    notaire(X), dossier_suspect_traite(X), lien_financier(X, _).

% ------------------------------------------------------------
% SECTION 4 : RÈGLES HYBRIDES NEURO-SYMBOLIQUES
%   Chaque règle combine une prédiction neuronale ET au moins
%   une contrainte symbolique pour produire une décision finale.
%   C'est le coeur de l'approche DeepProbLog.
% ------------------------------------------------------------

% ── H1 : Fraude confirmée — FRAUDEUR_PROBABLE neural + accaparement ──
% La vision neuronale classe l'acteur comme FRAUDEUR + le raisonnement
% symbolique confirme un accaparement urbain réel.
fraude_confirmee(X) :-
    neural_class(X, fraudeur_probable),
    accaparement_urbain(X).

% ── H2 : Fraude confirmée — FRAUDEUR_PROBABLE neural + blanchiment ──
fraude_confirmee(X) :-
    neural_class(X, fraudeur_probable),
    blanchiment(X).

% ── H3 : Spéculateur hybride — SPECULATEUR neural + validation symbolique ──
speculateur_hybride(X) :-
    neural_class(X, speculateur),
    speculateur_symbolique(X).

% ── H4 : Spéculateur hybride — SPECULATEUR neural + sans mise en valeur ──
speculateur_hybride(X) :-
    neural_class(X, speculateur),
    promoteur(X),
    sans_mise_en_valeur(X).

% ── H5 : Prête-nom hybride — ATYPIQUE neural + signal réseau ──
% Le modèle neural détecte un profil atypique, confirmé par
% un signal de réseau de prête-noms.
prete_nom_hybride(X) :-
    neural_class(X, atypique),
    reseau_prete_nom(X).

% ── H6 : Prête-nom hybride — FRAUDEUR_PROBABLE neural + réseau ──
prete_nom_hybride(X) :-
    neural_class(X, fraudeur_probable),
    reseau_prete_nom(X).

% ── H7 : Conflit hybride — profil neural quelconque + conflit symbolique ──
% Le conflit d'intérêt est une violation formelle indépendante du profil.
conflit_hybride(X) :-
    conflit_direct(X).

conflit_hybride(X) :-
    conflit_familial(X),
    neural_class(X, atypique).

% ── H8 : Complicité notariale hybride ──
% La complicité est renforcée si le modèle classifie le notaire
% comme atypique ou fraudeur.
complicite_hybride(X) :-
    notaire_complice(X),
    ( neural_class(X, atypique) ; neural_class(X, fraudeur_probable) ).

% ── H9 : Concentration familiale hybride ──
% Un acteur lié à un accapareur, classé atypique par le modèle.
concentration_hybride(X) :-
    lien_familial(X, Y),
    accaparement_urbain(Y),
    neural_class(X, atypique).

% ── H10 : Décision finale de classification ──
% Agrège toutes les règles hybrides en un verdict unique par acteur.
verdict(X, fraude_composite) :-
    fraude_confirmee(X).

verdict(X, speculation_confirmee) :-
    \+ fraude_confirmee(X),
    speculateur_hybride(X).

verdict(X, prete_nom_confirme) :-
    \+ fraude_confirmee(X),
    \+ speculateur_hybride(X),
    prete_nom_hybride(X).

verdict(X, conflit_interet) :-
    \+ fraude_confirmee(X),
    \+ speculateur_hybride(X),
    \+ prete_nom_hybride(X),
    conflit_hybride(X).

verdict(X, complicite) :-
    \+ fraude_confirmee(X),
    \+ speculateur_hybride(X),
    \+ prete_nom_hybride(X),
    \+ conflit_hybride(X),
    complicite_hybride(X).

verdict(X, standard) :-
    \+ fraude_confirmee(X),
    \+ speculateur_hybride(X),
    \+ prete_nom_hybride(X),
    \+ conflit_hybride(X),
    \+ complicite_hybride(X).

% ------------------------------------------------------------
% SECTION 5 : PRÉDICAT NEURONAL SIMULÉ (mode sans DeepProbLog)
%   Utilisé quand on appelle ce fichier directement depuis SWI-Prolog
%   sans le bridge DeepProbLog. Charge les prédictions depuis le
%   fichier neural_predictions.pl généré par neural_model.py.
% ------------------------------------------------------------

:- (exists_file('neural_predictions.pl')
   -> consult('neural_predictions.pl')
   ;  true).
