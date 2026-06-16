:- set_prolog_flag(encoding, utf8).
% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : rules.pl
%  Partie 2 — Raisonnement Symbolique avec Prolog
%
%  17 règles métier réparties en 4 catégories :
%     A. Accaparement              (4 règles : A1-A4)
%     B. Spéculation                (4 règles : B1-B4)
%     C. Conflits d'intérêts        (4 règles : C1-C4)
%     D. Réseaux & Prête-noms       (5 règles : D1-D5)
%
%  Chaque règle, en se déclenchant, journalise une explication
%  via log_violation/3 (cf. explainability.pl) en référençant
%  l'axiome DL et/ou la contrainte d'intégrité correspondants.
% ============================================================

% ============================================================
% CATÉGORIE A — ACCAPAREMENT
% ============================================================

% --- A1 : Accaparement urbain (AX-01 / CI-2) ---------------
% Un citoyen possédant >= 4 parcelles urbaines est un AccapareurUrbain.
accapareur_urbain(X) :-
    citoyen(X),
    findall(P, (possede(X,P), parcelle_urbaine(P)), L),
    length(L, N),
    N >= 4,
    format(atom(Motif),
           "Le citoyen ~w possede ~w parcelles urbaines (seuil CI-2 = 4) : classification AccapareurUrbain selon l'axiome AX-01.",
           [X, N]),
    log_violation(rule_a1_accapareur_urbain, [acteur=X, nb_parcelles_urbaines=N], Motif).

% --- A2 : Accaparement rural (AX-02) -----------------------
% Un citoyen possédant >= 6 parcelles rurales est un AccapareurRural.
accapareur_rural(X) :-
    citoyen(X),
    findall(P, (possede(X,P), parcelle_rurale(P)), L),
    length(L, N),
    N >= 6,
    format(atom(Motif),
           "Le citoyen ~w possede ~w parcelles rurales (seuil = 6) : classification AccapareurRural selon l'axiome AX-02.",
           [X, N]),
    log_violation(rule_a2_accapareur_rural, [acteur=X, nb_parcelles_rurales=N], Motif).

% --- A3 : Concentration familiale (AX-11) ------------------
% Un citoyen lie familialement à un AccapareurUrbain et possédant
% lui-meme >= 2 parcelles urbaines participe à un ReseauFrauduleux.
concentration_familiale(X) :-
    citoyen(X),
    lien_familial(X, Y),
    accapareur_urbain(Y),
    findall(P, (possede(X,P), parcelle_urbaine(P)), L),
    length(L, N),
    N >= 2,
    format(atom(Motif),
           "~w est lie familialement à ~w (classe AccapareurUrbain) et possede ~w parcelles urbaines : ReseauFrauduleux selon l'axiome AX-11.",
           [X, Y, N]),
    log_violation(rule_a3_concentration_familiale, [acteur=X, lien_familial_avec=Y, nb_parcelles_urbaines=N], Motif).

% --- A4 : Accaparement par un promoteur (CI-10) ------------
% Un promoteur détenant >= 10 parcelles sans projet declare
% déclenche une ALERTE_ACCAPAREMENT.
promoteur_accapareur(X) :-
    promoteur(X),
    findall(P, possede(X,P), L),
    length(L, N),
    N >= 10,
    \+ projet_declare(X),
    format(atom(Motif),
           "Le promoteur ~w detient ~w parcelles (seuil = 10) sans projet declare : ALERTE_ACCAPAREMENT selon la contrainte CI-10.",
           [X, N]),
    log_violation(rule_a4_promoteur_accapareur, [acteur=X, nb_parcelles=N], Motif).


% ============================================================
% CATÉGORIE B — SPÉCULATION
% ============================================================

% --- B1 : Revente rapide (CI-4) ----------------------------
% Une parcelle revendue moins de 6 mois apres son acquisition
% déclenche une ALERTE_SPECULATION.
revente_rapide(X, P) :-
    possede_historique(X, P, DateAcquisition, DateRevente),
    Delai is DateRevente - DateAcquisition,
    Delai >= 0,
    Delai < 6,
    format(atom(Motif),
           "~w a revendu la parcelle ~w apres ~w mois (seuil = 6 mois) : ALERTE_SPECULATION selon la contrainte CI-4.",
           [X, P, Delai]),
    log_violation(rule_b1_revente_rapide, [acteur=X, parcelle=P, delai_mois=Delai], Motif).

% --- B2 : Plus-value anormale ------------------------------
% Une plus-value supérieure à 50% du prix d'achat est jugee anormale.
plus_value_anormale(P) :-
    prix_achat(P, PA),
    prix_vente(P, PV),
    PV > PA * 1.5,
    Ratio is PV / PA,
    format(atom(Motif),
           "La parcelle ~w a ete revendue avec un ratio prix_vente/prix_achat de ~2f (seuil = 1.5) : plus-value jugee anormale.",
           [P, Ratio]),
    log_violation(rule_b2_plus_value_anormale, [parcelle=P, prix_achat=PA, prix_vente=PV], Motif).

% --- B3 : Spéculateur par revente (AX-07) ------------------
% Un acteur dont une parcelle a ete revendue rapidement avec une
% plus-value anormale est classe Speculateur.
speculateur_revente(X) :-
    possede_historique(X, P, _, _),
    once(revente_rapide(X, P)),
    once(plus_value_anormale(P)),
    format(atom(Motif),
           "~w a realise une revente rapide ET une plus-value anormale sur la parcelle ~w : classification Speculateur selon l'axiome AX-07.",
           [X, P]),
    log_violation(rule_b3_speculateur_revente, [acteur=X, parcelle=P], Motif).

% --- B4 : Promoteur sans mise en valeur (AX-08) ------------
% Un promoteur possédant une parcelle urbaine non mise en valeur
% est suspecté de rétention spéculative.
promoteur_sans_mise_en_valeur(X, P) :-
    promoteur(X),
    possede(X, P),
    parcelle_urbaine(P),
    \+ mise_en_valeur(P),
    format(atom(Motif),
           "Le promoteur ~w detient la parcelle urbaine ~w sans mise en valeur : classification Speculateur selon l'axiome AX-08.",
           [X, P]),
    log_violation(rule_b4_promoteur_sans_mise_en_valeur, [acteur=X, parcelle=P], Motif).


% ============================================================
% CATÉGORIE C — CONFLITS D'INTÉRÊTS
% ============================================================

% --- C1 : Conflit d'intérêt direct (AX-03) -----------------
% Un agent public qui traite un dossier ET est beneficiaire d'une
% affectation est en conflit d'intérêt direct.
conflit_interet_direct(X) :-
    agent_public(X),
    traite(X, D),
    beneficiaire(X, Aff),
    format(atom(Motif),
           "L'agent public ~w traite le dossier ~w et est beneficiaire de l'affectation ~w : ConflitInteret (direct) selon l'axiome AX-03.",
           [X, D, Aff]),
    log_violation(rule_c1_conflit_interet_direct, [agent=X, dossier=D, affectation=Aff], Motif).

% --- C2 : Conflit d'intérêt familial (AX-04) ---------------
% Un agent public qui traite un dossier alors qu'un membre de sa
% famille est beneficiaire d'une affectation est en conflit indirect.
conflit_interet_familial(X) :-
    agent_public(X),
    traite(X, D),
    lien_familial(X, Y),
    beneficiaire(Y, Aff),
    format(atom(Motif),
           "L'agent public ~w traite le dossier ~w alors que son proche ~w est beneficiaire de l'affectation ~w : ConflitInteret (familial) selon l'axiome AX-04.",
           [X, D, Y, Aff]),
    log_violation(rule_c2_conflit_interet_familial, [agent=X, dossier=D, proche=Y, affectation=Aff], Motif).

% --- C3 : Auto-attribution (CI-1) --------------------------
% Un agent public ne peut pas traiter un dossier dont il est lui-meme
% le propriétaire/déposant.
auto_attribution(X) :-
    agent_public(X),
    traite(X, D),
    dossier_proprietaire(D, X),
    format(atom(Motif),
           "L'agent public ~w traite le dossier ~w dont il est lui-meme le propriétaire : VIOLATION de la contrainte CI-1 (auto-attribution interdite).",
           [X, D]),
    log_violation(rule_c3_auto_attribution, [agent=X, dossier=D], Motif).

% --- C4 : Favoritisme repetitif (AX-09) --------------------
% Un agent public ayant traite >= 3 dossiers familiaux est qualifié
% d'AgentFavoritiste.
favoritisme_repetitif(X) :-
    agent_public(X),
    findall(D, (traite(X, D), dossier_familial(X, D)), L),
    length(L, N),
    N >= 3,
    format(atom(Motif),
           "L'agent public ~w a traite ~w dossiers concernant des proches (seuil = 3) : classification AgentFavoritiste selon l'axiome AX-09.",
           [X, N]),
    log_violation(rule_c4_favoritisme_repetitif, [agent=X, nb_dossiers_familiaux=N], Motif).


% ============================================================
% CATÉGORIE D — RÉSEAUX & PRÊTE-NOMS
% ============================================================

% --- D1 : Prête-nom par telephone partagé (AX-05 / CI-5) ---
% Deux citoyens distincts partageant un telephone et possédant
% chacun au moins une parcelle sont suspects de prête-nom.
% On canonise (X @< Y) pour éviter les doublons (X,Y) et (Y,X).
prete_nom_telephone(X, Y) :-
    citoyen(X), citoyen(Y), X @< Y,
    ( partage_telephone(X, Y) ; partage_telephone(Y, X) ),
    once(possede(X, _)), once(possede(Y, _)),
    format(atom(Motif),
           "~w et ~w partagent le meme numero de telephone et possedent chacun une parcelle : PretaNomSuspect selon l'axiome AX-05 / CI-5.",
           [X, Y]),
    log_violation(rule_d1_prete_nom_telephone, [acteur1=X, acteur2=Y], Motif).

% --- D2 : Prête-nom par adresse partagée (AX-06 / CI-6) ----
% Idem, canonisé avec X @< Y et once/1 pour éviter les doublons.
prete_nom_adresse(X, Y) :-
    citoyen(X), citoyen(Y), X @< Y,
    ( partage_adresse(X, Y) ; partage_adresse(Y, X) ),
    once(possede(X, _)), once(possede(Y, _)),
    format(atom(Motif),
           "~w et ~w partagent la meme adresse et possedent chacun une parcelle : PretaNomSuspect selon l'axiome AX-06 / CI-6.",
           [X, Y]),
    log_violation(rule_d2_prete_nom_adresse, [acteur1=X, acteur2=Y], Motif).

% --- D3 : Compte IBAN partagé (CI-7) -----------------------
prete_nom_iban(X, Y) :-
    ( partage_iban(X, Y), X @< Y ; partage_iban(Y, X), X @< Y ),
    once(possede(X, _)), once(possede(Y, _)),
    format(atom(Motif),
           "~w et ~w partagent le meme compte IBAN et possedent chacun une parcelle : FRAUDE_PROBABLE selon la contrainte CI-7.",
           [X, Y]),
    log_violation(rule_d3_prete_nom_iban, [acteur1=X, acteur2=Y], Motif).

% --- D4 : Réseau circulaire de transactions (AX-10 / CI-8) -
% Une chaîne de ventes X -> Y -> Z -> X constitue un reseau
% frauduleux (blanchiment foncier potentiel).
reseau_circulaire(X, Y, Z) :-
    vend_a(X, Y),
    vend_a(Y, Z),
    vend_a(Z, X),
    X \= Y, Y \= Z, X \= Z,
    format(atom(Motif),
           "Chaine de ventes circulaire detectee : ~w -> ~w -> ~w -> ~w : ReseauFrauduleux (BLANCHIMENT_FONCIER) selon l'axiome AX-10 / CI-8.",
           [X, Y, Z, X]),
    log_violation(rule_d4_reseau_circulaire, [acteur1=X, acteur2=Y, acteur3=Z], Motif).

% --- D5 : Notaire complice (AX-12) -------------------------
% Un notaire traitant un dossier suspect tout en ayant un lien
% financier avec un promoteur est en ConflitInteret.
notaire_complice(X) :-
    notaire(X),
    traite(X, D),
    dossier_suspect(D),
    lien_financier(X, Y),
    promoteur(Y),
    format(atom(Motif),
           "Le notaire ~w traite le dossier suspect ~w tout en ayant un lien financier avec le promoteur ~w : ConflitInteret selon l'axiome AX-12.",
           [X, D, Y]),
    log_violation(rule_d5_notaire_complice, [notaire=X, dossier=D, promoteur=Y], Motif).
