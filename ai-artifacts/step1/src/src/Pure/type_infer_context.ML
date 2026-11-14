(*  Title:      Pure/type_infer_context.ML
    Author:     Stefan Berghofer and Markus Wenzel, TU Muenchen

Type-inference preparation and standard type inference, with field access "x.f" (dot syntax).
*)

signature TYPE_INFER_CONTEXT =
sig
  val const_sorts: bool Config.T
  val const_type: Proof.context -> string -> typ option
  val prepare_positions: Proof.context -> term list -> term list * (Term_Position.T * typ) list
  val prepare: Proof.context -> term list -> int * term list
  val infer_types: Proof.context -> term list -> term list
  val infer_types_finished: Proof.context -> term list -> term list
  val standard_check:
    ((Proof.context -> term list -> term list) ->
      term list -> Proof.context -> (term list * Proof.context) option) ->
    term list -> Proof.context -> (term list * Proof.context) option
  val dot_check: term list -> Proof.context -> (term list * Proof.context) option
end;

structure Type_Infer_Context: TYPE_INFER_CONTEXT =
struct

(** prepare types/terms: create inference parameters **)

(* constraints *)

val const_sorts = Config.declare_bool ("const_sorts", \<^here>) (K true);

fun const_type ctxt =
  try ((not (Config.get ctxt const_sorts) ? Term.strip_sortsT) o
    Consts.the_constraint (Proof_Context.consts_of ctxt));

fun var_type ctxt = the_default dummyT o Proof_Context.def_type ctxt;


(* prepare_typ *)

fun prepare_typ typ params_idx =
  let
    val (params', idx) = fold_atyps
      (fn TVar (xi, S) =>
          (fn ps_idx as (ps, idx) =>
            if Type_Infer.is_param xi andalso not (Vartab.defined ps xi)
            then (Vartab.update (xi, Type_Infer.mk_param idx S) ps, idx + 1) else ps_idx)
        | _ => I) typ params_idx;

    fun prepare (T as Type (a, Ts)) idx =
          if T = dummyT then (Type_Infer.mk_param idx [], idx + 1)
          else
            let val (Ts', idx') = fold_map prepare Ts idx
            in (Type (a, Ts'), idx') end
      | prepare (T as TVar (xi, _)) idx =
          (case Vartab.lookup params' xi of
            NONE => T
          | SOME p => p, idx)
      | prepare (TFree ("'_dummy_", S)) idx = (Type_Infer.mk_param idx S, idx + 1)
      | prepare (T as TFree _) idx = (T, idx);

    val (typ', idx') = prepare typ idx;
  in (typ', (params', idx')) end;


(* prepare_term *)

fun prepare_term ctxt tm (vparams, params, idx) =
  let
    fun add_vparm xi (ps_idx as (ps, idx)) =
      if not (Vartab.defined ps xi) then
        (Vartab.update (xi, Type_Infer.mk_param idx []) ps, idx + 1)
      else ps_idx;

    val (vparams', idx') = fold_aterms
      (fn Var (_, Type ("_polymorphic_", _)) => I
        | Var (xi, _) => add_vparm xi
        | Free (x, _) => add_vparm (x, ~1)
        | _ => I)
      tm (vparams, idx);
    fun var_param xi = the (Vartab.lookup vparams' xi);

    fun polyT_of T idx =
      apsnd snd (prepare_typ (Type_Infer.paramify_vars T) (Vartab.empty, idx));

    fun constraint T t ps =
      if T = dummyT then (t, ps)
      else
        let val (T', ps') = prepare_typ T ps
        in (Type.constraint T' t, ps') end;

    fun prepare (Const ("_type_constraint_", T) $ t) ps_idx =
          let
            val A = Type.constraint_type ctxt T;
            val (A', ps_idx') = prepare_typ A ps_idx;
            val (t', ps_idx'') = prepare t ps_idx';
          in (Const ("_type_constraint_", A' --> A') $ t', ps_idx'') end
      | prepare (Const (c, T)) (ps, idx) =
          (case const_type ctxt c of
            SOME U =>
              let val (U', idx') = polyT_of U idx
              in constraint T (Const (c, U')) (ps, idx') end
          | NONE => error ("Undeclared constant: " ^ quote c))
      | prepare (Var (xi, Type ("_polymorphic_", [T]))) (ps, idx) =
          let val (T', idx') = polyT_of T idx
          in (Var (xi, T'), (ps, idx')) end
      | prepare (Var (xi, T)) ps_idx = constraint T (Var (xi, var_param xi)) ps_idx
      | prepare (Free (x, T)) ps_idx = constraint T (Free (x, var_param (x, ~1))) ps_idx
      | prepare (Bound i) ps_idx = (Bound i, ps_idx)
      | prepare (Abs (x, T, t)) ps_idx =
          let
            val (T', ps_idx') = prepare_typ T ps_idx;
            val (t', ps_idx'') = prepare t ps_idx';
          in (Abs (x, T', t'), ps_idx'') end
      | prepare (t $ u) ps_idx =
          let
            val (t', ps_idx') = prepare t ps_idx;
            val (u', ps_idx'') = prepare u ps_idx';
          in (t' $ u', ps_idx'') end;

    val (tm', (params', idx'')) = prepare tm (params, idx');
  in (tm', (vparams', params', idx'')) end;


(* prepare_positions *)

fun prepare_positions ctxt tms =
  let
    fun prepareT (Type (a, Ts)) ps_idx =
          let val (Ts', ps_idx') = fold_map prepareT Ts ps_idx
          in (Type (a, Ts'), ps_idx') end
      | prepareT T (ps, idx) =
          (case Term_Position.decode_positionT T of
            [] => (T, (ps, idx))
          | pos =>
              let
                val U = Type_Infer.mk_param idx [];
                val ps' = map (rpair U) pos;
              in (U, (ps' @ ps, idx + 1)) end);

    fun prepare_var (xi as (x, 0), T) =
          if Dot_Field.is_payload x andalso Config.get ctxt Dot_Field.dot_syntax
          then Dot_Field.rebuild_payload (x, T) else Var (xi, T)
      | prepare_var v = Var v;

    fun prepare (Const ("_type_constraint_", T)) ps_idx =
          let
            val A = Type.constraint_type ctxt T;
            val (A', ps_idx') = prepareT A ps_idx;
          in (Const ("_type_constraint_", A' --> A'), ps_idx') end
      | prepare (Const (c, T)) ps_idx =
          let val (T', ps_idx') = prepareT T ps_idx
          in (Const (c, T'), ps_idx') end
      | prepare (Free (x, T)) ps_idx =
          let val (T', ps_idx') = prepareT T ps_idx
          in (Free (x, T'), ps_idx') end
      | prepare (Var (xi, T)) ps_idx =
          let val (T', ps_idx') = prepareT T ps_idx
          in (prepare_var (xi, T'), ps_idx') end
      | prepare (t as Bound _) ps_idx = (t, ps_idx)
      | prepare (Abs (x, T, t)) ps_idx =
          let
            val (T', ps_idx') = prepareT T ps_idx;
            val (t', ps_idx'') = prepare t ps_idx';
          in (Abs (x, T', t'), ps_idx'') end
      | prepare (t $ u) ps_idx =
          let
            val (t', ps_idx') = prepare t ps_idx;
            val (u', ps_idx'') = prepare u ps_idx';
          in (t' $ u', ps_idx'') end;

    val idx = Type_Infer.param_maxidx_of tms + 1;
    val (tms', (ps, _)) = fold_map prepare tms ([], idx);
  in (tms', ps) end;



(** order-sorted unification of types **)

exception NO_UNIFIER of string * typ Vartab.table;

fun unify ctxt =
  let
    val thy = Proof_Context.theory_of ctxt;
    val arity_sorts = Proof_Context.arity_sorts ctxt;


    (* adjust sorts of parameters *)

    fun not_of_sort x S' S =
      "Variable " ^ x ^ "::" ^ Syntax.string_of_sort ctxt S' ^ " not of sort " ^
        Syntax.string_of_sort ctxt S;

    fun meet (_, []) tye_idx = tye_idx
      | meet (Type (a, Ts), S) (tye_idx as (tye, _)) =
          meets (Ts, arity_sorts a S handle ERROR msg => raise NO_UNIFIER (msg, tye)) tye_idx
      | meet (TFree (x, S'), S) (tye_idx as (tye, _)) =
          if Sign.subsort thy (S', S) then tye_idx
          else raise NO_UNIFIER (not_of_sort x S' S, tye)
      | meet (TVar (xi, S'), S) (tye_idx as (tye, idx)) =
          if Sign.subsort thy (S', S) then tye_idx
          else if Type_Infer.is_param xi then
            (Vartab.update_new
              (xi, Type_Infer.mk_param idx (Sign.inter_sort thy (S', S))) tye, idx + 1)
          else raise NO_UNIFIER (not_of_sort (Term.string_of_vname xi) S' S, tye)
    and meets (T :: Ts, S :: Ss) (tye_idx as (tye, _)) =
          meets (Ts, Ss) (meet (Type_Infer.deref tye T, S) tye_idx)
      | meets _ tye_idx = tye_idx;


    (* occurs check and assignment *)

    fun occurs_check tye xi (TVar (xi', _)) =
          if xi = xi' then raise NO_UNIFIER ("Occurs check!", tye)
          else
            (case Vartab.lookup tye xi' of
              NONE => ()
            | SOME T => occurs_check tye xi T)
      | occurs_check tye xi (Type (_, Ts)) = List.app (occurs_check tye xi) Ts
      | occurs_check _ _ _ = ();

    fun assign xi (T as TVar (xi', _)) S env =
          if xi = xi' then env
          else env |> meet (T, S) |>> Vartab.update_new (xi, T)
      | assign xi T S (env as (tye, _)) =
          (occurs_check tye xi T; env |> meet (T, S) |>> Vartab.update_new (xi, T));


    (* unification *)

    fun show_tycon (a, Ts) =
      quote (Syntax.string_of_typ ctxt (Type (a, replicate (length Ts) dummyT)));

    fun unif (T1, T2) (env as (tye, _)) =
      (case apply2 (`Type_Infer.is_paramT o Type_Infer.deref tye) (T1, T2) of
        ((true, TVar (xi, S)), (_, T)) => assign xi T S env
      | ((_, T), (true, TVar (xi, S))) => assign xi T S env
      | ((_, Type (a, Ts)), (_, Type (b, Us))) =>
          if a <> b then
            raise NO_UNIFIER
              ("Clash of types " ^ show_tycon (a, Ts) ^ " and " ^ show_tycon (b, Us), tye)
          else fold unif (Ts ~~ Us) env
      | ((_, T), (_, U)) => if T = U then env else raise NO_UNIFIER ("", tye));

  in unif end;



(** simple type inference **)

(* errors *)

fun prep_output ctxt tye bs ts Ts =
  let
    val (Ts_bTs', ts') = Type_Infer.finish ctxt tye (Ts @ map snd bs, ts);
    val (Ts', Ts'') = chop (length Ts) Ts_bTs';
    fun prep t =
      let val xs =
        rev (Syntax_Trans.variant_bounds ctxt t (rev (map (Name.clean o fst) bs ~~ Ts'')))
      in Term.subst_bounds (map Syntax_Trans.mark_bound_abs xs, t) end;
  in (map prep ts', Ts') end;

fun err_loose i = error ("Loose bound variable: B." ^ string_of_int i);

fun unif_failed msg =
  "Type unification failed" ^ (if msg = "" then "" else ": " ^ msg) ^ "\n\n";

fun err_appl ctxt msg tye bs t T u U =
  let val ([t', u'], [T', U']) = prep_output ctxt tye bs [t, u] [T, U]
  in error (unif_failed msg ^ Type.appl_error ctxt t' T' u' U' ^ "\n") end;


(* infer *)

fun infer ctxt =
  let
    fun inf _ (Const (_, T)) tye_idx = (T, tye_idx)
      | inf _ (Free (_, T)) tye_idx = (T, tye_idx)
      | inf _ (Var (_, T)) tye_idx = (T, tye_idx)
      | inf bs (Bound i) tye_idx =
          (snd (nth bs i handle General.Subscript => err_loose i), tye_idx)
      | inf bs (Abs (x, T, t)) tye_idx =
          let val (U, tye_idx') = inf ((x, T) :: bs) t tye_idx
          in (T --> U, tye_idx') end
      | inf bs (t $ u) tye_idx =
          let
            val (T, tye_idx') = inf bs t tye_idx;
            val (U, (tye, idx)) = inf bs u tye_idx';
            val V = Type_Infer.mk_param idx [];
            val tye_idx'' = unify ctxt (U --> V, T) (tye, idx + 1)
              handle NO_UNIFIER (msg, tye') => err_appl ctxt msg tye' bs t T u U;
          in (V, tye_idx'') end;

  in inf [] end;


(* main interfaces *)

fun prepare ctxt raw_ts =
  let
    val constrain_vars = Term.map_aterms
      (fn Free (x, T) => Type.constraint T (Free (x, var_type ctxt (x, ~1)))
        | Var (xi, T) => Type.constraint T (Var (xi, var_type ctxt xi))
        | _ => raise Same.SAME);

    val ts = burrow_types (Syntax.check_typs ctxt) raw_ts;
    val idx = Type_Infer.param_maxidx_of ts + 1;
    val (ts', (_, _, idx')) =
      fold_map (prepare_term ctxt o constrain_vars) ts
        (Vartab.empty, Vartab.empty, idx);
  in (idx', ts') end;

fun infer_types ctxt raw_ts =
  let
    val (idx, ts) = prepare ctxt raw_ts;
    val (tye, _) = fold (snd oo infer ctxt) ts (Vartab.empty, idx);
    val (_, ts') = Type_Infer.finish ctxt tye ([], ts);
  in ts' end;

fun infer_types_finished ctxt =
  infer_types ctxt #> Proof_Context.standard_term_check_finish ctxt;



(** type inference with field access (dot syntax) **)

(*what the texts of Dot_Field borrow*)
fun dot_engine ctxt : Dot_Field.engine =
  {rigid = not o Type_Infer.is_param, unify = unify ctxt, prep_output = prep_output ctxt};


(* the standard engine *)

(*fields: stamp |-> key of a field that waits for its object's type; index: the waiting fields under
  the parameters of their object types; stamp: the next stamp, so that waiting fields are examined
  in the order they began to wait*)
type waiting = {fields: indexname Inttab.table, index: Dot_Field.waiting_index, stamp: int};

val no_waiting_fields: waiting =
  {fields = Inttab.empty, index = Dot_Field.no_waiting_index, stamp = 0};

type field_state = {decided: term Vartab.table, waiting: waiting};

(*a late decision that makes inference conflict: the fields decided so far and the learnt ones
  among them, to be decided at their nodes when inference starts again*)
exception LATE_CLASH of term Vartab.table * Vartab.set;

(*the finished batch with a marker per learnt field appended, and its accesses with their
  choices.  Fields are decided at their nodes, or wait for their object's type and are decided late
  by unification; at the end, a field that still waits starts a learning run*)
fun infer_fields ctxt raw_ts =
  let
    val (idx0, ts) = prepare ctxt raw_ts;
    val accs = Dot_Field.collect_accesses ts;
    val dest_access = Dot_Field.batch_access accs;
    fun the_access key = the (Vartab.lookup accs key);
    fun objT_of key = #objT (#1 (the_access key));
    val engine = dot_engine ctxt;

    fun decide (tye, _) key =
      let val ({payload, objT, ...}, _) = the_access key in
        Dot_Field.decide ctxt {rigid = #rigid engine} (Dot_Field.field_name payload)
          (Dot_Field.norm tye objT)
      end;
    fun field_error_msg tye_idx key =
      Dot_Field.field_error_msg ctxt engine tye_idx (the_access key);


    (* waiting fields *)

    fun add_waiting tye key ({fields, index, stamp}: waiting) =
      {fields = Inttab.update (stamp, key) fields,
       index = Dot_Field.place tye stamp (objT_of key) index, stamp = stamp + 1};


    (* inference *)

    fun run (decided0, learnt0) =
      let
        fun decide_late learnt key g (tye_idx, decided) =
          let
            val ({objT, resT, ...}, _) = the_access key;
            val (P, g') = Dot_Field.node_instance_parts key g;
            val decided' = Vartab.update (key, g) decided;
            val tye_idx' =
              tye_idx |> unify ctxt (P, fastype_of g') |> unify ctxt (objT --> resT, fastype_of g')
                handle NO_UNIFIER _ => raise LATE_CLASH (decided', learnt);
          in (tye_idx', decided') end;

        fun resolve tye_idx (fs as {decided, waiting = {fields, index, stamp}}: field_state) =
          if Inttab.is_empty fields then (tye_idx, fs)
          else
            let
              fun round this next tye_idx decided fields index =
                (case Inttab.min this of
                  NONE =>
                    if Inttab.is_empty next then
                      (tye_idx,
                        {decided = decided,
                         waiting = {fields = fields, index = index, stamp = stamp}})
                    else round next Inttab.empty tye_idx decided fields index
                | SOME (st, ()) =>
                    let
                      val this' = Inttab.delete st this;
                      val key = the (Inttab.lookup fields st);
                    in
                      (case decide tye_idx key of
                        Dot_Field.Choose g =>
                          let
                            val (tye_idx', decided') = decide_late learnt0 key g (tye_idx, decided);
                            val (cands, index') = Dot_Field.take_bound (#1 tye_idx') index;
                            val (this'', next') =
                              Inttab.fold (fn (s, ()) => fn (th, nx) =>
                                if s > st then (Inttab.insert_set s th, nx)
                                else (th, Inttab.insert_set s nx)) cands (this', next);
                          in
                            round this'' next' tye_idx' decided' (Inttab.delete st fields) index'
                          end
                      | Dot_Field.Wait =>
                          round this' next tye_idx decided fields
                            (Dot_Field.place (#1 tye_idx) st (objT_of key) index)
                      | d => error (field_error_msg tye_idx key d))
                    end);
              val (cands, index') = Dot_Field.take_bound (#1 tye_idx) index;
            in round cands Inttab.empty tye_idx decided fields index' end;

        fun inf bs t state =
          (case dest_access t of
            SOME {key, objT, resT, node, obj, ...} =>
              let
                val (U, (tye_idx, {decided, waiting})) = inf bs obj state;
                (*the payload's type is the constant's first argument type, so that a carrier in
                  a message is a well-typed application*)
                val tye_idx' =
                  unify ctxt (objT, U) tye_idx
                  |> (case node of
                      Const (_, T) $ p $ _ => unify ctxt (fastype_of p, domain_type T)
                    | _ => I);
                val choice =
                  (case Vartab.lookup decided key of
                    SOME g => SOME g
                  | NONE =>
                      (case decide tye_idx' key of
                        Dot_Field.Choose g => SOME g
                      | Dot_Field.Wait => NONE
                      | d => error (field_error_msg tye_idx' key d)));
              in
                (case choice of
                  SOME g =>
                    let
                      val g' = Dot_Field.node_instance key g;
                      val (Tg, state') =
                        inf bs g'
                          (tye_idx', {decided = Vartab.update (key, g) decided, waiting = waiting});
                    in app bs (g', Tg) (obj, U) state' end
                | NONE =>
                    (resT,
                      (tye_idx',
                        {decided = decided, waiting = add_waiting (#1 tye_idx') key waiting})))
              end
          | NONE => inf_plain bs t state)
        and inf_plain _ (Const (_, T)) state = (T, state)
          | inf_plain _ (Free (_, T)) state = (T, state)
          | inf_plain _ (Var (_, T)) state = (T, state)
          | inf_plain bs (Bound i) state =
              (snd (nth bs i handle General.Subscript => err_loose i), state)
          | inf_plain bs (Abs (x, T, t)) state =
              let val (U, state') = inf ((x, T) :: bs) t state
              in (T --> U, state') end
          | inf_plain bs (t $ u) state =
              let
                val (T, state') = inf bs t state;
                val (U, state'') = inf bs u state';
              in app bs (t, T) (u, U) state'' end
        and app bs (t, T) (u, U) ((tye, idx), fs as {decided, ...}: field_state) =
          let
            val V = Type_Infer.mk_param idx [];
            val tye_idx = unify ctxt (U --> V, T) (tye, idx + 1)
              handle NO_UNIFIER (msg, tye') =>
                err_appl ctxt msg tye' bs (Dot_Field.explicit decided t) T
                  (Dot_Field.explicit decided u) U;
          in (V, resolve tye_idx fs) end;

        val (tye_idx, {decided, waiting = {fields, ...}}) =
          fold (fn t => fn state => #2 (inf [] t state)) ts
            ((Vartab.empty, idx0), {decided = decided0, waiting = no_waiting_fields});

        (*the choices of a learning run on this typing for the fields still undecided*)
        fun learn tye_idx decided =
          let
            val (_, out) =
              Type_Infer.finish ctxt (#1 tye_idx) ([], map (Dot_Field.explicit decided) ts);
          in Dot_Field.learn I engine ctxt accs out end;

        fun finish_waiting tye_idx (decided, learnt) [] = (tye_idx, decided, learnt)
          | finish_waiting tye_idx (decided, learnt) (key :: keys) =
              if Vartab.defined decided key then finish_waiting tye_idx (decided, learnt) keys
              else
                (case decide tye_idx key of
                  Dot_Field.Choose g =>
                    let val (tye_idx', decided') = decide_late learnt key g (tye_idx, decided)
                    in finish_waiting tye_idx' (decided', learnt) keys end
                | d as Dot_Field.Wait =>
                    let val new = learn tye_idx decided in
                      if Vartab.is_empty new then error (field_error_msg tye_idx key d)
                      else
                        let
                          val learnt' = Vartab.fold (Vartab.insert_set o #1) new learnt;
                          val (tye_idx', decided') =
                            Vartab.fold (fn (k, g) => decide_late learnt' k g) new
                              (tye_idx, decided);
                        in finish_waiting tye_idx' (decided', learnt') (key :: keys) end
                    end
                | d => error (field_error_msg tye_idx key d));

        val (tye_idx', decided', learnt) =
          finish_waiting tye_idx (decided, learnt0) (map #2 (Inttab.dest fields));

        (*a learnt field has its last check at stage 1, on its marker*)
        val _ =
          Dot_Field.last_check ctxt engine tye_idx' accs
            (Vartab.fold (Vartab.delete_safe o #1) learnt decided');
      in (#1 tye_idx', decided', learnt) end;

    fun attempt (decided, learnt) =
      run (decided, learnt) handle LATE_CLASH clash => attempt clash;
    val (tye, decided, learnt) = attempt (Vartab.empty, Vartab.empty);

    val markers =
      Vartab.fold (fn (key, ()) => cons (Dot_Field.marker ctxt engine tye (the_access key)))
        learnt [];
    val (_, ts') = Type_Infer.finish ctxt tye ([], map (Dot_Field.explicit decided) ts @ markers);
  in (ts', (accs, decided)) end;


(* checks *)

(*stage 0 "standard": stock's function, or with field accesses the standard engine
  (Dot_Field.selection_check).  check: how a stage-0 function becomes a check (Syntax_Phases)*)
fun standard_check check ts ctxt =
  let
    fun standard record ctxt' =
      infer_types ctxt' #> record #> map (Proof_Context.expand_abbrevs ctxt');
  in
    if not (Config.get ctxt Dot_Field.dot_syntax) orelse not (exists Dot_Field.has_access ts)
    then check (standard I) ts ctxt
    else
      (case Dot_Field.learning ctxt of
        SOME record => check (standard (tap record)) ts ctxt
      | NONE =>
          Dot_Field.selection_check
            (fn ctxt' => infer_fields ctxt' #>> map (Proof_Context.expand_abbrevs ctxt')) ts ctxt)
  end;

(*stage 1: a field access ends a learning run; the last check of the learnt fields on their
  objects' final types; a field access that no engine resolved*)
fun dot_check ts ctxt =
  if not (Config.get ctxt Dot_Field.dot_syntax) then NONE
  else
    let val carriers = exists Dot_Field.has_access ts in
      if carriers andalso is_some (Dot_Field.learning ctxt) then raise Dot_Field.LEARNT
      else if carriers orelse exists Dot_Field.is_marker ts then
        let
          val engine = dot_engine ctxt;
          val ts' = Dot_Field.check_markers ctxt engine ts;
          val _ = Dot_Field.report_unresolved ctxt engine (K true) ts';
        in if length ts' = length ts then NONE else SOME (ts', ctxt) end
      else NONE
    end;

end;
