(*  Title:      Pure/Syntax/dot_field.ML

Field access "x.f" and "(e).f" (dot syntax): the options, the carrier of a field access, the
field registry, the selection rule with its texts, and the last check.
*)

signature DOT_FIELD =
sig
  val dot_syntax: bool Config.T
  val dot_syntax_warning: bool Config.T
  type payload =
    {name: string, index: int, field: string, paren: bool, const_object: bool, serial: int,
      pos: Position.T}
  val is_payload: string -> bool
  val encode_payload: payload -> string
  val decode_payload: string -> payload option
  val field_name: payload -> string
  val field_position: payload -> Position.T
  val object_prefix: payload -> string
  val access_const: string
  val dest_payload: term -> payload option
  val rebuild_payload: string * typ -> term
  val dest_carrier: term -> (payload * term) option
  val fold_carriers: ((string * typ) list -> payload * term -> 'a -> 'a) -> term -> 'a -> 'a
  type access = {key: indexname, payload: payload, objT: typ, resT: typ, node: term, obj: term}
  val dest_access: term -> access option
  val with_object_type: typ -> access -> access
  val batch_access: (access * (string * typ) list) Vartab.table -> term -> access option
  val has_access: term -> bool
  val collect_accesses: term list -> (access * (string * typ) list) Vartab.table
  val rebuild_node: term -> term -> term
  val is_long_ident: string -> bool
  val is_ident_token: string * string -> bool
  val ident_marker: string * string -> term
  val prefix_range: string * Position.T -> int -> Position.T
  val accesses: {const_object: bool} -> string * Position.T -> int -> term -> term
  val paren_accesses: string * string -> term -> term
  val is_fixed: Proof.context -> string -> bool
  val is_const_name: Proof.context -> string -> bool
  val const_prefix: Proof.context -> int -> string list -> int option
  type registration = {field: string, term: term, serial: serial, global: bool, pos: Position.T}
  val pattern_of: registration -> typ
  val term_instance: theory -> term * term -> bool
  val identical_terms: theory -> term * term -> bool
  val registrations: Proof.context -> string -> registration list
  val defined: Proof.context -> string -> bool
  val unifier: theory -> {rigid: indexname -> bool} -> typ -> typ -> (Type.tyenv * int) option
  val fits: theory -> {rigid: indexname -> bool} -> typ -> typ -> bool
  val candidates: Proof.context -> {rigid: indexname -> bool} -> string -> typ -> term list
  val field_names: Proof.context -> {rigid: indexname -> bool} -> typ -> string list
  val declaration: {add: bool, pos: Position.T} -> (string * term) list -> Morphism.declaration
  val register_constants: string list -> Context.generic -> Context.generic
  val read_registration: Proof.context -> string * Input.source -> term
  val check_registration: Proof.context -> string * term -> string * term
  datatype conflict = Same_Pattern | Overlap of typ
  val conflicts: Proof.context -> string * term -> (conflict * term) list
  val report_conflicts: Proof.context -> string * term -> unit
  type site = {args: int, types: typ list}
  type occurrence = {name: string, const: string, pos: Position.T, site: site}
  val warning_texts: Proof.context -> occurrence list -> string list
  val emit_warnings: Proof.context -> occurrence list -> unit
  val access_tr': Proof.context -> term list -> term
  datatype decision = Choose of term | Wait | Empty | Ambiguous of term list
  val decide: Proof.context -> {rigid: indexname -> bool} -> string -> typ -> decision
  val norm: typ Vartab.table -> typ -> typ
  val fresh_instance: term -> int -> term * int
  type waiting_index = {roots: Inttab.set Vartab.table, inner: Inttab.set Vartab.table}
  val no_waiting_index: waiting_index
  val place: typ Vartab.table -> int -> typ -> waiting_index -> waiting_index
  val take_bound: typ Vartab.table -> waiting_index -> Inttab.set * waiting_index
  type engine =
   {rigid: indexname -> bool,
    unify: typ * typ -> typ Vartab.table * int -> typ Vartab.table * int,
    prep_output: typ Vartab.table -> (string * typ) list -> term list -> typ list ->
      term list * typ list}
  val field_error_msg: Proof.context -> engine -> typ Vartab.table * int ->
    access * (string * typ) list -> decision -> string
  val last_check: Proof.context -> engine -> typ Vartab.table * int ->
    (access * (string * typ) list) Vartab.table -> term Vartab.table -> unit
  val node_instance_parts: indexname -> term -> typ * term
  val node_instance: indexname -> term -> term
  val dest_node_instance: term -> (int * term) option
  val explicit: term Vartab.table -> term -> term
  val selection_check:
    (Proof.context -> term list ->
      term list * ((access * (string * typ) list) Vartab.table * term Vartab.table)) ->
    term list -> Proof.context -> (term list * Proof.context) option
  val selections: Proof.context -> term Inttab.table
  val head_constant: Proof.context -> term -> string option
  val marker: Proof.context -> engine -> typ Vartab.table -> access * (string * typ) list -> term
  val is_marker: term -> bool
  val check_markers: Proof.context -> engine -> term list -> term list
  val report_unresolved: Proof.context -> engine -> (payload -> bool) -> term list -> unit
  exception LEARNT
  val learning: Proof.context -> (term list -> unit) option
  val guard: term list -> bool
  val learn: (Proof.context -> Proof.context) -> engine -> Proof.context ->
    (access * (string * typ) list) Vartab.table -> term list -> term Vartab.table
end;

structure Dot_Field: DOT_FIELD =
struct

(** options **)

val dot_syntax = Config.declare_bool ("dot_syntax", \<^here>) (K false);
val dot_syntax_warning = Config.declare_bool ("dot_syntax_warning", \<^here>) (K true);



(** carrier **)

(* payload *)

(*name: the written long identifier "x.f.g", or the written field token "f.g" after the dot of
  "(e).f.g" (paren); index: the segment of name that is this field; field: that segment;
  const_object: the object of this field is the constant that the written prefix reads as
  (decode_ident, rows 5 and 6); serial: 0 when parsed, a serial of its own inside the check phase;
  pos: the position of that segment in the written token*)
type payload =
  {name: string, index: int, field: string, paren: bool, const_object: bool, serial: int,
    pos: Position.T};

(*plain text, so that a printed carrier stays readable:
  "dot_field index=2 field=xpos offset=18 end_offset=22 id=5 name=s.start.xpos";
  the values before name escape "%", "=", blanks and control characters as %XX; name comes last
  and as written (a token has no blank), so that decoding does not depend on its length*)

val payloadN = "dot_field";
val indexN = "index";
val fieldN = "field";
val parenN = "paren";
val const_objectN = "const_object";
val name_sep = " " ^ Markup.nameN ^ "=";

val is_payload = String.isPrefix (payloadN ^ " ");

local

fun escape_char c =
  if c = "%" orelse c = "=" orelse ord c < 33 orelse ord c = 127
  then "%" ^ StringCvt.padLeft #"0" 2 (Int.fmt StringCvt.HEX (ord c)) else c;

fun unescape s =
  (case space_explode "%" s of
    [] => ""
  | x :: xs =>
      x ^ implode (xs |> map (fn y =>
        (case StringCvt.scanString (Int.scan StringCvt.HEX) (String.substring (y, 0, 2)) of
          SOME i => chr i ^ String.extract (y, 2, NONE)
        | NONE => raise Fail "Dot_Field.decode_payload"))));

fun dest_prop s =
  (case first_field "=" s of
    SOME (k, v) => (k, unescape v)
  | NONE => raise Fail "Dot_Field.decode_payload");

in

fun encode_payload ({name, index, field, paren, const_object, serial, pos}: payload) =
  let
    val props =
      (indexN, Value.print_int index) :: (fieldN, field) ::
        Properties.make_bool parenN paren @ Properties.make_bool const_objectN const_object @
        Properties.make_int Markup.serialN serial @ Position.properties_of pos;
    fun print_prop (k, v) = k ^ "=" ^ translate_string escape_char v;
  in space_implode " " (payloadN :: map print_prop props) ^ name_sep ^ name end;

(*the first name_sep ends the escaped values*)
fun decode_payload x =
  if not (is_payload x) then NONE
  else
    let val (props, name) = Substring.position name_sep (Substring.full x) in
      if Substring.isEmpty name then NONE
      else
        (case try (map dest_prop) (tl (space_explode " " (Substring.string props))) of
          SOME props' =>
            (case (Properties.get props' indexN, Properties.get props' fieldN) of
              (SOME index, SOME field) =>
                SOME {name = Substring.string (Substring.triml (size name_sep) name),
                  index = Value.parse_int index, field = field,
                  paren = Properties.get_bool props' parenN,
                  const_object = Properties.get_bool props' const_objectN,
                  serial = Properties.get_int props' Markup.serialN,
                  pos = Position.of_properties props'}
            | _ => NONE)
        | NONE => NONE)
    end;

end;

fun field_name ({field, ...}: payload) = field;
fun field_position ({pos, ...}: payload) = pos;

(*the first k segments of the long name a*)
fun prefix_of a k = Long_Name.implode (take k (Long_Name.explode a));

(*the written segments before this field: the object of an identifier access, the preceding
  fields of a paren access*)
fun object_prefix ({name, index, ...}: payload) = prefix_of name index;


(* carrier terms *)

(*the declared constant "Pure.dot_access :: 'n => 'a => 'b" (pure_thy.ML) applied to the
  payload and the object.  The payload is a schematic variable with index 0 outside the check
  phase (Specification.close_form binds free variables) and a free variable inside it
  (Proof_Context.expand_abbrevs rejects schematic ones)*)

val access_const = "Pure.dot_access";

fun dest_payload p =
  (case Type.strip_constraints p of
    Var ((x, 0), _) => decode_payload x
  | Free (x, _) => decode_payload x
  | _ => NONE);

(*the payload x of type T inside the check phase: its serial is its own*)
fun rebuild_payload (x, T) =
  (case decode_payload x of
    SOME {name, index, field, paren, const_object, pos, ...} =>
      Free (encode_payload
        {name = name, index = index, field = field, paren = paren, const_object = const_object,
          serial = serial (), pos = pos}, T)
  | NONE => raise Fail "Dot_Field.rebuild_payload");

(*any carrier*)
fun dest_carrier (Const (c, _) $ p $ x) =
      if c = access_const then Option.map (rpair x) (dest_payload p) else NONE
  | dest_carrier _ = NONE;

(*f bs (payload, node) on every carrier node of t, its object first; bs: the binders around it,
  innermost first*)
fun fold_carriers f =
  let
    fun fold_term bs t =
      (case dest_carrier t of
        SOME (payload, obj) => fold_term bs obj #> f bs (payload, t)
      | NONE =>
          (case t of
            u $ v => fold_term bs u #> fold_term bs v
          | Abs (x, T, u) => fold_term ((x, T) :: bs) u
          | _ => I));
  in fold_term [] end;

fun carrier_object_type (Const (_, T) $ _ $ _) = domain_type (range_type T)
  | carrier_object_type t = raise TERM ("Dot_Field.carrier_object_type", [t]);

(*a carrier prepared for type inference; key = the result parameter of this occurrence*)
type access = {key: indexname, payload: payload, objT: typ, resT: typ, node: term, obj: term};

(*the key of a prepared carrier; its payload is not read*)
fun carrier_key (Const (c, T) $ _ $ _) =
      if c <> access_const then NONE
      else
        (case body_type T of
          TVar (key, _) => if Type_Infer.is_param key then SOME key else NONE
        | _ => NONE)
  | carrier_key _ = NONE;

(*a prepared carrier as an access, its payload given by read key p*)
fun read_access read (t as (Const (_, T) $ p $ x)) =
      (case carrier_key t of
        SOME key =>
          Option.map (fn payload =>
            {key = key, payload = payload, objT = carrier_object_type t, resT = body_type T,
              node = t, obj = x})
            (read key p)
      | NONE => NONE)
  | read_access _ _ = NONE;

val dest_access = read_access (K dest_payload);

fun with_object_type T ({key, payload, resT, node, obj, ...}: access) =
  {key = key, payload = payload, objT = T, resT = resT, node = node, obj = obj};

val has_access = Term.exists_Const (fn (c, _) => c = access_const);

(*every prepared carrier of a batch, with the binders around it (innermost first)*)
fun collect_accesses ts =
  fold (fold_carriers (fn bs => fn (payload, node) =>
    (case read_access (K (K (SOME payload))) node of
      SOME (a as {key, ...}) => Vartab.update (key, (a, bs))
    | NONE => I))) ts Vartab.empty;

(*dest_access on the terms of a batch whose accesses are accs: a payload is not read again*)
fun batch_access accs =
  read_access (fn key => fn p =>
    (case Vartab.lookup accs key of
      SOME ({payload, ...}: access, _) => SOME payload
    | NONE => dest_payload p));

fun rebuild_node (c $ p $ _) x = c $ p $ x
  | rebuild_node t _ = raise TERM ("Dot_Field.rebuild_node", [t]);



(** long identifiers in term position **)

fun is_long_ident a =
  let val segs = Long_Name.explode a in
    length segs >= 2 andalso
      forall (fn s => Symbol_Pos.is_identifier s andalso not (Name.is_internal s)) segs
  end;

(*the token a at encoded position p of a _constrain node is split under dot syntax*)
fun is_ident_token (a, p) =
  exists_string (fn c => c = ".") a andalso Term_Position.detect p andalso is_long_ident a;

(*the constraint slot of the token: the first segment, where binders see it, the position, and
  the whole name, so that decode_term can tell whether a translation renamed the token*)
fun ident_marker (a, p) =
  Syntax.const Term_Position.dot_identN $ Syntax.free (hd (Long_Name.explode a)) $
    Syntax.free p $ Syntax.var (a, 0);

(*the range of the first k segments of the written token a at pos*)
fun prefix_range (a, pos) k = #1 (Symbol_Pos.range (Symbol_Pos.explode (prefix_of a k, pos)));

(*the segments of the written token a at pos, each with its position*)
fun segments (a, pos) =
  let
    fun split ss =
      (case chop_prefix (fn (s, _) => s <> ".") ss of
        (seg, []) => [seg]
      | (seg, _ :: rest) => seg :: split rest);
  in
    split (Symbol_Pos.explode (a, pos))
    |> map (fn seg => (Symbol_Pos.content seg, #1 (Symbol_Pos.range seg)))
  end;

(*the carriers with constant c of the fields k .. n-1 of the written token a at pos around t; the
  one place where a payload's field and its position are taken from the token*)
fun carriers c {paren, const_object} (a, pos) k t =
  fold_index (fn (j, (field, field_pos)) => fn u =>
    let
      val payload =
        {name = a, index = k + j, field = field, paren = paren,
          const_object = const_object andalso j = 0, serial = 0, pos = field_pos};
    in Syntax.const c $ Syntax.var (encode_payload payload, 0) $ u end)
    (drop k (segments (a, pos))) t;

(*the carriers of the fields k .. n-1 of a around the decoded object t; const_object: t is the
  constant that the first k segments read as*)
fun accesses {const_object} =
  carriers access_const {paren = false, const_object = const_object};

(*"(e).f.g": the carriers of the field token f.g (at encoded position p) around e; built before
  parse translations, hence the marked constant*)
fun paren_accesses (f, p) =
  let val pos = (case Term_Position.decode p of {pos, ...} :: _ => pos | [] => Position.none)
  in carriers (Lexicon.mark_const access_const) {paren = true, const_object = false} (f, pos) 0 end;

(*exactly when Proof_Context.lookup_free reads x as a fixed variable*)
fun is_fixed ctxt x = not (Variable.is_const ctxt x) andalso is_some (Variable.lookup_fixed ctxt x);

(*c is a constant, without exception and without completion*)
fun is_const_name ctxt c = Variable.is_const ctxt c orelse Proof_Context.is_const_declared ctxt c;

(*the length of the longest prefix of the segments, at least min and fewer than all, that is a
  constant*)
fun const_prefix ctxt min segs =
  let
    fun find k =
      if k < min then NONE
      else if is_const_name ctxt (Long_Name.implode (take k segs)) then SOME k
      else find (k - 1);
  in find (length segs - 1) end;



(** registry **)

(* registrations *)

(*term: the registered term, read in its context, as morphisms transform it; serial: of the
  registration this copy was made from; global: added to a theory, not to a proof context*)
type registration = {field: string, term: term, serial: serial, global: bool, pos: Position.T};

(*the pattern type of a registered term: the type of the object*)
fun pattern t = domain_type (fastype_of t);
fun pattern_of ({term, ...}: registration) = pattern term;

fun key_of field T = Const (field, dummyT) $ Net.encode_type T;

(*the same copy: storage only*)
fun eq_copy (r1: registration, r2: registration) =
  #serial r1 = #serial r2 andalso #global r1 = #global r2 andalso
  #field r1 = #field r2 andalso #term r1 aconv #term r2;

structure Data = Generic_Data
(
  type T = {regs: registration Item_Net.T, local_serials: Inttab.set};
  val empty =
   {regs = Item_Net.init eq_copy (fn r => [key_of (#field r) (pattern_of r)]),
    local_serials = Inttab.empty};
  fun merge ({regs = regs1, local_serials = s1}, {regs = regs2, local_serials = s2}) =
    {regs = Item_Net.merge (regs1, regs2), local_serials = Inttab.merge (K true) (s1, s2)};
);


(* the one relation: type instance on beta-eta-normal terms, sorts respected *)

fun term_instance thy (u, t) =
  let
    val u' = Envir.beta_eta_contract u;
    val t' = Logic.incr_indexes ([], maxidx_of_term u' + 1) (Envir.beta_eta_contract t);
  in can (Pattern.first_order_match thy (t', u')) (Vartab.empty, Vartab.empty) end;

fun identical_terms thy (t, u) =
  t aconv u orelse (term_instance thy (t, u) andalso term_instance thy (u, t));

fun identical thy (r1: registration, r2: registration) =
  #field r1 = #field r2 andalso identical_terms thy (#term r1, #term r2);

(*drop a registered term that is a type instance of another one; of identical ones keep the
  first (registry order: newest first).  A type instance is the same term up to its types, so
  only such terms are compared: linear in the terms unless they differ in their types only*)
fun subsume thy ts =
  let
    val untyped = Term.map_types (K dummyT) o Envir.beta_eta_contract;
    val uts = map_index (fn (i, t) => (untyped t, (i, t))) ts;
    val groups = fold_rev Termtab.cons_list uts Termtab.empty;
    fun dropped (u, (i, t)) =
      exists (fn (j, t') =>
          i <> j andalso term_instance thy (t, t') andalso
          (j < i orelse not (term_instance thy (t', t))))
        (Termtab.lookup_list groups u);
  in map_filter (fn ut => if dropped ut then NONE else SOME (#2 (#2 ut))) uts end;


(* visible registrations *)

(*in a proof context, a theory copy is hidden if the context holds a copy of the same
  registration added to it, or if it is identical to such a hidden copy*)
fun visible thy local_serials rs =
  if Inttab.is_empty local_serials then rs
  else
    let
      fun own_hidden ({global, serial, ...}: registration) =
        global andalso Inttab.defined local_serials serial;
      val hidden = filter own_hidden rs;
      fun is_hidden r =
        own_hidden r orelse #global r andalso exists (fn h => identical thy (r, h)) hidden;
    in filter_out is_hidden rs end;

(*the visible registrations named field whose pattern the net lets through for T*)
fun lookup_data thy ({regs, local_serials}: Data.T) field T =
  Item_Net.retrieve regs (key_of field T)
  |> filter (fn r => #field r = field)
  |> visible thy local_serials;

fun lookup context = lookup_data (Context.theory_of context) (Data.get context);

fun registrations ctxt field =
  lookup (Context.Proof ctxt) field (TVar ((Name.aT, 0), []));

val defined = not o null oo registrations;


(* the selection helper: U for the object type T *)

(*the one unification of the registry: T, with every type variable for which rigid holds
  frozen, against the pattern P renamed apart.  rigid = K false: unifiable; rigid = K true: T is
  an instance of P (matches).  The engines pass rigid = not o Type_Infer.is_param*)
fun freeze rigid =
  Term.map_atyps (fn T as TVar (xi, S) =>
      if rigid xi then TFree ("?" ^ Term.string_of_vname xi, S) else T
    | T => T);

fun unifier thy {rigid} T P =
  let
    val T' = freeze rigid T;
    val P' = Logic.incr_tvar (maxidx_of_typ T' + 1) P;
  in try (Sign.typ_unify thy (T', P')) (Vartab.empty, Term.maxidx_typ P' (maxidx_of_typ T')) end;

fun fits thy rigid T P = is_some (unifier thy rigid T P);

(*T is an instance of the pattern P*)
fun matches thy = fits thy {rigid = K true};

(*the registered terms of the candidates*)
fun candidates ctxt rigid field T =
  let val thy = Proof_Context.theory_of ctxt in
    lookup (Context.Proof ctxt) field T
    |> map_filter (fn r => if fits thy rigid T (pattern_of r) then SOME (#term r) else NONE)
    |> subsume thy
  end;

fun field_names ctxt rigid T =
  let
    val thy = Proof_Context.theory_of ctxt;
    val {regs, local_serials} = Data.get (Context.Proof ctxt);
  in
    visible thy local_serials (Item_Net.content regs)
    |> filter (fits thy rigid T o pattern_of)
    |> map #field |> sort_distinct string_ord
  end;


(* the rule on the candidates U of the object type T *)

datatype decision = Choose of term | Wait | Empty | Ambiguous of term list;

(*T as the check phase fixes it without the field (Proof_Context.prepare_patterns): every
  inference parameter left in it is a fixed type variable, of the object logic's base sort if it
  has no sort and a term is read; a pattern keeps the sort*)
fun fixed_type ctxt T =
  Logic.dest_type
    (singleton (Type_Infer.fixate ctxt (Proof_Context.pattern_mode ctxt)) (Logic.mk_type T));

(*the matching candidates of U that no other matching one is more specific than (in the order
  of U), and those that only unify with T.  One candidate is more specific than another if its
  pattern is an instance of the other's, not conversely; a matching candidate that another
  matching one is more specific than can never be chosen, as the other one keeps matching.
  Of the patterns that no other one is more specific than, one of each class of equal ones is
  kept, and a candidate is compared with the kept ones: linear in U for a given number of them*)
fun contenders ctxt T U =
  let
    val thy = Proof_Context.theory_of ctxt;
    val (matching, others) = List.partition (matches thy (fixed_type ctxt T) o pattern) U;
    fun add P Ps =
      if exists (fn Q => matches thy Q P) Ps then Ps
      else filter_out (matches thy P) Ps @ [P];
    val unbeaten = fold (add o pattern) matching [];
  in (filter (fn t => exists (matches thy (pattern t)) unbeaten) matching, others) end;

(*of several candidates the one more specific than every other is chosen, once all of them
  match T: one that only unifies with T may still come to match or drop out, so the rule waits,
  unless none of these can come to be more specific than every matching one*)
fun select _ _ [] = Empty
  | select _ _ [t] = Choose t
  | select ctxt T U =
      (case contenders ctxt T U of
        ([t], []) => Choose t
      | ([], _) => Wait
      | ([_], _) => Wait
      | (ts, others) =>
          let
            val thy = Proof_Context.theory_of ctxt;
            fun below_all u = forall (fn t => matches thy (pattern u) (pattern t)) ts;
          in if exists below_all others then Wait else Ambiguous ts end);


(* insertion, removal, the declaration *)

fun insert (r: registration) (data as {regs, local_serials}: Data.T) =
  if Item_Net.member regs r then data
  else
    {regs = Item_Net.update r regs,
     local_serials =
      if #global r then local_serials else Inttab.insert_set (#serial r) local_serials};

(*the visible registrations named field whose terms are identical to t*)
fun remove thy (field, t) (data as {regs, local_serials}: Data.T) =
  let
    val removed =
      lookup_data thy data field (domain_type (fastype_of t))
      |> filter (fn r => identical_terms thy (#term r, t));
  in {regs = fold Item_Net.remove removed regs, local_serials = local_serials} end;

(*a copy is kept if it has no schematic term variable and every free variable is fixed in the
  receiving context; the data is updated once*)
fun declaration {add, pos} regs : Morphism.declaration =
  let val regs' = map (fn (field, t) => (field, t, serial ())) regs in
    fn phi => fn context =>
      let
        val (global, fixed) =
          (case context of
            Context.Theory _ => (true, K false)
          | Context.Proof ctxt => (false, Variable.is_fixed ctxt));
        val add' = Syntax.effective_polarity_generic context add;
        val dropped =
          Term.exists_subterm (fn Var _ => true | Free (x, _) => not (fixed x) | _ => false);
        val thy = Context.theory_of context;
        fun apply (field, t, s) =
          let val t' = Morphism.term phi t in
            if dropped t' then I
            else if add' then
              insert {field = field, term = t', serial = s, global = global, pos = pos}
            else remove thy (field, t')
          end;
      in Data.map (fold apply regs') context end
  end;

(*the record package's registration of its fields: silent*)
fun register_constants cs context =
  let
    val consts = Sign.consts_of (Context.theory_of context);
    val regs = map (fn c => (Long_Name.base_name c, Const (c, Consts.the_constraint consts c))) cs;
  in declaration {add = true, pos = Position.thread_data ()} regs Morphism.identity context end;


(* reading and checking a registration *)

fun typed_text ctxt (t, T) = Syntax.string_of_term ctxt t ^ " :: " ^ Syntax.string_of_typ ctxt T;
fun registered_text ctxt t = typed_text ctxt (t, fastype_of t);

(*the written constant (also an abbreviation, also with a type constraint), read as
  Syntax.read_term reads it*)
fun read_registration ctxt (field, source) =
  let
    val t = Syntax.parse_term ctxt (Syntax.implode_input source);
    val _ =
      (case Type.strip_constraints t of
        Const _ => ()
      | _ =>
          error ("The term of field " ^ quote field ^
            " is not a constant; a field is registered with a constant or an abbreviation:\n  " ^
            Input.string_of source));
  in singleton (Variable.polymorphic ctxt) (Syntax.check_term ctxt t) end;

fun check_registration ctxt (field, t) =
  let
    val _ = Symbol_Pos.is_identifier field orelse
      error ("Bad field name " ^ quote field ^ ": a field name is an identifier without dots");
    fun err msg = error (msg ^ "\n  " ^ registered_text ctxt t);
    val _ = can dest_funT (fastype_of t) orelse
      err ("The term of field " ^ quote field ^
        " is not a function; it must take the object as its first argument:");
    val _ = not (Term.exists_subterm is_Var t) orelse
      err ("The term of field " ^ quote field ^ " contains schematic variables:");
    val frees = Term.add_frees t [] |> filter_out (Variable.is_fixed ctxt o #1);
    val _ = null frees orelse
      err ("The term of field " ^ quote field ^ " mentions variables that are not fixed here: " ^
        commas (map #1 frees));
  in (field, t) end;


(* conflicts of an explicit registration *)

(*Overlap: the common instances of the two patterns*)
datatype conflict = Same_Pattern | Overlap of typ;

(*against the registrations the rule considers.  One that is more specific or more general than
  the new one is no conflict; neither is an overlap on whose common instances the rule chooses*)
fun conflicts ctxt (field, t) =
  let
    val thy = Proof_Context.theory_of ctxt;
    val P = pattern t;
    val us = subsume thy (map #term (lookup (Context.Proof ctxt) field P));
    fun ambiguous T =
      (case select ctxt T (subsume thy (filter (matches thy T o pattern) (t :: us))) of
        Ambiguous _ => true
      | _ => false);
    fun classify u =
      if term_instance thy (t, u) orelse term_instance thy (u, t) then NONE
      else
        let val Q = pattern u in
          (case (matches thy P Q, matches thy Q P) of
            (true, true) => SOME Same_Pattern
          | (false, false) =>
              (case unifier thy {rigid = K false} P Q of
                SOME (tyenv, _) =>
                  let val common = Envir.norm_type tyenv P
                  in if ambiguous common then SOME (Overlap common) else NONE end
              | NONE => NONE)
          | _ => NONE)
        end;
  in map_filter (fn u => Option.map (rpair u) (classify u)) us end;

(*an error for the same pattern, a warning for an overlap*)
fun report_conflicts ctxt (field, t) =
  let
    val P = pattern t;
    val new = "Field " ^ quote field ^ " of " ^ registered_text ctxt t;
    val dot = quote ("x." ^ field);
    fun old u = "\n  " ^ registered_text ctxt u ^ "\n";
    fun text (Same_Pattern, u) =
          "Field " ^ quote field ^ " cannot be registered: on every object of type " ^
          Syntax.string_of_typ ctxt P ^ " it would be ambiguous with" ^ old u ^
          "Register it under another name, or remove the existing field with dot_field del."
      | text (Overlap common, u) =
          new ^ " overlaps the existing field " ^ quote field ^ old u ^
          dot ^ " is ambiguous on objects of type " ^ Syntax.string_of_typ ctxt common ^ ".";
    val cs = conflicts ctxt (field, t);
  in
    (case find_first (fn (Same_Pattern, _) => true | _ => false) cs of
      SOME c => error (text c)
    | NONE => List.app (warning o text) cs)
  end;



(** lists in messages **)

(*every list of fields shows at most 5 items*)
val bound = 5;
fun bounded xs = (take bound xs, length xs > bound);

(*only the shown items are rendered*)
fun bounded_lines render xs =
  let val (shown, more) = bounded xs
  in map (prefix "  " o render) shown @ (if more then ["  \<dots>"] else []) end;

fun bounded_commas xs =
  let val (shown, more) = bounded xs
  in commas shown ^ (if more then ", \<dots>" else "") end;

(*the constant that the field segment shows for the registered term t: its head after folding
  abbreviations, as printing shows it*)
fun head_constant ctxt t =
  (case head_of (Envir.eta_contract (Proof_Context.contract_abbrevs ctxt t)) of
    Const (c, _) => SOME c
  | _ => NONE);

(*candidates in the order of their printed names: the head constant (as the field markup), else
  the printed term*)
fun sort_candidates ctxt gs =
  let
    fun key g =
      (case head_constant ctxt g of
        SOME c => Proof_Context.extern_const ctxt c
      | NONE => Syntax.string_of_term ctxt g);
  in map (fn g => (key g, g)) gs |> sort (string_ord o apply2 #1) |> map #2 end;



(** warning: a long identifier read as a constant could also be read as field access **)

(*the place of the identifier, as decode_term knows it: the number of arguments it is applied
  to, the types written directly on it (raw)*)
type site = {args: int, types: typ list};

(*a long identifier of a parse tree that decode_term read as the constant const*)
type occurrence = {name: string, const: string, pos: Position.T, site: site};

local

(*a reading: the term so far, under one type unifier*)
type state = {t: term, env: Type.tyenv, maxidx: int};

fun fresh_tvar S ({t, env, maxidx}: state) =
  (TVar (("'dot", maxidx + 1), S), {t = t, env = env, maxidx = maxidx + 1});

(*a type as inference treats it: dummies are fresh schematic type variables (flexible), every
  other type variable is rigid*)
fun inference_view T st =
  let
    fun prep (Type ("dummy", [])) st = fresh_tvar [] st
      | prep (Type (a, Ts)) st = fold_map prep Ts st |>> (fn Ts' => Type (a, Ts'))
      | prep (TFree ("'_dummy_", S)) st = fresh_tvar S st
      | prep (TVar (xi, S)) st = (TFree (Term.string_of_vname xi, S), st)
      | prep T st = (T, st);
  in prep T st end;

(*a type written in the text, as the check phase reads it; no reports*)
fun written_type ctxt raw_T =
  inference_view (Syntax.check_typ (Context_Position.set_visible false ctxt) raw_T);

fun unify ctxt TU ({t, env, maxidx}: state) =
  let val (env', maxidx') = Type.unify (Proof_Context.tsig_of ctxt) TU (env, maxidx)
  in {t = t, env = env', maxidx = maxidx'} end;

(*the object: the constant that the longest proper prefix of the segments that is a constant
  reads as; the other segments are the fields*)
fun object ctxt segs =
  let
    fun reading k =
      (case try (#1 o Proof_Context.check_const {proper = true, strict = false} ctxt)
          (Long_Name.implode (take k segs), []) of
        SOME (Const (c, _)) =>
          let val T = Consts.the_constraint (Proof_Context.consts_of ctxt) c in
            SOME ({t = Const (c, T), env = Vartab.empty, maxidx = maxidx_of_typ T}, drop k segs)
          end
      | _ => NONE);
  in Option.mapPartial reading (const_prefix ctxt 1 segs) end;

(*the type that a reading has reached*)
fun reached ({t, env, ...}: state) = Envir.norm_type env (fastype_of t);

(*readings that reach the same type, as one: a reading of them, and for each field so far (the
  last one first) the registered terms that they take for it*)
type path = state * term list list;

(*the identifier read as field access: each field with the registered terms that the complete
  readings take for it, complete readings (one of those that reach the same type), and whether
  readings were left out*)
type readings = {fields: (string * term list) list, complete: term list, cut: bool};

(*every way to continue the readings with the field f: the candidates that the selection rule
  does not rule out on the type reached (contenders), each applied*)
fun step ctxt f =
  maps (fn (st as {t, env, maxidx}, picks): path =>
    let
      val T = reached st;
      fun apply g =
        let
          val g' = Logic.incr_indexes ([], maxidx + 1) g;
          val st' = {t = g' $ t, env = env, maxidx = Int.max (maxidx, maxidx_of_term g')};
        in Option.map (rpair ([g] :: picks)) (try (unify ctxt (T, pattern g')) st') end;
    in map_filter apply (op @ (contenders ctxt T (candidates ctxt {rigid = K false} f T))) end);

(*the readings to continue with the field f: those that reach the same type continue as one,
  and of the types that f has a candidate for at most bound are followed, so that a chain of
  fields adds up instead of multiplying.  Also whether a type was left out: then readings are
  missing, and with them possibly the warning*)
fun followed ctxt f rs =
  let
    val thy = Proof_Context.theory_of ctxt;
    fun same T T' = matches thy T T' andalso matches thy T' T;
    fun continues T = not (null (candidates ctxt {rigid = K false} f T));
    fun add (st, picks) (kept, cut) =
      let val T = reached st in
        (case find_index (fn (T', _) => same T T') kept of
          ~1 =>
            if not (continues T) then (kept, cut)
            else if length kept = bound then (kept, true)
            else (kept @ [(T, (st, picks))], cut)
        | i => (nth_map i (apsnd (apsnd (map2 (union (op aconv)) picks))) kept, cut))
      end;
  in apfst (map #2) (fold add rs ([], false)) end;

(*the reading fits the text around the identifier: the types written on it, and the number of
  arguments it is applied to*)
fun fits_site ctxt ({args, types}: site) (st: state) =
  let
    val R = fastype_of (#t st);
    fun constraint A st = let val (A', st') = written_type ctxt A st in unify ctxt (R, A') st' end;
    fun arity st =
      let
        val (Ts, st') = fold_map (K (fresh_tvar [])) (1 upto args) st;
        val (B, st'') = fresh_tvar [] st';
      in unify ctxt (R, Ts ---> B) st'' end;
  in can (arity o fold constraint types) st end;

(*the reading as printed: types normalised, beta-normal*)
fun reading_term ({t, env, ...}: state) = Envir.beta_norm (Term.map_types (Envir.norm_type env) t);

(*the readings of the identifier as field access on a constant that fit the site*)
fun readings ctxt ({name, site, ...}: occurrence) : readings option =
  (case object ctxt (Long_Name.explode name) of
    SOME (obj, fields) =>
      if forall (defined ctxt) fields then
        let
          val (rs, cut) =
            fold (fn f => fn (rs, cut) =>
                followed ctxt f rs |>> step ctxt f ||> (fn cut' => cut orelse cut'))
              fields ([(obj, [])], false);
          val complete = filter (fits_site ctxt site o #1) rs;
        in
          if null complete then NONE
          else
            SOME
             {fields =
                fields ~~ rev (fold (map2 (union (op aconv)) o #2) complete (map (K []) fields)),
              complete = map (reading_term o #1) complete, cut = cut}
        end
      else NONE
  | NONE => NONE);

(*the warning's text; the text of one reading when every field has one term and no reading was
  left out*)
fun render ctxt ({name, const, pos, ...}: occurrence) ({fields, complete, cut}: readings) =
  let
    val T = Consts.type_scheme (Proof_Context.consts_of ctxt) const;
    val print = Syntax.string_of_term ctxt;
    fun reading t = typed_text ctxt (t, fastype_of t);
    fun field (f, gs) =
      let val (shown, more) = bounded (map print (sort_candidates ctxt gs))
      in "  " ^ quote f ^ ": " ^ commas shown ^ (if more orelse cut then ", \<dots>" else "") end;
    val keep = "or " ^ quote ("CONST " ^ name) ^ " to keep the constant without this warning.";
    val body =
      if forall (fn (_, gs) => length gs = 1) fields andalso not cut then
        ["It could also be read as field access:", "  " ^ reading (hd complete),
          "Write that term to mean the field access, " ^ keep]
      else if length fields = 1 then
        "It could also be read as field access:" ::
          bounded_lines reading (sort_candidates ctxt complete) @
          ["Write one of these terms to mean the field access, " ^ keep]
      else
        "It could also be read as field access, each field being one of:" :: map field fields @
          ["Write the term you mean, for example " ^ quote (print (hd complete)) ^ ", " ^ keep];
  in
    cat_lines
      ((Markup.markup (Position.markup pos) (quote name) ^ " is read as the constant " ^ const ^
          " :: " ^ Syntax.string_of_typ ctxt T) :: body)
  end;

(*what determines the text: the terms, and readings left out or not*)
fun same_text (r: readings, r': readings) =
  #cut r = #cut r' andalso
  eq_list (op aconv) (maps #2 (#fields r) @ #complete r, maps #2 (#fields r') @ #complete r');

in

(*the warnings of the chosen parse tree: one evaluation per identifier and site, one message per
  identifier and readings (which determine the text); never raises (so that the warning cannot
  change which tree is chosen)*)
fun warning_texts ctxt occs =
  occs
  |> distinct (fn (o1: occurrence, o2: occurrence) =>
      #name o1 = #name o2 andalso #site o1 = #site o2)
  |> map_filter (fn occ =>
      Option.map (pair occ) (the_default NONE (try (readings ctxt) occ)))
  |> distinct (fn ((o1: occurrence, r1), (o2: occurrence, r2)) =>
      #name o1 = #name o2 andalso same_text (r1, r2))
  |> map_filter (fn (occ, r) => try (render ctxt occ) r);

fun emit_warnings ctxt occs = List.app warning (warning_texts ctxt occs);

end;



(** printing **)

(*a carrier in a message as "t.f" or "(e).f" (the output syntax _dot_access of pure_thy.ML); its
  payload is a schematic variable outside the check phase, a free variable inside.  Without its
  object, the printer's eta-contraction took a bound variable: "%x. x.f" again*)
fun access_tr' _ (p :: ts) =
      let
        val payload =
          (case p of
            Const ("_free", _) $ q => dest_payload q
          | Const ("_var", _) $ q => dest_payload q
          | _ => dest_payload p);
      in
        (case payload of
          NONE => raise Match
        | SOME {name, paren, field, ...} =>
            let fun access x = Syntax.const "_dot_access" $ x $ Syntax.free field in
              (case ts of
                x :: ts' => Term.list_comb (access x, ts')
              | [] =>
                  let val x = if paren then "x" else hd (Long_Name.explode name)
                  in Abs (x, dummyT, access (Bound 0)) end)
            end)
      end
  | access_tr' _ _ = raise Match;



(** selection rule **)

(*step 1 of the rule: the object type is a type variable that may still be instantiated*)
fun unknown {rigid} (TVar (xi, _)) = not (rigid xi)
  | unknown _ _ = false;

(*T: the object type, dereferenced by the engine's typing*)
fun decide ctxt rigid field T =
  if unknown rigid T then Wait
  else select ctxt T (candidates ctxt rigid field T);


(* types *)

fun norm tye T =
  (case Type_Infer.deref tye T of
    Type (a, Ts) => Type (a, map (norm tye) Ts)
  | U => U);

(*the type variables of t as fresh inference parameters from idx*)
fun fresh_instance t idx =
  let
    val vs = rev (Term.add_tvars t []);
    val (inst, idx') =
      fold_map (fn (xi, S) => fn i => ((xi, Type_Infer.mk_param i S), i + 1)) vs idx;
    fun inst_type (TVar (xi, _)) = the (AList.lookup (op =) inst xi)
      | inst_type T = T;
  in (Term.map_types (Term.map_atyps inst_type) t, idx') end;


(* waiting fields *)

(*the stamps of waiting fields under the parameters of their object types: roots (the object type
  is the parameter) and inner (it mentions the parameter)*)
type waiting_index = {roots: Inttab.set Vartab.table, inner: Inttab.set Vartab.table};

val no_waiting_index: waiting_index = {roots = Vartab.empty, inner = Vartab.empty};

fun add_stamps p s = Vartab.map_default (p, Inttab.empty) (fn s' => Inttab.merge (K true) (s', s));

(*the waiting field st under the parameters of its object type objT*)
fun place tye st objT (index as {roots, inner}: waiting_index) =
  (case Type_Infer.deref tye objT of
    TVar (p, _) =>
      if Type_Infer.is_param p
      then {roots = add_stamps p (Inttab.make_set [st]) roots, inner = inner}
      else index
  | T =>
      {roots = roots,
       inner =
        fold (fn q => add_stamps q (Inttab.make_set [st]))
          (filter Type_Infer.is_param (Term.add_tvar_namesT (norm tye T) [])) inner});

(*the stamps under the parameters that tye has bound, taken out of the index: the caller places
  again each field that still waits*)
fun take_bound tye ({roots, inner}: waiting_index) =
  let
    (*entries under an unbound parameter are exact; entries under a parameter bound since the last
      take_bound are read through deref and moved here.  A root bound to another parameter keeps
      its fields: they still wait (rule step 1)*)
    val (roots', cands1) =
      Vartab.fold (fn (p, s) => fn (rs, cands) =>
        if not (Vartab.defined tye p) then (rs, cands)
        else
          (case Type_Infer.deref tye (TVar (p, [])) of
            TVar (q, _) =>
              if Type_Infer.is_param q then (rs |> Vartab.delete p |> add_stamps q s, cands)
              else (Vartab.delete p rs, Inttab.merge (K true) (cands, s))
          | _ => (Vartab.delete p rs, Inttab.merge (K true) (cands, s))))
        roots (roots, Inttab.empty);
    val (inner', cands) =
      Vartab.fold (fn (p, s) => fn (ins, cands) =>
        if Vartab.defined tye p then (Vartab.delete p ins, Inttab.merge (K true) (cands, s))
        else (ins, cands)) inner (inner, cands1);
    (*a stamp taken also leaves its other parameters*)
    val inner'' =
      if Inttab.is_empty cands then inner'
      else
        Vartab.fold (fn (p, s) =>
          let val s' = Inttab.fold (Inttab.remove_set o #1) cands s
          in if Inttab.is_empty s' then Vartab.delete p else Vartab.update (p, s') end)
        inner' inner';
  in (cands, {roots = roots', inner = inner''}) end;



(** texts **)

(*what an engine lends to the texts: its rigid type variables, its unification and its
  preparation of terms and types for output*)
type engine =
 {rigid: indexname -> bool,
  unify: typ * typ -> typ Vartab.table * int -> typ Vartab.table * int,
  prep_output: typ Vartab.table -> (string * typ) list -> term list -> typ list ->
    term list * typ list};

(*the access t as written: the written identifier up to this field, or the object e of a bracket
  form printed by print, and the written fields up to this one*)
fun written print t =
  (case dest_carrier t of
    SOME ({name, index, paren, ...}, x) =>
      let
        val fields = prefix_of name (index + 1);
        fun bracketed 0 u = u
          | bracketed i u = bracketed (i - 1) (the_default u (Option.map #2 (dest_carrier u)));
      in if paren then enclose "(" ")" (print (bracketed index x)) ^ "." ^ fields else fields end
  | NONE => print t);

(*terms as the texts print them; display shows a prepared carrier as written*)
fun printer ctxt ({prep_output, ...}: engine) tye bs =
  let
    fun print u = Syntax.string_of_term ctxt (hd (#1 (prep_output tye bs [display u] [])))
    and display u =
      (case dest_access u of
        SOME {resT, ...} => Free (written print u, resT)
      | NONE => u);
  in {print = print, display = display} end;

(*the rule's text for a decision other than Choose*)
fun field_error_msg ctxt (engine as {rigid, unify, prep_output}: engine) (tye, idx)
    (({payload, objT, node, obj, ...}: access), bs) decision =
  let
    val {print, display} = printer ctxt engine tye bs;
    val obj' = display obj;
    val ([x], [T]) = prep_output tye bs [obj'] [objT];
    val (obj_text, type_text) = (Syntax.string_of_term ctxt x, Syntax.string_of_typ ctxt T);
    val field = field_name payload;
    val dot = quote (written print node);
    val here = Position.here (field_position payload);
    val {paren, const_object, ...} = payload;
    fun cand g =
      let
        val (g', idx') = fresh_instance g idx;
        val gT = fastype_of g';
        val tye' =
          the_default tye (Option.map #1 (try (unify (objT, domain_type gT)) (tye, idx')));
        val ([t], [R]) = prep_output tye' bs [g' $ obj'] [range_type gT];
      in typed_text ctxt (t, R) end;
    val candidate_lines = bounded_lines cand o sort_candidates ctxt;
    val ambiguous =
      "Ambiguous field " ^ quote field ^ " of " ^ obj_text ^ " :: " ^ type_text ^ here;
    val T' = norm tye objT;
    fun fields_of () =
      (case field_names ctxt {rigid = rigid} T' of
        [] => []
      | fields => ["Fields of " ^ type_text ^ ": " ^ bounded_commas fields]);
    (*the object is the constant that the written prefix reads as*)
    fun constant_object fields =
      let
        val first = hd (Long_Name.explode (#name payload));
        val prefix = object_prefix payload;
      in
        cat_lines
          ((dot ^ " is neither a constant nor a field of the constant " ^ obj_text ^ " :: " ^
            type_text ^ here) :: fields @
           [quote prefix ^ " is read as the constant CONST " ^ prefix ^ ", because " ^
              quote first ^ " is not a local variable here.",
            "For a field of a variable " ^ first ^ ", make it local: " ^ quote ("for " ^ first) ^
              " after a defining equation, " ^ quote ("fixes " ^ first) ^ " in a statement."])
      end;
  in
    (case decision of
      Ambiguous gs =>
        cat_lines
          ([ambiguous,
            (if paren then "" else dot ^ " is not a constant, and ") ^ type_text ^
              " has no most specific field named " ^ quote field ^ ":"] @
           candidate_lines gs @ ["Write one of these terms instead."])
    | Empty =>
        if const_object then constant_object (fields_of ())
        else
          cat_lines
            ((dot ^ (if paren then " is not" else " is neither a constant nor") ^ " a field of " ^
              obj_text ^ " :: " ^ type_text ^ here) :: fields_of ())
    | Wait =>
        let val gs = candidates ctxt {rigid = rigid} field T' in
          if unknown {rigid = rigid} T' then
            if const_object andalso null gs then constant_object []
            else
              let
                val line2 =
                  (if paren then [] else [dot ^ " is not a constant."]) @
                  (if null gs then [] else ["Fields named " ^ quote field ^ " exist for:"]);
              in
                cat_lines
                  (("Field " ^ quote field ^ " of " ^ obj_text ^
                    " cannot be resolved: the type of " ^ obj_text ^ " is unknown" ^ here) ::
                   (if null line2 then [] else [space_implode " " line2]) @
                   bounded_lines (registered_text ctxt) (sort_candidates ctxt gs))
              end
          else
            cat_lines
              ([ambiguous,
                (if paren then "The type of " else dot ^ " is not a constant, and the type of ") ^
                  obj_text ^ " is not determined enough to choose among:"] @
               candidate_lines (op @ (contenders ctxt T' gs)) @
               ["Write one of these terms instead, or fix the type of " ^ obj_text ^ "."])
        end
    | Choose _ => raise Fail "Dot_Field.field_error_msg")
  end;



(** last check **)

(*the decided field acc (choice g) chooses the same term on the object's final type*)
fun last_check_field ctxt (engine: engine) (tye, idx) (acc as ({objT, payload, ...}: access, _)) g =
  let
    fun final_type () =
      Syntax.string_of_typ ctxt (the_single (#2 (#prep_output engine tye [] [] [objT])));
    val reg = registered_text ctxt;
    val field = field_name payload;
    val here = Position.here (field_position payload);
  in
    (case decide ctxt {rigid = #rigid engine} field (norm tye objT) of
      Choose g' =>
        if g aconv g' then ()
        else
          error ("Field " ^ quote field ^ ": chose " ^ reg g ^
            " but the object's final type " ^ final_type () ^ " selects " ^ reg g' ^ here)
    | Wait =>
        error ("Field " ^ quote field ^ ": the object's final type " ^ final_type () ^
          " no longer selects " ^ reg g ^ here)
    | d =>
        error ("Field " ^ quote field ^ ": the choice " ^ reg g ^
          " is not confirmed on the final object type:\n" ^
          field_error_msg ctxt engine (tye, idx) acc d))
  end;

(*every decided field (key |-> registered term) chooses the same term on the object's final
  type*)
fun last_check ctxt engine tye_idx accs decided =
  Vartab.fold (fn (key, g) => fn () =>
    (case Vartab.lookup accs key of
      NONE => ()
    | SOME acc => last_check_field ctxt engine tye_idx acc g)) decided ();



(** explicit form **)

(*the registered term g at the node of key: its type variables become parameters of that node, and
  a constraint names its type*)
val node_tokenN = "dot_token";

fun node_instance_parts ((_, j): indexname) g =
  let
    fun param ((x, i), S) = Type_Infer.param j ("dot" ^ string_of_int i ^ x, S);
    val g' = Term.map_types (Term.map_atyps (fn TVar v => param v | T => T)) g;
  in (Type_Infer.param j (node_tokenN, []), g') end;

fun node_instance key g = uncurry Type.constraint (node_instance_parts key g);

(*the index of the node's key and the registered term at the node*)
fun dest_node_instance (Const ("_type_constraint_", T) $ g) =
      (case domain_type T of
        P as TVar ((_, j), S) =>
          if P = Type_Infer.param j (node_tokenN, S) then SOME (j, g) else NONE
      | _ => NONE)
  | dest_node_instance _ = NONE;

(*E(C) of a prepared term: every decided carrier (key |-> registered term) becomes its choice
  applied to the object; payloads are not read*)
fun explicit decided =
  if Vartab.is_empty decided then I
  else
    let
      fun sub t =
        (case (carrier_key t, t) of
          (SOME key, u $ obj) =>
            let val obj' = sub obj in
              (case Vartab.lookup decided key of
                SOME g => node_instance key g $ obj'
              | NONE => u $ obj')
            end
        | (_, u $ v) => sub u $ sub v
        | (_, Abs (x, T, u)) => Abs (x, T, sub u)
        | _ => t);
    in sub end;



(** selections **)

(*the choices of the accepted fields: payload serial |-> registered term*)
structure Selections = Proof_Data
(
  type T = term Inttab.table;
  fun init _ = Inttab.empty;
);

(*the choices C (key |-> registered term) of the accesses accs*)
fun record_selections (accs, C) =
  let
    val choices =
      Vartab.fold (fn (key, g) =>
        let val ({payload, ...}: access, _) = the (Vartab.lookup accs key)
        in Inttab.update (#serial payload, g) end) C Inttab.empty;
  in Selections.map (fn tab => Inttab.merge (K true) (tab, choices)) end;

(*a check by an engine f that returns the batch and its accesses with their choices, which the
  context passes back; NONE when nothing changed, as Syntax_Phases.simple_check (a stage repeats
  its checks while one changes)*)
fun selection_check f ts ctxt =
  let val (ts', choices) = f ctxt ts
  in if eq_list (op aconv) (ts, ts') then NONE else SOME (ts', record_selections choices ctxt) end;

val selections = Selections.get;



(** stage 1 **)

(* markers *)

(*the last check of a learnt field waits for stage 1, on its object's type there: the marker is a
  free variable of the object's type, appended to the batch; its name holds the access as written,
  the object as printed, and the payload*)
val markerN = "dot_last_check ";

fun marker ctxt engine tye (({payload, objT, node, obj, ...}: access), bs) =
  let
    val {print, ...} = printer ctxt engine tye bs;
    fun counted s = string_of_int (size s) ^ ":" ^ s;
  in
    Free (markerN ^ counted (written print node) ^ counted (print obj) ^ encode_payload payload,
      objT)
  end;

fun dest_marker (Free (x, T)) =
      if not (String.isPrefix markerN x) then NONE
      else
        let
          fun uncounted s =
            (case first_field ":" s of
              SOME (n, rest) =>
                let val k = Value.parse_nat n
                in (String.substring (rest, 0, k), String.extract (rest, k, NONE)) end
            | NONE => raise Fail "Dot_Field.dest_marker");
          val (dot, s) = uncounted (unprefix markerN x);
          val (object, s') = uncounted s;
        in Option.map (fn payload => (payload, dot, object, T)) (decode_payload s') end
  | dest_marker _ = NONE;

val is_marker = is_some o dest_marker;

(*the last check of every learnt field on its marker's type, with the choice that Selections
  holds; the batch without the markers*)
fun check_markers ctxt engine ts =
  let
    val (ms, ts') = List.partition is_marker ts;
    val idx = Type_Infer.param_maxidx_of ts + 1;
    fun check m =
      let
        val (payload as {serial, ...}, dot, object, T) = the (dest_marker m);
        val acc =
          {key = (markerN, serial), payload = payload, objT = T, resT = dummyT,
            node = Free (dot, dummyT), obj = Free (object, T)};
      in
        last_check_field ctxt engine (Vartab.empty, idx) (acc, [])
          (the (Inttab.lookup (selections ctxt) serial))
      end;
  in (List.app check ms; ts') end;


(* carriers left *)

(*the rule's text for the first carrier of the typed batch ts (objects first) whose payload select
  accepts; a carrier that the rule decides is an internal error*)
fun report_unresolved ctxt engine select ts =
  let
    val idx = Type_Infer.param_maxidx_of ts + 1;
    fun report bs (payload, node as (Const (_, T) $ _ $ x)) () =
          if not (select payload) then ()
          else
            let
              val objT = carrier_object_type node;
              val acc =
                {key = ("?dot_unresolved", idx), payload = payload, objT = objT,
                  resT = body_type T, node = node, obj = x};
            in
              (case decide ctxt {rigid = #rigid engine} (field_name payload) objT of
                Choose _ =>
                  error ("Field access " ^
                    quote (written (#print (printer ctxt engine Vartab.empty bs)) node) ^
                    " was not resolved (internal error)" ^ Position.here (field_position payload))
              | d => error (field_error_msg ctxt engine (Vartab.empty, idx) (acc, bs) d))
            end
      | report _ _ () = ();
  in fold (fold_carriers report) ts () end;



(** D14: learning runs **)

(*stage 1 of a learning run (Type_Infer_Context.dot_check)*)
exception LEARNT;

(*the learning flag: the recorder of the running learning run, called after each stage-0
  inference (Type_Infer_Context.standard_check)*)
structure Learning = Proof_Data
(
  type T = (term list -> unit) option;
  fun init _ = NONE;
);

val learning = Learning.get;

(*learn only if some carrier's object type shares a type parameter with a constant: not a
  carrier, not Pure.type (the TYPE terms of the typing report), not an internal constant*)
fun guard ts =
  let
    val objs =
      fold (fold_carriers (K (Term.add_tvar_namesT o carrier_object_type o #2))) ts [];
    val consts =
      fold (Term.fold_aterms
        (fn Const (c, T) =>
            if c = access_const orelse c = "Pure.type" orelse String.isPrefix "_" c then I
            else Term.add_tvar_namesT T
          | _ => I)) ts [];
  in exists (fn xi => Type_Infer.is_param xi andalso member (op =) consts xi) objs end;

(*a learning run on the batch ts of an engine (typed, its undecided carriers left in it; accs, its
  accesses): stock's check phase in an invisible context, prepared by prepare, with the learning
  flag; it ends at stage 1 (LEARNT), with an error or normally.  Result: the rule's choices,
  key |-> registered term, for the carriers left in ts, on the object types recorded last;
  without any choice, the rule's text for the first field that these types reject*)
fun learn prepare engine ctxt accs ts =
  if not (guard ts) then Vartab.empty
  else
    let
      val _ = if is_some (learning ctxt) then raise Fail "Dot_Field.learn: nested" else ();
      val records = Unsynchronized.ref (Inttab.empty: (payload * typ) Inttab.table);
      val last = Unsynchronized.ref ([]: term list);
      val carriers =
        fold_carriers (fn _ => fn (payload, node) =>
          Inttab.update (#serial payload, (payload, carrier_object_type node)));
      fun record batch = (last := batch; records := fold carriers batch (! records));
      val ctxt' =
        ctxt |> prepare |> Learning.put (SOME record) |> Context_Position.set_visible false;
      val _ = ignore (Syntax.check_terms ctxt' ts) handle LEARNT => () | ERROR _ => ();

      fun rule (payload, T) = decide ctxt {rigid = #rigid engine} (field_name payload) T;
      val choices =
        Inttab.fold (fn (i, r) => (case rule r of Choose g => Inttab.update (i, g) | _ => I))
          (! records) Inttab.empty;
      fun rejected ({serial, ...}: payload) =
        (case Option.map rule (Inttab.lookup (! records) serial) of
          SOME Empty => true
        | SOME (Ambiguous _) => true
        | _ => false);
      val _ =
        if Inttab.is_empty choices then report_unresolved ctxt engine rejected (! last) else ();
    in
      Vartab.fold (fn (key, ({payload, ...}: access, _)) =>
        (case Inttab.lookup choices (#serial payload) of
          SOME g => Vartab.update (key, g)
        | NONE => I)) accs Vartab.empty
    end;

end;
