"""The edit lists of derive.py (plan §6.12, "一份代码、几个构建").  Filled in at sub-step 4.

  CHANGED_FILES  stock files the feature changes (paths in the Isabelle tree); the stock build takes
                 them from the stock tree, the other builds from ../src/
  NEW_FILES      files the feature adds (only in ../src/)
  LOAD           user-space load order of the clean, observe and mutant builds (paths in the build)
  STOCK_LOAD     user-space load order of the stock build
  IMPORTS        what the generated Dot_Build theory imports
  USERSPACE      edits that make the files loadable in user space next to stock (structure renames,
                 ...); applied to stock and clean alike, so their anchors lie in text the feature
                 does not change; an edit of a new file is skipped in the stock build
  OBSERVE        edits that add G2's switches, counters and audits (never in the clean code)
  MUTANTS        name -> edits of one G3 mutant, applied on top of OBSERVE
"""
from collections import namedtuple

Edit = namedtuple("Edit", "name path old new")

CHANGED_FILES = [
  "src/Pure/Syntax/lexicon.ML",
  "src/Pure/Syntax/parser.ML",
  "src/Pure/Syntax/term_position.ML",
  "src/Pure/Isar/proof_context.ML",
  "src/Pure/Syntax/syntax_phases.ML",
  "src/Pure/Syntax/syntax.ML",
  "src/Pure/pure_thy.ML",
  "src/Pure/type_infer_context.ML",
  "src/Tools/subtyping.ML",
]
NEW_FILES = [
  "src/Pure/Syntax/dot_field.ML",
  "src/Pure/Syntax/dot_field_attrib.ML",
]
# proof_context.ML is not loaded in user space (its one change is replaced by the edit
# dot_field-is-const-declared).  syntax.ML and pure_thy.ML are not loadable in user space: the
# parse tests (tests/parse/Parse_Base.thy) stand in for their parts (Syntax.parse_field_dots, the
# _dot_field productions; the carrier constant is the edit dot_field-pure-declarations) and load
# syntax_phases.ML themselves after that harness, which its tokenize and parse calls need
# type_infer_context.ML shadows Type_Infer_Context for the ML after it; Syntax.check_terms keeps
# Pure's, so a test theory registers the stand-ins of plan 6.12 (tests/standard/eng/Restart_Base.thy)
LOAD = [
  "src/Pure/Syntax/lexicon.ML",
  "src/Pure/Syntax/parser.ML",
  "src/Pure/Syntax/term_position.ML",
  "src/Pure/Syntax/dot_field.ML",
  "src/Pure/type_infer_context.ML",
  "src/Pure/Syntax/dot_field_attrib.ML",
  "src/Tools/subtyping.ML",
]
STOCK_LOAD = [
  "src/Pure/Syntax/lexicon.ML",
  "src/Pure/Syntax/parser.ML",
  "src/Pure/Syntax/term_position.ML",
  "src/Pure/type_infer_context.ML",
  "src/Tools/subtyping.ML",
]

SUB = "src/Tools/subtyping.ML"
DF = "src/Pure/Syntax/dot_field.ML"
SP = "src/Pure/Syntax/syntax_phases.ML"
TIC = "src/Pure/type_infer_context.ML"
IMPORTS = "Complex_Main"   # subtyping's userspace_replay needs real

USERSPACE = [
  # the options are declared and registered as attributes at once (attrib.ML registers them in
  # Pure; Attrib.register_config_bool is not exported)
  Edit("dot_field-options", DF,
r"""val dot_syntax = Config.declare_bool ("dot_syntax", \<^here>) (K false);
val dot_syntax_warning = Config.declare_bool ("dot_syntax_warning", \<^here>) (K true);""",
r"""val dot_syntax = Attrib.setup_config_bool \<^binding>\<open>dot_syntax\<close> (K false);
val dot_syntax_warning = Attrib.setup_config_bool \<^binding>\<open>dot_syntax_warning\<close> (K true);"""),
  # the loading theory declares the carrier constant, with the type that pure_thy.ML gives it:
  # read by Simple_Syntax.read_typ, so that its type variables have the empty sort.  (Written as
  # \<^typ> in a HOL theory they had sort "type", and unifying the carrier's object type with an
  # object raised every inference parameter of the object's type to that sort: the engines then
  # saw object types that the product never sees.  Review of proto_specific, 2026-11-15.)
  Edit("dot_field-pure-declarations", DF,
r"""val access_const = "Pure.dot_access";""",
r"""val access_const = "Pure.dot_access";

(*user space: the carrier constant of pure_thy.ML*)
val _ =
  Theory.setup (fn thy =>
    thy
    |> Sign.root_path
    |> Sign.add_consts
        [(Binding.concealed (Binding.qualify true "Pure" (Binding.make ("dot_access", \<^here>))),
          Simple_Syntax.read_typ "'n \<Rightarrow> 'a \<Rightarrow> 'b", NoSyn)]
    |> Sign.restore_naming thy);"""),
  # stock Proof_Context does not export is_const_declared: its body (proof_context.ML:374-376)
  Edit("dot_field-is-const-declared", DF,
r"""Proof_Context.is_const_declared ctxt c""",
r"""(let val space = Proof_Context.const_space ctxt
     in Name_Space.declared space (Name_Space.intern space c) end)"""),
  # stock Proof_Context does not export pattern_mode (proof_context.ML, next to abbrev_mode; the
  # file is not loaded in user space).  mode_pattern is the only mode with the pattern flag
  # (proof_context.ML:244-247, make_mode is not exported), so the test is the same
  Edit("dot_field-pattern-mode", DF,
r"""Proof_Context.pattern_mode ctxt""",
r"""(Proof_Context.get_mode ctxt = Proof_Context.mode_pattern)"""),
  # a copy of Subtyping next to HOL's: its own option and data (userspace_replay)
  # Syntax_Phases.simple_check, which step 2 exports (plan 6.10); the copy's check (the engine,
  # MERGE.md 5 step 9) uses it.  A structure extended by it, before the copy; harmless for stock
  Edit("subtyping-simple-check", SUB,
"""signature SUBTYPING =""",
"""(*user space: Syntax_Phases with simple_check, which syntax_phases.ML exports in step 2*)
structure Syntax_Phases =
struct
open Syntax_Phases;
fun simple_check eq f xs ctxt =
  let val xs' = f ctxt xs
  in if eq_list eq (xs, xs') then NONE else SOME (xs', ctxt) end;
end;

signature SUBTYPING ="""),
  Edit("subtyping-signature", SUB,
"""  val print_coercions: Proof.context -> unit
end;""",
"""  val print_coercions: Proof.context -> unit
  val coercion_infer_types: Proof.context -> term list -> term list
  val userspace_replay: Context.generic -> Context.generic
  val hol_coercion_enabled: bool Config.T
end;"""),
  # the copy registers its check at stage -100 next to HOL's; its own option (no attribute, so that
  # several copies load in one theory, MERGE_INVENTORY 0.12) switches it, so that a test switches
  # HOL's check off and the copy's on, and the copy's learning runs (D14) switch the copy's off;
  # hol_coercion_enabled: HOL's option, for the tests
  Edit("subtyping-own-option", SUB,
"""val coercion_enabled = Attrib.setup_config_bool \\<^binding>\\<open>coercion_enabled\\<close> (K false);""",
"""(*user space: the copy's own option; HOL's for the tests*)
val coercion_enabled = Config.declare_bool ("coercion_enabled", \\<^here>) (K false);
val hol_coercion_enabled = Subtyping.coercion_enabled;"""),
  Edit("subtyping-no-attributes", SUB,
"""val _ =
  Theory.setup
   (Attrib.setup \\<^binding>\\<open>coercion\\<close>""",
"""(*user space: HOL's declarations (Real.thy:936-945, Complex.thy:146-149, HOL.thy:1892,
  Ctr_Sugar.thy:25-28) replayed into this copy's data*)
val userspace_replay =
  fold add_coercion
   [\\<^term>\\<open>of_nat :: nat \\<Rightarrow> int\\<close>, \\<^term>\\<open>of_nat :: nat \\<Rightarrow> real\\<close>,
    \\<^term>\\<open>of_int :: int \\<Rightarrow> real\\<close>] #>
  fold add_type_map
   [\\<^term>\\<open>map\\<close>, \\<^term>\\<open>\\<lambda>f g h x. g (h (f x))\\<close>, \\<^term>\\<open>\\<lambda>f g (x,y). (f x, g y)\\<close>] #>
  fold add_coercion
   [\\<^term>\\<open>of_real :: real \\<Rightarrow> complex\\<close>, \\<^term>\\<open>of_rat :: rat \\<Rightarrow> complex\\<close>,
    \\<^term>\\<open>of_int :: int \\<Rightarrow> complex\\<close>, \\<^term>\\<open>of_nat :: nat \\<Rightarrow> complex\\<close>] #>
  map_coerce_args (fn tab => tab
    |> Symtab.update (\\<^const_name>\\<open>NO_MATCH\\<close>, [FORBID, FORBID])
    |> Symtab.update (\\<^const_name>\\<open>case_guard\\<close>, [FORBID, PERMIT, FORBID])
    |> Symtab.update (\\<^const_name>\\<open>case_cons\\<close>, [FORBID, FORBID])
    |> Symtab.update (\\<^const_name>\\<open>case_abs\\<close>, [FORBID])
    |> Symtab.update (\\<^const_name>\\<open>case_elem\\<close>, [FORBID, PERMIT]));

val _ =
  I
   (Attrib.setup \\<^binding>\\<open>coercion\\<close>"""),
  Edit("subtyping-no-command", SUB,
"""val _ =
  Outer_Syntax.command \\<^command_keyword>\\<open>print_coercions\\<close>
    "print information about coercions"
    (Scan.succeed (Toplevel.keep (print_coercions o Toplevel.context_of)));""",
""""""),
  # a copy of Syntax_Phases next to Pure's: renamed, without signature (the tests call its
  # parse_term and check_terms), installing nothing, its standard phases registered in its own
  # checks (Pure's Syntax.check_terms is not the copy's).  The clean copy, compiled after this build's
  # Lexicon and Parser, needs the harness of tests/parse/Parse_Base.thy (Syntax.tokenize, parse,
  # parse_field_dots on them), so it is not in LOAD; the stock copy loads on Pure's own
  # (tests/parse/Stock_Copy.thy)
  Edit("phases-signature", SP,
"""signature SYNTAX_PHASES =""",
"""signature DOT_SYNTAX_PHASES ="""),
  Edit("phases-structure", SP,
"""structure Syntax_Phases: SYNTAX_PHASES =""",
"""structure Dot_Syntax_Phases ="""),
  Edit("phases-no-translations", SP,
"""val _ = Theory.setup
 (Sign.parse_ast_translation""",
"""val _ = I
 (Sign.parse_ast_translation"""),
  Edit("phases-no-install", SP,
"""  Theory.setup
   (Syntax.install_operations""",
"""  I
   (Syntax.install_operations"""),
  Edit("phases-standard-begin", SP,
"""val _ = Context.>>
 (Syntax_Phases.typ_check 0 "standard" """,
"""local structure Syntax_Phases = Dot_Syntax_Phases in
val _ = Context.>>
 (Syntax_Phases.typ_check 0 "standard" """),
  Edit("phases-standard-end", SP,
"""Proof_Context.standard_term_uncheck);
""",
"""Proof_Context.standard_term_uncheck);
end;
"""),
  # a copy of Type_Infer_Context next to Pure's: Pure's option, which the attribute const_sorts sets
  Edit("type_infer_context-const-sorts", TIC,
r"""val const_sorts = Config.declare_bool ("const_sorts", \<^here>) (K true);""",
r"""val const_sorts = Type_Infer_Context.const_sorts;"""),
]
OBSERVE = [
  # G2 (b), the first-round audit (round 6's DOT_V_R1AUDIT, type_infer_restart.ML:471-524), on with
  # DOT_V_R1AUDIT=on: on every batch the standard engine decides, its output (inference and
  # abbreviation expansion, markers removed) against stock's "standard" on E(C), built from the
  # engine's input with every carrier replaced by a fresh instance of its choice; one VR1 line
  Edit("observe-r1-audit", TIC,
r"""(* checks *)

""",
r"""(* checks *)

val r1audit = getenv "DOT_V_R1AUDIT" = "on";

fun r1_explicit choices t =
  (case Dot_Field.dest_carrier t of
    SOME ({serial, ...}, x) =>
      let
        val g =
          (case Inttab.lookup choices serial of
            SOME g => g
          | NONE => raise Fail "VR1: an undecided carrier");
        val g' = Term.map_types (Term.map_atyps (fn TVar ((a, j), S) =>
            Type_Infer.param 0 (a ^ "_vr1_" ^ string_of_int serial ^ "_" ^ string_of_int j, S)
          | T => T)) g;
      in g' $ r1_explicit choices x end
  | NONE =>
      (case t of
        u $ v => r1_explicit choices u $ r1_explicit choices v
      | Abs (a, T, u) => Abs (a, T, r1_explicit choices u)
      | _ => t));

(*the engine's choices (key |-> registered term) of its accesses, by payload serial*)
fun r1_choices accs decided =
  Vartab.fold (fn (key, g) =>
    let val ({payload, ...}: Dot_Field.access, _) = the (Vartab.lookup accs key)
    in Inttab.update (#serial payload, g) end) decided Inttab.empty;

fun r1_audit ctxt raw_ts choices ts' =
  let
    val engine = filter_out Dot_Field.is_marker ts';
    val learnt = if length engine < length ts' then "learnt" else "no-learning";
    val pr = Syntax.string_of_term (ctxt |> Config.put show_types true |> Config.put show_sorts true);
    val stock =
      Exn.capture (fn () =>
        infer_types ctxt (map (r1_explicit choices) raw_ts)
        |> map (Proof_Context.expand_abbrevs ctxt)) ();
  in
    (case stock of
      Exn.Res us =>
        if length us = length engine andalso forall (op aconv) (us ~~ engine)
        then writeln ("VR1 SAME " ^ learnt)
        else
          writeln ("VR1 DIFF " ^ learnt ^ "\n  engine: " ^ commas (map pr engine) ^
            "\n  stock:  " ^ commas (map pr us))
    | Exn.Exn e => writeln ("VR1 STOCK-ERR " ^ learnt ^ ": " ^ Runtime.exn_message e))
  end;

"""),
  Edit("observe-r1-audit-call", TIC,
r"""          Dot_Field.selection_check
            (fn ctxt' => infer_fields ctxt' #>> map (Proof_Context.expand_abbrevs ctxt')) ts ctxt)""",
r"""          Dot_Field.selection_check
            (fn ctxt' => fn ts =>
              let
                val (ts', (accs, decided)) = infer_fields ctxt' ts;
                val ts'' = map (Proof_Context.expand_abbrevs ctxt') ts';
                (*the batches where the engine decided fields and left no carrier*)
                val _ =
                  if r1audit andalso not (Vartab.is_empty decided) andalso
                    not (exists Dot_Field.has_access ts'')
                  then r1_audit ctxt' ts (r1_choices accs decided) ts'' else ();
              in (ts'', (accs, decided)) end) ts ctxt)"""),
  # the coercion engine (MERGE.md 5 step 9): switches by environment variable; every switch is off
  # unless set.  Dot_Observe holds them and the audits' records
  Edit("observe-sub-structure", SUB,
"""structure Subtyping: SUBTYPING =
struct

open Subtyping_Base;
""",
"""(*OBSERVE: the switches and records of the observation build*)
structure Dot_Observe =
struct
(*G2 (a): every I1a exit re-elaborated by stock's code on E(C)*)
val recheck_done = getenv "S3B_RECHECK_DONE" = "on";
(*I1a's keep or drop (plan 1 item 22): every I1a exit returns stock's inference on E(C) instead*)
val no_i1a = getenv "DOT_NO_I1A" = "on";
(*G2 (c): every prediction against the late choice of a run without prediction (S3B_AB_PRED), every
  prediction table against one without the later rounds' reuse (S3C_PRED_AUDIT)*)
val ab_pred = getenv "S3B_AB_PRED" = "on";
val pred_audit = getenv "S3C_PRED_AUDIT" = "on";
(*the I1b shortcut (plan 6.12), limited by I1a's coercion_args condition*)
val i1b = getenv "DOT_I1B" = "on";
(*D15: the decisions without the object's own type (dot_object_own_type off)*)
val own_off = getenv "DOT_OBJECT_OWN_TYPE" = "off";
(*frequency counts: one OBS line per event*)
val counting = getenv "DOT_OBS_COUNT" = "on";
fun note s = if counting then writeln ("OBS " ^ s) else ();
val predict = Unsynchronized.ref true;
val reuse = Unsynchronized.ref true;
val late_made = Unsynchronized.ref ([]: (indexname * term) list);
val pred_made = Unsynchronized.ref ([]: (indexname * term) list);
(*I1b: the last local failure had no field waiting, no late choice and no rule error; the binding
  choices of the local pass*)
val clean_failure = Unsynchronized.ref false;
val binding = Unsynchronized.ref (Vartab.empty: term Vartab.table);
end;

structure Subtyping: SUBTYPING =
struct

open Subtyping_Base;
"""),
  Edit("observe-sub-own-type", SUB,
"""          if transparent count_of false c then inner_type bs obj else NONE""",
"""          if not Dot_Observe.own_off andalso transparent count_of false c then inner_type bs obj
          else NONE"""),
  Edit("observe-sub-no-i1a", SUB,
"""    fun exit objects (ts', (tye, idx')) C confirmed =
      let
""",
"""    fun exit objects (ts', (tye, idx')) C confirmed =
      if Dot_Observe.no_i1a andalso is_none objects then explicit_E C else
      let
"""),
  Edit("observe-sub-recheck-done", SUB,
"""      in (#2 (Type_Infer.finish ctxt tye ([], ts' @ markers)), (accs, C)) end;

    (*stock's inference on the term E(C), C complete: the local pass, else the global algorithm*)
    fun explicit_E C =""",
"""        val r = (#2 (Type_Infer.finish ctxt tye ([], ts' @ markers)), (accs, C));
        (*OBSERVE G2 (a): an I1a exit against stock's code on E(C), and the last check on every
          field, the confirmed ones included*)
        val _ =
          if not Dot_Observe.recheck_done orelse is_some objects then ()
          else
            (case Exn.result (fn () =>
                (Dot_Field.last_check ctxt engine (tye, idx') accs_read (without learnt C);
                 explicit_E C)) () of
              Exn.Res r' =>
                if eq_list (op aconv) (#1 r, #1 r') then writeln "S3B DONE-RECHECK SAME"
                else writeln ("S3B DONE-RECHECK DIFF " ^ \\<^make_string> (#1 r, #1 r'))
            | Exn.Exn e => writeln ("S3B DONE-RECHECK REJECTED " ^ Runtime.exn_message e));
      in r end

    (*stock's inference on the term E(C), C complete: the local pass, else the global algorithm*)
    and explicit_E C ="""),
  Edit("observe-sub-reuse", SUB,
"""            if left andalso exists feeds added then loop reusing preds' sorted""",
"""            if left andalso exists feeds added then
              loop (if ! Dot_Observe.reuse then reusing else first) preds' sorted"""),
  Edit("observe-sub-pred-audit", SUB,
"""    val predictions = Lazy.lazy (fn () => compute_predictions false);
    (*generation's are the local ones unless a local prediction is sorted*)
    val predictions_gen = Lazy.lazy (fn () =>
      let val r as (_, _, sorted) = Lazy.force predictions
      in if sorted then compute_predictions true else r end);""",
"""    (*OBSERVE G2 (c): every table also without the later rounds' reuse*)
    fun predictions_of gen =
      let val r = compute_predictions gen in
        if not Dot_Observe.pred_audit then r
        else
          let
            val _ = Dot_Observe.reuse := false;
            val r' = Exn.result compute_predictions gen;
            val _ = Dot_Observe.reuse := true;
            fun same ((pf, pb), objs, s) ((pf', pb'), objs', s') =
              Symtab.dest pf = Symtab.dest pf' andalso Vartab.dest pb = Vartab.dest pb' andalso
              Vartab.dest objs = Vartab.dest objs' andalso s = s';
          in
            (writeln ("S3C PRED-AUDIT " ^ (if same r (Exn.release r') then "SAME" else "DIFF")); r)
          end
      end;
    val predictions = Lazy.lazy (fn () => predictions_of false);
    (*generation's are the local ones unless a local prediction is sorted*)
    val predictions_gen = Lazy.lazy (fn () =>
      let val r as (_, _, sorted) = Lazy.force predictions
      in if sorted then predictions_of true else r end);"""),
  Edit("observe-sub-ab-pred-local", SUB,
"""                    | Dot_Field.Wait =>
                        Option.map (fn g => (g, false, true)) (predicted key)""",
"""                    | Dot_Field.Wait =>
                        if not (! Dot_Observe.predict) then NONE
                        else
                          Option.map (fn g =>
                            (Dot_Observe.pred_made := (key, g) :: ! Dot_Observe.pred_made;
                             (g, false, true)))
                          (predicted key)"""),
  Edit("observe-sub-ab-pred-gen", SUB,
"""              let val T = the_default U' (exact_object key) in
""",
"""              let
                val T = if ! Dot_Observe.predict then the_default U' (exact_object key) else U';
                val predicted_gen = fn k =>
                  if ! Dot_Observe.predict then predicted_gen k
                  else NONE;
              in
"""),
  # the late choices of both re-runs (a step's, the end of the traversal's)
  Edit("observe-sub-ab-pred-late", SUB,
"""    fun late_choices ds deferred late =
      (fold (fn (s, _, _) => Integer.min s) ds""",
"""    fun late_choices ds deferred late =
      (Dot_Observe.late_made :=
        fold (fn (_, key, g) => cons (key, g)) ds (! Dot_Observe.late_made);
      (fold (fn (s, _, _) => Integer.min s) ds"""),
  Edit("observe-sub-ab-pred-late-end", SUB,
"""        (Inttab.fold (fn (_, (key, g)) => Vartab.update (key, g)) deferred late));""",
"""        (Inttab.fold (fn (_, (key, g)) => Vartab.update (key, g)) deferred late)));"""),
  Edit("observe-sub-ab-pred-run", SUB,
"""    Dot_Field.selection_check (dot_infer_types (Config.put coercion_enabled false)) ts ctxt""",
"""    Dot_Field.selection_check (fn ctxt => fn ts =>
    let
      val infer = dot_infer_types (Config.put coercion_enabled false) ctxt;
      (*OBSERVE G2 (c): the late choices of the run without prediction*)
      val late =
        if not Dot_Observe.ab_pred then []
        else
          (Dot_Observe.predict := false; Dot_Observe.late_made := [];
           ignore (Exn.result infer ts); Dot_Observe.predict := true; ! Dot_Observe.late_made);
      val _ = Dot_Observe.pred_made := [];
      val r = Exn.result infer ts;
      val _ =
        if not Dot_Observe.ab_pred then ()
        else
          ! Dot_Observe.pred_made |> List.app (fn (key, g) =>
            writeln ("S3B AB-PRED " ^
              (case AList.lookup (op =) late key of
                SOME g' => if g aconv g' then "pred-match" else "pred-MISMATCH"
              | NONE => "pred-unmatched")));
    in Exn.release r end) ts ctxt"""),
  # G2 (d): a field that dot_propagate decides is never one that the prediction table types or
  # predicts (in a run with prediction: not S3B_AB_PRED's run without it)
  Edit("observe-sub-prop-dup", SUB,
"""                        val new = pending |> filter ready |> map_filter (fn key' =>
                          (case decide tye_idx' key' of
                            Dot_Field.Choose g' => SOME (key', g')
                          | _ => NONE));""",
"""                        val new = pending |> filter ready |> map_filter (fn key' =>
                          (case decide tye_idx' key' of
                            Dot_Field.Choose g' => SOME (key', g')
                          | _ => NONE));
                        val _ = new |> List.app (fn (key', _) =>
                          let val ({payload, ...}, _) = the_access key' in
                            Dot_Observe.note "PROPAGATE";
                            if ! Dot_Observe.predict andalso
                              (is_some (exact_object key') orelse is_some (predicted_gen key'))
                            then writeln ("S3C PROP-DUP " ^ Dot_Field.field_name payload) else ()
                          end);"""),
  # frequency counts (plan 6.12 end): tolerant learning; and the default path, the coercion_args
  # condition, the replaced pass
  Edit("observe-sub-count-tol-constraints", SUB,
"""           {carrier = carrier fields, tolerate_weak = coerced_ctors,""",
"""           {carrier = carrier fields,
            tolerate_weak = fn tye => fn TU =>
              coerced_ctors tye TU andalso (Dot_Observe.note "TOLERANT-WEAK"; true),"""),
  Edit("observe-sub-count-default", SUB,
"""            (binding_rule_error C_bind rule; explicit_E (learn err rule C_bind)))""",
"""            (Dot_Observe.note "DEFAULT-PATH"; binding_rule_error C_bind rule;
             explicit_E (learn err rule C_bind)))"""),
  Edit("observe-sub-count-replaced", SUB,
"""    and replaced () = after_local (local_pass false);""",
"""    and replaced () =
      (Dot_Observe.note "REPLACED"; after_local (local_pass false));"""),
  # the I1b shortcut as a test switch (plan 6.12 "one code, several builds"): after a local pass
  # that failed with no field waiting, no late choice and no rule error, a candidate that agrees
  # with its binding choices goes to stock's global algorithm on E(C) at once; not with a
  # coercion_args head
  Edit("observe-sub-i1b-failure", SUB,
"""    fun local_failure rule err fs =
      if postponed fs then POSTPONED_FAILURE""",
"""    fun local_failure rule err fs =
      (if postponed fs then ()
       else
        (Dot_Observe.clean_failure :=
          (Inttab.is_empty (#fields (#waiting fs)) andalso Vartab.is_empty (#late fs) andalso
            is_none rule);
         Dot_Observe.binding := binding_choices fs);
      if postponed fs then POSTPONED_FAILURE"""),
  Edit("observe-sub-i1b-reset", SUB,
"""    fun local_pass defer =
      let
""",
"""    fun local_pass defer =
      let
        val _ = Dot_Observe.clean_failure := false;
"""),
  Edit("observe-sub-i1b-failure-end", SUB,
"""      else LOCAL_FAILURE (err, binding_choices fs, rule);""",
"""      else LOCAL_FAILURE (err, binding_choices fs, rule));"""),
  # the observed instance's generation and solving, for the I1b shortcut's global algorithm
  Edit("observe-sub-i1b-signature", SUB,
"""    val infer_prepared: Proof.context -> hooks -> int -> term list -> term list * tye_idx
  end =
  Coercion_Inference(val observed = true val learning = false);""",
"""    val infer_prepared: Proof.context -> hooks -> int -> term list -> term list * tye_idx
    val generate_constraints: Proof.context -> (unit -> string * Buffer.T) -> hooks -> term ->
      tye_idx -> typ * tye_idx * constraint list
    val process_constraints: Proof.context -> (unit -> string * Buffer.T) -> hooks ->
      constraint list -> tye_idx -> tye_idx
  end =
  Coercion_Inference(val observed = true val learning = false);"""),
  Edit("observe-sub-i1b", SUB,
"""    (*option b: learn C from nothing; when that learning is rejected and the local pass made
      binding choices, the default path*)""",
"""    (*OBSERVE: (I1b) stock's global algorithm on the term E(C), observed*)
    fun global_E err C =
      let
        val objs = Unsynchronized.ref Inttab.empty;
        fun observe t U =
          (case Dot_Field.dest_node_instance t of
            SOME (j, _) => objs := Inttab.update (j, U) (! objs)
          | NONE => ());
        val hooks = observe_hooks observe;
        val tms = map (Dot_Field.explicit C) ts;
        val err' = err ++> "\\n";
        val (tye_idx, cs) =
          fold (fn t => fn (tye_idx, cs) =>
            let val (_, tye_idx', cs') =
              Observed_Coercions.generate_constraints ctxt err' hooks t tye_idx
            in (tye_idx', cs' @ cs) end) tms ((Vartab.empty, idx), []);
        val tye_idx' = Observed_Coercions.process_constraints ctxt err' hooks cs tye_idx;
      in exit (SOME (! objs)) (insert_coercions ctxt tye_idx' tms, tye_idx') C Vartab.empty end;
    (*OBSERVE: a candidate's elaboration, at the three places where the clean code calls explicit_E
      on one*)
    fun try_candidate err C =
      let
        val shortcut =
          Dot_Observe.i1b andalso ! Dot_Observe.clean_failure andalso not (cargs_head C) andalso
            Vartab.forall (fn (k, g) =>
              (case Vartab.lookup C k of SOME g' => g aconv g' | NONE => false))
              (! Dot_Observe.binding);
      in if shortcut then (Dot_Observe.note "I1B"; global_E err C) else explicit_E C end;

    (*option b: learn C from nothing; when that learning is rejected and the local pass made
      binding choices, the default path*)"""),
  Edit("observe-sub-i1b-option-b", SUB,
"""        Exn.Res C => explicit_E C""",
"""        Exn.Res C => try_candidate err C"""),
  Edit("observe-sub-i1b-waiting", SUB,
"""            explicit_E (learn no_err NONE C_bind))""",
"""            try_candidate no_err (learn no_err NONE C_bind))"""),
  Edit("observe-sub-i1b-default", SUB,
"""             explicit_E (learn err rule C_bind)))""",
"""             try_candidate err (learn err rule C_bind)))"""),
]
MUTANTS = {
  # G3 (plan 6.12): one mutant per junction of the mechanisms that remain, on the observe build.
  # The standard engine's late decision forgets the result type (round 6 VERIFY 2.1; scored by G2 (b))
  "late_no_result": [Edit("late_no_result", TIC,
"""tye_idx |> unify ctxt (P, fastype_of g') |> unify ctxt (objT --> resT, fastype_of g')""",
"""tye_idx |> unify ctxt (P, fastype_of g') |> unify ctxt (objT, domain_type (fastype_of g'))""")],
  # I1a without its coercion_args condition (the one I1a exit, of a pass that deferred or not)
  "i1a_no_cargs": [Edit("i1a_no_cargs", SUB,
"""if cargs_head C then explicit_E C""",
"""if false then explicit_E C""")],
  # the default path's final rule error without its coercion_args condition
  "default_no_cargs": [Edit("default_no_cargs", SUB,
"""if cargs_head C_bind then () else error msg""",
"""if false then () else error msg""")],
  # the single exit function (round 5 review 3.6): the exit of stock's inference on E(C) reads the
  # objects' types as the local pass's exit does; the deferred I1a exit skips the last check
  "exit_reader": [Edit("exit_reader", SUB,
"""          (case objects of
            NONE => accs_read""",
"""          (case NONE of
            NONE => accs_read""")],
  "deferred_exit_no_check": [Edit("deferred_exit_no_check", SUB,
"""exit NONE (ts', tye_idx) C confirmed""",
"""exit NONE (ts', tye_idx) C (if postponed then Vartab.map (K (K ())) C else confirmed)""")],
  # D15 (plan 6.5.1): the two readings of tye0 that the revision removed -- the choice after solving
  # tries the typing before solving first; the oldest field's decision (its learning run, its text)
  # reads the typing before solving
  "d15_chosen_tye0": [
    Edit("d15_chosen_tye0-choice", SUB,
"""        fun decide_solved key =
""",
"""        fun choice key =
          (case (decide (tye0, #2 tye_idx) key, decide tye_idx key) of
            (Dot_Field.Choose g, _) => SOME g
          | (_, Dot_Field.Choose g) => SOME g
          | _ => NONE);
        fun decide_solved key =
"""),
    Edit("d15_chosen_tye0-oldest", SUB,
"""            (case d of
              Dot_Field.Choose g => relearn (key, g)""",
"""            (case (case choice key of SOME g => Dot_Field.Choose g | NONE => d) of
              Dot_Field.Choose g => relearn (key, g)""")],
  "d15_text_tye0": [
    Edit("d15_text_tye0-d", SUB,
"""            val d = decide tye_idx key;""",
"""            val d = decide (tye0, #2 tye_idx) key;"""),
    Edit("d15_text_tye0-text", SUB,
"""               error (field_error_msg tye_idx key d));""",
"""               error (field_error_msg (tye0, #2 tye_idx) key d));""")],
  # D15 before solving, and at a node of generation, off
  "d15_no_presolve": [Edit("d15_no_presolve", SUB,
"""if depends key orelse not solved andalso constrained tye0 cs' (objT_of key) then ds""",
"""if depends key then ds""")],
  # D15 in the local pass: a refining choice is made during the traversal again
  "d15_local_refines": [Edit("d15_local_refines", SUB,
"""if has_blocked tye (objT_of key) then Dot_Field.Wait else decide_on final tye_idx key;""",
"""if has_blocked tye (objT_of key) then Dot_Field.Wait else decide tye_idx key;""")],
  "d15_no_node": [Edit("d15_no_node", SUB,
"""if constrained tye1 (cs1 @ earlier) T then predicted_gen key""",
"""if false then predicted_gen key""")],
  # D13's dependency guard off
  "d13_off": [Edit("d13_off", SUB,
"""if depends key orelse not solved andalso constrained""",
"""if false andalso depends key orelse not solved andalso constrained""")],
  # tolerance (I12), at its one place
  "tolerance_no_weak": [Edit("tolerance_no_weak", SUB,
"""              coerced_ctors tye TU andalso""",
"""              false andalso coerced_ctors tye TU andalso""")],
  # option b's default path, D14's learning run off
  "no_default_path": [Edit("no_default_path", SUB,
"""if rejected exn andalso not (Vartab.is_empty C_bind) then default ()""",
"""if false then default ()""")],
  "no_d14": [Edit("no_d14", SUB,
"""(case learn_d14 (tye_idx, decided) of""",
"""(case NONE of""")],
  # D14's markers missing, the choices not passed back
  "no_markers": [Edit("no_markers", SUB,
"""            cons (Dot_Field.marker ctxt engine tye (the (Vartab.lookup accs' key)))) learnt [];""",
"""            cons (Dot_Field.marker ctxt engine tye (the (Vartab.lookup accs' key)))) Vartab.empty [];""")],
  "no_selections": [Edit("no_selections", SUB,
"""ts' @ markers)), (accs, C));""",
"""ts' @ markers)), (accs, Vartab.empty));""")],
  # the prediction off in the local pass
  "no_prediction": [Edit("no_prediction", SUB,
"""if not (! Dot_Observe.predict) then NONE""",
"""if true then NONE""")],
  # D6's spine reading: a constraint ends the spine (m1); a constraint counts as an argument (m2)
  "spine_m1": [Edit("spine_m1", SUB,
"""    fun spine (Const ("_type_constraint_", _) $ u) n = spine u n
      | spine (u $ _) n = spine u (n + 1)""",
"""    fun spine (u $ _) n = spine u (n + 1)""")],
  "spine_m2": [Edit("spine_m2", SUB,
"""    fun spine (Const ("_type_constraint_", _) $ u) n = spine u n""",
"""    fun spine (Const ("_type_constraint_", _) $ u) n = spine u (n + 1)""")],
  # D7: a step that fails on a blocked variable is frozen whole
  "blocked_freeze_all": [Edit("blocked_freeze_all", SUB,
"""    (case opened_unify ctxt (U' --> V, T') step (idx + 1) tye of""",
"""    (case (NONE: (typ Vartab.table * int) option) of""")],
  # D7: a parameter linked to a wildcard through a variable on the wildcard's chain is not frozen
  "opened_chain_missed": [Edit("opened_chain_missed", SUB,
"""                    is_wild A orelse member (op =) on_chain xi orelse""",
"""                    is_wild A orelse""")],
  # deferral: a pass that postponed a re-run reports its failure, or returns its waiting fields
  "deferral_report_failure": [Edit("deferral_report_failure", SUB,
"""      if postponed fs then POSTPONED_FAILURE
""",
"""      if false then POSTPONED_FAILURE
""")],
  "deferral_keep_waiting": [Edit("deferral_keep_waiting", SUB,
"""else if postponed fs then raise POSTPONED_FAILURE""",
"""else if false then raise POSTPONED_FAILURE""")],
}
