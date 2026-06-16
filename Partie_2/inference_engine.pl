:- set_prolog_flag(encoding, utf8).
% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : inference_engine.pl
%  Partie 2 — Moteur d'Inférence Symbolique
%
%  Charge la base de connaissances, les règles métier et le
%  module d'explicabilité, puis exécute l'analyse complète
%  sur les 4 catégories (A, B, C, D).
%
%  Utilisation :
%     swipl inference_engine.pl
%     (l'analyse se lance automatiquement via initialization/1)
%
%  Utilisation interactive :
%     ?- run_full_analysis.
%     ?- print_traces.
% ============================================================

:- [knowledge_base].
:- [rules].
:- [explainability].

:- initialization(main, main).

main :-
    set_stream(current_output, encoding(utf8)),
    run_full_analysis,
    nl,
    format("========== JOURNAL D'EXPLICATIONS (XAI) ==========~n~n"),
    print_traces,
    count_traces(Total),
    format("~n>>> Total des alertes journalisees : ~w~n", [Total]),
    format("========== FIN DE L'ANALYSE ==========~n~n").

% ------------------------------------------------------------
% run_full_analysis/0
%   Lance les 4 catégories de règles et affiche un résumé.
% ------------------------------------------------------------
run_full_analysis :-
    reset_traces,
    format("~n========== LANDGUARD — ANALYSE SYMBOLIQUE ==========~n"),
    run_category_a,
    run_category_b,
    run_category_c,
    run_category_d.

% ------------------------------------------------------------
% CATEGORIE A — ACCAPAREMENT
% ------------------------------------------------------------
run_category_a :-
    format("~n--- CATEGORIE A : ACCAPAREMENT ---~n"),
    ( forall(accapareur_urbain(X),
             format("  [A1] ~w -> AccapareurUrbain~n", [X]))
    ; true ),
    ( forall(accapareur_rural(X),
             format("  [A2] ~w -> AccapareurRural~n", [X]))
    ; true ),
    ( forall(concentration_familiale(X),
             format("  [A3] ~w -> ReseauFrauduleux (concentration familiale)~n", [X]))
    ; true ),
    ( forall(promoteur_accapareur(X),
             format("  [A4] ~w -> ALERTE_ACCAPAREMENT (promoteur)~n", [X]))
    ; true ).

% ------------------------------------------------------------
% CATEGORIE B — SPECULATION
% ------------------------------------------------------------
run_category_b :-
    format("~n--- CATEGORIE B : SPECULATION ---~n"),
    ( forall(revente_rapide(X, P),
             format("  [B1] ~w / ~w -> ALERTE_SPECULATION (revente rapide)~n", [X, P]))
    ; true ),
    ( forall(plus_value_anormale(P),
             format("  [B2] ~w -> plus-value anormale~n", [P]))
    ; true ),
    ( forall(speculateur_revente(X),
             format("  [B3] ~w -> Speculateur (revente)~n", [X]))
    ; true ),
    ( forall(promoteur_sans_mise_en_valeur(X, P),
             format("  [B4] ~w / ~w -> Speculateur (sans mise en valeur)~n", [X, P]))
    ; true ).

% ------------------------------------------------------------
% CATEGORIE C — CONFLITS D'INTERETS
% ------------------------------------------------------------
run_category_c :-
    format("~n--- CATEGORIE C : CONFLITS D'INTERETS ---~n"),
    ( forall(conflit_interet_direct(X),
             format("  [C1] ~w -> ConflitInteret (direct)~n", [X]))
    ; true ),
    ( forall(conflit_interet_familial(X),
             format("  [C2] ~w -> ConflitInteret (familial)~n", [X]))
    ; true ),
    ( forall(auto_attribution(X),
             format("  [C3] ~w -> VIOLATION CI-1 (auto-attribution)~n", [X]))
    ; true ),
    ( forall(favoritisme_repetitif(X),
             format("  [C4] ~w -> AgentFavoritiste~n", [X]))
    ; true ).

% ------------------------------------------------------------
% CATEGORIE D — RESEAUX & PRETE-NOMS
% ------------------------------------------------------------
run_category_d :-
    format("~n--- CATEGORIE D : RESEAUX & PRETE-NOMS ---~n"),
    ( forall(prete_nom_telephone(X, Y),
             format("  [D1] ~w <-> ~w -> PretaNomSuspect (téléphone)~n", [X, Y]))
    ; true ),
    ( forall(prete_nom_adresse(X, Y),
             format("  [D2] ~w <-> ~w -> PretaNomSuspect (adresse)~n", [X, Y]))
    ; true ),
    ( forall(prete_nom_iban(X, Y),
             format("  [D3] ~w <-> ~w -> FRAUDE_PROBABLE (IBAN)~n", [X, Y]))
    ; true ),
    ( forall(reseau_circulaire(X, Y, Z),
             format("  [D4] ~w -> ~w -> ~w -> ~w -> ReseauFrauduleux (circulaire)~n", [X, Y, Z, X]))
    ; true ),
    ( forall(notaire_complice(X),
             format("  [D5] ~w -> ConflitInteret (notaire complice)~n", [X]))
    ; true ).
