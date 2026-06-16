:- set_prolog_flag(encoding, utf8).
% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : knowledge_base.pl
%  Partie 1 — Logique de Description : Base de Connaissances
%  Déclarations des concepts, rôles et contraintes d'intégrité
% ============================================================

% ------------------------------------------------------------
% SECTION 1 : TAXONOMIE DES CONCEPTS (TBox — Terminologie)
% ------------------------------------------------------------
% Hiérarchie : Acteur
concept(acteur).
concept(citoyen).
concept(agent_public).
concept(promoteur).
concept(notaire).

sous_concept(citoyen,      acteur).
sous_concept(agent_public, acteur).
sous_concept(promoteur,    acteur).
sous_concept(notaire,      acteur).

% Hiérarchie : Parcelle
concept(parcelle).
concept(parcelle_urbaine).
concept(parcelle_rurale).

sous_concept(parcelle_urbaine, parcelle).
sous_concept(parcelle_rurale,  parcelle).

% Hiérarchie : Affectation
concept(affectation).
concept(attribution).
concept(revente).
concept(heritage).

sous_concept(attribution, affectation).
sous_concept(revente,     affectation).
sous_concept(heritage,    affectation).

% Hiérarchie : Dossier
concept(dossier).
concept(dossier_actif).
concept(dossier_suspect).

sous_concept(dossier_actif,   dossier).
sous_concept(dossier_suspect, dossier).

% Hiérarchie : Lien Social
concept(lien_social).
concept(lien_familial).
concept(lien_professionnel).
concept(lien_financier).

sous_concept(lien_familial,      lien_social).
sous_concept(lien_professionnel, lien_social).
sous_concept(lien_financier,     lien_social).

% Concepts dérivés (issus des axiomes DL)
concept(accapareur_urbain).
concept(accapareur_rural).
concept(conflit_interet).
concept(prete_nom_suspect).
concept(speculateur).
concept(agent_favoritiste).
concept(reseau_frauduleux).

% ------------------------------------------------------------
% SECTION 2 : DÉCLARATION DES RÔLES (Relations binaires)
% ------------------------------------------------------------
role(possede,           acteur,    parcelle).
role(traite,            acteur,    dossier).
role(beneficiaire,      acteur,    affectation).
role(lien_familial_r,   acteur,    acteur).
role(vend_a,            acteur,    acteur).
role(partage_telephone, acteur,    acteur).
role(partage_adresse,   acteur,    acteur).
role(partage_iban,      acteur,    acteur).
role(instruit_par,      dossier,   acteur).
role(concerne,          dossier,   parcelle).

% ------------------------------------------------------------
% SECTION 3 : AXIOMES DE LOGIQUE DE DESCRIPTION (TBox)
%
%  Notation utilisée :
%    dl_axiome(ID, Description, Formule_textuelle).
%  Les règles Prolog correspondantes sont dans rules.pl
% ------------------------------------------------------------

dl_axiome(ax01,
    'Accaparement urbain',
    'Citoyen ⊓ (≥4 possede.ParcelleUrbaine) ⊑ AccapareurUrbain').

dl_axiome(ax02,
    'Accaparement rural',
    'Citoyen ⊓ (≥6 possede.ParcelleRurale) ⊑ AccapareurRural').

dl_axiome(ax03,
    'Conflit d_interet direct',
    'AgentPublic ⊓ ∃traite.Dossier ⊓ ∃beneficiaire.Affectation ⊑ ConflitInteret').

dl_axiome(ax04,
    'Conflit d_interet familial',
    'AgentPublic ⊓ ∃traite.Dossier ⊓ ∃lienFamilial.(∃beneficiaire.Affectation) ⊑ ConflitInteret').

dl_axiome(ax05,
    'Suspect prete-nom par telephone partage',
    'Citoyen ⊓ ∃partageTelephone.Citoyen ⊓ ∃possede.Parcelle ⊑ PretaNomSuspect').

dl_axiome(ax06,
    'Suspect prete-nom par adresse partagee',
    'Citoyen ⊓ ∃partageAdresse.Citoyen ⊓ ∃possede.Parcelle ⊑ PretaNomSuspect').

dl_axiome(ax07,
    'Speculateur foncier',
    'Acteur ⊓ ∃vendA.(∃possede.Parcelle) ⊓ ReventeRapide ⊑ Speculateur').

dl_axiome(ax08,
    'Promoteur sans mise en valeur',
    'Promoteur ⊓ ∃possede.Parcelle ⊓ ¬MiseEnValeur ⊑ Speculateur').

dl_axiome(ax09,
    'Agent favoritiste repetitif',
    'AgentPublic ⊓ (≥3 traite.DossierFamilial) ⊑ AgentFavoritiste').

dl_axiome(ax10,
    'Reseau frauduleux circulaire',
    'Acteur ⊓ ∃vendA.(∃vendA.(∃vendA.Self)) ⊑ ReseauFrauduleux').

dl_axiome(ax11,
    'Concentration familiale de parcelles',
    'Citoyen ⊓ ∃lienFamilial.(AccapareurUrbain) ⊓ (≥2 possede.ParcelleUrbaine) ⊑ ReseauFrauduleux').

dl_axiome(ax12,
    'Notaire complice',
    'Notaire ⊓ ∃traite.DossierSuspect ⊓ ∃lienFinancier.Promoteur ⊑ ConflitInteret').

% ------------------------------------------------------------
% SECTION 4 : CONTRAINTES D'INTÉGRITÉ (CI)
%
%  Déclarées ici comme métadonnées.
%  L'enforcement est dans inference_engine.pl
% ------------------------------------------------------------

contrainte(ci1,
    'Un agent public ne peut pas traiter son propre dossier',
    'Pour tout x : AgentPublic(x) ⊓ DossierPropre(x) → VIOLATION').

contrainte(ci2,
    'Maximum 3 parcelles urbaines par citoyen simple',
    'Pour tout x : Citoyen(x) ⊓ (≥4 possede.ParcelleUrbaine)(x) → VIOLATION').

contrainte(ci3,
    'Un notaire ne peut pas etre beneficiaire dans un dossier qu_il instruit',
    'Pour tout x : Notaire(x) ⊓ ∃instruit.Dossier(x) ⊓ ∃beneficiaire.Affectation(x) → VIOLATION').

contrainte(ci4,
    'Revente dans les 6 mois apres acquisition interdite sans justification',
    'Pour tout x,p : possede(x,p) ⊓ ReventeRapide(x,p,6mois) → ALERTE_SPECULATION').

contrainte(ci5,
    'Meme telephone entre deux acheteurs distincts = suspicion prete-nom',
    'Pour tout x,y : x≠y ⊓ partageTelephone(x,y) ⊓ ∃possede.Parcelle(x) ⊓ ∃possede.Parcelle(y) → SUSPICION_PRETE_NOM').

contrainte(ci6,
    'Meme adresse entre deux acheteurs distincts = suspicion prete-nom',
    'Pour tout x,y : x≠y ⊓ partageAdresse(x,y) ⊓ ∃possede.Parcelle(x) ⊓ ∃possede.Parcelle(y) → SUSPICION_PRETE_NOM').

contrainte(ci7,
    'Meme IBAN entre deux acheteurs = fraude probable',
    'Pour tout x,y : x≠y ⊓ partageIBAN(x,y) ⊓ ∃possede.Parcelle(x) ⊓ ∃possede.Parcelle(y) → FRAUDE_PROBABLE').

contrainte(ci8,
    'Transaction circulaire entre 3 acteurs ou plus = blanchiment foncier',
    'Pour tout x,y,z : vendA(x,y) ⊓ vendA(y,z) ⊓ vendA(z,x) → BLANCHIMENT_FONCIER').

contrainte(ci9,
    'Un agent public ne peut pas traiter le dossier d_un membre de sa famille',
    'Pour tout x,y : AgentPublic(x) ⊓ lienFamilial(x,y) ⊓ traite(x, Dossier_de_y) → VIOLATION').

contrainte(ci10,
    'Promoteur ne peut detenir plus de 10 parcelles sans justification de projet',
    'Pour tout x : Promoteur(x) ⊓ (≥10 possede.Parcelle)(x) ⊓ ¬ProjetDeclare(x) → ALERTE_ACCAPAREMENT').

% ------------------------------------------------------------
% SECTION 5 : PRÉDICATS UTILITAIRES (héritage de concepts)
% ------------------------------------------------------------

% Vérifier si X est une instance d'un concept (avec héritage)
est_un(X, Concept) :-
    call(Concept, X).
est_un(X, Concept) :-
    sous_concept(SousConcept, Concept),
    call(SousConcept, X).

% Lister tous les axiomes du domaine
lister_axiomes :-
    forall(dl_axiome(ID, Desc, _),
           format("  [~w] ~w~n", [ID, Desc])).

% Lister toutes les contraintes
lister_contraintes :-
    forall(contrainte(ID, Desc, _),
           format("  [~w] ~w~n", [ID, Desc])).

% ------------------------------------------------------------
% SECTION 6 : BASE DE FAITS (ABox) — Instances du domaine
%
%   Jeu de données de démonstration (10 acteurs) couvrant
%   chaque catégorie de règles de la Partie 2 :
%     - Cas 1 (yussef)          : Accaparement urbain (Cat. A)
%     - Cas 2 (othniel)          : Profil standard
%     - Cas 3 (hakim)         : Accaparement rural (Cat. A)
%     - Cas 4 (cedric, christian)    : Prête-noms tél./IBAN (Cat. D)
%     - Cas 5 (barkissa)           : Prête-nom adresse + concentration familiale (Cat. A/D)
%     - Cas 6 (sawadogo)         : Spéculation + accaparement promoteur (Cat. A/B)
%     - Cas 7 (konan)         : Conflit d'intérêt direct + auto-attribution (Cat. C)
%     - Cas 8 (ouedraogo)         : Conflit d'intérêt familial + favoritisme (Cat. C)
%     - Cas 9 (sawadogo/christian/barkissa) : Réseau circulaire (Cat. D)
%     - Cas 10 (zongo)       : Notaire complice (Cat. D)
% ------------------------------------------------------------

:- dynamic(projet_declare/1).
:- dynamic(dossier_familial/2).

% --- Acteurs ---
citoyen(yussef).
citoyen(othniel).
citoyen(hakim).
citoyen(cedric).
citoyen(christian).
citoyen(barkissa).
citoyen(pascal).

agent_public(konan).
agent_public(ouedraogo).

promoteur(sawadogo).

notaire(zongo).

% --- Parcelles Urbaines ---
parcelle_urbaine(p1).  parcelle_urbaine(p2).  parcelle_urbaine(p3).
parcelle_urbaine(p4).  parcelle_urbaine(p5).  parcelle_urbaine(p6).
parcelle_urbaine(p7).  parcelle_urbaine(p8).  parcelle_urbaine(p9).
parcelle_urbaine(p10). parcelle_urbaine(p11). parcelle_urbaine(p12).
parcelle_urbaine(p13). parcelle_urbaine(p14). parcelle_urbaine(p15).
parcelle_urbaine(p16). parcelle_urbaine(p17). parcelle_urbaine(p18).
parcelle_urbaine(p19). parcelle_urbaine(p20). parcelle_urbaine(p21).

% --- Parcelles Rurales ---
parcelle_rurale(r1). parcelle_rurale(r2). parcelle_rurale(r3). parcelle_rurale(r4).
parcelle_rurale(r5). parcelle_rurale(r6). parcelle_rurale(r7). parcelle_rurale(r8).

% --- Cas 1 : yussef — accaparement urbain (5 parcelles, seuil = 4) ---
possede(yussef,p1). possede(yussef,p2). possede(yussef,p3).
possede(yussef,p4). possede(yussef,p5).

% --- Cas 2 : othniel — profil standard (1 parcelle, mise en valeur) ---
possede(othniel,p6).
mise_en_valeur(p6).
mise_en_valeur(p1).
mise_en_valeur(p2).

% --- Cas 3 : hakim — accaparement rural (7 parcelles, seuil = 6) ---
possede(hakim,r1). possede(hakim,r2). possede(hakim,r3).
possede(hakim,r4). possede(hakim,r5). possede(hakim,r6). possede(hakim,r7).

% --- Cas 4 : cedric & christian — réseau de prête-noms (téléphone + IBAN) ---
possede(cedric,p7).
possede(christian,p8).
partage_telephone(cedric,christian).
partage_iban(cedric,christian).

% --- Cas 5 : barkissa — prête-nom par adresse + concentration familiale ---
possede(barkissa,r8).
possede(barkissa,p12).
possede(barkissa,p13).
partage_adresse(barkissa,hakim).
lien_familial(barkissa,yussef).

% --- Cas 6 : sawadogo (promoteur) — spéculation + accaparement (11 parcelles) ---
possede(sawadogo,p9).  possede(sawadogo,p10). possede(sawadogo,p11).
possede(sawadogo,p14). possede(sawadogo,p15). possede(sawadogo,p16).
possede(sawadogo,p17). possede(sawadogo,p18). possede(sawadogo,p19).
possede(sawadogo,p20). possede(sawadogo,p21).
% Aucune mise_en_valeur déclarée pour ces parcelles -> spéculation/accaparement

% Revente rapide + plus-value anormale sur p11
possede_historique(sawadogo,p11,1,4).   % acquis mois 1, revendu mois 4 (délai = 3 < 6)
prix_achat(p11,5000000).
prix_vente(p11,9000000).              % PV(9M) > 1.5 x PA(5M) = 7.5M

% --- Cas 7 : konan (agent public) — conflit direct + auto-attribution ---
dossier(d1).
dossier_suspect(d1).
traite(konan,d1).
affectation(aff1).
attribution(aff1).
beneficiaire(konan,aff1).
concerne(d1,p9).

dossier(d6).
traite(konan,d6).
dossier_proprietaire(d6,konan).

% --- Cas 8 : ouedraogo (agent public) — conflit familial + favoritisme répétitif ---
dossier(d2). dossier(d3). dossier(d4). dossier(d5).
lien_familial(ouedraogo,othniel).
lien_familial(ouedraogo,pascal).
traite(ouedraogo,d2). traite(ouedraogo,d3). traite(ouedraogo,d4). traite(ouedraogo,d5).
affectation(aff2).
attribution(aff2).
beneficiaire(othniel,aff2).
dossier_familial(ouedraogo,d2).
dossier_familial(ouedraogo,d3).
dossier_familial(ouedraogo,d4).

% --- Cas 9 : réseau circulaire de transactions ---
vend_a(sawadogo,christian).
vend_a(christian,barkissa).
vend_a(barkissa,sawadogo).

% --- Cas 10 : zongo (notaire) — complicité avec un promoteur ---
dossier(d7).
dossier_suspect(d7).
traite(zongo,d7).
lien_financier(zongo,sawadogo).
