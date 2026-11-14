# Sub-step 4 research: one Dot_Field interface and a map from the prototypes to the final files

**Scope.** This is read-only research. I edited no file, wrote no file, and ran no Isabelle process. Four read-only Opus agents read the five component sources in parallel, and I put their findings together.

**What I checked myself.** I read every `Dot_Field` structure directly: the parse prototype, V, D, the warning section, the registry stub, the registry prototype and `Restart_Base.thy`. I also re-checked these claims in the code: `print_checks` order; the solved branch, the `done_result` exit and `cargs_head` in P; the skeleton's observed entry; the parse prototype's ungated second parse; `record.ML:2274`; `adhoc_overloading.ML:153`; `hrtl` running the preset form. Everything else is the agents' reading of the code, with file:line given.

**Paths and abbreviations.**
- A = `/home/qiyuan/Current/MLML/contrib/dot_syntax/ai-artifacts`
- S = `/home/qiyuan/Current/MLML/contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax-stock` (7d475f7). It is identical to `contrib/Isabelle2026` for the files that matter here. **Every "S:n" is an Isabelle2026 line number.**
- PLAN = `A/DOT_SYNTAX_PLAN.md`
- Parse prototype:
  - PD = `A/step1/ref/parse/code/new/Syntax/dot_field.ML`
  - PSP = `…/parse/code/new/Syntax/syntax_phases.ML`
  - PSY = `…/Syntax/syntax.ML`
  - PPT = `…/parse/code/new/pure_thy.ML`
  - PRT = `…/ROOT.ML`
- Local-first prototype:
  - VD = `A/step1/ref/localfirst/V/dot_field_v.ML`
  - VP = `A/step1/ref/localfirst/V/out/phases_v.ML`; it is a copy of stock syntax_phases lines 43–458, so before its first hunk VP:n corresponds to S:n+37.
  - VT = `…/V/term_position_v.ML`
  - VTR = `…/V/trans_v.ML`
  - DD = `A/step1/ref/localfirst/D/dot_field_d.ML`
- Registry and warning prototypes:
  - R = `A/step1/ref/regwarn/registry/probes/Dot_Registry_Proto.thy`
  - W = `A/step1/ref/regwarn/warn/src/dot_field_warning.ML`
  - WSP = `…/warn/src/syntax_phases.ML`
  - STB = `…/warn/harness/registry_stub.ML`
- Engines and D14 (the files under `reviews/round6/d14/verify/proto/` are byte-identical to the ones in `A/step1/ref/engine6/`):
  - RB = `A/reviews/round6/d14/verify/proto/Restart_Base.thy`
  - P = `A/reviews/round6/d14/verify/proto/subtyping_esr3_restart.ML`
  - TIR = `…/type_infer_restart.ML`
- Clean code: SK = `A/step1/src/src/Tools/subtyping.ML`; CL = `A/step1/src/src/Pure/Syntax/lexicon.ML`; CP = `…/parser.ML`.

---

## 0. Facts to read first: prototype conflicts, gaps, and plan lines that are wrong

1. **Name clashes between the prototypes.** The same `Dot_Field` name means different things in different prototypes:
   - `accesses`:
     - VD:102-108 builds carriers around a decoded object; this is the meaning PLAN 1446 uses.
     - RB:147-157 collects every prepared carrier with its binders, typed `term list -> (access * bs) Vartab.table`; P:1461 and TIR:126 use this one.
   - `dest_access`:
     - PD:163-170 gives `term -> (payload * term) option` and accepts a Var or a Free payload.
     - VD:55-57 gives `term -> (string * term) option` and accepts a Var payload only.
     - RB:105-116 gives `term -> access option` for *prepared* carriers, where `key` is the result parameter. RB also has `dest_carrier` (RB:95-99), which accepts any carrier.
   - `access`: a local function at PD:132 versus the record type at RB:101-102.
   - The carrier constant's name: `access_const` (PD:36, VD:22) versus `name` (RB:54).
2. **The payload has three formats.**
   - PD (= VD): `dot_field name=… index=… [paren=true] <Position.properties_of pos>`.
   - RB:56-81: `dot_field.<field>`, tagged as `dot_field.<serial>.<field>`.
   - **The `id=1` in PLAN 1485's example is the *position* id** (S/src/Pure/General/position.ML:227-233), not a serial. The `serial ()` that PLAN 1488 gives each payload therefore needs a key of its own, and that key is undecided.
3. **Load order.** The final `dot_field.ML` loads between S/src/Pure/ROOT.ML:236 (`Isar/proof_context.ML`) and :237 (`type_infer_context.ML`). That position has these consequences:
   - The following are not visible from dot_field.ML: `Type_Infer_Context` (its `unify` and `infer` are local anyway, S type_infer_context.ML:171, :242), `Syntax_Phases` (238), `Args` (239), `Local_Theory` (243), `Attrib` (262), ML antiquotations (254), and HOL's `Subtyping.coercion_enabled`.
   - So `decide`, `last_check`, `learn` and the level-1 dot check cannot use the engine's unifier unless it is passed in. The prototypes use `Type_Infer_Restart.unify` (RB:796, TIR:586, 598), a copy of S type_infer_context.ML:171-234.
   - The learning context's `coercion_enabled false` has to be set by the HOL caller, as the round-6 judge wrote: `Dot_Field.learn (Config.put coercion_enabled false ctxt)` (`A/reviews/round6/d14/JUDGE.md` §1.3). The prototype sets it inside `hlearn` (RB:786).
   - VD:16-17 and DD:14-15 (`Attrib.setup_config_bool \<^binding>…`) and RB:54, 218-219 cannot be used there.
   - The attribute parser (`Args.embedded_declaration`) must go in the separate file loaded after attrib.ML.
   - The legacy "ML string looks like formal name" check (`ML_check_strings`, set at Pure.thy:1642) never applies to Pure bootstrap files; it affects user-space copies only (S/src/Pure/ML/ml_context.ML:138-150, ml_env.ML:55).
4. **Code the plan requires that no prototype contains:**
   - field-segment markup;
   - the context data that passes selections back (serial ↦ term);
   - `check` returning its context, and the report at the exit;
   - the learning flag (RB disarms carriers into `dot_plain` instead, RB:26, 766-768);
   - the payload rebuild inside `prepare_positions`;
   - `CONST` printing in `pretty_entity_cache` (no code anywhere in `A/reviews` or `A/step1`);
   - `Dot_Field.defined`;
   - the round-8 hiding rule (theory copies identical to a hidden theory copy);
   - the copy refinement "every Free fixed in the receiving context";
   - an "is a constant" check in registration;
   - the short attribute form and the `del` form;
   - the 5-item cap with ellipsis;
   - row 6 of `decode_ident` (the misspelt qualified constant goes to stock);
   - a switch gating the second parse.
5. **The prototype standard engine does no last check of its own node or late decisions.** It only checks D14 markers at level 1 (TIR:573-590). PLAN 1399 and 1619 say the standard engine "以最后检查结束" (ends with a last check). `A/reviews/round3/stage0/DESIGN.md:197-205` argues that the rule's monotonicity makes the last check unnecessary. These disagree.
6. **`Dot_Field.prep_output` (RB:245-252) is the 2025-2 text.** It lacks 2026's `Name.clean` (S type_infer_context.ML:251-252), and every engine error text goes through it.
7. **`print_checks` prints each stage's checks newest first,** which is the reverse of the order they run in (S syntax_phases.ML:910-931 against :962-967; evidence: `A/step1/ref/engine6/out/hrtl.Audit_Probe1.off.out:1741-1743`). The step-2 test "`print_checks` 显示 dot 检查在第 1 级第一个" (PLAN 2147, "shows the dot check first at level 1") would show it *last* on the stage-1 line, even when it runs first.
8. **The empty-candidate-list text has two sources.**
   - TIR:131-135 (`Wait []` for a typed carrier) disappears with the removed machinery.
   - `decide`'s parameter branch (RB:229-232) returns `Wait regs` even when `regs = []`, so `err_unknown` ends with an empty `Fields named "foo" exist for:`. This case remains reachable, for example `(λt. t.foo) z` (PLAN 2167-2168).
   - The registry prototype's `select` tests "U empty" before "T is a type variable" (R:142-145). RB and §1 item 3 test the type variable first.
9. **The `coercion_args` examples and the D14 form.** The G1 reference `hrtl` ran D14 in the *preset* form (`DOT_H_FORM` unset; `lists/v4.txt`). §6 (PLAN 1642-1644) and the round-6 JUDGE §1.3 want the *design* form (learnt choices only through `RELEARN`, kept in a table for the engine call). `A/reviews/round6/d14/VERIFY.md` §2.7 (lines 257-275) found identical verdicts and texts on every battery and every job.
10. **The skeleton's hooks do not yet fit the ESR code.** Details are in C.8 and D.2:
    - SK's observed entry `coercion_infer_types ctxt hooks raw_ts` (SK:882-954) runs `prepare` itself and returns only finished terms. The engine needs inference on its own prepared E(C) that returns the typing.
    - The `carrier` hook receives no `app`, no `err` and no state slot.
    - One `tolerate` hook serves two call sites that use different predicates in P.
11. **Plan citations that are 2025-2 line numbers (with the 2026 line):**

    | PLAN line | cites | 2026 |
    |---|---|---|
    | §0 (40) | syntax_phases.ML:1011 | `check_stage` S:959 |
    | 1681 | `check` drops the context at :1021 | S:968 |
    | 1421 | proof_context.ML:712 | `reject_schematic` S:715 |
    | §1 item 2 (105-106) | `unifiable_types` at adhoc_overloading.ML:139-145 | S:153-158; local, not exported |
    | round-4 JUDGE | `is_const_declared` at proof_context.ML:371 | S:374-376; not in the signature |

    In addition, PLAN 1467 calls `Syntax.parse_field_dots` "one line", but PSY needs two lines: one in the signature (PSY:89) and one definition (PSY:506).
12. **The user-space coercion copy needs its own gating option.** The edit `subtyping-no-check` in `A/step1/derive/edits.py` replaces the copy's option with HOL's `Subtyping.coercion_enabled`. A user-space ESR check therefore needs a separate option, as RB uses `esr_engine` (RB:640, 679-680). Without one, the learning run's `coercion_enabled false` cannot switch off the copy, and HOL's stock check also runs on the dot form.
13. **The parse prototype's second parse has no switch.** It sits in `parse_asts` (PSP:385-391) and is reached from `parse_term`, `parse_sort`, `parse_typ` and `parse_trrule` (S:494). PSP's `parse_term` hard-codes `{dot_syntax = true}` (PSP:453-454). PLAN 1419 says only `parse_typ`/`parse_sort` count as switched off; it does not mention `parse_trrule`.

---

## A. Final files (PLAN 6.10, 1741-1766): contents, load constraints, starting code

Status: `lexicon.ML` and `parser.ML` are done (CL, CP). `subtyping.ML` has only the skeleton (SK). `A/step1/derive/edits.py` lists only these three files (CHANGED_FILES, LOAD; NEW_FILES is empty). `derive.py` stops if src/ holds a file that `edits.py` does not list (derive.py:100-103).

### A.1 `src/Pure/Syntax/dot_field.ML` (new)
- **Load:** ROOT.ML between :236 and :237 (PRT:237 already does this). Only `\<^here>` and `@{make_string}` may be used; options are made with `Config.declare_bool (name, \<^here>)`, following the precedent `Syntax.ambiguity_warning` at S syntax.ML:179.
  - Available: Term_Position, Lexicon, Syntax (dispatch to `read_term`/`check_terms`/`string_of_*` at run time), Item_Net, Net, Envir, Consts, Sign, Pattern, Morphism, Variable, Token (`Token.Declaration`), Proof_Context, Type_Infer.
  - Not available: everything listed in 0.3.
- **Contents:** the PLAN 1745 list (switches, registry, rule, texts, last check, level-1 check, D14 learning run and guard), plus the payload codec, the identifier-marker helpers, the warning section (PLAN 1672-1675; W is "a section of src/Pure/Syntax/dot_field.ML", W:1), and the selection-recording data.
- **Starting code:**

  | part | starting code |
  |---|---|
  | codec | PD:24-170 |
  | identifier helpers, `is_fixed`, "is constant" | VD:59-119 |
  | registry | R:17-249, without probe items |
  | access type, carrier helpers, types and explicit form, rule, texts, last check | RB:89-351 |
  | guard | RB:467-487 |
  | markers | RB:523-537 |
  | `LEARNT` and `hlearn` | RB:709, 746-814 |
  | level-1 dot check | TIR:573-629 |
  | warning | W:16-223 |
  | head constant for markup | `A/probes/markup_fold/Markup_Fold.thy:12-27` |

  Full grouped detail is in B.

### A.2 `src/Pure/Syntax/term_position.ML`
- `val dot_identN = "_dot_ident"` (VT:11) is added to the structure and to the signature (S:20-27).
- `detect_position`, `decode_position` and `decode_position1` get one more clause each, `Const (c,_) $ _ $ p $ _` with `c = dot_identN` (VT:13-29, against S:101-114).
- `strip_positions` (S:131-137) keeps its text; it now also strips the marker through `detect_position`.
- Load position: ROOT.ML:150, early, so it cannot see Dot_Field. Dot_Field uses `Term_Position.dot_identN`.

### A.3 `src/Pure/Syntax/lexicon.ML`, `parser.ML` (done)
- CL exports `Field_Dot`, `is_field_dot`, `literal_of_field_dot`, `field_access_dots: token list -> token list option` (CL:335-360) and the terminal `"field_dot"` (CL:231). Only a literal `)` counts as the closing bracket (CL:339-341).
- CP exports `Parser.parse` (stock instance) and `Parser.parse_field_dots: gram -> string -> Lexicon.token list -> tree list` (CP:19-20, 871-880).
- CP keeps `field_prods` out of the lookahead tables (CP:479-502), and `functor Earley(val field_dots: bool)` is at CP:638.

### A.4 `src/Pure/Syntax/syntax.ML`
- `parse_field_dots` goes in the signature (PSY:89, after S:88) and as a definition (PSY:506, `Parser.parse_field_dots (cache_eval gram)`, after S:504). I diffed PSY against stock; these are its only changes.

### A.5 `src/Pure/Syntax/syntax_phases.ML`
Loads at ROOT.ML:238, after dot_field.ML and type_infer_context.ML. Hunks and their sources:

| part | stock (2026) | start from | notes |
|---|---|---|---|
| share `decode_free`, move `decode_const` | S:243 insertion; S:265-267 removed; `Free` branch S:304-313 | PSP:244-261 = VP:207-224 (identical); `Free` branch PSP:340-344 = VP:292-296 | the optional non-raising variant is in D.1 |
| `ast_to_term ctxt {dot_syntax} trf` | S:246-260 | header PSP:266 / VP:229. `_constrain` clause: **VP:238-242** (V's identifier marker), not PSP:273-292 (superseded split). `_dot_field` clause and `field_token`: **PSP:283-285, 293-294** (`Dot_Field.paren_accesses`) | the two prototypes' `_constrain` clauses have the same pattern head; §6 keeps V's |
| `decode_term` → `decode_ident` | S:269-324 | VP:253-367: `_dot_ident` clause before the general `_constrain` clause (VP:266-268), `decode_ident` (VP:306-360), exported wrapper (VP:367) | row 6's first half is missing (C.2); V's W1/W2 warnings must go |
| warning channel | same function | WSP:271-346: `decode_term_warnings {warn}`, a `site` argument in every inner `decode` clause, binder triples, hook in the constant case (WSP:326-334) | conflicts with V's inner `decode`, which keeps stock's arity, and with V's warning type `(unit -> string)` |
| second parse | `parse_asts` S:346-369 (`Syntax.parse` at S:354) | PSP:385-391 | must gain the switch (C.3) |
| `parse_tree`/`parse_sort`/`parse_typ` | S:371-399 | VP:415-444 (`{dot_syntax=false}` for sort and type) | V's `routes` (VP:418) is prototype-only |
| `parse_term` reads the switch once | S:404-456 | VP:456-506 (switch, `warn`, `emit`); WSP:438-483 for the warning's emission of the chosen tree | |
| `simple_check` exported | S:938-940 (local, inside `local … in … end` at S:933-954); signature S:8-36 | none | PLAN 1752 |
| `check` returns its context | S:962-968 (`#1 (perhaps …)` at S:968); used by the four `apply_*` at S:970-973 | none | PLAN 1681 |
| `check_terms` exit report | S:987-1006, next to `typing_report` S:996-1005 | none; reuse the local `markup_const` S:51-52 | PLAN 1680-1682, 1765 |
| `"standard"` as `term_check'` + level-1 dot check registration | S:1040-1045 (`"standard"` at S:1042-1043) | the prototype's registrations RB:681-683 are plain `term_check` stand-ins | the level-1 check registered here runs first at stage 1 (oldest first) |
| `pretty_entity_cache` CONST printing | S:766-771; exclusion set from the local `exclude_consts` S:734-745, applied at S:754 | none; probe predicate at `A/reviews/round5/focused/defend-verification-5/proto/P_Readback.thy:41-44` (uses `Variable.lookup_fixed`, not `is_fixed`) | `Proof_Context.exclude_consts_of` (S proof_context.ML:338) is not exported |
| carrier print translation (candidate home) | translation setup S:880-889 | RB:368-386 (`Dot_Print`); output syntax RB:364-365 | where it lives is open (D.2) |

### A.6 `src/Pure/pure_thy.ML` (ROOT.ML:193, before dot_field.ML)
- The two input-only productions: PPT:230-234, after S:229. They are `Sign.syntax_global true Syntax.mode_input [("_dot_field", "logic ⇒ field_dot ⇒ id_position ⇒ logic", "___" [1000,0,0] 1000), (same with longid_position)]`.
- The constant: PPT:242-243, `(Binding.concealed (qualify (Binding.make ("dot_access", \<^here>))), typ "'n ⇒ 'a ⇒ 'b", NoSyn)`, after S:236.
- PPT:257 `Theory.add_deps_const "Pure.dot_access"`, after S:249.
- The terminal `field_dot` needs no edit here; it comes from `Lexicon.terminals` (PPT:85-87).
- An output-only `_dot_access` syntax could go in the `("", false)` block (S:228). A print translation that decodes payloads cannot live here, because pure_thy.ML loads before dot_field.ML.

### A.7 `src/Pure/ROOT.ML`
- PRT:237 adds `ML_file "Syntax/dot_field.ML";`.
- Add a second line for the attribute file after `Isar/attrib.ML` (S ROOT.ML:262).

### A.8 `src/Pure/type_infer_context.ML` (ROOT.ML:237)
- **`prepare_positions`, `Var` branch** (S:146-148; S:121-163; only caller S syntax_phases.ML:990): test the name prefix, read the switch only when a payload is met, rebuild the payload as a Free, and add a `serial ()`. Start from RB:129-133 (`rebuild_tagged`) and RB:508-518 (`tag_carriers`). Only the per-payload rebuild survives; the traversal is `prepare_positions`' own.
- **The standard engine:** a new entry beside stock `infer` (S:242) and `infer_types` (S:304), both unchanged. It reuses the file's own `unify` (S:171) and `prepare` (S:290) instead of TIR's copy (TIR:48-104). Start from TIR:109-461 `gen_infer`, minus the removals in C.6, plus the learning-flag branch (C.7).
- The observation-build R1 audit is ported from TIR:471-524.

### A.9 `src/Pure/Isar/attrib.ML`
- Two `register_config_bool` lines after S:611 (`register_config_bool Syntax.ambiguity_warning #>`, inside the setup block S:532-643). The warning prototype adds one such line (`attrib.warn.diff`).

### A.10 `src/Pure/Isar/proof_context.ML`
- One signature line for `is_const_declared` (body at S:374-376; signature neighbours `const_space` S:45, `lookup_free` S:46). No prototype adds it; VD:116-119 re-implements it as `is_const_name`.

### A.11 The `dot_field` attribute file (new, after attrib.ML)
- Antiquotations are allowed here (it loads after ml_antiquotations at 254).
- Start from R:327-342 (`attribute_decl`: `Scan.state` + `Scan.lift (Args.name --| Args.$$$ "=")` + `Args.embedded_declaration` + `Morphism.entity`/`Morphism.form` + `Thm.declaration_attribute`). The precedent is `Method.parse_tactic`, S/src/Pure/Isar/method.ML:327-340.
- `Attrib.setup \<^binding>‹dot_field›`; the name has 0 hits in S/src and the AFP.

### A.12 `src/Tools/subtyping.ML` (HOL)
- SK (1216 lines) plus the ESR part from P, about 1,450-1,550 surviving lines.
- Hook bodies, about 80 lines: carrier about 40 (P:704-743), application about 18 (P:760-777), tolerance about 20 (P:816-842, 920-925), explain 3 (P:794-797).
- The registration as `term_check'` and the recording, about 20 lines.
- Estimated total: 2,750-2,850 lines. Full map in C.8.

### A.13 `src/HOL/Tools/record.ML`
- One line after S:2274 `|> put_record name info`, inside `definition` (S:1841-2297; `fields` at S:1862; `more` is not part of `fields`).
- The text is `|> Context.theory_map (Dot_Field.register_constants (map #1 fields))` (`A/reviews/round3/registry/DESIGN.md:732-737`, §8.1).
- The block-path form (PLAN 1531-1538; DESIGN §8.2, :758-783) is not part of step 1.

---

## B. A unified `Dot_Field`: every item other files need, with origins and disagreements

**Notation.** `U` = `typ * typ -> tye_idx -> tye_idx` (an engine unifier); `tye_idx` = `typ Vartab.table * int`; `bs` = `(string * typ) list`. Plan-given names are marked (PLAN n). Every other name is the prototype's and is open.

### B.1 Options
- **`dot_syntax : bool Config.T`** (PLAN 1407), `Config.declare_bool ("dot_syntax", \<^here>) (K false)`.
  - Origins: the JUDGE round 4 §3.1 text; VD:16 / DD:14 use `Attrib.setup_config_bool`, which is not allowed at this position.
  - Readers:
    - `parse_term`, once;
    - the `prepare_positions` Var branch, only when it meets a payload;
    - the standard-engine entry;
    - the HOL coercion check entry;
    - the level-1 dot check (one `Config.get`);
    - the printer, once per unparse;
    - the warning gate;
    - the exported `decode_term`, per D.1.
- **`dot_syntax_warning : bool Config.T`** (PLAN 1407), default true.
  - Disagreement: W:19 and VD:17 name the option `dot_constant_warning` and the ML value `constant_warning`.
  - Gate per PLAN 1675: both options on and the context visible. That gate is computed exactly at VP:457-459. WSP:438-439 tests only the warning option and visibility.
- **Drop:** W:25 `dot_warning_rule`; R:48-50 (`dot_registry_rule`, `_visibility`, `_subsumption`); RB:218-219 `dot_singleton` (D1 is not done, PLAN 1384); RB:72 `DOT_PAYLOAD`; RB:87 `strict_head`; RB:640 `esr_engine`.

### B.2 Payload and carrier codec
- **`access_const = "Pure.dot_access"`**: PD:36. VD:22 `"V_Base.dot_access"`, DD:20 `"D_Base.dot_access"`, RB:54 `name = \<^const_name>‹dot_access›`. User space needs an edit that renames it.
- **`type payload = {name: string, index: int, paren: bool, pos: Position.T}`**: PD:45 = VD:24. There is no serial field. Where the serial lives is open (record field, or a separate property).
- **`encode_payload : payload -> string`**: PD:77-83 = VD:35-41, byte-identical.
- **`decode_payload : string -> payload option`**: PD:85-98, strict (first word `dot_field`, unescapes, requires name and index).
  - Disagreement: VD:44-53 `payload_field : string -> string option` is loose (no prefix check, no unescape, field name only).
  - Disagreement: RB:56-81 uses a different format: `payload_name`, `tagged_payload_name`, `dest_payload_name` (reads under constraints, Free or Var), `dest_payload`, `payload_tag : term -> int option`.
- **Serial access** (`payload_tag` in RB:78-81). Consumers:
  - coercion-engine markers and the learnt-tag map (P:1547, 1568, 1613);
  - the standard engine (TIR:136-137);
  - the level-1 marker check;
  - the selection recording.
- **The cheap prefix test for `prepare_positions`**: PD's format allows `String.isPrefix "dot_field "`, RB uses `"dot_field."`. Open.
- **Payload rebuild Var → Free plus serial**: RB:129-133 (`rebuild_tagged`, written for the old format).
- **Derived data**: `field_name` (PD:105), `segment_position` (PD:107-114), `field_position` (PD:116), `object_prefix` (PD:120-121). These feed the texts, field-segment markup positions (PLAN 1680), and `written` (B.5) if the texts quote what the user wrote.
- **Carrier recognition**:
  - `carrier_const` (RB:89-92, without `strip_head`);
  - `has_access : term -> bool` (RB:124; PLAN 1560 names it);
  - `dest_carrier : term -> (string * term) option` (RB:95-99);
  - `dest_access : term -> access option` with `type access = {key: indexname, field: string, objT: typ, resT: typ, node: term, obj: term}` (RB:101-116). The prototype's access record carries only the field name; markup and texts would also want the payload.
  - Plus PD's `dest_access : term -> (payload * term) option` (PD:163-170) and VD's `(string * term)` form. The clash is described in 0.1.
- **`accesses (RB) : term list -> (access * bs) Vartab.table`** (RB:147-157), the batch collector. Consumers P:1461, TIR:126. Clash with B.3 `accesses`.
- **`rebuild_node`** (RB:126), used for learning outputs (P:2529, 2536; TIR:358-360).
- **Carrier construction**:
  - identifier form: B.3 `accesses`;
  - bracket form: `paren_accesses : term -> string * string -> term` (PD:152-156). It builds the *marked* constant `Lexicon.mark_const access_const` before translations (PD:132-133), whereas V's identifier form builds a plain `Const (access_const, dummyT)` after decoding (VD:105).
- **Print translation for carriers**: `Dot_Print.payload_field`/`tr'` (RB:368-386) read the `_free`/`Free`/`_var`/`Var` forms (PLAN 1489-1490), together with output-only syntax RB:364-365 (`"_dot_access_print"`, mixfix `"_._" [1000,1000] 1000`). PLAN 1671 calls it `_dot_access`.
- **Drop:** `strip_head`, `annot_of`, `untag`, `tags_of` (RB:84-92 part, 120-122, 135-144); `var_payload` (RB:72).

### B.3 Identifier marker and decode helpers
- **`is_ident_token : string * string -> bool`** (PLAN 1429): VD:74-75 = DD:72-73 (`"." ∈ a ∧ Term_Position.detect p ∧ is_long_ident a`). PSP's superseded test also has `¬ can decode_free` (PSP:275-281).
- **`ident_marker : string * string -> term`** (PLAN 1430): VD:77-79, three arguments plus the recorded name (`_dot_ident $ Free a1 $ Free p $ Var ((a,0), dummyT)`; JUDGE round 4 §3.4).
  - Disagreement: DD:75-76 has two arguments; DD:78-79 adds `dest_ident_marker`.
  - Marker name: `Term_Position.dot_identN` (VT:11; PLAN 1432) versus DD:70's literal.
- **`accesses : string * Position.T -> int -> term -> term`** (PLAN 1446): VD:102-108. It wraps fields k…n−1 in carriers with a Var payload.
- **`prefix_range : string * Position.T -> int -> Position.T`**: VD:92-99. It gives the object's position over the first k segments, dots included (PLAN 1446, "只盖住对象那几段", covering only the object's segments). PD's `segment_position` (PD:107-114) covers a single segment; field markup needs it.
- **`token_position`**: PD:135-138 is `string -> Position.T` (via `Term_Position.decode`); VD:86-89 is `term -> Position.T` (via `decode_position1`).
- **`is_long_ident : string -> bool`**: PD:126-130 = VD:59-63.
- **`is_fixed : Proof.context -> string -> bool`** (PLAN 1436, 1685): VD:111 = DD:106. It is the fixed-variable branch of `lookup_free` (S proof_context.ML:378-387). Consumers: `decode_ident` row 3, `pretty_entity_cache`.
- **"Is a constant"** without exception or completion: VD:116-119 `is_const_name` = `Variable.lookup_const` or the body of the unexported `Proof_Context.is_const_declared`. PLAN 1444 exports `is_const_declared` instead; whether Dot_Field also wraps it is open.
- **Drop:** VD:82-84 `routes`; VD:124-137 `Fields`/`is_field_name`/`trailing_fields`, replaced by the registry's `defined`; VD:143-182 W1/W2 and `emitted`.

### B.4 Registry (R unless noted; the plan's names are `unifier`, `candidates`, `declaration`, `defined`)
- **`type registration = {field, term, serial, global, pos}`** (R:22-27); `pattern_of` (R:29); key `Const (field, dummyT) $ Net.encode_type P` (R:30, = §1 item 2); `eq_copy` (R:33-35); `Data = Generic_Data {regs: registration Item_Net.T, local_serials: Inttab.set}` (R:37-43).
- **The one relation**: `term_instance` (R:55-59: β-η contract, `Pattern.first_order_match`), `identical_terms` (R:61-62), `identical` (R:64-65), `subsume` (R:67-75: drop instances; latest wins by Item_Net order).
- **Visibility**: `is_visible`, `visible`, `lookup` (R:80-93). The round-8 rule is missing.
- **`unifier : theory -> {rigid: indexname -> bool} -> typ -> typ -> (Type.tyenv * int) option`** (R:102-111; `Sign.typ_unify` after freezing rigid TVars). `fits` (R:113).
  - Disagreement: the plan cites adhoc_overloading's `unifiable_types`, which is local at S adhoc_overloading.ML:153-158.
  - DESIGN §6.1 says the engines pass `rigid = not o Type_Infer.is_param`.
- **`candidates : Proof.context -> {rigid} -> string -> typ -> registration list`** (R:115-120).
  - Disagreement: the warning stub's `candidates : Proof.context -> (typ -> bool) -> string -> typ -> term list` (STB:27-30; W:117 calls it with a `unifies` predicate).
  - Disagreement: the engines have no `candidates`; they use `registrations : theory -> string -> term list` (RB:48) and filter inside `decide` with the engine unifier.
  - Open question recorded in `A/reviews/round3/registry/DESIGN.md:1016-1026` §14 item 1: P11 found 0 differences in 60,000 comparisons. PLAN 1502 ("选择、所有报错、警告、冲突检测都从 Dot_Field.candidates 取 U", meaning selection, all errors, the warning and conflict detection all take U from `Dot_Field.candidates`) settles it in favour of `candidates`.
- **Field-name listing for "Fields of …"**: R:123-127 `field_names` (oldest first). RB:295-304 `fields_of` sorts alphabetically and uses the engine unifier.
- **`defined : Proof.context -> string -> bool`** (PLAN 1441; DESIGN §13 at :984-1005). Absent from R. The same concept is `is_field_name` in STB:25, VD:132 and W:150. Consumers: `decode_ident` row 6, the warning's cheap gate. Whether it respects visibility is open.
- **`declaration : {add: bool, pos: Position.T} -> (string * term) list -> Morphism.declaration`** (PLAN 1514). R:173-191 has an extra probe field `rule`; the serial is drawn outside `fn phi` (R:174); it uses `Syntax.effective_polarity_generic` (R:178).
- **`register_constants : string list -> Context.generic -> Context.generic`** (R:193-200), the record hook. It is silent, draws a new serial per call, and builds `Const (c, Consts.the_constraint …)`.
- **Reading and checking**: `read_term = Syntax.read_term #> singleton (Variable.polymorphic ctxt)` (R:221; DESIGN calls it `read_registration`); `check_registration` (R:205-219: identifier field, function type, no Var, Frees fixed; **no constant check**).
- **Conflicts**: `datatype conflict = Same_Pattern | New_Never | Old_Never | Overlap`, `conflicts` (R:226-249).
- **`insert` / `remove`** (R:155-170). `remove` ignores visibility; DESIGN 2.4 (:226-227) says "visible".
- **Drop:** command R:3, 299-322; probe printing R:254-294; `registry_probe` R:347-362, 403; `merge_conflicts` R:365-396 (PLAN 1539: no check after theory merge).

### B.5 Selection rule and texts (RB unless noted)
- **`datatype decision = Choose of term | Wait of term list | Empty | Ambiguous of term list`** (RB:212-216).
  - Disagreement: R:132-134 `outcome` has a separate `Unknown`, and its payloads are registrations.
  - `Wait` covers both step 1 and step 6; `field_error` tells them apart (RB:323).
  - If `decide` moves to `candidates`, whether the payloads become registrations is open. Markup needs the stored term; the last check compares with `aconv`.
- **`decide : Proof.context -> U -> tye_idx -> string -> typ -> decision`** (RB:221-240): the type-variable test first, then filtering, `freeze_params` for "matches". Consumers: P (714, 1981, 2134, 2857, the solved branch), TIR, learn, last_check, the level-1 check.
- **Types and explicit form** (KEEP, used by P and TIR):
  - `norm` (RB:162-165), `fresh_instance` (167-172);
  - `node_instance_parts`/`node_instance` (174-180), which builds `_type_constraint_ (?dot_token_j)` around a renamed copy. P's `node_token` (P:2443, 3072) and `cargs_head` (P:3367-3371) depend on that shape;
  - `explicit_with`/`explicit` (183-202), `freeze_params` (204-207).
- **Texts** (the §1.7 approved texts):
  - `err_ambiguous` (269-274), `err_undetermined` (276-281), `err_unknown` (283-288), `err_empty` (290-293);
  - `field_error : ctxt -> U -> tye_idx -> access * bs -> decision -> 'a` (306-326). Its `Choose` branch gives the internal text `Field "f" is decided` (RB:325);
  - helpers `prep_output` (245-252; see 0.6), `written` (254-262, rebuilt from the term), `display` (264-267).
  - Missing:
    - the 5-item cap with ellipsis (PLAN 300-302);
    - leaving out the "Fields of" line when the list is empty (1667-1668);
    - leaving out the `"c.xpos" is not a constant` half-sentence in the bracket form (1668);
    - the variant for a written prefix that is a constant (1665).
  - Order: candidate lines follow registry order, newest first (RB:42 `insert_list`); "Fields of" is alphabetical (RB:303); R's `field_names` is oldest first.

### B.6 Last check
- **`last_check : ctxt -> U -> tye_idx -> (access * bs) Vartab.table -> term Vartab.table -> unit`** (RB:328-351). It has three draft texts (RB:342-343, 345-346, 348-350) that are under text review (PLAN 1666).
- Consumers: P:1560 (I1a, `accs_read`) and P:3120 (`last_check_E`); TIR:586 (markers).
- The standard engine's own last check: see 0.5.

### B.7 Level-1 dot check
- Start from TIR:573-590 `last_check_markers` and TIR:592-629 `reject_unresolved` (registered as `term_check 1 "dot_unresolved"` at RB:683).
- Its parts:
  1. In a learning run, raise `LEARNT` on a batch that contains a carrier (VERIFY patch (1); prototype readout RB:782-783).
  2. The last check on D14 markers, then remove the markers.
  3. Report the carriers that are left, objects first.
- Safety-net text: TIR:615 `Unresolved field access "f" on x`, against PLAN 1667 `Field access "t.xpos" was not resolved (internal error)`.
- The marker's choice is recovered through `nth (registrations thy field) r` (TIR:580). That breaks once the registry has subsumption and hiding; see D.2.

### B.8 D14: learning run and guard
- **Learning flag**: none in any prototype. A new `Proof_Data` is needed. Its readers are the standard-engine entry (in type_infer_context.ML) and the level-1 dot check.
- **`exception LEARNT of term list`** (PLAN 1633): `DOpen.LEARNT` at RB:709.
- **`learn`** (PLAN 1640) starts from `DOpen.hlearn` (RB:763-814), typed `Proof.context -> term list -> term Inttab.table * (unit -> unit) option` (serial ↦ choice, plus a thunk that raises the rule's definite text).
  - Learning context (RB:784-790): `esr_engine false`, `coercion_enabled false`, `Data.put Inttab.empty`, `set_visible false`, observer at stage 0, readout at stage 1.
  - Records are read in all three ways the run can end: `LEARNT`, `ERROR` or a normal return (RB:791-794).
  - The rule on the records uses `Type_Infer_Restart.unify` (RB:796).
  - Report thunk: RB:799-813.
  - Callers reach it through `Dot_Restart.hlearn_ref` (RB:462-464, set at RB:924; called at TIR:368, P:1608).
  - `carriers` (RB:746-757) reads `(tag, field, domain_type (range_type T))`.
- **Guard** (PLAN 1646): `h_guard_open` (RB:467-487; called at TIR:365, P:1605).
  - Disagreement: the prototype excludes every `Pure.type` constant and every `_`-prefixed constant; PLAN excludes only the `TYPE` terms that `check_terms` appends (S syntax_phases.ML:992-993).
- **Markers**: `marker i r field written T` / `dest_marker` / `is_marker` (RB:523-537; name `dot_last_check.<tag>.<r>.<field>.<written>`). Built by P:1564-1577 (`objT_of` per exit) and TIR:151-158 (typed `objT`).
- **Learning output**: built by each engine (P:1585-1588; TIR:358-360).

### B.9 Selections passed back and field-segment markup
No prototype has either. Needed:
- a `Proof_Data` from payload serial ↦ registered term (PLAN 1680-1681), with writers in the coercion exit function, the standard engine's return and the level-1 check, and a reader in the `check_terms` exit;
- a head-constant function: `Envir.eta_contract (Proof_Context.contract_abbrevs ctxt t)`, then `head_of`, `Const` only (Markup_Fold.thy:12-27; `contract_abbrevs` S proof_context.ML:733, a no-op when `show_abbrevs` is off or in abbreviation mode);
- the markup itself from syntax_phases' local `markup_const` (S:51-52);
- the position from `field_position` (PD:116).

### B.10 Printing support
- The switch, `is_fixed` (B.3), and the carrier print translation (B.2). The exclusion set comes from syntax_phases' local `exclude_consts` (A.5).

### B.11 Warning (W)
- `type site = {binders, args, types}` (W:30); `type warning`, `same_warning` (W:192-195); `constant_warning_message` (W:199-202, wrapped in `try`); `type occurrence` (W:207-208); `constant_occurrence` (W:210-212); `emit_warnings : (unit -> occurrence) list -> unit` (W:217-223, three dedup stages; RESULTS.md §6).
- Local helpers: `inference_view`, `written_type`, `step` (per-segment walk over every candidate), `fits` (written types and argument count), `reading_term`, `render` (W:37-186).
- Disagreement: VD:178-182 `emit_warnings : (unit -> string) list -> unit`.
- Superseded: the object rule `object` (W:68-101), `names_its_field` (W:140-142), and the measurement tags (W:158-163, 179-181).
- Needs from the registry: `defined` and `candidates` (`{rigid = K false}`, with `#term`).

---

## C. Changes §6 requires, per component (plan line → prototype lines)

### C.1 Removed across the board (PLAN §4, 1344-1346; 1593-1597)
- Every test switch, counter and audit leaves the clean code (PLAN 1613, 2129-2134).
- G2 instruments live only in the observation build: `S3B_RECHECK_DONE`, `S3B_AB_PRED`/`S3C_PRED_AUDIT`, PROP-DUP, the R1 audit, the I1b test switch.
- G3 mutants are separate edits.
- Statistics refs: P:217-330; RB:455-466, 598-599; TIR:36-37.

### C.2 `decode_ident` and local variables first (PLAN 1427-1458)

| row | PLAN | V | change |
|---|---|---|---|
| 1 | 1434 | VP:309, 359 | keep (DD lacks the recorded-name check) |
| 2 | 1435 | VP:336 → `field_access 1` (VP:322-333) | **drop W1** computed at VP:327-332 (§1 item 16, 271-274) |
| 3 | 1436 | VP:338-339 (`Dot_Field.is_fixed`) | drop W1 |
| 4 | 1437-1438 | VP:340 (`is_const_name ∨ lookup_free`) → stock VP:353 | VP:342-350 computes W2 for every row-4 case through `const_of`/`try`. The plan wants the warning computed only when the reading is a `Const` (round-5 §3.16), and with the registry rule of W, not V's names-only W2. |
| 5 | 1439 | VP:355-356 (`const_prefix`, VP:316-319) | keep. Edge case: the object `Free (prefix k)` goes through `decode_free`, which tries `lookup_free` first, so a prefix that is a constant *and* has a declared default type would read as a free variable. |
| 6, first half | 1440-1442 | **missing** | add: `lookup_free ctxt a1` is SOME, as stock's Free branch tests (S:307), and not `Dot_Field.defined ctxt (2nd segment)` → stock `decode_free` (round-5 JUDGE §3.10, `A/reviews/round5/focused/JUDGE.md:509-544`) |
| 6, second half | 1442-1443 | VP:357 (J08 repair, make_v.py:57-68) | keep |

- Also:
  - the "is constant" test (PLAN 1444) — see D.1;
  - the exported `decode_term` (PLAN 1447-1450): VP:367 and WSP:346 do not read the switch (D.1);
  - remove the superseded split: PSP:273-281, 289-292 and PD:140-149 (`ident_accesses`, leftmost only; PLAN 155, 172, 1345).

### C.3 `(e).f` (PLAN 1460-1480)
- `[…].f`/`{…}.f`: already gone from CL (only `)`, CL:339-341). PSP, the parser and PPT have no `]`/`}` handling left. The tests L4 and Q6 (`A/step1/ref/parse/tests/parser_battery.ML:132`, :158) differ on purpose (PLAN 2087).
- The second parse (PSP:385-391) must be gated by the switch passed from `parse_term`. That means `parse_asts` takes the flag; `parse_trrule` is the open case (D.2).
- Keep PSP's `_dot_field` clause unconditionally? PSP:293-294 is not gated; but the production can only be used by the second parse, so the clause is unreachable with the switch off (my reading).

### C.4 Carrier and payload (PLAN 1482-1496)
- One rule: the payload is schematic outside the check phase and Free inside it.
  - The parse side always creates Var payloads (PD:132-133, VD:102-108).
  - The rebuild is new code in `prepare_positions` (A.8).
  - Every reader inside the check phase sees only the Free form; the print translation reads both.
  - The third-round "rebuild at level 0" and d14on's second encoding are gone. In round 6 that rebuild survives only as the ML wrapper RB:508-518, 606-628, 886-914, which Isar commands bypass (`A/step1/ref/engine6/PORT.md` §6-7, `St0_CloseForm` line 24).
- The rule that carriers do not leak sits in `Syntax.check_terms` through the level-1 check. The final `infer_types` is stock: delete TIR:467-469 and the alias RB:642-643.

### C.5 Registry and attribute (PLAN 1498-1540; §1 items 1, 20)
- **Remove:** the command, its keywords and parser (R:3, 299-322); the λ-term registrations in the probes (P02/P04/P06/P09/P10 must be rewritten with constants); the probe switches; `registry_probe`; `merge_conflicts`; the `"notation"` keep rule (R:183).
- **Add:**
  - The constant check before reading (D.1). `register_constants` builds the term itself (R:193-195) and stays unchecked.
  - The stored term: `read_term` (R:221) is already the standard reading with `Variable.polymorphic` (PLAN 78-80, 1503-1506).
  - The copy refinement "every Free of `Morphism.term φ t` is fixed in the receiving context", next to R:182-184 inside `fn phi` (PLAN 1518-1520).
  - The round-8 hiding rule (PLAN 1520-1523), which can live in `lookup`/`visible` (R:80-93).
  - `defined`.
  - The attribute named `dot_field` (rename `dot_field_attr`, R:341-342), with the short form `[[dot_field c]]`, a delete form, and the conflict report raised once, at read time (PLAN 1511, 1514-1517, 1539; R:303-308 has the report in the command only).
  - The record hook line (A.13).
  - The registry hands the stored term to markup (B.9).
- **Unchanged and correct:** `pattern_of`/`key_of` (R:29-30); the relation and subsumption (R:55-75; remove the switch at R:119); the serial drawn outside `fn phi` (R:174); "registrations do not look at the switch" (R has no switch code, PLAN 1540).

### C.6 Standard engine (TIR → type_infer_context.ML; PLAN 1615-1625, 1488-1489, 1495-1496)
- **Remove:**
  - designer A's restart (TIR:131-148, 415-437, the preset merge at 455, preset markers at 459; RB:492-503, 606-628);
  - typed-carrier recognition and leftover typing (TIR:285-307, 441-443; RB:84-92, 120-122);
  - the drop test (TIR:444-445, 525-533; RB:135-144);
  - `standard_check_first` and its economies (TIR:555-566);
  - D-open (`leave_waiting`, `dwait_mode`, `DOPEN_WAIT` in `finish_pending` TIR:378-410);
  - `err_late` (TIR:210-223), dead once the late rerun is unconditional;
  - the copied `unify` (TIR:48-104), replaced by the file's own (S:171);
  - the mutants (`DOT_STAGE0_MUTANT` at TIR:40 and its uses, `DOT_V_MUTANT` 239, `RT_SKIP_TYPED_FIRST` 555).
- **Make unconditional:** the late rerun (`attempt … handle LATE_CLASH`, TIR:455; switch at TIR:43-44, 225, 243; PLAN 1623-1624).
- **Keep:** node decision (TIR:279-327 minus the removed parts); `inf_plain`/`app` (328-347); the waiting table (169-208); `resolve` (247-277); `decide_late` (231-245); `finish_pending` with `h_learn` (361-377, 390-402); `learntH` (150; it survives the rerun, PLAN 1644); the markers (151-158).
- **Add:**
  - the learning-flag branch (C.7);
  - the entry gate: switch, then `exists has_access`, else stock (PLAN 1560; TIR:541-546 is the entry);
  - registration as `term_check' 0 "standard"`: with the switch off or no carrier it is stock `simple_check (op aconv)` on stock's function; otherwise it returns `SOME (ts', ctxt')` with the selections recorded (PLAN 1751-1752);
  - the last check, if one is wanted (0.5).
- The R1 audit (TIR:471-524) is ported to the observation build (G2 (b), PLAN 2173-2175).

### C.7 D14 (PLAN 1627-1657)
- **Remove:**
  - D-open: RB:24-26, 699-919 except `hlearn`/`carriers`, 923, 930-943; P:3466-3474;
  - the d14on gate (RB:539-589, 904-905);
  - `hlearn_ref` as a mutable forward hook (G5: no mutable state at structure level, PLAN 2183);
  - `h_mode`/`h_read`/`h_readout_tagged`/`h_form_design`/`h_guard` switches (RB:438-458);
  - the `dot_plain` disarming (RB:26, 766-768, 816).
- **Change:**
  - The learning context (PLAN 1634-1640): invisible, no reports, learning flag, `coercion_enabled` false (set by the HOL caller), switch kept on. Prototype form: RB:784-790.
  - The two flag readers replace the emulation:
    - (1) the standard-engine entry: on the flag, run stock `infer`, record object types after each round's inference and before `expand_abbrevs` (patch (2); emulated by `observe` with reinfer, RB:779, 789), then run stock `expand_abbrevs`;
    - (2) the level-1 dot check: raise `LEARNT` on batches that contain a carrier (patch (1); RB:782-783, 790).
  - Patches (1) and (2): PLAN 1647-1648; VERIFY §3.1-§3.2; configuration `hrtl`.
  - Guard per PLAN 1646 (B.8 disagreement).
  - One marker per learnt field, typed by the exit's object-type reader (PLAN 1642-1643).
  - Coercion engine: the design form (learnt table `learntD` plus the cached re-raise P:1590-1600, under `h_form_design`); delete `presetH` (P:1553, 2131-2132, 2852-2853) and `preset14` (P:1540-1551). See 0.9.

### C.8 Coercion engine (P → SK functor + ESR part; PLAN 1563-1613)

**Removals:**

| item | PLAN | P lines |
|---|---|---|
| I1b shortcut | 1578-1580 | `try_candidate` 3292-3293, 3298; `global_E` as a separate exit 3124-3143; `S3B_I1B_DOTFORM` 254-255, 3125-3135. Kept only as the observation-build switch (2133) |
| fixes A/B/C and the three-way operator-head reading | 1595-1597, §1 item 21 | 632-664; uses at 709, 756, 2455, 2558 |
| `dot_wild` | 1593 | 177, 2087, 2101, 2392-2398; in `app` 2588-2592, 2636-2646, 2650-2663 |
| `dot_memo` | 1593 | 180, 2090, 2758-2805, 3056 |
| guard (`dot_guard`) | 1593 | 198-203, 2095-2102, 2650, 2749, 2845, 2986, 3008, 3056, 3318-3319, 3325, 3435-3439, 3442 |
| `domain_expect` (lookahead) | 1593 | 204-207, 77-121, 1437-1451, 1625-1776, 2496-2504, 2511-2512, 2552-2560, the `ex` parameter (2683-2686), `audit` 3087-3093, `dot_lookahead`/`dot_glook` 51-55, 192-197 |
| prefix replay | 1593 | 144-151, 1362-1369, 1382, 1397-1403, 2167, 2264-2265, REDECIDE's 5th component (1315), 2400-2437, 2554-2557 |
| `dot_learnt_complete` | 1593 | 264-267, 2835, 2837-2838 |
| `WAIT_REJECT` | 1593 | 30-32, 1335, 3046-3048, 3062-3063, 3223, 3299, 3453-3474 |
| the `waited` flag and the I2 counter | 1573 | `Local_Done`'s 5th field (1407), 2713, 3373, 3424 |
| retired D3 variants | — | `afresh*`, `stale` 3231-3276; `resolve` 3334-3365; `judge` 3330; switches `local_typing`/`optb_*` 42-67 |
| stock pipeline emulation | 1549, 1578 | `stock_global` 3068-3082, `stock_local_E`/`explicit_E` 3146-3164, replaced by one observed-instance call |
| switches made fixed-on | — | `provisional`, `dependency`, `spine`, `defer_rerun`, `expected_type`, `propagate`, `tolerant`, `cycle`, `repair`, `rounds_reuse` |

**Additions and changes:**
1. **D15** (PLAN 1598-1611; P mapping in 0 of the coercion agent):
   - After solving, make one decision on the solved typing that gives:
     - the choice: replace `chosen` (P:3018-3022), including its use in the cycle rule (P:3027-3030);
     - the D14 trigger (P:3040-3045);
     - the rule text: replace `decide (tye0, idx')`/`field_error (tye0, idx')` at P:3033-3037.
   - Take `Choose` first; the local pass's text still has precedence (P:3035-3036).
   - Before solving, a field waits if a parameter of its object type, read through `tye0`, is in `tied`. `tied` is taken out of `propagate` (P:2911-2916) and computed at `learn` level. It needs `comp`/`root` (P:2867-2879), which are built only when something is pending.
   - P's `learnt` fold (P:2890-2897) is where the pre-solve choice happens.
2. **I1a's `coercion_args` condition** (PLAN 1569-1571): P's `cargs_head` (P:3367-3371: `head_of (strip_constraints (node_instance key g))`, no folding of abbreviations) already matches. It is applied at `done_result` (3374) and at the deferred exit (3424).
3. **Default-path rule error** (PLAN 1581-1583): P:3307 (`if final then error …`) gains "and no `cargs_head` in C_bind" (C_bind = `binding_choices fs`, P:2105ff). The path condition already matches P:3327.
4. **Single exit function** (PLAN 1566-1568):
   - Merge P:3377 (`done_result`), 3427 (`attempt`), 3141-3142 and 3162.
   - It does the last check (`accs_read` minus `confirmed` for I1a, P:1559-1561; `last_check_E` for E(C), P:3112-3122), the markers (P:1564-1575), `finish` (P:1576-1577), the recording of C (new), and the `S3B_RECHECK_DONE` hook in the observation build (P:3380-3388).
   - Note: the deferred I1a exit catches `LAST_CHECK` and calls `replaced` (P:3428-3430), while `done_result` rejects.
   - Object-type readers: `objT_local` (P:1582) and `objT_E` (P:3104-3111, `object_own` first).
5. **Single rejection judgement** (PLAN 1584): `rejected` (P:1333-1336) becomes `ERROR` + `LAST_CHECK`, used at P:3217, 3223, 3299, 3325, 3327, 3442-3443.
6. **D14 trigger** (PLAN 1612, 1631-1645): stays in the solved branch. Keep `learning_output` (P:1585-1588), `h_learn`/`h_learn_run` (P:1590-1623) and the guard call, with `Dot_Field.learn` called directly.
7. **Registration** (PLAN 1753-1754): `term_check' ~100 "coercions"` replaces SK:983-985 / S:888-890. With the switch off or no carrier it is stock `simple_check (op aconv)` on `coercion_infer_types` (SK:971); otherwise it runs the engine and returns its context with C recorded.
8. **D6 spine reader**: P:619-630 changes stock `update_coerce_arg` (the switch is read on every call). The plan wants stock unchanged and the spine reader only in ESR's own traversal (PLAN 1558). P:605-617 holds the readers and the `S2_D6_MUT` mutants.
9. **What survives (approximate):**
   - `local_fields` and the waiting table (P:1338-1375, 1412-1434);
   - field-state helpers (P:2105-2169);
   - `check_decisions` (P:2174-2269);
   - D7 blocked steps (P:2271-2391);
   - `inf`/`inf_plain`/`app` (P:2440-2672 minus removals; the clash path P:2586-2647 is a modified copy of stock S:821-855);
   - `local_pass` (P:2680-2721);
   - prediction (P:1778-2081 minus audits; β-redex source P:1932-1936; registered range P:1994-1999);
   - `global_solve` (P:2835-3063);
   - node repair (P:3198-3222);
   - option b / default path / exits (P:3289-3431);
   - D15 support (P:1514-1538).

**Hooks against SK** (`hooks` at SK:105-118; calls at SK:363, 379, 381, 397-399, 424, 507, 730, 733, 899):

| hook | P code | fit |
|---|---|---|
| `observe` (SK:379, 899) | `record_object`/`node_token` (P:2440-2448), `record` (P:3071-3072) | the type fits, but the entry point does not (0.10) |
| `carrier` (SK:363) | P:704-743 + `gen_pred` (P:2738-2750) | it needs stock's `app` and `err` and a place for the per-generation state `global_fields` (P:682-698); the `gen` type has no state slot |
| `application` (SK:381) | P:760-777 | fits |
| `tolerate` (SK:424, 507) | P:816-842 (`coerced_ctors`, recursive, both directions) against P:920-925 (head constructors only, one direction) | one hook cannot tell the two sites apart |
| `learn` (SK:730, 733) | P:2862-3053 (called at P:1149, 1152) | fits; it closes over generation's `pending`/`decided` |
| `explain` (SK:397-399) | P:794-797 | fits |

---

## D. Choices left to step 1

### D.1 Choices §6 leaves explicitly

| PLAN | the choice | options the prototypes suggest |
|---|---|---|
| 1444-1445, 1714-1715 | the "is constant" test; optional non-raising `decode_free` (also removes the repeated lookup of qualified constants, +0.5–1.1 µs each) | (a) export `Proof_Context.is_const_declared` + `Variable.lookup_const` (VD:116-119 = that composition); where the composite lives is open. (b) a non-raising `decode_free` that decides row 4 and gives the reading; the error path must still give stock's exact `Undefined constant` with completion |
| 1450 ("子步骤 4 定", decided in sub-step 4) | how the exported `decode_term` (called by Simpl `hoare_syntax.ML:720-721`) gets the switch | (a) as VP:367: no read; a marker exists only if `ast_to_term` saw the switch on, and with it off `decode_position` sees through the marker. (b) one `Config.get` in the exported wrapper, if `decode_ident` is gated by a passed-down value. Test: `_INFER` in V_Attack (C07) |
| 1507 ("所用函数第一步定", step 1 fixes the function) | confirm "is a constant", then expand | (a) `Proof_Context.read_const {proper=true, strict=false}` (S proof_context.ML:667-673; `strict=true` rejects abbreviations, consts.ML:113-116), then `read_term` reads the text again (position reports twice). (b) `Syntax.parse_term`, test the raw term after stripping position constraints (`decode_position` makes `TFree pos`, term_position.ML:104-108), then `check_term` + `Variable.polymorphic`. (c) the non-raising test of D.1 row 1. Also open: is `c :: T` allowed; does the short form take the base name of the written text or of the resolved constant (they differ for aliases and `CONST …`) |
| 1511, 1670 | delete syntax (proposal `[[dot_field del f = c]]`) | `Args.del` (args.ML:90; precedent `Attrib.add_del`, attrib.ML:274), which collides with a field named `del` but backtracking resolves it; or a separate attribute (precedent `coercion_delete`, subtyping.ML:1102-1104). Whether to keep `effective_polarity_generic` (R:178) |
| 1519-1520 ("第一步实测", measured in step 1) | the copy refinement (every Free fixed in the receiving context) | light locale is not on 2026 (P12 not run). Proposed stand-in (not run): `context fixes c begin definition d … declare [[dot_field f = d]] end`; the theory copy carries `Free c` and must be dropped |
| 1558-1559 | fallback (optional hook parameters) if the hook-less instance is too slow | already measured within the variation range (PLAN 2102-2103); not needed unless the hook types change (PLAN 2098) |
| 1569, §1 item 22 (318-326) | keep or remove I1a, by measurement | `S3B_RECHECK_DONE` in the observation build, covering both exits; if kept, an R1 regression test |
| 1602 ("确切条件第一步定", step 1 fixes the exact condition) | the exact D15 pre-solve condition | P's `tied` (P:2911-2916) leaves out constraints where both sides are parameters (P:2913), while the plan's wording covers them. Node decisions during constraint generation (P:713-719) can meet the same `?c list` situation where `tied` is not available |
| 1608-1609 | `dot_object_own_type` may be redundant | switch it in the observation build, measure, delete if redundant (P:268-273, 1514) |
| 1610 | the typed binder `(λt::_ list. t.ih) ns` may be decided in the local pass | handle it there too, or list it as an exception and report to the user |
| 1611 | count the acceptances D15 loses | report to the user; test list L1, L6, L7, L9, U17, U18 (`A/reviews/round3/d15/`) plus composites, plus the `is decided` example and a D14 example, plus two `tye0` mutants |
| 1640 | optional `raise Fail` in `learn` when the flag is already set | no prototype equivalent |
| 2098 | learning-hook types may change in sub-step 4; re-measure if they do | see C.8 hooks and D.2 |
| 2133 | the I1b test switch in the observation build; C2 rows timed with and without | report under rule (4) with the option "ship the restricted shortcut" if C2 fails |
| 153, 300-302, 1669 | candidate order (sorted by full name?), which 5 items, ellipsis form (`…` on its own line or `, …`); whether "has N fields" counts all or only the shown ones | prototypes: registry order newest first (RB), alphabetical "Fields of" (RB:303), R's `field_names` oldest first |
| 1664-1671 | every user-visible text | draft texts: RB:342-350, TIR:615, W:170-186; registry error texts in DESIGN §11 (:887-904, items 1-8; no text yet for "not a constant"); conflicts as error or warning per class (DESIGN §7.1, :654-673, proposes errors for 3 classes and a warning for overlap; §6 says only "report"); a cap on the warning's reading lines (not among §1 item 19's three lists) |
| 1479-1480, 1700, 2186-2193 | new probes: `mk_lift_expr`, K7, and the "另加" (additional) list | registry coverage gaps: theory-level `[[dot_field a.bar]]`, a sublocale with its own `bar`, `locale two = a: foo 1`, `context fixes c` with a constant, the markup cases |
| 341, 2194-2195 | frequency counts of tolerant learning, the cycle rule and node repair | P's counters `n_tol` 3176, `n_cycle` 3030, `n_repair` 3209, as observation-build edits |

### D.2 Questions the inventories found that §6 does not settle (listed, not decided)
1. The serial key in the payload, the payload fields that stay (`paren`, `label`, `file`, `id`), and the prefix test (0.2, B.2).
2. Names, for the clashes in 0.1: `accesses`, `dest_access`, `access`, `name`/`access_const`.
3. The `decide` signature: does it keep an engine unifier argument, or use `candidates` with `{rigid = not o Type_Infer.is_param}`? The level-1 check and `learn` cannot use the engine's unifier (0.3).
4. Whether `decision` carries terms or registrations, and whether `Unknown` is separate. The order "type variable first" versus "U empty first" (0.8), and with it the empty `exist for:` list.
5. Marker encoding and how level 1 recovers the choice. Today it is a registry index `r` (TIR:580). Alternatives: a serial lookup in the selection-recording context data, or a stored term.
6. Where the learning run's object-type records live: a closure-local ref (RB:769), the threaded context, or data carried by `LEARNT`. A stage-0 `term_check'` must still return `NONE` when unchanged. Also: whether a run that ends with `ERROR` or a normal return still reads the records. The prototype reads them; JUDGE §1.2 says "an ERROR means nothing is learnt".
7. Whether the standard engine does its own last check (0.5).
8. Whether the level-1 dot check is itself a `term_check'`. PLAN 1681 lists it as a recording site, but 6.10 names only `"standard"` and the coercion check.
9. Which C is recorded for learnt fields (exit function, or the level-1 marker check).
10. How `check` returns its context: change `check` and add `#1` at the four `apply_*` (S:970-973), or add a second function.
11. Where the carrier print translation and the `_dot_access` output syntax live (A.5, A.6), and whether `_dot_ident` (a parse marker in Term_Position) also serves as an output-only name (PLAN 1671).
12. Gating `parse_trrule`'s second parse (0.13).
13. Where the warning is computed: `decode_ident` row 4, and/or stock's plain Free branch for long identifiers that get no marker; whether row 5's constant object triggers it (WSP's Free-branch hook would); whether `site.binders` is still needed under the constant-only object rule; how `site` threads through `decode_ident`. Test consequences: `Warn_Tests_A` A04 (`A/step1/ref/regwarn/warn/tests/Warn_Tests_A.thy:74`) flips under §6; A30-A39, A50-A53, A60-A62, B01-B05, B08, B20-B23, B30, B40-B43 and the mutants `no_refinement`/`outermost_binder` exercise the superseded rule.
14. `CONST` printing mechanics: how `pretty_entity_cache` gets the exclusion set (local `exclude_consts`, or export something); constants only; where the printer reads the switch.
15. The coercion skeleton:
    - (a) an observed entry on prepared input that returns the typing (node-instance parameters use the carrier key's index);
    - (b) the `carrier` hook signature (`app`, `err`, state);
    - (c) `tolerate` per call site;
    - (d) where the D6 spine reader lives;
    - (e) ESR's copy of stock's clash path (P:2586-2647) against the CLAUDE.md reuse rule;
    - (f) vestigial code: P's option-b `learn` second component (always NONE, P:3169-3177) and `explicit_result_f`'s argument.
16. `Dot_Field.prep_output`: use 2026's `Name.clean`; copy versus lift, given "原版 infer 一字不改" (stock `infer` unchanged word for word, PLAN 1560) and the CLAUDE.md reuse rule.
17. The guard's exact exclusion set (B.8).
18. Stand-in stage numbers. The payload rebuild must run before −100. The exit-report stand-in must run above 101, because HOL-Library `rewrite.ML:90` registers `hole_expansion` at 101, and it must return `NONE`, because `perhaps_loop` (S:960) loops while a check returns `SOME`.
19. The ambiguous input case. `parse_term` type-checks every tree (S:422-428), so an exit report would fire per tree, as stock's typing report does. This matters for the step-2 test "报告恰一次" (reported exactly once) and for K7.
20. Whether `defined` respects visibility. An Item_Net query `Const (f) $ Var` returns all of f's entries (S net.ML:202).
21. The step-2 `print_checks` test wording (0.7).

---

## E. Dependencies and a writing order for user-space testing

**Dependency graph.**
- The codec, identifier helpers and switches (dot_field part 1) are used by: syntax_phases (parse), term_position (the marker name only, which lives in Term_Position), the type_infer_context rebuild, both engines, the printer and the warning.
- The registry (dot_field part 2) is used by: `decode_ident` row 6 (`defined`), the warning (`candidates`, `defined`), the rule (`candidates`), markup (the stored term), the record hook and the attribute file.
- The rule, texts and last check (part 3) are used by: both engines, `learn`, the level-1 check, the warning (U only).
- D14 and the level-1 check (part 4) need the standard engine's learning branch to work at all: a coercion-engine learning run goes through stock `Syntax.check_terms` with coercions off, so the *standard* engine's flag branch and the level-1 check do the learning. **The standard engine and Pure D14 therefore come before the coercion engine's D14 path.**
- Selection recording (part 5) is written by both engines and read by the `check_terms` exit.

**Proposed order.** Each step loads in user space as an `ML_file` of the derive builds, with `edits.py` gaining CHANGED_FILES, NEW_FILES, LOAD and USERSPACE entries per step.

1. **dot_field.ML part 1 + term_position.ML.**
   - Contents: options, payload codec (with the serial key), carrier helpers, identifier-marker helpers, `is_fixed`, "is constant".
   - User-space edits: the carrier constant name (a test theory with `consts dot_access`); the options via `Attrib.register_config_bool` in a setup, or `Attrib.setup_config_bool`; `is_const_declared` re-implemented (VD:116-119).
   - Tests: the codec section C and survival section G of `A/step1/ref/parse/tests/Dot_Parse_User.thy` (its sections B, E, H, I belong to the superseded split).
2. **Registry, attribute file, record-hook stand-in.**
   - Test: P01-P11 (`A/step1/ref/regwarn/registry/probes/`, driver `run_probes.sh`, loader `A/step1/ref/regwarn/use_thy26.ML`), rewritten with constants, plus the §6.12 locale tests.
   - Record stand-in: a P05-style `setup` after each `record` (P05_Records.thy:11-15).
   - Independent of everything else; it must exist before row 6 and before the rule.
3. **Rule, texts, last check on `candidates`.** Test with probes in R's style (`select`/`expect_select`, R:136-150, 285-294) and P11 (unifier agreement).
4. **syntax_phases.ML (parse side) and the pure_thy and syntax.ML pieces.**
   - Contents: `decode_free`, the two `ast_to_term` clauses, `decode_ident` rows 1-6, the exported `decode_term`, the gated second parse, `parse_term`.
   - User space cannot install a second syntax_phases (S syntax.ML:165-168), so tests call the copy's `parse_term` and then the real `Syntax.check_term`. This follows V: `A/step1/ref/localfirst/V/V_Base.thy` loads `term_position_v.ML`, `dot_field_v.ML`, the phases copy and `trans_v.ML`, then sets routes.
   - HOL translations that call `Term_Position` are compiled against the patched copy (`make_trans_v.py` → VTR).
   - Tests: V_JAll and V_Fixed (corpus oracle), V_DProto, V_Attack, V_Sanity, through `A/step1/ref/localfirst/V/run.sh` → `../runjob.sh`. The G1 (i) additions are registrations named after the second segment (PLAN 2158-2164).
   - The `(e).f` battery is `parser_battery.ML` (`A/step1/probes/parse_check/`).
   - **Gap:** no prototype has run an end-to-end `(e).f` through a syntax_phases copy in user space. It needs a grammar built from HOL's xprods plus `_dot_field` (as `A/step1/probes/first_parse/First_Parse_Setup.thy` builds one through `Unsafe_Cast.thy`) and a phases copy compiled against CL/CP.
5. **Warning (dot_field section + syntax_phases channel).** Needs steps 2-4. Tests: Warn_Tests_A/B through `A/step1/ref/regwarn/warn/harness/make_harness.py` and `run_phase2.sh`, adjusted to the §6 object rule (D.2 item 13).
6. **type_infer_context.ML: the `prepare_positions` rebuild and the standard engine.**
   - Stand-ins from the PLAN 2142-2149 table:
     - the rebuild registered as a check before −100 (so that `class_declaration.ML:354` and Isar commands reach it, which fixes `St0_CloseForm` per G1 (ii));
     - the engine at levels −1 and 0 (stock `"standard"` still runs);
     - the level-1 dot check.
   - The copy of type_infer_context shadows `Type_Infer_Context` only for later ML files.
   - Tests: the coercion-off lists of engine6 (`A/step1/ref/engine6/`: `runjob.sh`, `Loader.ML` `Mini_Loader.use_thy`, harness `Crit_Harness.thy:33-75`, `reference.tsv`, `cmp_tags.py`) and engine3 (`A/step1/ref/engine3/`, REF lists `B C LR rr cargs probe`); G2 (b) in the observation build.
7. **Pure D14: learning flag, `LEARNT`, `learn`, guard, markers, level-1 dot check.** Plus the standard engine's flag branch. Test: the D14 lists with coercions off; `St0_CloseForm` line 24.
8. **Selection recording; `check` returning its context; the exit report; `term_check'` registrations; `simple_check` export.**
   - Stand-in: the highest-level `term_check'` (above 101, returning `NONE`), and the reporting code taken out of `check_terms` into a function both can call.
   - Tests: the field-segment markup cases (`A/probes/markup_fold/`).
9. **Coercion engine ESR part** (SK + hooks + exits + D15 + D14 path + registration).
   - Needs steps 1, 3, 7, 8.
   - User space: `A/step1/probes/coercion_first/` (`Coercion_Setup.thy`, copies A/B/F, `userspace_replay`), plus **its own gating option** (0.12); engine6 and engine3 coercion-on lists; G2 (a), (c), (d).
10. **`CONST` printing** in `pretty_entity_cache`. Needs step 1 only. Test by direct calls (PLAN 2148), plus V_Attack E01-E03 read-back.
11. **attrib.ML lines, the ROOT.ML lines, the record.ML line.** These have no user-space effect; step 1 uses stand-ins for them, and step 2 tests them for real.

**User-space stand-ins** (beyond PLAN's table):
- options registered by a setup;
- the carrier constant in a test theory;
- `is_const_declared` re-implemented;
- `simple_check` re-implemented;
- the HOL translations recompiled against the patched `Term_Position`;
- a separate gating option for the coercion copy;
- `ML_check_strings` legacy warnings in copies (for example PD:36, 68, 73, and the stock string `"Syntax_Phases.parse_term"` that warned 51 times in the localfirst runs).
