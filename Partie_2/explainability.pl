:- set_prolog_flag(encoding, utf8).
% ============================================================
%  LandGuard Neuro-Symbolic AI
%  Fichier : explainability.pl
%  Partie 2 — Module d'Explicabilité (XAI)
%
%  Chaque règle métier de rules.pl, lorsqu'elle se déclenche,
%  appelle log_violation/3 avec :
%     - RuleID : identifiant normé de la règle (ex: rule_a1_accapareur_urbain)
%     - Vars   : liste des variables/valeurs engagées (ex: [acteur=yussef, nb=5])
%     - Motif  : phrase de justification textuelle générée dynamiquement
%
%  Le journal (trace_log/4) est ensuite exploitable pour générer
%  un rapport XAI lisible par un humain (cf. print_traces/0)
%  et pour le pipeline d'orchestration (Partie 5, main.py).
% ============================================================

:- dynamic(trace_log/4).
:- dynamic(trace_counter/1).

trace_counter(0).

% ------------------------------------------------------------
% log_violation(+RuleID, +Vars, +Motif)
%   Enregistre une alerte/violation détectée par une règle.
% ------------------------------------------------------------
log_violation(RuleID, Vars, Motif) :-
    retract(trace_counter(N)),
    N1 is N + 1,
    assertz(trace_counter(N1)),
    get_time(TS),
    assertz(trace_log(RuleID, Vars, Motif, TS)).

% ------------------------------------------------------------
% reset_traces/0
%   Vide le journal d'explications (utile entre deux analyses).
% ------------------------------------------------------------
reset_traces :-
    retractall(trace_log(_,_,_,_)),
    retractall(trace_counter(_)),
    assertz(trace_counter(0)).

% ------------------------------------------------------------
% print_traces/0
%   Affiche le journal complet, formaté pour lecture humaine.
% ------------------------------------------------------------
print_traces :-
    ( trace_log(_,_,_,_)
    -> forall(trace_log(ID, Vars, Motif, _),
              format("  [~w]~n    Variables : ~w~n    Justification : ~w~n~n", [ID, Vars, Motif]))
    ;  format("  (Aucune alerte journalisée)~n")
    ).

% ------------------------------------------------------------
% print_traces_for/1
%   Affiche uniquement les traces dont l'identifiant de règle
%   commence par le préfixe donné (ex: print_traces_for(rule_a)).
% ------------------------------------------------------------
print_traces_for(Prefix) :-
    forall(
        ( trace_log(ID, Vars, Motif, _),
          atom(ID),
          atom_concat(Prefix, _, ID) ),
        format("  [~w]~n    Variables : ~w~n    Justification : ~w~n~n", [ID, Vars, Motif])
    ).

% ------------------------------------------------------------
% count_traces(-Count)
%   Nombre total d'alertes journalisées.
% ------------------------------------------------------------
count_traces(Count) :-
    findall(1, trace_log(_,_,_,_), L),
    length(L, Count).

% ------------------------------------------------------------
% traces_to_list(-List)
%   Exporte le journal sous forme de liste de termes
%   alerte(RuleID, Vars, Motif) — utile pour export JSON (Partie 5).
% ------------------------------------------------------------
traces_to_list(List) :-
    findall(alerte(ID, Vars, Motif), trace_log(ID, Vars, Motif, _), List).

% ------------------------------------------------------------
% write_traces_json(+Stream)
%   Sérialise le journal en JSON (format simple, sans dépendance
%   externe) sur le flux donné. Utilisé par main.py (Partie 5).
% ------------------------------------------------------------
write_traces_json(Stream) :-
    findall(alerte(ID, Vars, Motif), trace_log(ID, Vars, Motif, _), Alertes),
    format(Stream, "[~n", []),
    write_traces_json_list(Stream, Alertes),
    format(Stream, "]~n", []).

write_traces_json_list(_, []).
write_traces_json_list(Stream, [alerte(ID, Vars, Motif)]) :-
    !,
    write_one_trace_json(Stream, ID, Vars, Motif, "").
write_traces_json_list(Stream, [alerte(ID, Vars, Motif)|Rest]) :-
    write_one_trace_json(Stream, ID, Vars, Motif, ","),
    write_traces_json_list(Stream, Rest).

write_one_trace_json(Stream, ID, Vars, Motif, Sep) :-
    json_escape(Motif, MotifEsc),
    with_output_to(string(VarsStr), write_canonical(Vars)),
    json_escape(VarsStr, VarsEsc),
    format(Stream,
           '  {"rule_id": "~w", "variables": "~w", "explanation": "~w"}~w~n',
           [ID, VarsEsc, MotifEsc, Sep]).

% Échappe les guillemets et retours à la ligne pour un JSON valide
json_escape(In, Out) :-
    ( atom(In) -> atom_string(In, S0) ; S0 = In ),
    split_string(S0, "\"", "", Parts1),
    atomic_list_concat(Parts1, '\\"', A1),
    split_string(A1, "\n", "", Parts2),
    atomic_list_concat(Parts2, ' ', Out).
