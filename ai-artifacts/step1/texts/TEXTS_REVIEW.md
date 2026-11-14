# dot_syntax step 1 (r10): every user-visible text, with its real rendering

This file collects, for the owner's one-time review (plan `DOT_SYNTAX_PLAN.md` §6.6), every text that the
step-1 code (`step1/src/`, revision r10) can show to a user, and every grammar or option name a user can see.
It changes nothing; it only reports. Each entry gives: where the text is in the code, whether the owner has
already approved it (with the plan item) or it is a draft, a minimal input that produces it, the text as
Isabelle actually printed it, and anything that looks wrong.

## How the renderings were captured

Step 2 (the patched Isabelle tree) is not built, so every rendering comes from user space: one
`isabelle ML_process` on the official Isabelle2026 HOL heap on cslh19, loading the clean r10 build exactly as
the parse suite does (`tests/parse/Parse_Base.thy`), plus the clean coercion copy, plus the stand-ins of plan
6.12 on Pure's check phase (payload rebuild at stage −200, the standard engine at stages −1 and 0, the dot
check at stage 1). The probe theories are in `step1/texts/`; the harness is `step1/texts/Texts_Base.thy`.

- `dot_term "…"` reads a term text the way step 2's `term "…"` will: the clean parse (with its warnings),
  then Pure's check phase with the stand-ins; `dot_syntax` on, coercions off (the standard engine).
  `dot_term_co "…"` is the same with coercions on (the coercion engine). Both give the text the positions
  that jEdit gives (an id and an offset, no line).
- `dot_term_batch "…"` uses the positions of a batch build (a line and a file, no id).
- The triggers below are written as a user will write them in step 2 (`term "…"`, with `declare [[dot_syntax]]`
  in force); the probe theories run the same text through `dot_term` (or `dot_term_co` where an entry says
  "coercions on").
- An error is printed the way the toplevel prints it (`Output.error_message`), so each line starts with
  `*** `; a warning starts with `### `. In jEdit the same text appears without these prefixes.
- Registration and attribute errors come from real `declare [[dot_field …]]` commands, one failing
  declaration per theory (`Texts_Reg_NN.thy`), so those renderings are exactly the toplevel's.

Outputs: `step1/texts/out/all.out` (term texts, names) and `step1/texts/out/reg.out` (registration), both
copied from cslh19 `~/Current/MLML/ai-artifacts/dot_syntax_timing/step1-tests/texts/out/`. Run script:
`step1/texts/run.sh`. Line references below are into these files unless another file is named.

Symbols are shown as the log shows them: `\<^here>` is the position marker that jEdit draws as ⌂ (a
link to the place in the text); `\<Rightarrow>` is ⇒, `\<dots>` is …, `\<lambda>` is λ, `\<times>` is ×.

Two things user space cannot show, and what the entries do about them:

1. **Positions in a batch build.** Isabelle keeps an inner-syntax position only when it has an id, which
   jEdit's positions have and a batch build's do not. So in a batch log none of the term-level texts below
   (and none of Isabelle's own inner-syntax texts, e.g. `Undefined constant`) carries a position; in jEdit
   each carries `\<^here>`. Entry A19 shows both side by side; the parse-failure hint (group E) is the exception,
   because it is raised before positions are filtered.
2. **The clean printer.** Messages are printed by Pure's installed printer, which user space cannot replace,
   so the `CONST` that the clean printer adds is missing from the message itself. Entry H2 shows the message
   and, next to it, the clean printer's output for the same candidate terms in the same context.

Status words: **approved** = the owner approved this wording (plan §1 item cited); **draft** = the text is in
§6.6's list of texts still to be reviewed, or (where said) not named there at all.

---

## A. Errors of field selection (the rule's texts)

All of group A is `Dot_Field.field_error_msg`, `src/src/Pure/Syntax/dot_field.ML:947-1027`. Records used:
`point = xpos :: int ypos :: int`, `cpoint = point + color :: nat`, `cpoint2 = point + xpos :: nat`,
`other = xpos :: nat`, `seg = start :: point stop :: point` (`step1/texts/Texts_Setup.thy`).

### A1. Step 5 (two or more fields match), identifier form

- Where: `dot_field.ML:967-968` (headline), `:990-995`.
- Status: **approved**, §1 item 7 (wording). The candidate order is not approved (see A16).
- Trigger: `context fixes c :: cpoint2 begin  term "c.xpos"  end`
- Rendering (`all.out:1392-1397`):
  ```
  *** Ambiguous field "xpos" of c :: cpoint2\<^here>
  *** "c.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
  ***   cpoint2.xpos c :: nat
  ***   point.xpos c :: int
  *** Write one of these terms instead.
  ```
- Looks wrong: nothing in the wording; it equals the approved text plus the position marker (A19).

### A2. Step 5, bracket form `(e).f`

- Where: `dot_field.ML:993` (the `if paren` that drops the half-sentence).
- Status: **draft**, §6.6 ("括号形式下省去 `"c.xpos" is not a constant` 半句").
- Trigger: `context fixes c :: cpoint2 begin  term "(c).xpos"  end`
- Rendering (`all.out:1404-1409`):
  ```
  *** Ambiguous field "xpos" of c :: cpoint2\<^here>
  *** cpoint2 has 2 fields named "xpos":
  ***   cpoint2.xpos c :: nat
  ***   point.xpos c :: int
  *** Write one of these terms instead.
  ```
- Looks wrong: nothing.

### A3. Step 6 (the type is not determined enough), identifier form

- Where: `dot_field.ML:1019-1024`.
- Status: **approved**, §1 item 7.
- Trigger: `term "λu :: _ point_scheme. u.xpos"`
- Rendering (`all.out:1410-1415`):
  ```
  *** Ambiguous field "xpos" of u :: ??'a point_scheme\<^here>
  *** "u.xpos" is not a constant, and the type of u is not determined enough to choose among:
  ***   cpoint2.xpos u :: nat
  ***   point.xpos u :: int
  *** Write one of these terms instead, or fix the type of u.
  ```
- Looks wrong: nothing new. The type shows as `??'a point_scheme` (an inference parameter) where the approved
  example shows `?'z point_scheme`; §1 item 7 says the variable name follows type inference.

### A4. Step 6, bracket form

- Where: `dot_field.ML:1021` (`if paren then "The type of "`).
- Status: **draft**, §6.6 (bracket variants).
- Trigger: `term "λu :: _ point_scheme. (u).xpos"`
- Rendering (`all.out:1416-1421`):
  ```
  *** Ambiguous field "xpos" of u :: ??'a point_scheme\<^here>
  *** The type of u is not determined enough to choose among:
  ***   cpoint2.xpos u :: nat
  ***   point.xpos u :: int
  *** Write one of these terms instead, or fix the type of u.
  ```
- Looks wrong: nothing.

### A5. Step 1 (the type is unknown), identifier form, with the list

- Where: `dot_field.ML:1004-1017`.
- Status: **approved**, §1 item 7 (wording); the order of the list lines is the draft of A16.
- Trigger: `term "z.xpos"` (`z` an undeclared free variable).
- Rendering (`all.out:1422-1427`):
  ```
  *** Field "xpos" of z cannot be resolved: the type of z is unknown\<^here>
  *** "z.xpos" is not a constant. Fields named "xpos" exist for:
  ***   cpoint2.xpos :: ?'z cpoint2_scheme \<Rightarrow> nat
  ***   other.xpos :: ?'z other_scheme \<Rightarrow> nat
  ***   point.xpos :: ?'z point_scheme \<Rightarrow> int
  ```
- Looks wrong: nothing. (The approved example listed `other`, `cpoint2`, `point`, newest first; now by name.)

### A6. Step 1 with no field of that name: the list line is left out

- Where: `dot_field.ML:1008-1015` (`line2` without "Fields named … exist for:" when `gs` is empty).
- Status: **draft**, §6.6 ("字段列表为空时省去 … 那一行"; MERGE.md §3 says both list lines are left out).
- Trigger: `term "λz. z.foo"` (no field named `foo` anywhere).
- Rendering (`all.out:1428-1430`):
  ```
  *** Field "foo" of z cannot be resolved: the type of z is unknown\<^here>
  *** "z.foo" is not a constant.
  ```
- Looks wrong: nothing.

### A7. Step 1, bracket form (with and without candidates)

- Where: `dot_field.ML:1009-1015` (`if paren then []`; with no candidates there is no second line at all).
- Status: **draft**, §6.6 (bracket variants).
- Trigger: `term "(f k).xpos"`; `term "(z).foo"`.
- Rendering (`all.out:1431-1438`):
  ```
  *** Field "xpos" of f k cannot be resolved: the type of f k is unknown\<^here>
  *** Fields named "xpos" exist for:
  ***   cpoint2.xpos :: ?'z cpoint2_scheme \<Rightarrow> nat
  ***   other.xpos :: ?'z other_scheme \<Rightarrow> nat
  ***   point.xpos :: ?'z point_scheme \<Rightarrow> int
  ```
  ```
  *** Field "foo" of z cannot be resolved: the type of z is unknown\<^here>
  ```
- Looks wrong: nothing.

### A8. Step 3 (no field fits), identifier form, with the "Fields of" line

- Where: `dot_field.ML:996-1001`, `:970-973`.
- Status: **approved**, §1 item 7.
- Trigger: `context fixes r :: point begin  term "r.foo"  end`
- Rendering (`all.out:1439-1441`):
  ```
  *** "r.foo" is neither a constant nor a field of r :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
- Looks wrong: nothing.

### A9. Step 3 with no field of the type: the "Fields of" line is left out

- Where: `dot_field.ML:970-973` (`[] => []`).
- Status: **draft**, §6.6 ("字段列表为空时省去 "Fields of …" 那一行").
- Trigger: `context fixes b :: bool begin  term "b.foo"  end`
- Rendering (`all.out:1442-1443`):
  ```
  *** "b.foo" is neither a constant nor a field of b :: bool\<^here>
  ```
- Looks wrong: nothing.

### A10. Step 3, bracket form ("is not a field of", without "a constant nor")

- Where: `dot_field.ML:1000` (`if paren then " is not"`).
- Status: **draft**, §6.6 (bracket variants; INVENTORY D.4 row 30 left steps 1, 3, 6 open).
- Trigger: `context fixes g :: "nat ⇒ point" begin  term "(g k).foo"  end`; `term "(origin).foo"`
  with a constant `origin :: point`.
- Rendering (`all.out:1444-1446`, `:1487-1489`):
  ```
  *** "(g k).foo" is not a field of g k :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
  ```
  *** "(origin).foo" is not a field of origin :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
- Looks wrong: the quoted text is rebuilt, not copied: the object is printed, so a written type or other
  detail disappears. Example in E2: the user writes `(x::nat).x`, the message quotes `"(x).x"`.

### A11. Chains: an object that is itself a field access is shown as written

- Where: `dot_field.ML:926-944` (`written`, `printer`).
- Status: **draft** (part of §6.6 "报错里未决定的字段显示为 …"; not separately named).
- Trigger: `context fixes s :: seg and h :: "nat ⇒ seg" begin  term "s.start.color"  term "(h k).start.foo"  end`
- Rendering (`all.out:1447-1452`):
  ```
  *** "s.start.color" is neither a constant nor a field of s.start :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
  ```
  *** "(h k).start.foo" is not a field of (h k).start :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
- Looks wrong: nothing.

### A12. The written prefix is a constant (step 3 on the constant), with `CONST` and `for` / `fixes`

- Where: `dot_field.ML:975-987` (`constant_object`), used at `:997`.
- Status: **draft**, §6.6 (first item of the list; seventh-round deep review issue 5).
- Triggers and renderings:
  - `term "origin.foo"` with `definition origin :: point` (`all.out:1463-1467`):
    ```
    *** "origin.foo" is neither a constant nor a field of the constant origin :: point\<^here>
    *** Fields of point: xpos, ypos
    *** "origin" is read as the constant CONST origin, because "origin" is not a local variable here.
    *** For a field of a variable origin, make it local: "for origin" after a defining equation, "fixes origin" in a statement.
    ```
  - The plan's example, `seg.start.xpos` in a defining equation: `term "foo seg = seg.start.xpos"`, `seg` not
    fixed, so the prefix `seg.start` is the record selector (`all.out:1468-1471`):
    ```
    *** "seg.start.xpos" is neither a constant nor a field of the constant start :: ??'a seg_scheme \<Rightarrow> point\<^here>
    *** "seg.start" is read as the constant CONST seg.start, because "seg" is not a local variable here.
    *** For a field of a variable seg, make it local: "for seg" after a defining equation, "fixes seg" in a statement.
    ```
    With `context fixes seg :: seg` the same text is accepted as `point.xpos (start seg)` (`all.out:1490-1491`),
    so the advice works.
  - A theory-qualified constant: `term "Texts_Setup.origin.foo"` (`all.out:1482-1486`):
    ```
    *** "Texts_Setup.origin.foo" is neither a constant nor a field of the constant origin :: point\<^here>
    *** Fields of point: xpos, ypos
    *** "Texts_Setup.origin" is read as the constant CONST Texts_Setup.origin, because "Texts_Setup" is not a local variable here.
    *** For a field of a variable Texts_Setup, make it local: "for Texts_Setup" after a defining equation, "fixes Texts_Setup" in a statement.
    ```
- Looks wrong:
  1. The constant is named two ways in one message: "the constant start" (printed, short name) in line 1,
     "CONST seg.start" (written) in line 2. Same for `origin` vs `Texts_Setup.origin`.
  2. The constant's type shows an inference parameter: `start :: ??'a seg_scheme ⇒ point`.
  3. When the first segment is a theory name, lines 3–4 advise making `Texts_Setup` a local variable,
     which makes no sense.

### A13. The written prefix is a constant of unknown type

- Where: `dot_field.ML:1005` (no candidates: the variant of A12 without a Fields line); with candidates the
  approved step-1 text of A5.
- Status: no candidates: **draft** (§6.6, same item as A12); with candidates: **approved** wording (§1 item 7).
- Triggers: `term "undefined.foo"`; `term "undefined.xpos"`.
- Rendering (`all.out:1472-1481`):
  ```
  *** "undefined.foo" is neither a constant nor a field of the constant undefined :: ??'a\<^here>
  *** "undefined" is read as the constant CONST undefined, because "undefined" is not a local variable here.
  *** For a field of a variable undefined, make it local: "for undefined" after a defining equation, "fixes undefined" in a statement.
  ```
  ```
  *** Field "xpos" of undefined cannot be resolved: the type of undefined is unknown\<^here>
  *** "undefined.xpos" is not a constant. Fields named "xpos" exist for:
  ***   cpoint2.xpos :: ?'z cpoint2_scheme \<Rightarrow> nat
  ***   other.xpos :: ?'z other_scheme \<Rightarrow> nat
  ***   point.xpos :: ?'z point_scheme \<Rightarrow> int
  ```
- Looks wrong: the two texts for the same constant object differ in kind, not only in the list: with no
  field of that name the user gets A12's explanation (`CONST`, `for` / `fixes`); as soon as some field of
  that name exists anywhere, the user gets the plain step-1 text, which calls the constant `undefined` an
  object of unknown type and says nothing about it having been read as a constant or how to make it local.

### A14. The first segment is local and the whole identifier is a constant — the planned text is missing

- Where: no own text; the ordinary texts A8 / A1 apply.
- Status: **missing**. §1 item 16 (2026-10-31, after the jEdit screenshot) says that in this case the error
  for a field that does not exist "仍提到那个常量与 `CONST` 写法（文案待实现第一步后过目）". The code has no
  such text.
- Triggers: `context fixes point :: bool begin  term "point.xpos"  end`;
  `context fixes point :: cpoint2 begin  term "point.xpos"  end` (`point.xpos` is the record selector).
- Rendering (`all.out:1492-1499`):
  ```
  *** "point.xpos" is neither a constant nor a field of point :: bool\<^here>
  ```
  ```
  *** Ambiguous field "xpos" of point :: cpoint2\<^here>
  *** "point.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
  ***   cpoint2.xpos point :: nat
  ***   point.xpos point :: int
  *** Write one of these terms instead.
  ```
- Looks wrong: both say `"point.xpos"` is not a constant, which is false here (it is the record selector;
  `CONST point.xpos` would reach it). This is the case §1 item 16 promised a text for.

### A15. The five-item bound and the ellipsis, in all three lists

- Where: `dot_field.ML:897-905` (`bounded`, `bounded_lines` → a line `  \<dots>`, `bounded_commas` → `, \<dots>`).
- Status: the bound of five with an ellipsis is **approved**, §1 item 19; the exact form of the ellipsis
  and which five are shown are **draft** (§1 item 19 and §6.6).
- Setup (`step1/texts/Texts_Bound.thy`): seven records, each extending the previous one with its own field
  `many`, defined in the order m7 m3 m5 m1 m6 m2 m4 (so the registry, newest first, holds m4 m2 m6 m1 m5 m3
  m7); a record `wide` with seven fields zeta alpha mu beta omega gamma delta. Records register silently,
  so seven same-named fields are possible.
- Renderings:
  - Step 5, `context fixes q :: m4 begin  term "q.many"  end` (`all.out:1502-1511`):
    ```
    *** Ambiguous field "many" of q :: m4\<^here>
    *** "q.many" is not a constant, and m4 has 7 fields named "many":
    ***   m1.many q :: nat
    ***   m2.many q :: nat
    ***   m3.many q :: nat
    ***   m4.many q :: nat
    ***   m5.many q :: nat
    ***   \<dots>
    *** Write one of these terms instead.
    ```
  - Step 6, `term "λq :: _ m7_scheme. q.many"` (`all.out:1512-1521`): same five lines and `  \<dots>`, ending
    `Write one of these terms instead, or fix the type of q.`
  - Step 1, `term "λz. z.many"` (`all.out:1522-1530`):
    ```
    *** Field "many" of z cannot be resolved: the type of z is unknown\<^here>
    *** "z.many" is not a constant. Fields named "many" exist for:
    ***   m1.many :: ?'z m1_scheme \<Rightarrow> nat
    ***   m2.many :: ?'z m2_scheme \<Rightarrow> nat
    ***   m3.many :: ?'z m3_scheme \<Rightarrow> nat
    ***   m4.many :: ?'z m4_scheme \<Rightarrow> nat
    ***   m5.many :: ?'z m5_scheme \<Rightarrow> nat
    ***   \<dots>
    ```
  - Step 3, `context fixes w :: wide begin  term "w.foo"  end` (`all.out:1531-1533`):
    ```
    *** "w.foo" is neither a constant nor a field of w :: wide\<^here>
    *** Fields of wide: alpha, beta, delta, gamma, mu, \<dots>
    ```
  - Exactly five: no ellipsis, `term "λq :: _ m6_scheme. q.many"` (`all.out:1534-1542`):
    ```
    *** Ambiguous field "many" of q :: ??'a m6_scheme\<^here>
    *** "q.many" is not a constant, and ??'a m6_scheme has 5 fields named "many":
    ***   m1.many q :: nat
    ***   m3.many q :: nat
    ***   m5.many q :: nat
    ***   m6.many q :: nat
    ***   m7.many q :: nat
    *** Write one of these terms instead.
    ```
- Looks wrong: (1) the count in "m4 has 7 fields named" is the full count while only five are shown —
  intended, but the ellipsis line does not say how many are hidden. (2) "??'a m6_scheme has 5 fields named"
  reads oddly: a type with an inference parameter "has" fields (step 5 can fire before the type is final).
  (3) The warning (group D) lists its readings without any bound.

### A16. The order of the candidate lines

- Where: `dot_field.ML:914-922` (`sort_candidates`: by the printed name of the head constant after folding
  abbreviations, else by the printed term), used at `:966` and `:1016`.
- Status: **draft**. §1 item 7: "建议候选按全名排序以使输出稳定（未批…）"; §6.6 lists it.
- Rendering: A15 shows the effect: registry order m4 m2 m6 m1 m5 m3 m7, shown m1 … m5 (the five
  alphabetically first; m6 and m7 are cut). A1/A5 show `cpoint2.xpos` before `point.xpos`. An abbreviation
  sorts by its folded name, a λ-registration (only from ML now) by its printed text: tests/core T18,
  `step1/r10/results/core/out/Core_Select.out:480-486` (`xs`, `length xs`, `rev xs`; `length` is stored as
  `size` and sorts as `length`).
- Looks wrong: the order follows the printed (shortest unambiguous) name, so the same fields can sort
  differently in different theories where the short names differ.

### A17. A misspelt qualified constant

- Where: `src/src/Pure/Syntax/syntax_phases.ML:367-373` (`misspelt`), `:398`; otherwise A5's text.
- Status: **approved**, §1 item 15 and §6.6 ("已定的"): stock's `Undefined constant` when no field of that
  name is registered anywhere; the step-1 text when one is.
- Triggers: `term "z.foo"`, `term "Lisst.map f ys"`; with `declare [[dot_field fil]]` (`fil :: nat list ⇒ nat
  list`), `term "List.fil ns"`.
- Rendering (`all.out:1453-1456`, `:1459-1462`):
  ```
  *** Undefined constant: "z.foo"\<^here>
  ```
  ```
  *** Undefined constant: "Lisst.map"\<^here>
  ```
  ```
  *** Field "fil" of List cannot be resolved: the type of List is unknown\<^here>
  *** "List.fil" is not a constant. Fields named "fil" exist for:
  ***   fil :: nat list \<Rightarrow> nat list
  ```
- Looks wrong: nothing beyond what §1 item 15 accepted (the theory qualifier `List` is called a variable
  whose type is unknown).

### A18. A rejected term whose fields are all decided: stock's text on the explicit form E(C)

- Where: stock (`src/src/Pure/type_infer_context.ML:478-480`, `err_appl` on `Dot_Field.explicit`); a field
  decided late whose decision clashes makes the standard engine run again with the field decided at its
  node (`:386`, `:524-525`).
- Status: **approved**, §6.6 ("被拒的 term 若已决定了全部字段，显示原版对 E(C) 的报错").
- Triggers: `context fixes p :: point and r :: point begin  term "p.xpos + (1::nat)"  term "t.xpos = (1::nat) ∧ t = r"  end`
- Rendering (`all.out:1545-1560`):
  ```
  *** Type unification failed: Clash of types "nat" and "int"
  *** 
  *** Type error in application: incompatible operand type
  *** 
  *** Operator:  (+) (point.xpos p) :: int \<Rightarrow> int
  *** Operand:   1 :: nat
  *** 
  ```
  ```
  *** Type unification failed: Clash of types "nat" and "int"
  *** 
  *** Type error in application: incompatible operand type
  *** 
  *** Operator:  (=) (point.xpos t) :: int \<Rightarrow> bool
  *** Operand:   1 :: nat
  *** 
  ```
- Looks wrong: nothing (the text names `point.xpos t`, not what the user wrote; that is the approved
  policy). The round-3 draft for a late clash (TEXTS.md §4, "Type error in field access …") no longer exists.

### A19. The position marker of every rule text

- Where: `dot_field.ML:956` (`here`), appended to the first line of every text in group A.
- Status: **draft** (not approved separately; the approved renderings in §1 item 7 have no marker;
  INVENTORY D.4 row 16 proposed it).
- Trigger: the same text read with jEdit-like positions and with batch positions:
  `term "c.xpos"` (`all.out:1392-1403`).
- Rendering: jEdit-like (A1) ends the first line with `\<^here>` (in jEdit ⌂, a link to the field segment);
  batch:
  ```
  *** Ambiguous field "xpos" of c :: cpoint2
  *** "c.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
  ```
- Looks wrong: in a batch build log no dot error says where it is (stock's inner-syntax errors behave the
  same). Only the toplevel's "At command …" line locates it.

### A20. D14: the learning run learns nothing — step 1

- Where: `type_infer_context.ML:502-504` (standard engine), the coercion engine's equivalent; text A5.
- Status: **approved** wording (§1 item 7; §1 item 18 names this case: "报已批的'类型未知'文案").
- Setup (`step1/texts/Texts_D14.thy`): `consts mk :: "'a ⇒ 'b"`, `adhoc_overloading mk ⇌ mkP mkO` with
  `mkP :: int ⇒ point`, `mkO :: nat ⇒ other`; `k :: int` fixed.
- Trigger: `term "(λt. t.xpos) (mk y)"`, coercions off and on.
- Rendering (`all.out:1728-1739`, both modes the same):
  ```
  *** Field "xpos" of t cannot be resolved: the type of t is unknown\<^here>
  *** "t.xpos" is not a constant. Fields named "xpos" exist for:
  ***   cpoint2.xpos :: ?'z cpoint2_scheme \<Rightarrow> nat
  ***   other.xpos :: ?'z other_scheme \<Rightarrow> nat
  ***   point.xpos :: ?'z point_scheme \<Rightarrow> int
  ```
  The bracket form on the overloaded object, `term "(mk y).xpos"` (`all.out:1758-1763`):
  ```
  *** Field "xpos" of mk y cannot be resolved: the type of mk y is unknown\<^here>
  *** Fields named "xpos" exist for:
  ...(the same three lines)
  ```
- Looks wrong: nothing.

### A21. D14: rule errors that appear only after stage 0 (steps 3 and 5 on the learnt type)

- Where: `dot_field.ML:1274-1280` (`learn` → `report_unresolved` on the learning run's last batch), texts
  A8 / A1.
- Status: **draft**, §6.6 ("D14 学不到时与第 0 级后才暴露的错误的文案（引用所写的标识符与对象）").
- Triggers: `term "(λt. t.di) (mk k)"` with `declare [[dot_field di = dbl_i]]` (`dbl_i :: int ⇒ int`);
  `term "(λt. t.xpos) (mkc n)"` with `adhoc_overloading mkc ⇌ mkC2`, `mkC2 :: nat ⇒ cpoint2`.
- Rendering (`all.out:1740-1757`; coercions off and on identical):
  ```
  *** "t.di" is neither a constant nor a field of mk k :: point\<^here>
  *** Fields of point: xpos, ypos
  ```
  ```
  *** Ambiguous field "xpos" of mkc n :: cpoint2\<^here>
  *** "t.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
  ***   cpoint2.xpos (mkc n) :: nat
  ***   point.xpos (mkc n) :: int
  *** Write one of these terms instead.
  ```
- Looks wrong: the written identifier is quoted (`"t.di"`, `"t.xpos"`), but the object is printed after beta
  reduction (`mk k`, `mkc n`), so one message calls the object `t` in one place and `mkc n` in another, and
  the suggested terms are `cpoint2.xpos (mkc n)` rather than something with `t`. §6.6 asks that these texts
  cite the written identifier and the object; the object is not the written one.

### A22. A field that beta normalisation drops

- Where: no own text: A5 at a new place (INVENTORY D.3 row 34: "no new wording").
- Status: **approved** wording (§1 item 7).
- Triggers: `term "(λu. n) z.xpos"`; `term "(λu. n) ((λt. t.xpos) (mk k))"`.
- Rendering (`all.out:1772-1783`): A5's text for `z`, resp. for `t`.
- Looks wrong: in the second, the object type would be known after adhoc_overloading, but the field is
  dropped first, so the user gets "the type of t is unknown" although the explicit form
  `(λu. n) ((λt. point.xpos t) (mk k))` is accepted (an expected rejection in tests/standard St0_D14, "DROP").

---

## B. The last check

All three are `Dot_Field.last_check_field`, `dot_field.ML:1034-1055`.

### B1. The final type selects another registration

- Where: `dot_field.ML:1046-1047`.
- Status: **draft**, §6.6 ("最后检查推翻选择的三条"; draft wording from `reviews/round3/DECISIONS.md` §5.2).
- Setup (`step1/texts/Texts_Last.thy`): `declare [[dot_field dd = dbl_i, dot_field dd = dbl_n, dot_field gi]]`
  (`dbl_i, gi :: int ⇒ int`, `dbl_n :: nat ⇒ nat`); fixed `k :: int`, `Pn :: nat ⇒ bool`, `Pi :: int ⇒ bool`.
- Trigger (coercions on; the shape of r10's d3/D3A_1 A12): `term "t = v ∧ Pn v ∧ t.dd > 0 ∧ t.gi = k ∧ Pi t"`
- Rendering (`all.out:1704-1705`):
  ```
  *** Field "dd": chose dbl_i :: int \<Rightarrow> int but the object's final type nat selects dbl_n :: nat \<Rightarrow> nat\<^here>
  ```
  Coercions off, the same text gives A8's text for `t.gi` (`all.out:1706-1708`).
- Looks wrong: (1) "chose" is the engine's vocabulary — the user chose nothing; (2) the object is not named
  (no `t`, no `"t.dd"`), unlike every text of group A; (3) no suggestion what to write. (INVENTORY D.2 row 5
  listed the same; only the position has been added since.)

### B2. The final type no longer selects the choice

- Where: `dot_field.ML:1049-1050`.
- Status: **draft**, §6.6.
- Trigger: none found. No r10 run reaches it (only the coercion mutant `m_exit_reader` printed it, e.g.
  cslh19 `step1-tests/coercion/out/m_exit_reader.VB_Battery1.on.out:1474`). At stage 1 every type variable is
  rigid, so the rule never answers "wait" there; in the standard engine a choice is made only on a singleton
  candidate set, which an instance of the type cannot turn into "wait". It would need the coercion engine to
  have chosen while the rule waited.
- Rendering from ML on a decided access (tests/core L3, `step1/r10/results/core/out/Core_Select.out:563-564`;
  no position there; in a real run `\<^here>` follows):
  ```
  Field "xpos": the object's final type ??'a point_scheme no longer selects point.xpos :: ?'z point_scheme \<Rightarrow> int
  ```
- Looks wrong: as B1 (no object, engine vocabulary); and it is very likely unreachable.

### B3. The choice is not confirmed on the final type (followed by the rule's text)

- Where: `dot_field.ML:1052-1054`.
- Status: **draft**, §6.6.
- Setup: `declare [[dot_field pa = fa, dot_field pb = fb]]` with `fa :: int × 'b ⇒ int`, `fb :: nat × 'b ⇒ nat`.
- Trigger (coercions on; r10's d15probes P3): `term "(λt. (t.pa, t.pb)) (undefined :: _ × _)"`
- Rendering (`all.out:1709-1712`):
  ```
  *** Field "pa": the choice fa :: int \<times> ?'a \<Rightarrow> int is not confirmed on the final object type:
  *** "t.pa" is neither a constant nor a field of t :: nat \<times> ??'a\<^here>
  *** Fields of nat \<times> ??'a: pb
  ```
  Coercions off, the same text is rejected at once with A8's text for `t.pb` (`all.out:1713-1715`). Other r10
  renderings: `cl10.CB_Constraints`, `cl10.D14on_Probes` ("STEER", followed by a step-5 text).
- Looks wrong: (1) two headlines — "Field "pa": …" and then the rule's own headline; (2) the position
  marker sits on the second line, not the first; (3) the "final" type still has an inference parameter
  (`nat × ??'a`); (4) "the choice" is engine vocabulary.

---

## C. The stage-1 fallback

### C1. "Field access … was not resolved (internal error)"

- Where: `dot_field.ML:1211-1213` (`report_unresolved`, when the rule would choose).
- Status: **draft**, §6.6 ("第 1 级兜底").
- Reachability: Isabelle's own checks never reach it — the engines resolve every field access or reject the
  term. It is reached when some check that runs before the engine gives the carrier constant its types by
  stock's type inference: the engine then does not recognise the carrier, and stage 1 finds it. In r10 the
  coercion suite's explicit contexts do this (HOL's stock coercion check, dot syntax on), e.g. cslh19
  `step1-tests/coercion/out/cl10_lrn.RC_Flip.on.out:1381-1382`. A third-party check running stock inference
  at a negative stage would do the same.
- Trigger (`step1/texts/Texts_Fallback.thy`: a check at stage −50 that runs `Type_Infer_Context.infer_types`
  on batches with carriers, standing for such a third-party check):
  `context fixes p :: point begin  term "p.xpos + 1"  end`
- Rendering (`all.out:1786-1787`):
  ```
  *** Field access "p.xpos" was not resolved (internal error)\<^here>
  ```
  When the object's type stays unknown, stage 1 gives the rule's text instead, e.g. A7's text for
  `(f k).xpos` (`all.out:1788-1793`).
- Looks wrong: if it is ever seen, it is caused by another tool's check, yet it says "internal error"
  without naming either; nothing tells the user what to do.

---

## D. Warnings

All are `Dot_Field.warning_texts` / `render`, `dot_field.ML:723-737`, emitted from
`syntax_phases.ML:557` for the chosen parse tree.

### D1. One reading

- Where: `dot_field.ML:730-736`.
- Status: **approved**, §1 item 8.
- Trigger: `record config = timeout :: nat retries :: nat`, `definition config :: config`; `term "config.timeout"`.
- Rendering (`all.out:1802-1806`):
  ```
  ### "config.timeout" is read as the constant Texts_Warn.config.timeout :: ?'z config_scheme \<Rightarrow> nat
  ### It could also be read as field access:
  ###   timeout config :: nat
  ### Write that term to mean the field access, or CONST config.timeout to keep the constant without this warning.
  ```
- Looks wrong: nothing; identical to the approved text. (The quoted identifier carries position markup
  only; no position text is shown, in jEdit or in batch.)

### D2. Several readings

- Where: `dot_field.ML:734` (`Write one of these terms`).
- Status: **draft**, §6.6 ("警告多读法时的末句"; §3.1).
- Trigger: `definition point :: cpoint2` (a constant named like the record); `term "point.xpos"`.
- Rendering (`all.out:1808-1813`):
  ```
  ### "point.xpos" is read as the constant Texts_Setup.point.xpos :: ?'z point_scheme \<Rightarrow> int
  ### It could also be read as field access:
  ###   cpoint2.xpos point :: nat
  ###   point.xpos point :: int
  ### Write one of these terms to mean the field access, or CONST point.xpos to keep the constant without this warning.
  ```
- Looks wrong: (1) no five-item bound on the reading lines (A15 bounds the error lists only); (2) the first
  line names the constant by its full name `Texts_Setup.point.xpos`, the reading lines by short names.

### D3. Along a chain

- Where: `dot_field.ML:715-721` (`readings`: every candidate of every segment).
- Status: **draft**, §6.6 ("链上的读法"; §3.1).
- Trigger: `definition s :: seg` and a constant named `s.start.xpos`; `term "s.start.xpos"`.
- Rendering (`all.out:1815-1819`):
  ```
  ### "s.start.xpos" is read as the constant Texts_Warn.s.start.xpos :: nat
  ### It could also be read as field access:
  ###   point.xpos (start s) :: int
  ### Write that term to mean the field access, or CONST s.start.xpos to keep the constant without this warning.
  ```
  A chain with several readings (r10 parse suite, constants and records only, `pbox :: 'a box`,
  `step1/r10/results/parse/out/Warn_Tests_A.out:1099-1104`):
  ```
  "pbox.content.xpos" is read as the constant Warn_Tests_A.pbox.content.xpos :: nat
  It could also be read as field access:
    cpoint2.xpos (content pbox) :: nat
    point.xpos (content pbox) :: int
  Write one of these terms to mean the field access, or CONST pbox.content.xpos to keep the constant without this warning.
  ```
  (A chain branching at an inner segment, `ns.sz.ev`, is at `Warn_Tests_A.out:1092-1097`; its registrations
  are λ-terms, which the attribute no longer accepts.)
- Looks wrong: nothing beyond D2.

### D4. The warning option

- Where: `dot_field.ML:108`; read at `syntax_phases.ML:525-528`.
- Status: name **approved**, §1 item 14.
- Trigger: `declare [[dot_syntax_warning = false]]`, `term "config.timeout"`: no warning (`all.out:1821-1822`).
- Looks wrong: nothing.

---

## E. The parse-failure hint

### E1. `field_dots_hint`

- Where: `src/src/Pure/Syntax/syntax_phases.ML:443-450`, attached at `:467`.
- Status: **draft**, §1 item 27 and §6.6.
- Triggers and renderings (jEdit positions; `all.out:1825-1844`):
  - `term "∀(x::nat).x > 0"`
    ```
    *** Inner syntax error\<^here>
    *** at ". x > 0"
    *** With dot_syntax on, a dot directly after ")" and directly before a name is read as a field access, as in "(f x).xpos". This text has such a dot at\<^here>. If it belongs to a binder or another notation, write a blank after it, as in "\<lambda>(x, y). x".
    *** Failed to parse term
    ```
  - `term "λ(x, y).x"` and `term "∀x ∈ (A ∪ B).P x"`: the same, with `*** at ""` as the second line.
  - Two such dots, `term "(∀(x::nat).x > 0) ∧ (∃(y::nat).y = 0)"`: the same hint, `*** at ". x > 0 ) \<and> ( \<exists> ( y :: nat ) . y = 0 )"`, and
    one `at\<^here>`.
  - Batch positions, `term "∀(x::nat).x > 0"` (`all.out:1849-1853`):
    ```
    *** Inner syntax error (line 17 of "/home/xero/Current/MLML/ai-artifacts/dot_syntax_timing/step1-tests/texts/Texts_Hint.thy")
    *** at ". x > 0"
    *** With dot_syntax on, a dot directly after ")" and directly before a name is read as a field access, as in "(f x).xpos". This text has such a dot at (line 17 of "/home/xero/Current/MLML/ai-artifacts/dot_syntax_timing/step1-tests/texts/Texts_Hint.thy"). If it belongs to a binder or another notation, write a blank after it, as in "\<lambda>(x, y). x".
    *** Failed to parse term
    ```
  - With a blank after the dot the text is accepted (`∀x. 0 < x`, `all.out:1847-1848`); with the option off
    stock reads it (`all.out:1854`).
- Looks wrong: (1) the hint is one long line of three sentences, inserted between the syntax error and
  "Failed to parse term"; (2) with two dots on one line, the plain rendering shows one marker (Isabelle's
  `Position.here_list` drops equal texts; jEdit shows one ⌂ per dot); (3) the example `"\<lambda>(x, y). x"`
  shows the blank only after the dot, though §1 item 27 allows it before or after.

### E2. A text that parses as a field access and then has no field: no hint

- Where: A10's text; the hint is only attached to parse failures.
- Status: the text is A10's (**draft**); the absence of the hint is how the code is.
- Trigger (§1 item 27's own example of a changed reading): `term "{(x::nat).x > 0}"`
- Rendering (`all.out:1845-1846`):
  ```
  *** "(x).x" is not a field of x :: nat\<^here>
  ```
- Looks wrong: (1) the user wrote a set comprehension; the error does not explain the blank rule, although
  §1 item 27 says such errors "要附说明并指出该点的位置"; (2) the quoted text `"(x).x"` is not what was written
  (`(x::nat).x`).

---

## F. Registration errors and conflicts

Raised while the attribute's argument is parsed (`src/src/Pure/Syntax/dot_field_attrib.ML:13-26`), so they
appear at the `declare` command. Renderings are in `out/reg.out`; setup `step1/texts/Texts_RegSetup.thy`.

### F1. Not a constant

- Where: `dot_field.ML:553-555`.
- Status: **draft** — not named in §6.6's list (INVENTORY D.6 row 27 proposal).
- Triggers: `declare [[dot_field plus1 = "λx::nat. x + 1"]]`; `declare [[dot_field nosuch]]` (no such
  constant); `context fixes x :: "nat ⇒ nat" begin declare [[dot_field fx = x]] end`.
- Rendering (`reg.out:1408-1410`, `:1492-1494`, `:1504-1506`):
  ```
  *** The term of field "plus1" is not a constant; a field is registered with a constant or an abbreviation:
  ***   \<lambda>x::nat. x + 1
  *** At command "declare" (line 7 of ".../Texts_Reg_01.thy")
  ```
  ```
  *** The term of field "nosuch" is not a constant; a field is registered with a constant or an abbreviation:
  ***   nosuch
  ```
- Looks wrong: an undefined (e.g. misspelt) name gets "is not a constant", with no hint that the name is
  simply unknown; the text never says "undefined".

### F2. Bad field name

- Where: `dot_field.ML:560-561`.
- Status: **draft** — not named in §6.6 (INVENTORY D.6 row 27).
- Triggers: `declare [[dot_field a.b = length]]`; `declare [[dot_field "a b" = length]]`.
- Rendering (`reg.out:1414`, `:1419`):
  ```
  *** Bad field name "a.b": a field name is an identifier without dots
  ```
  ```
  *** Bad field name "a b": a field name is an identifier without dots
  ```
- Looks wrong: for `"a b"` the problem is not a dot; the explanation fits only the first case.

### F3. Not a function

- Where: `dot_field.ML:563-565` (with `:562`).
- Status: **draft** — not named in §6.6.
- Trigger: `declare [[dot_field zero = "0 :: nat"]]`
- Rendering (`reg.out:1424-1425`):
  ```
  *** The term of field "zero" is not a function; it must take the object as its first argument:
  ***   0 :: nat
  ```
- Looks wrong: nothing.

### F4. Contains schematic variables

- Where: `dot_field.ML:566-567`.
- Status: **draft** — not named in §6.6.
- Trigger: none through the attribute (a constant cannot contain one); only an ML caller of
  `Dot_Field.check_registration`. Rendering from tests/core CHECK 4b (`step1/r10/results/core/out/R10_Checks_Contexts.out:267-268`):
  ```
  The term of field "schem" contains schematic variables:
    (+) ?k :: nat \<Rightarrow> nat
  ```
- Looks wrong: unreachable for users.

### F5. Mentions variables that are not fixed

- Where: `dot_field.ML:568-571`.
- Status: **draft** — not named in §6.6.
- Trigger: none through the attribute; ML only (tests/core CHECK 3, `R10_Checks_Contexts.out:257-258`):
  ```
  The term of field "plusc" mentions variables that are not fixed here: c
    c :: nat \<Rightarrow> nat
  ```
- Looks wrong: unreachable for users.

### F6. Conflict: same pattern (error)

- Where: `dot_field.ML:608-611`; error/warning choice `:630-632`.
- Status: **draft**, §6.6 ("登记冲突的文案"); error-or-warning per §3.2's proposal (MERGE.md §3).
- Triggers: after `declare [[dot_field total = total_a]]`, `declare [[dot_field total = total_b]]`
  (both `nat list ⇒ nat`); and against an interpretation's copy (`interpretation a: foo 3` of a locale field
  `bar`), `declare [[dot_field bar = bar5]]`.
- Rendering (`reg.out:1430-1432`, `:1518-1520`):
  ```
  *** Field "total" cannot be registered: on every object of type nat list it would be ambiguous with
  ***   total_a :: nat list \<Rightarrow> nat
  *** Register it under another name, or remove the existing field with dot_field del.
  ```
  ```
  *** Field "bar" cannot be registered: on every object of type nat list it would be ambiguous with
  ***   a.bar :: nat list \<Rightarrow> nat
  *** Register it under another name, or remove the existing field with dot_field del.
  ```
- Looks wrong: (1) the new term (`total_b`) is not shown, while F7–F9 show it; (2) "dot_field del" is not
  the full syntax (`[[dot_field del total = total_a]]`); (3) no conflict text says where the existing field
  was registered.

### F7. Conflict: the new one could never be chosen (error)

- Where: `dot_field.ML:612-614`.
- Status: **draft**, §6.6.
- Trigger: after `declare [[dot_field sz = len_a]]` (`len_a :: 'a list ⇒ nat`), `declare [[dot_field sz = len_n]]`
  (`len_n :: nat list ⇒ nat`).
- Rendering (`reg.out:1437-1440`):
  ```
  *** Field "sz" of len_n :: nat list \<Rightarrow> nat could never be chosen:
  *** every object it fits also fits the existing field "sz"
  ***   len_a :: ?'a list \<Rightarrow> nat
  *** and "x.sz" would be ambiguous on these objects.
  ```
- Looks wrong: "Field "sz" of len_n" uses "of" for the registered term, while every text of group A uses
  "Field "xpos" of z" for the object.

### F8. Conflict: the existing one would become impossible to choose (error)

- Where: `dot_field.ML:615-617`.
- Status: **draft**, §6.6.
- Trigger: after `declare [[dot_field sz2 = len_n]]`, `declare [[dot_field sz2 = len_a]]`.
- Rendering (`reg.out:1445-1447`):
  ```
  *** Field "sz2" of len_a :: ?'a list \<Rightarrow> nat would make the existing field "sz2"
  ***   len_n :: nat list \<Rightarrow> nat
  *** impossible to choose: every object it fits also fits the new one.
  ```
- Looks wrong: as F7 ("of").

### F9. Conflict: overlap (warning)

- Where: `dot_field.ML:618-627`.
- Status: **draft**, §6.6.
- Trigger: `declare [[dot_field p = fl]]`, `declare [[dot_field p = fr]]` with `fl :: nat × 'a ⇒ nat`,
  `fr :: 'a × nat ⇒ nat`.
- Rendering (`reg.out:1404-1406`):
  ```
  ### Field "p" of fr :: ?'a \<times> nat \<Rightarrow> nat overlaps the existing field "p"
  ###   fl :: nat \<times> ?'a \<Rightarrow> nat
  ### "x.p" is ambiguous on objects of type nat \<times> nat.
  ```
- Looks wrong: as F7 ("of").

Silent, as designed (no text): registering the same term again, `[[dot_field del …]]` of a field that does
not exist, removing and re-adding (`Texts_RegSetup.thy`, no output); record registrations.

---

## G. The attribute's syntax errors

### G1. Malformed argument

- Where: `src/src/Pure/Syntax/dot_field_attrib.ML:33-44` (`malformed`), used at `:48`.
- Status: **draft**, §1 item 26 (3) and §6.11 "r8" (the draft wording), listed in §6.6.
- Triggers: `declare [[dot_field len =]]`; `declare [[dot_field "List.length"]]` (quoted name, rejected per the
  owner's 11-12 decision); `declare [[dot_field "length :: nat list ⇒ nat"]]`; also r8's
  `[[dot_field del "rev :: nat list ⇒ nat list"]]` and `[[dot_field List.length rev]]`.
- Rendering (`reg.out:1462-1467`):
  ```
  *** Malformed argument of dot_field (line 7 of ".../Texts_Reg_09.thy"): len =
  *** Write the name of a constant, whose last segment becomes the field name:
  ***   [[dot_field List.length]]
  *** or a field name, "=", and a constant, which may carry a type:
  ***   [[dot_field len = "length :: nat list \<Rightarrow> nat"]]
  *** "del" in front of either form removes the field instead.
  *** At command "declare" (line 7 of ".../Texts_Reg_09.thy")
  ```
  The first line for the other inputs (`reg.out:1472`, `:1482`; `step1/r8/attr_render/out/Attr_Render_2.out:246`,
  `Attr_Render_3.out:246`): `…: "List.length"`, `…: "length :: nat list \<Rightarrow> nat"`,
  `…: del "rev :: nat list \<Rightarrow> nat list"`, `…: List.length rev`. In jEdit the position is `\<^here>`.
- Looks wrong: a quoted name `"List.length"` is rejected, and the message does not say that the quotes are
  the problem; the example right below it has a quoted term (allowed after `=`), which makes the rejection
  harder to understand.

### G2. Missing argument

- Where: `dot_field_attrib.ML:36`.
- Status: **draft** (§6.11 "r8": "没有参数时是 `Missing argument of dot_field`").
- Trigger: `declare [[dot_field]]`
- Rendering (`reg.out:1452-1457`):
  ```
  *** Missing argument of dot_field
  *** Write the name of a constant, whose last segment becomes the field name:
  ***   [[dot_field List.length]]
  *** or a field name, "=", and a constant, which may carry a type:
  ***   [[dot_field len = "length :: nat list \<Rightarrow> nat"]]
  *** "del" in front of either form removes the field instead.
  ```
- Looks wrong: no position on the first line (G1 has one); only the toplevel's "At command" locates it.

### G3. The attribute's description

- Where: `dot_field_attrib.ML:62-63`.
- Status: **draft** — not named in §6.6.
- Trigger: `print_attributes` (`all.out:2206`):
  ```
    dot_field:  register a constant for field access x.f
  ```
- Looks wrong: nothing.

---

## H. Printing with `CONST`

### H1. A constant whose qualified name starts with a variable of the term or a fixed variable

- Where: `src/src/Pure/Syntax/syntax_phases.ML:890-911`.
- Status: **approved**, §1 item 16 (2026-11-01 final) and §1 item 25 (2) (only names with a dot).
- Renderings (r10 parse suite, the clean printer; `step1/r10/results/parse/Print_Tests.results:1-27`):
  `λb. b ∈ CONST b.E` (bound `b`), `CONST b.E ∪ {length [b]}` (fixed `b`), `CONST b.E ∪ {b}` (free `b`),
  `CONST C.arr + xpos C` (the locale idiom), `λE. E ∈ b.E` (no clash), with `names_long`
  `λList. List = CONST List.rev List`; option off: stock.
- Looks wrong: nothing.

### H2. `CONST` inside the rule's candidate lines

- Where: H1's code applied to the candidate lines of group A (`dot_field.ML:958-966`, `:1016`).
- Status: **draft**, §6.6 ("候选行里的常量遇到第 16 条的 CONST 打印时的样子").
- Triggers: `context fixes point :: cpoint2 begin  term "point.xpos"  end` (step 5);
  `context fixes point :: nat begin  term "λz. z.xpos"  end` (step 1).
- Rendering: the message as user space prints it (`all.out:1858-1863`), then the clean printer on the same
  candidate terms in the same context (`all.out:1864-1865`, `:1877-1879`):
  ```
  *** Ambiguous field "xpos" of point :: cpoint2\<^here>
  *** "point.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
  ***   cpoint2.xpos point :: nat
  ***   point.xpos point :: int
  *** Write one of these terms instead.
    candidate "cpoint2.xpos point": clean printer "cpoint2.xpos point", Pure's printer "cpoint2.xpos point"
    candidate "CONST point.xpos point": clean printer "CONST point.xpos point", Pure's printer "point.xpos point"
  ```
  ```
    candidate "CONST point.xpos": clean printer "CONST point.xpos", Pure's printer "point.xpos"
  ```
  So in step 2 the lines read `  CONST point.xpos point :: int` (step 5) and
  `  CONST point.xpos :: ?'z point_scheme \<Rightarrow> int` (step 1, because `point` is a fixed variable there).
- Looks wrong: the step-5 message would then say `"point.xpos" is not a constant` and, two lines below,
  offer `CONST point.xpos point` — contradictory (see A14).

---

## I. How undecided fields show in messages

All through the output-only syntax `_dot_access` (`src/src/Pure/pure_thy.ML:230`) and
`Dot_Field.access_tr'` (`dot_field.ML:767-786`, installed at `syntax_phases.ML:1029`).

### I1. `t.xpos` in stock's unification error (standard engine)

- Status: **draft**, §6.6 ("报错里未决定的字段显示为 `t.xpos`、`(mk y).xpos`").
- Trigger: `term "λt. t.xpos + (1::nat) = True"`
- Rendering (`all.out:1561-1568`):
  ```
  *** Type unification failed: Clash of types "bool" and "nat"
  *** 
  *** Type error in application: incompatible operand type
  *** 
  *** Operator:  (=) (t.xpos + 1) :: nat \<Rightarrow> bool
  *** Operand:   True :: bool
  *** 
  ```
- Looks wrong: nothing.

### I2. The bracket form: `(f y).xpos`, `(mk y).xpos`

- Status: **draft**, §6.6.
- Triggers: `term "(f y).xpos + (1::nat) = True"`; `term "(mk y).xpos + (1::nat) = True"` (D14 setup).
- Rendering (`all.out:1574`, `:1769`): `*** Operator:  (=) ((f y).xpos + 1) :: nat \<Rightarrow> bool`,
  `*** Operator:  (=) ((mk y).xpos + 1) :: nat \<Rightarrow> bool` (the rest as I1).
- Looks wrong: nothing.

### I3. A chain

- Status: **draft**, §6.6.
- Trigger: `term "λt. t.start.xpos + (1::nat) = True"` → `*** Operator:  (=) (t.start.xpos + 1) :: nat \<Rightarrow> bool`
  (`all.out:1582`).
- Looks wrong: a bracket chain prints in identifier form (`((s).start).xpos` prints as `s.start.xpos`,
  `step1/r10/results/parse/Paren_E2E.results:55`); a constant object prints by its printed name
  (`seg.start.xpos` prints as `start.xpos`, `:56`). Both are only messages, but the second is not what
  was written.

### I4. An eta-contracted object: `λt. t.xpos`

- Where: `dot_field.ML:781-783`.
- Status: **draft**, §6.6.
- Trigger: `term "(λt. t.xpos) = True"`
- Rendering (`all.out:1585-1593`):
  ```
  *** Type unification failed: Clash of types "bool" and "_ \<Rightarrow> _"
  *** 
  *** Type error in application: incompatible operand type
  *** 
  *** Operator:  (=) (\<lambda>t. t.xpos) ::
  ***   (??'a \<Rightarrow> ??'b) \<Rightarrow> bool
  *** Operand:   True :: bool
  *** 
  ```
- Looks wrong: nothing.

### I5. Coercions on: stock's coercion text with undecided fields

- Where: the coercion engine (`src/src/Tools/subtyping.ML:2311-2313`: a local pass that ends with a field
  still waiting goes to option b with the empty message `no_err`, `:1644`) and stock's global-failure text.
- Status: **draft**, §6.6 (same item as I1).
- Trigger: `term "λt. t.xpos + (1::nat) = True"`, coercions on.
- Rendering (`all.out:1594-1627`, first lines):
  ```
  *** 
  *** 
  *** Now trying to infer coercions globally.
  *** 
  *** Coercion inference failed:
  *** no supremum
  *** 
  *** Cannot fulfil subtype constraints:
  ***   ??'a \<Rightarrow> ??'a \<Rightarrow> bool  <:
  ...
  ***   ??'a  <:  ??'b   from function application  t.xpos + 1 = True
  ...
  ```
  Stock's text for the same shape with a plain function `g` (HOL's coercion check; `all.out:1662-1690`):
  ```
  *** Type unification failed: Clash of types "bool" and "nat"
  *** 
  *** Type error in application: incompatible operand type
  *** 
  *** Operator:  (=) (g t + 1) :: nat \<Rightarrow> bool
  *** Operand:   True :: bool
  *** 
  *** Coercion Inference:
  *** 
  *** Local coercion insertion on the operand failed:
  *** "bool" is not a subtype of "nat"
  *** 
  *** Now trying to infer coercions globally.
  ...
  ```
- Looks wrong: the message starts with two empty lines and "Now trying to infer coercions globally." —
  the local part that stock always puts first ("Type unification failed …", "Coercion Inference:") is
  missing, because the field was still waiting when the local pass ended. The constraint list also has
  identical lines repeated (the `(=)` and the `(+)` constraint three times each).

---

## J. Front-end markup

### J1. The field segment's markup

- Where: `syntax_phases.ML:1116-1132` (`field_reports`), `dot_field.ML:909-912` (`head_constant`).
- Status: **approved** — §1 item 16 (field-segment hover and jump), §1 item 1 (2026-11-02 re-revision:
  the head constant after folding abbreviations), §1 item 24 (reported wherever stock reports).
- Text: none. It is entity markup (hover shows the constant, ctrl-click jumps to it), no type hint.
  Measured in the r10 parse suite: `step1/r10/results/parse/Field_Markup.results:1-33` (e.g. `xs.length`
  marks `List.length`, `s.start.xpos` marks `seg.start` and `point.xpos`, a rejected term marks nothing).
- Looks wrong: nothing.

### J2. Position markup in texts

- The `\<^here>` of every term-level text (A19) and of the hint (E1) is a link in jEdit; the warning's quoted
  identifier carries position markup without visible text (D1). No other text.

---

## K. Names a user can see

### K1. The options `dot_syntax`, `dot_syntax_warning`

- Where: `dot_field.ML:107-108` (declared; step 2 registers them in `attrib.ML`, not in `step1/src`).
- Status: **approved**, §1 item 14.
- Rendering: `print_options` (`all.out:1910-1911`) `  dot_syntax: bool = true` / `  dot_syntax_warning: bool = true`
  (true here because the probe theory turned it on; the default is false); `print_attributes`
  (`all.out:2207-2208`) `  dot_syntax:  configuration option`.
- Looks wrong: nothing.

### K2. The attribute `dot_field` and its `del`

- Where: `dot_field_attrib.ML:62`, `:51-52`.
- Status: **approved**, §6.6 ("删除登记的写法已定为 `[[dot_field del …]]`，attribute 名 `dot_field` 已定"), §1 item 20.

### K3. `_dot_field`

- Where: `src/src/Pure/pure_thy.ML:232-235` (two input-only productions); `syntax_phases.ML:264`.
- Status: **draft**, §6.6.
- Visible in `print_syntax` (productions; rendered here by the same `Parser.pretty_gram` on the parse suite's
  grammar, `all.out:4652-4657`):
  ```
    logic\<^sup>(\<^sup>1\<^sup>0\<^sup>0\<^sup>0\<^sup>) =
    logic\<^sup>(\<^sup>1\<^sup>0\<^sup>0\<^sup>0\<^sup>) field_dot
    longid_position\<^sup>(\<^sup>0\<^sup>) \<^bold>\<Rightarrow> "_dot_field"
  ```
  (and the same with `id_position`), i.e. in jEdit `logic⁽¹⁰⁰⁰⁾ = logic⁽¹⁰⁰⁰⁾ field_dot longid_position⁽⁰⁾ ⇒ "_dot_field"`.
  In parse trees of an ambiguous input, with two notations `AMB _` (`all.out:4663-4673`):
  ```
  *** Ambiguous input\<^here> produces 2 parse trees:
  *** ("\<^const>Texts_Names.amb1"
  ***   ("_dot_field" ("_position" p) ("_position" xpos)))
  *** ("\<^const>Texts_Names.amb2"
  ***   ("_dot_field" ("_position" p) ("_position" xpos)))
  *** Ambiguous input
  *** 2 terms are type correct:
  *** amb1 (p::<position>).xpos
  *** amb2 (p::<position>).xpos
  *** Failed to parse term
  ```
  (The identifier form shows `("_position" p.xpos)` in the tree; `(p::<position>)` is stock's way of printing
  these terms — the same input without dot syntax prints `amb1 (point.xpos (p::<position>))`.) User space
  cannot add the productions to Pure's syntax, so the real `print_syntax` here does not list them.
- Looks wrong: nothing.

### K4. `field_dot`

- Where: `src/src/Pure/Syntax/lexicon.ML:223` (token kind name), `pure_thy.ML:232,234`.
- Status: **draft**, §6.6.
- Visible as the terminal in the `print_syntax` productions of K3; usable as a nonterminal type in `syntax`
  declarations. Not shown in parse trees.
- Looks wrong: nothing.

### K5. `_dot_access`

- Where: `pure_thy.ML:230` (output only).
- Status: **draft**, §6.6.
- Visible in `print_syntax` among the syntax constants (`all.out:4192`, `… "_context_xconst" "_dot_access"`)
  and, as `"\<^const>Pure.dot_access"`, among the print translations (`all.out:4449`); its effect is group I.
- Looks wrong: nothing.

### K6. `_dot_ident`

- Where: `src/src/Pure/Syntax/term_position.ML:104`; built at `dot_field.ML:313-315`.
- Status: **draft**, §6.6.
- Visible to a parse translation (or a raw parse) as the position slot of a long identifier
  (`all.out:4714`, the term a translation receives for `s.start.xpos`):
  ```
  _constrain $ Free ("s.start.xpos") $ (_dot_ident $ Free "s" $ Free <position> $ Var (("s.start.xpos", 0)))
  ```
  (abridged from `ML_Syntax.print_term`). Not in `print_syntax`, not in parse trees.
- Looks wrong: nothing.

### K7. The carrier constant `Pure.dot_access` and its payload text

- Where: `pure_thy.ML:243-244` (concealed constant); payload format `dot_field.ML:125-168`.
- Status: **draft** — not named in §6.6 (INVENTORY D.9).
- Visible in a parsed, unchecked term printed raw (`all.out:4718`, abridged):
  `Pure.dot_access $ ?"dot_field index=2 field=xpos name=s.start.xpos" $ (Pure.dot_access $ ?"dot_field index=1 field=start name=s.start.xpos" $ s)`
  (with jEdit positions the payload also has `offset=… end_offset=… id=…`). Printed through the printer it
  is `(s::<position>).start.xpos` (`all.out:4719`).
- Looks wrong: nothing; visible only to ML code.

### K8. Internal names

- `dot_check` (the stage-1 check, `syntax_phases.ML:1204`; visible only through
  `Syntax_Phases.print_checks` from ML); the stage-1 marker name `dot_last_check …` (`dot_field.ML:1146`);
  the node parameter `dot_token` (`dot_field.ML:1071`). Status: not in §6.6; never shown to users in any run.

---

## L. Internal failures (must stay unreachable)

`Fail` / `TERM` messages that only a bug can show: `Dot_Field.decode_payload`, `Dot_Field.rebuild_payload`,
`Dot_Field.carrier_object_type`, `Dot_Field.rebuild_node` (`dot_field.ML:152,157,226,248,295`),
`Dot_Field.field_error_msg` (`:1026`), `Dot_Field.dest_marker` (`:1166`), `Dot_Field.learn: nested`
(`:1259`); in `subtyping.ML`: `Subtyping.rerun: deferred choices` (`:1089`), `Subtyping: an object type was not
recorded` (`:1713`), `Subtyping.learn: no decision after solving` (`:2275`). None appeared in any r10 run or
probe. Not for review; listed so the inventory is complete.

---

## Index

| id | group | status | gist |
|---|---|---|---|
| A1 | field selection | approved (§1.7) | step 5, identifier form |
| A2 | field selection | draft | step 5, bracket form without "is not a constant" |
| A3 | field selection | approved (§1.7) | step 6, identifier form |
| A4 | field selection | draft | step 6, bracket form |
| A5 | field selection | approved (§1.7) | step 1 with "Fields named … exist for" |
| A6 | field selection | draft | step 1, empty list line left out |
| A7 | field selection | draft | step 1, bracket form |
| A8 | field selection | approved (§1.7) | step 3 with "Fields of" |
| A9 | field selection | draft | step 3, empty "Fields of" left out |
| A10 | field selection | draft | step 3, bracket form "is not a field of" |
| A11 | field selection | draft | chained objects shown as written |
| A12 | field selection | draft | written prefix is a constant: CONST, `for`/`fixes` |
| A13 | field selection | draft / approved | constant prefix of unknown type |
| A14 | field selection | missing | local first segment, whole identifier a constant: §1.16 text not implemented |
| A15 | field selection | approved bound (§1.19); form draft | five items and `\<dots>` |
| A16 | field selection | draft | candidates sorted by printed name |
| A17 | field selection | approved (§1.15) | misspelt qualified constant |
| A18 | field selection | approved (§6.6) | stock text on E(C) when all fields decided |
| A19 | field selection | draft | position marker; none in batch logs |
| A20 | field selection | approved (§1.7, §1.18) | D14 learns nothing: step 1 |
| A21 | field selection | draft | D14 errors after stage 0 (object shown after beta) |
| A22 | field selection | approved (§1.7) | field dropped by beta normalisation |
| B1 | last check | draft | "chose … but the object's final type … selects …" |
| B2 | last check | draft (unreachable) | "… no longer selects …" |
| B3 | last check | draft | "the choice … is not confirmed …" + rule text |
| C1 | stage-1 fallback | draft | "… was not resolved (internal error)", only via a foreign pre-stage-0 inference |
| D1 | warnings | approved (§1.8) | one reading |
| D2 | warnings | draft | several readings |
| D3 | warnings | draft | chains |
| D4 | warnings | approved (§1.14) | option `dot_syntax_warning` |
| E1 | parse hint | draft | `field_dots_hint` |
| E2 | parse hint | draft (A10's text) | `{(x::nat).x > 0}`: field error, no hint |
| F1 | registration | draft (not in §6.6) | not a constant |
| F2 | registration | draft (not in §6.6) | bad field name |
| F3 | registration | draft (not in §6.6) | not a function |
| F4 | registration | draft (not in §6.6; ML only) | schematic variables |
| F5 | registration | draft (not in §6.6; ML only) | variables not fixed |
| F6 | registration | draft | conflict: same pattern (error) |
| F7 | registration | draft | conflict: new one never chosen (error) |
| F8 | registration | draft | conflict: existing one never chosen (error) |
| F9 | registration | draft | conflict: overlap (warning) |
| G1 | attribute syntax | draft | "Malformed argument of dot_field" |
| G2 | attribute syntax | draft | "Missing argument of dot_field" |
| G3 | attribute syntax | draft (not in §6.6) | attribute description |
| H1 | CONST printing | approved (§1.16, §1.25) | `CONST` on clashing qualified names |
| H2 | CONST printing | draft | `CONST` in candidate lines |
| I1 | undecided fields | draft | `t.xpos` in stock's error |
| I2 | undecided fields | draft | `(f y).xpos`, `(mk y).xpos` |
| I3 | undecided fields | draft | chains; constant objects by printed name |
| I4 | undecided fields | draft | `λt. t.xpos` after eta contraction |
| I5 | undecided fields | draft | coercions on: text starts with blank lines |
| J1 | front-end markup | approved (§1.1, §1.16, §1.24) | field segment entity markup, no text |
| J2 | front-end markup | — | position markup only |
| K1 | names | approved (§1.14) | `dot_syntax`, `dot_syntax_warning` |
| K2 | names | approved (§6.6, §1.20) | attribute `dot_field`, `del` |
| K3 | names | draft | `_dot_field` |
| K4 | names | draft | `field_dot` |
| K5 | names | draft | `_dot_access` |
| K6 | names | draft | `_dot_ident` |
| K7 | names | draft (not in §6.6) | `Pure.dot_access`, payload text |
| K8 | names | not in §6.6 | `dot_check`, `dot_last_check`, `dot_token` |
| L | internal | — | Fail/TERM messages, unreachable |
