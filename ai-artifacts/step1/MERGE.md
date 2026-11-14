# 第一步子步骤 4：合成的设计（2026-11-03 起草）

**这是什么**：把分开做的参考原型合成一份干净代码时的实现决定。设计以 `DOT_SYNTAX_PLAN.md` §6 为准；这里只定 §6 留给第一步的、不改变设计的
实现细节（用户 2026-11-03："具体实现上的，在不改变设计的前提下，你可以自决"）。改变设计的仍先问用户。事实来源是 `MERGE_INVENTORY.md`（只读清点，
文中记作 INV，后接节号）。下文行号凡标 S 的都是 Isabelle2026 原版（`worktrees/Isabelle2026-dot_syntax-stock`）。

## 1. 代码在哪、怎么测

- 干净代码在 `step1/src/`，路径同 Isabelle 树（`src/Pure/...`、`src/Tools/...`、`src/HOL/...`），就是第二步放进私有树的字节。（2026-11-03 起草时已有：
  `lexicon.ML`、`parser.ML`（Earley functor）、`src/Tools/subtyping.ML`（functor 骨架与钩子）。现状 2026-11-11：全部写完，`step1/src/` 是 r8；解析器的
  functor 已去掉，只解析一次，计划 §1 第 27 条、6.3.2。）
- 构建由 `derive/derive.py` 派生（`edits.py` 的 CHANGED_FILES、NEW_FILES、LOAD、USERSPACE、OBSERVE、MUTANTS）。每写完一个部件就补它的条目、派生、在 cslh19
  上用户空间装载并跑该部件的参考测试（`step1/ref/<部件>/`），与 `reference.tsv` 逐例比，差别只能是 6.12 G1 的允许差别。
- 资源规则：cslh19，`ML_process`，`nice -n 10`，起进程前查 `pgrep -a '[z]3|[c]vc5|[v]eriT'` 为空。正确性测试在别人构建期间也可以跑（用户 11-03
  "赞同"）：CPU 0–7、10、11、14–23，每个 agent 至多两个进程，不看负载上限。计时只在没有构建时跑：CPU 8、9、12、13，持 `TIMING.lock`，起跑前与拿到锁后
  各查一次 `pgrep -af '[I]sabelle_Tool build|[i]sabelle build'` 为空（11-03 的教训：构建在 JVM 命令行里是 `isabelle.Isabelle_Tool build`）。

## 2. 文件与读入顺序（INV A；§6.10）

| 文件 | 内容 | 读入位置与限制 |
|---|---|---|
| `src/Pure/pure_thy.ML` | 载体常量 `Pure.dot_access`；`_dot_field` 两条只用于输入的产生式与终结符 `field_dot`；只用于输出的 `_dot_access` | ROOT.ML:193，在 dot_field.ML 之前 |
| `src/Pure/Syntax/dot_field.ML`（新） | 开关、载荷与载体、标识符标记的辅助、登记表、选择规则与文案、最后检查、第 1 级检查、D14 学习运行与守卫、选择的回传与字段标记、打印辅助、警告 | `Isar/proof_context.ML`（S ROOT.ML:236）之后、`type_infer_context.ML`（:237）之前；只能用 `\<^here>` 与 `@{make_string}`；看不到 `Type_Infer_Context`、`Syntax_Phases`、`Args`、`Attrib`、`Local_Theory`、HOL |
| `src/Pure/Syntax/term_position.ML` | 三个读位置的函数认 `_dot_ident`（名字 `Term_Position.dot_identN`） | 原位 |
| `src/Pure/Syntax/syntax.ML` | `parse` 多一个参数 `{field_dots: bool}`（签名一行；2026-11-10 起，原先的 `parse_field_dots` 去掉） | 原位 |
| `src/Pure/Syntax/syntax_phases.ML` | `ast_to_term` 两处、`decode_ident`、警告通道、开关打开时标 `field_dot` 并解析一次与失败时的说明（`field_dots_hint`）、`check` 交回上下文、`check_terms` 出口报告、`pretty_entity_cache` 的 `CONST`、导出 `simple_check`；第 0 级 `"standard"` 改 `term_check'`（r8 起没有 `decode_free`，原版 `decode` 的 Free 分支原样） | 原位 |
| `src/Pure/Syntax/lexicon.ML`、`parser.ML` | `field_dot` token 与 `field_access_dots`；`Parser.parse` 多一个参数 `{field_dots: bool}`，左递归的 `field_dot` 产生式单独存放、只在后面还有 `field_dot` 时预测（计划 6.3.2） | 原位 |
| `src/Pure/type_infer_context.ML` | `prepare_positions` 的 `Var` 分支重建载荷；标准引擎（`standard_check`） | 原位 |
| `src/Pure/Isar/proof_context.ML` | 签名导出 `is_const_declared` | 原位 |
| `src/Pure/Isar/attrib.ML` | 登记两个开关（紧挨 `Syntax.ambiguity_warning`） | 原位 |
| `src/Pure/Syntax/dot_field_attrib.ML`（新） | `dot_field` attribute（`Args.embedded_declaration` + `Scan.state`）；参数只收标识符或长标识符（简写）与 `f = c`，前面可加 `del`，写错时报自定文案（r8，计划 §1 第 26 条 (3)） | `Isar/attrib.ML` 之后 |
| `src/Pure/ROOT.ML` | 读入上面两个新文件 | — |
| `src/Tools/subtyping.ML` | functor 三实例 + ESR 部分；coercion 检查改 `term_check'` | 原位 |
| `src/HOL/Tools/record.ML` | `put_record` 之后登记字段（localized_record 进 base 后改到 `local_add_record` 末尾，6.4） | 原位 |

## 3. `Dot_Field` 的统一接口（INV B 的同名冲突，逐项定）

名字凡 §6 已给的（`ident_marker`、`is_ident_token`、`accesses`、`has_access`、`unifier`、`candidates`、`declaration`、`defined`、`LEARNT`、`learn`）照用；
其余取原型的名字，冲突时如下定：

- **开关**：`dot_syntax`、`dot_syntax_warning`，`Config.declare_bool`（attrib.ML 里 `Attrib.register_config_bool`）。去掉原型的 `dot_constant_warning`、
  `dot_warning_rule`、`dot_registry_*`、`dot_singleton`、`DOT_PAYLOAD`、`strict_head`、`esr_engine`（INV B.1）。
- **载荷**：用解析原型的文本格式（`dot_field name=… index=… [paren=true] <位置属性>`，PD:77-98），记录类型加一项 `serial: int`（解析时 0）。
  `check_terms` 入口的重建（`prepare_positions`）给它 `serial ()` 并写进 Free 的名字（`serial=…`）。§6.3.3 例子里的 `id=1` 是位置的 id，不是 serial
  （INV 0.2）。前缀测试 `String.isPrefix "dot_field "`。
- **载体**：`access_const = "Pure.dot_access"`。原始形式的拆解叫 `dest_carrier : term -> (payload * term) option`（Var 或 Free 载荷都认）；
  检查期带类型的拆解叫 `dest_access : term -> access option`，`type access = {key, payload, objT, resT, node, obj}`（比 RB 多 `payload`，
  标记与文案要用；r8 去掉了 `field`，字段名一律 `field_name payload`）。§6.3.1 的 `accesses`（给各段套载体）保留这个名字；RB 收集一批载体的那个函数
  改名 `collect_accesses`（INV 0.1；r8 起与其余遍历载体的地方都建在 `Dot_Field.fold_carriers` 上）。
- **决定**：`datatype decision = Choose of term | Wait | Empty | Ambiguous of term list`（携带登记的 term；r8 起 `Wait` 不带列表，报错时由 `candidates`
  现算）。`decide` 经 `candidates` 取 U（§6.4："选择、所有报错、警告、冲突检测都从 `Dot_Field.candidates` 取 U"），引擎传入已按自己的 typing 解引用的对象
  类型与 `{rigid = not o Type_Infer.is_param}`；"可合一"与"匹配"同一函数换刚性集合。之后引擎照旧用自己的合一把对象类型细化。顺序照 §1 第 3 条：
  先看类型变量，再看 U 空（INV 0.8；r8 起先测类型变量，之后才算 U）。
- **文案**：错误文案只接收已由调用方的 `prep_output` 处理过的类型，所以 Dot_Field 不复制 `prep_output`（各引擎用自己的那份，含 2026 的 `Name.clean`）。
  五条上限与省略号、空列表时省去那一行（"Fields of …" 与 "Fields named … exist for:" 都省）、括号形式省去 `"c.xpos" is not a constant` 半句、写出的前缀
  是常量时的变体，都在这次补上；措辞全部列入 6.6 的文案过目。候选行按全名排序，截到前 5 条。
- **最后检查**：`last_check`（RB:328-351；r8 起是每个字段一次的 `last_check_field` 加一个 fold，`check_markers` 直接调前者）。标准引擎也以最后检查结束（§6.5.2 原文；原型没做，INV 0.5）；按单调性论证不应改变判定，G1 若有差别就查。
- **第 1 级检查**：学习运行中含载体的批次抛 `LEARNT`；对 D14 标记做最后检查并删去标记；报告留下的载体（兜底文案 `Field access "t.xpos" was not
  resolved (internal error)`）。标记里的选择不再用登记表下标（TIR:580，有遮蔽与包含后会错），而从选择回传的表按 serial 取（见下）。
- **D14**：学习标志是一个 `Proof_Data`；`learn` 取 `prepare: Proof.context -> Proof.context` 参数，HOL 传 `Config.put Subtyping.coercion_enabled false`
  （Pure 看不到 HOL 的开关，INV 0.3）；学到的对象类型记在该次 `learn` 调用自己的局部表里，运行以 `LEARNT`、`ERROR`、正常返回三种方式结束时都读
  （同参考 `hrtl`）。守卫照原型的读法：不算载体、不算 `Pure.type`（含 `check_terms` 追加的 `TYPE` 项）、不算以 `_` 开头的内部常量（如
  `_type_constraint_`）——这是 §6.5.3"常量"的确切读法。可选的 `raise Fail` 做上（见到已带学习标志时）。r8 起 `Dot_Field.learn` 两个引擎共用一份
  （两个引擎各自那份 fold 去掉）；r9 起它取这一批的 `accs` 与这一批 term，返回批里留下的载体的 key ↦ 学到的 term（r8 还取已决定的表，那道过滤从不起作用，再评审后删去）。
- **选择的回传与字段标记**：一个 `Proof_Data`，serial ↦ 所选登记的 term；r8 起唯一的写入者是 `Dot_Field.selection_check`（两个检查都经它：引擎
  返回这一批、它的 access 与 key ↦ 选择，私有的 `record_selections` 一次把 key 换成载荷 serial 写入；此前写入者是 coercion 引擎的出口函数与标准引擎的返回，
  学到的字段也由引擎写，11-03 改：第 1 级的标记检查按 serial 读它，自己不写）；读者是 `check_terms` 出口，只报告本批次载荷的 serial（嵌套的 `check_terms` 不重复报告）。头部常量：`Envir.eta_contract (Proof_Context.contract_abbrevs ctxt t)` 取 `head_of`，是 `Const` 才报，标记用
  syntax_phases 的 `markup_const`，位置用载荷算出的字段段位置。
- **登记表**：R 的结构（`Item_Net`、`term_instance` 关系、`subsume`）加上 §6.4 补的两条：copy 的细化（不含 schematic term 变量，且每个 Free 在接收它的
  context 里都是固定变量）与第八轮的遮蔽规则（与被遮住的 theory 副本相同的 theory 副本也遮住）。`defined` 只看可见的登记。读法：
  `Syntax.parse_term` 后去掉位置与类型约束，必须是 `Const`（含缩写；`c :: T` 也算常量），再 `check_term` 加 `Variable.polymorphic`，只读一遍（位置
  只报告一次）。简写 `[[dot_field c]]` 的字段名取所写文本的最后一段（§6.4 原文）。删除写法 `[[dot_field del f = c]]`、`[[dot_field del c]]`（`Args.del`；已定）。
  r8 起参数在 attribute 解析时只收两种写法（简写的 `c` 是标识符或长标识符 token，`f = c` 的 `c` 可带类型），其余报自定文案（计划 §1 第 26 条 (3)，文案列入 6.6 过目）。
  冲突：按同一关系分类并报告（错误还是警告列入文案过目，先按登记设计 §7.1 的提议）。

## 4. INV D 列出的其余选择

| 项 | 定为 |
|---|---|
| "是常量"的测试（§6.3.1） | 导出 `Proof_Context.is_const_declared`（签名一行），加 `Variable.lookup_const`（r8：`Dot_Field.is_const_name`）；不抛异常的 `decode_free` 曾做过，代码评审后删去（r8），第 4 行用 `is_const_name` 加 `Proof_Context.lookup_free`，读法交原版 `decode` 的 Free 分支 |
| 导出的 `decode_term`（Simpl 直接调用） | 不读开关：标记只在 `ast_to_term` 见到开关打开时才有，`(e).f` 只在开关打开时才标出 `field_dot`，所以有标记即开着；这条路上不发警告。测试：V_Attack 的 `_INFER`（C07） |
| `parse_trrule` | 与 `parse_typ`、`parse_sort` 一样当关闭（翻译规则只在 AST 层，载体只在 term 层） |
| 括号形式的解析 | 原为"第二次解析：只在开关打开、第一次解析失败、且 `Lexicon.field_access_dots` 找到点时才跑"（原型没有开关这一道，INV 0.13）。2026-11-10 起只解析一次：开关打开且 `field_access_dots` 找到点时，用 `{field_dots = true}` 解析，失败时附说明；否则原版解析（计划 §1 第 27 条、6.3.2） |
| 警告 | 在 `decode_ident` 第 4 行读成常量时计算（§6.3.1），对象按 §6.6（最长的、本身是常量的真前缀）；用警告原型的读法计算与去重。原型测试里按旧对象规则的那批（INV D.2 13 所列）作为 G1 的允许差别"警告对象规则按 §6.6" |
| `CONST` 打印 | `pretty_entity_cache` 里用局部的 `exclude_consts` 加 `Dot_Field.is_fixed`，只对常量；打印器每次 unparse 读一次开关 |
| `check` 交回上下文 | 改 `check` 返回 `perhaps` 本来的 `(xs, ctxt)`，其余 `apply_*` 取第一项；`check_terms` 直接调 `check snd false`，`apply_term_check` 不再有人用，去掉（11-04 改） |
| 用户空间的替身阶段号 | 载荷重建注册在第 −200 级；出口报告注册在第 200 级（高于 HOL-Library `rewrite.ML:90` 的 101），返回 `NONE`（`perhaps_loop` 遇 `SOME` 会再跑） |
| 歧义输入的报告次数 | 同原版的类型报告：每棵通过检查的树各报一次；第二步的"恰一次"测试改为"每个被接受的读法恰一次" |
| coercion 骨架 | 加一个在已准备好的输入上推断、返回 typing 的入口（原版 `coercion_infer_types` 拆成 prepare + 它 + finish）；`carrier` 钩子拿到 `app`、`err`；`tolerate` 按两个调用处拆成两个钩子（弱合一失败、不同构造子）；把原版 local pass 的冲突路径（S:821-855）提成 functor 里的一个函数，原版 `inf` 与 ESR 自己的 local pass 都调它（不复制 P:2586-2647）。改完重测无钩子实例。（代码评审后，fix_rev1a：钩子记录由 `Subtyping_Base` 的 `observe_hooks`、`learning_hooks` 造；ESR 的预测提到顶层 `dot_predictions`） |
| D6 的 spine 读法 | 只在 ESR 自己的遍历里。原为"原版 `update_coerce_arg` 不动"；代码评审后（计划 §1 第 26 条 (2)，用户定 B）原版函数拆出 `coerce_arg ctxt old (f, n)`，原版只剩取头部与参数个数再调用它，D6 只留读脊的几行、同样调用它（§6.5） |
| 废代码 | 去掉 P 里 option b 的 `learn` 恒为 `NONE` 的第二分量、`explicit_result_f` 的参数 |
| D15 求解前的确切条件 | 对象类型（经 `tye0`）里的类型参数出现在任何一条待解子类型约束里（含两边都是参数的约束；P 的 `tied` 漏了这类，P:2913）就等；节点上决定时遇到同样情形也等 |
| `dot_object_own_type`、I1a、I1b 测试开关、D15 失去的接受数、带类型标注的 binder | 照 §6 在观察构建里测，报用户 |
| `print_checks` 的第二步测试 | 每一级是新的在前，所以 dot 检查在第 1 级那一行显示在最后、运行在最先（INV 0.7）；计划那句改正 |

## 5. 写作顺序（INV E）

每步写完即在用户空间测：
1. `dot_field.ML` 第一部分（开关、载荷、载体、标识符标记、`is_fixed`、"是常量"）与 `term_position.ML`。测：`Dot_Parse_User` 的 C、G 两节。
2. 登记表、attribute 文件、record 钩子的替身。测：P01–P11 改成只写常量，加 6.12"另加"里的 locale 例子。
3. 选择规则、文案、最后检查（经 `candidates`）。测：R 式的选择探针与 P11。
4. `syntax_phases.ML` 的解析一侧与 `pure_thy`、`syntax.ML` 的部分。测：V_JAll、V_Fixed、V_DProto、V_Attack、V_Sanity（补名为第二段的登记）、
   `parser_battery.ML`；补一个经 syntax_phases 副本的 `(e).f` 端到端探针（HOL 的产生式加 `_dot_field`，同 `probes/first_parse/` 的取法）。
5. 警告。测：Warn_Tests_A/B（按 §6.6 调整后的期望）。
6. `type_infer_context.ML`：重建与标准引擎。测：engine6、engine3 的 coercion 关闭列表；观察构建上的 G2 (b)。
7. Pure 的 D14 与第 1 级检查。测：coercion 关闭的 D14 列表；`St0_CloseForm` 第 24 行。
8. 选择的回传、`check` 交回上下文、出口报告、`term_check'` 注册、`simple_check` 导出。测：`probes/markup_fold/` 的例子。
9. coercion 引擎的 ESR 部分。测：engine6、engine3 的 coercion 打开列表；G2 (a)、(c)、(d)。
10. `CONST` 打印。测：直接调用、V_Attack E01–E03 的读回。
11. attrib.ML、ROOT.ML、record.ML 的那几行（用户空间没有作用，第二步实测）。

用户空间的替身（6.12 那张表之外）：开关由 setup 登记；载体常量写在测试 theory 里；`is_const_declared`、`simple_check` 在副本里另写；HOL 里调
`Term_Position` 的翻译编译在补过的副本上；coercion 副本另有自己的开关（`edits.py` 的 `subtyping-no-check` 让副本借 HOL 的开关，学习运行关不掉它，
INV 0.12）；副本里 `ML_check_strings` 的 legacy 警告不管（Pure 的引导文件不受它影响）。

## 6. 由此要改计划的地方

- 6.12 G1 的允许差别补"警告对象规则按 §6.6"一项（列出受影响的测试）。
- 6.12 第二步那句 `print_checks` 的测试改正；"报告恰一次"改为"每个被接受的读法恰一次"。
- §6.3.2"`syntax.ML` 一行"改为两行（2026-11-10 去掉 `parse_field_dots` 后又是一行：`parse` 的类型）；§0 与 6.6、6.2 里几处 2025-2 行号（INV 0.11 的表）。
