(*  Title:      Tools/subtyping.ML
    Author:     Dmitriy Traytel, TU Muenchen

Coercive subtyping via subtype constraints.
*)

signature SUBTYPING =
sig
  val coercion_enabled: bool Config.T
  val add_type_map: term -> Context.generic -> Context.generic
  val add_coercion: term -> Context.generic -> Context.generic
  val print_coercions: Proof.context -> unit
end;

(*the coercion data; the inference is functor Coercion_Inference below*)
structure Subtyping_Base =
struct

(** coercions data **)

datatype variance = COVARIANT | CONTRAVARIANT | INVARIANT | INVARIANT_TO of typ;
datatype coerce_arg = PERMIT | FORBID | LEAVE

datatype data = Data of
  {coes: (term * ((typ list * typ list) * term list)) Symreltab.table,  (*coercions table*)
   (*full coercions graph - only used at coercion declaration/deletion*)
   full_graph: int Graph.T,
   (*coercions graph restricted to base types - for efficiency reasons stored in the context*)
   coes_graph: int Graph.T,
   tmaps: (term * variance list) Symtab.table,  (*map functions*)
   coerce_args: coerce_arg list Symtab.table  (*special constants with non-coercible arguments*)};

fun make_data (coes, full_graph, coes_graph, tmaps, coerce_args) =
  Data {coes = coes, full_graph = full_graph, coes_graph = coes_graph,
    tmaps = tmaps, coerce_args = coerce_args};

fun merge_error_coes (a, b) =
  error ("Cannot merge coercion tables.\nConflicting declarations for coercions from " ^
    quote a ^ " to " ^ quote b ^ ".");

fun merge_error_tmaps C =
  error ("Cannot merge coercion map tables.\nConflicting declarations for the constructor " ^
    quote C ^ ".");

fun merge_error_coerce_args C =
  error ("Cannot merge tables for constants with coercion-invariant arguments.\n" ^
    "Conflicting declarations for the constant " ^ quote C ^ ".");

structure Data = Generic_Data
(
  type T = data;
  val empty = make_data (Symreltab.empty, Graph.empty, Graph.empty, Symtab.empty, Symtab.empty);
  fun merge
    (Data {coes = coes1, full_graph = full_graph1, coes_graph = coes_graph1,
      tmaps = tmaps1, coerce_args = coerce_args1},
      Data {coes = coes2, full_graph = full_graph2, coes_graph = coes_graph2,
        tmaps = tmaps2, coerce_args = coerce_args2}) =
    make_data (Symreltab.merge (eq_pair (op aconv)
        (eq_pair (eq_pair (eq_list (op =)) (eq_list (op =))) (eq_list (op aconv))))
        (coes1, coes2) handle Symreltab.DUP key => merge_error_coes key,
      Graph.merge (op =) (full_graph1, full_graph2),
      Graph.merge (op =) (coes_graph1, coes_graph2),
      Symtab.merge (eq_pair (op aconv) (op =)) (tmaps1, tmaps2)
        handle Symtab.DUP key => merge_error_tmaps key,
      Symtab.merge (eq_list (op =)) (coerce_args1, coerce_args2)
        handle Symtab.DUP key => merge_error_coerce_args key);
);

fun map_data f =
  Data.map (fn Data {coes, full_graph, coes_graph, tmaps, coerce_args} =>
    make_data (f (coes, full_graph, coes_graph, tmaps, coerce_args)));

fun map_coes_and_graphs f =
  map_data (fn (coes, full_graph, coes_graph, tmaps, coerce_args) =>
    let val (coes', full_graph', coes_graph') = f (coes, full_graph, coes_graph);
    in (coes', full_graph', coes_graph', tmaps, coerce_args) end);

fun map_tmaps f =
  map_data (fn (coes, full_graph, coes_graph, tmaps, coerce_args) =>
    (coes, full_graph, coes_graph, f tmaps, coerce_args));

fun map_coerce_args f =
  map_data (fn (coes, full_graph, coes_graph, tmaps, coerce_args) =>
    (coes, full_graph, coes_graph, tmaps, f coerce_args));

val rep_data = (fn Data args => args) o Data.get o Context.Proof;

val coes_of = #coes o rep_data;
val coes_graph_of = #coes_graph o rep_data;
val tmaps_of = #tmaps o rep_data;
val coerce_args_of = #coerce_args o rep_data;


(** hooks **)

(*what the instances of Coercion_Inference with "observed" or "learning" do beyond stock*)

type tye_idx = typ Vartab.table * int;
type constraint = (typ * typ) * ((string * typ) list * term * typ * typ * typ);
type gen = bool -> constraint list -> (string * typ) list -> term -> tye_idx ->
  typ * tye_idx * constraint list;
type app = bool -> constraint list -> (string * typ) list -> term * typ -> term * typ -> tye_idx ->
  typ * tye_idx * constraint list;

type hooks =
 {(*observed: the operator and the operand's type of every application*)
  observe: term -> typ -> unit,
  (*learning: generation at a carrier (NONE: stock's generation), given stock's generation, its
    constraints of an application and its error message*)
  carrier: gen -> app -> (unit -> string * Buffer.T) -> bool -> constraint list ->
    (string * typ) list -> term -> tye_idx -> (typ * tye_idx * constraint list) option,
  (*learning: a subtype constraint that a learning run drops instead of failing on it, when weak
    unification fails on it*)
  tolerate_weak: typ Vartab.table -> typ * typ -> bool,
  (*learning: after simplification (false) and after solving (true), given the simplified
    constraints, the typing before solving and the current typing*)
  learn: bool -> constraint list -> typ Vartab.table -> tye_idx -> unit,
  (*learning: the term shown for an application in a bound error*)
  explain: term -> term};

val no_hooks: hooks =
 {observe = K (K ()), carrier = K (K (K (K (K (K (K (K NONE))))))), tolerate_weak = K (K false),
  learn = K (K (K (K ()))), explain = I};

(*the hooks of the observed instance and of the learning instance; the other hooks no_hooks'*)
fun observe_hooks observe: hooks =
 {observe = observe, carrier = #carrier no_hooks, tolerate_weak = #tolerate_weak no_hooks,
  learn = #learn no_hooks, explain = #explain no_hooks};

fun learning_hooks {carrier, tolerate_weak, learn, explain}: hooks =
 {observe = #observe no_hooks, carrier = carrier, tolerate_weak = tolerate_weak, learn = learn,
  explain = explain};

end;


(*observed: the operator and the operand's type of each application go to the hook observe;
  learning: generation with carriers, tolerance and learning; neither: stock's coercion inference*)
functor Coercion_Inference(val observed: bool val learning: bool) =
struct

open Subtyping_Base;


(** utils **)

fun restrict_graph G = Graph.restrict (fn x => Graph.get_node G x = 0) G;

fun nameT (Type (s, [])) = s;
fun t_of s = Type (s, []);

fun sort_of (TFree (_, S)) = SOME S
  | sort_of (TVar (_, S)) = SOME S
  | sort_of _ = NONE;

val is_typeT = fn (Type _) => true | _ => false;
val is_compT = fn (Type (_, _ :: _)) => true | _ => false;
val is_freeT = fn (TFree _) => true | _ => false;
val is_fixedvarT = fn (TVar (xi, _)) => not (Type_Infer.is_param xi) | _ => false;
val is_funtype = fn (Type ("fun", [_, _])) => true | _ => false;

fun mk_identity T = Abs (Name.uu, T, Bound 0);
val is_identity = fn (Abs (_, _, Bound 0)) => true | _ => false;

fun instantiate t Ts = Term.subst_TVars
  ((Term.add_tvar_namesT (fastype_of t) []) ~~ rev Ts) t;

exception COERCION_GEN_ERROR of unit -> string * Buffer.T;

infixr ++>  (*composition with deferred error message*)
fun (err : unit -> string * Buffer.T) ++> s =
  err #> apsnd (Buffer.add s);

fun eval_err err =
  let val (s, buf) = err ()
  in s ^ Markup.markup Markup.text_fold (Buffer.content buf) end;

fun eval_error err = error (eval_err err);

fun inst_collect tye err T U =
  (case (T, Type_Infer.deref tye U) of
    (TVar (xi, _), U) => [(xi, U)]
  | (Type (a, Ts), Type (b, Us)) =>
      if a <> b then eval_error err else inst_collects tye err Ts Us
  | (_, U') => if T <> U' then eval_error err else [])
and inst_collects tye err Ts Us =
  fold2 (fn T => fn U => fn is => inst_collect tye err T U @ is) Ts Us [];


(* unification *)

exception NO_UNIFIER of string * typ Vartab.table;

fun unify weak ctxt =
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

    val weak_meet = if weak then fn _ => I else meet;


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
          else env |> weak_meet (T, S) |>> Vartab.update_new (xi, T)
      | assign xi T S (env as (tye, _)) =
          (occurs_check tye xi T; env |> weak_meet (T, S) |>> Vartab.update_new (xi, T));


    (* unification *)

    fun show_tycon (a, Ts) =
      quote (Syntax.string_of_typ ctxt (Type (a, replicate (length Ts) dummyT)));

    fun unif (T1, T2) (env as (tye, _)) =
      (case apply2 (`Type_Infer.is_paramT o Type_Infer.deref tye) (T1, T2) of
        ((true, TVar (xi, S)), (_, T)) => assign xi T S env
      | ((_, T), (true, TVar (xi, S))) => assign xi T S env
      | ((_, Type (a, Ts)), (_, Type (b, Us))) =>
          if weak andalso null Ts andalso null Us then env
          else if a <> b then
            raise NO_UNIFIER
              ("Clash of types " ^ show_tycon (a, Ts) ^ " and " ^ show_tycon (b, Us), tye)
          else fold unif (Ts ~~ Us) env
      | ((_, T), (_, U)) => if T = U then env else raise NO_UNIFIER ("", tye));

  in unif end;

val weak_unify = unify true;
val strong_unify = unify false;


(* Typ_Graph shortcuts *)

fun get_preds G T = Typ_Graph.all_preds G [T];
fun get_succs G T = Typ_Graph.all_succs G [T];
fun maybe_new_typnode T G = perhaps (try (Typ_Graph.new_node (T, ()))) G;
fun maybe_new_typnodes Ts G = fold maybe_new_typnode Ts G;
fun new_imm_preds G Ts =  (* FIXME inefficient *)
  subtract (op =) Ts (distinct (op =) (maps (Typ_Graph.immediate_preds G) Ts));
fun new_imm_succs G Ts =  (* FIXME inefficient *)
  subtract (op =) Ts (distinct (op =) (maps (Typ_Graph.immediate_succs G) Ts));


(* Graph shortcuts *)

fun maybe_new_node s G = perhaps (try (Graph.new_node s)) G;
fun maybe_new_nodes ss G = fold maybe_new_node ss G;



(** error messages **)

fun gen_err err msg =
  err ++> ("\nNow trying to infer coercions globally.\n\nCoercion inference failed" ^
    (if msg = "" then "" else ":\n" ^ msg) ^ "\n");

val gen_msg = eval_err oo gen_err

fun prep_output ctxt tye bs ts Ts =
  let
    val (Ts_bTs', ts') = Type_Infer.finish ctxt tye (Ts @ map snd bs, ts);
    val (Ts', Ts'') = chop (length Ts) Ts_bTs';
    fun prep t =
      let val xs = rev (Syntax_Trans.variant_bounds ctxt t (rev (map fst bs ~~ Ts'')))
      in Term.subst_bounds (map Syntax_Trans.mark_bound_abs xs, t) end;
  in (map prep ts', Ts') end;

fun err_loose i = error ("Loose bound variable: B." ^ string_of_int i);

fun unif_failed msg =
  "Type unification failed" ^ (if msg = "" then "" else ": " ^ msg) ^ "\n\n";

fun err_appl_msg ctxt msg tye bs t T u U () =
  let val ([t', u'], [T', U']) = prep_output ctxt tye bs [t, u] [T, U] in
    (unif_failed msg ^ Type.appl_error ctxt t' T' u' U' ^ "\n\n",
      Buffer.empty |> Buffer.add "Coercion Inference:\n\n")
  end;

fun err_list ctxt err tye Ts =
  let val (_, Ts') = prep_output ctxt tye [] [] Ts in
    eval_error (err ++>
      ("\nCannot unify a list of types that should be the same:\n" ^
        Pretty.string_of (Pretty.list "[" "]" (map (Syntax.pretty_typ ctxt) Ts'))))
  end;

fun err_bound ctxt err tye packs =
  let
    val (ts, Ts) = fold
      (fn (bs, t $ u, U, _, U') => fn (ts, Ts) =>
        let val (t', T') = prep_output ctxt tye bs [t, u] [U', U]
        in (t' :: ts, T' :: Ts) end)
      packs ([], []);
    val msg =
      Pretty.string_of (Pretty.big_list "Cannot fulfil subtype constraints:"
        (map2 (fn [t, u] => fn [T, U] =>
          Pretty.block [
            Syntax.pretty_typ ctxt T, Pretty.brk 2, Pretty.str "<:", Pretty.brk 2,
            Syntax.pretty_typ ctxt U, Pretty.brk 3,
            Pretty.str "from function application", Pretty.brk 2,
            Pretty.block [Syntax.pretty_term ctxt (t $ u)]])
          ts Ts));
  in eval_error (err ++> ("\n" ^ msg)) end;



(** constraint generation **)

(*the flag of the argument that follows n arguments of the head f; old: the outer flag*)
fun coerce_arg ctxt old (f, n) =
  let
    val mk_coerce_args = the_default [] o Symtab.lookup (coerce_args_of ctxt);
    fun update _ [] = old
      | update 0 (coerce :: _) = (case coerce of LEAVE => old | PERMIT => true | FORBID => false)
      | update n (_ :: cs) = update (n - 1) cs;
  in
    update n (case f of Const (name, _) => mk_coerce_args name | _ => [])
  end;

fun update_coerce_arg ctxt old t =
  coerce_arg ctxt old (Term.strip_comb (Type.strip_constraints t) ||> length);

fun generate_constraints ctxt err (hooks: hooks) =
  let
    fun app coerce' cs'' bs (t, T) (u, U') (tye, idx) =
      let
        val U = Type_Infer.mk_param idx [];
        val V = Type_Infer.mk_param (idx + 1) [];
        val tye_idx'' = strong_unify ctxt (U --> V, T) (tye, idx + 2)
          handle NO_UNIFIER (msg, _) => error (gen_msg err msg);
        val error_pack = (bs, t $ u, U, V, U');
      in
        if coerce'
        then (V, tye_idx'', ((U', U), error_pack) :: cs'')
        else (V,
          strong_unify ctxt (U, U') tye_idx''
            handle NO_UNIFIER (msg, _) => error (gen_msg err msg),
          cs'')
      end;

    fun gen coerce cs bs t tye_idx =
      (case if learning then #carrier hooks gen app err coerce cs bs t tye_idx else NONE of
        SOME res => res
      | NONE => gen_stock coerce cs bs t tye_idx)
    and gen_stock _ cs _ (Const (_, T)) tye_idx = (T, tye_idx, cs)
      | gen_stock _ cs _ (Free (_, T)) tye_idx = (T, tye_idx, cs)
      | gen_stock _ cs _ (Var (_, T)) tye_idx = (T, tye_idx, cs)
      | gen_stock _ cs bs (Bound i) tye_idx =
          (snd (nth bs i handle General.Subscript => err_loose i), tye_idx, cs)
      | gen_stock coerce cs bs (Abs (x, T, t)) tye_idx =
          let val (U, tye_idx', cs') = gen coerce cs ((x, T) :: bs) t tye_idx
          in (T --> U, tye_idx', cs') end
      | gen_stock coerce cs bs (t $ u) tye_idx =
          let
            val (T, tye_idx', cs') = gen coerce cs bs t tye_idx;
            val coerce' = update_coerce_arg ctxt coerce t;
            val (U', tye_idx'', cs'') = gen coerce' cs' bs u tye_idx';
            val _ = if observed then #observe hooks t U' else ();
          in app coerce' cs'' bs (t, T) (u, U') tye_idx'' end;
  in
    gen true [] []
  end;



(** constraint resolution **)

exception BOUND_ERROR of string;

fun process_constraints ctxt err (hooks: hooks) cs0 tye_idx =
  let
    val err_bound = fn ctxt => fn err => fn tye => fn packs =>
      err_bound ctxt err tye
        (if learning then map (fn (bs, tu, U, V, U') => (bs, #explain hooks tu, U, V, U')) packs
         else packs);
    val thy = Proof_Context.theory_of ctxt;

    val coes_graph = coes_graph_of ctxt;
    val tmaps = tmaps_of ctxt;
    val arity_sorts = Proof_Context.arity_sorts ctxt;

    fun split_cs _ [] = ([], [])
      | split_cs f (c :: cs) =
          (case apply2 f (fst c) of
            (false, false) => apsnd (cons c) (split_cs f cs)
          | _ => apfst (cons c) (split_cs f cs));

    fun unify_list (T :: Ts) tye_idx =
      fold (fn U => fn tye_idx' => strong_unify ctxt (T, U) tye_idx') Ts tye_idx;


    (* check whether constraint simplification will terminate using weak unification *)

    fun weak_check (c as (TU, _)) tye_idx =
      (SOME c, weak_unify ctxt TU tye_idx) handle NO_UNIFIER (msg, _) =>
        if learning andalso #tolerate_weak hooks (fst tye_idx) TU then (NONE, tye_idx)
        else error (gen_msg err ("weak unification of subtype constraints fails\n" ^ msg));
    val cs = map_filter I (fst (fold_map weak_check cs0 tye_idx));


    (* simplify constraints *)

    fun simplify_constraints cs tye_idx =
      let
        fun contract a Ts Us error_pack done todo tye idx =
          let
            val arg_var =
              (case Symtab.lookup tmaps a of
                (*everything is invariant for unknown constructors*)
                NONE => replicate (length Ts) INVARIANT
              | SOME av => snd av);
            fun new_constraints (variance, constraint) (cs, tye_idx) =
              (case variance of
                COVARIANT => (constraint :: cs, tye_idx)
              | CONTRAVARIANT => (swap constraint :: cs, tye_idx)
              | INVARIANT_TO T => (cs, unify_list [T, fst constraint, snd constraint] tye_idx
                  handle NO_UNIFIER (msg, _) =>
                    err_list ctxt (gen_err err
                      ("failed to unify invariant arguments w.r.t. to the known map function\n" ^
                        msg))
                      (fst tye_idx) (T :: Ts))
              | INVARIANT => (cs, strong_unify ctxt constraint tye_idx
                  handle NO_UNIFIER (msg, _) =>
                    error (gen_msg err ("failed to unify invariant arguments\n" ^ msg))));
            val (new, (tye', idx')) = apfst (fn cs => (cs ~~ replicate (length cs) error_pack))
              (fold new_constraints (arg_var ~~ (Ts ~~ Us)) ([], (tye, idx)));
            val test_update = is_typeT orf is_freeT orf is_fixedvarT;
            val (ch, done') =
              done
              |> map (apfst (apply2 (Type_Infer.deref tye')))
              |> (if not (null new) then rpair []  else split_cs test_update);
            val todo' = ch @ todo;
          in
            simplify done' (new @ todo') (tye', idx')
          end
        (*xi is definitely a parameter*)
        and expand varleq xi S a Ts error_pack done todo tye idx =
          let
            val n = length Ts;
            val args = map2 Type_Infer.mk_param (idx upto idx + n - 1) (arity_sorts a S);
            val tye' = Vartab.update_new (xi, Type(a, args)) tye;
            val (ch, done') = split_cs (is_compT o Type_Infer.deref tye') done;
            val todo' = ch @ todo;
            val new =
              if varleq then (Type(a, args), Type (a, Ts))
              else (Type (a, Ts), Type (a, args));
          in
            simplify done' ((new, error_pack) :: todo') (tye', idx + n)
          end
        (*TU is a pair of a parameter and a free/fixed variable*)
        and eliminate TU done todo tye idx =
          let
            val [TVar (xi, S)] = filter Type_Infer.is_paramT TU;
            val [T] = filter_out Type_Infer.is_paramT TU;
            val SOME S' = sort_of T;
            val test_update = if is_freeT T then is_freeT else is_fixedvarT;
            val tye' = Vartab.update_new (xi, T) tye;
            val (ch, done') = split_cs (test_update o Type_Infer.deref tye') done;
            val todo' = ch @ todo;
          in
            if Sign.subsort thy (S', S) (*TODO check this*)
            then simplify done' todo' (tye', idx)
            else error (gen_msg err "sort mismatch")
          end
        and simplify done [] tye_idx = (done, tye_idx)
          | simplify done (((T, U), error_pack) :: todo) (tye_idx as (tye, idx)) =
              (case (Type_Infer.deref tye T, Type_Infer.deref tye U) of
                (T1 as Type (a, []), T2 as Type (b, [])) =>
                  if a = b then simplify done todo tye_idx
                  else if Graph.is_edge coes_graph (a, b) then simplify done todo tye_idx
                  else
                    error (gen_msg err (quote (Syntax.string_of_typ ctxt T1) ^
                      " is not a subtype of " ^ quote (Syntax.string_of_typ ctxt T2)))
              | (Type (a, Ts), Type (b, Us)) =>
                  if a <> b then
                    error (gen_msg err "different constructors") (fst tye_idx) error_pack
                  else contract a Ts Us error_pack done todo tye idx
              | (TVar (xi, S), Type (a, Ts as (_ :: _))) =>
                  expand true xi S a Ts error_pack done todo tye idx
              | (Type (a, Ts as (_ :: _)), TVar (xi, S)) =>
                  expand false xi S a Ts error_pack done todo tye idx
              | (T, U) =>
                  if T = U then simplify done todo tye_idx
                  else if exists (is_freeT orf is_fixedvarT) [T, U] andalso
                    exists Type_Infer.is_paramT [T, U]
                  then eliminate [T, U] done todo tye idx
                  else if exists (is_freeT orf is_fixedvarT) [T, U]
                  then error (gen_msg err "not eliminated free/fixed variables")
                  else simplify (((T, U), error_pack) :: done) todo tye_idx);
      in
        simplify [] cs tye_idx
      end;


    (* do simplification *)

    val (cs', tye_idx') = simplify_constraints cs tye_idx;

    fun find_error_pack lower T' = map_filter
      (fn ((T, U), pack) => if if lower then T' = U else T' = T then SOME pack else NONE) cs';

    fun find_cycle_packs nodes =
      let
        val (but_last, last) = split_last nodes
        val pairs = (last, hd nodes) :: (but_last ~~ tl nodes);
      in
        map_filter
          (fn (TU, pack) => if member (op =) pairs TU then SOME pack else NONE)
          cs'
      end;

    (*styps stands either for supertypes or for subtypes of a type T
      in terms of the subtype-relation (excluding T itself)*)
    fun styps super T =
      (if super then Graph.immediate_succs else Graph.immediate_preds) coes_graph T
        handle Graph.UNDEF _ => [];

    fun minmax sup (T :: Ts) =
      let
        fun adjust T U = if sup then (T, U) else (U, T);
        fun extract T [] = T
          | extract T (U :: Us) =
              if Graph.is_edge coes_graph (adjust T U) then extract T Us
              else if Graph.is_edge coes_graph (adjust U T) then extract U Us
              else raise BOUND_ERROR "uncomparable types in type list";
      in
        t_of (extract T Ts)
      end;

    fun ex_styp_of_sort super T styps_and_sorts =
      let
        fun adjust T U = if super then (T, U) else (U, T);
        fun styp_test U Ts = forall
          (fn T => T = U orelse Graph.is_edge coes_graph (adjust U T)) Ts;
        fun fitting Ts S U = Sign.of_sort thy (t_of U, S) andalso styp_test U Ts;
      in
        forall (fn (Ts, S) => exists (fitting Ts S) (T :: styps super T)) styps_and_sorts
      end;

    (* computes the tightest possible, correct assignment for 'a::S
       e.g. in the supremum case (sup = true):
               ------- 'a::S---
              /        /    \  \
             /        /      \  \
        'b::C1   'c::C2 ...  T1 T2 ...

       sorts - list of sorts [C1, C2, ...]
       T::Ts - non-empty list of base types [T1, T2, ...]
    *)
    fun tightest sup S styps_and_sorts (T :: Ts) =
      let
        fun restriction T = Sign.of_sort thy (t_of T, S)
          andalso ex_styp_of_sort (not sup) T styps_and_sorts;
        fun candidates T = inter (op =) (filter restriction (T :: styps sup T));
      in
        (case fold candidates Ts (filter restriction (T :: styps sup T)) of
          [] => raise BOUND_ERROR ("no " ^ (if sup then "supremum" else "infimum"))
        | [T] => t_of T
        | Ts => minmax sup Ts)
      end;

    fun build_graph G [] tye_idx = (G, tye_idx)
      | build_graph G ((T, U) :: cs) tye_idx =
        if T = U then build_graph G cs tye_idx
        else
          let
            val G' = maybe_new_typnodes [T, U] G;
            val (G'', tye_idx') = (Typ_Graph.add_edge_acyclic (T, U) G', tye_idx)
              handle Typ_Graph.CYCLES cycles =>
                let
                  val (tye, idx) =
                    fold
                      (fn cycle => fn tye_idx' => (unify_list cycle tye_idx'
                        handle NO_UNIFIER (msg, _) =>
                          err_bound ctxt
                            (gen_err err ("constraint cycle not unifiable\n" ^ msg)) (fst tye_idx)
                            (find_cycle_packs cycle)))
                      cycles tye_idx
                in
                  collapse (tye, idx) cycles G
                end
          in
            build_graph G'' cs tye_idx'
          end
    and collapse (tye, idx) cycles G = (*nodes non-empty list*)
      let
        (*all cycles collapse to one node,
          because all of them share at least the nodes x and y*)
        val nodes = (distinct (op =) (flat cycles));
        val T = Type_Infer.deref tye (hd nodes);
        val P = new_imm_preds G nodes;
        val S = new_imm_succs G nodes;
        val G' = fold Typ_Graph.del_node (tl nodes) G;
        fun check_and_gen super T' =
          let val U = Type_Infer.deref tye T';
          in
            if not (is_typeT T) orelse not (is_typeT U) orelse T = U
            then if super then (hd nodes, T') else (T', hd nodes)
            else
              if super andalso
                Graph.is_edge coes_graph (nameT T, nameT U) then (hd nodes, T')
              else if not super andalso
                Graph.is_edge coes_graph (nameT U, nameT T) then (T', hd nodes)
              else
                err_bound ctxt (gen_err err "cycle elimination produces inconsistent graph")
                  (fst tye_idx)
                  (maps find_cycle_packs cycles @ find_error_pack super T')
          end;
      in
        build_graph G' (map (check_and_gen false) P @ map (check_and_gen true) S) (tye, idx)
      end;

    fun assign_bound lower G key (tye_idx as (tye, _)) =
      if Type_Infer.is_paramT (Type_Infer.deref tye key) then
        let
          val TVar (xi, S) = Type_Infer.deref tye key;
          val get_bound = if lower then get_preds else get_succs;
          val raw_bound = get_bound G key;
          val bound = map (Type_Infer.deref tye) raw_bound;
          val not_params = filter_out Type_Infer.is_paramT bound;
          fun to_fulfil T =
            (case sort_of T of
              NONE => NONE
            | SOME S =>
                SOME
                  (map nameT
                    (filter_out Type_Infer.is_paramT
                      (map (Type_Infer.deref tye) (get_bound G T))), S));
          val styps_and_sorts = distinct (op =) (map_filter to_fulfil raw_bound);
          val assignment =
            if null bound orelse null not_params then NONE
            else SOME (tightest lower S styps_and_sorts (map nameT not_params)
                handle BOUND_ERROR msg => err_bound ctxt (gen_err err msg) tye
                  (maps (find_error_pack (not lower)) raw_bound));
        in
          (case assignment of
            NONE => tye_idx
          | SOME T =>
              if Type_Infer.is_paramT T then tye_idx
              else if lower then (*upper bound check*)
                let
                  val other_bound = map (Type_Infer.deref tye) (get_succs G key);
                  val s = nameT T;
                in
                  if subset (op = o apfst nameT) (filter is_typeT other_bound, s :: styps true s)
                  then apfst (Vartab.update (xi, T)) tye_idx
                  else
                    err_bound ctxt
                      (gen_err err
                        (Pretty.string_of (Pretty.block
                          [Pretty.str "assigned base type", Pretty.brk 1,
                            Pretty.quote (Syntax.pretty_typ ctxt T), Pretty.brk 1,
                            Pretty.str "clashes with the upper bound of variable", Pretty.brk 1,
                            Syntax.pretty_typ ctxt (TVar (xi, S))])))
                      tye
                      (maps (find_error_pack lower) other_bound)
                end
              else apfst (Vartab.update (xi, T)) tye_idx)
        end
      else tye_idx;

    val assign_lb = assign_bound true;
    val assign_ub = assign_bound false;

    fun assign_alternating ts' ts G tye_idx =
      if ts' = ts then tye_idx
      else
        let
          val (tye_idx' as (tye, _)) = fold (assign_lb G) ts tye_idx
            |> fold (assign_ub G) ts;
        in
          assign_alternating ts
            (filter (Type_Infer.is_paramT o Type_Infer.deref tye) ts) G tye_idx'
        end;

    (*Unify all weakly connected components of the constraint forest,
      that contain only params. These are the only WCCs that contain
      params anyway.*)
    fun unify_params G (tye_idx as (tye, _)) =
      let
        val max_params =
          filter (Type_Infer.is_paramT o Type_Infer.deref tye) (Typ_Graph.maximals G);
        val to_unify = map (fn T => T :: get_preds G T) max_params;
      in
        fold
          (fn Ts => fn tye_idx' => unify_list Ts tye_idx'
            handle NO_UNIFIER (msg, _) => err_list ctxt (gen_err err msg) (fst tye_idx) Ts)
          to_unify tye_idx
      end;

    fun solve_constraints G tye_idx = tye_idx
      |> assign_alternating [] (Typ_Graph.keys G) G
      |> unify_params G;

    val _ = if learning then #learn hooks false cs' (fst tye_idx') tye_idx' else ();
    val (G, tye_idx2) = build_graph Typ_Graph.empty (map fst cs') tye_idx';
    val tye_idx3 = solve_constraints G tye_idx2;
    val _ = if learning then #learn hooks true cs' (fst tye_idx2) tye_idx3 else ();
  in tye_idx3 end;



(** coercion insertion **)

fun gen_coercion ctxt err tye TU =
  let
    fun gen (T1, T2) =
      (case apply2 (Type_Infer.deref tye) (T1, T2) of
        (T1 as (Type (a, [])), T2 as (Type (b, []))) =>
            if a = b
            then mk_identity T1
            else
              (case Symreltab.lookup (coes_of ctxt) (a, b) of
                NONE =>
                  raise COERCION_GEN_ERROR (err ++>
                    (Pretty.string_of o Pretty.block)
                      [Pretty.quote (Syntax.pretty_typ ctxt T1), Pretty.brk 1,
                        Pretty.str "is not a subtype of", Pretty.brk 1,
                        Pretty.quote (Syntax.pretty_typ ctxt T2)])
              | SOME (co, _) => co)
      | (T1 as Type (a, Ts), T2 as Type (b, Us)) =>
            if a <> b
            then
              (case Symreltab.lookup (coes_of ctxt) (a, b) of
                (*immediate error - cannot fix complex coercion with the global algorithm*)
                NONE =>
                  eval_error (err ++>
                    ("No coercion known for type constructors: " ^
                      quote (Proof_Context.markup_type ctxt a) ^ " and " ^
                      quote (Proof_Context.markup_type ctxt b)))
              | SOME (co, ((Ts', Us'), _)) =>
                  let
                    val co_before = gen (T1, Type (a, Ts'));
                    val coT = range_type (fastype_of co_before);
                    val insts =
                      inst_collect tye (err ++> "Could not insert complex coercion")
                        (domain_type (fastype_of co)) coT;
                    val co' = Term.subst_TVars insts co;
                    val co_after = gen (Type (b, (map (typ_subst_TVars insts) Us')), T2);
                  in
                    Abs (Name.uu, T1, Library.foldr (op $)
                      (filter (not o is_identity) [co_after, co', co_before], Bound 0))
                  end)
            else
              let
                fun sub_co (COVARIANT, TU) = (SOME (gen TU), NONE)
                  | sub_co (CONTRAVARIANT, TU) = (SOME (gen (swap TU)), NONE)
                  | sub_co (INVARIANT, (T, _)) = (NONE, SOME T)
                  | sub_co (INVARIANT_TO T, _) = (NONE, NONE);
                fun ts_of [] = []
                  | ts_of (Type ("fun", [x1, x2]) :: xs) = x1 :: x2 :: (ts_of xs);
              in
                (case Symtab.lookup (tmaps_of ctxt) a of
                  NONE =>
                    if Type.could_unify (T1, T2)
                    then mk_identity T1
                    else
                      raise COERCION_GEN_ERROR
                        (err ++>
                          ("No map function for " ^ quote (Proof_Context.markup_type ctxt a)
                            ^ " known"))
                | SOME (tmap, variances) =>
                    let
                      val (used_coes, invarTs) =
                        map_split sub_co (variances ~~ (Ts ~~ Us))
                        |>> map_filter I
                        ||> map_filter I;
                      val Tinsts = ts_of (map fastype_of used_coes) @ invarTs;
                    in
                      if null (filter (not o is_identity) used_coes)
                      then mk_identity (Type (a, Ts))
                      else Term.list_comb (instantiate tmap Tinsts, used_coes)
                    end)
              end
      | (T, U) =>
            if Type.could_unify (T, U)
            then mk_identity T
            else raise COERCION_GEN_ERROR (err ++>
              (Pretty.string_of o Pretty.block)
               [Pretty.str "Cannot generate coercion from", Pretty.brk 1,
                Pretty.quote (Syntax.pretty_typ ctxt T), Pretty.brk 1,
                Pretty.str "to", Pretty.brk 1,
                Pretty.quote (Syntax.pretty_typ ctxt U)]));
  in
    gen TU
  end;

fun function_of ctxt err tye T =
  (case Type_Infer.deref tye T of
    Type (C, Ts) =>
      (case Symreltab.lookup (coes_of ctxt) (C, "fun") of
        NONE =>
          eval_error (err ++> ("No complex coercion from " ^
            quote (Proof_Context.markup_type ctxt C) ^ " to " ^
            quote (Proof_Context.markup_type ctxt "fun")))
      | SOME (co, ((Ts', _), _)) =>
        let
          val co_before = gen_coercion ctxt err tye (Type (C, Ts), Type (C, Ts'));
          val coT = range_type (fastype_of co_before);
          val insts =
            inst_collect tye (err ++> "Could not insert complex coercion")
              (domain_type (fastype_of co)) coT;
          val co' = Term.subst_TVars insts co;
        in
          Abs (Name.uu, Type (C, Ts), Library.foldr (op $)
            (filter (not o is_identity) [co', co_before], Bound 0))
        end)
  | T' =>
      eval_error (err ++>
        (Pretty.string_of o Pretty.block)
         [Pretty.str "No complex coercion from", Pretty.brk 1,
          Pretty.quote (Syntax.pretty_typ ctxt T'), Pretty.brk 1,
          Pretty.str "to", Pretty.brk 1, Proof_Context.pretty_type ctxt "fun"]));

fun insert_coercions ctxt (tye, idx) ts =
  let
    fun insert _ (Const (c, T)) = (Const (c, T), T)
      | insert _ (Free (x, T)) = (Free (x, T), T)
      | insert _ (Var (xi, T)) = (Var (xi, T), T)
      | insert bs (Bound i) =
          let val T = nth bs i handle General.Subscript => err_loose i;
          in (Bound i, T) end
      | insert bs (Abs (x, T, t)) =
          let val (t', T') = insert (T :: bs) t;
          in (Abs (x, T, t'), T --> T') end
      | insert bs (t $ u) =
          let
            val (t', Type ("fun", [U, T])) = apsnd (Type_Infer.deref tye) (insert bs t);
            val (u', U') = insert bs u;
          in
            if can (fn TU => strong_unify ctxt TU (tye, 0)) (U, U')
            then (t' $ u', T)
            else (t' $ (gen_coercion ctxt (K ("", Buffer.empty)) tye (U', U) $ u'), T)
          end
  in
    map (fst o insert []) ts
  end;



(** assembling the pipeline **)

(*the local pass's response when the step U --> V = T of the application of t' to an operand of
  type U fails with message err (V = the parameter idx): coerce the operator to a function, then
  the operand.  's: what a pass threads besides the typing; recoerce: its inference of the coerced
  operator; operand co: its inference of the operand with the coercion co (the identity: none);
  kept: the operand that a forbidden coercion keeps as written; raised: the exception that every
  error of this path (ERROR, COERCION_GEN_ERROR) raises in its state*)
fun local_clash ctxt bs {recoerce, operand, kept, raised} err coerce' (t', T) U V
    ((tye, idx), s) =
  let
    fun guarded s f x =
      f x handle exn as ERROR _ => raise raised s exn
        | exn as COERCION_GEN_ERROR _ => raise raised s exn;
    val W = Type_Infer.mk_param (idx + 1) [];
    val (t'', (tye', idx'), s1) =
      (t', strong_unify ctxt (W --> V, T) (tye, idx + 2), s)
        handle NO_UNIFIER _ =>
          let
            val err' = err ++> "Local coercion insertion on the operator failed:\n";
            val co = guarded s (function_of ctxt err' tye) T;
            val (t'', T'', (tye_idx'', s1)) = recoerce (co $ t') ((tye, idx + 2), s);
          in
            (t'', strong_unify ctxt (W --> V, T'') tye_idx''
              handle NO_UNIFIER (msg, _) => raise raised s1 (ERROR (eval_err (err' ++> msg))), s1)
          end;
    val err' = err ++>
      ((if t' aconv t'' then ""
        else "Successfully coerced the operator to a function of type:\n" ^
          Syntax.string_of_typ ctxt
            (the_single (snd (prep_output ctxt tye' bs [] [W --> V]))) ^ "\n") ^
       (if coerce' then "Local coercion insertion on the operand failed:\n"
        else "Local coercion insertion on the operand disallowed:\n"));
    val (u'', U', (tye_idx', s2)) =
      if coerce' then
        operand (guarded s1 (gen_coercion ctxt err' tye') (U, W)) ((tye', idx'), s1)
      else (kept s1, U, ((tye', idx'), s1));
  in
    (t'' $ u'', (strong_unify ctxt (U', W) tye_idx'
      handle NO_UNIFIER (msg, _) => raise raised s2 (COERCION_GEN_ERROR (err' ++> msg)), s2))
  end;

(*the inference of prepared terms (Type_Infer_Context.prepare; idx: the next parameter index):
  the terms with coercions inserted and their typing, not finished*)
fun infer_prepared ctxt (hooks: hooks) idx ts =
  let
    fun inf _ _ (t as (Const (_, T))) tye_idx = (t, T, tye_idx)
      | inf _ _ (t as (Free (_, T))) tye_idx = (t, T, tye_idx)
      | inf _ _ (t as (Var (_, T))) tye_idx = (t, T, tye_idx)
      | inf _ bs (t as (Bound i)) tye_idx =
          (t, snd (nth bs i handle General.Subscript => err_loose i), tye_idx)
      | inf coerce bs (Abs (x, T, t)) tye_idx =
          let val (t', U, tye_idx') = inf coerce ((x, T) :: bs) t tye_idx
          in (Abs (x, T, t'), T --> U, tye_idx') end
      | inf coerce bs (t $ u) tye_idx =
          let
            val (t', T, tye_idx') = inf coerce bs t tye_idx;
            val coerce' = update_coerce_arg ctxt coerce t;
            val (u', U, (tye, idx)) = inf coerce' bs u tye_idx';
            val _ = if observed then #observe hooks t U else ();
            val V = Type_Infer.mk_param idx [];
            val (tu, tye_idx'') = (t' $ u', strong_unify ctxt (U --> V, T) (tye, idx + 1))
              handle NO_UNIFIER (msg, tye') =>
                let
                  fun infer coerce t (tye_idx, ()) =
                    let val (t', T, tye_idx') = inf coerce bs t tye_idx
                    in (t', T, (tye_idx', ())) end;
                  val (tu, (tye_idx'', ())) =
                    local_clash ctxt bs
                      {recoerce = infer coerce,
                       operand = fn co => infer coerce' (if is_identity co then u else co $ u),
                       kept = K u, raised = K I}
                      (err_appl_msg ctxt msg tye' bs t T u U) coerce' (t', T) U V ((tye, idx), ());
                in (tu, tye_idx'') end;
          in (tu, V, tye_idx'') end;

    fun infer_single t tye_idx =
      let val (t, _, tye_idx') = inf true [] t tye_idx
      in (t, tye_idx') end;
  in
    fold_map infer_single ts (Vartab.empty, idx)
      handle COERCION_GEN_ERROR err =>
        let
          fun gen_single t (tye_idx, constraints) =
            let val (_, tye_idx', constraints') =
              generate_constraints ctxt (err ++> "\n") hooks t tye_idx
            in (tye_idx', constraints' @ constraints) end;

          val (tye_idx, constraints) = fold gen_single ts ((Vartab.empty, idx), []);
          val (tye, idx) = process_constraints ctxt (err ++> "\n") hooks constraints tye_idx;
        in
          (insert_coercions ctxt (tye, idx) ts, (tye, idx))
        end
  end;

fun coercion_infer_types ctxt (hooks: hooks) raw_ts =
  let
    val (idx, ts) = Type_Infer_Context.prepare ctxt raw_ts;
    val (ts', (tye, _)) = infer_prepared ctxt hooks idx ts;
    val (_, ts'') = Type_Infer.finish ctxt tye ([], ts');
  in ts'' end;


end;


structure Subtyping: SUBTYPING =
struct

open Subtyping_Base;

structure Stock_Coercions = Coercion_Inference(val observed = false val learning = false);
structure Observed_Coercions:
  sig
    val infer_prepared: Proof.context -> hooks -> int -> term list -> term list * tye_idx
  end =
  Coercion_Inference(val observed = true val learning = false);
(*the learning instance never returns a term*)
structure Learning_Coercions:
  sig
    val generate_constraints: Proof.context -> (unit -> string * Buffer.T) -> hooks -> term ->
      tye_idx -> typ * tye_idx * constraint list
    val process_constraints: Proof.context -> (unit -> string * Buffer.T) -> hooks ->
      constraint list -> tye_idx -> tye_idx
  end =
  Coercion_Inference(val observed = false val learning = true);

open Stock_Coercions;

fun coercion_infer_types ctxt = Stock_Coercions.coercion_infer_types ctxt no_hooks;

infixr ++>;



(** field access (dot syntax): explicit-subterm re-inference **)

(*The engine searches for C, a choice for every field access, and returns stock's inference on
  E(C) -- each field written as its choice applied to its object -- through one exit, which does
  the last check.  A term is returned in two places only: (I1a) the local pass's own result, when it
  succeeded and no choice in C has a coercion_args declaration (every field was then decided at its
  node, and the traversal has stock's code shape on E(C)); and stock's inference on the term E(C),
  the observed instance.  Everything else only finds C.

  The local pass decides a field at its node when the rule does on the object's type without
  refining it, or when the prediction gives the object's variable a ground type there; otherwise
  the field waits: its result is a blocked variable that no unification binds, and a step that
  fails on one commits only what does not depend on it.  A later step that lets the rule decide a
  waiting field re-runs the smallest application frame around its node from the frame's input
  state, the field decided there (REDECIDE), unless the re-run can be postponed until another
  field of the frame is decided.  At the end of the traversal the waiting fields are decided once
  on the typing reached, a refining choice included, and re-run the term (a field's choice is
  thus made on the type solved without it, D15; likewise the global algorithm makes a refining
  choice only after solving).
  When the local pass fails or ends with fields waiting (option b), the global algorithm learns C
  from nothing (learning runs) and stock elaborates E(C); when that learning is rejected, the
  default path learns from the local pass's binding choices.*)


(* exceptions *)

(*a waiting field was decided after its node: the oldest stamp of the fields decided now, the late
  choices, whether the pass has postponed a re-run*)
exception REDECIDE of int * term Vartab.table * bool;
(*a pass that postponed a re-run failed, or ended with fields waiting*)
exception POSTPONED_FAILURE;
(*the local pass failed: the message, the binding choices, the rule's error on a field (binding:
  made at its node on stock's local typing)*)
type pass_failure =
  (unit -> string * Buffer.T) * term Vartab.table *
    {key: indexname, msg: string, binding: bool} option;
exception LOCAL_FAILURE of pass_failure;
(*a learning run decided a field after its node: all choices*)
exception RELEARN of term Vartab.table;
(*the last check refuted a choice*)
exception LAST_CHECK of string;

(*the one judgement of every path after the local pass*)
fun rejected (ERROR _) = true
  | rejected _ = false;


(* the local pass's fields *)

(*the waiting fields: stamp -> key, key -> stamp, and their index under the parameters of their
  object types*)
type waiting =
  {fields: indexname Inttab.table, keys: int Vartab.table, index: Dot_Field.waiting_index};

val no_waiting_fields: waiting =
  {fields = Inttab.empty, keys = Vartab.empty, index = Dot_Field.no_waiting_index};

(*deferred re-runs: on in this pass; deferred: stamp -> (key, late choice) of the waiting fields
  decided whose re-run is postponed (they still wait); undecided: the stamps of the other waiting
  fields; postponed: the pass has postponed a re-run (kept through re-runs)*)
type deferral =
  {on: bool, deferred: (indexname * term) Inttab.table, undecided: Inttab.set, postponed: bool};

fun no_deferral on: deferral =
  {on = on, deferred = Inttab.empty, undecided = Inttab.empty, postponed = false};

(*threaded with the typing.  decided: all choices; confirmed: the fields chosen at their node on an
  object type without parameters (the last check holds for them by construction); stamp: of the
  next waiting field; late: the choices made after the field's node or by the prediction; binding:
  the fields chosen at their node while no field waited and no late choice was used, i.e. on
  stock's local typing of E(C) (tainted: a late choice was used)*)
type local_fields =
  {decided: term Vartab.table, confirmed: Vartab.set, waiting: waiting, stamp: int,
   late: term Vartab.table, binding: Vartab.set, tainted: bool, deferral: deferral};

(*a frame's input state, re-run with the late choices; a deferred late choice belongs to a field
  created before that state was taken, so it has none*)
fun rerun (late, postponed)
    ({decided, confirmed, waiting, stamp, binding, tainted,
      deferral = {on, deferred, undecided, ...}, ...}: local_fields) =
  if not (Inttab.is_empty deferred) then raise Fail "Subtyping.rerun: deferred choices"
  else
    {decided = Vartab.merge (K true) (decided, late), confirmed = confirmed, waiting = waiting,
     stamp = stamp, late = late, binding = binding, tainted = tainted,
     deferral = {on = on, deferred = deferred, undecided = undecided, postponed = postponed}};

(*a frame: f run from its input state fs0, the frame's entry stamp pushed on the active frames
  fr0 (innermost first).  A field created inside the frame and decided later (REDECIDE at or after
  the entry stamp) re-runs the frame from fs0 with the late choices; an older one propagates*)
fun frame fr0 (fs0: local_fields) f =
  let
    val fr = #stamp fs0 :: fr0;
    fun run fs =
      f fr fs handle exn as REDECIDE (s, late, pp) =>
        if s >= #stamp fs0 then run (rerun (late, pp) fs0) else Exn.reraise exn;
  in run fs0 end;

datatype local_result =
  Local_Done of term list * tye_idx * term Vartab.table * Vartab.set * bool
    (*C, confirmed, the pass postponed a re-run*)
| Local_Waiting of term Vartab.table  (*the binding choices*)
| Local_Failed of pass_failure;

fun is_blocked_var (TVar (("'_dotblk", _), _)) = true
  | is_blocked_var _ = false;

fun blocked_var i S = TVar (("'_dotblk", i), S);

fun params_of tye T = filter (Type_Infer.is_param o #1) (Term.add_tvarsT (Dot_Field.norm tye T) []);

(*D15: a parameter of T occurs in one of the subtype constraints cs, so the type that solving
  them gives T does not involve the field yet*)
fun constrained tye cs T =
  (case params_of tye T of
    [] => false
  | ps =>
      exists (fn ((A, B), _) =>
        exists (AList.defined (op =) ps o #1) (params_of tye A @ params_of tye B)) cs);

(*the number of occurrences of each type variable in Ts*)
fun occurrences_of Ts =
  fold (fold_atyps (fn TVar (xi, _) => Vartab.map_default (xi, 0) (Integer.add 1) | _ => I)) Ts
    Vartab.empty;

(*a unification that fails on a blocked variable: no step commits on a waiting result.  The
  equation A = B is opened: every occurrence of a blocked variable becomes its own fresh
  parameter (a wildcard), so that nothing passes through a waiting result from one occurrence to
  another.  A parameter of step that the unifier links to a wildcard depends on a waiting
  result: it is opened as well, until no new one occurs twice in the equation, and is then
  frozen to a blocked variable of the sort the unifier gives it.  SOME: the rest of the unifier,
  read through the frozen parameters; NONE: the opened types do not unify either.  Wildcards are
  numbered from start*)
fun opened_unify ctxt (A, B) step start tye =
  let
    val occurrences = occurrences_of [A, B];
    fun is_wild (TVar (("?'_dotwild", _), _)) = true
      | is_wild _ = false;
    (*D: the dependent parameters with their sorts; origin: wildcard index -> the variable it
      replaces*)
    fun probe D =
      let
        fun opn (A as TVar (xi, S)) (origin, i) =
              (case (is_blocked_var A, AList.lookup (op =) D xi) of
                (false, NONE) => (A, (origin, i))
              | (_, S') =>
                  (Type_Infer.param i ("'_dotwild", the_default S S'),
                    (Inttab.update (i, A) origin, i + 1)))
          | opn (Type (a, As)) st =
              let val (As', st') = fold_map opn As st in (Type (a, As'), st') end
          | opn A st = (A, st);
        val ((A', B'), (origin, i1)) = opn A (Inttab.empty, start) ||>> opn B;
      in
        (case SOME (strong_unify ctxt (A', B') (tye, i1)) handle NO_UNIFIER _ => NONE of
          NONE => NONE
        | SOME (tye1, i2) =>
            let
              (*the parameters on a wildcard's binding chain*)
              fun chain (A as TVar (xi, _)) acc =
                    if not (Type_Infer.is_param xi) orelse member (op =) acc xi then acc
                    else
                      let val acc' = if is_wild A then acc else xi :: acc in
                        (case Vartab.lookup tye1 xi of SOME B => chain B acc' | NONE => acc')
                      end
                | chain (Type (_, As)) acc = fold chain As acc
                | chain _ acc = acc;
              val on_chain =
                Inttab.fold (fn (i, _) => chain (Type_Infer.param i ("'_dotwild", [])))
                  origin [];
              fun to_wild (A as TVar (xi, _)) =
                    is_wild A orelse
                      (case Vartab.lookup tye1 xi of SOME B => to_wild B | NONE => false)
                | to_wild _ = false;
              val new = step |> filter (fn (xi, S) =>
                not (AList.defined (op =) D xi) andalso
                  (member (op =) on_chain xi orelse to_wild (TVar (xi, S))));
              (*the sort that the unifier gives a parameter*)
              fun sort_in (xi, S) =
                (case Type_Infer.deref tye1 (TVar (xi, S)) of TVar (_, S') => S' | _ => S);
              val D' = D @ map (fn p => (fst p, sort_in p)) new;
            in
              if exists (fn (xi, _) => the (Vartab.lookup occurrences xi) > 1) new
              then probe D' else SOME (tye1, i2, D', origin)
            end)
      end;
  in
    (case probe [] of
      SOME (tye1, i2, D, origin) =>
        let
          val (frozen, i3) =
            fold_map (fn (xi, S) => fn i => ((xi, blocked_var i S), i + 1)) D i2;
          fun image (A as TVar (xi as (_, j), _)) =
                if is_wild A then
                  (case the (Inttab.lookup origin j) of
                    B as TVar (xk, _) => the_default B (AList.lookup (op =) frozen xk)
                  | B => B)
                else
                  (case AList.lookup (op =) frozen xi of
                    SOME F => F
                  | NONE => (case Vartab.lookup tye1 xi of SOME B => image B | NONE => A))
            | image (Type (a, As)) = Type (a, map image As)
            | image A = A;
          val tye' = fold (fn (xi, S) => fn tye =>
            let val I = image (TVar (xi, S)) in
              if (case I of TVar (xj, _) => xj = xi | _ => false) then tye
              else Vartab.update (xi, I) tye
            end) step tye;
        in SOME (tye', i3) end
    | NONE => NONE)
  end;

(*a step U --> V = T that fails on a blocked variable (D7): the opened step, committed in part;
  when the opened step does not unify either, every parameter of the step is frozen and its
  result is the operator's range*)
fun blocked_parts V T U tye =
  let val (T', U') = apply2 (Dot_Field.norm tye) (T, U)
  in (T', U', dest_TVar V :: fold (fn A => fold (insert (op =)) (params_of tye A)) [T', U'] [])
  end;
fun blocked_step ctxt V T U (tye, idx) =
  let val (T', U', step) = blocked_parts V T U tye in
    (case opened_unify ctxt (U' --> V, T') step (idx + 1) tye of
      SOME (tye', i3) => (Dot_Field.norm tye' V, (tye', i3))
    | NONE =>
        let
          val (tye', idx') =
            fold (fn (xi, S) => fn (tye, i) => (Vartab.update (xi, blocked_var i S) tye, i + 1))
              (tl step) (tye, idx + 1);
        in
          (case Dot_Field.norm tye' T of
            Type ("fun", [_, B]) => (B, (tye', idx'))
          | _ => (blocked_var idx' \<^sort>\<open>type\<close>, (tye', idx' + 1)))
        end)
  end;

(*D6: coerce_arg with the head and the argument count read off the spine, through its
  constraints*)
fun spine_coerce_arg ctxt old t =
  let
    fun spine (Const ("_type_constraint_", _) $ u) n = spine u n
      | spine (u $ _) n = spine u (n + 1)
      | spine u n = (u, n);
  in coerce_arg ctxt old (spine t 0) end;

(*solved spine equations of the prediction, by the head type, the expected result and the argument
  types*)
structure Spine_Tab =
  Table(type key = typ option list val ord = list_ord (option_ord Term_Ord.typ_ord));


(* transparent constraints *)

fun param_leaves sortfree (Type ("fun", [B, C])) =
      (case (param_leaves sortfree B, param_leaves sortfree C) of
        (SOME xs, SOME ys) => SOME (xs @ ys)
      | _ => NONE)
  | param_leaves sortfree (TVar (xi, S)) =
      if Type_Infer.is_param xi andalso (not sortfree orelse null S) then SOME [xi] else NONE
  | param_leaves _ _ = NONE;
(*a constraint whose parameters occur only in its own type constrains nothing; sortfree: and they
  carry no sort.  count_of: the occurrences of a parameter in the prepared terms*)
fun transparent count_of sortfree (Const ("_type_constraint_", Type ("fun", [A, _]))) =
      (case param_leaves sortfree A of
        SOME xs =>
          not (has_duplicates (op =) xs) andalso forall (fn xi => count_of xi = SOME 2) xs
      | NONE => false)
  | transparent _ _ _ = false;
fun strip_transparent count_of (t as (c $ u)) =
      if transparent count_of true c then strip_transparent count_of u else t
  | strip_transparent _ t = t;


(* the prediction: expected-type propagation *)

(*A field whose object is a variable -- an implicit free variable, or a bound variable whose
  binder parameter occurs only in its abstraction -- is decided at its node on the ground type E
  that every other occurrence of the variable gets: a position whose expected type is E, read
  off spines whose heads have their own parameters and whose other arguments have exact types,
  or the argument of a beta-redex head; all its fields or none.  The exact type of a subterm is
  the type it gets in every traversal; a carrier whose choice is known statically and whose
  registered range has no type variable has that range.  So the predictions are a least
  fixpoint, computed in rounds; the later rounds reuse the spines solved before.  A prediction
  is a function of the prepared terms (I13).  In the local pass a constraint whose type is not
  ground disqualifies its variable; generation uses a prediction only when the variable's
  parameter and the spine heads between it and its sources have parameters of the default sort
  only.*)

(*the selection rule's rigid type variables, here and in the engine: all but the parameters*)
val rigid = {rigid = not o Type_Infer.is_param};

fun static_ground T =
  not (Term.exists_subtype (fn U => Type_Infer.is_paramT U orelse is_blocked_var U) T);
fun default_sort thy S = Sign.subsort thy (Sign.defaultS thy, S);
fun sorted_params thy T =
  Term.exists_subtype (fn TVar (xi, S) => Type_Infer.is_param xi andalso not (default_sort thy S)
    | _ => false) T;
fun is_type_constraint (Const ("_type_constraint_", _)) = true
  | is_type_constraint _ = false;
(*the type of a head whose parameters are its own: a constant (prepare gives each occurrence
  fresh parameters; not the carrier), or an atom of ground type*)
fun head_type (Const (c, T)) = if c = Dot_Field.access_const then NONE else SOME T
  | head_type (Free (_, T)) = if static_ground T then SOME T else NONE
  | head_type (Var (_, T)) = if static_ground T then SOME T else NONE
  | head_type _ = NONE;
fun atom_type h =
  (case head_type h of
    SOME T => if static_ground T then SOME T else NONE
  | NONE => NONE);

(*the static tree: atoms, carriers (key, field, object, the object's exact type), abstractions
  (binder type, body), spines (head, head type, arguments with their exact types)*)
datatype etree =
  ELeaf of term
| EField of indexname * string * etree * typ option
| ELam of typ * etree
| EApp of etree * typ option * (etree * typ option) list;

(*the exact range of a spine of head type T whose arguments all have exact types; solve: the spine
  equations' solver*)
fun exact_spine solve T bargs =
  if forall (is_some o snd) bargs then
    (case solve T (map snd bargs) NONE of
      SOME (_, R, _) => if static_ground R then SOME R else NONE
    | NONE => NONE)
  else NONE;

(*the objects' exact types of a tree, by key*)
fun exact_objects (EField (key, _, otr, oE)) =
      (case oE of SOME E => Vartab.update (key, E) | NONE => I) #> exact_objects otr
  | exact_objects (ELam (_, b)) = exact_objects b
  | exact_objects (EApp (h, _, args)) = exact_objects h #> fold (exact_objects o #1) args
  | exact_objects (ELeaf _) = I;

(*a position: Exp (E, s), expected ground type E; Lone, a parameter that nothing else
  constrains (the top of a term, the object of a field, a parameter occurring once in its
  spine's equations); Pos, a position type with parameters, to be read only; Unknown.  s: a
  spine head type between the position and the top of its term has a parameter of a sort other
  than the default*)
datatype position = Exp of typ * bool | Lone | Pos of typ * int Vartab.table * bool | Unknown;
fun classify (Pos (P, occurrences, s)) =
      if static_ground P then Exp (P, s)
      else
        (case P of
          TVar (xi, _) => if Vartab.lookup occurrences xi = SOME 1 then Lone else Unknown
        | _ => Unknown)
  | classify pos = pos;
fun fun_parts (Pos (Type ("fun", [D, R]), occurrences, s)) =
      (classify (Pos (D, occurrences, s)), classify (Pos (R, occurrences, s)))
  | fun_parts (Exp (Type ("fun", [D, R]), s)) = (Exp (D, s), Exp (R, s))
  | fun_parts Lone = (Lone, Lone)
  | fun_parts _ = (Unknown, Unknown);
fun pos_sorted (Exp (_, s)) = s
  | pos_sorted (Pos (_, _, s)) = s
  | pos_sorted _ = false;

(*the occurrences of a variable: sources (expected types), a disqualifying occurrence, fields;
  sorted: a source read through a sorted spine head, or the variable's own parameter has a sort
  other than the default*)
type occ = {srcs: typ list, bad: bool, fields: string list, sorted: bool};
val no_occ: occ = {srcs = [], bad = false, fields = [], sorted = false};
fun add_src E s ({srcs, bad, fields, sorted}: occ) =
  {srcs = E :: srcs, bad = bad, fields = fields, sorted = sorted orelse s}: occ;
fun add_bad ({srcs, fields, sorted, ...}: occ) =
  {srcs = srcs, bad = true, fields = fields, sorted = sorted}: occ;
fun add_field f ({srcs, bad, fields, sorted}: occ) =
  {srcs = srcs, bad = bad, fields = insert (op =) f fields, sorted = sorted}: occ;
fun mark_sort thy S ({srcs, bad, fields, sorted}: occ) =
  {srcs = srcs, bad = bad, fields = fields, sorted = sorted orelse not (default_sort thy S)}: occ;

(*the variable of an atom: an implicit free variable, or the parameter of a binder that occurs
  only in its abstraction*)
datatype var = VFree of string * sort | VBound of indexname * sort;

(*predictions: implicit free variable -> (field, choice) list; binder parameter -> the same*)
type preds = (string * term) list Symtab.table * (string * term) list Vartab.table;

(*a new prediction changes the next round's trees only through a choice with a ground range*)
fun feeds (cs, _) =
  exists (fn (_, g) => null (Term.add_tvarsT (range_type (fastype_of g)) [])) cs;

(*the prediction on a batch of prepared terms: ts0, the terms without the position reports; accs,
  their accesses; count_of, the occurrences of a parameter in them; idx, the next parameter
  index.  The three entries take only the key of a field: predicted, the choice that the local
  pass's predictions give the field; predicted_gen, likewise generation's; exact_object, the
  object's exact type in generation, its own, else generation's predictions'*)
fun dot_predictions ctxt idx count_of accs ts0 =
  let
    val thy = Proof_Context.theory_of ctxt;
    val dest_access = Dot_Field.batch_access accs;
    fun access_of key = #1 (the (Vartab.lookup accs key));

    (*the spine of t, transparent constraints stripped at every level; a carrier is a head*)
    fun spine_of t args =
      let val t0 = strip_transparent count_of t in
        if is_some (dest_access t0) then (t0, args)
        else (case t0 of u $ v => spine_of u (v :: args) | h => (h, args))
      end;
    (*the equations of a spine, the head's type against the argument types and the result, with
      fresh parameters (from idx, discarded) for the unknown ones: the normalised position types,
      the result, and the occurrences of every parameter in them*)
    fun solve_spine T argTs resT =
      let
        val (Ts, st) =
          fold_map (fn SOME A => (fn st => (A, st))
            | NONE => (fn (tye, i) => (Type_Infer.mk_param i [], (tye, i + 1))))
            argTs (Vartab.empty, idx);
        val (R, (tye, i)) =
          (case resT of
            SOME R => (R, st)
          | NONE => (Type_Infer.mk_param (snd st) [], (fst st, snd st + 1)));
        val (tye', _) = strong_unify ctxt (Ts ---> R, T) (tye, i);
        val Ps = map (Dot_Field.norm tye') Ts;
        val R' = Dot_Field.norm tye' R;
      in SOME (Ps, R', occurrences_of (R' :: Ps)) end
      handle NO_UNIFIER _ => NONE;

    (*the static tree of t and its exact type; cr key objE: the exact type of a carrier; solve: the
      spine equations' solver*)
    fun build cr solve t =
      let val t0 = strip_transparent count_of t in
        (case dest_access t0 of
          SOME {key, payload, obj, ...} =>
            let
              val field = Dot_Field.field_name payload;
              val (otr, oE) = build cr solve obj;
            in (EField (key, field, otr, oE), cr key oE) end
        | NONE =>
            (case t0 of
              Abs (_, T, b) => (ELam (T, #1 (build cr solve b)), NONE)
            | _ =>
                (case spine_of t0 [] of
                  (h, []) => (ELeaf h, atom_type h)
                | (h, args) =>
                    let
                      val hT = head_type h;
                      val bargs = map (build cr solve) args;
                      (*a constraint that is not transparent, of ground type A, has type A
                        whatever its argument: unification, stock's clash path and a blocked step
                        all give it the range A (prepare puts every fixed variable in this form)*)
                      val exact =
                        (case hT of
                          SOME (Type ("fun", [A, R])) =>
                            if is_type_constraint h andalso static_ground A then SOME A
                            else exact_spine solve (A --> R) bargs
                        | SOME T => exact_spine solve T bargs
                        | NONE => NONE);
                    in (EApp (#1 (build cr solve h), hT, bargs), exact) end)))
      end;

    fun bound_var (TVar (p, S)) =
          if Type_Infer.is_param p andalso count_of p = SOME 1 then SOME (VBound (p, S)) else NONE
      | bound_var _ = NONE;
    fun var_of _ (Free (x, TVar (xi, S))) =
          if Type_Infer.is_param xi then SOME (VFree (x, S)) else NONE
      | var_of bs (Bound i) = (case try (nth bs) i of SOME T => bound_var T | NONE => NONE)
      | var_of _ _ = NONE;
    fun upd v f (frees, bounds) =
      (case v of
        VFree (x, S) => (Symtab.map_default (x, no_occ) (f o mark_sort thy S) frees, bounds)
      | VBound (p, S) => (frees, Vartab.map_default (p, no_occ) (f o mark_sort thy S) bounds));
    fun occur v pos =
      (case classify pos of
        Exp (E, s) => upd v (add_src E s)
      | Lone => I
      | _ => upd v add_bad);
    (*the beta-redex head (\<lambda>x1 .. xn. b) a1 .. am: the binder xi (i <= m) gets ai's exact
      type*)
    fun redex_sources (ELam (T, body)) ((_, SOME E) :: args) =
          (case bound_var T of SOME v => upd v (add_src E false) | NONE => I) #>
          redex_sources body args
      | redex_sources (ELam (_, body)) ((_, NONE) :: args) = redex_sources body args
      | redex_sources _ _ = I;
    (*the occurrences of the variables in a tree at the position pos; solve: as build*)
    fun scan solve bs pos tr =
      (case tr of
        ELeaf h => (case var_of bs h of SOME v => occur v pos | NONE => I)
      | EField (_, f, ELeaf h, _) => (case var_of bs h of SOME v => upd v (add_field f) | NONE => I)
      | EField (_, _, obj, _) => scan solve bs Lone obj
      | ELam (T, body) =>
          let
            val (dom, ran) = fun_parts pos;
            (*the body binds the binder before the abstraction's own step: only a ground domain is
              a source; the position never disqualifies the binder*)
            val src =
              (case (bound_var T, dom) of
                (SOME v, Exp (E, s)) => upd v (add_src E s)
              | _ => I);
          in src #> scan solve (T :: bs) ran body end
      | EApp (htr, hT, args) =>
          (case hT of
            NONE =>
              (*a head whose type is not its own: it is constrained by its use, its arguments by
                it; an abstraction's binders get the exact types of their arguments*)
              redex_sources htr args #>
              scan solve bs Unknown htr #> fold (fn (a, _) => scan solve bs Unknown a) args
          | SOME T =>
              let val s = pos_sorted pos orelse sorted_params thy T in
                (case solve T (map snd args)
                    (case classify pos of Exp (R, _) => SOME R | _ => NONE) of
                  NONE => fold (fn (a, _) => scan solve bs Unknown a) args
                | SOME (Ps, _, occurrences) =>
                    fold2 (fn (a, _) => fn P => scan solve bs (Pos (P, occurrences, s)) a)
                      args Ps)
              end));

    fun predicted_choice ((frees, bounds): preds) key =
      let
        val ({payload, obj, ...}, bs) = the (Vartab.lookup accs key);
        val f = Dot_Field.field_name payload;
      in
        (case strip_transparent count_of obj of
          Free (x, _) =>
            (case Symtab.lookup frees x of SOME cs => AList.lookup (op =) cs f | NONE => NONE)
        | Bound i =>
            (case try (nth bs) i of
              SOME (_, TVar (p, _)) =>
                (case Vartab.lookup bounds p of SOME cs => AList.lookup (op =) cs f | NONE => NONE)
            | _ => NONE)
        | _ => NONE)
      end;
    fun static_choice field E =
      (case Dot_Field.decide ctxt rigid field E of
        Dot_Field.Choose g => SOME g
      | _ => NONE);
    (*choice key field E: the static choice at a carrier*)
    fun carrier_type choice preds key oE =
      (case
        (case oE of
          SOME E => choice key (Dot_Field.field_name (#payload (access_of key))) E
        | NONE => predicted_choice preds key) of
        SOME g =>
          let val R = range_type (fastype_of g)
          in if null (Term.add_tvarsT R []) then SOME R else NONE end
      | NONE => NONE);

    (*the predictions, the objects' exact types by key, and whether a prediction is sorted; gen:
      generation's predictions (not sorted)*)
    fun compute_predictions gen =
      let
        fun predict ({srcs, bad, fields, sorted}: occ) =
          if bad orelse null srcs orelse null fields orelse (gen andalso sorted) then NONE
          else
            let
              val E = hd srcs;
              val chosen = fields |> map_filter (fn f => Option.map (pair f) (static_choice f E));
            in
              if forall (fn E' => E' = E) srcs andalso length chosen = length fields
              then SOME chosen else NONE
            end;
        (*the spines solved and the static choices made at the carriers in this call*)
        val spines =
          Unsynchronized.ref
            (Spine_Tab.empty: (typ list * typ * int Vartab.table) option Spine_Tab.table);
        val carriers = Unsynchronized.ref (Vartab.empty: (typ * term option) Vartab.table);
        fun reused_solve T argTs resT =
          let val key = SOME T :: resT :: argTs in
            (case Spine_Tab.lookup (! spines) key of
              SOME r => r
            | NONE =>
                let val r = solve_spine T argTs resT
                in spines := Spine_Tab.update (key, r) (! spines); r end)
          end;
        fun reused_choice key field E =
          (case Vartab.lookup (! carriers) key of
            SOME (E', r) => if E' = E then r else static_choice field E
          | NONE =>
              let val r = static_choice field E
              in carriers := Vartab.update (key, (E, r)) (! carriers); r end);
        (*a round's spine solver and static choices at the carriers: the first round's, which
          records nothing (most batches need only one round), and the later rounds', which record
          what they solve and choose and reuse it*)
        val first = (solve_spine, K static_choice);
        val reusing = (reused_solve, reused_choice);
        (*a round: the trees with the carriers' exact types of preds, the predictions added (with
          their sorted flags), and whether a variable with fields is still unpredicted*)
        fun round (solve, choice) (preds as (pf, pb)) =
          let
            val trees = map (#1 o build (carrier_type choice preds) solve) ts0;
            val (frees, bounds) = fold (scan solve [] Lone) trees (Symtab.empty, Vartab.empty);
            fun new defined tab =
              tab |> map_filter (fn (v, o': occ) =>
                if defined v then NONE
                else Option.map (fn cs => (v, (cs, #sorted o'))) (predict o'));
            val new_f = new (Symtab.defined pf) (Symtab.dest frees);
            val new_b = new (Vartab.defined pb) (Vartab.dest bounds);
            val preds' =
              (fold (Symtab.update o apsnd #1) new_f pf, fold (Vartab.update o apsnd #1) new_b pb);
            fun unpredicted defined = exists (fn (v, o': occ) => not (null (#fields o')) andalso
              not (defined v));
            val left =
              unpredicted (Symtab.defined (#1 preds')) (Symtab.dest frees) orelse
              unpredicted (Vartab.defined (#2 preds')) (Vartab.dest bounds);
          in (preds', trees, map #2 new_f @ map #2 new_b, left) end;
        fun loop solver preds sorted0 =
          let
            val (preds', trees, added, left) = round solver preds;
            val sorted = sorted0 orelse exists #2 added;
          in
            if left andalso exists feeds added then loop reusing preds' sorted
            else (preds', trees, sorted)
          end;
        val (preds, trees, sorted) = loop first (Symtab.empty, Vartab.empty) false;
      in (preds, fold exact_objects trees Vartab.empty, sorted) end;
    val predictions = Lazy.lazy (fn () => compute_predictions false);
    (*generation's are the local ones unless a local prediction is sorted*)
    val predictions_gen = Lazy.lazy (fn () =>
      let val r as (_, _, sorted) = Lazy.force predictions
      in if sorted then compute_predictions true else r end);
    fun predicted preds key = predicted_choice (#1 (Lazy.force preds)) key;
    fun exact_object key =
      (case
        build (carrier_type (K static_choice) (Symtab.empty, Vartab.empty)) solve_spine
          (#obj (access_of key)) of
        (_, SOME E) => SOME E
      | (_, NONE) => Vartab.lookup (#2 (Lazy.force predictions_gen)) key);
  in
    {predicted = predicted predictions, predicted_gen = predicted predictions_gen,
     exact_object = exact_object}
  end;


(* the engine *)

(*the finished terms of stock's inference on E(C), a marker per field learnt by D14 appended, and
  the accesses with their choices C; learning_context: the preparation of a learning run's context
  (D14)*)
fun dot_infer_types learning_context ctxt raw_ts =
  let
    val (idx, ts) = Type_Infer_Context.prepare ctxt raw_ts;
    val thy = Proof_Context.theory_of ctxt;
    val accs = Dot_Field.collect_accesses ts;
    val dest_access = Dot_Field.batch_access accs;
    val engine: Dot_Field.engine =
      {rigid = #rigid rigid, unify = strong_unify ctxt, prep_output = prep_output ctxt};
    fun complete C = Vartab.forall (fn (key, _) => Vartab.defined C key) accs;
    fun has_blocked tye T = Term.exists_subtype is_blocked_var (Dot_Field.norm tye T);
    fun without keys C = Vartab.fold (Vartab.delete_safe o #1) keys C;
    val no_err = fn () => ("", Buffer.empty);


    (* the objects' own types (D15) *)

    (*the TYPE terms that check_terms appends to report the types of positions*)
    fun is_report (Const ("_type_constraint_", _) $ Const ("Pure.type", _)) = true
      | is_report _ = false;
    val ts0 = filter_out is_report ts;
    val counts = Lazy.lazy (fn () =>
      (fold o fold_types o fold_atyps)
        (fn TVar (xi, _) =>
            if Type_Infer.is_param xi then Vartab.map_default (xi, 0) (Integer.add 1) else I
          | _ => I) ts0 Vartab.empty);
    fun count_of xi = Vartab.lookup (Lazy.force counts) xi;

    (*the object's own type: the type of the term inside its transparent constraints (the position
      constraint), where the global algorithm can place a coercion that only the field's domain
      demands -- a token's own type, or a declared type*)
    fun inner_type bs ((c as Const ("_type_constraint_", Type ("fun", [A, _]))) $ u) =
          if transparent count_of false c then inner_type bs u else SOME A
      | inner_type bs (Bound i) = Option.map snd (try (nth bs) i)
      | inner_type _ (Free (_, T)) = SOME T
      | inner_type _ (Const (_, T)) = SOME T
      | inner_type _ (Var (_, T)) = SOME T
      | inner_type _ _ = NONE;
    fun object_own bs (obj as (c $ _)) =
          if transparent count_of false c then inner_type bs obj else NONE
      | object_own _ _ = NONE;

    (*the accesses as decisions and the last check read them*)
    val accs_read =
      Vartab.map (fn _ => fn (acc as {objT, obj, ...}: Dot_Field.access, bs) =>
        (Dot_Field.with_object_type (the_default objT (object_own bs obj)) acc, bs)) accs;
    fun the_access key = the (Vartab.lookup accs_read key);
    fun objT_of key = #objT (#1 (the_access key));
    fun decide (tye, _) key =
      Dot_Field.decide ctxt rigid (Dot_Field.field_name (#payload (#1 (the_access key))))
        (Dot_Field.norm tye (objT_of key));
    fun field_error_msg tye_idx key =
      Dot_Field.field_error_msg ctxt engine tye_idx (the_access key);
    (*the rule before the typing is final: a choice that refines the object type T (T is not an
      instance of its pattern: choosing it binds a parameter of T or strengthens its sort) waits,
      since a later step may still bind that parameter; a choice that does not refine T is the
      rule's choice on every instance of T*)
    fun provisional T (d as Dot_Field.Choose g) =
          if Dot_Field.fits thy {rigid = K true} T (domain_type (fastype_of g)) then d
          else Dot_Field.Wait
      | provisional _ d = d;
    fun decide_on final (tye_idx as (tye, _)) key =
      if final then decide tye_idx key
      else provisional (Dot_Field.norm tye (objT_of key)) (decide tye_idx key);


    (* the exits *)

    (*D14: the choices that learning runs of this call learnt; their last check is at stage 1, on
      markers*)
    val learnt_choices = Unsynchronized.ref (Vartab.empty: term Vartab.table);

    (*the object's type on stock's inference of E(C): its own, else the operand's type recorded at
      its node instance*)
    fun object_type_E objs key =
      let val ({obj, ...}, bs) = the (Vartab.lookup accs key) in
        (case object_own bs obj of
          SOME T => T
        | NONE =>
            (case Inttab.lookup objs (#2 key) of
              SOME U => U
            | NONE => raise Fail "Subtyping: an object type was not recorded"))
      end;

    (*the one exit: the last check of C (except confirmed and the learnt fields), a marker per
      learnt field, finish.  objects: NONE for the local pass's own typing (I1a), else
      the objects' types recorded on stock's inference of E(C)*)
    fun exit objects (ts', (tye, idx')) C confirmed =
      let
        val accs' =
          (case objects of
            NONE => accs_read
          | SOME objs =>
              Vartab.map (fn key => fn (acc, bs) =>
                (Dot_Field.with_object_type (object_type_E objs key) acc, bs)) accs);
        val learnt = ! learnt_choices;
        val _ =
          Dot_Field.last_check ctxt engine (tye, idx') accs' (without learnt (without confirmed C))
            handle ERROR msg => raise LAST_CHECK msg;
        val markers =
          Vartab.fold (fn (key, _) =>
            cons (Dot_Field.marker ctxt engine tye (the (Vartab.lookup accs' key)))) learnt [];
      in (#2 (Type_Infer.finish ctxt tye ([], ts' @ markers)), (accs, C)) end;

    (*stock's inference on the term E(C), C complete: the local pass, else the global algorithm*)
    fun explicit_E C =
      let
        val objs = Unsynchronized.ref Inttab.empty;
        fun observe t U =
          (case Dot_Field.dest_node_instance t of
            SOME (j, _) => objs := Inttab.update (j, U) (! objs)
          | NONE => ());
        val result =
          Observed_Coercions.infer_prepared ctxt (observe_hooks observe) idx
            (map (Dot_Field.explicit C) ts);
      in exit (SOME (! objs)) result C Vartab.empty end;


    (* D14: learning runs on the learning output *)

    (*the dot form on a typing with the choices C, the carriers of the other fields left*)
    fun learning_output ((tye, idx'), C) =
      (Dot_Field.last_check ctxt engine (tye, idx') accs_read (without (! learnt_choices) C);
       #2 (Type_Infer.finish ctxt tye
        ([], insert_coercions ctxt (tye, idx') (map (Dot_Field.explicit C) ts))));

    (*C with the choices that a learning run on this typing learns for the fields not in C, or the
      ones learnt earlier in this call; NONE: none*)
    fun learn_d14 (tye_idx, C) =
      let val known = without C (! learnt_choices) in
        if not (Vartab.is_empty known) then SOME (Vartab.merge (K true) (C, known))
        else
          (case Exn.result learning_output (tye_idx, C) of
            Exn.Res out =>
              let val new = Dot_Field.learn learning_context engine ctxt accs out in
                if Vartab.is_empty new then NONE
                else
                  (learnt_choices := Vartab.merge (K true) (! learnt_choices, new);
                   SOME (Vartab.merge (K true) (C, new)))
              end
          | Exn.Exn exn => if rejected exn then NONE else Exn.reraise exn)
      end;


    (* the prediction *)

    val {predicted, predicted_gen, exact_object} = dot_predictions ctxt idx count_of accs ts0;


    (* the local pass *)

    fun binding_choices ({decided, binding, ...}: local_fields) =
      Vartab.fold (fn (k, g) => if Vartab.defined binding k then Vartab.update (k, g) else I)
        decided Vartab.empty;
    fun postponed ({deferral = {postponed, ...}, ...}: local_fields) = postponed;
    (*the failure of a pass; a pass that postponed a re-run is not reported, the pass without
      deferral replaces it*)
    fun local_failure rule err fs =
      if postponed fs then POSTPONED_FAILURE
      else LOCAL_FAILURE (err, binding_choices fs, rule);
    (*the exception of an error of stock's clash path in the state fs*)
    fun raised fs (COERCION_GEN_ERROR err) = local_failure NONE err fs
      | raised fs exn = if postponed fs then POSTPONED_FAILURE else exn;
    fun no_waiting ({waiting = {fields, ...}, ...}: local_fields) = Inttab.is_empty fields;
    fun binding_now (fs as {tainted, ...}: local_fields) = no_waiting fs andalso not tainted;
    fun is_waiting ({waiting = {keys, ...}, ...}: local_fields) key = Vartab.defined keys key;

    (*the rule on the current typing, final at the end of the traversal; a field whose object type
      mentions a blocked variable waits*)
    fun local_decide final (tye_idx as (tye, _)) key =
      if has_blocked tye (objT_of key) then Dot_Field.Wait else decide_on final tye_idx key;

    (*the rule's error on a field in the state fs, a failure that the global algorithm takes over*)
    fun rule_failure tye_idx key d fs =
      let val msg = field_error_msg tye_idx key d in
        raise local_failure (SOME {key = key, msg = msg, binding = binding_now fs})
          (fn () => (msg, Buffer.empty)) fs
      end;

    fun add_waiting tye key
        ({decided, confirmed, waiting = {fields, keys, index}, stamp, late, binding,
          tainted, deferral = {on, deferred, undecided, postponed}}: local_fields) =
      let val index' = Dot_Field.place tye stamp (objT_of key) index in
        {decided = decided, confirmed = confirmed, stamp = stamp + 1, late = late,
         binding = binding, tainted = tainted,
         waiting =
          {fields = Inttab.update (stamp, key) fields, keys = Vartab.update (key, stamp) keys,
           index = index'},
         deferral =
          {on = on, deferred = deferred, undecided = Inttab.insert_set stamp undecided,
           postponed = postponed}}: local_fields
      end;

    (*the late choices ds (stamp, key, choice) with the deferred ones: the oldest stamp, and the
      late choices of the re-run*)
    fun late_choices ds deferred late =
      (fold (fn (s, _, _) => Integer.min s) ds
        (case Inttab.min deferred of SOME (s, _) => s | NONE => #1 (hd ds)),
       fold (fn (_, key, g) => Vartab.update (key, g)) ds
        (Inttab.fold (fn (_, (key, g)) => Vartab.update (key, g)) deferred late));

    (*after a committed step: the waiting fields whose object type the step may have changed, in
      stamp order.  fr: the entry stamps of the active frames, innermost first.  The fields decided
      now, with the deferred ones, re-run the innermost active frame entered before the oldest of
      them; that re-run is postponed while a waiting field created inside the frame is undecided
      and decidable in this traversal*)
    fun check_decisions fr (tye_idx as (tye, _))
        (fs as {decided, confirmed, waiting = {fields, keys, index}, stamp, late, binding,
          tainted, deferral = {on, deferred, undecided, postponed}}: local_fields) =
      if Inttab.is_empty fields then fs
      else
        let
          val (cands, index1) = Dot_Field.take_bound tye index;
          val (index', ds) =
            Inttab.fold (fn (st, ()) => fn (index', ds) =>
              let val key = the (Inttab.lookup fields st) in
                (case local_decide false tye_idx key of
                  Dot_Field.Choose g => (index', (st, key, g) :: ds)
                | Dot_Field.Wait => (Dot_Field.place tye st (objT_of key) index', ds)
                | d => rule_failure tye_idx key d fs)
              end)
              cands (index1, []);
          fun with_index deferral' =
            {decided = decided, confirmed = confirmed, stamp = stamp, late = late,
             binding = binding, tainted = tainted,
             waiting = {fields = fields, keys = keys, index = index'},
             deferral = deferral'}: local_fields;
        in
          if null ds then
            with_index {on = on, deferred = deferred, undecided = undecided, postponed = postponed}
          else
            let
              val (oldest, late') = late_choices ds deferred late;
              val undecided' = fold (fn (s, _, _) => Inttab.remove_set s) ds undecided;
              val entry = the_default 0 (find_first (fn e => e <= oldest) fr);
              (*an undecided field that this traversal can still decide: its object type has no
                blocked variable (a blocked variable is never bound within a traversal)*)
              fun decidable s = not (has_blocked tye (objT_of (the (Inttab.lookup fields s))));
              val postpone =
                on andalso Inttab.exists (fn (s, ()) => s >= entry andalso decidable s) undecided';
            in
              if postpone then
                with_index {on = on, undecided = undecided', postponed = true,
                  deferred = fold (fn (s, key, g) => Inttab.update (s, (key, g))) ds deferred}
              else raise REDECIDE (oldest, late', postponed)
            end
        end;

    (*the end of the traversal: the waiting fields, decided once on the typing reached (which
      their blocked results did not influence); a choice re-runs the term of the oldest field
      decided, with the deferred choices*)
    fun end_decisions tye_idx
        (fs as {waiting = {fields, ...}, late, deferral = {deferred, postponed, ...}, ...}:
          local_fields) =
      let
        val ds =
          Inttab.fold_rev (fn (st, key) =>
            if Inttab.defined deferred st then I
            else
              (case local_decide true tye_idx key of
                Dot_Field.Choose g => cons (st, key, g)
              | Dot_Field.Wait => I
              | d => rule_failure tye_idx key d fs)) fields [];
      in
        if null ds then ()
        else
          let val (oldest, late') = late_choices ds deferred late
          in raise REDECIDE (oldest, late', postponed) end
      end;

    (*the local pass's inference: stock's local pass with the fields decided at their nodes
      (Dot_Field.node_instance and stock's application step) or waiting.  fr: the entry stamps of
      the active frames, innermost first*)
    fun inf coerce bs fr t st =
      (case dest_access t of
        SOME {key, objT, resT, obj, node, ...} =>
          let
            val (obj', U, (tye_idx0, fs1)) = inf coerce bs fr obj st;
            val tye_idx1 = strong_unify ctxt (objT, U) tye_idx0;
            (*the choice; whether it was made now on a type without parameters (confirm);
              whether the prediction made it (booked as the late choice it replaces)*)
            val choice =
              (case Vartab.lookup (#decided fs1) key of
                SOME g => SOME (g, false, false)
              | NONE =>
                  if is_waiting fs1 key then NONE
                  else
                    (case local_decide false tye_idx1 key of
                      Dot_Field.Choose g =>
                        SOME (g, not (Term.exists_subtype Type_Infer.is_paramT
                          (Dot_Field.norm (fst tye_idx1) objT)), false)
                    | Dot_Field.Wait =>
                        Option.map (fn g => (g, false, true)) (predicted key)
                    | d => rule_failure tye_idx1 key d fs1));
          in
            (case choice of
              SOME (g, confirm, by_prediction) =>
                let
                  val g' = Dot_Field.node_instance key g;
                  val {decided, confirmed, waiting, stamp, late, binding, tainted, deferral} = fs1;
                  val fs2 =
                    {decided = Vartab.update (key, g) decided, waiting = waiting, stamp = stamp,
                     confirmed = if confirm then Vartab.insert_set key confirmed else confirmed,
                     late = if by_prediction then Vartab.update (key, g) late else late,
                     binding =
                      if not (Vartab.defined decided key) andalso not by_prediction andalso
                        binding_now fs1
                      then Vartab.insert_set key binding else binding,
                     tainted = tainted orelse by_prediction orelse Vartab.defined late key,
                     deferral = deferral};
                  val (g'', Tg, st2) = inf coerce bs fr g' (tye_idx1, fs2);
                in
                  app coerce (spine_coerce_arg ctxt coerce g') bs fr (g', g'', Tg) (obj, obj', U)
                    st2
                end
            | NONE =>
                if is_waiting fs1 key then (Dot_Field.rebuild_node node obj', resT, (tye_idx1, fs1))
                else
                  let
                    val (tye, idx) = tye_idx1;
                    val S =
                      (case Type_Infer.deref tye resT of
                        TVar (_, S) => S
                      | _ => \<^sort>\<open>type\<close>);
                    val tye_idx2 = strong_unify ctxt (resT, blocked_var idx S) (tye, idx + 1);
                  in
                    (Dot_Field.rebuild_node node obj', resT,
                      (tye_idx2, add_waiting (fst tye_idx2) key fs1))
                  end)
          end
      | NONE => inf_plain coerce bs fr t st)
    and inf_plain _ _ _ (t as (Const (_, T))) st = (t, T, st)
      | inf_plain _ _ _ (t as (Free (_, T))) st = (t, T, st)
      | inf_plain _ _ _ (t as (Var (_, T))) st = (t, T, st)
      | inf_plain _ bs _ (t as (Bound i)) st =
          (t, snd (nth bs i handle General.Subscript => err_loose i), st)
      | inf_plain coerce bs fr (Abs (x, T, t)) st =
          let val (t', U, st') = inf coerce ((x, T) :: bs) fr t st
          in (Abs (x, T, t'), T --> U, st') end
      | inf_plain coerce bs fr0 (t $ u) (tye_idx, fs0) =
          (*the application frame*)
          frame fr0 fs0 (fn fr => fn fs =>
            let
              val (t', T, st') = inf coerce bs fr t (tye_idx, fs);
              val coerce' = spine_coerce_arg ctxt coerce t;
              val (u', U, st'') = inf coerce' bs fr u st';
            in app coerce coerce' bs fr (t, t', T) (u, u', U) st'' end)
    (*one application step, operator and operand already inferred: stock's step, a step that fails
      on a blocked variable committed in part, else stock's clash path*)
    and app coerce coerce' bs fr (t, t', T) (u, u', U) ((tye, idx), fs) =
      let
        val V = Type_Infer.mk_param idx [];
        val (tu, R, (tye_idx', fs')) =
          (t' $ u', V, (strong_unify ctxt (U --> V, T) (tye, idx + 1), fs))
            handle NO_UNIFIER (msg, tye') =>
              if not (no_waiting fs) andalso (has_blocked tye T orelse has_blocked tye U) then
                let val (R, tye_idx') = blocked_step ctxt V T U (tye, idx)
                in (t' $ u', R, (tye_idx', fs)) end
              else
                let
                  val (tu, st) =
                    local_clash ctxt bs
                      {recoerce = inf coerce bs fr, operand = operand coerce' bs fr (u, u', U),
                       kept = fn fs1 => Dot_Field.explicit (#decided fs1) u, raised = raised}
                      (err_appl_msg ctxt msg tye' bs (Dot_Field.explicit (#decided fs) t) T
                        (Dot_Field.explicit (#decided fs) u) U)
                      coerce' (t', T) U V ((tye, idx), fs);
                in (tu, V, st) end;
      in (tu, R, (tye_idx', check_decisions fr tye_idx' fs')) end
    (*the coerced operand of stock's clash path; while a field waits, everything inferred now is
      inferred again after its decision, so the operand already inferred is coerced*)
    and operand coerce' bs fr (u, u', U) co (tye_idx, fs1) =
      if no_waiting fs1 then inf coerce' bs fr (if is_identity co then u else co $ u) (tye_idx, fs1)
      else if is_identity co then (u', U, (tye_idx, fs1))
      else
        let val (co', coT, st_co) = inf coerce' bs fr co (tye_idx, fs1)
        in app coerce' (spine_coerce_arg ctxt coerce' co) bs fr (co, co', coT) (u, u', U) st_co end;

    (*the local pass.  defer: postpone re-runs (such a pass raises POSTPONED_FAILURE instead of
      failing or ending with fields waiting)*)
    fun local_pass defer =
      let
        (*the term's frame, which spans the rest of the batch*)
        fun go _ [] (st as (tye_idx, fs)) acc = (end_decisions tye_idx fs; (rev acc, st))
          | go fr0 (t :: rest) (tye_idx, fs0) acc =
              frame fr0 fs0 (fn fr => fn fs =>
                let val (t', _, st') = inf true [] fr t (tye_idx, fs)
                in go fr rest st' (t' :: acc) end);
        val fs0 =
          {decided = Vartab.empty, confirmed = Vartab.empty, waiting = no_waiting_fields,
           stamp = 0, late = Vartab.empty, binding = Vartab.empty, tainted = false,
           deferral = no_deferral defer};
      in
        let val (ts', (tye_idx, fs)) = go [] ts ((Vartab.empty, idx), fs0) [] in
          if no_waiting fs then Local_Done (ts', tye_idx, #decided fs, #confirmed fs, postponed fs)
          else if postponed fs then raise POSTPONED_FAILURE
          else Local_Waiting (binding_choices fs)
        end handle LOCAL_FAILURE failure => Local_Failed failure
      end;


    (* the global algorithm: learning runs *)

    (*generation at a carrier: the choice in decided, else the rule's at the node (D15: none while
      a parameter of the object type is in a subtype constraint generated so far), else the
      prediction's; a field without a choice is pending, its result unconstrained.  fields: the
      choices and the pending fields (latest first) of the run, the constraints of its earlier
      terms*)
    fun carrier fields gen app err coerce cs bs t tye_idx =
      (case dest_access t of
        NONE => NONE
      | SOME (acc as {key, payload, objT, resT, obj, ...}) =>
          let
            fun unify TU tye_idx =
              strong_unify ctxt TU tye_idx handle NO_UNIFIER (msg, _) => error (gen_msg err msg);
            val (U', tye_idx0, cs1) = gen coerce cs bs obj tye_idx;
            val tye_idx1 as (tye1, _) = unify (objT, U') tye_idx0;
            val {decided, pending, earlier} = ! fields;
            val field = Dot_Field.field_name payload;
            fun decide_here () =
              let val T = the_default U' (exact_object key) in
                if constrained tye1 (cs1 @ earlier) T then predicted_gen key
                else
                  let val T' = Dot_Field.norm tye1 T in
                    (case provisional T' (Dot_Field.decide ctxt rigid field T') of
                      Dot_Field.Choose g => SOME g
                    | Dot_Field.Wait => predicted_gen key
                    | d =>
                        error (Dot_Field.field_error_msg ctxt engine tye_idx1
                          (Dot_Field.with_object_type T acc, bs) d))
                  end
              end;
          in
            (case (case Vartab.lookup decided key of SOME g => SOME g | NONE => decide_here ()) of
              SOME g =>
                let
                  val g' = Dot_Field.node_instance key g;
                  val _ =
                    fields :=
                      {decided = Vartab.update (key, g) decided, pending = pending,
                        earlier = earlier};
                  val (Tg, tye_idx2, cs2) = gen coerce cs1 bs g' tye_idx1;
                  val (V, tye_idx3, cs3) =
                    app (update_coerce_arg ctxt coerce g') cs2 bs (g', Tg) (obj, U') tye_idx2;
                in SOME (V, unify (V, resT) tye_idx3, cs3) end
            | NONE =>
                (fields := {decided = decided, pending = key :: pending, earlier = earlier};
                 SOME (resT, tye_idx1, cs1)))
          end);

    (*tolerance (I12: a learning run that solves has a field pending): a constraint between type
      constructors that a coercion relates, which stock's global algorithm cannot solve (the local
      pass inserts that coercion), is dropped -- anywhere in it and in either direction where weak
      unification fails (it ignores variance)*)
    fun coerced_ctors tye (T, U) =
      (case (Type_Infer.deref tye T, Type_Infer.deref tye U) of
        (Type (a, Ts), Type (b, Us)) =>
          if a <> b then
            Symreltab.defined (coes_of ctxt) (a, b) orelse Symreltab.defined (coes_of ctxt) (b, a)
          else length Ts = length Us andalso exists (coerced_ctors tye) (Ts ~~ Us)
      | _ => false);

    (*after simplification (solved = false) and after solving, the fields that the rule decides
      now make the run start again with them at their nodes (RELEARN), except D13: a field whose
      object type shares a component of the simplified constraints with another pending field's
      result; and D15: before solving, a field whose object type (read through tye0) has a
      parameter in a constraint.  After solving the one decision on the solved typing for the
      oldest pending field gives its choice, its learning run (D14) and its rule text.  Before
      solving, a choice that refines its object type is not made (provisional).  rule: the local
      pass's rule error on a field, reported for that field when no run decides it*)
    fun decisions rule decided pending solved cs' tye0 tye_idx =
      let
        (*parameter components of the simplified constraints, through tye0*)
        val comp = Lazy.lazy (fn () =>
          let
            fun ps T = map #1 (params_of tye0 T);
            val adj = fold (fn ((T, U), _) => fn tab =>
              let val xs = ps T @ ps U
              in fold (fn x => Vartab.map_default (x, []) (fn ys => xs @ ys)) xs tab end)
              cs' Vartab.empty;
            fun visit r x comp =
              if Vartab.defined comp x then comp
              else
                fold (visit r) (the_default [] (Vartab.lookup adj x)) (Vartab.update (x, r) comp);
          in
            Vartab.fold (fn (x, _) => fn comp =>
              if Vartab.defined comp x then comp else visit x x comp) adj Vartab.empty
          end);
        fun root x = the_default x (Vartab.lookup (Lazy.force comp) x);
        fun comp_of T = map (fn (x, _) => root x) (params_of tye0 T);
        fun resT_of key = #resT (#1 (the_access key));
        fun depends key =
          let val c = comp_of (objT_of key) in
            exists (fn key' =>
              key' <> key andalso exists (member (op =) c) (comp_of (resT_of key'))) pending
          end;
        val learnt =
          fold (fn key => fn ds =>
            if depends key orelse not solved andalso constrained tye0 cs' (objT_of key) then ds
            else
              (case decide_on solved tye_idx key of
                Dot_Field.Choose g => Vartab.update (key, g) ds
              | Dot_Field.Wait => ds
              | d => if solved then ds else error (field_error_msg tye_idx key d)))
            pending Vartab.empty;

        (*dot_propagate: a field f learnt after solving whose result is one parameter, in a
          component K of the simplified constraints that no constraint ties to a type other than a
          parameter and that no other pending field's result reaches: the next run gives every
          parameter of K the type R that f's choice gives f's result, when R is ground and K's
          sorts admit it; so every deferred field whose object only such components determine is
          decided now, on that typing; its own result may feed the next component.  A component is
          fed once; a parameter that an object decided in this round mentions is never fed*)
        fun propagate learnt0 =
          let
            val tied =
              fold (fn ((T, U), _) => fn tab =>
                let val (T', U') = (Type_Infer.deref tye0 T, Type_Infer.deref tye0 U) in
                  if Type_Infer.is_paramT T' andalso Type_Infer.is_paramT U' then tab
                  else
                    fold (fn (x, _) => Vartab.insert_set (root x))
                      (params_of tye0 T' @ params_of tye0 U') tab
                end) cs' Vartab.empty;
            val sorted =
              fold (fn ((T, U), _) =>
                fold (fn (x, S) =>
                  if Sign.subsort thy (Sign.defaultS thy, S) then I else Vartab.insert_set (root x))
                  (params_of tye0 T @ params_of tye0 U)) cs' Vartab.empty;
            val feeders =
              fold (fn key =>
                fold (fn c => Vartab.map_default (c, []) (insert (op =) key))
                  (comp_of (resT_of key))) pending Vartab.empty;
            fun feeders_of c = the_default [] (Vartab.lookup feeders c);
            fun result_root key =
              (case Type_Infer.deref tye0 (resT_of key) of
                TVar (p, _) => if Type_Infer.is_param p then SOME (root p) else NONE
              | _ => NONE);
            (*the type that the choice g gives the result of the field key on the typing (tye, i)*)
            fun range_on (tye, i) key g =
              let
                val (g', i') = Dot_Field.fresh_instance g i;
                val gT = fastype_of g';
                val (tye', _) = strong_unify ctxt (objT_of key, domain_type gT) (tye, i');
              in Dot_Field.norm tye' (range_type gT) end;
            fun feed tye_idx decided_now fed key g =
              (case result_root key of
                NONE => NONE
              | SOME c =>
                  if Vartab.defined tied c orelse Vartab.defined sorted c orelse
                    not (null (Term.add_tvarsT (range_type (fastype_of g)) [])) orelse
                    Vartab.defined fed c orelse feeders_of c <> [key]
                  then NONE
                  else
                    let val rho = Type_Infer.deref (fst tye_idx) (resT_of key) in
                      (case (try (range_on tye_idx key) g, rho) of
                        (SOME R, TVar (p, _)) =>
                          if not (static_ground R) orelse not (Type_Infer.is_param p) orelse
                            exists (fn (k, _) => Term.exists_subtype (fn A => A = rho)
                              (Dot_Field.norm (fst tye_idx) (objT_of k))) (Vartab.dest decided_now)
                          then NONE
                          else
                            (case try (strong_unify ctxt (rho, R)) tye_idx of
                              SOME tye_idx' => SOME (c, tye_idx')
                            | NONE => NONE)
                      | _ => NONE)
                    end);
            fun loop [] _ decided_now = decided_now
              | loop ((key, g) :: work) (tye_idx, fed) decided_now =
                  (case feed tye_idx decided_now fed key g of
                    NONE => loop work (tye_idx, fed) decided_now
                  | SOME (c, tye_idx') =>
                      let
                        val fed' = Vartab.insert_set c fed;
                        fun ready key' =
                          not (Vartab.defined decided_now key') andalso
                            let val ocs = comp_of (objT_of key') in
                              member (op =) ocs c andalso forall (Vartab.defined fed') ocs
                            end;
                        val new = pending |> filter ready |> map_filter (fn key' =>
                          (case decide tye_idx' key' of
                            Dot_Field.Choose g' => SOME (key', g')
                          | _ => NONE));
                      in
                        loop (work @ new) (tye_idx', fed')
                          (fold Vartab.update new decided_now)
                      end);
          in loop (Vartab.dest learnt0) (tye_idx, Vartab.empty) learnt0 end;
        val learnt' =
          if solved andalso not (Vartab.is_empty learnt) then propagate learnt else learnt;

        fun relearn (key, g) = raise RELEARN (Vartab.update (key, g) decided);
        fun decide_solved key =
          let
            val d = decide tye_idx key;
            fun reject () =
              ((case rule of
                SOME {key = key', msg, ...} => if key' = key then error msg else ()
              | NONE => ());
               error (field_error_msg tye_idx key d));
          in
            (case d of
              Dot_Field.Choose g => relearn (key, g)
            | Dot_Field.Wait =>
                (case learn_d14 (tye_idx, decided) of
                  SOME C => raise RELEARN C
                | NONE => reject ())
            | _ => reject ())
          end;
      in
        if not (Vartab.is_empty learnt') then
          raise RELEARN (Vartab.merge (K true) (decided, learnt'))
        else if solved then (case pending of key :: _ => decide_solved key | [] => ())
        else ()
      end;

    (*learning runs from the choices C0 (stock's global algorithm on the dot form, the choices at
      their nodes, the other fields pending): the complete choices; a run with every field at its
      node that fails gives them too, for stock to elaborate*)
    fun learn err rule C0 =
      let
        val err' = err ++> "\n";
        val fields = Unsynchronized.ref {decided = C0, pending = [], earlier = []};
        val hooks =
          learning_hooks
           {carrier = carrier fields, tolerate_weak = coerced_ctors,
            learn = fn solved =>
              let val {decided, pending, ...} = ! fields
              in decisions rule decided (rev pending) solved end,
            explain = fn tu => Dot_Field.explicit (#decided (! fields)) tu};
        fun gen_single t (tye_idx, cs) =
          let
            val {decided, pending, ...} = ! fields;
            val _ = fields := {decided = decided, pending = pending, earlier = cs};
            val (_, tye_idx', cs') =
              Learning_Coercions.generate_constraints ctxt err' hooks t tye_idx;
          in (tye_idx', cs' @ cs) end;
        val (tye_idx, cs) = fold gen_single ts ((Vartab.empty, idx), []);
        val {decided, pending, ...} = ! fields;
      in
        if null pending then decided
        else
          (*the hook after solving always decides a field or rejects*)
          (ignore (Learning_Coercions.process_constraints ctxt err' hooks cs tye_idx);
           raise Fail "Subtyping.learn: no decision after solving")
      end
      handle RELEARN C => learn err rule C
        | exn as ERROR _ => if complete C0 then C0 else Exn.reraise exn;


    (* after the local pass *)

    (*a choice whose head carries a coercion_args declaration: the object was inferred under the
      outer flag, unlike stock on E(C)*)
    fun cargs_head C =
      Vartab.exists (fn (_, g) =>
        (case Term.head_of g of
          Const (c, _) => Symtab.defined (coerce_args_of ctxt) c
        | _ => false)) C;

    (*option b: learn C from nothing; when that learning is rejected and the local pass made
      binding choices, the default path*)
    fun option_b err rule C_bind default =
      (case Exn.result (learn err rule) Vartab.empty of
        Exn.Res C => explicit_E C
      | Exn.Exn exn =>
          if rejected exn andalso not (Vartab.is_empty C_bind) then default ()
          else Exn.reraise exn);

    (*the default path's rule error: one made on stock's local typing of E(C) is final, by stock's
      code shape, unless a choice's head carries a coercion_args declaration*)
    fun binding_rule_error C_bind (SOME {msg, binding = true, ...}) =
          if cargs_head C_bind then () else error msg
      | binding_rule_error _ _ = ();

    fun after_local (Local_Done (ts', tye_idx, C, confirmed, postponed)) =
          if cargs_head C then explicit_E C
          else
            (exit NONE (ts', tye_idx) C confirmed
              handle exn as LAST_CHECK _ => if postponed then replaced () else Exn.reraise exn)
      | after_local (Local_Waiting C_bind) =
          option_b no_err NONE C_bind (fn () =>
            explicit_E (learn no_err NONE C_bind))
      | after_local (Local_Failed (err, C_bind, rule)) =
          option_b err rule C_bind (fn () =>
            (binding_rule_error C_bind rule; explicit_E (learn err rule C_bind)))
    (*the local pass without deferral, in place of a deferring one that failed, ended with fields
      waiting, or whose last check failed; it runs without deferral, so it never falls back
      again*)
    and replaced () = after_local (local_pass false);
  in
    (case (SOME (local_pass true) handle POSTPONED_FAILURE => NONE) of
      NONE => replaced ()
    | SOME result => after_local result)
    handle LAST_CHECK msg => error msg
  end;



(** installation **)

(* term check *)

val coercion_enabled = Attrib.setup_config_bool \<^binding>\<open>coercion_enabled\<close> (K false);

(*stock's check, or with field accesses (dot syntax) the engine (Dot_Field.selection_check)*)
fun coercion_check ts ctxt =
  if Config.get ctxt Dot_Field.dot_syntax andalso Config.get ctxt coercion_enabled andalso
    exists Dot_Field.has_access ts
  then
    Dot_Field.selection_check (dot_infer_types (Config.put coercion_enabled false)) ts ctxt
  else
    Syntax_Phases.simple_check (op aconv)
      (fn ctxt => Config.get ctxt coercion_enabled ? coercion_infer_types ctxt) ts ctxt;

val _ =
  Theory.setup
    (Context.theory_map (Syntax_Phases.term_check' ~100 "coercions" coercion_check));


(* declarations *)

fun add_type_map raw_t context =
  let
    val ctxt = Context.proof_of context;
    val t = singleton (Variable.polymorphic ctxt) raw_t;

    fun err_str t = "\n\nThe provided function has the type:\n" ^
      Syntax.string_of_typ ctxt (fastype_of t) ^
      "\n\nThe general type signature of a map function is:" ^
      "\nf1 => f2 => ... => fn => C [x1, ..., xn] => C [y1, ..., yn]" ^
      "\nwhere C is a constructor and fi is of type (xi => yi) or (yi => xi).";

    val ((fis, T1), T2) = apfst split_last (strip_type (fastype_of t))
      handle List.Empty => error ("Not a proper map function:" ^ err_str t);

    fun gen_arg_var ([], []) = []
      | gen_arg_var (Ts, (U, U') :: Us) =
          if U = U' then
            if null (Term.add_tvarsT U []) then INVARIANT_TO U :: gen_arg_var (Ts, Us)
            else if Term.is_TVar U then INVARIANT :: gen_arg_var (Ts, Us)
            else error ("Invariant xi and yi should be variables or variable-free:" ^ err_str t)
          else
            (case Ts of
              [] => error ("Different numbers of functions and variant arguments\n" ^ err_str t)
            | (T, T') :: Ts =>
              if T = U andalso T' = U' then COVARIANT :: gen_arg_var (Ts, Us)
              else if T = U' andalso T' = U then CONTRAVARIANT :: gen_arg_var (Ts, Us)
              else error ("Functions do not apply to arguments correctly:" ^ err_str t));

    (*retry flag needed to adjust the type lists, when given a map over type constructor fun*)
    fun check_map_fun fis (Type (C1, Ts)) (Type (C2, Us)) _ =
          if C1 = C2 andalso not (null fis) andalso forall is_funtype fis
          then ((map dest_funT fis, Ts ~~ Us), C1)
          else error ("Not a proper map function:" ^ err_str t)
      | check_map_fun fis T1 T2 true =
          let val (fis', T') = split_last fis
          in check_map_fun fis' T' (T1 --> T2) false end
      | check_map_fun _ _ _ _ = error ("Not a proper map function:" ^ err_str t);

    val res = check_map_fun fis T1 T2 true;
    val res_av = gen_arg_var (fst res);
  in
    map_tmaps (Symtab.update (snd res, (t, res_av))) context
  end;

fun transitive_coercion ctxt tab G (a, b) =
  let
    fun safe_app t (Abs (x, T', u)) =
      let
        val t' = map_types Type_Infer.paramify_vars t;
      in
        singleton (coercion_infer_types ctxt) (Abs(x, T', (t' $ u)))
      end;
    val path = hd (Graph.irreducible_paths G (a, b));
    val path' = fst (split_last path) ~~ tl path;
    val coercions = map (fst o the o Symreltab.lookup tab) path';
    val trans_co = singleton (Variable.polymorphic ctxt)
      (fold safe_app coercions (mk_identity dummyT));
    val (Ts, Us) = apply2 dest_Type_args (Term.dest_funT (type_of trans_co));
  in
    (trans_co, ((Ts, Us), coercions))
  end;

fun add_coercion raw_t context =
  let
    val ctxt = Context.proof_of context;
    val t = singleton (Variable.polymorphic ctxt) raw_t;

    fun err_coercion () =
      error ("Bad type for a coercion:\n" ^
        Syntax.string_of_term ctxt t ^ " :: " ^
        Syntax.string_of_typ ctxt (fastype_of t));

    val (T1, T2) = Term.dest_funT (fastype_of t)
      handle TYPE _ => err_coercion ();

    val (a, Ts) = dest_Type T1
      handle TYPE _ => err_coercion ();

    val (b, Us) = dest_Type T2
      handle TYPE _ => err_coercion ();

    fun coercion_data_update (tab, G, _) =
      let
        val G' = maybe_new_nodes [(a, length Ts), (b, length Us)] G
        val G'' = Graph.add_edge_trans_acyclic (a, b) G'
          handle Graph.CYCLES _ => error (
            Syntax.string_of_typ ctxt T2 ^ " is already a subtype of " ^
            Syntax.string_of_typ ctxt T1 ^ "!\n\nCannot add coercion of type: " ^
            Syntax.string_of_typ ctxt (T1 --> T2));
        val new_edges =
          flat (Graph.dest G'' |> map (fn ((x, _), ys) => ys |> map_filter (fn y =>
            if Graph.is_edge G' (x, y) then NONE else SOME (x, y))));
        val G_and_new = Graph.add_edge (a, b) G';

        val tab' = fold
          (fn pair => fn tab =>
            Symreltab.update (pair, transitive_coercion ctxt tab G_and_new pair) tab)
          (filter (fn pair => pair <> (a, b)) new_edges)
          (Symreltab.update ((a, b), (t, ((Ts, Us), []))) tab);
      in
        (tab', G'', restrict_graph G'')
      end;
  in
    map_coes_and_graphs coercion_data_update context
  end;

fun delete_coercion raw_t context =
  let
    val ctxt = Context.proof_of context;
    val t = singleton (Variable.polymorphic ctxt) raw_t;

    fun err_coercion the =
      error ("Not" ^
        (if the then " the defined " else  " a ") ^ "coercion:\n" ^
        Syntax.string_of_term ctxt t ^ " :: " ^
        Syntax.string_of_typ ctxt (fastype_of t));

    val (T1, T2) = Term.dest_funT (fastype_of t)
      handle TYPE _ => err_coercion false;

    val (a, _) = dest_Type T1
      handle TYPE _ => err_coercion false;

    val (b, _) = dest_Type T2
      handle TYPE _ => err_coercion false;

    fun delete_and_insert tab G =
      let
        val pairs =
          Symreltab.fold (fn ((a, b), (_, (_, ts))) => fn pairs =>
            if member (op aconv) ts t then (a, b) :: pairs else pairs) tab [(a, b)];
        fun delete pair (G, tab) = (Graph.del_edge pair G, Symreltab.delete_safe pair tab);
        val (G', tab') = fold delete pairs (G, tab);
        fun reinsert pair (G, xs) =
          (case Graph.irreducible_paths G pair of
            [] => (G, xs)
          | _ => (Graph.add_edge pair G, (pair, transitive_coercion ctxt tab' G' pair) :: xs));
        val (G'', ins) = fold reinsert pairs (G', []);
      in
        (fold Symreltab.update ins tab', G'', restrict_graph G'')
      end

    fun show_term t =
      Pretty.block [Syntax.pretty_term ctxt t,
        Pretty.str " :: ", Syntax.pretty_typ ctxt (fastype_of t)];

    fun coercion_data_update (tab, G, _) =
      (case Symreltab.lookup tab (a, b) of
        NONE => err_coercion false
      | SOME (t', (_, [])) =>
          if t aconv t'
          then delete_and_insert tab G
          else err_coercion true
      | SOME (t', (_, ts)) =>
          if t aconv t' then
            error ("Cannot delete the automatically derived coercion:\n" ^
              Syntax.string_of_term ctxt t ^ " :: " ^
              Syntax.string_of_typ ctxt (fastype_of t) ^ "\n\n" ^
              Pretty.string_of
                (Pretty.big_list "Deleting one of the coercions:" (map show_term ts)) ^
              "\nwill also remove the transitive coercion.")
          else err_coercion true);
  in
    map_coes_and_graphs coercion_data_update context
  end;

fun print_coercions ctxt =
  let
    fun separate _ [] = ([], [])
      | separate P (x :: xs) = (if P x then apfst else apsnd) (cons x) (separate P xs);
    val (simple, complex) =
      separate (fn (_, (_, ((Ts, Us), _))) => null Ts andalso null Us)
        (Symreltab.dest (coes_of ctxt));
    fun show_coercion ((a, b), (t, ((Ts, Us), _))) =
      Pretty.item [Pretty.block
       [Syntax.pretty_typ ctxt (Type (a, Ts)), Pretty.brk 1,
        Pretty.str "<:", Pretty.brk 1,
        Syntax.pretty_typ ctxt (Type (b, Us)), Pretty.brk 3,
        Pretty.block
         [Pretty.keyword2 "using", Pretty.brk 1,
          Pretty.quote (Syntax.pretty_term ctxt t)]]];

    val type_space = Proof_Context.type_space ctxt;
    val tmaps =
      sort (Name_Space.extern_ord ctxt type_space o apply2 #1)
        (Symtab.dest (tmaps_of ctxt));
    fun show_map (c, (t, _)) =
      Pretty.block
       [Name_Space.pretty ctxt type_space c, Pretty.str ":",
        Pretty.brk 1, Pretty.quote (Syntax.pretty_term ctxt t)];
  in
   [Pretty.big_list "coercions between base types:" (map show_coercion simple),
    Pretty.big_list "other coercions:" (map show_coercion complex),
    Pretty.big_list "coercion maps:" (map show_map tmaps)]
  end |> Pretty.chunks |> Pretty.writeln;


(* attribute setup *)

val parse_coerce_args =
  Args.$$$ "+" >> K PERMIT || Args.$$$ "-" >> K FORBID || Args.$$$ "0" >> K LEAVE

val _ =
  Theory.setup
   (Attrib.setup \<^binding>\<open>coercion\<close>
      (Args.term >> (fn t => Thm.declaration_attribute (K (add_coercion t))))
      "declaration of new coercions" #>
    Attrib.setup \<^binding>\<open>coercion_delete\<close>
      (Args.term >> (fn t => Thm.declaration_attribute (K (delete_coercion t))))
      "deletion of coercions" #>
    Attrib.setup \<^binding>\<open>coercion_map\<close>
      (Args.term >> (fn t => Thm.declaration_attribute (K (add_type_map t))))
      "declaration of new map functions" #>
    Attrib.setup \<^binding>\<open>coercion_args\<close>
      (Args.const {proper = false, strict = false} -- Scan.lift (Scan.repeat1 parse_coerce_args) >>
        (fn spec => Thm.declaration_attribute (K (map_coerce_args (Symtab.update spec)))))
      "declaration of new constants with coercion-invariant arguments");


(* outer syntax commands *)

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>print_coercions\<close>
    "print information about coercions"
    (Scan.succeed (Toplevel.keep (print_coercions o Toplevel.context_of)));

end;
