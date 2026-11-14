# Dot 语法（`x.f`）设计文档

状态：第一版设计已成文（§6，2026-11-02 按用户全部决定改写）；第五轮聚焦评审、第六轮 D14 设计、第七轮深度复审（2026-11-02）已完成。深度复审裁定
有条件可开工。须由用户定的 8 项（2.1–2.8）用户已于 11-02 全部答复，已写进 §1、§6。深度复审交给我改的各项，11-02 向用户逐条讲了修法，用户答
"既然不需要跟我讨论的话我不予置评"，我按 §1 第 16、24 条的授权定下并手工改完；第八轮短评审（11-02）的 8 条也已处理（用户对其中要知情的一条答复后
定了前端标记的做法，其余用户"不需要跟我讨论的我不予置评"）。2026-11-03 通读全文、改正了不一致。**第一步已开始（11-03）：子步骤 1（参考原型移到 2026、AFP 扫描、
派生脚本框架）已完成**，结果见 §6.11 最末"第一步子步骤 1 的结果"；用户 11-03 授权不改变设计的实现细节由我定（functor 切法因此定下），G1 补的两项允许差别交 Opus agent
核查（同处，结论"不需要用户"，已按它收窄 G1）。子步骤 3（第一次解析的 Earley functor、coercion 引擎 functor 的无钩子实例）已测完，都在波动范围内
（§6.11 末）。子步骤 2 的参考表已写（`step1/REFERENCE_TABLE.md`）；子步骤 4 的 11 步代码都已写成并在用户空间测过
（`step1/src/`，各步结果见 §6.11 末；用户 11-04 定 D15 的 (B) 与 `coercion_args` 代价，(B) 已并入）。**2026-11-05 的位置**：G1–G5、G7 已过；G6 第一轮四组
都测完，查出的载荷平方增长等已修、并入（r6），第二轮在最终代码上解析与 coercion 两组已测完、标准引擎与局部变量优先两组在跑（`make_gram` 多 2–4% 用户
接受为例外，6.8）；I1a 按规则保留。G6 第二轮四组都已收齐。用户 11-09 对七项决定"全部按你建议来"（§1 第 25 条），已改完并重跑（r7，`step1/src/` 现为 r7）。
代码评审第一轮已做（§1 第 26 条，`step1/review1/`），用户 11-10 又定括号形式改为一次解析（§1 第 27 条）。
**2026-11-14 的位置（压缩后从这里接着做：先读 `ai-artifacts/STEP1_OPEN_QUESTIONS.md`，那里是正在讨论的思路与待用户回答的全部问题；
各步的细节在 §6.11 末按日期记的各条）：**
- **已做完：** 括号形式改为一次解析并去掉解析器 functor（§1 第 27 条）；三份草稿并入与跨文件评审项、attribute 只收两种写法（r8）；两处大重构的
  再评审与六条修改、送回复查通过（r9）；删去一个走不到的分支（r10）。`step1/src/` 现为 r10，各版源码备份 `step1/src_r7/`、`src_r8/`、`src_r9/`。
  手改文档（6.3–6.12 与 MERGE.md）；第三轮 G6 在 r10 上跑完，不通过的行按 §1 第 28 条全部接受。
- **进行中：** 一次性文案过目（`step1/texts/TEXTS_REVIEW.md`，62 条、附真实渲染；已定的记在 §1 第 29 条），以及由它引出的设计讨论：record 的
  同名字段是否改为"子 record 的赢"（用户 11-14 赞同改回来，具体做法待定）。
- **之后：** 按用户的决定派一个 agent 一次改完文案与 record 规则、全部重跑（r11）、重新渲染给用户看，record 规则按 CLAUDE.md 的流程评审；然后问用户
  第二步何时开始（建议 light_locale push 后）。
过程规矩（用户 11-05、11-09、11-13、11-14 的话）：计时超标不到 10% 一律接受（§1 第 28 条），更大的先列给用户、不自行派 agent 修；只改代码不算成本，用户关心
功能与性能上的损失；派 agent 去做，不自己动手（11-13）；与文档、测试相关、不改变设计的事我自决，改变设计的仍先问（11-14，§1 第 28 条）。
最后更新 2026-11-14。
**怎么读：** §1 是用户批准的决定（按编号；后面的条目可修订前面的，修订处都注明，被取代处有回指）；§6 是第一版的完整设计，必须与 §1 一致，与 §2–§5
冲突时以 §6 为准；§2 是核实过的事实；§3 是过程记录（含写作"已定""批准"的旧内容，与 §1、§6 不同处一律以 §1、§6 为准）；仍待用户回答的事与第七、
八轮评审的结果列在 §6.11 末尾。
§6 引用的行号多为 Isabelle2025-2 的，实现时按 2026 核对。
本文档所在仓库：`contrib/dot_syntax`（feature 仓库，2026-10-28 建）。实验原型与演示都在本仓库的
`ai-artifacts/probes/` 与 `ai-artifacts/reviews/`，被 `.gitignore` 排除，不提交（见 §5）。2026-10-28 之前它们在 MLML 的
`ai-artifacts/dot_syntax_probe/`，当时用绝对路径加载，挪动后重跑需改路径。
目标发行版：**只考虑 Isabelle2026**（用户 2026-10-31，§1 第 17 条）；私有树 `contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax`（分支
`Isabelle2026/dot_syntax`，base `Isabelle2026/local_datatype`；登记已提交为 `b8f3070`、未 push，见 §3.4）。此前的原型与实测大多在 `contrib/Isabelle2025-2` 上做。

## 0. 术语

- **dot 语法**：在 term 里写 `x.f`，意思是按 `x` 的类型选出名为 `f` 的函数，作用到 `x` 上。
- **对象**：`x.f` 里的 `x`。**字段名**：`f`。
- **登记**：一条"字段名 + 一个以对象为第一个参数的常量"（只能写常量，含 abbreviation；2026-11-02 起存的是按原版标准方式读出的 term，缩写展开，随 morphism 变换，§1 第 1 条）。
  record 包为每个字段自动登记（常量就是字段选择函数）；用户也可以登记别的常量，例如 `len` ↦ `length`。
- **模式类型**：登记存下的 term（locale 的副本是随 morphism 变换后的 term）的类型的第一个参数，即它接受什么样的对象（2026-11-02，§1 第 1 条修订）。
- **可合一**：对象类型 T 与模式类型 P 存在共同实例。
- **匹配**：T 本身是 P 的实例。
- **候选集合 U**：名字等于字段名、且模式类型与 T 可合一的所有登记（用时去掉被别的候选包含的候选，§6.4）。
- **长标识符**：inner syntax 里带点的一个 token，如 `a.b.c`（Isabelle 词法本来就把它读成一个 token）。**第一段**：其中的 `a`。
- **局部变量**：在该处被 binder 绑定的变量，或上下文里的固定变量（`fixes`、`fix`、`obtain`、`for`、locale 参数等）。未声明的隐式自由变量不算。
- **开关**：configuration option `dot_syntax`（§1 第 14 条）；**开关打开 / 关闭**指它在当前上下文的值。
- **载体**：解析阶段为一次字段访问生成的 term `Pure.dot_access $ 载荷 $ 对象`，等选字段之后换成选中的常量作用在对象上。
  （旧称"占位常量"，最初的原型写作 `dot_access ''f'' x`。）**载荷**：载体的第一个参数，一个名字是可读文本的变量
  （如 `dot_field name=s.start.xpos index=2 …`），记下所写的标识符、第几段、位置（§6.3.3）。
- **选择、C、E(C)**：选择 = 一次字段访问选中的登记；C = 一个 term 里所有字段访问的选择；E(C) = 把每个 `x.f` 按 C 写成显式形式 `g x` 后的 term。
- **最后检查**：每个选择都要在对象的最终类型上按选择规则重选一次，必须得到同一个，否则拒绝。
- **第 −100 级 / 第 0 级 / 第 1 级**：Isabelle term 检查阶段的级别。级别从小到大执行；同级按注册顺序；
  每一级反复执行直到某一遍没有任何函数改动 term（`src/Pure/Syntax/syntax_phases.ML:1011`）。
  类型推断 `"standard"` 在第 0 级；HOL 的 coercion 推断在第 −100 级；adhoc_overloading 在第 0 级。
- **轮**：第 0 级所有检查函数按顺序各跑一遍。这是 Isabelle 原有行为，不是 dot 语法引入的。
- **local pass / global algorithm**：HOL coercion 推断（`src/Tools/subtyping.ML`）原有的两种做法：先逐节点推断并就地插 coercion，失败时
  再对整个 term 生成约束、求解。沿用英文原名。
- **R1、R2、R3**：§6.0 的三条需求。
- **第 1 级的 dot 检查**：第 1 级的第一个检查（原型里叫 `dot_unresolved`），一个检查做三件事：报告留下的载体；对 D14 标记做最后检查并删去标记；
  在学习运行里见到学习标志就结束该运行。本文其他叫法（"第 1 级检查""标记检查"）都指它。
- **前端标记**：Isabelle 发给 jEdit 的 markup（上色、悬停、跳转）。**D14 标记**：D14 为每个学到的字段附加的一个自由变量，类型是对象类型，供第 1 级的
  dot 检查做最后检查。（解析时"给点做标记"是第三种用法，只在 6.3.2 出现。）
- **学习**：coercion 引擎在 global algorithm 里求出字段选择（第三轮起就有）。**学习运行**：D14 的嵌套运行——把引擎的输出交给原版检查跑到第 0 级结束，
  从中读对象类型（6.5.3）。**守卫**：决定要不要做学习运行的测试（6.5.3）；与已去掉的 `dot_guard` 无关。
- **I1a**：coercion 引擎的捷径出口——local pass 成功、且选中的常量都不带 `coercion_args` 声明时，直接返回 local pass 的结果，不再让原版推断 E(C)
  （6.5.1）。原先还写了"没有字段等待过"这个条件，它对成功的 local pass 按构造恒成立，不是运行时测试（第七轮深度复审问题 2）。去留由第一步实测定
  （§1 第 22 条）。
  **option b**：local pass 失败或结束时仍有字段等待时，从头在 global algorithm 里学选择。**节点修补**：option b 的候选被原版对 E(C) 拒绝时，在 E(C)
  的原版 local pass 里找到第一个选得不一样的字段，改取该处的选择、之后的重新学。**推迟重跑**：同一处还有别的字段等待时推迟重新推断，整处只重跑一次。
  **成环规则**：字段之间相互依赖成环时，先猜规则能决定的最早的那个。**晚决定**：字段等待后，对象类型确定时再决定。

## 1. 已定的决定（用户已批准）

1. **通用框架**，不只为 record 服务：任何 term 都可以登记成 `x.f` 的写法；record 字段只是自动登记的一种。
   **（2026-11-01 修订，用户确认）：只能登记常量（包括 abbreviation、locale 里的局部常量），登记时存常量名、不展开**；E(C) 就是 `c x`，abbreviation 由原版
   照常展开。不能直接登记任意 term（如 `λxs. size xs`），要先定义常量或 abbreviation。模式类型取 `Consts.the_constraint`。（用户说："在我脑海里
   dot_field 是必须登记到一个（语法）常量上去的"；"任意 term"是我 10-28 的记录。）由此：字段那一段的前端标记就是该常量的标记（悬停显示它，
   ctrl-click 跳到它的定义处），不需要新的标记类型；登记的同一性简化为常量名加类型实例。
   **（2026-11-02 修订，用户"按你建议来"；第七轮深度复审问题 1，§6.11 的 2.1）：仍只能写常量（照旧检查写的是不是常量），但存下的不是名字，而是按
   原版标准方式把它读成的 term——与原版带 term 参数的声明 attribute 相同（如 `[[coercion f]]` 用 `Args.term` 即 `Syntax.read_term`，检查阶段展开一切
   缩写）；这个 term 随 morphism 变换。** 例（theory 名 `T`）：record 字段 `xpos` 存 `Const ("T.point.xpos", ?'z point_scheme ⇒ int)`；`length` 存
   `Const ("Nat.size_class.size", ?'a list ⇒ nat)`（`length` 是 `size` 的缩写）；locale `foo`（`fixes n :: nat`）里定义的 `bar`（在 locale 里是缩写
   `local.bar`）存 `Const ("T.foo.bar", nat ⇒ ?'a list ⇒ nat) $ Free ("n", nat)`，`interpretation a: foo 3` 之后那一份变成 `T.foo.bar $ 3`，与原版读
   `a.bar xs` 的结果相同。放弃"不展开"的理由：存名字跟不进 interpretation（morphism 只变换 term、不改名字；`local.bar` 在 theory 里不存在，sublocale 里
   还会静默指到别的函数；Isabelle2026 探针 `reviews/round7/deep/review-decisions/P_LocalConst.out`、`review-surface/probe3.out`、
   `defend-integration-2/P_Defend2.out`）。由此：模式类型取存下的 term 的类型的第一个参数；E(C) 是 `t x`；字段那一段的前端标记是该 term 的头部常量
   （theory 层的缩写显示展开后的常量，如 `size`；locale 自己的常量显示全局常量 `T.foo.bar`，ctrl-click 仍跳到 locale 里那行 `definition`；报错的候选行由
   打印器折回缩写，仍显示 `length xs`、`a.bar xs`）；登记的同一性按展开后的 term 比较。上面 11-01 那段的"存常量名、不展开"、"E(C) 就是 `c x`"、
   "模式类型取 `Consts.the_constraint`"、"字段那一段的前端标记就是该常量的标记（悬停显示它，ctrl-click 跳到它的定义处）"、"同一性简化为常量名加类型
   实例"五句由此取代；"不能直接登记任意 term"与"不需要新的标记类型"仍成立。（本段里关于前端标记的那半句又被下面的再修订取代。）
   读法的细节（第八轮短评审第 5 条）：与 `[[coercion f]]` 存下的 term 相同——`Syntax.read_term` 之后在登记所在的 context 里做
   `singleton (Variable.polymorphic ctxt)`（subtyping.ML:957-960、adhoc_overloading.ML:259），context 不固定的类型变量成为 schematic，locale 的类型参数保持
   固定、由 morphism 实例化；只有"先确认写的是常量、再展开"用什么函数留到第一步定。
   **（2026-11-02 再修订，前端标记部分；第八轮短评审第 3 条）：** 我原先只告诉用户"悬停显示展开后的常量"；短评审指出 ctrl-click 也会落到展开后的常量上
   （`length` 字段跳到 Nat.thy 的 `class size`），带参数的缩写（`sym_diff`）没有头部常量。用户："这个不是很能接受"。讨论中用户先后问"为什么不走
   morphism""直接记录一个 term 然后这个 term 就会被 morphism""你直接记录 checked term 然后内部处理时 uncheck 不就好了？""或者你就是记一个名字，然后你的
   declare 能获得 morphism 吗？"。结论（用户的提议）：**存法不变——存检查过的 term（原版标准读法），随 morphism 变换；字段那一段的前端标记取这个 term 在
   当前 context 里折回缩写之后的头部常量**，即原版 uncheck 第 0 级 `"standard"` 那一步 `Proof_Context.contract_abbrevs`（proof_context.ML:733、921），经
   eta 收缩后取 `head_of`，是 `Const` 才报实体标记。于是：`len = length` 存 `size` 在 list 上的实例，折回成 `length`，悬停与 ctrl-click 都是 List.thy 的
   `abbreviation length`；locale 里的 `bar` 存 `T.foo.bar $ n`，在 locale 里折回成 `bar`，`interpretation a: foo 3` 之后那一份 `T.foo.bar $ 3` 折回成 `a.bar`
   （interpretation 为 `a.bar` 登记了打印用的缩写，generic_target.ML:155-156），与直接写 `a.bar` 时的标记相同；`sym_diff` 存 λ-term，折回后也得到
   `sym_diff`（实测见下）。我的细化（按授权定）：只用折回缩写这一步，不用整个 uncheck——整个 uncheck 还跑 adhoc_overloading 的 uncheck
   （adhoc_overloading.ML:203-223），会把登记的变体 `mkoP` 显示成重载名 `mko`，而直接写 `mkoP` 时显示 `mkoP`。用户关掉 `show_abbrevs` 时不折回，标记是展开后
   的常量（同打印器）。开销：每个报告标记的字段那一段一次折回，第一步测（字段标记本来就是未测行）。"只存名字、靠 declaration 收到的 morphism 变换"不行：
   declaration 确实收到 morphism，但 morphism 只变换 term（自由变量、类型）与正在声明的东西的名字，`local.bar` 这个名字里没有可变换的东西，而接收方
   （interpretation 之后的 theory）里也查不到它原来代表 `foo.bar n`；所以含义必须在登记时就定下，即存 term（探针 `defend-integration-2/P_Defend2.out` 的
   ACT 行是收到 morphism 的激活，仍报 `Undeclared constant`）。
   **实测（用户要求在 cslh19 上跑，2026-11-02；官方 Isabelle2026 + HOL heap；`probes/markup_fold/Markup_Fold.thy`、`.out`）：** 全部按上面的预期，带参数的
   缩写也折得回来——`length`（存 `size`）折回成 `List.length`，定义处 List.thy:279；`sym_diff`（存 λ-term）折回成 `Set.sym_diff`；record 字段不变；locale
   里的 `bar`（存 `foo.bar n`，定义它的块与重新打开的块）折回成 `local.bar`，定义处是 locale 里那行 `definition`；locale 里带参数的 `abbreviation baz`
   （存 λ-term）折回成 `local.baz`；`interpretation a: foo 3` 之后的副本 `foo.bar 3` 折回成 `a.bar`，实体标记有两处定义位置（locale 里的 `definition` 与
   `interpretation` 那一行，后者标 "interpreted"），与直接写 `a.bar` 相同；`baz` 的副本折回成 `a.baz`；sublocale 目标 `qux` 里 `foo.bar m` 折回成 `c.bar`。
   代价三条：(i) 有第二个缩写能折回同一个 term 时最新的胜出（之后定义 `abbreviation mylen ≡ size :: 'a list ⇒ nat`，登记 `length` 的字段的悬停与
   ctrl-click 变成 `mylen`；打印器也这样打印）；(ii) 只用于输入的缩写（`abbreviation (input)`）不折回，`show_abbrevs = false` 时不折回；(iii) 每次折回约
   2.1–2.6 µs（10 万次 0.21–0.27 s，负载 0.2–1、未绑计时 CPU、未排计时锁，非正式）。**用户 2026-11-02 接受 (i)；这一做法定下。**
2. **索引**：只用一个 Net。每条登记的 key term 是 `Const (字段名, dummyT) $ Net.encode_type (模式类型)`，
   即 key 序列先是字段名，再接模式类型生成的序列。Net 的查询结果是超集，查出后必须用
   `Sign.typ_unify`（处理 sort 与重复类型变量）过滤；可复用 adhoc_overloading 的 `unifiable_types`
   （`src/Pure/Tools/adhoc_overloading.ML:139-145`）。
3. **选择规则**（设对象当前类型为 T）：
   1. T 是类型变量：这一轮不动；到第 1 级报"类型未知"。（第一版里由引擎在推断结束、D14 学习运行也学不到时报，文案同第 7 条；"第 1 级"只做兜底，§6.5.3。）
   2. 求候选集合 U。（用时去掉被别的候选包含的候选：我按授权定，§6.4。）
   3. U 为空：立即报错。
   4. U 只有一个：选它。若它的模式类型比 T 更具体，选它的同时细化对象类型
      （例：`u :: ?'z point_scheme` 上的 `.color` 选中 `cpoint.color`）。
   5. U 有多个、且其中至少两个与 T 匹配：立即报错（T 无论怎么细化，这两个都仍然匹配）。
   6. U 有多个、但与 T 匹配的不到两个：这一轮不动；到第 1 级仍未解决就报"类型不够明确"。（报的位置同第 1 步的注。）
   - "不动"的意思是"这一轮先不动"，下一轮还会再看；链式访问 `s.start.xpos` 靠这一点逐层解开。
   - 已删除的旧规则："最具体者优先"（子 record 覆盖父 record 时选子的）——改为第 5 步报歧义。
     理由：覆盖只是名字遮蔽，一个 `cpoint2` 值里同时存着 `point.xpos` 和 `cpoint2.xpos`，仅凭类型分不清。
4. **不用上下文对结果类型的要求来消歧**（例如不因 `c.xpos + (1::int)` 而选 `point.xpos`）。
5. **对象类型推不出来就报错**，不退回到按短名查找。
6. **报错必须同时提到"常量"和"字段"两种可能**：解析时无法区分前缀是隐式自由变量还是打错的常量名
   （例：`Lisst.map`）。
7. **已批准的报错文案**（示例为实际渲染结果；类型变量名在真实报错里以类型推断留下的名字为准）：

   对象类型已知，有两个同名字段（第 5 步）：
   ```
   Ambiguous field "xpos" of c :: cpoint2
   "c.xpos" is not a constant, and cpoint2 has 2 fields named "xpos":
     cpoint2.xpos c :: nat
     point.xpos c :: int
   Write one of these terms instead.
   ```
   类型只明确一半（第 6 步，第 1 级）：
   ```
   Ambiguous field "xpos" of u :: ?'z point_scheme
   "u.xpos" is not a constant, and the type of u is not determined enough to choose among:
     cpoint2.xpos u :: nat
     point.xpos u :: int
   Write one of these terms instead, or fix the type of u.
   ```
   类型未知（第 1 步，第 1 级）：
   ```
   Field "xpos" of z cannot be resolved: the type of z is unknown
   "z.xpos" is not a constant. Fields named "xpos" exist for:
     other.xpos :: ?'z other_scheme ⇒ nat
     cpoint2.xpos :: ?'z cpoint2_scheme ⇒ nat
     point.xpos :: ?'z point_scheme ⇒ int
   ```
   没有候选（第 3 步）：
   ```
   "r.foo" is neither a constant nor a field of r :: point
   Fields of point: xpos, ypos
   ```
   - 候选行的名字由打印器生成（最短无歧义名）。建议候选按全名排序以使输出稳定（未批；第三轮原型按登记从新到旧，随其他文案在实现第一步后过目，§6.6）。
8. **警告**（用户提出；以下各条 2026-10-28 批准）：长标识符被解析成已有常量、但也能读作字段访问时给出警告。
   - 只有一种切分：最左一段是对象，其余各段从左到右全部按字段解释；不考虑"前若干段合起来当对象"。
   - 对象必须是常量，或在上下文里声明了类型的固定变量（`Variable.default_type`，`src/Pure/variable.ML:195`）。
   - 某一段有多个候选时**也警告**（无法确定用户意图）；某一段没有候选，则这种读法不成立、不警告。
   - 位置：`decode_term` 里把 `Free` 解析成常量的那一步；只对最终选定的语法树发警告（见 §2）。
   - 已批准的文案（只有一种读法时；实际渲染）：
     ```
     "config.timeout" is read as the constant Warning_Demo.config.timeout :: ?'z config_scheme ⇒ nat
     It could also be read as field access:
       timeout config :: nat
     Write that term to mean the field access, or CONST config.timeout to keep the constant without this warning.
     ```
   - 多候选时的文案、链中多候选后如何继续、AFP 测量：见 §3.1，待定。（现状见 §3.1 开头。）
   - （2026-10-31）第 9 条改为"局部变量优先"后，固定变量作对象的情形改读字段访问，本条需相应调整（在 2026-10-31 的设计迭代中设计，文案待批）。
     （已调整，见下一条。）
   - **（2026-10-31 调整后的现行规则，见第 16 条与 §6.6）**：只在"读成常量、也能读成字段访问"这一个方向警告。对象只能是常量：切分随第 9 条，
     取最长的、本身是常量的真前缀作对象（通常是第一段，如 `config.timeout` 的 `config`；也可以更长，如 `Demo.config.timeout` 的 `Demo.config`），
     其余各段是字段；第一段是局部变量时第 9 条已读成字段访问，不再走这条警告；隐式自由变量不作对象。用该常量的类型按选择规则逐段查登记，
     确实有字段才警告（某一段多候选也警告）。链上多候选的走法与 AFP 频率见 §3.1 的现状说明。上面"只有一种切分：最左一段"与"固定变量作对象"两点
     因此不再适用。
9. **局部变量优先**（2026-10-31 定，推翻 2026-10-28 的"已有常量优先"）：长标识符 `a.b.c…` 的第一段 `a` 是绑定变量或固定变量时，
   `a` 就是对象，其余各段从左到右都是字段——单独的标识符与链统一这样处理，即使整个标识符或它的某个前缀是已声明的常量（这时要取常量写
   `CONST a.b`）。第一段不是局部变量时：整个标识符是常量就按常量；否则取最长的、本身是常量的前缀作对象（如 `Thy.origin.xpos` 读作
   `xpos Thy.origin`），其余是字段；都不是常量时最左一段作对象。用户知道这会改变今天能运行的文本的含义（AFP 里绑定变量与 interpretation 前缀同名的
   写法，如 CAVA_Automata 的 `b.E`、Collections 的 `m.update`，静态上限 1,786 处、56 个 session），以第 14 条的开关兜底；用户的主要考虑是性能。
   （2026-10-31 第四轮更正：1,786 是第三轮对警告次数的估计，不是含义改变的处数；某 theory 打开开关时 AFP 里含义改变的约 9,100–10,500 处，
   约 93% 是 locale 参数与 interpretation 前缀同名的 `C.arr`，见 §3.3b 的第四轮条目；用户 2026-10-31 按新数字确认保持局部变量优先。）
   （2026-11-02 补全记录，第七轮深度复审问题 13，§6.11 的 2.5：上面"用户的主要考虑是性能"只转述了 05:57 原话的一句，不全，以本注为准。用户 10-31
   05:51 UTC 给的理由是功能上的——单写的 `seg.start` 也应局部变量优先；
   规则必须统一，单独的标识符与链一样处理——并以此否决了我当时推荐的"常量优先、只对非常量局部变量优先"的混合规则；05:57 的原话是"统一局部变量
   优先。是的，推翻 §1.9 / 我主要是考虑性能。如果你愿意可以再进行之前你进行过的自主设计迭代来找到一个好的方案"。用户 2026-11-02 确认维持局部变量
   优先，并说明："性能要考虑，但更要考虑的是功能"。已知后果：lemma 陈述与定义方程里的变量在读入时还没固定，局部变量优先在那里不起作用（2.4）。）
   （旧条文：长标识符本身是已声明常量时按常量解析，对 λ 绑定变量、固定变量也一样，`λconfig. config.timeout` 读成常量；补充事实：`CONST point.xpos`
   在原版里也能取到长名字的常量，即使同名固定变量存在，`probes/Const_Long.thy`。）
10. **名字**（2026-10-28 批准）：feature `dot_syntax`；分支 `Isabelle2025-2/dot_syntax`；私有树
    `contrib/Isabelle2025-2-dot_syntax`；stock 树 `contrib/Isabelle2025-2-dot_syntax-stock`；feature 仓库
    `contrib/dot_syntax`；GitHub `xqyww123/Dot_Syntax`（公开）；conda 包 `isabelle-dot-syntax`。
    （2026-10-31 查看：私有树与 stock 树已移到 feature 仓库里，作为它的 submodule：`contrib/dot_syntax/worktrees/Isabelle2025-2-dot_syntax`、
    `…-stock`，提交 30f098e，见 §3.4。名字不变。）（2026-10-31 起被第 17 条部分取代：分支、私有树、stock 树改为 Isabelle2026 的；feature、feature
    仓库、GitHub、conda 的名字不变。）
11. **链中位置**（2026-10-28 定）：local_datatype 之后、dev_patches 之下。
12. **选字段的算法采用 ESR**（2026-10-29 定）。ESR 即 explicit-subterm re-inference，是第一次头脑风暴
    judge 综合出的方案（`reviews/brainstorm/BRAINSTORM_REPORT.md`；原型 `reviews/brainstorm/judge/`）：
    - 字段在推断算法内部选：遇到 `dot_access` 时对象类型已能让选择规则决定，就当场选，并按显式写法
      `g x` 的原有步骤继续；
    - 当场选不了：结果类型设为 rigid type variable，依赖它的步骤不做决定；
    - coercion 推断中字段后来才能选：把同时包含该字段与确定它的那一步的最小函数应用，从它开始推断时
      保存的状态出发重新推断一遍（字段已写成显式调用）；标准推断中则等对象类型确定后用合一补上，不重新推断；
    - local coercion insertion 失败或结束时仍有未选字段：在显式写法上运行原有推断；
    - 最后检查：每个选中的字段，在对象最终类型上按选择规则重选必须得到同一个。
    用户由此放宽了"不重新推断"的要求：只在上述情形、只对那个最小函数应用。
    （2026-10-31 起：§6 在此之外还有几处重新推断——推迟重跑、option b 从头学与节点修补、晚决定冲突时放回节点重推断、D14 的学习运行——是我按用户
    2026-10-30 的授权"可以随便改变我之前的建议等，只要保持我们的需求不变"定的，R1/R2/R3 不变，实测更快或持平（§3.3b 用户 10-31 答复前的记录）；
    已在聚焦评审里审过。）
    对照方案 proto1（不重新推断，挂起后补做）的实现、验证与测量：`reviews/brainstorm/PROTO1_REPORT.md`、
    `reviews/brainstorm/measure-proto1-cslh19/`（cslh19 复测，与本机的同进程比值相差多在 5% 内）。
13. **括号后的字段访问 `(e).f`**（2026-10-30 定）：
    - 第一版就包含（`[…].f`、`{…}.f` 同理，尚未实测）；
    - 字段访问的点后面不允许空格：`(a + b).xpos` 是字段访问，`(a + b). xpos` 不是；
    - 一个点同时能被其他文法规则用作分隔符时，不读作字段访问，以保持今天的含义。唯一实测到的冲突是
      集合推导式与列出元素的集合：`{(x::nat).x > 0}`（模式是加了括号的单个变量、点后无空格；AFP 24 处，HOL 0 处）
      按集合推导式读。
    - 实测依据（`probes/paren_ambig/`）：只针对 `( 表达式 )` 的字段访问规则下，必须带点的 binder（λ、∀、∃、THE、⋃）
      与 tuple 模式都只有 1 棵解析树；冲突的写法每个产生 2 棵，同一 term 里 k 个就是 2^k 棵（k = 10 时 1,024 棵、0.7 秒），
      所以歧义必须在解析器列举语法树之前消除，不能事后挑选。
    - 实现方式（我的提案，待评审）：词法分析把"后面紧跟标识符的点"标成另一种 token；解析器让所有现有的 `.`
      分隔符同时接受两种点；`(e).f` 规则只接受后一种；剩余的冲突在解析之后、歧义警告之前，保留把更少的点读作
      字段访问的那棵语法树。（已被第三轮的做法取代：先用原版文法解析，失败时才做带 `(e).f` 规则的第二次解析，见 §6.3.2。）
    - （2026-10-31 修订）只认圆括号：字段访问的点只在 `)` 之后识别，`[…].f`、`{…}.f` 不支持（用户：假设不给 list、set 配置字段；
      需要时写 `([a, b]).f` 或 `xs.f`）。点的前面也不许有空白。
14. **开关**（2026-10-31 定）：有一个 configuration option，默认关闭；用户手动开启后 dot 语法（字段访问的拆分、`(e).f`、按第 9 条的解析）才生效。
    关闭时一切同原版（含开销；唯一例外是字段登记照常记录，第 16 条批准）。
    （2026-10-31 批准）名字：开关 `dot_syntax`，警告开关 `dot_syntax_warning`，bundle `dot_syntax`。
    **（2026-11-01 修订，用户："不要 bundle，不要过度设计"）：不提供 bundle。** 打开与关闭只用 `declare [[dot_syntax]]` / `declare [[dot_syntax = false]]`
    （或 `[[dot_syntax]]` 用在其他接受属性的地方）。因此第五轮评审 3.3（`unbundle no` 反而打开）不再存在。文档写明：在 locale 里 `declare` 会延续到
    该 locale 以后的每个 context 与每次 interpretation；第一版没有"只对一个 lemma 打开"的专门写法。作用范围：随 import 继承，同 Isabelle 其他
    configuration option（不加"每个 theory 从关闭开始"的钩子）。实测（`probes/config_merge/`，cslh19）：一个 import 打开、importer 也打开；
    两个 import 显式设了不同的值时 `imports` 里靠前的胜出（`imports On Off` 开，`imports Off On` 关）；从没设过的 theory 不参与（`imports Plain On` 开）。
    （2026-11-02 更正与重新确认，第七轮深度复审问题 10，§6.11 的 2.7：上面"第一版没有只对一个 lemma 打开的写法"不对——原版
    `context notes [[dot_syntax]] begin … end` 就是限定范围的写法，可包一个或几个 lemma、可嵌在 `context L begin … end` 里，块一关就恢复（Isabelle2026 探针
    `reviews/round7/deep/review-decisions/P_Scope.out`）；`lemma notes [[dot_syntax]] shows …` 的陈述按原开关读，只作用于证明（expression.ML:312）。locale 里的
    `declare` 到达的范围也比上面写的广：该 locale 以后每个 context、导入它的 locale、sublocale 的目标、每个 interpret 它的 theory（从那条命令起）及其导入者；
    无名块与 light-locale 块里的 `declare` 作用于整个 theory。去掉 bundle 时我告诉用户的"没办法只对一个 lemma 打开""bundle 是唯一不漏的写法"是错的。
    **用户 2026-11-02 "赞同你的建议"：维持随 import 继承、不要 bundle**；文档按 §6.11 待办问题 10 写五点。）
15. **其他 2026-10-31 的决定**：性能代价批准（常见写法约 0.95–1.2 倍；救回的 term 约 3 倍；报错最多约 1.7 倍；原版指数级嵌套且只有新做法
    能接受的 term 最多约 20 倍）；coercion 打开时对象类型只能靠 adhoc_overloading 定出的 term 接受（d14on 的做法，Pure 的 adhoc_overloading.ML
    导出 2 行 `is_overloaded`；**做法已被第 18 条取代**：接受不变，改用第六轮的机制，不需导出）；兼容性：case 模式里的带点变量名（`case xs of x.y ⇒ x.y`）改变含义接受（已被第 16 条取代：第四轮的方案下
    含义不变）；报错里的字段列表最多 10 条，多出的写
    `and N more`（已被第 19 条取代：一律最多 5 条，多出的只写省略号）；误拼的带限定名常量在没有任何同名字段登记时保留今天的 `Undefined constant` 原文（`List.fil`），有同名登记时用第 1 步文案。
16. **第四轮的决定**（2026-10-31；方案写在 §6.3.1，过程见 §3.3b 第四轮条目）：
    - case 模式（及列表推导、λ 模式）里的长标识符不拆，按今天读（`λoption. case v of option.None ⇒ …` 的模式仍是构造子）。
    - 带点的模式变量保持原版含义（`case v of Some b.x ⇒ b.x`，外面有 `λb` 也一样）；取代第 15 条里"改变含义接受"那一项。
    - 开关打开时带限定名常量每个 +0.5–1.1 µs：接受，但要尽力优化。
    - 打印能读回：只在开关打开时，打印器写的常量名第一段是该处绑定变量时给绑定变量换名（`λba. ba ∈ b.E`），是固定变量时打印 `CONST C.arr`。
      （2026-11-01 修订，用户："打印器需要升级，对于 b.E 应该打印成 Theory.b.E"：改为第五轮评审 3.7 推荐的做法——开关打开时，常量准备打印的名字
      第一段与该处的变量或固定变量冲突，就改用下一个可访问的更长名字，如 `Thy.b.E`、`local.C.arr`。用户另问：若 `Theory` 也冲突，能否支持
      `.Theory.b.E` 这种写法；我的答复与建议（全部冲突时打印 `CONST b.E`，不新增文法）待用户定。）
      **（2026-11-01 定稿，用户确认）：开关打开时，凡是常量准备打印的名字，第一段与该处的变量（绑定、自由）或上下文的固定变量冲突，一律打印成
      `CONST 名字`（如 `λb. b ∈ CONST b.E`、`CONST C.arr + xpos C`）；不冲突照原样；不换绑定变量名、不改用更长名字、不新增 `.Theory.b.E` 文法。**
      原版"自由变量与常量重名时打印更长名字"的规则照旧。开关关闭时打印同原版。位置与实现见第五轮评审 3.7（`pretty_entity_cache` 一处，判断用
      `exclude_consts` 已收集的名字与 `Dot_Field.is_fixed`）；已写进 §6.6。
    - 会删掉位置信息的翻译内部不拆，按今天读（Hoare 的 `_While` 变体、Statespace / Simpl / AutoCorres2 的变量名、Shallow_Expressions 的 `(e)\<^sub>e`）：
      2026-10-31 批准（听过讲解后）。
    - 开关关闭时字段登记照常记录（record 自动登记与 `dot_field` 命令——命令后改为 attribute，第 20 条；关闭时从不查表、不出消息；代价每字段 0.56 µs、不同大登记表合并 0.34 ms）：
      2026-10-31 批准。**（2026-11-01 修订，用户赞同）：开关只控制读 term（解析与选字段的引擎）；登记表本身不看开关。用户显式写的
      `[[dot_field …]]` 不论开关开关都照常检查（是常量、是函数）、报告冲突，删除登记总能执行；record 自动登记照旧不检查、不出消息。**
      理由：原版文本里没有 `[[dot_field …]]`，不影响 R3；照字面会失去开关关闭时的冲突检查与删除，并在 locale 重放时出现增删不一致（第五轮评审 3.11）。
    - 只写进文档的几种少见情形（不经自由变量绑定的第三方翻译、翻译中途 decode 子项如 Simpl、locale 里 `declare [[dot_syntax]]` 的延续、
      ML 在 parse 与 check 之间改开关）：2026-10-31 批准。
    - 给字段那一段补上悬停和跳转：字段选定后，在字段那一段（链中每一段、`(e).f` 的 `f`）报告所选常量的标记，与直接写该常量名时相同
      （颜色不变；悬停显示所选常量；ctrl-click 跳到 `record` 或 `dot_field` 处）；只在 IDE 里发；开销在实现第一步测。2026-10-31 批准。
      （"只在 IDE 里发"已被第 24 条下的决定取代：凡原版报告标记处都报告，含批量构建，字段那一段不提供类型提示；用户 2026-11-02 确认，§6.11 (a)。
      字段那一段的标记取所选登记 term 在当前 context 里折回缩写后的头部常量，ctrl-click 跳到该常量的定义处（第 1 条 2026-11-02 再修订、6.6）。）
    - lemma 陈述与证明里同一写法读法不同（陈述里未声明的变量不是固定变量）：只写进文档（建议用 `fixes`），不加警告。我按下面的授权自定。
      （2026-11-02，第七轮深度复审问题 5，§6.11 的 2.4：所有规格方程也一样，方程里没有 `fixes`，补救是方程后的 `for x`；文档按此改正（我的待办）。
      是否加警告：用户 11-02 "我认为不需要加警告，因为颜色已经说明了一切"——不加。）
    - **授权（2026-10-31）：与文档、测试相关的事，在不改变设计的前提下由我自决。**
    - （2026-10-31，看过 jEdit 截图后）第一段是局部变量、而整个标识符或前缀也是常量时**不发警告**：jEdit 里第一段显示为绑定变量（绿）或
      固定/自由变量（蓝），常量整体是默认色，颜色已表明读法。我向用户说明的唯一代价：在旧 theory 里打开开关时，字段读法恰好能通过类型检查的
      地方（AFP 至多约 643 处）没有提示；字段不存在时的报错仍提到那个常量与 `CONST` 写法（文案待实现第一步后过目）。
      §3.3b 第四轮条目里的讨论点 (1)（警告与报错重复）与 (3)（变量与 record 同名时的噪声）因此不再存在。
    - 另一方向（读成常量、也能读成字段访问）的警告保持 §1.8 已批的做法：对象必须是常量（第一段，或更长的前缀如 `Demo.config`），在解析选定
      语法树之后、类型检查之前发出；按选择规则用该常量的类型查登记，确实有这个字段才发（第三轮 `reviews/round3/warn/DESIGN.md` §3–§4 已这样实现，
      第四轮原型只比了字段名，是简化）。
    - 补充事实（读代码，2026-10-31，向用户讲解"去掉位置信息的翻译内部不拆"时）：只影响交给 `strip_positions` 的那一块。AutoCorres2
      `lookup_tr ctxt [s, x]` 只去掉名字参数 `x` 的位置（`CLocals.thy:629-641`），`s` 与 term 其余部分照常有点语法。Shallow_Expressions 的
      `(e)\<^sub>e`（`Expressions.thy:71, 110`，`Lift_Expr.mk_lift_expr` 对整个 `e` 去掉位置再把程序变量换成"在状态里取值"）里整个 `e` 都没有点语法：
      `(p.xpos + 1)\<^sub>e` 里的 `p.xpos` 照今天读，不是常量时得原版的 `Undefined constant`；要写 `(xpos p)\<^sub>e`。第三轮的旧设计（解析时就拆）
      在那里反而能用，但会让 AutoCorres2 崩；两个包都调同一个 `strip_positions`，一条通用规则不能同时满足，要两全只能让包自己配合。
      原版现象（与本补丁无关，`render/W_Strip.thy`、`W_Strip.log`，仿 `mk_lift_expr` 的翻译对整个参数 `strip_positions`）：扔掉位置后，括号里的
      标识符（自由变量 `x`、绑定变量 `y` 及其 binder、常量 `Suc`）都没有前端标记，不上色、不能悬停或 ctrl-click；记号 `+`、`0` 的标记保留。
      Shallow_Expressions 本身没有在 cslh19 上跑（没有它的 heap），是按同样形状复现。
17. **目标版本**（用户 2026-10-31，看过聚焦评审的汇报后）："目标版本始终只考虑 Isabelle2026"。取代第 10 条与 §6 里的 Isabelle2025-2：
    私有树 `contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax`（分支 `Isabelle2026/dot_syntax`，base `Isabelle2026/local_datatype`，目前只暂存未提交）；
    发行版 `contrib/Isabelle2026`；AFP 待定（本机有 `contrib/afp-2026-10-26`）。后果（待处理）：此前全部原型与实测都在 Isabelle2025-2 上，要移植到 2026
    并重新验证；Isabelle2026 改了起绑定变量名的代码（聚焦评审 3.12），卫生与打印读回都依赖它；cslh19 上没有 2026 的源码树与 HOL heap（`~/.isabelle/Isabelle2026`
    存在，内容未查），建 heap 需用户下令。（2026-11-02 更正：登记已提交为 `b8f3070`、未 push；cslh19 上有 Isabelle2026 官方发行版 `~/Isabelle2026`，
    自带 Pure 与 HOL heap，第一步可直接用；AFP 用哪一份仍待定，到第三步前问用户。）
18. **D14 的机制**（对象类型只能靠 adhoc_overloading 定出）：用户 2026-10-31 交给 agent 团队定（"这是与实现相关的，也不是我定的"）；采用第六轮裁决的
    机制加验证的两处修补（§6.11 的 D14 结果条目，`reviews/round6/d14/`），取代第三轮的重跑与 d14on 及其 2 行导出（已写进 §6.5.3）。
    用户 2026-11-01 批准两条共有的小妥协：学到的选择被最后检查推翻时直接拒绝、不重试；`termify` 里的 D14 字段不学（都 0 例）。
    用户 2026-11-01 接受超过已批数字的开销（按设计开销即对比报告的 NEW-observer 列：依赖链深度 3/5 约 3.6–3.8 / 5.4–5.5 倍（coercion 开）、2.7–2.9 /
    3.8–3.9 倍（关）；相互依赖的 do 块 3 个绑定 4.2–4.3 / 3.9–4.0 倍；报错中对象被量词绑定或参与 `=`/`∈` 时 1.33–1.64 倍，`∀` 下 10 处访问 1.64 / 2.2 倍；
    只有第 0 级后才暴露的第 3 步错误约 2.4–3.0 倍）。
    用户 2026-11-01 接受 R2 的残留并要求写进文档：周围文本对字段结果的类型要求（如 `(t.xpos :: int)`、`t.xpos + (1::int)`）可以经另一个重载常量
    定出对象类型（`(λt. hh (t.xpos :: int) t) (mk y)` 被接受；不写标注的 `(λt. hh t.xpos t) (mk y)` 报已批的"类型未知"文案）。
19. **报错里的字段列表一律最多 5 条，多出的只写省略号**（用户 2026-11-01："三种统一都改为 5 条，多了就直接省略号"；取代第 15 条的
    "最多 10 条加 `and N more`"）。三种列表：歧义候选（第 5、6 步，每行一个写完整的 term）、类型未知时的 "Fields named … exist for"（第 1 步）、
    没有候选时的 "Fields of …"（第 3 步，一行字段名）。省略号的确切写法（单独一行 `…`，或行内 `, …`）与显示哪 5 条（排序）随文案在实现第一步后过目。
20. **登记接口是 attribute，不引入新命令，不发布组件 theory**（用户 2026-11-01）：`declare [[dot_field 字段名 = 常量]]`（删除登记的写法与名字随文案
    过目，提案 `[[dot_field del 字段名 = 常量]]`），先例 `declare [[coercion int]]`。attribute 定义在 Pure 的 ML 里（加载在 `Isar/attrib.ML` 之后，
    不改任何 `.thy`，theory 哈希不变）；底层仍是一个 `Dot_Field.declaration`（随 morphism 走、遮蔽规则）。接受的缺口：locale 里登记的字段在
    另一个 locale 的头部（`locale B = A + assumes "x.bar = 0"`）、interpretation 的 `rewrites`、`global_interpretation`/`sublocale` 的 `defines` 里看不到
    （第三轮探针 P08）；在 locale 内部、它的 context 与 interpretation 之后都可见；写进文档。由于 bundle（第 14 条）与命令都去掉了，不再有组件 theory。
    简写（用户 2026-11-01 建议支持）：`[[dot_field c]]` 等于 `[[dot_field (c 的最后一段) = c]]`，如 `[[dot_field List.length]]` 即 `length = List.length`。
    （第七轮深度复审："随 morphism 走"与第 1 条的冲突已由第 1 条 2026-11-02 的修订解决；接受的缺口也包括 light-locale 块与无名块——在那里
    `declare [[dot_field …]]` 作用于整个 theory、块关了还在、传到导入者（light_locale 的规矩 REV37:3284-3299，原版无名块 generic_target.ML:407-409），
    用户 2026-11-02 确认，写进文档，限定范围用 `context notes [[dot_field …]] begin … end`（§6.11 的 2.8）；light locale
    只保存语法声明，块内定义的常量登记成字段后出了那个块就失效；用户 11-02："light locale/setclass 先不管"，留给以后的语法设计，见 §6.11 的 2.1 状态。）
21. **去掉 coercion_args 的三处修补**（第五轮评审放宽提议 4.3；用户 2026-11-01 赞同）：选中的字段常量带 coercion_args 声明时，显式写法直接交给原版
    推断（R1 按构造成立）；第三轮的修法 A、B、C（对象推断用所选头部的标志、运算符头部三分读法）全部不要，也不加评审发现的第四处。代价：字段要
    等待、且外层禁止而字段常量在参数里重新允许插入转换时会误拒（例：`cfm (t.f2p (ch n)) = 0 ∧ t = k`，`cfm` 声明 `-`、`cg2p` 声明 `0 +`，报原版的
    `Clash of types "nat" and "int"`，指向 `ch n`）。实情：coercion_args 只在 HOL 内部的 case 常量与 `NO_MATCH` 上声明（`Ctr_Sugar.thy:25-28`、
    `HOL.thy:1892`），AFP 2026-10-26 与 2026-05-13 都是 0 处；不声明时处处允许，不会出错。已写进 §6.5.1。
    ——2026-11-04 第一步实测：代价比上面写的宽，字段并不等待时也会误拒——local pass 在别处失败、转去约束生成时，生成读到的是载体常量那空的声明
    （`Cargs_Probe` 的 CV5、CV6、CV8；R1 都成立）。用户 11-04 答"按你建议来"：**接受**，写进文档（6.9）。
22. **保留 coercion 引擎的捷径 I1a**（第五轮评审放宽提议 4.4 不采用；用户 2026-11-02："建议保留捷径，靠那两个附加条件保证 R1"）：local pass 成功、
    过程中没有字段等待过、且 C 里没有任何选中的常量带 coercion_args 声明时，直接返回 local pass 的结果；否则一律交给原版对 E(C) 的推断。两个条件在
    每个依赖"代码形状等同原版"的地方都要检查（第五轮评审 3.4：去掉 I1b 捷径，条件写明一次）。不付"每个被接受的 dot term 多一次原版推断"的代价。
    （2026-11-02 修订，用户"同意"；第七轮深度复审问题 2，§6.11 的 2.6：第一个条件按构造对每个成功的 local pass 都成立——代码查的是"最后留下的那一遍
    里没有字段等待"，帧重跑把等待表与计数器一起恢复——所以不过滤任何东西；I1a 的 R1 实际靠"代码形状等同原版"的论证、帧从自己保存的状态重跑、以及
    `coercion_args` 条件；我当初把两个条件都讲成起作用，讲错了。**I1a 的去留改由第一步的实测定：** 用观察构建的 `S3B_RECHECK_DONE`（G2 (a)；I1a 的两个出口——`done_result`
    与推迟重跑成功的出口——都复算；参考引擎里它只在 `done_result` 里跑，s3c:3238-3256、3285-3291，第八轮短评审第 7 条）测"一律让原版推断
    E(C)"对 I1a（aconv 比较不计入计时；节点上决定与晚决定的行分开报）；常见写法仍在用户批准的 0.95–1.2 倍之内就去掉 I1a（复审放宽 1）；超出就保留，
    交付的测试加 R1 回归（测试集每个 term 开着开关读，与原版读其显式写法比较，aconv 含类型，每次 Isabelle 升级都跑）。）
23. **保留 `(e).f`**（第五轮评审放宽提议 4.7 不采用；用户 2026-11-02）。实现第一步最先测"第一次解析（Earley functor 的第一个实例）在开关关闭与无点
    文本上的开销"，超出两份相同副本的波动范围就回来找用户。
24. **计时门槛规则**（第五轮评审放宽提议 4.9；用户 2026-11-02 "按你建议来"）：(1) 有原型测量的行，新代码的倍数与所采用原型在空闲时测得的倍数相差
    ≤ 5% 且正序、倒序两次结论一致即通过；(2) 开关关闭或无点文本的行必须落在两份相同原版副本的波动范围内（不放宽）；(3) 以前没测过的行（第一次解析、
    开关打开时的打印、字段那一段的标记）按 (2) 判，不适用的报用户；(4) 任何不通过的行报用户。
    （这四条规则是我起草的提案（第五轮评审放宽提议 4.9），用户批准；用户 2026-11-02 特别说明"我从来没有起草过计时规则"，转述时不得说成用户的规则。）
    **（2026-11-02 修订，用户"全部按你建议来"；第七轮深度复审问题 9、8，§6.11 的 2.2）：** 规则 (1) 改为单侧：正序、倒序两次都不比参考慢 5% 以上
    就通过；比参考快的行也通过，记下变快的原因；其余按 (4) 报用户（比 judge 的"两次都慢 5% 以上才不通过"严：任一次慢 5% 以上就报）。原文"相差 ≤ 5%"
    是双侧的，按设计变快的行（如第二步 coercion 关闭的行，原型每轮多付一次原版推断，`COMPARE.md:82-86`）也会不通过。开关关闭时的开销（R3、规则 (2)）
    只在第一步用同进程的原版副本对功能副本把关；第二步跨两个 heap 的计时只记录、不设门槛（复审放宽 5；跨进程噪声至少 0.98–1.17 倍/行，
    `reviews/round3/tests-texts/TEST_PLAN.md` §6.3）。(2) 与已批例外的关系、参考表、I1b 的测试开关已写进 6.8、6.12（子步骤 2、"一份代码、几个构建"）
    与 G6（问题 9 第 2–4 点）。
    **授权（2026-11-02）："具体实现上的，在不改变设计的前提下，你可以自决。"**（连同第 16 条下文档、测试方面的授权。）
    据此我定：字段那一段的标记就是所选常量的标记（2026-11-02 起是所选登记 term 在当前 context 里折回缩写后的头部常量，见第 1 条再修订、6.6），凡原版会报告标记的地方都报告（包括批量构建，"只在 IDE 里"做不到也不需要），
    字段那一段不提供类型提示；评审放宽提议 4.8（宽容学习、成环规则、节点修补找到 C 时改为拒绝）待第一步数出触发频率后再提。
    （2026-11-05：4.8 的数据已出、按第 25 条部分采纳。）
25. **第一步 G6 之后的七项决定**（用户 2026-11-09 "全部按你建议来"；各项的数据与我的建议见 §6.11 末 11-05 的各条）：
    (1) **D15 那条等待保留**（6.5.1 不变）：(B) 之下它不再影响选择与判定，但保证求解前报出的错只来自类型已是最终的对象。
    (2) **打印 `CONST` 的判断只对带点的名字做**（6.6 修订）：不带点的名字与变量同名（只在 `names_short`，或 `names_long` 下根名字空间的常量时出现）照原版打印。
    (3) **4.8 部分采纳**（6.5.1 修订）：删去成环规则、构造子宽容、运算符宽容（217 个任务上从未改变结果）与节点修补（只挽救 C4 一族人造写法，
        被拒时用现有的最后检查文案）；保留弱合一宽容（真实库里有变成函数的 coercion，如 `measure`，去掉后的文案不提字段）。不加新的拒绝文案。
    (4) **接受三项没有已批数字的开销**（写进 6.8）：字段那一段的前端标记每段约 39–53 µs（登记为 λ-term 时，花在 6.6 的折回缩写上；6.6 不改）；
        真要打印 `CONST` 的 term 每个约 +0.6–0.7 µs；开关打开时无点文本每 term 约 +0.1–0.4%。
    (5) **接受 G6 第二轮仍不通过的各行**（§6.11 末逐条列出：局部变量优先一侧 6 行、标准引擎 2 行、coercion 一侧 let 链 4 行与超出已批倍数的 12 行）。
    (6) **撤回为约 1% 加的两处**：标准引擎在 `Type_Infer.finish` 前测守卫（`Dot_Field.guard` 恢复为 `term list -> bool`，j01–j03 coercion 关闭时回到慢 4–10%，
        随 (5) 接受）；登记表 `declaration` 末尾的 `pointer_eq` 换成 `Data.map`。
    (7) **开代码评审**（CLAUDE.md 的流程），在 (2)(3)(6) 改完、全部测试重跑之后；重在优雅与可读，评审意见经用户同意再改。
26. **代码评审第一轮里要用户定的三条**（2026-11-09；评审全文 `step1/review1/`，§6.11 末）：
    (1) **lexer-parser#1：用户"按你建议来"。** 只有左递归的（第一个符号就是自己的左部）、带 `field_dot` 终结符的产生式不进 lookahead 表、只在第二次解析时预测；
        其余一律照原版进表。前提（左部不能推出空串，`logic` 满足）写在 Gram 的注释里。6.3.2 的写法相应收窄。
    (2) **subtyping-esr#7：用户"赞同 B"**（用户："只是改代码的话不是成本，我关心的是功能或性能上的损失"；B 两者都没有）：原版 `update_coerce_arg` 拆出
        `coerce_arg ctxt old (f, n)`（查 `coercion_args` 与分派），原版函数只剩取头部与参数个数再调用它；D6 只留穿过类型标注读脊的几行，同样调用它。
        6.5 的"原版代码 + 钩子"清单因此多一处。
    (3) **dot-field#7：用户定 B，并收紧到语法层**：attribute 的参数在解析时就只接受两种写法——一个长标识符（简写，字段名取它的最后一段）或 `f = c`；
        `[[dot_field "length :: nat list ⇒ nat"]]` 之类直接是语法错误。写错时要给出看得懂的报错（说明这两种写法、举例），不能是默认 parser 那种
        报错；文案进 6.6 的过目。删除的简写 `[[dot_field del c]]` 同样只接受长标识符。
    评审里归实现者定的 25 项与删掉走不到的 `rejected (LAST_CHECK _)` 子句：用户"不需要跟我讨论的我不予置评"，按授权全做；第 6、11 两处大重构改完再评审一次。
27. **括号形式改为一次解析**（用户 2026-11-10 "赞同必须在 dot 后加空格以区分 field_dot"；取代 6.3.2 的"原版解析失败后再做第二次解析、`field_dot` 兼当分隔符、
    保留把最少的点读成字段访问的读法"）：开关打开时，词法阶段就把紧贴 `)`、又紧贴标识符的点标成 `field_dot`（前后都不许有空白，§1 第 13 条不变）；
    文本里没有 `field_dot` 就用原版解析，有就用能预测 `_dot_field` 产生式的实例只解析一次；`field_dot` 只当字段访问、不再兼当分隔符，于是不再需要
    第二次解析的回退、过滤与权重。**放宽 R3**：开关打开时，紧贴 `)` 的分隔符点（如 `λ(x, y).x`、`{(a, b).P a b}`、`∀x ∈ (A ∪ B).P x`）必须在点前或点后留空白，
    否则读作字段访问——多半报错（报错要附说明并指出该点的位置，文案进 6.6 过目），少数（恰有同名字段适用）会静默改义，写进文档。开关关闭时一切同原版。
    性能先做原型实测（cslh19）；Isabelle 库与 AFP 里这种写法的计数另有 agent 在数（`step1/count_paren_dot/`）。
    计数结果（11-10，term 文本里、按 Isabelle 内层词法判定"单个点 token 后紧跟标识符 token"）：Isabelle2026 `src` 1,574 处，其中绝大多数在一个文件
    `HOL/Nominal/Examples/Class.thy`（它自己的记法 `(x).M` 表示"把名字 x 抽象进 M"，点是它定义的分隔符）；其余约 40 处多在 ZF、CCL 等老对象逻辑，HOL 的 session
    只有 4 处（λ 元组模式 `λ(x, y).x`、`∃⇩F w in (at z).g w` 等），另有教程 6 处。点后留空白的通常写法 4,978 处，不计 Class.thy 时不留空白的占 0.8%。AFP 245 处（文本层 413，
    其中 Featherweight_OCL 的 110 处用的是它自己以点开头的分隔符如 `.boss`，不是单个点、不受影响）对通常写法 38,670 处，约 0.6%；大头是 AWN/AODV 进程前缀
    `send(_).p` 一类用户记法（155）、Ott 生成的 LightweightJava `%((x::t),(y::t)).x`（43）、S_Finite_Measure_Monad 里同一写法 54 处。这些只在该 theory 打开开关时才受影响。
    `.ML` 里的 term antiquotation 0 处。全表 `isabelle_src.tsv`、`afp.tsv`。
    原型（11-10，`step1/proto_onepass/`，`proto.diff`；cslh19 加锁计时，但另一用户的 PyTorch 作业占着计时 CPU，门禁只查构建与求解器没拦住，绝对值有噪声、比值正倒两次相差 1–3%）：
    整体读一个括号形式的 term（解析加检查）是原版读显式写法的 **0.95–1.09 倍**；只看解析 1.08–1.58 倍（旧的两次解析 10.7–13.4 倍、分组过滤 5.7–6.6 倍）；开关打开、
    无点文本上标点扫描每条约 0.19 µs，占 tokenize 加解析的 0.2%（单看 tokenize 一行是 +2%，按规则 (2) 不通过，列给用户）。代码：对 fix_rev1b 加 `syntax_phases` 净 −67 +36 行，
    过滤、权重、`field_dot` 兼当 "." 的分支、`Lexicon.dot` 都删掉；`_dot_field` 产生式只在后面还有 `field_dot` 时才预测（"下一个 token 是 `field_dot` 才预测"做不到——产生式
    要在点之前、内层 term 开始处就建）。测试：与 fix_rev1b 的差别都是本条预期的后果（`{(x::nat).x > 0}` 静默改读、`∀(x::nat).x > 0` 报错带说明等），无 bug；开关关闭与无点
    语料 0 处不同；括号形式各测试同前。它另提：两个 Earley 实例现在只差"后面还有 `field_dot` 时预测那两条产生式"，可以不要 functor、只留一个解析器。
    **用户 11-10：(a) 接受开关打开时标点扫描的开销（每条约 0.19 µs、tokenize 一行 +2%）；(b) "很倾向于取消" functor，先测开关关闭时第一次解析的开销。**
    不要 functor 的原型（11-10，Opus agent，`step1/proto_single/`，`single.diff` 对 proto_onepass、`stock.diff` 对原版）：`parser.ML` 回到原版那样一个封装的
    `structure Parser: PARSER`，没有 `Parser_Base`、没有 functor；`Parser.parse` 多一个参数 `{field_dots: bool}`，为 `true` 时解析器自己在输入里找最后一个
    `field_dot` 的下标，为 `false`（开关关闭或文本里没有 `field_dot`）时不扫，原版那条路上只多一次惰性的整数比较。这个接口我按授权定（下标必须按解析器自己
    的输入数，交给调用者算可能拿错 token 列表）。行数：`parser.ML` 原版 790、proto_onepass 853、它 825；`syntax.ML` 与原版只差一行（`parse` 的类型）；
    `syntax_phases.ML` 对 proto_onepass 改两行。正确性：tests/parse 与 tests/scope 的 25 个结果文件与 proto_onepass 逐字节相同；2026 语料上第一次解析的四个
    副本都与 Pure 自己的解析得同一摘要。测试只改了 API 消失后用不了的几处（`adapt_tests.py`）。**决定性的计时（开关关闭的第一次解析对原版副本，规则 (2)）
    还没测成**：另一用户的三个 PyTorch 作业不绑 CPU，一直被调度到计时 CPU 8、9、12、13 上，新加的忙线程检查让计时排队（cslh19 上脱离会话运行，
    `step1-proto-single/g6parse/results/`；第一次排队等满 1.5 小时没有空闲窗口，06:38 UTC 放弃，06:39 重新排队、最多等 4 小时，10:39 仍无窗口；10:44 再排队、最多等 12 小时）。作业 19:20 UTC 前后结束，计时随即跑完（四次都 VALID，`step1/proto_single/g6parse/results/`）：
    **开关关闭的第一次解析 S/A 正 1.002、倒 1.003，波动范围 1 ± 0.005，规则 (2) 通过**；带 functor 的版本的原版实例同一范围内是 1.012、1.007（不通过，只作参考），
    即去掉 functor 后原版那条路反而更近原版；两次各副本的解析树都与 Pure 自己的解析相同。括号形式各行（只看解析）S 比带 functor 的版本快 2–4%（S/P 0.958–0.982），
    对原版读显式写法 1.08–1.57 倍（`(p).x` 比 `x p` 多 4 个 token，项越长越接近 1）。`make_gram` S/A 0.985–0.988（只报告）。
    **按用户"很倾向于取消"与"在波动范围内就去掉"，去掉 functor：并入时用 `proto_single`。**（此前的烟测不作数：作业在跑、两进程并行、不在计时 CPU 上，S/A 0.98–1.01。）
    另：它发现 proto_onepass 的 `analyze.py` 按行名 `fp.parse` 核对"与 Pure 相同"，而那个原型的行名是 `op.parse`，所以那句核对什么都没查；它手核了 TSV，结论成立。
    （补记 2026-11-14：当时只测了真实 HOL 文法上的第一次解析与括号形式各行，没测解析器在人造文法上的那组行（`G6_Parser_Rows`）；第三轮 G6 里那组有 9 行
    慢 0.2–3.7%，按第 28 条接受，§6.11 末。）
28. **计时超标不到 10% 一律接受**（用户 2026-11-14 "小于 10% 的超标都可以接受"，看完第三轮 G6 的结果后说；修订第 24 条的规则 (4) 与 6.8）：任何一行比它的
    门槛超出不到 10% 就接受，不报、不修。门槛按"每个标识符、每个常量、每条登记多几 µs"写的行，按换算成整段输入的倍数判（我这样理解并报用户，用户随后
    "可以写进计划"）。第三轮里换算后仍超 10% 的只有 Reg.R1（登记字段每条 0.83 µs 对已批 0.56 µs；2.8 万条共 23 ms），第二轮起用户已接受（第 25 条 (5)）。
    **同日另一条（用户）：与文档、测试相关、不改变设计的事，我可以自决，不用用户批准**（此前用户 11-13 定"没有我的批准不准随便改计划文件"；本条之后，
    记录、改正与不改变设计的文档改动我自定，改变设计或新的设计元素仍先问用户）。
29. **文案过目的决定**（2026-11-14 起；全部文案与真实渲染在 `step1/texts/TEXTS_REVIEW.md`，条目号如 A14 指该文件）：
    (1) **A14**（第一段是局部变量、整个标识符又是常量，字段访问失败；§1 第 16 条承诺过、代码里没有的那段）：用户给的写法，经两处小改（双引号、"write"、
        分两行）定为
        `"point.xpos" is not a field of the local variable point :: bool⌂` / （类型有字段时照旧一行 `Fields of …`）/ `If you meant the constant "point.xpos", write "CONST point.xpos".`
        歧义那一种（第 5 步）的写法待用户答。
    (2) **凡是让用户照抄去写的东西一律加双引号**（用户："警告文案也要加引号。都要加"）：包括已批的警告文案（`or "CONST config.timeout" to keep the constant …`）
        与所有待定文案里的 `CONST …`。

## 2. 已核实的事实（读代码或实测）

- 词法：`r.xpos` 整体是一个长标识符 token（`src/Pure/Syntax/lexicon.ML:106`）；所以 `λx.x` 今天就是
  语法错误，而 `λ(a, b).a` 今天能解析（实测）。
- 名字解析：带点的名字永不当变量（`src/Pure/Isar/proof_context.ML:381`）；今天 `r.xpos`（`r` 是变量）
  报 `Undefined constant`（实测）。所以给它新含义不改变任何今天能通过的文本（前提：已有常量优先）。
  （第 9 条改为局部变量优先后这个前提不再成立；开关打开时改变的文本见 §6.7。）
- 拆分必须在 `abs_tr`（`src/Pure/Syntax/syntax_trans.ML:134`）之前完成，`λt. t.xpos` 的 `t` 才能被绑定；
  `ast_to_term` 先翻译参数再翻译外层（`syntax_phases.ML:246-257`）。（第一版的做法：`ast_to_term` 里先把第一段作为变量放进 term，
  让 binder 绑定它，读法到 `decode_term` 再决定，§6.3.1。）
- 每个语法常量只能挂一个 parse translation（`src/Pure/Syntax/syntax.ML:418-426`）；原型占用了
  `_constrain` 这一个位置。源码实现应放进 `decode_term`（`syntax_phases.ML:304`），那里有外层绑定变量
  列表与固定变量表。（第一版不在绑定变量列表里按名字查找，见 §6.3.1。）
- `decode_term` 对每棵候选语法树各跑一次（`syntax_phases.ML:415`）。
- 第 0 级循环：不用 dot 语法时也跑 2 轮；每多一层需要替换的链多一轮（最初原型的做法；第一版在推断内部选字段，见 §6.5）；adhoc_overloading 同样
  （实测：`size_of (3::nat) + 1 = 2` 跑 3 轮）。
- 先例：adhoc_overloading（第 0 级选、第 1 级报未解析，`adhoc_overloading.ML:221-222`）；
  coercions（第 −100 级自带推断并在推断中改写 term，`src/Tools/subtyping.ML:805-889`）。
- record 类型是嵌套的扩展类型，最外层名字是根 record 的扩展类型：
  `cpoint = Type ("…point.point_ext", [Type ("…cpoint.cpoint_ext", [unit])])`（实测）。
  因此子 record 字段的模式类型是父 record 字段模式类型的实例。
- 子 record 可以重新声明父 record 的字段名（实测），只遮蔽短名；同一 theory 内后声明者胜出；
  跨 theory 时 `imports` 里排在后面者胜出（两个 theory 的实测）。声明时 Isabelle 不给警告。
- 两个 record 有同名字段后，原生的构造语法 `⦇xpos = 0, ypos = 0⦈` 和更新语法 `r⦇xpos := 1⦈` 也会坏
  （实测，与 dot 语法无关）。
- 加一条 `(e).f` 文法规则会让 `{x. P x}`、`{(x, y). P}` 产生两棵语法树（实测歧义警告）。
- Pure 的 `Net` 自带 `encode_type`（`src/Pure/net.ML:67-70`）；iNet 的改进针对 λ/eta，与类型无关。
- `CONST x.f` 在 AST 层就被解析成标记过的常量（`syntax_phases.ML:922-929`），不会进入拆分逻辑（读代码；第四轮实测
  `λb. CONST b.E` 得常量，`reviews/round4/localfirst/VERIFY.md` §2.3）。
- Isabelle 合并 import 时，configuration option 的值只看显式设过的 theory，值不同时 `imports` 里靠前的胜出（`config.ML` 的
  `Inttab.merge (K true)`；实测 `probes/config_merge/`）。
- 有多棵语法树都能 decode 时，`parse_term` 逐棵做类型检查：恰一棵通过就用它（带歧义警告），零棵报错，多棵报 "Ambiguous input"
  （`syntax_phases.ML:404-456`）。
- 读位置、去掉位置的翻译（`Term_Position.strip_positions` 等）扔掉位置后，括号里的名字没有前端标记（不上色、不能悬停与跳转），
  记号的标记保留（实测 `reviews/round4/localfirst/render/W_Strip.log`）。

## 3. 待定事项与过程记录

（2026-10-31 通读后注：§3.1–§3.3a 写于 10-28 至 10-30，其中的"待定"现都已定下，各小节开头注明结论在哪里。2026-11-02 补注：§3 全部是
过程记录，其中写作"已定""批准""我按授权已定"的内容若与 §1、§6 不同，一律以 §1、§6 为准，例如登记用命令、bundle、打印时换绑定名、
coercion_args 修法 B/C、第 0 级重建载荷、D14 的重跑与 d14on、列表 10 条、"目标是否改为 Isabelle2026 待问"、2025-2 的树与流程。仍需用户回答的事
集中在 §6.11 末尾。）

### 3.1 警告——已批部分见 §1 第 8 条，以下待定

**现状（2026-10-31）：** 对象规则与切分已按 §1 第 8、16 条定下（只对常量对象、按第 9 条切分）。链上某一段多候选时沿每个候选往下走，走到
schematic 类型变量的一步也算（第三轮 `reviews/round3/warn/DESIGN.md` §4；下面"走到类型变量的分支不算"的提案作废）。多候选时的末句文案随其他
文案在实现第一步后过目。警告开关已有：`dot_syntax_warning`（§1 第 14 条）。AFP 频率：静态估计 0 处已知位置（第四轮 `D-option/DESIGN.md` §6.4），
开关无法在构建时整体打开，计数改用第三步的探针比对（§6.12 第 3 步，须用户下令）。以下是原文。

- 检查阶段做不了这件事的原因：`check_terms` 开头 `prepare_positions` 已剥掉位置，term 里也看不出原始写法；
  未声明类型的固定变量、λ 绑定的变量此时类型未知，所以不警告。
- 链中某一段有多个候选时，后面各段如何继续（我的提案：沿每个候选分别往下走，凡是能走到最后一段的读法都列出；
  走到类型变量的分支不算）。
- 多候选时的文案（我的提案：末句改为 `Write one of these terms to mean the field access, or CONST … to keep
  the constant without this warning.`）。
- 解析一侧的拆分是否也改成"只有最左一段当对象"（原型现在用"最长的、本身是常量的前缀"当对象，
  例如 `Split_Show.origin.xpos`），以与警告的切分一致。
- AFP 测量（用户 2026-10-28 同意：在 cslh19 上起一个 Opus agent 测量警告的触发频率）。
  cslh19：24 核、62 GB；有 `~/Current/MLML/contrib/Isabelle2025-2` 与 `afp-2026-05-13`
  （该目录在 cslh19 上不是独立 git 仓库，`git log` 显示的是 MLML 的提交）。
  测量需要在每条 term 的解析中装上探测代码并处理 AFP theory，即需要 `isabelle build`，
  按 CLAUDE.md 须用户明确下令；范围、是否用独立副本、探测代码装在哪里（Pure 的 `decode_term`，
  或 HOL 里一个 `_constrain` parse translation）待定。AFP 里没有任何显式登记，测量只覆盖 record 字段。
- 是否提供关闭警告的配置项（名字待定）——视测量结果而定。

### 3.2 登记冲突的处理——探测方法已演示；用户 2026-10-28：可以做，不做也可以；处理方式待批

**现状（2026-10-31）：** 按授权定为第三轮登记设计的做法（§6.4）：冲突用"β-η 正规形下的类型实例"这一个关系分类，只对显式登记报告；
`record` 命令不发冲突警告；不做 theory 合并后的检查。报告的四条文案随其他文案在实现第一步后过目。以下是原文。

- 登记时用新登记的 key 查 Net，取同名、term 不同的已有登记，用 `Sign.typ_instance` 比较模式类型：
  模式相同（互为实例）→ 两者永远歧义；新的更具体 → 新的永远选不上；新的更一般 → 旧的永远选不上；
  可合一但互不为实例 → 交叠部分的对象歧义。
- 完全相同的登记（同名同 term）视为重复登记，不报冲突（用 `Net.insert_term_safe`）。
- record 的覆盖正是"新的更具体"：按已批规则，`cpoint2.xpos` 永远无法用 dot 语法选中。
  record 字段之间只会出现这一种关系（推理，未实测）。
- 探测的盲区：theory 合并（两个 theory 各自登记，第三个同时导入）——可用 `Theory.at_begin`
  （`src/Pure/theory.ML:27, 186`；先例 `src/Pure/thm.ML:2716`）在合并后检查"没有在任何一个父 theory 里
  共存过"的登记对；带 sort 的模式类型在后来的 `instance` 声明后可能产生新的实例关系——登记时探测不到。
  两种盲区都由使用时的歧义报错兜底。
- 我的建议（未批）：用户的显式登记遇到"模式相同"或"永远选不上"→ 报错；"交叠"→ 警告；
  record 包的自动登记（覆盖）→ 只警告，不能挡住 `record` 命令。

### 3.3 其他未定

**现状（2026-10-31）：** 下列各项都已定：不要 Lean 式命名空间规则；不打印回 dot 语法；支持 `(e).f`（§1 第 13 条）；登记接口是命令
`dot_field` / `no_dot_field`（名字随文案过目）；locale 里登记随 morphism 走并加遮蔽规则；字段名放在载荷里（§6.3.3），与 HOL 无关。
详见 §6.3、§6.4。以下是原文。

- （已定，见 §1 第 9 条）常量与局部变量的优先级。曾考虑过的"局部变量优先"方案，留作记录：
  把拆分放进 `decode_term`，那里向下遍历时维护着外层绑定变量名的列表 `bs`（`syntax_phases.ML` 的
  `decode _ qs bs (Abs …)` 分支）；最左一段是外层 λ 绑定变量 → 对象为 `Bound i`，是固定变量 → 对象为
  该 `Free`；未固定的隐式自由变量不算局部变量（否则 `List.map` 也会被拆开）。
- （已定，见 §1 第 12 条）选字段放在哪里。
- 有了显式登记以后，是否还保留 Lean 式自动命名空间规则（`T.f` 自动作为字段）。
- 输出是否打印回 dot 语法。
- 是否支持 `(e).f`（代价见 §2 的歧义实测）。
- 登记接口（命令还是 attribute、名字）。
- 在 locale 里登记时，登记的 term 随 morphism 变换。
- 原型用 HOL 字符串字面量携带字段名；Pure 实现需要换一种与 HOL 无关的方式。

### 3.3a ESR v2（2026-10-30 完成的一轮，待用户决定）

- 规格：`reviews/brainstorm/ESR2_SPEC.md`（英文，含两种推断的伪代码、数据结构、Pure/HOL 挂接点、不变式、
  重新推断的清单与上界、报错文案、覆盖分类、测试计划、待决问题 D1–D15）；原型 `reviews/brainstorm/esr2-spec/`
  （最终版本）、`reviews/brainstorm/esr2/`；cslh19 实测 `reviews/brainstorm/measure-esr2-cslh19/`。
- 嵌套 coercion 超时已查清并修复（v2 在各深度为原版 Isabelle 读显式写法的 1.08–1.13 倍）；嵌套 λ 在不开前瞻时仍随层数增长。
- 规格里有一种超出 §1 第 12 条的重新推断：local coercion insertion 失败后，为了得知字段选择，对整个 term 运行
  global algorithm，每层相互依赖的字段一次（D12）。需用户决定。
- 用户尚未决定 D1–D15；在决定之前不把规格写进本文档正文。
- （2026-10-31 注）D1–D15 已由用户的决定（§1 第 12、15 条与 §3.3b 记录的各次答复）与授权定下；按 ESR v3 写成的第一版设计见 §6.5。

### 3.3b ESR v2 方案初稿与待决事项（2026-10-30，压缩上下文前整理）

（2026-10-31 注：本节是 10-30 至 10-31 的过程记录，按时间顺序写；其中的"待决""待批""待用户决定"都已在 §1 第 12–16 条与 §6 定下，
不再有效。当前设计以 §6 为准。仍待用户回答的事见本节末尾"压缩上下文前的完整清单"里的状态注与 §3.4 末尾。）

**算法初稿**（细节见 `reviews/brainstorm/ESR2_SPEC.md` §4–§9）：
- 载体：Pure 常量 `dot_access`，载荷是一个按 `dot_field.f` 编码的 `Free`，替代原型的 HOL 字符串。
- 标准推断（coercion 关闭）：节点处能决定就决定；否则字段等待、结果类型为 rigid type variable；对象类型确定后用合一补上，不重新推断。
- coercion 推断（`src/Tools/subtyping.ML`）：同上，字段后来才能选时，重新推断包含它与确定它那一步的最小函数应用；
  字段等待期间遇到类型冲突，不重新推断参数子 term，而是在已推出的结果外套转换函数（这是嵌套 coercion 超时的修复）；
  local coercion insertion 失败时，用 global algorithm 得知字段选择（整个 term，每层相互依赖的字段一次），再在显式写法上运行原有推断；
  最后检查：每个选择在对象最终类型上按选择规则重选必须相同。
- 挂接点：Pure 的 `pure_thy.ML`、`syntax_phases.ML`（`decode_term`、stage 注册）、新文件 `Syntax/dot_field.ML`、
  `type_infer_context.ML`；HOL 的 `subtyping.ML`（`generate_constraints`、`process_constraints`、`coercion_infer_types`）、`record.ML`。
- 实测（cslh19 空闲，`reviews/brainstorm/measure-esr2-cslh19/`）：不含 dot 1.01；当场能选 0.89–1.07；后来才选多为 1.03–1.98；
  嵌套 coercion 1.08–1.13；嵌套 λ（不开前瞻）2.57/4.28/8.02（16/32/64 层）。约 9 万对用例无一结果不同；
  coercion 打开的 33,153 对里只有 dot 写法报错 110 个，缺陷 0 个（分类见规格 §12）。

**用户 2026-10-30 的授权（三轮验证之后）：** "这些问题我觉得可以全部交给你……具体如何找到最佳的实现我全权交给你。
你可以随便改变我之前的建议等，只要保持我们的需求不变。请继续设计，但任何对性能或功能的妥协都必须经我批准。请积极 run Opus agents。"
据此（我的决定，2026-10-30）：
- 前瞻 D5 采用，带裁决 agent 的三处修改；允许它把"不开前瞻时 ESR 的误拒"变成与原版对显式形式一致的结果
  （"判定不得改变"原是我给验证写的条件）。
- D3 采用"重新决定，失败时退回默认做法的路"（`dot_optb_fix = "judge"`）；local pass 结束时仍有字段在等待时走默认做法的路
  （`dot_optb_wait = "default"`）。报错路径变慢（约为默认做法的 1.1–2 倍）属于性能妥协，连同其余妥协一起请用户批准。
- D6 采用（证明等价、改动 5 行、ESR 上约快 4%）。
- 需求（不变）：每个被接受的 term 等于原版对显式形式 E(C) 的推断结果（aconv，含类型，coercion 开关两种）；每个选择等于
  已批规则在对象最终类型上的选择（D1 不启用，D15：字段检索不考虑 coercion）；不含点语法的文本行为与开销同原版；
  其余变慢与误拒都是妥协，须列出请用户批准；用户可见文案由用户批准。

**用户 2026-10-30 的决定（授权之前）：**
- D12（local coercion insertion 失败后，对整个 term 运行 global algorithm 得知字段选择）：接受。
- D2（coercion 关闭时标准推断的位置）：先按 stage 0 走（并入原版 stage 0 的标准推断）；之后补原型，再由 agent team 验证。
- D5（前瞻：按 binder 预期类型提前选字段）：交由 Opus agent team 验证，通过则采用，有问题再讨论能否修复。
  **验证结果（2026-10-30，`reviews/brainstorm/LOOKAHEAD_REPORT.md`）：按规格的写法不通过；裁决 agent 做了三处修改，
  修改后除下面"剩余"一类外全部通过，提速保留。待用户决定（见下）。**
  - 问题 1：前瞻做出的选择被记成"在节点按原版局部类型做出、有约束力的选择"（不设 `tainted`），使后面无关的决定变成最终报错。
    例 `(λu. u.xpos) r = k ∧ (λt. t = n ∧ t.mag = k) k`：前瞻关时接受，开时报 `"t.mag" is neither a constant nor a field of t :: nat`。
    修改 (a)：把前瞻选择记成它所替代的 late choice（进 `late`，不进 `binding`，设 `tainted`）。
  - 问题 2：参数带 sort 的类型约束（`λt::_::ring`）被当作透明，前瞻按裸预期类型选字段：`(λt::_::ring. t.ee) n` 选了 `dd3n`，
    误报 `No type arity nat :: ring`。修改 (b)：仅对前瞻，参数带 sort 的约束不算透明；global algorithm 的 `own_type`（D8）不变。
  - 问题 3：前瞻在决定不了任何字段的调用上也做逐节点工作，开销 4–5%，与规格 §13.3 不符。修改 (c)：没有字段访问的调用不扫描；
    没有合格 binder 时不做逐节点工作；`domain_expect` 先查是否 λ 再规范化类型。不改变任何结果。
  - 修改后（cslh19，506 个进程）：现有测试集两种 coercion 模式、对抗探针、2,700 个随机 binder 项，判定与接受项 0 处改变
    （剩余一类除外）；审计 13,631 个前瞻选择，没有一个被最终选择推翻。提速：嵌套 λ k=128 从约 14–16 倍原版降到 1.10–1.13 倍，
    let 链 k=96 从约 14 倍降到 1.27–1.31 倍；不含点语法的文本开销从 1.01–1.05 倍回到 1.00 左右。计时时 cslh19 负载很高，
    比值是同进程交替测得，建议安静时复测一次再写进规格。补丁 `reviews/brainstorm/lookahead-judge/fix/lookahead_fix.diff`（+48/−32）。
  - 剩余：15 个探针情况（`LB_J` 8、`LB_J2` 6、`LB_K` 1），例 `Fpp (λt. (t.xpos, 1::nat)) ∧ wq.wfn 3 = k`：不开前瞻时 ESR 误拒
    （blocked step 的合一失败后冻结 binder 参数，字段只能交给 global algorithm 去学，而它做不了运算符 coercion；规格 §14.3 的限制，
    涉及 D7），开前瞻时得到与原版对显式形式完全相同的结果。前瞻内部无法消除这一差别，只有改 D7 才能让不开前瞻时也接受。
  - 待用户决定：① 是否允许前瞻在"误拒变成原版结果"时改变判定（"判定不得改变"是我给验证写的条件，不是用户的原话）；
    ② 三处修改是新设计元素，是否批准；③ `tainted` 是否应影响无关子项（`(λu. u.xpos) r = k ∧ S` 接受而 `S` 单独被拒，
    `S = (λt. t = n ∧ t.mag = k) k`，这是不开前瞻时 ESR 本身的性质，与 D3 相关，等 D3 报告一起讨论）；
    ④ 测试计划补上 `LA_Battery`、`LA_Mut`、`LA_A1`–`LA_A3`、`LA_X`、`LB_C`、`LB_M`、`LB_J`、`LB_Fuzz` 和审计检查。
  - 旁见：不开前瞻时 `(λt. t.ih) [n]`（`ih` 只登记在 `hd :: int list ⇒ int`）被接受为 `hd (map int [n])`，
    与 D15 里 `(λt. t.sqrt) n` 被拒是同类情况，结果却相反。
- 拒绝把"始终用中文回复"写进记忆。
- D13（三处改动，一条路径约慢 0.15 倍）：接受。D7–D10（四处修补）：接受。
- D15：确认。对字段的检索不考虑 coercion，`(λt. t.sqrt) n`、`map (λt. t.neg + x) ns` 报"没有这个字段"。
- D1：始终不启用"字段名只有一个登记时直接选它"（开关 `dot_singleton` 保持 false）。
- D3：采用"local coercion insertion 失败时一律由 global algorithm 重新决定"（开关 `dot_local_typing=false`），前提是通过
  Opus agent team 验证。
  **验证结果（2026-10-30，`reviews/brainstorm/D3_REPORT.md`）：原型的实现与按用户原话的做法都不通过；加一个补充后通过，
  但补充偏离用户原话，待批准。**
  - 原型的实现接受错误的项（118 个对抗探针中 26 个与原版对显式形式的结果不同）。例 `t = v ∧ Pn v ∧ t.gi = k ∧ Pi t`
    （`gi` 只登记在 `int`）被接受为 `gi t`、`t :: int`，而原版对显式形式给 `t :: nat`、`gi (int t)`。原因：原型假定"local pass
    失败而没有字段在等待时，原版对 E(C) 的 local pass 也在同一步失败"，这只在失败是类型冲突时成立，规则报错时不成立
    （`esr2-spec/eng/subtyping_esr2.ML` 1643–1666 行）。修正不改设计：只在失败是类型冲突时跳过 E(C) 的 local pass。
    原型还没有照用户原话做：先用节点上的选择跑一次 global algorithm，最后检查推翻时才重新决定，因此
    `(λt. t = n ∧ t.dd = k) k` 被拒；同一修正一并解决。
  - 按用户原话的做法（每次失败都重新决定）不会接受错误的项，但比默认做法多拒 5 个本应接受的项，例
    `t = v ∧ Pn v ∧ t.dd > 0 ∧ Pi t ∧ (λs. s.dd > 0 ∧ s = n) k`：global algorithm 在点语法形式上（字段尚不提供约束）推出
    `t :: int` 而选 `dbl_i`，原版对 E(C) 的 local pass 却成功并给 `t :: nat`，最后检查推翻 `dbl_i`。另外，两种做法都拒绝的
    46 个探针中 44 个报错文案与默认做法不同，15 个明显更差（10 个露出 `dot_access` 载体，3 个怪错字段，2 个说类型未知）。
  - 补充（裁决 agent 的原型，`reviews/brainstorm/d3-judge/eng/judge.subtyping.diff`，+60/−16，开关 `dot_optb_fix = "judge"`）：
    按用户原话重新决定并跑原版对 E(C) 的推断；若这条路拒绝，再走默认做法的路，用户看到的是默认做法的结果（项或报错）。
    结果：凡按原话的做法接受处给出它的项，凡它拒绝处给出默认做法的结果，0 例外；相对默认做法 0 个错误项、0 个新增拒绝、
    0 处报错文案改变；新接受输入集里预期的 15 个、扩展集 27 个、探针 31 个，均与原版对显式形式一致且是规则在最终类型上的选择。
    **偏离用户原话（"一律重新决定"），需要批准。**
  - 重新决定这种做法本身带来的含义改变：12 个探针两种做法都接受但项不同，例 `t = v ∧ Pn v ∧ t.dd > 0 ∧ Pi t ∧ n + j > 0`：
    默认给 `t :: nat`、`dbl_n t`；重新决定给 `t :: int`、`dbl_i t`。无关的 `n + j > 0` 使原版 local pass 失败、改用 global
    algorithm 为整个项推断类型，重新决定的做法让字段也跟随这一类型。两者都与原版对各自的显式形式一致。
    作为交换，消除了默认做法对合取顺序的依赖（`(λt. t = n ∧ t.mag = k) k` 默认被拒，`(λt. t.mag = k ∧ t = n) k` 被接受）。
  - 用户原话未覆盖的情况：local pass 没有失败但结束时仍有字段在等待（输入集 151 次）。裁决 agent 建议走默认做法的路
    （开关 `dot_optb_wait = "default"`），实测在所有集合上都不改变任何结果。
  - 开销（cslh19 高负载，同进程交替测比值）：两种做法都接受的形状上与默认做法相同（0.82–1.28 倍，只两行超过 1.08）；
    重新决定改变路径的常见形状 0.95–1.20 倍；最后检查推翻的形状比原型快；拒绝时要再走一遍默认做法的路，报错耗时约为默认做法的
    1.1–2.0 倍（输入集 3,770 次读取走此路，都是拒绝）。规格 §15.3 的计时门槛没有报错路径一行，采用时要补上。
  - 测试：C4、G2–G5 这 5 个项能抓到"重新决定后跳过最后检查"的变异（此前没有用例抓得到），应进入规格 §15.2。
  - 前瞻（D5）与 D3 的修正是分别在 s1 上验证的，两者合在一起尚未验证。
- D6（`update_coerce_arg` 逐层记下函数头与参数个数）：交由 Opus agent 验证，通过则采用。
  **验证通过（2026-10-30，`reviews/brainstorm/D6_REPORT.md`），按用户决定采用。** 要点：
  - 与原版在任何项上算出相同结果（报告 §1 结构归纳证明；穷举 28,175 项、随机 30 万项、真实输入约 297 万个运算符，0 处不同）；
    154 个任务开关两种状态输出逐字相同；6 万多条无点语法输入经原版、对照副本、D6 副本三方结果相同。
  - 改动：`update_coerce_arg` 内删一行、加五行代码与两行注释（`reviews/brainstorm/d6-verify/stock/D6.patch`）。
  - 收益比此前估计的 5–10% 小：原版本身测不出差别（长度 1000 的 spine 也一样，耗时在别处）；ESR v2 在嵌套 λ 与长 let 链上约快 4%。
  - 测试缺口：154 个回归任务抓不到"约束结点截断 spine"这种错误读法（批量测试里带 `coercion_args` 的头部只有 case 常量，
    且不带约束），实现时的测试要包含带约束的、有 `coercion_args` 声明的头部。
  - 顺带发现的原版问题（与 D6 无关，D6 下表现相同）：`max ((n :: int) + (2 :: nat) :: nat) (h3 (2 :: nat) m n)` 让
    `COERCION_GEN_ERROR` 作为未捕获异常漏出（subtyping.ML:677 `gen_coercion`）；`coercion_args h3 + - 0` 下 `h3 n n n`
    仍被接受为 `h3 (int n) (int n) (int n)`（借位置约束把 `h3` 本身当函数做 coercion），给 `h3` 写明类型或不带位置注记时则被拒绝。
- 报错里 "Fields of T: …" 目前列出全部字段、不截断（原型 `Esr2_Base.thy:231`）；字段很多时如何省略，随 D4 文案一起讨论。

**压缩上下文后要讨论的：**
- D4：新报错情况的文案（最后检查推翻选择的三条、标准推断后来才选合一失败的一条、兜底 "Unresolved field access"），以及 D11。
- D14：对象类型只能靠 adhoc_overloading 确定时，报错还是留到 stage 0。
- 第一次设计评审（`reviews/JUDGE_REPORT.md`）中仍未定的：长标识符在何处拆分（推荐 `ast_to_term`、只取最左一段、如实写明弱化后的兼容性承诺）；
  报错的位置与补全；在 locale 里登记以及命令还是 attribute；警告的四处缺口（对象范围、参数、可见性与开关、测量方式）；
  测试章节与 required sessions；Lean 式命名空间规则（推荐不要）；打印回 dot 语法（推荐不要）；§1 第 2 条的复用说明；链中位置的后果。
  以及该评审"自行决定后再送审"的 8 项（`reviews/brainstorm/../JUDGE_REPORT.md` 与 `reviews/debate_result.json`）。
- 下一步：用户定完以上各项后，由我亲自把 ESR v2 写进本文档正文，再连同第一次评审的遗留项送一次聚焦评审。

**压缩上下文时（2026-10-30）仍在后台运行的验证**（完成后用中文汇报，通过即采用）：
- 前瞻 D5：已完成（见上）。计时在 `reviews/brainstorm/measure-lookahead-cslh19/` 与 `reviews/brainstorm/lookahead-judge/out/timing*/`。
- D3（`dot_local_typing=false`）：已完成（见上）。计时在 `reviews/brainstorm/measure-d3-cslh19/` 与 `reviews/brainstorm/d3-judge/timing/`。
- D6 已完成（见上）。计时在 `reviews/brainstorm/measure-d6-cslh19/`。
- 三轮验证都已完成（2026-10-30 约 08:00 UTC），本机与 cslh19 上没有留下进程，本机负载监视器已停。
  下次起 agent 跑 Isabelle 时再挂：本机出现工作目录在 `contrib/dot_syntax` 下的 `poly` 进程时通知
  （只看这个目录，因为本机还有别的会话在跑 Isabelle）。

**第三轮（2026-10-30 08:35 UTC 起，8 个后台 Opus agent，用 `ListAgents` 找回）：** 目录 `reviews/round3/<子目录>/`。
- 分两个阶段（用户 2026-10-30 选"先只做设计，等空闲再跑"）：第一阶段只读代码、设计、写原型与测试 theory，任何机器上都不启动
  Isabelle（cslh19 被用户的 SMT 测试占满，本机是用户的笔记本）；第一阶段完成后各 agent 停下汇报。后台检查在 cslh19 空闲
  （负载 < 4、没有 z3/cvc5 等进程、没有 smtbench/mirabelle）时通知我；届时用 SendMessage 让各 agent 进入第二阶段（在 cslh19
  上运行验证），并给出资源规则（每个 agent 最多 2 个并发进程，`nice -n 10`，`taskset -c 0-7,10,11,14-23`；计时依次、
  只用 CPU 8、9、12、13）。
- 引擎组：`s2/`（把 s1、前瞻三处修改、D3 修正与补充、D6 合成一个引擎 s2，并备好合并验证）；`rerun/`（规格 §14.1、§14.10：
  late decision 反复重新推断造成的增长）；`learning/`（§14.2 learning rounds、§14.3 global algorithm 的固有限制与 D7、§14.7、
  D3 补充的报错路径开销）；`stage0/`（D2 并入 stage 0 的标准推断、D14 adhoc_overloading 对象、coercion 关闭时报错露出载体、
  载体不外泄的保证放在哪里）。
- 衔接组：`parse/`（长标识符在哪里拆、分段规则、兼容性、`(e).f` 的词法改动、载体内容与位置/补全）；`registry/`（登记接口、
  locale 与 interpretation、同一性与包含关系、record 钩子、登记冲突、命名空间规则、打印回 dot 语法）；`warn/`（§1.8 警告的
  实现、开关、AFP 测量计划）；`tests-texts/`（测试与实施步骤、所有用户可见文案的清单，供 D4、D11 文案评审）。
- 各 agent 的任务说明里写明了需求 R1–R6 与授权规则：不得悄悄引入妥协，剩下的妥协要列出大小与替代方案；文案只作提案。
- `tests-texts/` 第一阶段完成（`TEST_PLAN.md`、`TEXTS.md` 29 行文案清单、`Texts_Probe.thy` 未运行）。要点：
  前瞻修正、D3 补充、D6 从未一起跑过；D2 放进 stage 0 无法在用户空间测试（同一 stage 内按注册顺序执行，
  `syntax_phases.ML:1014-1021`，用户空间加的 check 总在原版 "standard" 之后），只能在私有树构建后验证（待 `stage0/` 确认）；
  `dot_field.ML` 在 Pure 的 `ROOT.ML` 中先于 antiquotation 加载，只能用 `\<^here>` 与 `@{make_string}`；原型的 coercion 副本只声明了
  3 个 coercion、3 个 map，step 1 必须重放 HOL 全部声明；`record` 命令若对登记冲突发警告，会改变无点语法文本的输出（需批准）；
  误拼的带限定名常量失去今天的 "Undefined constant"、位置与补全（用户有三个工具按 `^Undefined constant` 匹配）。
  其 §9 列出需用户下令的 9 次构建，§10 列出 10 个问题（required sessions、是否建 golden、回归范围、AFP 运行、计时门槛等），
  待其余 agent 完成后一并整理。
- `stage0/` 第一阶段完成（`DESIGN.md`、`src/pure_stage0.diff` 未应用、`proto/` 原型与测试未运行）。要点：
  - D2：原版 stage 0 的 "standard" 改为 `Type_Infer_Context.standard_check`（带字段推断，再 `expand_abbrevs`），dot term 只推断一次
    （s1 两次）；无点文本只多一次载体检测。用户空间无法替换原版 check（`context_check` 每次加新条目，无法删除），原型把同一函数
    注册在 stage −1 与 stage 0 两处，语义同设计但每轮多一次原版推断，真实开销要按组件计时推算或在私有树上测（需用户下令构建）。
  - D14，coercion 关闭：stage 0 决定不了的字段留在 term 里，adhoc_overloading 解析对象常量后下一轮再决定，仍未决定的到 stage 1
    报错；预计 16 + 6 个被拒用例变为与显式形式相同。旧的朴素尝试失败原因：在原版推断之后才运行（认不出已被绑定结果类型的载体），
    或在 beta 规范化之后（访问被丢掉）；新设计让引擎作为每轮第一个 check，并检查 `expand_abbrevs` 没有丢掉未决定的载体。
  - D14，coercion 打开（20 例）：方案 α 继续拒绝；方案 β 先在嵌套流程里得知选择，再在显式形式上重跑 coercion 推断，
    这类 term 约 2–3 倍开销，R2 的"最终类型"需界定。两者都是妥协，待我综合后请用户批准。
  - 报错露出载体：加只用于输出的语法常量与 `dot_access` 的 print translation，报错里显示成 `t.xpos` / `(e).f`（用户可见，需批准）。
  - "载体不外泄"的保证：stage 1 的 `dot_unresolved`（Pure 标准阶段里 stage 1 第一个）、stage 0 检查 `expand_abbrevs` 未丢载体、
    `infer_types` 对直接调用者当场决定或报错；Isabelle 的 8 处与 AFP 约 20 处直接调用都只传 ML 构造或已检查的 term。
  - 列出的妥协：K1 D14 在 coercion 打开时被拒（20 例）；K2 无点文本每次推断与 stage 1 各多一次载体检测（预计低于噪声，可用
    `prepare` 时设的标志去掉）；K3 `termify` 里的 D14 字段被拒（无用例）；K4 字段结果用于解析另一个 overloaded 常量时多一轮 stage 0
    （估计这类 term +30%）。
  - 该 agent 自报：早期用 python/sed 改过它自己新建的 `DESIGN.md`，之后改为手工编辑。
- `s2/` 第一阶段完成（`README.md`；`eng/subtyping_esr2.ML` 尚未编译；`s1_to_core.diff` 只含设计改动 +108/−48）。两份补丁改的区域不同，
  合并后 D3 部分与 D3 裁决 agent 的改动逐字节相同。它加了四处可开关的东西（我接受，都不改变结果）：在 E(C) 的 local pass 里不做
  前瞻工作（省时）；审计按路径分开记录；A/B 对照里比较前瞻选择与不开前瞻时的 late choice（`LA-EARLY`）；D6 两种错误读法作为变异。
  交互结论：每条返回 term 的路径仍是原版在 E(C) 上的推断再加最后检查，R1/R2 保持。剩余妥协：`tainted` 在补充（退回默认做法）里
  造成的误拒，例 `(λu. u.xpos) r = k ∧ C4` 被拒而 C4 单独被接受（C4 见 D3 的验证结果）；已转给 `learning/` 一并解决
  （要求判定满足组合性：显式写出无关的访问或加无关的合取式，不能把接受变成拒绝），连同报错路径的开销。
  第二阶段约 450 个进程（3 并发约 45–60 分钟）加两轮计时；`tools/s2_check.sh` 把每项比较与各裁决 agent 测得的结果对照。
- `registry/` 第一阶段完成（`DESIGN.md` §0–14；`probes/` 用户空间原型与 P01–P10 未运行）。提案要点：
  - 底层一个 ML 函数 `Dot_Field.declaration`（随 morphism 变换的 declaration）；命令经 `Local_Theory.declaration {syntax = true}` 用它，
    record.ML 直接用它。接口：命令，关键字放在随包发布的组件 theory（session `Dot_Syntax = Pure`）里，不改任何系统 theory 的 hash；
    代价是显式登记要 import 这个 theory。attribute 也可行，但在 locale 里它存成 note，读 locale header、`rewrites`、`defines` 时不生效。
  - 第一次评审 §3"attribute 看不到 morphism"的说法不对：装着 `Token.Declaration` 的 token 能收到 morphism（token.ML:533-546）。
  - locale 中的登记随 morphism 走（含 schematic term 变量的副本才丢弃），所以能到达 interpretation、`rewrites`、改名的 import；
    Pure 给 notation 的规则会把这些都丢掉。context 自己的副本遮蔽从 theory 继承来的副本（按 serial），消除评审发现的永久歧义，
    也修掉评审推荐方案里 interpretation 后 `?'c list` 对象变歧义的问题。
  - 同一性、包含、冲突、撤销登记用同一个关系（beta-eta 规范形上的 type instance，尊重 sort）；用时去掉被包含的候选；
    存储为一个 `Generic_Data` 里的 `Item_Net`；选择与报错共用 `Dot_Field.unifier`（基于 `Sign.typ_unify`）；
    `no_dot_field` 撤销登记（`unbundle no` 同样生效）。
  - record 钩子：record.ML:2274 `put_record` 之后一行，登记自己的字段，不含 `more` 与 update 函数。
  - 冲突只对显式登记报告；不在 theory 合并后检查（避免无点文本的开销）；`record` 命令不发警告。AFP 有 10 个 record 重复父 record 的
    字段名 `nothing`（Core_DOM 等）。
  - §3.3：不要 Lean 式命名空间规则，第一版不自动登记 datatype 选择器与 map/set，不打印回 dot 语法（都是范围选择）。
  - `DESIGN.md` §10 列 14 行妥协与偏离（如：用时去掉被包含的候选改动了已批 §1.3 第 2 步；遮蔽规则是新元素；随 morphism 走多出一种
    可用 `no_dot_field` 消除的歧义；显式登记要 import 组件 theory；没有 proof 级命令；候选按登记顺序而非全名排序），
    §11 列出全部用户可见名字与 9 条文案提案（`dot_field`、`no_dot_field`、`Dot_Syntax` 等）。
- 10:00 UTC 前后四个 agent（`rerun/`、`learning/`、`parse/`、`warn/`）因网络中断停下，网络恢复后用 SendMessage 从原处继续。
- `warn/` 第一阶段完成（`DESIGN.md` 13 节；测试 A01–A62、B01–B43 与 `Warn_Perf.thy` 未运行）。提案要点：
  - 只在 `decode_term` 的 `Free` 分支、长标识符解析成常量时考虑警告，在那里记下一个 closure；与 `parse/` 的拆分（只在共用的
    `decode_free` 失败时触发）互不重叠。内部 `decode_term_warnings` 把 closure 放进每棵语法树的 `Exn.Res`，导出的 `decode_term`
    类型不变；`parse_term` 只对选中的树、在原版歧义警告之后发出，受选项与 `Context_Position.is_visible` 控制。按构造不改变 term。
  - 对象规则：保留已批规则作对照；提案放宽为"最左一段按短名在原处的含义"（最内层 binder、固定变量、常量，不含隐式自由变量），
    并加一条细化：对象类型未知时，只有标识符正是它自己那个字段的已登记选择器的全名（如 `config.timeout`）才警告。
  - 链：每个候选都往下走；类型为 schematic 类型变量的一步也算（偏离 §3.1 的提案）；读法还须符合参数个数与标识符上直接写的类型。
  - AFP 静态估计：已批规则 6 处（全是误匹配），细化后的提案 16 处（都不会触发），评审的未细化放宽最多 1,786 处（大多是把
    interpretation 前缀当变量名）；即今天的 AFP 上几乎不会触发。精确测量需一次完整 AFP 构建（用户下令），计划见其 §9.2。
  - 妥协（§10）：S0 若保留已批规则，binder 与未声明类型的固定变量对象不警告；S1 隐式自由变量（AFP 约 60 个候选）；S3 只一种分段；
    S5 翻译生成的 binder 可能截获名字查找；F1 标识符作参数时仍警告；F2 函数类型字段对自己的建议再次触发；F4 别处写的 sort 看不到；
    C1 `decode` 多传一个参数（第二阶段测开销）。
  - 用户可见提案（§8）：选项名 `dot_constant_warning`（默认开）；多读法时的末句用本文档 §3.1 的提案；可选再建议 `(config).timeout`。
- `rerun/` 第一阶段完成（`DESIGN.md`；`eng-s2/subtyping_esr2.ML`、`rerun.s2.subtyping.diff` +265/−78，未编译）。
  - 增长原因：一次重新推断要重做从 frame 入口到决定字段那一步的一段；同一 frame 里同时有多个字段在等待时，共有的那段每个字段各做一次。
    对照行（每个对象紧接着自己的字段就定下类型，64 个 late decision）只 0.98–1.13 倍，说明增长不来自决定的个数。
  - 设计（开关 `dot_defer_rerun`）：同一 frame 里还有别的等待字段能在本次遍历中决定时，推迟本次重新推断，保留 late choice 继续遍历，
    之后整个 frame 只重跑一次；推迟的那次遍历若失败、结束时仍有字段等待或最后检查不过，就换回 s2 自己的 local pass，所以凡不成功
    的结果都与 s2 相同。R1 按构造成立，R2 的最后检查不变，R3 只在有字段等待时才多做事；成功时与 s2 相同依赖一条引理
    （§5.4 论证，未证明），第二阶段每次调用 A/B 对照检验。预计 5–14 倍的增长形状降到约 1.1–1.5 倍，昂贵子项的情形从 9.9 倍降到约 2 倍。
  - 剩余妥协：C1 每层依赖丢弃一次遍历，§14.10（一个 late field 的小 term 1.34–1.67 倍）未消除；C2 推迟后的报错路径最多多一次
    local pass；C3 左嵌套形状（每个 frame 里有很大的前缀、从不同时有两个字段等待）未覆盖；C4 引理只论证未证明。已请它在第一阶段
    继续为 C1（§7.1 对自由对象与在函数体里定类型的 binder 做前瞻式决定）和 C3（§7.3 prefix replay）写原型，并尝试把引理证出来。
  - 自报：DESIGN.md 里有三处小改动是用脚本改的，之后改为手工编辑。
- `parse/` 第一阶段完成（`DESIGN.md`；`code/parse_side.diff` 对私有树 `src/Pure` 约 +300/−55，未应用；`tests/` 未运行；`scans/`）。
  - 拆分：在 `ast_to_term` 的 `_constrain (Variable a) pos` 结点、只在解析 term 时；条件是结点带位置、`a` 是由两段以上且都不是内部名
    组成的长标识符、今天的 `decode_term` 会拒绝它。把 `decode_term` 的 Free 分支提成共用函数 `decode_free`，拆分与 `decode_term`
    都调用它，两者不会不一致。对象重建为 `_constrain (Free 第一段) 该段位置`，由现有机制绑定，不查名字。
  - 分段：只取最左一段作对象。试过的其他规则（最长常量前缀；第一段未绑定时才取常量前缀；把 theory 名当限定词）不是与已批警告的
    分段矛盾就是误读常见写法（AFP 有名为 C、M、T、U、G、E、K、Z、W 的 theory）。妥协 K1：`Thy.origin.xpos` 不能用，可写
    `(Thy.origin).xpos`。扫描：AFP 长标识符 21% 以 theory 名开头（165,714 中 34,784）；以 theory 限定的 record 类型常量用法最多 1,249 处；
    `R.f.g` 链在 HOL 与 AFP 中 0 处。
  - 兼容性：标识符形式只在三种情况下改变含义：今天就失败；term 级 parse translation 把非常量长标识符当名字用（静态扫描 0 处）；
    有歧义的文法换选另一棵树（需 AFP 构建测量）。括号形式按构造不改变任何今天能解析的文本。
  - `(e).f`、`[…].f`、`{…}.f`：词法把夹在 `)`/`]`/`}` 与标识符之间、两侧都无空白的 "." 标成新 token `Field_Dot`；`Parser.parse`
    先把这些点当普通 "." 解析（与今天完全相同），失败时才再解析一次，允许它开始字段访问；第二次解析里同一 Earley 项只留字段访问
    更少的状态，k 处冲突是线性开销而非 2^k 棵树。`{(x::nat).x > 0}` 第一次解析就成功，一棵树、无警告。Pure 文法加两条只用于输入的
    `_dot_field` 产生式。现有 "." 分隔符：Pure/HOL/ZF/FOL 279 个加 38 个 binder，AFP 478 个加 104 个，都不用改。
  - **改动 ESR2 §4.1 的发现：** 载荷若是 Free，凡用 dot 语法的 `fun`、`primrec`、`function`、`inductive`、`fixrec`、`partial_function`
    方程都会坏（`Specification.close_form` 在类型检查前绑定所有未固定的自由变量）。改为 schematic 变量 `Var ((载荷, 0), _)`，能经过
    该步与 `prepare_sorts`、`prepare_positions`、`prepare`、`singleton_fixate`；ESR 引擎须改用 `Dot_Field.dest_access` 读载荷。
    载荷含所写的标识符、段序号、是否括号形式、token 位置；报错指向字段那一段并带常量补全；`List.mapp` 经 `check_const` 保持今天的报错
    （测试 H 逐字节比较）。
  - 妥协（§9）：K1 见上；K2 按已批 §1.13 读作原有构造的形式，除 `{(e).f}` 外还有 `[(e).f]`、`[(e).f, guards]`、`⋃(e).f`/`⋂`/`⨆`/`⨅`
    （用户只见过第一种）；K3 点前也不许空白（新设计元素，用户原话只说点后）；K4 只在 `)`、`]`、`}` 之后识别；K5 字段名是关键字时、
    以及文法里有 `].`、`}.` 或 `.name` 分隔符的 theory（Nominal、IMPP、Pi_Calculus、OCL 等）里不能用括号形式；K6、K7 需 AFP 构建测量；
    K8 一些失败文本的报错改变；K9 每次解析都预测 `_dot_field` 产生式（估计 < 1%，未测），第一次解析失败的括号形式解析两次；
    K10 只解析不检查的工具今天得到异常，将来得到载体。§10 列出文案与新名字提案；括号形式下各已批文案的变体（没有 "is not a constant"）未定。
  - 第二阶段：用户空间两个 theory（用 `_constrain` parse translation 模拟拆分；在 theory 里编译暂存的 lexicon.ML、parser.ML 测小文法）
    与六个变异；`Dot_Parse_Tree.thy` 需要应用补丁后的私有树（用户下令构建）。
- `learning/` 第一阶段完成（`DESIGN.md`；`eng/subtyping_esr2.ML`，对 s2 +686/−142，未编译）。六处改动，各有开关、默认开、关掉即 s2：
  - A `dot_wild`（§14.3）：blocked step 的合一失败后先走原版的 clash path，那也失败才冻结（D7）。预计前瞻报告那 15 个误拒在不开前瞻时
    也被接受，前瞻够不着的变体（binder 有非字段用法、类型只由后面的参数定、带 sort 标注）也一样；前瞻的"问题 1"随之消失。
    PB_Operand2/3 剩下的是原版对显式形式也拒绝的，不算妥协。
  - B `dot_propagate`（§14.2）：一轮 learning 也决定只由一个已学到的结果才能到达的链上字段（条件：该组参数没有基础类型、sort 容许）。
    链从 k+1 次 global run 降到约 2 次，预计约 2 倍原版（现为 10–22 倍，k=24）。
  - C `dot_memo`（报错路径开销）：每次检查中，每个 global run 与每次原版对 E(C) 的推断只算一次，按构造不改变结果。
  - D `dot_tolerant`（§14.3）：只在拒绝之后、且某次 global run 遇到运算符 coercion 或改变类型构造子的 coercion 时，带着这些 coercion
    重新学习选择；只出现在 learning run 里，返回的结果不来自它。预计消除如 `C4 ∧ wq.wfn 3 = k` 的误拒，不改变 s2 的任何接受与报错文案。
  - E `dot_cycle`（§14.7(a)）：依赖成环时，猜规则能决定的最早的字段；消除如 `n + k > 0 ∧ a = n ∧ a = b.dn ∧ b = a.dn` 的误拒。
    §14.7(b) 是 option b 的既定含义，不是缺陷（有审计计数）。
  - F `dot_repair`（`tainted` 造成的误拒与补充的报错路径）：option b 自己的路径拒绝后，不再退回默认做法，而是"节点修补"：
    在 E(C) 上跑原版 local pass，停在第一个"首次访问时的类型选中另一个登记（或规则报错）"的字段，该字段取 local 选择，之前的字段保留
    选择，之后的重新学习，再由原版判定新的 E(C)；每轮停止点后移，轮数不超过字段数。它读的是原版在 E(C) 上的遍历，不读 ESR 自己第一遍
    的记账（binding、`tainted`），所以显式写出无关的访问不会改变判定。预计 `(λu. u.xpos) r = k ∧ C4` 等误拒消失，默认做法的路只在
    option b 自己的学习失败时才走，报错路径开销大部分消除。§6.5 比较了三种替代做法；"按最后检查点名的选择重跑"取最终类型上的选择，
    其中含字段自身的约束，可能确认一个只由字段自己支撑的选择。
  - R1/R2：每个被接受的 term 仍是原版对 E(C) 的推断加最后检查（§8）。
  - 剩余妥协（§11）：learning 链约 2 倍（已请它在第一阶段继续为 global algorithm 内的前瞻写原型）；option b 自己的学习失败时报错最多 2 倍；
    B 与 F 依赖与 D13 依赖守卫相同的假设（原版求解器对互不相关的类型参数组独立处理，已请它尝试证明或改为引擎检查）；节点修补后的
    拒绝显示最后一次尝试的 E(C) 的原版文案或规则文案，不再是默认做法路径的文案（无新措辞，但用户可见）；其他障碍仍受 global algorithm
    限制；§14.1 不在其范围（见 `rerun/`）。
  - 追加（第一阶段续，对 s2 +865/−166）：G `dot_glook`（§13）：global algorithm 生成约束时，λ 或 `let` 绑定变量上的字段按实参将给 binder
    的类型当场决定（条件 G1–G5：符合 local 前瞻条件、默认 sort、由 β-redex 或 `let` 绑定、实参静态类型 ground、规则确实能选），
    learning 变成一次生成；R1/R2 按构造成立；与 s2 选择相同由一条新引理（§15.2）证明，其中跨组 sort 检测一步只论证。预计链在各长度
    约 1.0–1.1 倍原版；自由变量链覆盖不了，仍约 2 倍。妥协 2（option b 自己学不出时的报错）只能缩小：剩一次失败的 global run，
    D3 裁决测得 1.46 倍（m=1）到 1.10 倍（m=64），找不到保持 R1/R2 与两条路径接受集的根本消除办法。妥协 3 的假设拆成已证、只论证、
    由引擎检查三部分；新开关 `dot_guard`（默认开）：节点修补拒绝后再走 s2 的默认做法路径；A、B、G 起过作用的拒绝再以关掉 A、B、G 的
    方式整体重跑；有了它，拒绝只在 s2 也拒绝处出现、文案同 s2（E 的猜测除外），代价是这些拒绝的报错路径回到 s2 的开销。
    该 agent 说 guard 开关由用户决定；第二阶段的 A/B（只关 guard）会测出 guard 是否改变过判定，我看结果后再定是否需要请用户决定。
    第二阶段约 670 个进程，2–4 小时，加约 1.5 小时计时。
- `rerun/` 追加（第一阶段续，对 s2 共 +589/−93）：`dot_expected_type`（§12）：对象是在 term 别处定了类型的变量（`z = r`、`z ∈ Sr`、
  `∃` 里的 `t ∈ set rs`、`map (λt. …) rs`、`{s. …} = Sr`）时，用只取"确切"类型的静态扫描在节点当场决定，不等待、不重跑；R1/R2/R3 已证，
  与 s2 选择相同在 s2 能决定时已证（两步依赖 §14.3–14.4 论证的引理）。属于类似 D5 的偏离：s2 在定类型的那处之前就失败时结果可能不同
  （预期情形下报错显示 `point.xpos z` 而非原始载体，原则上也可能改变判定）——妥协 C5，需用户批准。不覆盖嵌套 `case` 模式、经另一字段
  结果或未知函数定类型的对象。`dot_prefix_replay`（§13）：frame 重跑时复用在最早被重新决定的字段之前已完成的运算符推断记录；按确定性证明
  不改变结果（自查发现并修了一处会复用过期记录的缺陷）。§5.4 引理大部分已证，剩一处缺口（推迟的选择细化了对象类型、随后一步 s2 插
  coercion 而推迟的遍历做合一），论证它总以换回 s2 的 pass 结束，探针 C12、C13 检验。剩余妥协（§15）：C1' 传播定不了类型的 late field 仍
  丢弃一次遍历（增长形状约 1.1–1.5 倍，小 term 仍 1.34–1.67 倍）；C2 推迟后的报错路径多一次 local pass；C3' replay 只记录运算符；C4' 引理缺口；
  C5 见上；C6 无收益时的小开销。

**第二阶段（2026-10-30 10:30 UTC 起）：** cslh19 空闲（用户的 SMT 测试结束，负载 0.1）后，用 SendMessage 让各 agent 开始；规则：
只在 cslh19 上跑，每个 agent 最多 2 个并发进程，`nice -n 10`，`taskset -c 0-7,10,11,14-23`，不留脱离的驱动脚本；负载 > 20 或别人的重活
出现时暂停；计时只用 CPU 8、9、12、13，并用 `flock ~/Current/MLML/ai-artifacts/dot_syntax_timing/TIMING.lock` 在所有 agent 间排队；
先编译与冒烟检查；结果写 `RESULTS.md`。`learning/` 的原 agent 上下文用尽，`rerun/` 的原 agent 接近上下文上限，都由新 agent 接手
第二阶段（按各自 `DESIGN.md` 的计划运行）。`parse/` 只跑用户空间部分，私有树部分要等用户下令构建。`tests-texts/` 运行
`Texts_Probe.thy`，并把各组新提出的文案与测试并入清单。监视器：本机出现 dot_syntax 的 Isabelle 进程、cslh19 负载 > 30、
我们的 poly 进程 > 16、或用户的 SMT 测试回来时通知。
（附：之前等待空闲的后台检查没有触发，原因是在 zsh 里 `set -- $out` 不按空白拆分；以后这类脚本放进 `bash -c`。）
- `registry/` 第二阶段完成（`RESULTS.md`；cslh19 10:31–10:37 UTC，只用 `ML_process`）：修了自己原型里四处错误后（`Term.is_funtype` 不在
  签名里；`\<^typ>` 不接受 schematic 类型变量；P08 没看 `Trueprop` 之下；16 处预测把 `size` 写成了 `length`——`length` 是 `size` 的缩写），
  82 项检查全部符合预测，设计不变。确认：登记随 morphism 走；context 自己的副本遮蔽 theory 的副本（关掉遮蔽就出现评审说的三方歧义和
  `?'c list` 退化）；Pure 的 notation 规则会丢掉 interpretation 的副本；`rewrites` 下副本是改写后的 term；两条 import 路径造成真歧义，
  一条 `no_dot_field` 可消除且重开 locale 后仍有效；attribute 收得到 morphism（评审 §3 的说法确实错），但在 import 它的 locale 的 header、
  `rewrites`、`defines` 里看不到（缺口属实）；新增 P11：登记用的 unifier 与 `type_infer_context.ML` 的 unifier 在 6 万次随机比较中 0 处不同
  （coercion 引擎的 `strong_unify` 是同一份代码），所以 ESR 的 `decide` 可以照已批 §1.2 用 `Sign.typ_unify`；新增 P12：light locale block 里
  行为符合设计（2026-11-02 注：P12 测的是后来去掉的命令形式；改用 attribute 后，light-locale 块里的登记作用于整个 theory，见 6.4）。登记检查 3（schematic 变量）经命令时被 Isabelle 先以 "Unbound schematic variable" 拒绝，其文案只对 ML 调用者可见。
  未测：无点文本上登记表的开销；localized_record 钩子（localized_record 尚无提交）。妥协清单不变。
- `tests-texts/` 第二阶段完成（cslh19 约 10:31 UTC 跑了一次 `Texts_Probe.thy`，在 s1 上，两种 coercion 模式，14 个用例全部渲染）。实测：
  第 1 步对 `List.fil`、`Multiset.mset` 以 "exist for:" 结尾、后面空；第 3 步对类型 `'a` 与 `point ⇒ bool` 的对象出现空的 "Fields of …:" 行；
  链上的 late clash 标题写 `t.start.xpos`、正文写 `point.xpos (start t)`、类型 `cpoint ⇒ int`（coercion 打开时同一输入被接受）；链上的歧义
  建议混用两种写法（`cpoint2.xpos s2.a2`，读回仍正确）；`CONST r.xpos` 给今天的 `Undefined constant`；`r.more`、`r.xpos_update` 给已批第 3 步
  文案；第 1 步候选按登记从新到旧。两处预测更正：`Texts_Probe.origin.xpos` 第 2 行只引用失败的前缀；stage 1 兜底对未检查的 term 打印
  `B.0::<position>`。`TEXTS.md` 现为 36 行加一张名字提案表（标明提案方）；`TEST_PLAN.md` 新增 `Specification_Equations`（`fun`、`primrec`、
  `function`、`inductive`、`partial_function`、`primcorec`、旧式 `primrec`、`class` 规格里的 dot 语法，各带用 Free 载荷的变异）、`Stage0`，
  §5.7 各设计的测试与四处需要合并测试的交汇点，§10 问题增至 14 个。设计之间的冲突：`stage0/` 的丢弃检测标签与 termify 论证按 s1 的 Free
  载荷写，`parse/` 把载荷改为 schematic 变量，两者需在新载荷上复核（已写入测试计划，并已请 `stage0/` 在第二阶段说明）。
- `warn/` 第二阶段完成（`RESULTS.md`）：57 项测试在原版代码上、以及叠加在 `parse/` 补丁（其 `decode_free`、`ast_to_term` 拆分与新
  `dot_field.ML`，不含词法与解析器改动）上都通过；每项测试都核对 term 与原版 `Syntax.parse_term` 相同，无一改变；8 个变异各被至少一项测试抓到。
  一个设计上的冲突：本文档 §3.1 的提案（"走到类型变量的分支不算"）照字面用，会让所有类型未知的对象都不警告，包括第一次评审举的全部
  Lean 式误读例子（C5）；所以放宽对象规则与 §3.1 这条不能同时采用。计时（cslh19 负载 6.5–17.7，非安静数字）：无点 term 与未改副本相比
  0.985，常量长标识符 1.007，选项关闭 0.987–1.009；一个 term 里 100 处被警告的标识符 3.1 倍（每处约 32 µs，先渲染再去重所致）——
  已请它改为先按 closure 的键去重再渲染并重测。该 agent 自报第一阶段用 python/sed 改过自己的 `DESIGN.md` 三处。
- `parse/` 第二阶段（用户空间部分）完成（`RESULTS.md`；10:30–10:58 UTC）：`Dot_Parse_User.thy` 90 项通过，`Dot_Parser_User.thy`（暂存的
  lexer 与 parser，k ≤ 16）33 项通过；暂存的 `lexicon.ML`、`parser.ML`、`dot_field.ML` 能编译，`syntax_phases.ML` 等要私有树构建。
  - **载荷设计错了一处：** `Proof_Context.expand_abbrevs` 经 `expand_binds` 在默认模式下拒绝一切 schematic 变量；构造该报错时打印 YXML 名字的
    载荷会崩溃或吞掉整行输出。改为仍用 schematic 变量、但名字是可读的转义文本（`dot_field name=s.start.xpos index=2 line=1 offset=10 …`）。
    新约束：载体不得到达 `expand_abbrevs`，必须在 stage 0 标准推断内部或 stage −100 被替换或报错；ESR2 的 stage 1 兜底对这种载荷太迟。
    这与 `stage0/` 的 D14 设计（未决定的载体跨 stage 0 多轮留在 term 里）冲突，已转给 `stage0/` 从根上解决（换一种同时经得起 `close_form`
    与 `expand_binds` 的载荷编码，或换 D14 推迟的位置）。Free 载荷会坏 `fun` 等方程一事已实测（`close_form` 绑定 `dot_field.xpos`）。
  - K6、K7 实测属实：原版接受 `case xs of x.y ⇒ x.y`（名为 `x.y` 的模式变量），拆分后坏掉；有歧义的文法里原版选把名字当字符串用的树
    （`STR ''a.b''`），拆分后选 term 树。静态扫描在 HOL 与 AFP 里仍没找到这样的文本。`List.mapp` 的报错与今天完全相同（含位置与补全）；
    共用判断与原版 `decode_term` 54 例一致。变异 6 个中 5 个被抓到，第 6 个是第一阶段就预言的等价变异。
  - K9 估计错了：在 HOL 真实文法上，两条 `_dot_field` 产生式使解析多花 4.6%（14 个 HOL theory 的 8,933 个字符串）；lexer 标记扫描 0.17%。
    修法（新设计元素）：第一个符号之后带 `field_dot` 终结符的产生式不进 lookahead 表，只在第二次解析时预测；小文法里已与没有这些产生式时
    一样快。剩余：25 条产生式的文法里无点输入约 +4–8%（拆分测量时负载 19，读不出），违反 R3，已请它找出来源并从根上去掉
    （例如输入里没有 `field_dot` token 时完全走原版的数据通路），需安静机器或同进程交替计时确认。括号形式需第二次解析时为首次解析的
    1.7–2.1 倍；k 处冲突线性增长（k=1 17 µs 到 k=16 195 µs，每次一棵树）。
  - 新的用户可见文本：打印出的载体显示为 `?dot_field name=… index=… …`。
- `warn/` 跟进完成：先渲染再去重的开销已消除。三步：每个不同的 site key（标识符、首段的 binder 项、参数个数、写在其上的类型）只求一次
  读法；每个不同的读法 key（按 `aconv` 比较的 term）只渲染一次；每种不同文本只发一条。100 个相同被警告标识符的 term 从 3.11 倍降到
  1.057 倍（剩下的约 0.09 ms 是产生那一条消息本身）。59 项测试在两种基础上都通过，11 个变异全被抓到。无点行在负载 11–20 下两次之间
  摆动 ±6%（代码未变），只能说开销与噪声分不开，需安静机器复测（妥协 C1 的剩余部分）。
- 12:05 UTC 前后又一次网络中断，`learning/` 的接手 agent 停下，恢复后从原处继续。
- 12:20 UTC 前后周额度用尽，`s2/`、`rerun/` 与 `learning/` 的 agent 停下；用户换账号登录（/login）后说"resume all"，12:30 UTC 用 SendMessage
  让三者从原处继续（它们在 cslh19 上的后台任务——`rerun/` 的第二次计时、`learning/` 的两个批量进程——一直在跑，没有重启）。
  另起一个 agent（`reviews/round3/d14on/`）为 coercion 打开时的 D14（stage0 的妥协 K1，20 例）写原型：先学到选择，再让原版 coercion
  推断在 E(C) 上从检查流程开头重跑，最后检查。
- `s2/` 第二阶段完成（`RESULTS.md`；约 1,900 个进程全部正常退出）：开关退回时逐字复现每个旧引擎的输出（s1 的 154 个任务；前瞻裁决的
  A/B 计数、全部探针与整张变异表；D3 裁决的 `jw` 运行 35,242 块与其探针；D3 回归验证的 12 个变异）。采用的默认设置下，现有各测试集上
  的效果恰好是两位裁决测得的那些：对 s1 恰好是 D3 的 15 个判定改变，coercion 关闭 0 处；A/B（前瞻开对关，都在 option b 下）148 个任务
  TERM 0、VERDICT 0、TEXT 1（`P9_Fuzz_1` 那处已知改进），13,631 个前瞻选择与不开前瞻时的 late choice 0 处不一致；对前瞻裁决的运行
  21 处判定改变，全部是拒绝变为原版结果；`S2_Interact` 20 项预测全部成立；`S2_Spine` 37 个无点 term 全部等于原版。唯一的引擎改动是
  编译修正（`audit_default_path` 的全捕获 handler 改用 `Exn.result`）。自报一次违规：本机起过一个比命令活得久的 `ssh … &`，已杀掉并清理
  远端孤儿批次后重跑。计时（两次中位数相差约 1%）：无点 0.99–1.03；嵌套 λ k=128 1.10（s1 16.3–16.5）；let 链 k=96 1.30–1.36（s1 14.2–15.0）；
  嵌套 coercion 1.01–1.24（负载均值 12.8，引擎读显式形式也是 1.06–1.13，需安静复测）；learning 链 k=24 10.4–24.6（未变）；全拒绝的报错行
  1.19–2.32（补充的报错路径，默认做法的 1.08–2.00 倍）。剩余妥协：`tainted` 在补充里造成的误拒（现有集合 0 例，新探针 3/20：
  `S2_Interact` 5、7、12），由 `learning/` 的 F `dot_repair` 处理；补充的报错路径开销，由 `learning/` 的 C `dot_memo` 与 F 处理；
  learning 链、失败 application 里的原版指数嵌套（d=12 时 19.4 倍）、coercion 打开时的 D14，分别在 `learning/`、`rerun/`、`d14on/`。
- `learning/` 第二阶段大部分完成（`RESULTS.md`）：编译修正同 s2；改动 D 有一处设计错误已修（弱合一的障碍检测只查了 coercion 表的一个方向，
  而弱合一不看变型；修后全部重跑）。A/B（learning 全关对全开）：A 集 40,208 次调用 0 处差别；B 集 3 处新接受（D 接受，与原版对显式形式相同）；
  C 集 27 处新接受（预言的 LB_J 8、LB_J2 6、LB_K 1，`S2_Interact` 5、7、11、12、12b，LB_Fuzz 一例经核对与原版相同）；LR 探针 871 处新接受、
  2 行文案改变（同一 fuzz 用例：E 的猜测路径显示另一条已有措辞，需用户批准）；LR_Fuzz 2,000 例无拒绝、无 TERM 差别。`LR_Comp`：learning
  设置下误拒 0 例，s2 下 31 例。归因：wild 1、tol 26、cycle 6、repair 66 处接受，prop、memo、glook 无差别（A 与 D 有重叠，A 是更省的路径）。
  guard：关掉后在 68,696 次调用中判定 0 处改变，文案 231 处改变（0.34%），其中 48 处前面多了最后检查的前缀、5 处怪错字段、4 处先报另一处
  类型冲突——所以 guard 开着文案更好，代价待计时。变异：guard 和其他层掩盖了多数变异（被拒的效果被 guard 重跑掉），隔离变异运行已准备未跑。
  未完成：隔离变异、guard 关时变异的最后 26 个任务、两次计时；原 agent 接近上下文上限，已另起 agent 收尾。
- `rerun/` 第二阶段完成（`RESULTS.md`、`C5_CASES.md`）。两处设计错误已修并重跑：F4 `prepare` 给每个自由变量一个参数并包上约束
  （`_type_constraint_ (point ⇒ point) $ Free ("r", ?'a)`），所以静态扫描一个都预测不出；改为"ground 类型的非透明约束给出确切类型"。
  F5 探针 C15 是反例：推迟期间另一处合一定下了参数，`u.nm` 在 `real` 上被决定，最后的 term 与 s2 不同、且 `u` 的类型来自字段自己的选择
  （违反 §1.4）；改为"细化对象类型的选择一律不推迟"，加变异 `postpone_refining`。**我的决定：保留 F5**（不改用 §14.5 的"推迟时立即
  应用细化"，因为没有一个测量到的形状需要推迟细化选择，F5 更简单且已测）。
  - A/B 对 s2（176 个任务）：A 集 76,768 次调用 0 处差别；B 集 23,586 次只 1 处文案；C 集 8,798 次 473 处文案、19 处判定；预测与 s2 的
    late choice 比较 9,018 次 0 处不一致。逐个机制单开：推迟与 replay 各自 0 处差别，全部差别来自期望类型传播（C5）。C5 全部 493 例列在
    `C5_CASES.md`：采用的设置（前瞻开）下 76 处文案改变、0 判定、0 term（75 处报告了另一处失败的函数应用，1 处把操作数类型打成
    `int × nat` 而非 `int × ??'a`）；前瞻关时 398 处文案、19 处判定（全是 s2 的误拒变为原版结果）。
  - 探针 68 例全部与 s2 相同；变异 16 个抓到 14 个（`keep_last_check`、`pred_no_count` 如预言抓不到）。
  - 计时（两次，钉单核，负载均值 10.2 / 6.7；两次不满足规格 §15.3 的 5% 一致性，65/300 对相差 > 5%，多为 < 5 ms 的行；各形状结论两次一致）。
    s2 → 三机制全开：隐式自由对象 m=128 8.3 → 0.93–0.98；引理末尾 m=64 4.2–5.1 → 0.97–1.01；批量 m=64 7.5–8.7 → 1.00–1.06；嵌套 `case`
    k=32 2.9 → 1.07–1.08；推导式 k=24 2.8 → 0.94–0.97；嵌套 `∃` k=64 4.1 → 1.01；嵌套 λ（不开前瞻）k=128 15 → 1.11–1.13；let 链（不开前瞻）
    k=96 13 → 0.95–0.98；frame 里有昂贵子项 j=8 10.5–11.3 → 1.19；左 spine 由 `= r` 定类型 m=16 12.3 → 1.12；左 spine 经字段定类型 m=16
    11.7 → 1.16–1.18；被替换的路径 m=64 6.2–6.4 → 1.03–1.04。§14.10 的 `(λt. t.xpos + k) r`（不开前瞻）：s2 1.05，加传播后 1.12–1.14
    （静态扫描开销，+0.03 ms / 0.3 ms，妥协 C6）。无点对照各列（含 s2）1.03–1.08，属负载噪声。
  - 剩余妥协：C1'（传播定不了类型时每层依赖丢弃一次遍历）各形状 0.95–1.21；C2（推迟的 pass 失败时换回 s2 的 local pass）A 集 1/76,768、
    C 集 309/8,798 次，m=64 时比 s2 多 3%、1–10 ms 的行多 6–11%；C3'（大部分是操作数的左嵌套形状）未测；C4'（推迟后与 s2 相同）只论证，
    实测 F5 后 0 处 TERM 差别；C5 见上；C6 无收益时的小开销。
  - 所有计时需在最终合并的引擎上、cslh19 安静时统一复测一次。
- `parse/` 跟进完成：无点文本的解析残余开销找到并去掉，三个来源：三字段的解析输出与 predictor 的 closure（改回原版的两字段输出，字段访问在
  已有的 size 计数里记 2^30）；lexer 的标记扫描（`tokenize` 恢复原版，`Syntax_Phases.parse_asts` 先跑今天的解析，失败才调
  `Lexicon.field_access_dots` 与第二次解析）；第一次解析里两处恒假标志的测试（第二次解析改用自己的 `field_process_states`、`field_produce`，
  第一次解析逐字运行原版的 `process_states`、`produce`、`parse`，经 diff 核对）。最终（负载 4–5，同进程三份副本交替计时、取最小值）：
  tokenize+parse 0.971–1.007、对照副本 0.974–1.009，测量分辨率约 ±2%，残余测不出。K9 只剩括号形式需第二次解析时为首次的 1.7–2.1 倍。
  代价：Earley 步骤约 60 行重复（违背代码复用规则）——**实现时改用 functor（同一份源码实例化两次，第二次带字段访问），既不重复又没有运行时
  标志测试**，需在实现时计时确认。`stage0/` 的载荷方案已接上：`Dot_Field.dest_access` 认两种编码，新检查通过。补丁 `code/parse_side.diff`
  约 +384/−33，另改 `Syntax/syntax.ML` 一行（`Syntax.parse_field_dots`）。用户测试 91/0，parser 33/0，变异 m1、m3–m6 都被抓到，
  m2 改由私有树上的 `Dot_Parse_Tree.thy` 覆盖。
- 12:56 UTC 用户的 SMT 测试在 cslh19 上重新开始（23 个 z3/cvc5，负载 22）。按用户的规则暂停：通知 `learning/` 收尾 agent 与 `d14on/`
  不再启动新的 Isabelle 进程；`learning/` 的第一次计时（`timing/run.sh run1 Esr D3 Err Learn`，正在跑 Esr）由我直接停掉（只杀
  round3-learning 的进程），cslh19 上已没有我们的进程。后台等待空闲的检查已重新挂上（这次放在 `bash -c` 里）。空闲后要续跑：
  `learning/` 的两次计时（及其报告里列的未跑项）、`d14on/` 的运行，以及最终合并引擎的统一安静计时。
- `learning/` 收尾 agent 暂停时的报告（`RESULTS.md` §7 写明了待跑命令）：隔离变异 176 个任务与 guard 关时变异剩下的 22 个任务都已跑完。
  主要发现：**guard 开着时，A、B、F、G 中任何"造成 s2 自己不会有的拒绝"的缺陷对所有测试都不可见**（guard 会把结果换回 s2 的），这些改动
  只能在 guard 关（有的还要 D 关）时测试；guard 不掩盖错误的接受（每个接受仍是原版对 E(C) 的结果加最后检查）。变异表：wild_nofreeze、
  wild_final（D 关时）、memo_tolerr、repair_noprefix、repair_nolearn（隔离时）、glook_spine、glook_any、glook_noii 被抓到；prop_tied、
  prop_unfed 等价；prop_nosort 与 prop_sorted、prop_ground 与 prop_polyrange 两两互相覆盖；wild_err、prop_single、glook_sort 三个幸存者
  已写了新探针 `lr/LR_MutX.thy`（未编译未运行）。预测错的：AB4、LR4、LR5 Y3、prop_tied、prop_single、prop_nosort、memo_err（目前）、
  glook_sort、glook_noii。缓存对"参数类型错"的行 0 次命中，所以不能缩小妥协 2。E 的猜测改变 2,000 个 fuzz 中 1 个的文案，列为 §11 第 8 项。
  空闲后待跑：`LR_MutX` 的 30 个任务、两次计时（各约 45 分钟），然后补 §9.2/§9.4 的计时与 §11 的开销。
- 13:10 UTC 起（等 cslh19 空闲期间）：另起一个没参与过设计的 Opus agent（`reviews/round3/arch/ESR3_ARCH.md`），不运行任何东西，
  通读各组设计与实测，做重叠分析（如本地前瞻与期望类型传播、`dot_glook` 与 `dot_propagate`、`dot_wild` 与 `dot_tolerant`、
  推迟重跑与 prefix replay、D3 补充与 `dot_repair` 与 `dot_guard`），提出机制最少、不变式按构造成立的 ESR v3 架构、测试配置、
  合并成 s3 的计划与统一验证/安静计时计划，以及剩余妥协与需批准的文案的完整清单。
- `d14on/` 第一阶段完成、暂停（`DESIGN.md`；原型未编译，已暂存到 cslh19；`RESULTS.md` 列出待跑命令）。设计：coercion 引擎拒绝一个
  dot term 时，它自己在 stage −100 的 check 里嵌套运行一遍完整检查流程（标为 stage 0 learning run，结果不用）：其中 engine 不报告到最后
  仍等待对象类型的字段（载体留下、结果类型自由），stage 0 推断中不决定任何字段，adhoc_overloading 解析对象后由 stage 0 check 在该轮
  类型上用规则决定，以异常 `STAGE0_LEARNT` 带回选择；回到 stage −100，engine 以这些选择在节点上预设再跑一次（s2 的不变式 I1 保证
  得到原版对 E(C) 的推断），每个学到的字段附一个以对象类型为类型的标记自由变量；外层 stage 0 起都是原版；stage 1 的 dot check 读
  标记类型（adhoc_overloading 之后的对象类型）做最后检查并删掉标记。原始输入就是 stage −100 check 的参数，不另存；不改 `check_terms`；
  嵌套深度 1，每次 learning run 必须学到新选择，否则拒绝，次数不超过载体数。R2 的"最终类型"是 stage 1 开头被接受的运行里对象自己的
  类型。探针 OBJ 说明为何不能用字段自身的约束来确认选择。**新发现：** `stage0/` 在 coercion 关闭时的重跑没有最后检查，若某个 stage 0
  check 不单调，可能接受规则会推翻的选择；同样的标记可以补上（待用探针 STEER 证实）。剩余妥协（待测）：D14-1 被接受的 D14 term 预计
  2–3 倍原版；D14-2 被拒的点语法文本若无 guard 要多付一次（guard 需从 adhoc_overloading.ML 导出 2 行 `is_overloaded`）；D14-3 文案；
  D14-4 最后检查推翻的选择直接拒绝、不按最终类型上规则的选择重试；D14-5 有 guard 时只学 adhoc_overloading 定类型的对象。
- 13:06 UTC cslh19 再次空闲（用户的 SMT 测试只跑了约 10 分钟）。让 `learning/` 收尾 agent（`LR_MutX`、两次计时）与 `d14on/`（全部运行，
  外加用 STEER 探针在 coercion 关闭时检验 stage 0 重跑缺最后检查的发现）继续；新规则：每个任务与每次计时之前查 z3/cvc5，出现就不再
  启动新进程，正在进行的计时停掉并报告未完成。监视器重新挂上。
- `arch/ESR3_ARCH.md` 完成（只读，未运行）。核心：ESR 是分开的两件事——搜索 C（每个 `x.f` 是哪个登记），以及原版对 E(C) 的推断加
  最后检查；其余机制只影响多快、能否找到 C，不决定返回什么 term。重叠分析：本地前瞻、期望类型传播、`own_type`（D8）、`dot_glook`、
  `dot_propagate` 的静态部分是同一原因（按对象在别处必然得到的类型提前决定），有四份"子项的确定类型"函数、三种 sort 处理；`dot_wild`
  关掉只少 1 个接受（`dot_tolerant` 关掉少 26 个）；`dot_glook`、`dot_propagate` 不改变任何结果、只减少 global run 次数；推迟重跑与
  prefix replay 解决不同的开销，各有只有自己能改善的行；guard 开时默认做法路径在 68,696 次调用中 0 次改变判定，节点修补在所有测得集合上
  已覆盖旧的退回做法；`dot_memo` 在它针对的行上 0–1 次命中。提议的 v3：保留 s2 的 local pass 与 D7（不要 `dot_wild`）；一个预测机制
  （期望类型传播加 β-redex 头与"声明值域 ground 的载体"两种情形，local pass 与约束生成都用，取代前瞻、`own_type`、`dot_glook`，预测只是
  prepared term 的函数）；保留推迟重跑与 prefix replay；global algorithm 里的 learning，tolerance 改述为"有字段待定的 run 就是 tolerant"
  （可被返回的 run 永不 tolerant）；成环规则；option b（local pass 失败或结束时仍等待都适用）后接节点修补，默认做法路径只在 option b 学不出
  候选时才走；stage 0 标准引擎及其重跑；载荷解析时为 schematic、stage 0 第一次见到时重建为 Free。去掉 `dot_wild`、`dot_propagate`、`dot_memo`、
  `dot_guard`、`dot_optb_wait`、`domain_expect` 与已退役的模式、审计、内联变异（§3.5 写明各自损失）。返回 term 只有三处，都以最后检查结束；
  C 完整时直接用原版（无点）代码处理 E(C)；local pass 自己的结果只在一个新布尔量表明没有字段等待过时使用。
  **可能的 R1 缺口（读代码所得，未运行，§3.2a）：** 原版推断参数时用其运算符头部的 `coercion_args` 标志（subtyping.ML:817-821）；s2 在选择
  未知时用外层标志推断字段的对象（s2 约 1521 行），对头部是载体的 application 读 `Pure.dot_access` 的声明（没有，约 1592 行）；所选登记的头部
  带 `coercion_args` 声明时两者不同（HOL 里只有 `case_*` 有声明，现有测试不覆盖）。已另起 agent（`reviews/round3/cargs/`）在 s2 与 s1 上
  写探针实测。测试：发布的引擎里不留"掩盖其他部分效果"的检查，guard 的作用移到测试配置。合并顺序：s2 → rerun 补丁 → learning 的 tolerance、
  成环、节点修补与生成钩子 → 预测统一、返回/编排改动 → 登记表的 `Dot_Field.candidates` → Pure 侧（需用户下令构建）→ d14on。统一安静运行
  的规则：某机制关掉后判定改变或某行慢 5% 以上才保留。§7 列出需决定的 10 项（我按授权能定的我来定；文案与妥协清单请用户批准）。
- 已另起 agent 做 s3a（`reviews/round3/s3a/`）：把 rerun 补丁与 learning 补丁按开关合进 s2，核对两组开关各自复现原结果、全开时解释每一处交互
  效应。
- `d14on/` 第二阶段完成（`RESULTS.md`；输出 94 MB）：coercion 打开时那 20 个 K1 拒绝全部变成原版的 term（`CB_Clean` 及两份副本各 4、
  `CB_Constraints` #46、`CB_ElabS` #0、1、16、34、`VB_Battery2` #56–58），154 个任务两种模式下别无变化，54 个 fuzz 计数相同；剩下的 69 个
  coercion 打开时的拒绝都是规则所要求、`(e).f` 语法或测试工具的问题。schematic 载荷 0 处变化。探针 62 例中 39 例 DOT-ERR → SAME（嵌套 D14
  对象各两次 learning run、链、`let`、有界 `∀`、推导式、`case`、批量等），规则要求的拒绝都保留。**STEER 证实了 stage 0 重跑缺最后检查：**
  coercion 关闭时接受了 `(λt. t.xpos) (sv k)` 为 `point.xpos (svC k)`，而规则在 `cpoint2` 上应报歧义（需要一个不单调的 stage 0 check，
  今天并不存在），同样的标记可补上——**我的决定：coercion 关闭的重跑也加上标记与最后检查**（实现层面，不是妥协）。一个预测错误引出的问题：
  `(λt. (t.pa, t.pb)) (mk2 k)` 被接受，因为 s2 在 global algorithm 里把放在对象 token 位置上的 coercion 算作对象的一部分（s2 对非 D14 对象
  也如此）；这是否符合 §1.4"对象类型不靠字段决定"待我分析后报用户。变异 5 个抓到 4 个（`no_parsed_guard` 只省一次引擎运行，不影响结果）。
  计时（负载 1.0–1.4，无 z3）：无点 0.994–1.006；普通点文本 0.995–1.018；这 20 个 D14 term 为原版对 E(C) 的 2.8–4.4 倍（预测 2–3 倍）；被拒的
  点文本无 guard 时为 s2 拒绝的 1.9–2.5 倍，用 guard 后不含 overloaded 常量的 1.007–1.023、含的约 2.06 倍。剩余妥协：D14-1 这 20 个 term 的
  2.8–4.4 倍（§3.9 有一种省一次引擎运行的办法，未写原型）；D14-2 被拒文本的开销（需从 adhoc_overloading.ML 导出 2 行 `is_overloaded`）；
  D14-3 文案（154 个任务 0 处改变，探针 8 处）；D14-4 最后检查推翻的选择不重试（输入集 0 例）；D14-5 只学 adhoc_overloading 定类型的对象。
  已请它为 §3.9 省一次引擎运行的办法写原型、分段计时，并按发布形态实现 guard 再测。
  跟进完成：分段计时（一处访问，原版 E(C) 0.32 ms）：第一版多出的 0.61 ms = 被拒的首次引擎运行 0.21 + learning 模式引擎运行 0.17 + 嵌套
  stage 0 0.16 + 第二次引擎运行 0.05。改动（各有开关）：合并版——s2 拒绝一个在等对象类型的字段时抛新异常 `WAIT_REJECT`，带上已算好的
  点形式 typing，s2 内部两个处理 `ERROR` 的 handler 同样对待它，learning run 只剩 stage 0，其他原因的拒绝不再启动 learning run；guard
  （`adhoc`，发布时从 adhoc_overloading.ML 导出 2 行 `is_overloaded`，原型里模拟）；更严的 guard（`linked`：等待的对象类型与某个 overloaded
  常量的类型共享类型参数时才学）；learning run 的第一轮 stage 0 只展开缩写。推荐配置 `DOT_D14ON=on DOT_D14ON_MERGE=on DOT_D14ON_GATE=linked
  DOT_D14ON_SKIP1=on`：154 个任务、20 例、探针与 stage 0 测试的判定、结果行全部与第一版相同；77 个 coercion 打开任务里 learning run 从 3,772 次
  降到 107 次。计时（三次相差 ±0.02）：无点 0.99–1.00；普通点文本 0.97–1.01；D14 term 对原版 E(C) 2.04–2.91 倍（原 2.8–4.4）；被拒文本对 s2 的
  拒绝：一般 0.97–1.01，挨着 `mk k` 1.12，`(λt. t.xpos) (mk y)` 1.70（等待的对象确实与 `mk` 相连且 stage 0 也解析不了 `mk`）。剩余的 0.40 ms
  中被拒的首次运行占 0.20（s2 先试 local pass 与 global algorithm；跳过它就要先按 local typing 学，会改变两者都能决定的字段由哪种 typing 决定，
  属于语义选择而非优化，未做原型）。新变异 `no_reject_fallback` 抓不到（没有用例走到那个 handler，保留它是为了按构造保持 s2 的尝试顺序）。
  `proto/out/` 现 225 MB。
- `s3a/` 完成（`README.md`、`RESULTS.md`）：用 `diff3 -m` 合并 rerun 与 learning 两份引擎（23 处冲突手工解决），每个机制各有开关、默认全开，
  修法 B、C 不设开关直接并入。(a) learning 全关时 179 个任务与 rerun 引擎逐行相同；(b) rerun 全关时 1,456 个任务与 learning 引擎逐行相同；
  (c) 全开时对 s2 的 A/B 共 124,238 次调用：A 集 0 处差别，B 集 TEXT 1、VERDICT 3，C 集 TEXT 473、VERDICT 27，每一处都可归于 rerun、learning
  或两者单独都给出同样结果，**交互效应 0**；从未拒绝 s2 接受的 term；预测不一致 0。`Cargs_Probe` 92 例三种配置下 0 处 R1 违反，CV1、CV2、
  CV5–CV9 都得原版 term。列出了 14 个交互点及其处理（例：rerun 的替换 pass 现在会继续进入 learning 的路径；guard 的 plain 重跑包含推迟、
  预测与 replay；两处"deferred"含义不同、互不共享代码）。两项此前未报告的开销（都在 s2 也拒绝的 term 上）：guard 整体重跑检查在 A 集 1,392 次、
  C 集 1,510 次；tolerant 尝试在 A 集跑了 2,387 次、一次也没接受。粗测无点 m=60 一行全开与全关都是 1.04（负载下、未绑核）。
- 已另起 agent 做 s3b（`reviews/round3/s3b/`）：在 s3a 上实现 ESR3_ARCH §3（统一的预测机制；返回路径与 tolerance 的改述；去掉 `dot_wild`、
  `dot_propagate`、`dot_memo`、`dot_guard`、`dot_optb_wait`、`domain_expect`，各留测试开关），对 s3a 做全量 A/B（期望 TERM 0、判定只从误拒
  变为原版结果、文案差别按类列出以便请用户批准），安静计时，并按"关掉后判定改变或某行慢 5% 以上才保留"决定条件性机制的去留。
- 另起 agent 汇总给用户的决策清单（`reviews/round3/INVENTORY.md`，只读不运行）：仍待批的妥协（按领域分组、附例子与实测大小）、已被后来的
  工作消除的妥协、对已批决定或用户原话的偏离、全部用户可见文案与名字、需用户下令的构建、其他需用户回答的问题。我据此写中文决策材料给用户。
  完成：妥协 68 条、已消除 26 条、偏离 14 条、文案 41 条加名字 17 个、构建 9 次、问题 32 个。它另标出两处新偏离：§1.12 放宽范围之外的重新推断
  （D14 重跑、d14on、节点修补、推迟重跑）；无登记字段名时保留今天的 "Undefined constant" 与已批 §1.6（报错须同时提到常量与字段）冲突。
- 中文决策材料草稿：`reviews/round3/DECISIONS.md`（§1 六项重大事项逐项讲解与建议；§2–§5 成批的偏离、性能妥协、功能妥协、文案与名字；
  §6 构建；§7 我已定下的事）；待 s3b 结果后定稿再交用户。其中 §1.4（D15 一致性：经 coercion 改变的对象类型能否用来选字段，
  `(λt. t.ih) [n]`、`(λt. (t.pa, t.pb)) w` 被接受而 `(λt. t.sqrt) n` 被拒）我的建议是照 D15 一致处理（最后检查用对象自身的类型）；
  已另起 agent（`reviews/round3/d15/`）在 s3a 上实现并测出受影响的 term 数。
- `d15/` 完成（`RESULTS.md`）：成对形状的原因属实——对象 token 外总有位置约束 `_type_constraint_ (?p ⇒ ?p) $ t`，所有决定读的 `objT` 是 `?p`；
  global algorithm 生成 `τ_t <: ?p` 与（字段决定后）`?p <: dom g`，求解器可能把 coercion 放进位置里；local pass 永不在位置上插 coercion。
  `(λt. t.ih) [n]` 原因不同：位置上没有 coercion，coercion 在 λ 的实参上；learning run 在求解前对象类型为 `?c list`、按已批规则第 4 步选中唯一候选，
  与规则一致。`w :: nat × _`（已知类型）s3a 本来就拒绝，被接受的形状要实参类型只部分已知（`undefined :: _ × _`）或自由变量。实现：开关
  `dot_object_own_type`（+90/−9），决定与最后检查读对象自身的类型（透明约束之内：binder 类型、自由变量或常量自己的类型、固定变量声明的类型），
  不碰推断本身（两个较早版本直接绑定 `objT`，判定相同但因 sort 参数改名产生 101 处无谓的文案差异，已弃）。288 个任务：70,325 次调用判定 0 改变、
  接受的 term 0 改变、拒绝变接受 0，2 个原本被拒的 term 文案改变；新探针 91 例八种设置下一致：14 例接受变拒绝（list、函数、set、pair、自由变量、
  `let`、有界 `∀`、链上叠加等），每例都与换序的 twin 判定与文案相同；文案为最后检查的草稿行加已批第 3 步文案。仍依赖顺序的：链形状
  `(λt. (t.sw.pa, t.sw.pb)) (undefined :: _ × _)`（coercion 落在链内层，需新机制）。451 个被接受的语料用例位置上有 coercion（经多态字段传到
  对象），规则在自身类型上选到同一个登记，不变。开销测不出（中位 1.01）。决策材料 §1.4 已据此更新；我的建议是采用。
- `s3b/` 完成（`README.md`、`RESULTS.md`；`out/` 492 MB）：统一的预测（期望类型传播加子句 (iv)"静态已知选择且声明值域 ground 的载体"与 β-redex
  头，需按轮次求不动点；local pass 与约束生成读同一张表；生成里只在相关参数都是默认 sort 时使用），取代前瞻的静态部分、`own_type`、`dot_glook`；
  预测只是 prepared term 的函数（读代码可见），24,986 次预测与不预测时的 late choice 0 处不一致。出口：local pass 的结果只在没有字段等待过、且
  没有所选头部带 `coercion_args` 声明时返回；其余一律由原版的无点代码处理 E(C)（原版 local pass，再原版 global algorithm），最后检查经节点实例
  操作数处的记录钩子读对象类型；option b 用于失败与等待两种情况，再接节点修补；默认做法路径只在 option b 的学习报错且 pass 做过 binding 选择时；
  有字段待定的 learning run 就是 tolerant；没有 guard、memo、重试。A/B 对 s3a（277 个任务、70,148 次调用加 stage 0 测试 100 次）：TERM 0、
  VERDICT 0（两个方向）、TEXT 2,737（都在两者都拒绝的调用上；按原因 X1 1,230 原版 global algorithm 跑在 E(C) 上，X2 150 报错策略，X3 822
  tolerance 改述，X4 535 其余；按形状 603 只差内部参数编号、185 编号与约束顺序、1,214 诊断细节、735 先报另一处错误；没有新措辞）。local pass
  返回的 26,226 个结果都由原版代码在 E(C) 上复算，全部 aconv；I2 回退 0 次；cargs 探针 0 R1 违反；RR_Mut 抓到 14/16。安静计时（两次 227 行中
  223 行相差 5% 以内）：增长形状 0.95–1.05、嵌套 λ/let 0.95–0.99、左 spine 1.12–1.21、learning 链 0.94–1.12、头部靠求解定类型的链 1.65–10.86
  （去掉 `dot_propagate` 所致）、D3 行 0.94–21.13、报错行 0.96–1.88、无点 0.98–1.05；25 行比 s3a 慢 5% 以上。按 5% 规则：prefix replay 去掉
  （0 处结果变化、各行 ≤ 1.1%）；`domain_expect` 去掉；`dot_propagate` 保留（**我的决定**，偏离 ESR3_ARCH §3.5）；`dot_wild` 去掉；tolerance 用 I12。
  自查修了两处设计错误（预测轮次在每个 term 上都跑、生成重复算表；生成对每个对象强制全 term 扫描）。剩余：C1 链上每一环一次全扫描（let/λ 链
  0.94–1.12，s3a 0.71–1.02）；C2 完整 C 时用原版 global algorithm（m=60/64 的干净失败行 0.94–1.07，s3a 0.74–0.95）；C3 tolerance（操作数 λ 行
  1.16/1.08）。已另起 agent 做 s3c（`reviews/round3/s3c/`）：放回 `dot_propagate`、去掉 prefix replay、消除 C1（只重扫来源变了的 spine）、尝试消除
  C2/C3、移植 D15 开关（默认关，待用户批准）、重写 RR_AB 的两个门槛，再对 s3b 做 A/B 与安静计时。
- 本机磁盘 97% 满（剩 59 GB）；`reviews/` 共 4.7 GB（brainstorm 2.0 GB、s3a 714 MB、s3b 500 MB、learning 425 MB 等），是否清理请用户定。
- `s3c/` 完成（`README.md`、`RESULTS.md`、`eng/s3b_to_s3c.diff`；`out/` 4.9 MB）：`dot_propagate` 发布（其条件在每次 learning run 自己的约束上检查，
  与统一预测不冲突；它只决定生成后仍待定的字段，预测表覆盖的字段从不待定，实测 0 个重复）；prefix replay 默认关、只作测试开关；C1：第二轮起复用
  先前各轮的 spine 解与载体选择（`dot_rounds_reuse`，纯函数故精确，43,568 次调用复算 0 差异）；C2 的一部分：选择已完整的 learning run 在生成前
  结束（`dot_learnt_complete`，10,115 次调用起作用）；D15 开关 `dot_object_own_type` 移植、默认关；RR_AB 门槛 C4、R7 改写。对 s3b A/B：
  70,148 次调用加 D15 探针 91 次，TERM 0、TEXT 0、VERDICT 0；RR_AB 68/68；RR_Mut 14/16；cargs 0 R1 违反。D15 开关开：探针恰好 d15 的 14 处，
  语料 0 判定改变，7 处被拒文案改变（"type of v is unknown" → "neither a constant nor a field of v :: T"）。安静计时（22:24–23:30 UTC，227 行中
  221 行两次相差 5% 以内）：头部靠求解定类型的链 k=2/8/24 1.29/1.17/1.11（s3b 1.65/3.98/10.90）；链报错 k=24 1.45（s3a 1.38）；λ 链 1.02–1.04；
  无点 0.99–1.04。14 行比此前最好的引擎慢 5% 以上：C2（`let` 链与干净接受行 0.94–1.07，s3a 0.71–0.97；要按构造返回原版在 E(C) 上的推断就得用
  原版的 global algorithm）；C3 实为预测在字段等待时的一次全 term 扫描而非 tolerance（操作数 λ 行 1.16/1.10，s3a 1.08/1.04）；C1 残余（链报错 k=24）；
  两行不足 1 ms 的报错。**我的决定：** 保留 `dot_rounds_reuse`（关掉 5 行慢 6–32%）；按 5% 规则去掉 `dot_learnt_complete`（不改结果、去掉不变慢）。
  引擎设计到此告一段落；中文决策材料 `reviews/round3/DECISIONS.md` 已更新 s3b/s3c 结果，等用户批复。cslh19 与本机上已没有我们的进程，资源监视器已停。
- 用户 2026-10-31："我没有看，请你帮我整理出我必须决策的要点（实现细节我不需要决策）我期望是没有需要我决策的，然后我们可以继续"。
  据此我按授权自己定下（都不改变需求：被接受的 term 仍等于原版对 E(C) 的推断、选择仍是规则在最终类型上的选择、无点文本不变）：
  - 采用统一的预测（偏离 §1.12 的机制，但被接受的 term 不变，只多接受原来误拒的、并让报错换成原版对另一处错误的报错）；采用 §1.12 放宽范围
    之外的几处重新推断（D14 重跑、节点修补、推迟重跑；性能实测更好或持平）；D3 的处理用节点修补；拒绝时的报错用原版对 E(C) 的报错，不要 guard。
  - D15 一致：决定与最后检查读对象自身的类型（`dot_object_own_type` 开），14 类本就违背 D15 本意的形状被拒。
  - 警告保持已批的对象规则（不放宽）；本文档 §3.1 旧提案"走到类型变量的分支不算"作废。
  - 点的前面也不许有空白；计算候选时去掉被包含的候选；locale 里登记随 morphism 走并加遮蔽规则；不加 Lean 式命名空间规则、第一版不自动登记
    datatype 选择器、不打印回 dot 语法；record 的 `more` 与 update 函数不登记；`record` 命令不发冲突警告；不做 theory 合并后的冲突检查。
  - 文案：在实现第一步跑出真实渲染后一次性交用户过目（延后，不在此时请用户决定）。
  需要用户决定的只剩四项（性能代价、coercion 打开时的 D14、现有文本的兼容性、几处功能限制），用 AskUserQuestion 询问。
  **用户答复（2026-10-31）：** 性能代价——批准（常见写法 0.95–1.2 倍；救回的 term 约 3 倍；报错最多约 1.7 倍；原版指数级嵌套且只有新做法能接受的
  term 最多约 20 倍）。D14——用户先问：t 的类型不需要 adhoc_overloading、只是 term 里出现重载常量时，性能会不会下降。兼容性——用户要求具体讲
  两点。功能限制——用户问 `Thy.origin.xpos` 是否被读成"Thy 的 origin 字段的 xpos 字段"，并提议只考虑 `(...).xpos` 这种括号形式（假设不给 list、set
  配置字段），问是否更安全。
  我回答后，**用户 2026-10-31 第二次答复：** D14（coercion 打开时，对象类型只能靠 adhoc_overloading 定出）——**接受**（即 d14on 的做法，
  需从 adhoc_overloading.ML 导出 2 行 `is_overloaded`）。兼容性 (1)——用户不明白 `case xs of x.y ⇒ x.y` 里 `x.y` 为什么是变量而不是常量，
  认为这可能是 Isabelle 已有的 bug，并要求举例说明"有歧义的文法"；(2)——要求举例看报错信息。括号形式——用户问：若要支持把 `Thy.origin.xpos`
  解析对，成本大不大？做法是常量优先、改为在各段中匹配最长的常量前缀。
  **用户 2026-10-31 第三次答复：** case 模式那个漏洞（`case xs of x.y ⇒ x.y` 今天把 `x.y` 当模式变量，拆分后会坏）——**接受**。
  分段规则——**赞同改为"最长常量前缀"**（整个标识符是常量就用常量，§1.9 原样；否则从长到短找最长的、本身是常量的前缀当对象，其余是字段；
  都不是常量时最左一段当对象），因而 `Thy.origin.xpos` 读作 `xpos Thy.origin`，原先的妥协 K1 消失。用户追问：(a) 情形 B（误拼常量、但某处登记过同名
  字段）如果同名字段很多会怎样；(b) 当第一段是固定变量或绑定变量时，能否不走常量前缀那条路（避免 `λseg. seg.start.xpos` 被读成选择器常量），
  是否容易实现。有歧义文法那一点（K7）用户这次没有明确表态。
  **用户 2026-10-31 第四次答复：** 字段列表上限——赞同"最多列若干条再加一行 `and N more`"，10 条（8 也行）；**定为 10**。用户提议：先常量优先，
  等到解析之后真正要把它对应成常量的那一步（那时有 binder 信息）再看第一段是不是绑定变量、再拆分，问是否可行；认为单独的 `seg.start` 也应改成
  局部变量优先，问 §1.9 是什么；要求规则必须统一：要做"第一段是绑定或固定变量时最左一段当对象"就要对单独的标识符和链统一做。
  **用户 2026-10-31 第五次答复：** 选"统一局部变量优先"，推翻旧 §1.9，主要考虑性能，并请我再做一轮自主设计迭代找好方案；随后补充：会有一个
  configuration option，默认关闭，用户手动开启后 dot 语法才生效（所以兼容性问题只在开启时出现）。已写进 §1 第 9、13、14、15 条（第 15 条汇总
  当天其他决定；其中"误拼常量情形 A/B"与"有歧义文法 K7"用户没有逐字表态，我按已同意的上下文记入，并在答复里请用户确认）。
- 第四轮设计迭代（2026-10-31 06:00 UTC 起，Workflow `wqkyn6sso`，目录 `reviews/round4/localfirst/`）：四个设计 agent 并行——A 在 `decode_term`
  用绑定变量表 `bs` 判断并解决翻译自造 binder 的卫生问题；B 在绑定时（`abs_tr`、`absfree_proper`、`mk_binder_tr`、case、推导式、let 等绑定路径）
  把首段等于绑定名的长名字改成字段访问；C 在 `ast_to_term` 早拆、在 `decode_term` 晚定（对象成了绑定或固定变量就是字段链，否则退回常量、
  最长常量前缀或最左一段），并处理把长标识符当名字用的翻译；D 设计开关（作用域、关闭时零开销地挡住每个部件、名字提案）、局部变量优先下的
  警告（两个方向）、开启时真正改变含义的 AFP 位置数。之后裁决 agent 选或综合（`JUDGE.md`），验证 agent 对抗检验（`VERIFY.md`）。需求：
  关闭时同原版（含开销）；开启时第 9 条精确成立且卫生（对象的含义恰等于在该处单写第一段的含义）；开启时无点文本开销同原版、拆分的标识符开销小；
  兼容性实测分类；文案只作提案、剩余妥协列出大小。
- 用户 2026-10-31 第六次答复：误拼的带限定名常量（情形 A 保留今天的 `Undefined constant`、情形 B 用第 1 步文案）——**批准**。有歧义文法（K7）
  要求具体举例，并要求起 Opus agent 查 AFP 里有没有类似用法：已起 agent（`reviews/round3/k7scan/RESULTS.md`），扫描 Pure、HOL、AFP 中接受名字类别
  （`longid_position`、`longid`、`id_position`、`id`、`idt` 等）并由翻译当名字用的记号，判断哪些与 term 位置有歧义（K7）、哪些现有文本在那里传了带点
  的标识符（K6/K7 的实际暴露），给出 file:line 与例子。K7 的构造例子：`Dot_Parse_User.thy` 91–100 行（`"_nm_name" :: "longid_position ⇒ logic" ("NM _")`，
  parse translation 把名字变成字符串字面量；另有 `"_nm_term" :: "logic ⇒ logic" ("NM _")`），原版 `NM a.b` 读作 `STR ''a.b''`，拆分后选 term 那棵树。
- 07:10 UTC 前后网络中断：第四轮的四个设计 agent 与裁决 agent 都失败，验证 agent 在没有设计输入时被启动。已停掉该运行（`wqkyn6sso`），在脚本里
  加上"目录里有中断留下的半成品就接着做"与"设计没有全部完成就不进入裁决、裁决失败就不验证"，重新运行为 Workflow `wj379fh4g`；k7scan agent
  用 SendMessage 从原处继续。
- `k7scan/` 完成（`RESULTS.md`）：K7（有歧义文法）在 HOL 与 AFP 中 0 例——能接受长标识符的名字类别都只在名字是常量时成功，而常量不会被拆分。
  带名字类别参数的 syntax 声明 788 个（HOL 319、AFP 469），其中只有 6 个直接取 `longid`/`longid_position`，都不受影响。K6 有 1 处真实用例：
  AutoCorres2 的 `CLocals` 查找记号接受 `fn.var` 形式的限定名（`CLocals.thy:629–641`），`AutoCorres2_Test` 的两个 theory 共 9 处
  （`tests/c-parser/factorial.thy` 232–288 行，如 `(actuals2 ⋅ alloc.ret')`；`fnptr0.thy:95`）；开关打开时这些会报 `exception Match raised`；
  CLocals 的打印也以 `s ⋅ alloc.ret'` 显示，打印出的目标贴回去在开关打开时不能解析。其余：case 模式里 390 个长标识符都是构造子或常量；
  HOL 的 binder 今天确实会把带点名字当绑定变量（`⋃i.j≤n. {i.j}`、`[x.y. x.y ← xs]`），但没有文本这样用。探针还发现一处要修的用户可见缺陷：
  `[x.y. x.y ← xs]` 在拆分下报 `Bad name binding: "dot_field name=x.y index=1"`（载荷文本露出），实现时要给出正常的报错。开关默认关闭，
  AutoCorres2 的那 9 处只在其 theory 主动打开开关时才受影响。

**压缩上下文前（2026-10-31 约 07:30 UTC）的完整清单：在跑的、未定的、要讨论的**

*正在跑：*（2026-10-31 约 09:40 UTC 已完成，结果见本清单之后的"第四轮"条目）
- Workflow `wj379fh4g`（第四轮，局部变量优先的实现设计）：四个设计 agent → 裁决 → 验证。产出 `reviews/round4/localfirst/{A-decode,B-binder,C-carrier,
  D-option}/DESIGN.md、RESULTS.md`、`JUDGE.md`、`VERIFY.md`。完成后：用中文向用户汇报；按我的授权采用裁决的方案（不改变需求的实现选择不必请示），
  其中的妥协、开关名、警告文案交用户批准。还要把 k7scan 的结果（AutoCorres2 `CLocals` 的 9 处、`Bad name binding` 露出载荷）转给最终方案处理。

*需要用户决定（等第四轮结果后一起提）：*（2026-10-31 已全部定下：第 1 项见 §1 第 14 条；第 2 项见 §1 第 8、16 条，只保留"读成常量"一个方向；
第 3 项见 §1 第 16 条；第 4 项见下。）
1. 开关（§1 第 14 条）的名字；作用域与在 locale、bundle、import 下的行为若有取舍。
2. 局部变量优先之下的警告（§1.8 要调整）：两个方向——第一段是局部变量而整个标识符或前缀也是常量（常量被遮住，迁移提示 `CONST`），以及第一段
   不是局部变量而读成常量（字段读法被遮住）；文案与 AFP 静态频率。
3. 第四轮方案若有妥协（性能或功能）。
4. AutoCorres2 `CLocals` 的 9 处在开关打开时报错：接受，或让设计特殊处理（开关默认关，只有那些 theory 打开时才受影响）。
   （第四轮的方案已解决，不再需要决定。）

*用户可见文案（在实现第一步跑出真实渲染后一次性请用户过目；我已推荐的写在括号里）：*
- 最后检查推翻选择的三条（候选：沿用已批文案的写法，见 `reviews/round3/DECISIONS.md` §5.2）；标准推断的 late clash（推荐用 `dot_late_rerun`
  重跑显示原版对 E(C) 的报错，删掉草稿）；stage 1 兜底（`Field access "t.xpos" was not resolved (internal error)`）；列表为空时省去那一行；
  列表最多 10 条加 `and N more`（已定）；括号形式下省去 `"c.xpos" is not a constant` 那半句；报错里未决定的字段显示为 `t.xpos`、`(mk y).xpos`；
  警告多读法时的末句与链上的读法；登记冲突四条与接口错误四条（`reviews/round3/INVENTORY.md` §D.6）；名字：`dot_field` / `no_dot_field`、组件 theory
  `Dot_Syntax`（父 session `Pure` 还是 `HOL`）、可选 attribute、`dot_constant_warning`、文法里的 `_dot_field`、`field_dot`、只用于输出的 `_dot_access`；
  `[x.y. x.y ← xs]` 一类 binder 里写带点名字时的正常报错（代替 `Bad name binding: "dot_field name=…"`）。
  （2026-10-31 状态：警告开关已定名 `dot_syntax_warning`，`dot_constant_warning` 不用；`[x.y. x.y ← xs]` 在第四轮方案下按原版读，不再需要这条报错；
  新增两条：字段不存在而写出的前缀是常量时的报错变体、内部名字 `_dot_ident`。完整清单以 §6.6 为准。）
- 全部文案底稿：`reviews/round3/tests-texts/TEXTS.md`（36 行）与 `INVENTORY.md` §D（41 行、17 个名字）。

*需要用户下令的构建与流程问题（实现第二步之前问）：* 私有树 Pure 批次、HOL 批次、发行版回归、AFP 构建（同时测警告频率与 K6/K7 计数，需临时选项
`dot_warning_rule`）、是否建自己的 golden、`tools/required_sessions.txt` 的内容、回归范围、AFP 构建的机器与超时、计时门槛、变异与审计只在第一步的
带插桩副本里（`reviews/round3/tests-texts/TEST_PLAN.md` §9–§10 共 14 个问题）。

*其他待用户回答：*
- 本机磁盘 97% 满，`contrib/dot_syntax/ai-artifacts/reviews/` 共 4.7 GB（brainstorm 2.0 GB、round3/s3a 714 MB、s3b 500 MB、learning 425 MB 等，都不进 git）：
  是否清理、清理哪些（我不会自己删）。
- 顺带发现的原版问题（与 dot 语法无关）：`max ((n :: int) + (2 :: nat) :: nat) (h3 (2 :: nat) m n)` 让 `COERCION_GEN_ERROR` 未捕获漏出；
  `coercion_args h3 + - 0` 下 `h3 n n n` 仍被接受。要不要做什么。
- 更早遗留：`contrib/dot_syntax` 首次提交的文件清单、README / LICENSE（GPL v2？）/ GitHub 描述文案、MLML 子模块、my_better_isabelle_prover README 里的链顺序。
  （2026-10-31 查看：`contrib/dot_syntax` 已是 MLML 的 submodule，已有一个提交 30f098e，不是我做的，见 §3.4。）
- （2026-10-31 新增）feature 仓库的暂存区里有别人未提交的 Isabelle2026 版树（`worktrees/Isabelle2026-dot_syntax` 与 `-stock`，分支
  `Isabelle2026/dot_syntax`、base `Isabelle2026/local_datatype`）：第一版的目标是否改为 Isabelle2026，或两个版本都做。

*我按授权已定、写进文档正文时照此（2026-10-30、31）：* 统一的预测（取代前瞻等）；§1.12 之外的几处重新推断；D3 用节点修补；拒绝时报原版对 E(C) 的报错、
不要 guard；去掉 `dot_wild`、`dot_memo`、guard、`domain_expect`、prefix replay、`dot_learnt_complete`；保留 `dot_propagate`、预测轮次复用；D15 一致
（`dot_object_own_type` 开）；coercion_args 修法 B、C；coercion 关闭时 D14 的重跑加标记与最后检查；载荷解析时为可读文本的 schematic 变量、stage 0
第一次见到时重建为 Free；解析器重复的 Earley 代码实现时改为 functor；登记用命令（组件 theory 里的关键字）、随 morphism 走加遮蔽规则、用时去掉被
包含的候选、同一关系判重与冲突、`Sign.typ_unify`、record 钩子不含 `more` 与 update、`record` 命令不发冲突警告、不做 theory 合并后检查、不加命名
空间规则、第一版不自动登记 datatype 选择器、不打印回 dot 语法；警告保持已批对象规则（第 9 条改后需按上面第 2 项调整），§3.1 旧提案作废。
最终引擎：`reviews/round3/s3c/eng/subtyping_esr2.ML`（HOL 侧）；stage 0 与 D14：`reviews/round3/stage0/`、`reviews/round3/d14on/`（推荐配置
`DOT_D14ON=on DOT_D14ON_MERGE=on DOT_D14ON_GATE=linked DOT_D14ON_SKIP1=on`）；解析：`reviews/round3/parse/`（分段改为第 9 条、括号只认 `)`）；
登记：`reviews/round3/registry/`；警告：`reviews/round3/warn/`；测试计划：`reviews/round3/tests-texts/TEST_PLAN.md`。

*之后的步骤：* 第四轮结束、用户定完上面几项后，由我亲手把 ESR v3 与衔接部分写进本文档正文（新章节），再送一次聚焦评审（含第一次评审 §5 的 8 项
"先定再复审"：插入所选登记、警告通道、record 自动登记、登记同一性、实施步骤、载体不外泄、载体编码、文档修正）；评审通过后进入实现第一步
（一个用户空间 ML 模块，cslh19 上用 `ML_process` 测，不需构建）；第二步私有树，每批构建需用户下令。

*工作规则（不变）：* 回复用户始终用中文（不写进记忆）；Isabelle 只在 cslh19 上跑（每个 agent 最多 2 个并发、`nice -n 10`、`taskset -c 0-7,10,11,14-23`；
计时只用 CPU 8/9/12/13 并经 `flock …/dot_syntax_timing/TIMING.lock` 排队）；启动前查 z3/cvc5，用户的 SMT 测试在跑就不启动；停掉 agent 或 workflow 后
清理它在本机与 cslh19 的进程；监视脚本放进 `bash -c`；agent 接近上下文上限时提前换新 agent 接手。
- `learning/` 第二阶段全部完成（`RESULTS.md` §6–8）：计时两次（13:10–14:10 UTC，负载 1.0–11.5，1,240 个比值中 1,230 个两次相差 5% 以内），
  对原版 E(C)：let 链 k=24/96 0.84/0.91（s2 19.8/128.9）；λ 链 1.02/1.03（s2 15.6/97.6）；自由变量链 1.26/1.20（s2 10.3/36.6）；D3 链 k=24
  0.81、1.00、1.34（s2 24.8、14.8、10.9）；wild 行 0.92–1.03（s2 拒绝）；节点修补行（C4 合取）2.83–3.46（s2 拒绝；被接受的对照在 s2 里也要
  2.72–3.34）；tolerant 行 3.00–3.50（s2 拒绝）；无点 1.00–1.03。`dot_glook` 关掉时链最多 2.17 倍（所以架构提案里统一的预测机制必须覆盖它）。
  `LRT_Esr` 上 learning/s2 0.98–1.02。guard 的代价只在拒绝时：C4 报错行 1.76–2.01 倍、链报错行 1.32–1.34 倍、固定与 λ 绑定报错行 1.01–1.15 倍；
  判定 0 处改变；guard 开时拒绝文案同 s2（E 的猜测除外），关时 231/68,696 处不同。变异：新探针 X1 在 guard 开时也抓到 prop_single
  （接受了与 s2 不同的 term）；X3 抓到 wild_err（文案）；glook_sort 仍抓不到（G 从不作用于写了 sort 的 binder，可能被条件 (i) 覆盖，未在代码中
  确认）。剩余妥协：自由变量链 1.20–1.35 倍；option b 自己学不出时的报错 1.61/1.24/1.10 倍（m=1/16/64）；guard（代价、文案、测试盲区）；
  guard 关时文案；E 的猜测文案（2,000 中 1 例）。
- `cargs/` 完成（`RESULTS.md`）：**s2 与 s1 的一处 R1 缺陷属实，只在运算符那一处**：运算符头部是已决定的字段访问（`x.f a`）时，操作数按
  外层的 `coercion_args` 标志推断（`update_coerce_arg` 读到的头部是没有声明的 `dot_access`），而原版在 E(C) 上按所选登记头部的声明。62 例探针
  里 9 例违反 R1（例 `k.f2 (ch n)` 被接受为 `cg2 k (ch (int n))`，原版拒绝 `cg2 k (ch n)`；local pass 与 global algorithm 两条返回路径都有，含
  late decision、前瞻选择、链），7 例误拒（原版接受）。对象在选择前推断的那一处代码不同，但造不出改变结果的例子。实测原版的 `-`：不禁止操作数
  本身被转换（`cff n` 得 `cff (int n)`），禁止操作数内部的转换（`cff (ch n)` 被拒）以及写明运算符类型时的转换。修法 A：新函数 `explicit_head`
  把运算符 spine 头部已决定的载体换成其节点实例，两处调用点改用它；修后 9 例都以原版文案拒绝，误拒中 6 例变为 SAME；154 个任务 66,318 例
  判定、接受的 term、文案 0 处改变。修法 B = A 加上"选择先于对象已知时对象也用所选头部的标志"，结果与 A 相同。**我的决定：采用修法 B**，
  已通知 s3a 并入。剩 CV9 误拒（learning run 里字段尚未决定时其操作数已失败）：已请它把修法 C 做完并测。
  修法 C 完成：`t $ u` 中 `t` 的 spine 头部是尚未决定的字段访问时（local pass 里字段在等待，或 global run 里字段在生成时待定），操作数 `u`
  按 permit 推断（外层 permit 时 s2 本来就这样，所以只在外层 forbid 下有变化）；两处调用点对运算符 spine 三分：已决定的载体 → 所选头部的声明，
  未决定的载体 → permit，没有载体 → 原版。返回的 term 不变的理由：返回 typing 的 global run 里没有待定字段（否则 `learn` 抛 `RELEARN` 或报错，
  或抛 `LEARNT`）；local pass 以 `Done` 结束时，permit 只在字段等待期间生效，字段之后被决定会抛 `REDECIDE`、外层 frame 从自己的输入状态带着
  选择重跑，从未被决定则该 pass 不返回 term。修法 C 只能改变 learning run 传出的选择、被拒 term 走的路径和拒绝文案。剩一处理论上的误拒风险
  （R5，不涉及 R1；s2 在外层 permit 下本来就有，未见用例）。92 例探针（新增 UC1–UC27、UB1–UB3，都在参数被声明为 `-` 的 `cfm` 之下、字段在
  节点处未决定）：0 例违反 R1，无一由标志造成的误拒；原版拒绝的 27 例全部以原版文案拒绝；UC20（`t` 的类型始终未知）按规则拒绝，文案变为
  已批的"type of t is unknown"。154 个任务 66,318 例对 s2 与修法 B 均 0 处变化。**我的决定：采用修法 C（叠在 B 上）**，已通知 s3a。
- `stage0/` 第二阶段完成（`RESULTS.md`；cslh19 上三份原型副本 `proto`、`proto2`、`proto3`）：
  - 154 个任务对 s1：coercion 打开 DOT-ERR→SAME 6 例（都是 battery 里不开 coercion 的比较），关闭 16 例，别无变化；无 DIFF、EXPL-ERR、
    超时，54 个 fuzz 计数相同。强制恢复 s1 的推断末尾报错时，77 个 coercion 关闭任务的判定与 s1 完全相同。报错里露出原始载体：s1 1,362 行，
    现在 0 行。coercion 关闭时 1,377 条文案改变：1,358 条只是载体改为 `t.xpos` 式渲染；10 条是现已决定、但 E(C) 本身也失败的 D14 用例，
    现在显示原版对 E(C) 的文案；9 条退化（T1）：beta 规范化之后的 stage 1 报错指名被代入的对象、引用用户没写的文本（如 `(λt. t.head = y) xs`
    报 `"xs.head" is not a constant`），`parse/` 的载荷（带所写文本与位置）可修。
  - **发现并修了一处 R1 违反：** 第一阶段"字段跨轮留在 term 里"的设计接受了三个原版对 E(C) 拒绝的 term（如 `kk2 ((λt. t.xpos) (mk k))`，
    `kk2 ⇌ "id :: nat ⇒ nat"`）。原因：adhoc_overloading 插入的变体擦掉全部类型、放在常量当前的类型下，登记类型只用于挑选
    （`adhoc_overloading.ML:115-116, 161-177`）；点形式第一轮里未决定字段的结果类型还是自由的，变体按更一般的类型选出，之后没有东西再加上
    `nat`。修法（`DOT_STAGE0_D14=restart`，DESIGN §4.5）：stage 0 检查在上下文里保存第一轮的输入；后面某轮决定了字段，就以写明该选择的
    E(C) 从头重跑 stage 0，结果按构造就是原版对 E(C) 的推断。三例变为两者都报错；154 个任务上 0 判定、0 文案改变。
  - 变异：`ignore_annotation` 原预测无影响，实际让 stage 0 循环不收敛（超时），说明对带类型的载体常量合一先前约束是必需的设计元素；
    `keep_tags` 无害。
  - 计时（负载 8–9；原型比设计至少多一次原版推断，所以是上界）：无点 0.984–1.005；节点上决定 m=10/60 为 0.986/0.909；一个 late field 1.036；
    宽 λ 0.962；由最后合取式定类型 1.039；D14 1/10 处访问：继续方案 1.37/1.60，重跑方案 1.69/2.16。
  - **schematic 载荷与 `expand_abbrevs` 的冲突已解决（DESIGN §6.4）：** 冲突属实（默认模式报 "Unbound schematic variable"）；`close_form`
    又确实需要 schematic 载荷（Free 载荷下 `primrec` 报 `Extra variable "dot_field.xpos"`）。做法：解析仍产生 schematic 载荷；stage 0 检查
    第一次看到载体时、在推断之前把它们重建为 Free 载荷（在重跑方案里就是给载体编号那一步），所以 schematic 载荷到不了 `expand_abbrevs`，
    `close_form` 也看不到 Free 载荷。实测与 Free 载荷在全部测试和 77 个任务上相同；只在推断结束时才换不够（推断中途的 5 条消息打印失败）。
    否决的编码：TFree 标记（坏 `singleton_fixate`）、类型构造子标记（未声明类型）、常量载荷（termify 会反射载体）。解析侧只需
    `dest_access`/`dest_payload` 认两种载荷。
  - 剩余妥协：K1 coercion 打开时 D14 仍被拒（20 例，已另起 agent 为方案 β 写原型）；K2 无点文本每次推断一次载体检测（测不出）；
    K3 termify 里的 D14 字段（0 例）；K4 D14 字段结果用于解析另一个 overloaded 常量时多一轮 stage 0（4 轮对 3 轮）；K5 R1 所需的重跑，
    D14 term 上是继续方案的 1.23–1.35 倍；T1 见上。

**第四轮：局部变量优先的实现设计（2026-10-31 09:37 UTC 完成，Workflow `wj379fh4g`）**
- （结果，2026-10-31 用户答复后补记；下面各条的"待批""待用户决定""等答复"以此为准）：五处与所述设计不同之处——(1) case 模式不拆、(2) 带点的模式变量
  保持原义、(3) 去掉位置的翻译内部不拆、(5) 开关关闭时登记照常：批准；(4) 每个 theory 从关闭开始：**不采用**，改为随 import 继承。剩余妥协：全部批准
  （限定名常量开销接受并尽力优化；几种少见情形写进文档）。打印读回的修正：批准（绑定变量换名、固定变量打印 `CONST`）。警告：只保留"读成常量"一个
  方向；"第一段是局部变量而也是常量"不警告（颜色已表明读法）。名字：`dot_syntax`、`dot_syntax_warning`、bundle `dot_syntax` 批准。字段那一段的
  悬停与跳转：批准。讨论点 (1)(3) 随"不警告"消失，(2) 只剩报错变体的文案（实现第一步后过目），(4) 按授权写进文档。均已记入 §1 第 8、9、14、16 条与 §6。
- 产出：`reviews/round4/localfirst/` 下四个设计 `A-decode`、`B-binder`、`C-carrier`、`D-option`，裁决 `JUDGE.md`（及 `judge/`），验证 `VERIFY.md`
  （验证用原型 `verify/proto/`，结果 `verify/results/`；`V_Attack.results` SUMMARY 61 过 4 败，4 败是有意构造的 A22、E01–E03；`V_DProto.results` 69 过 1 败，
  败的 H20 是下面"case 模式按今天读"的有意改变）。
- **采用的方案**（我按授权采用，正文照此写；细节 `JUDGE.md` §3）：开关打开时，`ast_to_term` 把长标识符 `a.b.c` 的第一段写成普通自由变量
  `Free "a"`，放进该标识符 `_constrain` 节点的第二个参数（原版放 token 位置的地方）：`_dot_ident $ Free "a" $ Free p $ Var (("a.b.c", 0), dummyT)`。
  所有 parse translation 像对待单独写的 `a` 一样对待这个 `Free "a"`：binder 绑定它，起新名字的翻译避开它。只有 `decode_term` 决定读法，
  依据是它是否变成了 `Bound`，不按名字查找。另有三处修补，都已在原型里实测：
  1. `Term_Position` 把 `_dot_ident` 项当作位置（`detect_position`、`decode_position`、`decode_position1` 认它，`strip_positions` 因此也去掉它），
     所以读、测或去掉位置的翻译看到原版的 term，其中的标识符按原版读、不拆；
  2. `_dot_ident` 项记下它所属的整个标识符（上面的 `Var`），翻译改过名的标识符不拆（`update_name_tr` 的 `point.xpos_update`）；
  3. 第一段被翻译变成别的 term（如把 `w` 变成 `w σ`）时按"不是局部变量"读，对象就是那个 term。
  `decode_ident` 的判定顺序见 `JUDGE.md` §3.5。HOL 不改；Pure 改 `syntax_phases.ML`、`term_position.ML`、新文件 `dot_field.ML`、`attrib.ML` 一行
  （登记开关）、`proof_context.ML` 签名一行（导出 `is_const_declared`）。开关的值每次 `parse_term` 读一次往下传；各引擎入口先查开关。
- 未采用：A（`decode_term` 按 binder 名字查找，靠输入文本位置做保护、另需第二次翻译；AFP Simpl 调用导出的 `decode_term` 时不卫生）；
  B（每个 binder 翻译都要参与，改 HOL 5 个文件，不参与的报错）；C（新的包装 term，每个翻译外要套异常重试，并改 `case_tr`）。
- 验证（cslh19；用户空间原型，HOL 里读位置的翻译 `case_tr`、列表推导、`_lam_pats_syntax`、`update_name_tr` 编译在打过补丁的 `Term_Position` 副本上）：
  裁决的探针 J01–J14 全如预测；A 的语料 oracle（HOL 10,025 条里 stock 能解析并检查的 8,280 条，每条最多 12 个短标识符 `x` 逐个改写成 `x.DOT`，
  要求等于原版对 `FLD_DOT x` 的读法）跑 4 次：无位置/有位置 × 无固定/固定 21 个常用名字并同时声明同名带点常量，各 41,458 处，0 处不一致；
  不固定的对照组 23,266 处不一致（读成常量），说明 oracle 抓得到；24 个卫生攻击（引号、case/λ 模式/推导式自造的名字、`let`、遮蔽、带类型与嵌套
  binder）全过；三处修补各自的错误版本都被探针抓到。开关关闭时 10,025 条的 raw term 与消息都同原版。
- 计时（CPU 8/9/12/13、排队锁、`nice -n 10`，同进程交替轮次）：开关关在两份相同副本的差异（0.2%）之内；开关开、无点文本在噪声内；开关开、
  限定名常量（第一段不是局部变量）每个 +0.5–1.1 µs，只由这种标识符组成的文本 +0.6–1.3%（来自原版代码之前的固定变量测试与常量测试；
  去掉需要 Pure 里能带位置、不抛异常的常量查找）；拆分的标识符比普通标识符多 0.4 µs（不含选字段与类型推断）；一次 `Config.get` 40 ns。
  `(e).f` 的第二次解析未测（没有原型含它；只在第一次解析失败后才跑）。
- k7scan 的两项由此方案解决：AutoCorres2 `CLocals` 的 9 处（`strip_positions` 之后按原版读，不拆、不报错；J03 是同形状的探针）；
  `[x.y. x.y ← xs]` 露出载荷（J14：按原版读成 `map (λx.y. x.y) xs`）。上面"需要用户决定"的第 4 项因此不再需要决定。
- **更正（已在 §1 第 9 条加注，要告诉用户）：** 1,786 处是第三轮对警告次数的估计（`reviews/round3/warn/DESIGN.md` §9.1）。B、C、D 独立扫描的
  含义改变处数：某 theory 打开开关时 AFP 约 9,100–10,500（D：10,543 处、155 个 session；D 抽查 24 处 20 对、验证抽查 8 处 6 对，可能偏高
  15–20%，方法参数里的事实名是误报来源之一），HOL 约 450–620。约 93% 是同一写法：locale 参数与 interpretation 前缀同名，
  `locale functor = C: category C … for C` 之后的 `C.arr f`（Category3 约 4,000，ResiduatedTransitionSystem2 约 1,200–1,300，Bicategory 约 900–1,200）。
  D 的 10,543 处中约 9,900 处变成报错（`C` 的类型没有字段 `arr`），643 处后面各段是 record 字段名、可能静默改变含义（"第一段是局部变量而
  也是常量"的警告会出）。开关关闭时都不变。
- **验证发现的新问题（裁决未列）：** 开关打开时，Isabelle 打印的输出不一定能读回。打印器用最短名字写常量；名字的第一段恰是该处的绑定变量或
  上下文的固定变量时，第 9 条把打印出的文本读成字段访问：`λb::nat. b ∈ b.E` 打印成 `λb. b ∈ b.E`；`b` 固定时的 `b.E ∪ …`；locale 里
  `C.arr + xpos C`（`C.arr` 是 locale abbreviation）。影响 Sledgehammer 的 Isar 证明、粘贴回来的目标等。我的建议（未做原型）：只在开关打开时，
  绑定变量的情形让打印器换一个绑定名（`λba. ba ∈ b.E`，同原版为避开同名自由变量而换名），固定变量的情形打印 `CONST C.arr`（正是开关打开时
  用户自己也必须写的形式）。待用户决定。
- **与用户所述设计不同之处（待批，`JUDGE.md` §8）：** (1) case 模式（及列表推导、λ 模式）里不拆，按今天读：`λoption. case v of option.None ⇒ 0 | _ ⇒ 1`
  的模式仍是构造子（字段访问不可能是合法模式，照字面只能报错）；(2) 带点的模式变量 `case v of Some b.x ⇒ b.x` 保持原版含义，外面有 `λb` 也一样
  （§1 第 15 条曾接受它改变含义，现在不变了）；(3) 去掉位置的翻译内部完全不拆、按原版读（Hoare 的 `_While` 变体、Statespace / Simpl / AutoCorres2
  的变量名、Shallow_Expressions 的表达式）；那里第一段是局部变量而整个标识符是常量时静默读常量；(4) 每个 theory 开始时开关是关的
  （`Theory.at_begin` 钩子），不随 import 继承；另一种是同其他 option 与 bundle 一样继承；(5) 字段登记在开关关闭时也记录（否则开关打开的 theory
  看不到之前定义的 record 字段；定义时每个字段 0.56 µs，两个不同的 700 条登记合并时 0.34 ms）。
- **剩余妥协（待批，`JUDGE.md` §9、`VERIFY.md` §5）：** 开关开时限定名常量的 +0.5–1.1 µs（实现时试着去掉）；不经自由变量绑定的翻译（只处理
  `_constrain` 的第一个参数）会让对象静默不被绑定（A22 演示；HOL、AFP 0 处；文档给翻译作者写规则）；翻译中途 decode 子项（AFP 只有 Simpl
  `hoare_syntax.ML:721` 一处）时第一段总是非局部；locale 里 `declare [[dot_syntax]]` 会延续到该 locale 以后的每个 context 与每次 interpretation
  （Isabelle 里一切 locale 声明都如此；文档建议用 `includes`）；ML 在 parse 与 check 之间改开关时得到原版关于载荷变量的报错；记录标识符的
  `Var` 对翻译可见（未扫 AFP 里检查 schematic 变量的 parse translation，估计 0，聚焦评审时补扫）。K2 的去除（`prepare_term` 传标志）我决定一并做。
- **警告（§1 第 8 条的调整，`JUDGE.md` §5）：** 两个方向都发，共用一个警告开关：第一段是局部变量、而整个标识符或至少两段的前缀也是常量时
  （读成字段访问，提示写 `CONST`；开关打开时也是迁移提示）；第一段不是局部变量、读成常量、而以常量前缀为对象的字段读法也成立时（已批文案不变，
  静态估计 0 处）。引擎的无候选报错在写出的前缀是常量时用一个变体，提到那个常量与 `CONST` 写法。文案在实现第一步后连同真实渲染请用户过目。
- 名字提案：开关 `dot_syntax`（四个设计都提这个名字）；警告开关 `dot_syntax_warning`（默认开）；bundle `dot_syntax`（组件 theory 里，不放 `Pure.thy`）。
- cslh19 上有两个 Naproche server（`/tmp/isabelle-xero/bash_script…` 启动，已运行 9 天与约 4 小时），是空闲的服务进程，来源不明，我没动。
- 用户 2026-10-31 的答复已记入 §1 第 9、14、16 条。警告的真实渲染（验证原型，cslh19）：`reviews/round4/localfirst/render/W_Render.thy`、`W_Render.log`
  （`λpoint::point. point.xpos`、固定的 `point`、`λb. x ∈ b.E`、`λp. p.q.xpos`、locale 里的 `C.arr`；`origin.xpos` 没出警告是原型登记表只是桩）。
  向用户提出的讨论点（等答复）：(1) 字段访问失败时只出报错、不出"常量被遮住"的警告（需把该警告挪到检查成功之后发，待设计验证）；
  (2) 警告里常量写全名加类型，同 §1.8 已批文案，locale 缩写写 `C.arr` 而非 `local.C.arr`；(3) 变量与它的 record 同名（`λpoint. point.xpos`）时每次都警告，
  我倾向保持；(4) 局部变量优先的后果：lemma 陈述里未声明的变量不是固定变量，`b.E` 在陈述里读常量、在证明里读字段访问（AFP 约 2,404 处），
  新代码 `lemma "state.pc > 0"` 在陈述里读成选择函数且无警告；建议写进文档（用 `fixes`），不加警告。另重提两项未答：开关关闭时字段登记照常、
  少见情形写文档；并讲解了"去掉位置信息的翻译内部不拆"（AutoCorres2 `actuals2 ⋅ alloc.ret'`、Shallow_Expressions `(p.xpos + 1)\<^sub>e`、
  HOL-Hoare `WHILE … VAR {…}`）。
- 前端标记（用户问 jEdit 里的颜色；实测 `render/W_Markup.thy`、cslh19 上的 `W_Markup.log`，截取 PIDE 报告）：开关打开、`λb. x ∈ b.E` 里的对象 `b`（偏移 9–10）
  得到与单独写 `λb. x ∈ b` 完全相同的标记 `bound` + 指向绑定处的 entity（jEdit 绿色，悬停/ctrl-click 连到 `λb`）；固定变量 `C` 得 `free` + `fixed` entity（蓝色），
  隐式自由变量 `p` 得 `free`（蓝色）。`.E` 部分没有任何标记；原版的 `b.E` 整体是 `const` + constant entity（jEdit 不给常量上色，但悬停显示常量、ctrl-click 跳到定义）。
  所以颜色上 `E` 与常量一样是默认色，但悬停与跳转没有了。我的提案（用户可见的 IDE 行为，待批）：选定字段后在字段那一段报告所选常量的标记
  （同单独写 `xpos` 时的 `const` + entity），悬停显示 `point.xpos`、ctrl-click 跳到 record 定义。
  jEdit 真截图（cslh19，Xvfb，临时用户目录，`jedit -n`；测试命令 `dot_term` 只用原型解析、不检查）：`render/jedit_full.png`、`render/jedit_zoom.png`，
  `render/W_Shot.thy`、`render/shot.sh`。每次 jEdit 运行会留下一个孤儿 Naproche server，已杀掉自己的两个。

**第五轮聚焦评审、第六轮 D14 与新旧计时对比（2026-10-31 至 11-01；2026-11-02 整理时从 §6.11 原样挪来）**
（以下是过程记录：第五轮聚焦评审、第六轮 D14、新旧计时对比与用户逐项答复的经过。其中"未达开工条件""须用户
决定的 6 件""仍待用户答复""bundle""恢复 `is_overloaded` 导出"等都已过时，结论见 §1 第 14–24 条与 §6 正文。）

**聚焦评审（2026-10-31 16:57 UTC 起，Workflow `w9ii95pcf`，用户要求的形式）：** 两轮对抗辩论，全程英文，全部 Opus、xhigh。第一轮五个审查角度
（engine、parsing、userfacing、elegance、verification）各一个 agent，各提至多 8 条质疑（按严重度排，另列"放宽规约可更优雅"的提议）；第二轮每条
质疑各起一个全新的 agent 辩护（驳倒 / 部分成立 / 成立、是否钻牛角尖、最优雅的修法、是否须用户决定）；最后一个 judge 删除低质量与钻牛角尖的意见，
排出留下的问题并分为"须与用户讨论"与"我自定后再送评审"，列出放宽提议，裁定是否达到实现第一步的开工条件。产出 `reviews/round5/focused/JUDGE.md`。
用户要求：结果用中文汇报全部问题与修法计划，**用户同意之前不改代码**（也不改本设计）。
**结果（2026-10-31 约 18:00 UTC 完成；`reviews/round5/focused/JUDGE.md`，863 行）：** 裁定**未达开工条件**。架构不需重做；22 条质疑删 6 条（5 条并入重复项、
1 条被驳倒），留 16 条（9 major、7 minor）。须用户决定的 6 件（按顺序）：目标版本（JUDGE 3.12）；D14 的机制，连同 coercion 关闭时的重跑在 class
target 里违反 R1 的缺陷（3.5，推荐 `check_terms` 里统一重跑，放宽 4.1）；打印读回的形式（3.7，推荐按原版"取下一个可访问的更长名字"，放宽 4.2）；
bundle 在 `no` 下反而打开开关（3.3）；字段那一段标记的措辞（3.9、4.5）；登记命令是否不受开关影响（3.11、4.6）。另有放宽提议 4.3（放弃
coercion_args 修法 A–C）、4.4（去掉 I1a，一律原版重推断 E(C)）、4.7（第一版不做 `(e).f`）、4.9（计时门槛规则一次批准），4.8 待第一步数据后再定。
其余（3.1 引擎改为"原版代码 functor + 钩子"、3.2 载荷在 `check_terms` 入口重建、3.4 去掉 I1b 捷径、3.6 D14 与 v3/D15 的组合、3.8 新验收门槛、
3.10 误拼限定名在 `decode_ident` 判、3.13–3.16 测试方法与文档）由我定、改完送短评审。尚未改设计，等用户答复。
**用户答复（2026-10-31）：** 目标版本只考虑 Isabelle2026（§1 第 17 条）。D14 的机制：用户说"这是与实现相关的，也不是我定的"，要我交 Opus agent
团队讨论、找最佳方案。已起 Workflow `wb88peqm3`（目录 `reviews/round6/d14/`）：四个设计 agent——A 在 `check_terms` 统一重跑、B 修好现有两套机制、
C 在引擎内部模拟 adhoc_overloading 的选版本规则（不重跑、不嵌套）、D 开放搜索并给出"第一版不支持 D14"的基线及其代价（AFP 扫描）——之后裁决
（`JUDGE.md`）与对抗验证（`VERIFY.md`），全部 Opus、xhigh，原型在 cslh19 的 Isabelle2026 官方发行版（`~/Isabelle2026`，自带 HOL heap）上跑。
结果若含需求放宽或新妥协，仍须用户批准。其余五件（打印读回、bundle 的 `no`、字段标记措辞、登记命令与开关）与放宽提议 A–D 仍待用户答复。
（`wb88peqm3` 的四个设计 agent 跑了约 85 分钟后都因网络中断 ENOTFOUND 失败，只留下 `proto/`、`probes/` 半成品、没有 DESIGN.md；cslh19 无残留进程。
网络恢复后以同一脚本重跑为 `w1a3iq81s`，设计 agent 按提示从目录里的半成品接着做。）
**D14 结果（2026-11-01 约 08:30 UTC；`reviews/round6/d14/JUDGE.md`、`VERIFY.md`，原型在 `judge/proto/`、`verify/`，cslh19 上的 Isabelle2026）：**
裁决综合了 C 与 D：引擎在"字段因对象类型未知而要报错"的地方，先把它的学习输出（字段留作不解释的载体）交给原版检查跑到第 0 级结束（嵌套的
学习运行，开关关、不报告、带学习标志；第 1 级的 dot 检查见到学习标志就带着批次结束），从那里读对象类型、按规则选，再用引擎已有的晚决定路径
（标准引擎 `decide_late`，coercion 引擎 `RELEARN`）在同一次推断里决定；每个这样的字段一个标记，第 1 级做最后检查。不重跑、不改 `check_terms`
与 `check`、不改 adhoc_overloading.ML 与 overloading.ML、不需要 `is_overloaded` 导出；取代 §6.5.2 的重跑与 §6.5.3 的 d14on。守卫：对象类型与某个
常量（不算载体与 `check_terms` 为类型报告追加的 `TYPE` 项）共享类型参数时才学。Pure 约 70 行、HOL 约 35 行。R1：coercion 开时按构造（I1b/I1c）；
关时靠已有的晚决定论证，验证用 8,110 个批次直接比对第 1 轮输出与原版对 E(C) 的第 1 轮，0 差异。R2 按构造（对象类型来自原版第 0 级，字段不参与；
最后检查）。class target 缺陷消失；154 个任务对 A 0 判定变化，coercion 打开时恰好 20 个 D14 例变为原版 term。验证找到两处误拒并给出修法（我按授权
采用）：(1) 学习运行中另一个第 0 级检查调用 `check_terms` 时只在含载体的批次上结束（约 2 行）；(2) 学习运行在每轮第 0 级推断后、展开前记录对象类型
（约 5 行，只在学习运行里多一次遍历），因此裁决的妥协 1（被 β 归约丢掉的字段）不再需要。
须用户批准：(a) 开销超过已批：相互依赖的 D14 链每层多一次学习运行，深度 3 为 3.75×（coercion 开）/ 2.85×（关），深度 5 为 5.52× / 3.94×；相互依赖的
do 块 2 个绑定 3.08×（开），3 个 4.04×（关）（已批"约 3 倍"）；报错：对象被 `∀`/`∃`/`{x. …}` 绑定或参与 `=`/`∈` 时守卫打开、白跑一次学习，单处访问
1.33–1.49×，十处 1.63×（开）/ 2.23×（关）；只有第 0 级之后才暴露的第 3 步错误 2.41× / 2.95×（E(C) 本身也失败）；`(λt. t.xpos) (mk y)` 1.53× / 1.73×
（已批"报错约 1.7 倍"）。降报错开销的替代：只对重载常量与缩写开守卫，要恢复 2 行 `is_overloaded` 导出并加一个钩子。(b) R2 的残留：用户在字段结果上
写的类型（如 `(t.xpos :: int)`）可经另一个重载常量定出对象类型，`(λt. hh (t.xpos :: int) t) (mk y)` 被接受；所有设计共有；建议写进文档。(c) 两条共有的
小妥协：最后检查推翻学到的选择时直接拒绝不重试（0 例）；`termify` 里的 D14 字段不学（0 例）。文案：建议打开标准引擎已有的 `dot_late_rerun`
（E(C) 失败时显示原版报错），"第 0 级之后才暴露的错误"用规则文案并引用所写的标识符；随其他文案在第一步后过目。
仅供知情：开关关闭时多一次 context 查询（每次检查）；class specification 里守卫可能挡掉一次本可成功的学习（0 例）。
用户 2026-11-01 要求比较新旧版本的耗时。现有数字不在同一进程、同一时间测（旧版 = B 在 Isabelle2026 上移植的 base0，即第三轮的两套机制、s2 引擎，
`B-repair/DESIGN.md` §5.5，负载 11–12；新版 = 裁决原型，`JUDGE.md` §5，负载 1.6–2.5；报错行分母不同：B 除以原版对 E(C)，裁决除以基线 N）。
已起一个 Opus agent 在同样条件下重测（旧、新，必要时加 B 的 v3；cslh19、Isabelle2026、计时锁），输出 `reviews/round6/d14/compare/COMPARE.md`。
（2026-11-01 约 17:00 UTC：agent 已搭好全部计时（`compare/proto/`，55 行、两种模式，旧 = base0 与 v3，新 = 带两处修补的 NEW、近似设计开销的
NEW-observer、基线 N），只做了一次试跑（负载 17–29，仅供参考，`scratchpad/tr1.md`）；正式两轮待 cslh19 空闲（当时用户自己的 Isabelle2026 AFP
构建与 `/var/tmp/bicompose_fix/measure` 在跑，负载 38）。已挂后台检查，空闲后让该 agent 按 `compare/` 下的说明跑完并写 COMPARE.md。
试跑要点：被接受的 term，coercion 开时新旧多在 ±10%；依赖链与相互依赖的 do 块新版慢 10–40%（大半来自修补 2 的模拟方式）；coercion 关时新版为旧版
的 1.0–1.55 倍；报错：coercion 开、对象被 `∀`/`∃`/`Collect`/`=`/`∈` 约束时旧版约 1.0×N、新版 1.5–1.7×N；coercion 关、自由对象时新版便宜得多
（1.0–1.3 对 1.6–2.0）。实测证实 `bind_do` 缺口：旧版 coercion 打开时能接受 do 块只因原型模拟导出时展开了缩写，用真实答案则 8 个都被拒。）
**正式对比结果（2026-11-01，用户告知 cslh19 空闲后跑完；`reviews/round6/d14/compare/COMPARE.md`）：** 两轮（正序、倒序）各 100 次，12 个进程，负载 0.04–2.34，
三种原型 55 行判定全部一致，控制带 0.97–1.03（≥1 ms 的行）。列：OLD = base0；v3 = 旧机制放在 ESR v3 上；NEW = 验证原型（修补 2 用重推断模拟，偏高）；
NEW-observer = 设计实际做法的近似（每轮一次遍历）。按设计开销（NEW-observer）对 OLD：无点文本相同；被接受的 D14、coercion 开 0.89–1.13 倍
（深度 5 的链 5.41–5.48 对 5.30–5.35）；coercion 关时宽 term 与批次 0.86–0.97、链 1.11–1.14、相互依赖的 do 块 1.21–1.32（每层：OLD +0.44 E，
新 +0.57 E）；报错、coercion 开：对象被 `∀`/`∃`/`Collect`/`=`/`∈` 约束时 OLD 的 `linked` 守卫关着（约 1.0×N），新版守卫打开（1.33–1.64×N）；`mk y`
1.57–1.59 对 1.65–1.72；报错、coercion 关：新版便宜，自由对象 1.01–1.11×N 对 1.44–2.16×N，量词行 0.71–0.94 倍于 OLD。coercion 关的列都是上限。
因此此前请用户批准的"超过已批数字"的几行，按设计开销应读 NEW-observer 列：深度 3/5 的链 3.6–3.8 / 5.4–5.5（开）、2.7–2.9 / 3.8–3.9（关）；相互依赖的
do 块 3 个绑定 4.2–4.3（开）/ 3.9–4.0（关）；`∀` 下 10 处访问的报错 1.64（开）/ 2.19–2.25（关）。

**运行 agent 的资源规则**（用户 2026-10-30 要求，写进每个 agent 的任务说明）：所有 Isabelle 进程在 cslh19 上跑
（`~/Current/MLML/ai-artifacts/dot_syntax_timing/<目录>/`，每个 agent 最多 3 个并发、`nice -n 10`、`taskset -c 0-7,10,11,14-23`）；
计时只在 cslh19 的 CPU 8、9、12、13 上依次进行；本机只读代码、改 scratch 文件、处理文本；不留后台驱动脚本；
启动高负载工作前先确认机器空闲。停 workflow 后必须清理它在本机与 cslh19 上留下的进程（曾有残留的 `xargs -P 6` 驱动脚本把本机负载推到 75）。
回复用户始终用中文。

### 3.4 仓库与发布（用户 2026-10-28：在 contrib/ 下建专门的 GitHub 仓库，用 git 补丁机制，在 conda 上发布，仿照 light_locale）

已知的流程（`contrib/my_better_isabelle_prover/README.md` 的 "Working in the Isabelle source repository"
与 `RELEASE.md`）：
- feature 仓库 `contrib/<目录>`：放 `tools/patched_files.txt`、`tools/signature_additions.txt`、
  `tools/required_sessions.txt`、`.gitattributes`（`*.patch -text`）、`README.md`、`LICENSE`；
  `patches/<R>/` 与 `provenance.txt` 由 `make-patches` 生成，不手改；如需随包发布 theory，加
  `tools/component_files.txt`（light_locale 发布 `ROOT`、`Light_Locale.thy`、`README.md`、`LICENSE`）。
  计划文档放在该仓库的 `ai-artifacts/`（localized_record 等新 feature 的做法）。
- Isabelle 源码仓库里的分支 `Isabelle2025-2/<feature>`、私有树 `contrib/Isabelle2025-2-<feature>`、
  stock 树 `-stock`：由 owner 用 `new-tree --base` 建；agent 不得建分支或 worktree。
- 私有树里一切 Isabelle 运行走 `run-tree`；任何 `isabelle build` 都要 owner 下令或点名该树的长期授权。
- 发布：owner 下令 `make-patches`，再由 isabelle_patch_control 的 `release-features.yml` 批量发布到
  conda.qiyuan.me；包依赖其 base 包的确切版本。
- 补丁链：pristine → expose_foreign → future_assign_interrupt → light_locale → local_type_abbrev →
  localized_record → local_datatype → dev_patches。2026-10-28 查看：已发布的只有 expose_foreign/1、
  future_assign_interrupt/1；local_type_abbrev、localized_record、local_datatype 的分支尚无提交。
  会与 dot 语法改同一文件的：light_locale 改了 `syntax_phases.ML`、`syntax_trans.ML`、`proof_context.ML`、
  `Pure/ROOT.ML`；dev_patches 改了 `syntax_phases.ML`；localized_record 预计会改 `record.ML`（未核实）。（2026-11-02 注：localized_record 的计划
  只在背景 theory 的步骤里跑原版的 `finish`（含 `put_record`），`contrib/localized_record/ai-artifacts/LOCALIZED_RECORD_PLAN.md:740-785`；record 钩子在块里的改法见 6.4。2026 的链见 6.10。）

用户 2026-10-28 的决定与授权：
- 授权我运行 `new-tree`（建分支、私有树、stock 树；建分支需为这一条命令设 `ISABELLE_GIT_OWNER=1`）。
- 授权我用 `gh` 在 xqyww123 下建 GitHub 仓库（Light_Locale 与 isabelle-base-features 均为 PUBLIC）。
- 需要 `isabelle build` 时及时申请。
- 没有需要新增的 theory 文件就不随包发布 theory。
- 名字由我推荐、用户批准后再建。

2026-10-28 已完成（名字与位置见 §1 第 10、11 条）：
- `new-tree --base Isabelle2025-2/local_datatype Isabelle2025-2/dot_syntax`：新分支在 local_datatype 的
  tip `5826993`，私有树 `contrib/Isabelle2025-2-dot_syntax`；`new-tree --stock`：stock 树在同一提交
  （不是 base 的发布 tag，因为 local_datatype 尚未发布）。
- 用户授权后把 dev_patches 的 upstream 改为 `Isabelle2025-2/dot_syntax`（dev_patches 已含新分支的全部提交，
  无需 merge）。链现为 … → local_datatype → dot_syntax → dev_patches。
- 本地 feature 仓库 `contrib/dot_syntax`（`main` 分支，remote `origin` = `git@github.com:xqyww123/Dot_Syntax.git`），
  `.gitignore` 照 localized_record 排除 `ai-artifacts/probes/`、`ai-artifacts/reviews/`；尚无提交。
- `gh repo create xqyww123/Dot_Syntax --public` 被 Claude Code 自动权限检查拒绝（"创建公开内容"），
  GitHub 仓库尚未建立。

待定：GitHub 仓库由谁建；首次提交的文件清单（须逐个批准）；README、LICENSE（light_locale 用 GPL v2）
与仓库描述的文案；是否加为 MLML 的 submodule；`my_better_isabelle_prover/README.md` 里的链顺序说明是否要补上
dot_syntax（那是另一个仓库的文档）。另：本机根分区 2026-10-28 已用 98%（剩 33G）。

2026-10-31 查看到的变化（都不是我做的）：
- `contrib/dot_syntax` 已是 MLML 的 submodule（`.gitmodules` 第 74 行），已有一个提交 `30f098e`（2026-10-31 12:39 +0800，"Register the Isabelle
  trees of dot_syntax as submodules; init.sh puts them in place"）：加了 `.gitmodules` 与 `init.sh`（调用 `isabelle-patch-control new-tree`）。
  私有树与 stock 树因此在 `contrib/dot_syntax/worktrees/Isabelle2025-2-dot_syntax`（分支 `Isabelle2025-2/dot_syntax`，base
  `Isabelle2025-2/local_datatype`）与 `…/Isabelle2025-2-dot_syntax-stock`，都是 `github.com/xqyww123/isabelle-patched` 的 clone；原来的
  `contrib/Isabelle2025-2-dot_syntax` 已不存在。
- 暂存区（未提交）：`.gitmodules` 加了 `worktrees/Isabelle2026-dot_syntax`（分支 `Isabelle2026/dot_syntax`，base `Isabelle2026/local_datatype`）
  与 `worktrees/Isabelle2026-dot_syntax-stock`，两个目录已存在。第一版的目标版本是否随之改变，待问用户。
- 仍待定：首次提交里 `ai-artifacts/` 等文件的清单（逐个批准）、README、LICENSE、GitHub 描述、链顺序说明。`.gitignore` 尚未提交。
- **2026-11-01 "git 2026" 会话（开 Isabelle2026 发行线的那个会话）转来的通知：**
  1. 用户决定所有 feature 都移到 Isabelle2026，2025 线不再继续。私有树 `contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax`（分支 `Isabelle2026/dot_syntax`，
     已在 GitHub、跟踪 origin，在 7d475f7 = `Isabelle2026/pristine`），stock 树 `worktrees/Isabelle2026-dot_syntax-stock`（7d475f7）；base 是
     `Isabelle2026/local_datatype`（记在 `.gitmodules`，目前为空）。`contrib/Isabelle2026` 是 2026 的共享树（`Isabelle2026/daily`）。运行 Isabelle 用该树
     自己的 `bin/isabelle`，在没有 `ISABELLE_*` 变量的 shell 里；用户目录 `~/.isabelle/Isabelle2026-dot_syntax`。
  2. 流程见技能 `isabelle-patch-feature`（`contrib/my_better_isabelle_prover/.claude/skills/isabelle-patch-feature/SKILL.md`），升级是 §3.9；第 1、2 步已做，
     我从第 3 步开始：按用户命令提交登记（按路径）`git -C contrib/dot_syntax commit -- .gitmodules worktrees/Isabelle2026-dot_syntax worktrees/Isabelle2026-dot_syntax-stock`
     （现已暂存、未提交），再按用户命令 push。2025 上没有我的工作，所以第 4 步是在 2026 上从头实现。base 移动时：`git fetch`、在干净状态下
     `git merge origin/Isabelle2026/local_datatype`，再跑 `contrib/dot_syntax/init.sh`。
  3. 新规则（2026-11-01）：commit 与 push 都要用户下令（SKILL §2）。
  4. 发布构建：release-features.yml 先构建 HOL，再在五个平台上跑各 feature 自己的 `tools/release_build.sh`；首次发布前按 SKILL §3.4 第 4 步写
     （至少构建 `tools/required_sessions.txt` 的 session，用相对路径；macOS 慢）；新文件要用户批准。
  5. fast_abbrev_printing 的 golden 会话打印 HOL-Algebra 在 locale 与 class 上下文里的全部事实，从 Isabelle2026 起在它之上的每个 feature 的发布批次里都跑，
     dot_syntax 也在内：改变打印输出的 feature 必须保持这些字节不变（除非用户另有裁定）。dot_syntax 的打印改动（§1 第 16 条的 `CONST`）只在开关打开时
     生效，开关默认关闭，按设计不改变这些输出；实现时要用这些 golden 验证。（2026-11-11 fast_abbrev_printing 会话转告，用户同意转达：两个按字节比的 session 是
     `Fast_Abbrev_Printing_Fixture`、`Fast_Abbrev_Printing_Golden`，golden 在原版树上录，覆盖 HOL-Algebra 全部具名事实、theory 内与九个 locale/class 上下文、默认与 iff
     两种打印模式；发布前在 2026 私有树上查：`<私有树>/bin/isabelle build -d contrib/isabelle-base-features/golden -d contrib/isabelle-base-features/fast_abbrev_printing/tests
     Fast_Abbrev_Printing_Fixture Fast_Abbrev_Printing_Golden`——构建要用户下令。当前发布 `Isabelle2026/fast_abbrev_printing/2`；2026 的栈：pristine → bicompose_rename_fix →
     fast_abbrev_printing → light_locale（将改名 concepts）→ local_type_abbrev → localized_record → local_datatype → dot_syntax → dev_patches。）
  - 2026-11-02 按用户命令提交了第 2 步的登记（`b8f3070`，只含 `.gitmodules` 与两棵 2026 树的登记，按路径提交）；用户说先别 push，未 push。

## 4. 原型现状

- 最初的 `probes/Dot_Prototype.thy`（10-28）已过时，不再维护：`_constrain` 上的 parse translation 拆分；第 0 级按 record 字段与
  Lean 式命名空间规则选择；第 1 级报未解析；有短名退回查找、用 `Record.get_recT_fields` 而非 Net 登记、取第一个同名字段。
- 第一版各部分的参考原型（都在用户空间，cslh19 上用 `ML_process` 测过）：coercion 引擎 `reviews/round3/s3c/eng/subtyping_esr2.ML`；
  标准引擎 `reviews/round3/stage0/proto/`（其中 D14 的重跑部分作废）；D14 `reviews/round6/d14/judge/proto/` 与 `reviews/round6/d14/verify/proto/`
  （Isabelle2026；第三轮的 `reviews/round3/d14on/` 作废）；登记 `reviews/round3/registry/probes/`（改为只登记常量、attribute）；警告 `reviews/round3/warn/`；
  `(e).f` 的解析 `reviews/round3/parse/code/`；局部变量优先的解析 `reviews/round4/localfirst/verify/proto/`（含补过的 `Term_Position` 副本）。
  它们是分开做的，还没有合成一份；合成是实现第一步的事（§6.12）。合成时按 §6 去掉它们里已作废的部分：s3c 里的 coercion_args 修法 B/C 与 I1b 捷径，
  以及求解后读 `tye0` 的两处（6.5.1 D15）；stage0 原型里第 0 级重建载荷、丢失载体的测试与 D14 重跑；parse 原型里的 `[…].f`/`{…}.f` 与"只取最左一段"的
  分段；registry 原型里的命令与任意 term（改为只写常量、存原版标准读法的 term、标记取折回缩写后的头部常量，§1 第 1 条）。除第六轮的 D14 原型外都是
  Isabelle2025-2 的代码，在 2026 上编译不了（`Name_Space.markup`、`Variable.markup_fixed`、`Thy_Info.use_thy_legacy`、2025-2 的 light_locale 行），所以
  第一步的第一个子步骤是把它们移到 2026（6.12）。

## 5. 实验文件（`ai-artifacts/probes/`，不提交）

- `Const_Long.thy`：`CONST` 加长名字能取到常量。

- `Dot_Probe.thy`：今天的行为（`r.xpos` 报错、`λx.x` 报错等）。
- `Dot_Prototype.thy`、`Dot_Prototype_Test.thy`：原型与测试。
- `Dot_Paren_Test.thy`：`(e).f` 文法的歧义。
- `Split_Trace.thy`、`Split_Show.thy`：拆分函数收到什么、拆分结果。
- `Dot_Rounds.thy`、`Native_Rounds.thy`：轮数与计时。
- `Dot_Errors.thy`：第 1 轮出类型错误时错误信息露出占位常量。
- `Baseline_Clash.thy`、`Dup_Parent.thy`、`Nested_Type.thy`、`Partial_Type.thy`、`shadow/`：record 相关事实。
- `Net_Select.thy`、`Net_Messages.thy`：Net 选择规则与报错渲染。
- `Dot_Registry.ML`、`Warning_Demo.thy`、`Conflict_Demo.thy`：警告与登记冲突的演示。
- `config_merge/`（2026-10-31）：configuration option 随 import 合并的实测（§1 第 14 条、§2）。
- 评审与各轮设计的原型、结果在 `ai-artifacts/reviews/`（`brainstorm/`、`round3/<部件>/`、`round4/localfirst/`），同样不提交；
  `round4/localfirst/render/` 是警告渲染、前端标记截取、jEdit 截图与扔位置实验（2026-10-31）。

## 6. 第一版设计（正文；2026-10-31 起草，2026-11-02 按用户的全部决定改写）

本章把 §1 的全部决定（第 1–24 条）与各部件的设计合成一份完整的第一版设计。每一节先说这一部分是什么，再给关键规则，最后指向完整的部件设计文件；
部件设计文件是经过评审与实测的细节，本章与它们不同时以本章为准。§3.3b 是过程记录，不必再读。
**目标版本是 Isabelle2026**（§1 第 17 条）；下文的部件原型与实测都在 Isabelle2025-2 上做（第六轮 D14 与新旧对比在 Isabelle2026 上），实现时在 2026 上
从头写并重新验证。2025-2 与 2026 之间与本设计相关的差异：adhoc_overloading、overloading、type_infer、`src/Tools/subtyping.ML`、term_position 没变；
`type_infer_context.ML` 一行（`variant_bounds` 前 `Name.clean`）；`syntax_phases.ML`、`syntax_trans.ML`、`proof_context.ML`、`record.ML`、
`case_translation.ML`（现为 `declare_term_names`）、`variable.ML`（`markup_fixed` 返回 `Markup.T list`）、`General/name_space.ML`（只剩 `markups`，返回列表）
有改动，实现时逐一核对。
参考原型移到 2026 是第一步的第一个子步骤（6.12）。2026 的补丁链与重叠见 6.10。

### 6.0 需求（不变）

- **R1**：开关打开时，每个被接受的 term 都等于原版对显式形式 E(C) 的推断结果（`aconv`，含类型；coercion 开与关两种情形）。
  E(C) 是把每个 `x.f` 按选定的登记 C 写成 `g x` 后的 term。
- **R2**：每个字段的选择都等于选择规则（§1 第 3 条）在对象最终类型上的选择；对象类型在不借助这个字段的情况下确定；查字段时不考虑
  coercion，对象用它自己的类型（D15，用户 2026-10-30 确认，§3.3b；2026-11-02 定为"一个字段只在不看它时求解剩下的类型上决定"，6.5.1）；D1（字段名只有
  一个登记时直接选它）不做。
- **R3**：开关关闭时一切同原版，包括开销；开关打开时，不用 dot 语法的文本也同原版（例外见 6.8，均已批）。
- 其他任何变慢或误拒都是妥协，必须经用户批准；用户能看到的文字都先提案。

### 6.1 一个 `x.f` 的完整路径

用一个例子走一遍：`record point = xpos :: int ypos :: int`，开关打开，读 `λp::point. p.xpos + 1`。

1. **词法**（原版不变）：`p.xpos` 是一个长标识符 token。
2. **语法树变 term**（`ast_to_term`）：`p.xpos` 照原版变成 `_constrain (Free "p.xpos") 位置`，只是位置那一格放的不再只是位置，而是
   `_dot_ident (Free "p") 位置 ?"p.xpos"`：第一段作为普通自由变量、原来的位置、完整名字（6.3.1）。
3. **parse translation**（原版不变）：λ 的翻译把 body 里所有 `Free "p"` 换成绑定变量，包括藏在位置那一格的那个。
4. **`decode_term`**：看到 `_dot_ident` 的第一项已被绑定，按 §1 第 9 条读成字段访问，生成载体 `Pure.dot_access ?载荷 (Bound 0)`；
   对象 `p` 用只盖住 `p` 的位置交给原版代码，所以 `p` 得到绑定变量的前端标记。
5. **检查阶段**：`check_terms` 入口先把载荷重建为 Free（6.3.3）。选字段的引擎（coercion 打开时是 HOL 的 coercion 引擎，关闭时是 Pure 第 0 级的
   标准引擎）在 `p` 的类型 `point` 上按选择规则选出 `point.xpos`，按原版推断 E(C) = `λp::point. xpos p + 1`，再做最后检查；`check_terms` 出口在
   `xpos` 那一段报告所选常量的前端标记（6.6）。
6. **第 1 级**：`dot_unresolved` 检查确认没有载体留下。

结果与原版读 `λp::point. xpos p + 1` 的结果相同（R1）。

### 6.2 开关与作用范围（§1 第 14、16 条）

- `dot_syntax`（bool，默认 false）与 `dot_syntax_warning`（bool，默认 true）在 `src/Pure/Syntax/dot_field.ML` 用 `Config.declare_bool`
  声明，在 `src/Pure/Isar/attrib.ML` 紧挨 `Syntax.ambiguity_warning` 登记。不提供 bundle（§1 第 14 条，2026-11-01）；用法是
  `declare [[dot_syntax]]` 与 `declare [[dot_syntax = false]]`（`[[dot_syntax]]` 也可用在其他接受属性的地方）。
- 作用范围同 Isabelle 其他 configuration option：随 import 继承；两个 import 显式设了不同值时 `imports` 里靠前的胜出；从没设过的不参与
  （实测 `probes/config_merge/`）。不加"每个 theory 从关闭开始"的钩子（用户 2026-11-02 重新确认，§1 第 14 条）。文档写五点（第七轮深度复审问题 10；
  Isabelle2026 探针 `reviews/round7/deep/review-decisions/P_Scope.out`、`defend-surface-2/probe.out`）：
  1. 限定范围用原版的 `context notes [[dot_syntax]] begin … end`：可写在 theory 层、`context L begin … end` 里，包住一个或几个 lemma，块一关就恢复；
  2. `lemma notes [[dot_syntax]]`、`using`、`supply` 只作用于证明，陈述按原开关读（expression.ML:312）；
  3. theory 层的 `declare` 传到所有导入者，父 theory 的值不同时 `imports` 里靠前的胜出；
  4. 库 theory 用限定块；
  5. 在 locale、无名 `context begin … end` 块、light-locale 块里不用 `declare`：locale 里的 `declare` 到达该 locale 以后每个 context、导入它的 locale、
     sublocale 的目标、每个 interpret 它的 theory（从那条命令起）及其导入者；两种块里的 `declare` 作用于整个 theory。
- 开关在每次 `Syntax_Phases.parse_term` 读一次，往下传给解析的各部分；`parse_typ`、`parse_sort` 一律当关闭。各引擎入口先查开关（一次
  `Config.get`，实测 40 ns）。引擎假定一个 term 在解析与检查时开关相同；ML 在两者之间把开关关掉时，检查就是原版的检查，载荷是 schematic 变量，
  原版的结果（G4 实测，2026-11-04 更正；写进文档）：一般模式下 `expand_binds` 报 `Unbound schematic variable`（`proof_context.ML:716`），它打印载荷的
  文本（不带类型）；载荷里所写的名字带点时（标识符形式，及字段那一段多于一段的括号形式），打印本身先失败，报 `Bad name binding: "dot_field index=… field=… name=…"`；
  schematic 或 pattern 模式下原版不报错，term 里留着 `Pure.dot_access ?载荷 对象`。
- 开关只控制读 term（解析与选字段的引擎）。字段登记表不看开关（6.4，§1 第 16 条）：record 自动登记照常记录且不出消息；用户显式写的
  `[[dot_field …]]` 不论开关开关都照常检查、报告冲突，删除登记总能执行。原版文本里没有 `[[dot_field …]]`，所以不影响 R3。

### 6.3 解析

#### 6.3.1 长标识符与"局部变量优先"（第四轮方案；`reviews/round4/localfirst/JUDGE.md` §3、`VERIFY.md`）

- **藏第一段**：`ast_to_term` 在 `_constrain` 节点上，若开关打开、token 带位置、含点、每段都是普通标识符（`Dot_Field.is_ident_token`），
  就把第二个参数写成 `Dot_Field.ident_marker` = `_dot_ident $ Free 第一段 $ 位置 $ Var ((完整名字, 0), dummyT)`；否则同原版。
- **`Term_Position` 认它**：`detect_position`、`decode_position`、`decode_position1` 把 `_dot_ident` 项当作它里面的位置，`strip_positions`
  因此连同藏着的第一段一起去掉。于是读位置、测位置、去位置的翻译看到的都是原版的 term。常量名 `_dot_ident` 放在 `Term_Position`。
- **`decode_term` 决定读法**（新函数 `decode_ident`，在一般的 `_constrain` 分支之前），按顺序：
  1. 名字那一项已不是记下的完整名字（被翻译改过名，或被模式变量整个绑定）→ 原版读法；
  2. 第一段被绑定 → 字段访问，对象是该绑定变量；
  3. 第一段是固定变量（与 `Proof_Context.lookup_free` 的条件相同）→ 字段访问，对象是该固定变量；
  4. 原版能无错地读出整个标识符（它是常量，或 `Proof_Context.lookup_free` 能读到它，如 ML 声明了默认类型的带点自由变量）
     → 原版读法（原版 `decode` 的 Free 分支）；第一段不是局部变量时的警告（6.6）只在读出的是常量时计算（第五轮评审 3.16）；
  5. 有本身是常量的前缀（取最长的，至少 2 段、少于全部）→ 字段访问，对象是该常量，其余各段是字段；
  6. 否则：先看是不是误拼的带限定名常量——第一段单写会读成隐式自由变量（与原版 `Free` 分支同一测试），且**没有任何**登记的字段名等于第二段
     （`Dot_Field.defined`，用登记表自己的查找）→ 交给原版 `decode` 的 Free 分支读整个标识符，原版在解析时报 `Undefined constant`（带位置与补全），不加任何
     标记（§1 第 15 条；第五轮评审 3.10，取代第三轮"引擎里调 `check_const`"的做法）；否则 → 字段访问，对象是"第一段单独写在这里"时的读法：
     隐式自由变量；第一段本身是常量就是常量；被翻译变成了别的 term（如 `w σ`）就是那个 term。
  "是常量"用不抛异常、不算补全的测试（`Proof_Context.is_const_declared` 加 `Variable.lookup_const`；`proof_context.ML` 签名加一行；r8 里是
  `Dot_Field.is_const_name`）。（曾加过一个不抛异常的 `decode_free` 同时判定第 4 行并给出读法，代码评审后删去，2026-11-10 r8：原版 `decode` 的 Free 分支
  原样保留，只是 `decode` 多一个参数 `site`，这一分支的模式里多一个 `_`。）
  "字段访问"把对象连同只盖住对象那几段的位置交给原版的 `decode`，再套上各段的载体（`Dot_Field.accesses`）。名字从不在绑定列表里查找。
  记下完整名字的 `Var` 对翻译可见；第一步前扫描 AFP 里检查 schematic 变量的 parse translation（估计 0）。——2026-11-03 扫描完：AFP 与 Isabelle2026
  `src` 里 0 处（`ai-artifacts/step1/ref/afp_var_scan/REPORT.md`；碰到它的 5 处都原样返回或只记进随即丢掉的 context）。同时查到 Simpl 的 `infer_type`
  （hoare_syntax.ML:720-721）在 parse translation 里直接调导出的 `Syntax_Phases.decode_term`，是 Pure 之外唯一的直接调用者，不经 `parse_term`：
  `decode_term` 导出的签名不变，这条路上也要处理掉标记，开关值拿不到 `parse_term` 传下来的那一份（6.2），拟由导出的 `decode_term` 自己读一次（子步骤 4 定）。
- **卫生**由构造保证：凡经自由变量绑定的翻译（`absfree`、`abstract_over`、`Term.lambda`、de Bruijn 下标）都会扫到藏着的第一段；起新名字
  的翻译也会避开它。不经自由变量绑定、只处理 `_constrain` 第一项的翻译会让对象静默不被绑定，HOL 与 AFP 里 0 处（写进文档）。
- **不拆的地方**（均已批）：case 模式（及列表推导、λ 模式）按今天读；带点的模式变量保持原版含义；去掉位置的翻译内部（Hoare 的 `_While`
  变体、Statespace / Simpl / AutoCorres2 的变量名、Shallow_Expressions 的 `(e)\<^sub>e`）按今天读。
- **实测**（验证原型 `reviews/round4/localfirst/verify/proto/`，HOL 中读位置的翻译编译在补过的 `Term_Position` 副本上）：语料比对——HOL 语料
  10,025 条里原版能解析并检查的 8,280 条，把其中的短变量 `x` 逐个改写成 `x.DOT`，要求对象的含义恰等于在同处单写 `x`——4 次运行（输入带或不带
  位置 × 不固定或固定 21 个常用名字并声明同名带点常量）各 41,458 处，0 处不一致；开关关闭时 10,025 条的 raw term 与消息都同原版；24 个卫生攻击、
  裁决的探针 J01–J14 全过；第四轮设计 D 的 70 个探针 69 过，H20 因"case 模式不拆"按今天读。

#### 6.3.2 括号形式 `(e).f`（§1 第 13 条；`reviews/round3/parse/DESIGN.md` §5）

（2026-11-11 按 §1 第 27 条重写。此前的写法——原版解析失败后才做第二次解析、`field_dot` 兼当分隔符、把最少的点读成字段访问的过滤与权重、Earley 解析器
做成 functor 的两个实例——都已取代，过程见 §1 第 27 条与 §6.11 末各条。）
- 只认圆括号：开关打开时，词法在原版 token 序列上把"紧跟在字面 `)` 之后、前后都无空白、后面是标识符"的点标成 `field_dot`（`Lexicon.field_access_dots`；
  没有这种点时返回 `NONE`，token 不变）。开关关闭时不标。词法只认 `)` 之后的点（原型还认 `]`、`}`，按 §4 去掉）。
- **只解析一次。** 文本里没有 `field_dot` 时就是原版的解析；有时用同一个解析器、预测字段访问的产生式，解析一次。`field_dot` 只当字段访问，不兼当
  原版的分隔符点。所以开关打开时，紧贴 `)` 的分隔符点（`λ(x, y).x`、`{(x::nat).x > 0}`、`∀x ∈ (A ∪ B).P x`）必须在点前或点后留空白，否则读作字段访问——
  多半报错，少数恰有同名字段适用时静默改义（`{(x::nat).x > 0}` 读作含一个字段访问的单元素集合）。这是对 R3 的放宽（§1 第 27 条；Isabelle 库里不留空白的
  这种写法约占 0.8%，AFP 约 0.6%，只在该 theory 打开开关时受影响）。带 `field_dot` 的解析失败时，报错后附一段说明并指出那个点的位置（文案见 6.6）。
- 文法：Pure 文法多两条只用于输入的 `_dot_field` 产生式与终结符 `field_dot`。构建文法时，只有左递归的（第一个符号就是自己的左部）、带 `field_dot`
  终结符的产生式不进 lookahead 表，单独存放（`field_prods`；§1 第 26 条 (1)；前提"左部不能推出空串"写在 Gram 的注释里，`logic` 满足）；两条若进表，
  开关关闭的解析在 HOL 文法上多 4.6%（`reviews/round3/parse/RESULTS.md:77-87`）。解析器只在当前位置不超过最后一个 `field_dot` 的下标时预测它们
  （"下一个 token 是 `field_dot` 才预测"做不到：产生式要在点之前、内层 term 开始处就建）。开关关闭时 `print_syntax` 也列出这两条产生式（如 `print_options`
  列出开关），仅供知情。
- 解析器只有一个（2026-11-10 去掉 functor）：`parser.ML` 同原版是一个封装的 `structure Parser: PARSER`；`Parser.parse` 与 `Syntax.parse` 多一个参数
  `{field_dots: bool}`（`syntax.ML` 只这一行；两者在 Isabelle2026 与 AFP 里唯一的调用者是 `syntax_phases.ML`）。为 `true` 时解析器自己在输入里找最后一个
  `field_dot` 的下标（下标按解析器自己的输入数，所以不交给调用者算）；为 `false` 时不扫，原版那条路上只多一次惰性的整数比较。
  实测（`step1/proto_single/g6parse/`）：开关关闭的解析对原版副本 1.002–1.003 倍（波动范围 ±0.005，规则 (2) 通过）；括号形式只看解析，是原版读显式写法的
  1.08–1.57 倍（`(p).x` 比 `x p` 多 4 个 token，项越长越接近 1）。`step1/proto_onepass/` 上测的（带 functor，解析比现在慢 2–4%）：整体读一个括号形式的 term
  （解析加检查）0.95–1.09 倍；开关打开时无点文本上标点扫描每条约 0.19 µs（用户 11-10 接受）。
- `ast_to_term` 里因此有两处新子句：标识符的 `_dot_ident`（6.3.1）与括号形式的 `_dot_field`（把字段 token 当文本读，绑定变量捕获不到字段）。
- 括号形式的载体在 parse translation 之前就已存在，`strip_positions` 会保留它，所以在去掉位置的翻译内部（如 `((p).xpos + 1)\<^sub>e`）它**是**字段访问，
  而标识符形式 `(p.xpos + 1)\<^sub>e` 不是。这一不对称有原则：括号形式今天本来没有含义（已告知用户，写进文档；第一步加一个仿 `mk_lift_expr` 的探针，
  按 R1 与显式写法比较）。

#### 6.3.3 载体与载荷（`reviews/round3/parse/DESIGN.md` §6、`reviews/round3/stage0/DESIGN.md` §5、§6.4）

- 载体：`Pure.dot_access $ Var ((载荷, 0), dummyT) $ 对象`，常量在 `pure_thy.ML` 声明。载荷是一段可读文本，如
  `dot_field index=2 field=xpos line=1 offset=18 end_offset=22 id=1 name=s.start.xpos`，字段名、字段位置、对象前缀都从它推出。（2026-11-04 按 G6 改编码，
  实现细节：字段名与字段那一段自己的位置直接记下；变长的所写文本 `name` 放最后、不转义，解码不随它变长；引擎在一个批次里按载体的 key 查已解码的
  载荷，不重复解码。原先每次整段解码，字段链上开销随长度平方增长。）
- **一条规则：检查阶段之外载荷是 schematic 变量（`close_form` 需要），检查阶段之内是 Free（`expand_abbrevs` 需要）。** 重建放在 `check_terms` 的入口：
  `Type_Infer_Context.prepare_positions` 的 `Var` 分支里加一种情形（它只被 `check_terms` 调用，本来就在这里把解析期的编码换成检查期的编码），
  测名字前缀、只在遇到载荷时读开关，并给每个载荷一个 `serial ()`（D14 学到的选择按它对应，6.5.3）。第三轮"第 0 级第一次见到载体时重建"与 d14on 的
  第二种编码都去掉（第五轮评审 3.2：否则 coercion 打开时第 −100 级先跑，打印未决定的载体会报 `Bad name binding`）。检查阶段里所有读者只见 Free；
  print translation 两种都认（`parse_term` 的 "Ambiguous input" 报错打印未检查的 term）。
- 报错信息里载体按 `t.xpos`、`(e).xpos` 显示（只用于输出的语法常量与 print translation；打印器的 eta 缩约去掉了对象的载体还原成 `λx. x.f`，
  2026-11-04 补）；被接受的 term 里不会有载体。
- 载体不外泄：保证放在 `Syntax.check_terms`——第 1 级的 dot 检查报告每个留下的载体，与原版对 adhoc_overloading（adhoc_overloading.ML:221-222）
  和 `case`（case_translation.ML:461）的做法相同。把解析输出直接交给 `Type_Infer_Context.infer_types` 的代码会收到载体（引擎只经 6.5 的两个注册检查
  到达）；Isabelle 的 8 处、AFP 的 21 处直接调用都只传 ML 构造或已检查的 term，不受影响；文档给工具作者写一行（第三轮 K10）。（第七轮深度复审
  问题 14 更正了此前"直接调用者也由它决定或报告每个字段"的说法。第三轮"第 0 级检查确认展开没有丢掉未决定的载体"的测试随旧 D14 机制去掉：未决定
  的载体不再跨过第 0 级的轮次，第六轮裁决 §1.2。）

### 6.4 字段登记（`reviews/round3/registry/DESIGN.md`）

- **是什么**：一张表，回答"名叫 `f`、能接受类型 T 的对象的登记有哪些"。存在一个 `Generic_Data` 里的一个 `Item_Net`，key 是
  `Const (f, dummyT) $ Net.encode_type 模式类型`（§1 第 2 条）；查出后用 `Sign.typ_unify` 过滤（`Dot_Field.unifier`、`Dot_Field.candidates`；
  "可合一"与"匹配"是同一个函数换刚性变量集合）。选择、所有报错、警告、冲突检测都从 `Dot_Field.candidates` 取 U。
- **登记的是常量**（§1 第 1 条，2026-11-02 修订）：只能写常量（含 abbreviation、locale 里的局部常量），不能直接写任意 term。存下的是按原版标准方式
  读出的 term，与 `[[coercion f]]` 存下的 term 相同：`Syntax.read_term`（检查阶段展开一切缩写）之后在登记所在的 context 里做
  `singleton (Variable.polymorphic ctxt)`（subtyping.ML:957-960、adhoc_overloading.ML:259；context 不固定的类型变量成为 schematic，locale 的类型参数保持固定、
  由 morphism 实例化；第八轮短评审第 5 条）。`length` 存 `size` 在 list 上的实例，locale `foo` 里的 `bar` 存 `T.foo.bar $ Free ("n", nat)`。模式类型取该 term
  的类型的第一个参数；E(C) 就是 `t x`。先确认写的是常量、再展开（所用函数第一步定）。字段那一段的前端标记取这个 term 在当前 context 里折回缩写后的头部
  常量（6.6）。
- **来源**：`record` 为自己的每个字段登记选择函数常量（不含 `more` 与 update 函数；`record.ML` 在 `put_record` 后一处调用；不检查、不出消息；
  localized_record 进 base 之后改法见下面"record 钩子"）；
  用户用 attribute（§1 第 20 条）`declare [[dot_field 字段名 = 常量]]`，简写 `declare [[dot_field c]]` 即字段名取 `c` 的最后一段；删除登记写
  `[[dot_field del 字段名 = 常量]]` 或 `[[dot_field del c]]`。参数在 attribute 解析时就只收这两种写法（§1 第 26 条 (3)）：简写的 `c` 必须是一个标识符或长标识符
  token（带引号的名字、带类型的 term 都不收：按 token 种类严格读，用户 11-12 "建议简单一点，继续拒绝"），`f = c` 的 `c` 可以是带类型的 term；其余一律报
  看得懂的文案（6.6），不用默认 parser 的报错。没有命令，没有组件 theory；attribute 定义在 Pure 的 ML 里（加载在 `Isar/attrib.ML` 之后）。
  不自动登记 datatype 选择器，不加 Lean 式命名空间规则。
- **底层**：一个 `Dot_Field.declaration : {add, pos} -> (string * term) list -> Morphism.declaration`（字段名、读出的 term），attribute 与 record 钩子都
  调用它（attribute 用装着 declaration 的 token，`Token.Declaration`，所以收得到 morphism）。attribute 的参数照第三轮原型的形式：`Args.embedded_declaration`，
  context 由 `Scan.state` 取得，同 `Method.parse_tactic`（Pure/Isar/method.ML:326-340；`reviews/round3/registry/probes/Dot_Registry_Proto.thy:221`、`:327-339`）；
  读、检查与取 serial 都在读参数时做一次，不在 `fn phi` 里（第八轮短评审第 5 条）。
- **locale**：登记随 morphism 走，每个 copy 是 `Morphism.term φ t`；copy 只在不含 schematic term 变量、且其中每个自由变量在接收它的 context 里都是
  固定变量时保留（后一半是深度复审问题 1 的细化：light-locale 块里的登记原样作用到 theory 时，块内常量展开后带着 theory 层没有固定的块参数，这一份
  因此丢掉；第一步实测）；一个 context 自己的 copy 遮住它从 theory 继承的同一登记的 copy（按 serial，`Token.Declaration` 使 serial 只取一次）；与这样被
  遮住的 theory 副本相同（同一关系下相同，不是"是其实例"）的 theory 副本也被遮住（第八轮短评审第 4 条：`interpretation a: foo 3` 之后在 theory 层另写
  `[[dot_field a.bar]]`，新 serial 的 `foo.bar 3` 否则在 `context foo` 及其导入者里不被遮住，`xs.bar` 歧义；遮不遮仍只看登记表、不看对象类型，第三轮
  §3.2 的单调性论证不变；比它更具体的 theory 登记照旧可见）；
  用时去掉被别的候选包含的候选（同一关系：β-η 正规形下一个 term 是另一个的类型实例，即第三轮登记设计的关系；存的已是展开后的 term，所以
  `[[dot_field a.bar]]` 与 interpretation 带来的副本算同一条；同一登记取最新的）。**接受的缺口**：attribute 在 locale 里存为附注，
  在另一个 locale 的头部、interpretation 的 `rewrites`、`global_interpretation`/`sublocale` 的 `defines` 里看不到 locale 内的登记（第三轮探针 P08）；
  在 light-locale 块与无名 `context begin … end` 块里，`declare [[dot_field …]]` 作用于整个 theory、块关了还在、传到导入者（light_locale 的规矩
  REV37:3284-3299，原版无名块 generic_target.ML:407-409；用户 2026-11-02 确认）。文档同 6.2：限定范围用 `context notes [[dot_field …]] begin … end`，
  locale 与块里的 `declare` 到达的范围同 6.2 第 5 点。light locale 只保存语法声明，块内定义的常量登记成字段后出了那个块就失效（§6.11 的 2.1 状态；
  用户 11-02："light locale/setclass 先不管"）。
- **record 钩子在块里**（第七轮深度复审问题 11；不挡第一步，在 base 合并时做）：2026 链里 localized_record 在 dot_syntax 之下，它只在背景 theory 的
  步骤里跑原版的 `finish`（含 `put_record`），写进背景 theory 的东西在打开的块里看不见，所以"`put_record` 之后一处调用"在 `context`、locale、
  light-locale 块里定义的 record 上要等块关了才登记。改法（登记设计 `reviews/round3/registry/DESIGN.md` §8.2，:758-783，加细化）：在 `local_add_record`
  末尾、背景第 3 步之后、每条路径上写 `Local_Theory.background_theory (Context.theory_map reg) #> Local_Theory.map_contexts (K (Context.proof_map reg))`
  （localized_record 给 Induct 规则用的同一形状），去掉 `definition` 里那一行；`context -` 也算 theory 级，只写 theory 时看不见（`reviews/round7/deep/
  defend-integration-1/P_Defend.out` Q2）。合并时的块测试：嵌套 `context`、locale 的重开与 interpretation、light-locale 块、`context -`、ML 调
  `Record.add_record`。到时问用户：登记设计第 13 行"私有 record 的字段在作用域外可经 `r.x` 访问"是否接受。现在 localized_record 以上各分支都还在
  7d475f7，所以第一步不受影响。
- **冲突与检查**：显式登记总是检查（是常量、是函数）并按同一关系分类冲突、报告，不论开关；`record` 自动登记不报冲突；不做 theory 合并后的检查。
- **开关关闭时照常记录**（已批）：每字段 0.56 µs；两个不同的 700 条登记合并 0.34 ms。登记表里没有任何看开关的代码。

### 6.5 选字段

选择规则（§1 第 3–6 条）不变：在对象类型上求候选集合 U，空则报错，唯一则选（必要时细化对象类型），两个以上匹配则报歧义，否则等待；
不用结果类型消歧；对象类型推不出来就报错。

**两个引擎共同的不变式**（第五轮评审 3.1；第七轮深度复审问题 2、3 改述）：开关关闭、或 term 里没有载体时，各引擎逐字跑原版自己的函数。每个被接受的
term 都等于原版对 E(C) 的推断，经且只经下面三条路之一，各有各的保证与检查：
1. coercion 引擎的观察者实例（原版代码加一个返回 `unit` 的观察者，作用在 term E(C) 上）：按构造；
2. coercion 引擎的 I1a 捷径（若第一步实测后保留，§1 第 22 条）：按"无等待的遍历与原版代码形状相同"的论证，由 G2 的"每个 Done 重新推断对照"检查；
3. 标准引擎自己的推断（节点决定、晚决定、学到的选择）：按晚决定的论证（`reviews/round3/stage0/DESIGN.md` §3.4），由 G2 的第一轮审计检查。
引擎只经两个注册的检查到达：Pure 第 0 级替换 `"standard"` 的检查与 HOL 的 coercion 检查（6.10）。原版名字 `coercion_infer_types`（未导出，
subtyping.ML:7-13）绑定 functor 的无钩子实例。
- coercion 引擎：原版的 coercion 推断（local pass、约束生成、求解、插入 coercion）只写一次，做成以一小组钩子为参数的 functor，钩子之间是原版的
  代码，有三个实例：无钩子（开关关闭或没有载体时注册的检查）；只有一个返回 `unit` 的观察钩子，在节点实例的应用处记下操作数类型（在 term E(C)
  上做原版推断时用它，最后检查从它读对象类型）；带学习钩子（带载体的约束生成、宽容、`learn`；从不返回 term，2026-11-09 起由签名保证）。返回 term
  的实例根本没有学习钩子，以后的改动不可能误传。ESR 自己的 local pass（字段状态、REDECIDE 帧）是另一个函数，复用原版的辅助函数（`strong_unify`、
  `gen_coercion`、`function_of`、`insert_coercions`）。D6 的 spine 读法只用于 ESR 自己的遍历。（2026-11-09 修订，§1 第 26 条 (2)：原版 `update_coerce_arg`
  拆出 `coerce_arg ctxt old (f, n)`——查 `coercion_args` 与分派——原版函数只剩取头部与参数个数再调用它；D6 只留穿过类型标注读脊的几行，同样调用它。
  所以 `coerce_arg` 也是两边共用的原版代码。）若无钩子实例的计时超出波动范围，退路是带可选钩子参数、`NONE` 分支即原版那一行的函数（报用户；实测在
  波动范围内，未用）。
- 标准引擎：原版 `infer` 与 `infer_types` 一字不改，引擎放在旁边；先查开关，再测有没有载体（`exists Dot_Field.has_access`）。不加 `prepare_term` 标志
  （第三轮 K2 的那次遍历测出来在噪声以下；第五轮评审 3.1 撤回）。——2026-11-03 实现时：`infer` 里四个只在报错路径上用的局部函数（`prep_output`、
  `err_loose`、`unif_failed`、`err_appl`）提到外面供引擎共用（文本不变、`infer` 其余一字不改），不复制（用户的"不复制、要重构"规则；行为不变；开关关闭
  的开销照样在 G6 测）。

#### 6.5.1 coercion 引擎（HOL `src/Tools/subtyping.ML`，ESR v3；参考原型 `reviews/round3/s3c/eng/subtyping_esr2.ML`，架构 `reviews/round3/arch/ESR3_ARCH.md`）

- **核心**：找 C 与"原版对 E(C) 的推断 + 最后检查"分开。找 C 的各种机制只影响找得多快、找不找得到，不影响返回的 term 是什么。
- **返回 term 只有两处，都经同一个出口函数**（它做最后检查、为 D14 学到的字段建标记、再 `finish`；参数是该出口读对象类型的方式：I1a 读
  `accs_read` 的 `objT`，另一处读 `last_check_E` 的方式，`object_own` 优先；第五轮评审 3.6）。I1a 有两个出口——`done_result` 与推迟重跑成功的出口
  （原型 s3c:3285-3297，那里绕过了 `done_result`）——都经这个出口函数（r7 起代码里两者是 `after_local` 里的同一处调用）：
  - **(I1a) 捷径**（§1 第 22 条；去留由第一步实测定）：local pass 成功、且 C 里没有任何选中的常量带 `coercion_args` 声明时，直接返回 local pass 的
    结果（这里看的是节点上存下的 term 原样的头部，不折回缩写，同原版 `update_coerce_arg` 在 E(C) 上只看 `Const` 头部，subtyping.ML:291-300；第八轮短评审
    第 3 条）。原先写的另一个条件"过程中没有任何字段等待过"按构造对每个成功的 local pass 都成立，不是运行时测试（第七轮深度复审问题 2）：代码查的是"最后
    留下的那一遍里没有字段等待"——字段进等待表与计数器加一同时发生，只有帧重跑移走条目，并把等待表与计数器一起恢复（s3c:2047-2058、1363-1371），
    local pass 只在等待表为空时成功（s3c:2602-2604）。交付的代码不带 `waited` 标志与 I2 计数。所以 I1a 也返回晚决定、帧重跑、推迟重跑之后的 term。
    这里 R1 靠两个前提：(i) 无等待的遍历与原版代码形状相同——节点经 `node_instance` 展开加原版的应用步骤、参数编号（type_infer.ML:80-85）、D6 的
    spine 读法、`coercion_args` 条件；(ii) 帧从自己保存的状态重跑（I6）。不需要推迟引理（`reviews/round3/rerun/DESIGN.md:394-397`）。此前这个论证两次
    失败都出在 `coercion_args` 上（ESR3_ARCH §3.2a、第五轮评审 3.4），`coercion_args` 条件正好堵住这一类；实测 26,226 个经 `done_result` 的 I1a
    结果全部等于原版对 E(C) 的推断（第三轮 s3b；推迟重跑成功的出口当时没复算，s3c:3285-3291）。G2 的"每个 Done 重新推断对照"检查它，I1a 的两个出口都做。
  - **其余情形**：一次原版的 coercion 推断作用在 term E(C) 上（先 local pass，`COERCION_GEN_ERROR` 时再 global algorithm），即 functor 的观察者实例。
    第三轮的 I1b 捷径（"clean 且 C 含 binding 选择"时跳过原版 local pass 直接用 global algorithm）**去掉**：它在对象含应用时会返回与原版不同的 term
    （第五轮评审 3.4，实测）。
- **默认路径**（第七轮深度复审问题 2）：只在 option b 的学习报错、且 local pass 做过有约束力的选择（`binding_now`）时走；它最后的规则报错只在
  `binding_now` 成立、且这些有约束力的选择（C_bind）里没有带 `coercion_args` 声明的常量时报（这一句依赖"代码形状等同原版"）。它只会拒绝，影响判定与
  文案，不影响 R1。
- **一个拒绝判断**：编排里所有 handler 用同一个判断，不各写一套。（原为 `ERROR`、`LAST_CHECK` 两种；节点修补删掉后 `LAST_CHECK` 那一支走不到，
  2026-11-09 fix_rev1a 删去，现在只剩 `ERROR`。）
- **找 C 的机制（第一版保留的）**：节点上决定；等待与晚决定、对最小函数应用的重新推断（§1 第 12 条）；统一的预测（期望类型传播，加
  "已知选择的载体用其登记的值域"与 β-redex 头部两条来源；取代旧的前瞻、`own_type`、`dot_glook`），后续轮次复用已解的结果；推迟重跑
  （`dot_defer_rerun`）；global algorithm 里学习选择（D12：local pass 失败后在 dot 写法上对整个 term 跑 global algorithm 学选择，次数不超过依赖链深度
  加 1；D13：s1 的改动，其中的依赖守卫让对象类型与另一个待定字段的结果共享参数分量的字段先等；D9：求解后只认选择，没有任何一次决定的字段报规则
  文案（local pass 为该字段留下的优先，否则用求解出的类型上的文案；ESR2_SPEC §11 原写"求解前的类型"，由下面 D15 改）；定义见
  `reviews/brainstorm/ESR2_SPEC.md` §11），`dot_propagate`，有字段待定时宽容（I12：global algorithm 的一次运行在有字段
  待定时才宽容，所以可被返回的运行从不宽容；2026-11-09 起只保留弱合一那一处，构造子与运算符两处去掉，§1 第 25 条），~~成环规则~~（去掉，同上）；local pass
  失败后按 option b 从头学，~~候选被拒时做节点修补（`dot_repair`）~~（去掉，同上：候选被拒即按最后检查的文案拒绝）。
- **去掉的**：`dot_wild`、`dot_memo`、guard、`domain_expect`、prefix replay、`dot_learnt_complete`、I1b 捷径、`WAIT_REJECT`。拒绝时显示原版对 E(C) 的报错
  （C 完整时）。
- **`coercion_args`**（§1 第 21 条）：第三轮的修法 A、B、C 全部去掉，也不加第四处。选中的字段常量带 `coercion_args` 声明时，I1a 的 `coercion_args` 条件不成立，
  显式写法交给原版推断，R1 按构造成立。代价（已批）：字段要等待、且外层禁止而字段常量在参数里重新允许插入转换时会误拒（例与报错见 §1 第 21 条）；
  coercion_args 只在 HOL 内部的 case 常量与 `NO_MATCH` 上声明，AFP 里 0 处。
- **D15**（2026-11-02 修订，用户赞同；第七轮深度复审问题 4，§6.11 的 2.3）：**一个字段只在"不看它时求解剩下的类型"上决定。** 原先的写法
  （"查字段时用对象自己的类型，coercion 改变过的类型不用来选字段"）在对象类型由类型构造子组成时不成立：`ns :: nat list`、`ih` 只登记在 `int list ⇒ int`
  上时，`(λt. t.ih) ns` 被接受为 `hd (map int ns)`，因为 global algorithm 求解前看到 `?c list` 与 `nat <: ?c`，按规则第 4 步选中唯一候选并定 `?c := int`
  （s3c:2774-2780），求解后 `chosen` 还先试求解前的类型 `tye0`（s3c:2906-2910）。改法：求解之前，对象类型（经 `tye0` 读）里若有类型参数还出现在待解的
  子类型约束里，该字段先等（判据用 s3c 里 `propagate` 已算的 `tied` 集合，提出来共用；确切条件第一步定）；**求解之后只读求解出的类型：在求解出的类型上
  对该字段求一次决定，选择、D14 学习运行的触发（6.5.3）与规则文案都由这一次决定给出**（local pass 为该字段留下的规则文案仍优先）。参考引擎求解后有两处
  读 `tye0`：`chosen`（s3c:2906-2910），以及 `val d = decide (tye0, idx') key` 与 `field_error (tye0, idx') key d`（s3c:2921-2924；第六轮移植里同一个 `d` 还经
  `Dot_Field.Wait _ => h_learn …` 触发 D14 学习运行，proto/subtyping_esr3_restart.ML:3033-3048）；两处都改。只删 `chosen` 那一处，`field_error` 会报内部文案
  `Field "ih" is decided`（第八轮短评审第 1 条，读码推出的例子 `(n::nat) = (i::int) ∧ map (λt. t.ih) [ns] = []`）。先取 `Choose`，所以 `field_error` 的
  `Choose` 分支按构造到不了。没有约束的类型参数照旧按第 4 步细化（`?'z point_scheme` 上的 `cpoint.color`）。于是 `(λt. t.ih) ns` 与 `(λt. t.sqrt) n` 一样
  按第 3 步文案拒绝。另保留"查字段时用对象自己的类型"（`dot_object_own_type` 开）；新规则下它可能多余，第一步实测，多余就删。第一步要测：L1、L6、L7、
  L9、U17、U18（`reviews/round3/d15/`）；复合对象 `(xs @ ys).ih`、`(if b then xs else ys).ih`、`([n]).ih`；带类型标注的 binder `(λt::_ list. t.ih) ns`（可能在
  local pass 里就被决定，那时 local pass 同样处理或列为例外，报用户）；上面那个例子（按第 3 步文案拒绝，永不出现 `is decided`）；一个 D14 例子（确认学习
  运行仍被触发）；恢复 `tye0` 读法的变异两个（`chosen` 先试 `tye0`；`d` 与规则文案读 `tye0`）；数出失去的接受数，报用户。
- **D14**：见 6.5.3（在 `global_solve` 的已解状态里，字段因对象类型未知而要报错之前做学习运行，学到的选择用 `RELEARN` 重解）。
- **测试用的开关、计数器、审计**只在第一步从干净代码派生出的观察构建与变异构建里（6.12）；交付的代码没有。

#### 6.5.2 标准引擎（Pure `src/Pure/type_infer_context.ML`；`reviews/round3/stage0/DESIGN.md`）

- coercion 关闭时，标准引擎取代原版第 0 级的 `"standard"` 检查：新的引擎入口（原型里叫 `Type_Infer_Context.standard_check`，Isabelle2026 里没有这个
  原版函数）注册在原来的位置；原版函数不改，引擎在旁边；不含载体的文本只多一次载体测试，其余走原版代码。节点上决定、等待、对象类型确定后用合一补上
  （晚决定，`decide_late`），不重新推断（§1 第 12 条）；以最后检查结束。
- 这里 R1 靠论证，不按构造：返回的是引擎自己的推断（节点决定，加上用合一补上的晚决定），论证见 `reviews/round3/stage0/DESIGN.md` §3.4。第六轮验证在
  原型上做过直接比对（`reviews/round6/d14/verify/proto/type_infer_restart.ML:471-524` 的 `DOT_V_R1AUDIT`，8,110 个批次 0 差异），第一步要在新代码上
  重做，即 G2 的第一轮审计（6.12；第七轮深度复审问题 3）。
- 晚决定使推断冲突时，交付的代码直接采用原型里 `dot_late_rerun` 的做法（不是开关）：把冲突的晚决定放回节点重新推断，从而显示原版对 E(C) 的
  报错（只在这种拒绝上多一次推断；按授权定）。
- D14：见 6.5.3。第三轮的"字段留到后面几轮、从保存的第一轮输入重跑第 0 级"整套去掉（它在 class/overloading target 里违反 R1，第五轮评审 3.5）。

#### 6.5.3 D14：对象类型只能靠 adhoc_overloading 定出（§1 第 18 条；`reviews/round6/d14/JUDGE.md` §1、`VERIFY.md` §3、`compare/COMPARE.md`）

- **是什么**：如 `(λt. t.xpos) (mk k)`（`mk` 重载，`mkP :: int ⇒ point`、`mkO :: nat ⇒ other`，`k :: int`），第一次推断时对象类型未知，要等第 0 级的
  adhoc_overloading 换成 `mkP` 才知道；现实中最常见的是 do 块或 `⤜` 之后取字段（`Monad_Syntax` 重载 `bind`，do 记法生成 `bind_do` 缩写）。
- **机制（两个引擎相同）**：引擎在"字段因对象类型未知（规则第 1、6 步；coercion 引擎里在求解出的类型上判断，6.5.1 D15）而要报错"之前，若守卫成立，先做一次**学习运行**：把它的学习输出（当前
  typing 下的批次，字段仍是不解释的载体）交给原版的 `Syntax.check_terms`，在一个学习用的上下文里，一直跑到第 0 级结束；第 1 级的 dot 检查见到学习
  标志就结束该运行（`Dot_Field.LEARNT`）。
- **学习用的上下文**（第七轮深度复审问题 12）：不可见、不报告、带学习标志、`coercion_enabled` 设为 false（第六轮实测的形式，
  `reviews/round6/d14/verify/proto/Restart_Base.thy:759-790`；已批的 D14 开销也是这样测的，`compare/COMPARE.md:75`）；**开关保持打开**，所以开关
  关闭的路径一行不碰（按授权定，验证 §3.2 的备选做法；"学习运行关开关"已被复审驳回：会给每次开关关闭的检查加两次上下文查询，违反 R3）。查学习
  标志的只有两处：(1) 标准引擎的入口见到标志就跑原版 `infer`、按修补 (2) 记下对象类型、再跑原版 `expand_abbrevs`，不进引擎主体；(2) 第 1 级的 dot
  检查在含载体的批次上抛 `LEARNT`（修补 (1)）。coercion 关闭使 HOL 的 coercion 检查不跑（subtyping.ML:884-890 按 `coercion_enabled` 决定），所以 dot 版的
  coercion 引擎也进不了学习运行。由此两条性质在开关打开的形式下成立：学习运行里不跑任何引擎主体，所以那里不决定字段（R2）；只有引擎主体启动学习运行，
  所以学习运行不嵌套，一次推断的学习运行次数不超过载体数。可选：`Dot_Field.learn` 见到上下文已带学习标志时 `raise Fail`。
- **学到之后**：对象类型取自修补 (2) 在每一轮第 0 级推断后记下的类型，按规则选；选到的用引擎已有的晚决定路径在**同一次推断**里补上（标准引擎
  `decide_late`；coercion 引擎 `raise RELEARN (C + 学到的)`，之后经原版对 E(C) 的推断返回）。每个学到的字段一个标记，类型取该出口读对象类型的方式
  （D15），第 1 级的 dot 检查在对象最终类型上做最后检查并删去标记。学不到时报规则文案（第 1 或第 6 步；第 0 级之后才暴露的第 3、5 步错误报规则在学习
  typing 上的文案）。学习结果在该次引擎调用内保留，后续路径（option b、节点修补）不再学。直接调用 `infer_types`/`coercion_infer_types` 的代码到不了
  引擎（6.5），所以不学。
- **守卫**：某个载体的对象类型与某个常量（不算载体、也不算 `check_terms` 为类型报告追加的 `TYPE` 项）共享类型参数时才学。
- **验证提出、已采用的两处修补**：(1) 学习运行中另一个第 0 级检查自己调用 `check_terms` 时，只在含载体的批次上结束学习；(2) 学习运行里在每一轮
  第 0 级推断之后、展开之前记录对象类型（被 β 归约丢掉的字段也读得到）。
- **不改的**：D14 本身不改 `check_terms`、`check`（它们另因载荷与字段标记各有一处改动，6.10）；不改 adhoc_overloading.ML、overloading.ML；
  不需要 `is_overloaded` 导出；没有重跑、没有预置、没有跨 handler 的异常。第 0 级的 `"standard"` 检查与 coercion 检查要注册为 `term_check'`
  （才能把记下的选择通过上下文交回，6.6）。
- **已知的一处小误拒**（验证 §2.5，0 例；用户 2026-11-02 接受，§6.11 (b)）：class specification 里守卫可能挡掉一次本可选出字段的学习运行。
  Pure 约 70 行（`dot_field.ML` 的学习函数与守卫、标准引擎、第 1 级检查 2 行、载荷 serial 1 行），HOL 约 35 行。
- **R1/R2**：coercion 打开时 R1 按构造（学到的字段经 `RELEARN` 进入 C，之后经原版对 E(C) 的推断返回，不走 I1a）；关闭时靠已有的晚决定论证（第六轮验证在原型上用 8,110 个批次直接比对第 1 轮输出与原版对
  E(C) 的第 1 轮，0 差异；新代码上由 G2 的第一轮审计重做，6.5.2）。R2 按构造（对象类型来自原版第 0 级，字段不参与；最后检查）。class/overloading target 里不再重新推断，第五轮发现的缺陷消失。
- **已批的妥协与残留**（§1 第 18 条）：学到的选择被最后检查推翻时直接拒绝；`termify` 里的字段不学；R2 残留（周围文本对字段结果的类型要求可经另一个
  重载常量定出对象类型，写进文档）；超过原批数字的开销（6.8）。

### 6.6 报错、警告、前端标记与打印

- **报错，已定的**：§1 第 7 条的已批文案；三种字段列表（歧义候选、类型未知时的 "Fields named … exist for"、没有候选时的 "Fields of …"）一律最多
  5 条，多出的只写省略号（§1 第 19 条）；误拼的带限定名常量在没有同名字段登记时保留原版 `Undefined constant`（含位置与补全，在解析时由
  `decode_ident` 交给原版，6.3.1），有同名登记时用第 1 步文案（§1 第 15 条）；被拒的 term 若已决定了全部字段，显示原版对 E(C) 的报错。
- **报错与名字，待实现第一步跑出真实渲染后一次性请用户过目**（底稿 `reviews/round3/tests-texts/TEXTS.md`、`reviews/round3/INVENTORY.md` §D）：
  写出的前缀是常量而字段不存在时的变体（提到那个常量与 `CONST` 写法；还要说明第一段在此处不是局部变量，并提方程的 `for x` 与陈述的 `fixes`，
  例如定义方程里的 `seg.start.xpos`，第七轮深度复审问题 5）；最后检查推翻选择的三条（`reviews/round3/DECISIONS.md` §5.2）；候选行里的
  常量遇到第 16 条的 `CONST` 打印时的样子（如对象与 record 同名时的 `CONST point.xpos point`）；第 1 级兜底 `Field access "t.xpos" was not resolved (internal error)`；字段列表为空时
  省去 "Fields of …" 那一行；括号形式下省去 `"c.xpos" is not a constant` 半句；报错里未决定的字段显示为 `t.xpos`、`(mk y).xpos`；警告多读法时的
  末句与链上的读法；候选行的排列顺序（建议按全名排序；决定截到 5 条时显示哪几条）与省略号的确切写法；D14 学不到时与第 0 级后才暴露的错误的文案
  （引用所写的标识符与对象）；登记冲突的文案；attribute 参数写错时的文案（r8 草稿与真实渲染见 §6.11 末"r8"一条，`step1/r8/attr_render/out/`）；
  带 `field_dot` 的解析失败时附的说明（§1 第 27 条，`syntax_phases.ML` 的 `field_dots_hint`）；文法里的 `_dot_field` 与 `field_dot`、只用于输出的
  `_dot_access`、`_dot_ident`。（删除登记的写法已定为 `[[dot_field del …]]`，attribute 名 `dot_field` 已定。）
- **警告**：只有"读成常量、也能读成字段访问"一个方向（§1 第 8、16 条）。对象必须是常量（最长的、本身是常量的真前缀，通常是第一段）；用该常量的
  类型按选择规则逐段查登记，确实有该字段才发（某段多候选时沿每个候选走；标识符上写了类型或带参数时也要对得上）。实现沿用第三轮
  `reviews/round3/warn/DESIGN.md` §4（读法计算）、§5（发给用户的通道）与 `RESULTS.md` §6 的去重（每个不同的位置只算一次、每种文本只发一条），
  但对象规则以本条为准（该文件 §3 的对象规则不再适用）。在解析选定语法树之后、类型检查之前发出；要求两个开关都开、上下文可见。"选了字段访问、遮住常量"不发警告：颜色已表明读法。
- **前端标记**：对象那一段得到单独写该名字时的标记（绑定变量绿色并链接到 binder；固定、自由变量蓝色；常量可悬停与跳转），实测见
  `reviews/round4/localfirst/render/`。字段选定后，在字段那一段（链中每一段、`(e).f` 的 `f`）报告所选登记 term 在当前 context 里折回缩写后
  的头部常量的标记（§1 第 1 条 2026-11-02 再修订：`Proof_Context.contract_abbrevs`，经 eta 收缩取 `head_of`，是 `Const` 才报），与直接写该常量名时相同：
  `length` 字段悬停与 ctrl-click 都是 `length`；locale 里的 `bar` 在 locale 里是 `bar`，interpretation 之后是 `a.bar`；record 字段即 `record` 那一行。凡原版会报告标记的地方都报告，包括批量构建（"只在 IDE
  里"做不到也不需要）；字段那一段不提供类型提示（它没有位置约束）。报告点只有一处：各引擎把确认了的选择（载荷 serial ↦ 所选登记的 term；报告时才在当前 context 里折回缩写）记进检查链传递的
  上下文（coercion 引擎的出口函数、标准引擎的返回、第 1 级的标记检查），`check` 把这个上下文交回（今天它丢掉，`syntax_phases.ML:1021`），
  `check_terms` 在原版的类型报告旁边统一报告；被丢弃的路径与被拒的 term 不会报告（第五轮评审 3.9；按授权定，§1 第 24 条）。
- **打印**（§1 第 16 条定稿）：不打印成 dot 语法。开关打开时，凡是常量准备打印的名字，第一段与该处的变量（绑定、自由）或上下文的固定变量冲突，
  一律打印成 `CONST 名字`（`λb. b ∈ CONST b.E`、`CONST C.arr + xpos C`）；不冲突照原样。（2026-11-09 修订，§1 第 25 条 (2)：只对带点的名字做；
  不带点的名字与变量同名时照原版打印。）只在一处做：`pretty_entity_cache` 选定打印名时判断，冲突集合
  用 `exclude_consts` 已收集的名字与 `Dot_Field.is_fixed`。原版"自由变量与常量重名时打印更长名字"的规则照旧。开关关闭时打印同原版，所以
  fast_abbrev_printing 的 golden（在 dot_syntax 的发布批次里也跑）不受影响，实现时验证。开销在第一步测。

### 6.7 兼容性（开关打开的 theory 里）

| 情形 | 开关打开时 |
|---|---|
| 第一段是局部变量、整个标识符或前缀是常量（多为 locale 参数与 interpretation 前缀同名的 `C.arr`） | 读成字段访问；AFP 约 9,100–10,500 处（可能偏高 15–20%），大多变成报错（报错提示 `CONST`），至多约 643 处可能静默改变 |
| lemma 陈述与所有定义方程（`definition`、`abbreviation`、`fun`、`function`、`primrec`、`primcorec`、`partial_function`、`inductive`、`fixrec`、`nominal_primrec`、locale 假设）里未声明的变量 | 读入时还没固定（specification.ML:138-170），不是局部变量：`b.E` 读常量；变量与 record 同名时 `state.pc` 读成选择函数常量（`definition get where "get state = state.pc"` 静默接受成 `get :: 'b ⇒ 'a state_scheme ⇒ nat`，`fun` 里报原版的类型错）；证明里 `fix` 之后读字段访问。不加警告（用户 2026-11-02：颜色已说明读法）。写进文档：方程后加 `for x`（parse_spec.ML:64-67；`primcorec` 没有）、陈述用 `fixes`、或换一个不是常量前缀的变量名（`s.pc` 按 6.3.1 第 6 行读成字段访问）、或写显式形式 |
| case 模式、带点的模式变量、去掉位置的翻译内部（标识符形式） | 同今天 |
| 去掉位置的翻译内部的括号形式（如 `((p).xpos + 1)\<^sub>e`） | 字段访问（括号形式今天没有含义；6.3.2） |
| `(e).f` | 只在第一次解析失败后才试，今天能解析的文本不变 |
| 字段登记在 locale 里 | 另一个 locale 的头部、interpretation 的 `rewrites`、`defines` 里看不到（已接受，6.4）；light-locale 块与无名块里的登记作用于整个 theory（已确认，6.4） |
| D14 | 对象类型只能靠 adhoc_overloading 定出的 dot 写法被接受，与原版对显式写法相同（6.5.3）；字段结果上写了类型时可经另一个重载常量定出对象类型（R2 残留） |
| 带 coercion_args 声明的常量登记成字段、字段要等待 | 可能误拒（已接受，AFP 里 0 处，6.5.1） |
| 有歧义的文法：同一输入既能把长标识符当名字（如被翻译变成字符串），也能放在 term 位置（第三轮称 K7） | 今天 term 那棵树因 `Undefined constant` 被排除；开关打开后它能 decode（误拼限定名在解析时交给原版以后，只在第二段是某个登记的字段名时才会，6.3.1 第 6 行），于是两棵树都做类型检查（§2）：字段读法通不过检查时结果同今天；通过时报 "Ambiguous input"。HOL 与 AFP 里 0 处（`reviews/round3/k7scan/`）。按代码推断，实现第一步加探针 |
| Isabelle 打印出的文本 | 常量名第一段与该处变量或固定变量冲突时打印 `CONST 名字`（6.6），以便读回 |
| 其余文本 | 同今天（HOL 10,025 条 0 差异） |

开关关闭：一切同原版。

### 6.8 性能（均已批）

- 开关关闭：在两份相同副本的差异之内。开关关闭时仍会跑的东西（第七轮深度复审问题 15 补全）：字段登记照常记录（6.4）；每次 `parse_term` 读一次开关；
  `ast_to_term` 的长标识符测试与 `decode_term` 里 `decode_ident` 的那一句；`Term_Position` 几个读位置函数里多的那一句；警告通道多传的 decode 参数；
  打印器读一次开关；各引擎入口与第 1 级的 dot 检查各一次 `Config.get`（40 ns）；`term_check'` 的包装；`prepare_positions` 的 `Var` 分支对每个 schematic
  变量多一次名字前缀测试；`check` 交回上下文；构建文法时把 `field_dot` 产生式挡在 lookahead 表外（6.3.2）。这份清单只作说明；规则 (2) 用按构造包含全部
  这些路径的端到端行来判：第一次解析；第四轮语料上的 tokenize、parse、decode；`check_terms`；unparse；`make_gram`。第一步用同进程的原版副本对功能副本测；
  第二步跨 heap 只记录（§1 第 24 条 2026-11-02 修订）。
- 开关打开、不用 dot 语法：在噪声内；带限定名常量（`List.map` 一类）每个 +0.5–1.1 µs（只由这种名字组成的文本 +0.6–1.3%），实现时尽力去掉
  （思路：Pure 里能带位置、不抛异常的常量查找，省去重复查找）。
- 用 dot 语法：§1 第 15 条的数字（常见写法约 0.95–1.2 倍；救回的 term 约 3 倍；报错最多约 1.7 倍；原版指数级嵌套且只有新做法能接受的
  term 最多约 20 倍）；拆分的标识符比普通标识符多 0.4 µs。
- D14（§1 第 18 条已接受，按设计开销即 `compare/COMPARE.md` 的 NEW-observer 列）：一个或许多互不相关的 D14 对象 1.7–2.4 倍；依赖链深度 3/5 约 3.6–3.8 /
  5.4–5.5 倍（coercion 开）、2.7–2.9 / 3.8–3.9 倍（关）；相互依赖的 do 块 3 个绑定 4.2–4.3 / 3.9–4.0 倍；报错中对象被量词绑定或参与 `=`/`∈` 时 1.33–1.64 倍，
  `∀` 下 10 处访问 1.64 / 2.2 倍；只有第 0 级之后才暴露的第 3 步错误约 2.4–3.0 倍；`(λt. t.xpos) (mk y)` 的报错 1.57–1.59（开）/ 1.77–1.83 倍（关，
  略超原批的约 1.7 倍；用户 2026-11-02 接受，§6.11 (c)）。与旧机制（第三轮）同条件对比：常见写法持平，coercion 关时自由对象
  的报错便宜得多，链与相互依赖的 do 块慢 11–32%。
- 门槛：§1 第 24 条的规则（规则 (1) 已改为单侧）。规则 (2) 不用于本节已批例外的行：带限定名常量的行按已批数字判（每个不超过 +1.1 µs），不按两份
  相同副本的波动（约 0.2%）判，也不按规则 (1) 的 5% 判（第七轮深度复审问题 9）。
- （用户 2026-11-05 批准的例外）开关关闭时建文法（`Parser.make_gram`）比原版多 2–4%，每次建 HOL 文法约 0.3–0.6 ms：`extend_gram` 另扫一遍新产生式、
  把带字段点的分出来（6.3.2）。（2026-11-10 去掉解析器 functor 之后测得 0.985–0.988 倍，即不再比原版慢；只报告，例外留着无妨。）
- （用户 2026-11-09 接受，§1 第 25 条 (4)(5)）字段那一段的前端标记每段约 39–53 µs（登记为 λ-term 时）；真要打印 `CONST` 的 term 每个约 +0.6–0.7 µs；
  开关打开时无点文本每 term 约 +0.1–0.4%；G6 第二轮仍不通过的各行（§6.11 末）。
- （用户 2026-11-14，§1 第 28 条）任何一行超出门槛不到 10% 一律接受；按 µs 写门槛的行按换算成整段输入的倍数判。第三轮 G6（最终代码 r10）的各行与不通过的行
  见 §6.11 末"第三轮 G6"，都在此条之内（Reg.R1 第二轮起已接受）。
- 第一步已测（原先列为"未测"的各项）：开关关闭时的解析，去掉 functor 后 1.002–1.003 倍（6.3.2）；coercion 引擎 functor 无钩子实例在波动范围内
  （§6.11 末"第一步子步骤 3"）；`(e).f` 改为一次解析后的数字见 6.3.2（旧的第二次解析慢到 10–16 倍，是改一次解析的原因）；开关打开时的打印与字段那一段的
  前端标记见上一条。

### 6.9 文档要写的内容（按授权自定）

开关与继承规则（无 bundle）与作用范围的五点（6.2：`context notes` 限定范围、`lemma notes` 只作用于证明、theory 层 `declare` 传到导入者、库 theory 用限定块、
locale 与块里不用 `declare`）；`[[dot_field]]` 的作用范围同此（6.4）；变量只有在读到它的那一刻已绑定或已固定才算局部变量——lemma 陈述与定义方程里的
变量不是（列出 6.7 表中的命令），补救是方程的 `for x`、陈述的 `fixes`、换变量名或显式写法；不拆的地方（case 模式、去掉位置的翻译，
列出 AutoCorres2、Shallow_Expressions、HOL-Hoare、Statespace、Simpl）；给工具作者：把解析输出直接交给 `infer_types` 会收到载体，要走 `Syntax.check_terms`
（6.3.3）；给翻译作者的规则（经自由变量绑定，或先去掉位置）；翻译中途 decode
子项时第一段一律当非局部（Simpl）；打印时的 `CONST`；ML 在解析与检查之间把开关关掉的后果（6.2：`Unbound schematic variable` 或 `Bad name binding`，schematic 与 pattern 模式下载体留在 term 里）；与 Lean 的差异（不打印回 dot
语法、没有命名空间规则、不自动登记 datatype 选择器）；R2 的残留（§1 第 18 条：字段结果上写的类型可经另一个重载常量定出对象类型）；登记只能是
常量，`[[dot_field 字段 = 常量]]` 与简写 `[[dot_field c]]`；字段那一段的悬停与 ctrl-click 跟着打印器走（折回缩写后的常量；之后定义的另一个能折回同一
term 的缩写会胜出；`abbreviation (input)` 与 `show_abbrevs = false` 时显示展开后的常量，§1 第 1 条）；locale 里的登记在另一个 locale 的头部、`rewrites`、
`defines` 里看不到；括号形式在去掉位置的翻译内部也是字段访问；带 coercion_args 声明的常量登记成字段时可能误拒（字段等待时，以及 local pass 在别处
失败、转去约束生成时，§1 第 21 条 11-04 的注）；字段只在不看它时求解出的类型上决定（D15），所以借 coercion 改过的类型选中的字段会被拒，例如
`(λt::_ list. t.ih) ns`（`ns :: nat list`、`ih` 只登记在 `int list` 上）。

### 6.10 改动的文件

（都在 Isabelle2026 的私有树 `contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax` 上改。）
- **Pure**：`pure_thy.ML`（载体常量）、`ROOT.ML`（加载 `dot_field.ML`，在 `Isar/proof_context.ML` 之后、`type_infer_context.ML` 之前，故不能用
  antiquotation，只能用 `\<^here>` 与 `@{make_string}`；再加载 attribute 的小文件，在 `Isar/attrib.ML` 之后）、`Syntax/dot_field.ML`（新：开关、登记、
  选择规则、文案、最后检查、第 1 级检查、D14 学习运行与守卫、两个引擎共用的等待索引与 `selection_check`）、`Syntax/syntax_phases.ML`（`ast_to_term` 两处、
  `decode_ident`、警告通道、开关打开时标 `field_dot` 并解析一次与失败时的说明、第 1 级检查、`check` 交回上下文与 `check_terms` 出口的字段标记报告、
  `pretty_entity_cache` 的 `CONST` 打印）、`Syntax/term_position.ML`（三个读位置的函数）、`Syntax/lexicon.ML` 与 `Syntax/parser.ML`（`(e).f` 的点标记；
  `Parser.parse` 多一个参数 `{field_dots}`，左递归的 `field_dot` 产生式单独存放、只在后面还有 `field_dot` 时预测）与 Pure 文法、`Syntax/syntax.ML`（一行，
  `Syntax.parse` 的类型）、`type_infer_context.ML`（标准引擎；`prepare_positions` 的 `Var` 分支经 `Dot_Field.rebuild_payload` 重建载荷）、`Isar/attrib.ML`（登记两个开关）、
  `Isar/proof_context.ML`（签名一行）、`dot_field` attribute 的小 ML 文件。**不改** `Tools/adhoc_overloading.ML`、`Isar/overloading.ML`、任何 `.thy`。
  第 0 级的 `"standard"` 检查（`syntax_phases.ML:1041-1043`）改为用 `term_check'` 注册（才能把记下的选择经上下文交回，6.6）：开关关闭或没有载体时，
  它就是原版 `simple_check (op aconv)` 作用于原版函数；为此在 `Syntax_Phases` 的签名里导出 `simple_check`（一行），不复制它（第七轮深度复审问题 16）。
- **HOL**：`src/Tools/subtyping.ML`（coercion 引擎：原版代码写成带钩子的 functor 加 ESR 部分；coercion 检查 `subtyping.ML:889` 同样改为 `term_check'`、
  开关关闭时是原版 `simple_check (op aconv)` 作用于原版函数）、`src/HOL/Tools/record.ML`（登记钩子一处；localized_record 进 base 后改在
  `local_add_record` 末尾，6.4）。
- **2026 的补丁链**（第七轮深度复审问题 6）：pristine → bicompose_rename_fix → fast_abbrev_printing → light_locale → …（local_type_abbrev、localized_record、
  local_datatype）→ dot_syntax。light_locale 改了 `syntax_phases.ML`（打印的 implicit structure 部分）、`syntax_trans.ML`、`proof_context.ML`、`attrib.ML`、
  `generic_target.ML`、`ROOT.ML` 等，fast_abbrev_printing 改打印；与本补丁同名的文件在 base 合并时逐个核对。现在从 localized_record 到 dot_syntax 的
  2026 分支都还在 7d475f7（原版），第一步不受影响。
  **2026-11-03 查看（`git fetch` 后的 GitHub 分支与 tag、本机各私有树）：** 已发布 `Isabelle2026/bicompose_rename_fix/1`、`Isabelle2026/fast_abbrev_printing/1`；
  light_locale 在做（私有树比 GitHub 多 11 个提交，已合并 fast_abbrev_printing/1，未 push、未发布，setclass 那批在进行）；local_type_abbrev、localized_record、
  local_datatype 在 2026 上没有实现（分支在 7d475f7；2025-2 上也只有 light_locale 的提交，各自只有 10-17 至 10-19 的计划）；dot_syntax 与其 base 都在
  7d475f7。所以第一步（用户空间、官方 Isabelle2026）不受影响；第二步技术上可在 pristine 上开始，但下面四个 feature 进来时要再合并（上列同名文件，及
  6.4 的 record 钩子）；发布（第四步）要等它们都在 2026 上发布、local_datatype 有发布 tag。第二步何时开始，到时问用户。
- `check_terms` 的改动只有两处，在一个地方设计：入口重建载荷（经 `prepare_positions`）；出口报告字段标记（经 `check` 交回的上下文）。D14 不改它。
- **组件 theory**：无（2026-11-01：不提供 bundle，登记用 attribute）。`dot_field` attribute 的定义在 Pure 的 ML 里，加载在 `Isar/attrib.ML` 之后。

### 6.11 待短评审的内容、待用户回答的事、第七轮深度复审的结果

（2026-11-02 改写：第五轮评审已把原先列在这里的各项审过，结论都写进了本章；下面是改写后要送短评审的内容，见本节末尾的待办第 4 项。2026-11-03 注：
第七轮深度复审通读了整个设计、第八轮短评审审了其后的改动，下列各项都已覆盖；其中"`Var` 是否被 AFP 的 parse translation 看到"的扫描是第一步开头要做的事，
"带限定名常量开销的去除"在第一步实现时做。）
- 我按授权自定、写进本章的：两个引擎的"原版代码 + 钩子"不变式（6.5）；载荷在检查入口重建（6.3.3）；去掉 I1b 捷径、I1a 只剩 `coercion_args` 一个运行时条件（6.5.1）；
  单一出口函数与单一拒绝判断（6.5.1）；D14 机制及两处修补（6.5.3）；`decode_ident` 第 4、6 行（6.3.1）；字段标记的报告点（6.6）；
  `check_terms` 的两处改动（6.10）；第一步的验收门槛与测试方法（6.12）。
- 第四轮解析与第三轮载荷的衔接：字段位置从 `_dot_ident` 里的 token 位置推出；`decode_ident` 与 `Dot_Field.accesses` 的接口。
- 记下完整名字的 `Var` 是否会被 AFP 里检查 schematic 变量的 parse translation 看到（扫描）。
- 带限定名常量开销的去除方案（不抛异常的 `decode_free`）。
- 第一次评审 §5 的 8 项"先定再复审"（插入所选登记、警告通道、record 自动登记、登记同一性、实施步骤、载体不外泄、载体编码、文档修正）是否都已在本章落实。

（第五轮聚焦评审、第六轮 D14、新旧计时对比与用户逐项答复的过程记录，2026-11-02 整理时已原样挪到 §3.3b 末尾。）

**2026-11-02 第五轮评审与第六轮列出的待用户决定事项都已答复（§1 第 14–24 条；通读后又发现的几件见本节末尾）。接下来（按顺序）：**
1. **亲手改写 §6**（2026-11-02 已完成，随后通读全文核对），把以下都写进正文：§1 第 1、20 条（只登记常量、attribute `[[dot_field 字段 = 常量]]` 与简写 `[[dot_field c]]`、
   无命令、无组件 theory、locale 头部等处的缺口）；第 14 条（无 bundle）；第 16 条（打印冲突时打印 `CONST 名字`；登记表不看开关、显式登记总是检查）；
   第 17 条（目标 Isabelle2026，树与规则见 §3.4）；第 18 条（D14 用第六轮机制加两处修补，取代 §6.5.2 的重跑与 §6.5.3 的 d14on，不需 `is_overloaded` 导出；
   已接受的开销与 R2 残留）；第 19 条（列表最多 5 条加省略号）；第 21 条（去掉 coercion_args 三处修补）；第 22 条（保留 I1a；后经第七轮问题 2 改为只剩 `coercion_args` 一个运行时条件，去留由第一步实测定）；第 23 条
   （保留 `(e).f`，先测第一次解析）；第 24 条（计时规则、授权）。以及第五轮评审中我自定的各项：3.1（引擎写成"原版代码 + 钩子"的 functor 三实例，
   原版函数不改；去掉 `prepare_term` 标志）、3.2（载荷在 `check_terms` 入口、`prepare_positions` 的 `Var` 分支里重建为 Free，去掉第 0 级重建）、3.4
   （去掉 I1b 捷径，I1b/I1c 合成一次原版 `coercion_infer_types`）、3.6 的 1–2（单一出口函数、单一拒绝判断；标记类型按出口的对象类型读法）、3.8（新验收
   门槛 G1–G7）、3.10（误拼限定名在 `decode_ident` 第 6 行判）、3.13（第一步的测试方法）、3.14（AFP 那一步改法）、3.15（`ast_to_term` 两处、括号形式在去位置的
   翻译里会拆）、3.16（第 4 行补 `lookup_free`）、3.12 的两句（stock 副本来源、`syntax.ML` 进改动清单；树改为 2026）。来源：`reviews/round5/focused/JUDGE.md`、
   `reviews/round6/d14/JUDGE.md` §1 与 `VERIFY.md` §3、`reviews/round6/d14/compare/COMPARE.md`。
2. 把 `check_terms` 的改动集中设计在一处（入口重建载荷；出口报告字段那一段的标记；D14 新机制不改 `check_terms`）。——已写进 6.3.3、6.6、6.10。
3. 写第一步的验收门槛（替换 TEST_PLAN §5.6，列出 TEST_PLAN 作废的部分）。——门槛已写进 6.12；TEST_PLAN 作废部分的清单在第一步开头写。
4. 送一次短的聚焦评审（全新 agent），只审我自定的各项与 `check_terms` 设计。（2026-11-02：用户要求先做了第七轮深度复审，见本节末尾；短评审改到
   深度复审的待办改完之后，范围加上那些改动。）
5. 第一步在 Isabelle2026 上从头实现（技能 `isabelle-patch-feature` §3.9 第 4 步；先读该技能）；最先测开关关闭时的第一次解析与 coercion 引擎无钩子实例的开销；
   fast_abbrev_printing 的 golden 已挪到第二步（它要构建好的 session，6.12）。commit 与 push 都要用户下令；`b8f3070` 未 push。
   短评审的范围还包括第五轮评审 3.14（AFP 那一步）与 3.15（`ast_to_term` 两处、括号形式的不对称）。第一步的子步骤顺序以本节末尾深度复审的"接下来"为准。

**仍待用户回答（2026-11-02 通读后列出）：**
- (a) 字段那一段的前端标记：你批准的原话含"只在 IDE 里发"，做不到；我按授权改为"凡原版报告标记处都报告（含批量构建），字段那一段不提供类型提示"
  （6.6）。**用户 2026-11-02 确认。**
- (b) D14 在 class specification 里守卫可能挡掉一次本可选出字段的学习运行，造成误拒（验证 §2.5，0 例）。**用户 2026-11-02："按你建议来"——接受**
  （我的建议是接受；替代做法要恢复 `is_overloaded` 导出并加钩子）。
- (c) `(λt. t.xpos) (mk y)` 的报错在 coercion 关闭时 1.77–1.83 倍，略超原批的约 1.7 倍（6.8）。**用户 2026-11-02：接受。**
- (d) 第三步 AFP 用哪一份（本机有 `contrib/afp-2026-10-26`），第三步之前问。
- (e) 构建与流程问题（TEST_PLAN §9–§10，其中计时门槛与 `dot_warning_rule` 已不需要问；G7 并进来的几项见 §6.11 末"G7"），第二步之前问。
- (f) 更早遗留：首次提交的文件清单、README / LICENSE / GitHub 描述、`my_better_isabelle_prover` README 的链顺序；磁盘清理（`reviews/` 已超 5 GB）；
  顺带发现的两处原版问题（§3.3b）。

**第七轮深度复审（用户 2026-11-02 要求"建议深度复审"，因为用户对自己定下的事也可能不确定）：** Workflow `wmd3lwwem`，目录 `reviews/round7/deep/`，
报告 `JUDGE.md`（1,085 行，2026-11-02 约 05:30 UTC 完成）。两轮对抗辩论，全部 Opus xhigh、全程英文；五个角度：decisions（§1 用户自己的决定）、engine、
surface（解析、登记、报错、标记、打印）、integration（改动文件、补丁链、2025-2 与 2026 的差异）、readiness（第一步的门槛与文档自洽）；每条质疑一个
全新辩护 agent；judge 删去低质量意见，另列"建议用户重新考虑的决定"。
**结论：有条件可开工（ready_with_conditions）。** 架构不变，R1–R3 都能满足，没有要重做的部分。24 条质疑里 9 条并入别条，留下 16 个问题：6 个须与用户
讨论（问题 1、2、4、5、9、13；问题 8 另带一个用户问题），10 个由我定、改完送短评审。下面"文中有误或不全之处"所列的句子在处理之前以本条目为准。
*开工条件（JUDGE §1.1）：*
- 写第一步代码之前：我手工改完下面"我的待办"（文本、门槛、测试方法），短评审复核；——已满足（11-02 改完，第八轮短评审复核，其 8 条也已处理）；
- 第一步的第一个子步骤是把参考原型移到 Isabelle2026（问题 6），在任何计时之前；——已写进 6.12 子步骤 1；
- 写登记表之前：用户定 2.1；测第一行按规则 (1) 判的计时之前：用户定 2.2（第一次解析是规则 (2) 的行，不必等）；——都已满足（11-02）；
- 可在第一步中再定（第一步产出所需的数字）：2.3、2.4 的警告、2.6。——2.3 已定（第一步数出失去的接受数报用户，知情）；2.4 已定（不加警告）；2.6 已定为
  第 22 条的规则（第一步提供计时）。
*须与用户讨论（JUDGE §2；按此顺序一个一个讲，答复后在这里记状态）：*
- **2.1 第 1 条与第 20 条矛盾（问题 1）。** locale 里用 `definition` 定义的常量在 locale 里只是一个局部缩写 `local.bar`，代表全局 term `foo.bar n`；
  interpretation `a: foo 3` 另造常量 `a.bar`（代表 `foo.bar 3`），locale morphism 只变换 term、不改存下的名字。所以"存常量名"与"随 morphism 走、
  interpretation 之后可见"对 locale 自己的常量不能同时成立：照字面实现，interpretation 之后表里是一个不存在的名字（`Undeclared constant: "local.bar"`，
  `review-decisions/P_LocalConst.out`、`defend-integration-2/P_Defend2.out`），在有自己 `bar` 的 locale 里做 sublocale 时静默选到别的函数
  （`review-surface/probe3.out`）。judge 推荐：theory 级常量照第 1 条存名字、不展开；只存在于 locale 或块里的常量存它代表的 term（`foo.bar n`），
  interpretation 后变成 `foo.bar 3`，与写 `a.bar xs` 结果相同（第三轮登记设计实测过的做法 P01–P12）；代价：这类字段的悬停显示全局常量 `foo.bar`，
  不是 `a.bar`（ctrl-click 仍跳到 locale 里的 `definition`）；两个同类型的 interpretation 使 theory 级的 `xs.bar` 歧义（任何存法都有）。其他选项：
  存 term 后再按缩写反查表映射回常量名（未做原型）；照 Pure 对 notation 的规则只保留 morphism 不改变的副本（失去第 20 条的承诺，且用户登记 `a.bar`
  后 locale 里 `xs.bar` 变成歧义，不推荐）；只许登记 theory 级常量（放宽 2）。**写登记表之前要定。**
  状态：**用户 2026-11-02 定：采用原版标准读法**——用户指出"按常量的来源分开存"其实就是原版 `declare` 在 locale 下的标准反应；对一切常量都按原版带
  term 参数的声明 attribute 的方式读（缩写一律展开），随 morphism 变换，不分来源；放弃第 1 条"不展开"，代价只是 theory 层缩写的悬停显示展开后的常量。
  已写进 §1 第 1 条与 6.4、6.6。（第八轮短评审更正：ctrl-click 也落在展开后的常量上；带参数的缩写没有头部常量。已告知用户；用户不接受前者，前端标记改为
  取折回缩写后的头部常量，存法不变，见第 1 条再修订；按这个定义，带参数的缩写也有头部常量，实测 `sym_diff` 折回成 `Set.sym_diff`。）原版另有一种标准反应：语法声明（`notation` proof_context.ML:1280-1285、`adhoc_overloading` adhoc_overloading.ML:243-249）
  只保留 morphism 没改变的副本，不跟 interpretation 走。
  讲解中用户问 light locale / setclass 上会不会有问题。我读 light 树源码（`Isabelle2026-light_locale` 的 `5ef3a5e`，未实测）得到：(i) light locale 只保存
  语法声明（`named_target.ML:95-100`）；块里的 `declare [[…]]` 走 `light_notes`（`generic_target.ML:446-479`），在块里生效一次、原样作用到 theory，不存进
  locale（light 的规矩，REV37:3284-3299）。所以块内定义的常量登记成字段后只在定义它的块里能用（theory 层那份因块参数不固定被丢掉）；重新打开的块、
  `lemma (in LF)`、interpret 之后都不能用（`bar xs` 照样能写，常量缩写是语法声明、会重放）；存名字时还会在别的块里静默指错。theory 级常量（record 字段，
  如 HOL-Algebra 的 `carrier`、`mult`）不受影响。(ii) light locale 导入普通 locale 时只激活语法声明（`locale.ML:490`），普通 locale 里用 `declare` 做的登记
  进不了 light locale。(iii) setclass（`ai-artifacts/LIGHT_LOCALE_SETCLASS_BY_CONTENT_PLAN.md`，MLML 主仓库）只改证明方法认 setclass 前提与谓词登记表，
  与 term 的读法无冲突；改动文件有交集（`ROOT.ML`、`attrib.ML`、`generic_target.ML`；light 对 `syntax_phases.ML` 的改动在打印的 implicit structure 部分），
  属 base 合并的文本问题（问题 6）。但用户设想把 light locale 升级为集合论下的 type class，那时运算多定义在 light locale 里，按现在的第 20 条，`x.inv`
  只在定义它的块里能用。根治：把登记做成语法声明（`Local_Theory.declaration {syntax = true}`，同 `notation`、`adhoc_overloading`），即回到命令，推翻
  第 20 条"不引入新命令"（语法声明的处理函数照样可以随 morphism 变换 term，不必照搬 notation 的"只保留不变的副本"）；新关键字放哪里未查；
  我没找到让 attribute 存成语法声明的现成办法。**用户 2026-11-02 答："light locale/setclass 先不管。之后我们会有一个宏大的语法相关的设计"。**
  所以第 20 条维持 attribute；上面 (i)–(iii) 的限制与"改成语法声明"的思路只记在这里，留给那个设计，第一版不处理。
- **2.2 第 24 条规则 (1) 改为单侧（问题 9）。** "相差 ≤ 5%"是双侧的，按设计变快的行（第二步 coercion 关闭的行少一次模拟的原版推断）也会不通过。
  推荐：两次都比参考慢 5% 以上才不通过，变快的记下原因。另一个小问题（问题 8）：第二步在两个 heap 之间计时噪声约 0.98–1.17，推荐 R3 只在第一步用
  同进程的原版副本对功能副本把关，第二步跨 heap 的计时只记录（放宽 5）；或现在定一个跨 heap 门槛。
  状态：**用户 2026-11-02："全部按你建议来"**——规则 (1) 改为单侧（两次都不比参考慢 5% 以上才通过，变快的记原因），第二步跨 heap 只记录；已写进 §1
  第 24 条。用户同时指出"我从来没有起草过计时规则"：这四条是我起草、用户批准的，我讲解时说成"你原来的规则"是错的。
- **2.3 D15 对有结构的对象类型不成立（问题 4）。** `ns :: nat list`、`ih` 只登记在 `hd :: int list ⇒ int` 上时，`(λt. t.ih) ns` 被接受为
  `hd (map int ns)`，而用户自己的例子 `(λt. t.sqrt) n` 被拒（`reviews/round3/d15/out/d/d15.D15_Probe.on.out:1490-1495`、`:1568-1573`）；链
  `(λt. (t.sw.pa, t.sw.pb)) (undefined :: _ × _)` 被接受而换序的被拒（`:1879`、`:1893`）。原因：`learn` 在求解前看到 `?c list` 与界 `nat <: ?c`，按规则第 4 步
  选唯一候选并定 `?c := int`（s3c:2751-2786），求解后 `chosen` 还先试求解前的 `tye0`（s3c:2908）。我曾判"与已批规则一致"（`reviews/round3/DECISIONS.md:100-105`），
  用户没读过。推荐：在 global algorithm 里，对象类型（经 `tye0` 读）含有仍被子类型约束限住的类型参数（`dot_propagate` 已算的 `tied` 集合）的字段等到求解后
  再定，求解后只读已解的 typing；record 字段不受影响；第一步测试 L1、L6、L7、L9、U17、U18、复合对象、带标注的 binder、恢复 `tye0` 分支的变异，数出
  失去的接受。另一选：写成 R2 的例外。无论哪种，§6.5.1 的 D15 一句都要改。
  状态：**用户 2026-11-02 赞同让 D15 名副其实**（用户先问"是否会让代码实现更简单"；我答：代码量大致持平——加一个检查、删一个分支，检查用的 `tied` 集合
  已有；规则与论证更简单，只剩一种读法；`dot_object_own_type` 可能多余、local pass 可能也要改，都待第一步实测）。已写进 6.5.1。（第八轮短评审更正：
  求解后读 `tye0` 的地方有两处，不是一处——`chosen` 与 `d`/`field_error`；两处都改，6.5.1 已写明。）
- **2.4 方程与陈述里与 record 同名的变量（问题 5）。** 所有规格方程（`definition`、`abbreviation`、`fun`、`function`、`primrec`、`primcorec`、
  `partial_function`、`inductive` 等）与 lemma 陈述里的变量在读入时还没固定（specification.ML:154-170 `prep_specs`、:138-152 `prep_spec_open`），所以
  `record state = pc :: nat` 之后 `definition get where "get state = state.pc"` 把 `state.pc` 读成选择函数常量，静默接受为
  `get :: 'b ⇒ 'a state_scheme ⇒ nat`（`defend-decisions-4/probe/D4_Spec.out:13-14`）；`fun` 里报原版的 `No type arity fun :: plus`
  （`review-surface/probe4.out:18-23`）；第 8 条的警告不发（对象不是常量）。AFP 有 679 处这种命名，约 430 处正在这些位置。用户当时没被告知方程也如此、
  方程里没有 `fixes`（补救是 `for x`）。推荐：文档改正（我无论如何做）+ 再加一条警告子句：标识符读成一个本身登记为同名字段的常量（`state.pc` 是登记的
  选择函数 `pc`），且第一段在同一 term 里作为未声明变量出现；文案用已批的那条，可加"写 `for state`"的提示；不改变任何读法；`assumes`/`shows` 分开的
  陈述是几个 term，盖不到。可选：用它取代常量对象的警告（放宽 3）。与 2.5 一起讲。
  状态：**用户 2026-11-02："我认为不需要加警告，因为颜色已经说明了一切"——不加警告**；文档照"我的待办"问题 5 改正。颜色的依据（第四轮 `render/W_Markup.log`）：
  jEdit 里隐式自由变量蓝色、常量是默认色，所以 `get state = state.pc` 左边的 `state` 蓝、右边整个 `state.pc` 默认色，悬停显示选择函数常量；读成字段访问时
  右边的 `state` 才是蓝色。限制（已告诉用户）：颜色只在 IDE 里；批量构建与经 REPL、Isabelle-MCP 的 agent 看不到颜色。用户另要我查 TAT 的 `Define`
  是否加 `for`：**不加**——`contrib/Theory-Agent-over-Trees/Isabelle_Std/ML/TAT_Define.ML` 里 `definition_transition` 调
  `Specification.definition_cmd (SOME fixes) [] [] …`、`function_transition` 给每条方程 `((Binding.empty_atts, eq), [], [])`，两处的 `for` 参数都是空表；
  方程里的变量照原版在读完后才收成参数。所以 TAT agent 在 `Define` 里写 `state.pc`（变量与 record 同名）时同样读成选择函数常量，`definition` 静默接受成
  怪类型、`function` 报原版的类型错。TAT 目前用 Isabelle2025-2（其 README），dot 语法目标 2026，暂不相交；TAT 若想避开，可先读一遍方程收集自由变量再作为
  `for` 传入（TAT 的事，没动）。
- **2.5 第 9 条记录的理由（问题 13）。** 第 9 条记的"用户的主要考虑是性能"不是用户的理由（后经查对话记录：这句是用户 05:57 原话的一句，只是转述不全，
  第 9 条的注已改成这样说）；用户 10-31 说的是语义：单写的 `seg.start` 也应局部变量优先，
  单独标识符与链要统一（05:51、05:57 UTC）；记录还漏了我 04:59 推荐"常量优先、只对非常量局部变量优先"的混合规则与用户的否决。后果：用户的例子
  `λseg. seg.start.xpos` 只在 `seg` 已绑定或已固定处有效，在 2.4 的位置仍读成 `xpos seg.start`。推荐保持局部变量优先，改正记录。
  状态：**用户 2026-11-02："局部变量优先继续维持。性能要考虑，但更要考虑的是功能"**；记录已在第 9 条补全（05:51 的功能理由、对混合规则的否决、05:57 原话）。
- **2.6 第 22 条 I1a（问题 2）。** 条件"过程中没有任何字段等待过"按构造对每个成功的 local pass 都成立（字段进等待表与 stamp 加一同时发生；只有帧重跑
  删条目，而重跑把表与计数一起还原，s3c:2049-2058、1363-1371；`Local_Done` 只在表空时出现，s3c:2602-2604），所以不过滤任何东西；真正起作用的是
  coercion_args 条件，加上"无等待的遍历与原版代码形状相同"与"帧从自己保存的状态重跑"两个论证。没告诉用户的代价：ESR 自己的 local pass 必须永远与
  原版 coercion 推断保持相同，交付代码里没有东西检查它。推荐：第一步用 `S3B_RECHECK_DONE` 测"总是原版对 E(C) 的推断"对 I1a（节点决定与晚决定的行
  分开报），在已批 0.95–1.2 之内就去掉 I1a（放宽 1）；否则保留，并加 R1 回归测试（每次升级时把全部测试 term 与原版对其显式写法比较）。用第一步的
  数字再定。
  状态：**用户 2026-11-02："同意"**（按推荐，第一步实测后定去留）；已写进 §1 第 22 条。
- **2.7 第 14 条（问题 10；知情、重新确认）。** 去掉 bundle 时我告诉用户"没办法只对一个 lemma 打开""bundle 是唯一不漏的写法""locale 里 declare 会延续到
  该 locale 以后所有地方"。前两句不对：原版 `context notes [[dot_syntax]] begin … end`（Pure.thy:690-691）就是限定范围的写法，可包住一个或几个 lemma，
  也可在 locale 里用（AFP 已有此用法，如 `LinearQuantifierElim/Thys/QE.thy:126`）；第三句不全：locale 里的 `declare` 还到达导入它的 locale、sublocale
  目标、interpret 它的 theory（从那条命令起）及其导入者；无名 `context begin … end` 块与 light-locale 块里的 `declare` 作用于整个 theory；
  `lemma notes [[dot_syntax]] shows …` 看似限定，陈述却按原开关读（expression.ML:312）。实测 `review-decisions/P_Scope.out:19-65`、
  `defend-surface-2/probe.out`。推荐：保持继承、无 bundle，文档教 `context notes`。
  状态：**用户 2026-11-02 "第 7 件赞同你的建议"**——维持随 import 继承、不要 bundle；已在第 14 条加更正与确认。
- **2.8 第 20 条的缺口也包括 light-locale 块与无名块（问题 10）。** 在这两种块里 `declare [[dot_field …]]`（与 `[[coercion]]` 等一切声明 attribute 一样）
  作用于整个 theory 并传到导入者（light_locale 自己的规则 `LIGHT_LOCALE_PLAN_REV37.md:3284-3299`；原版无名块 generic_target.ML:407-409）。推荐：确认，
  写进文档，限定范围的写法也是 `context notes [[dot_field …]] begin … end`。
  状态：**用户 2026-11-02 "第 8 件确认"**；已在第 20 条注明。至此 2.1–2.8 都已答复。
*我的待办（JUDGE §4；向用户说明修法计划、用户同意后手工改，改完送短评审）：* **状态（2026-11-02）：** 我把下列修法逐条讲给用户，用户答"既然不需要跟我
讨论的话我不予置评"（即由我按授权定）。我已手工改完问题 2、3、5、6、7、8、9、10、11、12、14、15、16 涉及的 §0、§3.3b、§3.4、6.2、6.3.2、6.3.3、6.4、
6.5、6.5.1、6.5.2、6.5.3、6.6、6.7、6.8、6.9、6.10、6.12；下面各条留作修法的记录。第八轮短评审已复核（见本节末尾）。
- 问题 2（文本）：改写 §0 的 I1a、第 22 条（加注，保留用户原话）与 6.5.1：条件 1 是每个成功 local pass 按构造就有的性质，不测；运行时唯一的测试是
  coercion_args 条件；写明两个前提（无等待遍历的代码形状：经 `node_instance` 展开节点加原版的应用步骤、参数编号 type_infer.ML:80-85、D6 的 spine 读法、
  coercion_args 条件；帧从自己保存的状态重跑）。交付代码不带 `waited` 与 I2 计数；推迟成功的出口（s3c:3289-3297）也经单一出口函数；G2 去掉"I2 布尔量
  回退 0 次"，两个 Done 出口都做"每个 Done 重新推断对照"；6.5.1 写出默认路径（只在 option b 的学习报错且 pass 做过有约束力的选择时走；最后的规则报错只在
  `binding_now` 与 C_bind 上的 coercion_args 条件下报；只会拒绝，不影响 R1）；6.5 的不变式按问题 3 改述。不采用：把条件 1 改成第一次等待时就设的真过滤。
- 问题 3：G2 加第一轮审计（移植 `reviews/round6/d14/verify/proto/type_infer_restart.ML:471-524` 的 `DOT_V_R1AUDIT`）：标准引擎决定过字段（节点、晚决定、
  学到）的每个批次，第一轮输出与原版 `infer_types` 加 `expand_abbrevs` 在 E(C) 上比（aconv，含类型与 sort），要求 0 DIFF、0 STOCK-ERR；G3 加变异
  `late_no_result`（第六轮 VERIFY：67 个攻击批次错 51 个，只改变 79 个判定中 1 个，所以端到端 G1 抓不到）；6.5 的不变式改述：开关关闭或没有载体时各引擎
  逐字跑原版函数；每个被接受的 term 等于原版对 E(C) 的推断，经三条路之一——观察者实例（按构造）、I1a（按代码形状，"每个 Done 重新推断"检查）、标准引擎
  自己的推断（按晚决定论证，第一轮审计检查）；6.5.2、6.5.3 写明那里 R1 靠论证，8,110 个批次是原型的数字。
- 问题 5（文档）：第 16 条的陈述一项（加注）、6.7 表、6.9 改成一条规则"变量只有在读入时已绑定或已固定才是局部的"；列出命令（`definition`、`abbreviation`、
  `fun`、`function`、`primrec`、`primcorec`、`partial_function`、`inductive`、`fixrec`、`nominal_primrec`、locale 假设）；补救：方程上 `for x`
  （parse_spec.ML:64-67；`primcorec` 没有）、陈述里 `fixes`、不是常量前缀的变量名（`s.pc` 按第 6 行读成字段访问）、显式写法；第一步端到端测试加
  `fun`、`definition` 方程（带不带 `for`，覆盖第 4、5 行）；第 5 行的报错变体在文案过目时说明"第一段在此处不是局部变量"并提 `for`/`fixes`。不采用：
  按名字把隐式自由变量当局部（违背 6.3.1 按绑定判断的卫生）。
- 问题 6：6.12 第一步加第一个子步骤"参考原型移到 Isabelle2026"：引擎用第六轮的 2026 移植（`reviews/round6/d14/verify/proto/subtyping_esr3_restart.ML`、
  `type_infer_restart.ML`、`Loader.ML`）；解析、登记、警告的参考从 2026 原版重新生成（用原型自己的 diff 或生成器 `make_trans_v.py`、`parse_side.diff`，
  不手改 2025-2 副本，去掉 2025-2 的 light_locale 行，用第六轮的 loader）；在 cslh19 上跑各自的测试列表，2026 的输出作为 G1 的参考，与 2025-2 的差别
  作为信息报告。G1 改述：逐例比判定、被接受的 term（aconv）与 C，以原版 2026 对 E(C) 为准；参考的开关取本章的值（`dot_object_own_type` 开、`dot_late_rerun`
  开；D14 的参考配置见 6.12 G1，第八轮短评审第 6 条补全）；允许的差别在第一步前列出（I1b 去掉、修法 B/C 去掉、第 0 级重跑去掉、§4 列的解析与登记的去除、Isabelle2026 自己的改动，各追到 diff 行）；文案只与
  2026 上记录的参考比，其余文案差别交 6.6 的文案过目（放宽 4，我的权限）。卫生 oracle 与开关关闭的语料检查不需要参考，在 2026 上对同版本原版重跑。
  §6 开头的差异清单加 `case_translation.ML`（现为 `declare_term_names`）与 `variable.ML`；6.10 加一行：2026 链里 light_locale 与 fast_abbrev_printing 在
  dot_syntax 之下，改 `syntax_phases.ML`、`proof_context.ML`、`attrib.ML`、`ROOT.ML`。
- 问题 7：干净代码是唯一来源；一个脚本用"恰好匹配一处、否则停"的编辑（仿第四轮 `make_v.py:20-23`）派生出用户空间可加载副本、G2 用的一个观察构建、
  G3 每个变异一个构建；装不上或载入失败的变异单独报、不算抓到。G1、G4、G5、G6 在干净构建上，G2 在观察构建上，G3 在变异构建上。TEST_PLAN §5.6 的
  22 个任务对照改为"观察构建与干净构建在每个 G2 任务上判定、term、文案相同"；TEST_PLAN §8 的补丁对照作为第二步的门槛。不采用：把计数器做成 functor 的
  额外钩子实例（会把测试接缝放进交付的引擎）。
- 问题 8（第 1–3 点）：6.12 的"第一步测不到的"改成表（最终代码元素 | 第一步的替身 | 第二步的直接测试）：载荷重建——把最终的重建函数注册为 −100 级以下
  的检查（不用第六轮那个被 Isar 命令绕过的包装），于是 class specification（class_declaration.ML:354）在第一步就到得了，class target 的 D14 路径成为
  第一步的测试 | 第二步：coercion 打开时 0 个 `Bad name binding`；出口报告——最高级的 `term_check'` | 每个字段那一段在批量与 PIDE 里各报告恰一次；
  替换 `"standard"`——引擎在 −1/0 级 | coercion 关闭的测试集逐例对照；第 1 级的顺序——第六轮的观察者 | `print_checks` 显示 dot 检查在第 1 级第一个，
  加 D14 例子与 adhoc、`case` 的第 1 级检查并存；打印——第一步直接调用 | 真实的 `term` 与目标输出、golden。fast_abbrev_printing 的 golden 挪到第二步
  （它要构建好的 session）。写出第二步门槛（G7）：G1/G4 测试集与 Isar 命令、class 的例子在私有树上重跑、与第一步逐例对照，加表的第二步一栏。开关关闭的
  部件行在第一步用同进程的原版副本对功能副本测（规则 (2)）；改 6.11 待办与 6.12 里"计时问题已定"的说法（第 24 条是为第一步的行批的）。
- 问题 9（第 2–4 点）：规则 (2) 不含 6.8 已批例外的行（如带限定名常量，按已批数字判：每个 ≤ +1.1 µs）；第一步开头写参考表：每组行对应的参考原型与配置
  （引擎行：s3c 的 2026 移植、D15 开；D14 行：NEW-observer），列出 §6 有意移动的行与预期方向；参考与新代码在同一轮计时里在 2026 上用 COMPARE §2 的方法
  重测；带插桩副本把 I1b 捷径作测试开关（受 I1a 的 coercion_args 条件限制），C2 行带与不带各测一次，不通过时按规则 (4) 连同"发布受限的捷径"这个选项
  报用户；交付代码不预先带它。
- 问题 10：第 14 条（加注）与 6.2 把"第一版没有'只对一个 lemma 打开'的专门写法"换成五点：限定范围用 `context notes [[dot_syntax]] begin … end`（theory 级、
  `context L begin` 里、包住一个或几个 lemma）；`lemma notes`、`using`、`supply` 只作用于证明，不作用于陈述；theory 级 `declare` 到达所有导入者，父 theory
  值不同时 `imports` 里靠前的胜出；库 theory 用限定块；locale、无名块、light-locale 块里不用 `declare`（到达以后每个 context、导入它的 locale、sublocale
  目标、interpret 它的 theory 及其导入者，或在块里到达整个 theory）。6.4 对 `[[dot_field]]` 同样写，并把第 20 条的缺口扩到 light-locale 块与无名块；
  §3.3b 里 P12"符合设计"那句加注（P12 测的是已去掉的命令形式）；G4 加全部探针形状（light-locale 块在 base 合并时测，无名块在第一步测）。不采用：恢复
  bundle；在 locale 里用 attribute 时警告（分不清 `declare` 与嵌套的 `context notes`）。
- 问题 11（不阻挡第一步）：把登记设计 `reviews/round3/registry/DESIGN.md` §8.2（:758-783）的块路径带进 6.4、6.10，并细化：localized_record 进 base 后，
  在 `local_add_record` 末尾、背景第 3 步之后、每条路径上写 `Local_Theory.background_theory (Context.theory_map reg) #> Local_Theory.map_contexts (K (Context.proof_map reg))`
  （localized_record 给 Induct 规则用的同一形状），去掉 `definition` 里那一行；`context -` 也算 theory 级、只写 theory 看不到（`defend-integration-1/P_Defend.out`
  Q2）。§3.4 的"localized_record 预计会改 `record.ML`（未核实）"换成事实；base 合并时的块测试：嵌套 `context`、locale 的重开与 interpretation、light-locale
  块、`context -`、ML 调 `Record.add_record`；登记设计第 13 行（私有 record 的字段在作用域外可经 `r.x` 访问）作为 rebase 时的用户问题。现在 localized_record
  以上各分支都还在 7d475f7，所以缺口在 base 合并时出现，不在第一步。
- 问题 12：6.5.3 的学习用上下文加 `coercion_enabled` false（第六轮实测的形式，`verify/proto/Restart_Base.thy:759-790`；已批的 D14 开销是 coercion 关闭时测的）；
  把"dot 代码见到学习标志就只做学习所需的事"换成两处查标志的地方：标准引擎入口跑原版 `infer`、记对象类型（修补 2）、原版 `expand_abbrevs`，不进引擎主体；
  第 1 级的 dot 检查在含载体的批次上抛 LEARNT（修补 1）。为开关打开的形式重述两条性质：学习运行里不跑引擎主体，所以那里不决定字段（R2）；只有引擎主体启动
  学习运行，所以不嵌套，一次推断的学习运行不超过载体数。可选：`Dot_Field.learn` 见到上下文已带学习标志时 `Fail`。
- 问题 14：6.3.3"直接调用 `infer_types` 的代码也由它决定或报告每个字段"改为：不外泄的保证在 `Syntax.check_terms`（原版对 adhoc_overloading 与 `case`
  也是这样，adhoc_overloading.ML:221-222、case_translation.ML:461）；直接把解析输出交给 `infer_types` 的代码会收到载体（Isabelle 8 处、AFP 21 处都不受影响）；
  6.5 写明引擎只经两个注册的检查到达，原版名字 `coercion_infer_types`（未导出，subtyping.ML:7-13）绑定 functor 的无钩子实例；6.5.3 那句改为"直接调用者
  到不了引擎，所以不学"；文档给工具作者一行（第三轮 K10）。
- 问题 15：6.8 的"开关关闭时仍会跑的"列全（每次 `parse_term` 读开关；`ast_to_term` 的模式测试与 `decode_ident` 子句；`Term_Position` 读者多的子句；警告通道的
  decode 参数；打印器读开关；`term_check'` 包装；文法构建把 `field_dot` 产生式挡在 lookahead 表外），规则 (2) 用按构造包含全部开关关闭路径的端到端行判
  （第一次解析；第四轮语料上的 tokenize/parse/decode；`check_terms`；unparse；`make_gram`），第二步加一行真实树的行；6.3.2 加一句 `field_prods`（两条 `_dot_field`
  产生式若进 lookahead 表，第一次解析在 HOL 文法上多 4.6%，`reviews/round3/parse/RESULTS.md:77-87`）。第 14 条不变；`print_syntax` 在开关关闭时也显示这两条
  产生式（如 `print_options` 显示开关），仅供知情。
- 问题 16（与整理一起做）：6.10 写明第 0 级 `"standard"`（syntax_phases.ML:1041-1043）与 coercion（subtyping.ML:889）的注册改为 `term_check'`，开关关闭时
  是原版 `simple_check (op aconv)` 作用于原版函数（导出 `simple_check`，一行签名，不复制）；6.5.2 的 `Type_Infer_Context.standard_check` 不是原版函数，是新引擎
  入口；6.5.3、6.8 里"待用户批准""未单独问过用户"按 11-02 的答复改；第 16 条（"只在 IDE 里"）、第 15 条（10 条加 `and N more`）、第 10 条（2025-2 的名字）
  加"已被第 N 条取代"，凡"取代第 N 条"处在第 N 条都有回指；G2、G3 里的标签各用一句话说明（预测审计 = `S3B_AB_PRED` 与 `S3C_PRED_AUDIT`；PROP-DUP；
  "3.2、3.4、3.6"是第五轮评审的小节；6.5.1 的 D9、D12、D13）；6.4 里"copy 不含 schematic term 变量就保留"是第三轮 term 登记的遗留，随 2.1 的答复改（11-02 已改，存 term 后这条规则重新有意义，并加了细化）。
*文中有误或不全之处：* 2026-11-02 已全部改好（§0 的 I1a、第 1、9、14、16、20、22、24 条、6.2、6.3.3、6.4、6.5、6.5.1、6.5.2、6.5.3、6.7、6.8、6.9、6.12），
第八轮短评审已复核（见本节末尾）。
*已驳回、不要再提（JUDGE §3、§5）：* 恢复 bundle；把登记的 term 放进 `Token.Term`（locale 每次激活都重新变换 attribute，serial 会变）；`Dot_Field.mode` 访问器；
学习运行关开关（给每次开关关闭的检查加两次上下文查询，违反 R3）；第 9 条的混合规则（用户 10-31 已否决）；让警告信号改变第 6 行的读法；只对标识符对象
定义 D15；"计时参考同进程交替"（各原型定义相同的结构，常常做不到）。
*接下来（JUDGE §6）：* ① 按 2.1、2.2、2.3、2.4 与 2.5、2.6、2.7 与 2.8 的顺序一个一个向用户讲（2026-11-02 已完成）；② 把"我的待办"的修法计划讲给用户、
手工改（2026-11-02 已完成）；③ 短评审（全新 agent，只审第七轮之后改动的 §1、§6 部分；结果用中文向用户汇报，用户同意前不改；2026-11-02 已完成：Workflow `wjz46dij8`，
三个角度 fidelity / engine / surface、每个至多 3 条质疑、每条一个全新辩护 agent、一个 judge，全部 Opus xhigh、只读、不跑 Isabelle，目录
`reviews/round8/short/`，报告 `JUDGE.md`；结果与处理见本节末尾）；③′ 轻查（全新 agent，`reviews/round8/short/LIGHT_CHECK.md`，2026-11-02 完成，
它指出的五处残留已手工改好）；④ 第一步：参考移到 2026 与
派生脚本 → 参考表 → 第一次解析与无钩子实例的计时 → 合成代码 → 改述后的门槛；第一步也测 2.3 与 2.6 所需的数字。

**第八轮短评审结果（2026-11-02 完成；Workflow `wjz46dij8`，报告 `reviews/round8/short/JUDGE.md`，353 行）：** 有条件可开工（ready_with_conditions）。
用户的决定都成立，不需重新设计。9 条质疑辩论后留 8 条（按报告编号）：
1. （major，我改）D15 在求解后的状态里有两处读求解前的类型 `tye0`：`chosen`（s3c:2906-2910），以及 `d` 与 `field_error`（s3c:2921-2924；第六轮移植里同一个
   `d` 还触发 D14 学习运行，proto/subtyping_esr3_restart.ML:3033-3048）。6.5.1 只删了前一处；只删一处会让内部文案 `Field "ih" is decided` 露出来（读码推出的例子
   `(n::nat) = (i::int) ∧ map (λt. t.ih) [ns] = []`）。改法：求解后对该字段在求解出的类型上只求一次决定，选择、D14 触发与规则文案都由它给出；D9 的注释、
   6.5.3、G3 的变异（两处各一个）与 D15 的测试（加上面的例子与一个 D14 例子）同改。
2. （我改）模式类型在 §0 术语表与第 1 条 11-01 那段仍按"常量的声明类型"定义；第 1 条的取代清单要明列五句；第 16 条 11-02 的注过时。
3. （**须告诉用户，属知情**；定义文字我改）2.1 的代价我只讲了一半：ctrl-click 也落在展开后的常量上（`length` 字段跳到 Nat.thy 的 `class size`，不是
   List.thy 的 `abbreviation length`）；带参数的缩写（如 `sym_diff`、locale 里带参数的 `abbreviation`）存成 λ-term，没有头部常量，字段那一段不报实体标记
   （没有悬停与跳转）。被接受的 term 不受影响（第 0 级的 `expand_abbrevs` 做 β 归约，variable.ML:294-298；pattern 模式不做，proof_context.ML:716，R1 仍按 E(C)
   成立）。头部常量定义为存下的 term 经 `Envir.beta_eta_contract` 后的 `head_of`，是 `Const` 时才有；I1a 的 `coercion_args` 测试照旧读节点的原样头部。
   2.1 状态句保留，后附更正注。第一步子步骤 4 写标记报告之前要告诉用户；子步骤 1–3 不必等。
   **状态（2026-11-02）：** 已告诉用户。用户不接受 ctrl-click 落到展开后的常量，提议"记录 checked term，内部处理时 uncheck"：存法不变，标记取折回缩写后的
   头部常量（§1 第 1 条再修订、6.6）；头部常量的定义因此改为"折回缩写、eta 收缩后的 `head_of`"，取代上面 `beta_eta_contract` 那句。
4. （我改，我按授权定的遮蔽规则）interpretation 之后在 theory 层另写 `[[dot_field a.bar]]`，新 serial 的副本在 `context foo` 里不被遮住，`xs.bar` 歧义。改法：
   与被遮住的 theory 副本相同（同一关系下）的 theory 副本也被遮住（只看"相同"，不看"实例"）；6.12 写明该测试的预期。
5. （我改）登记的读法漏了 `Variable.polymorphic`（同 `[[coercion f]]` 的 subtyping.ML:957-960、adhoc_overloading.ML:259），否则模式类型带刚性 `'a`；
   底层写明第三轮原型的形式（`Args.embedded_declaration` 加 `Scan.state`，读、查、取 serial 都在 `fn phi` 之外做一次）。
6. （我改）G1 的参考配置不全：写明第六轮验证的 `hrtl`（`DOT_H=on DOPEN_LEARN=off DOT_H_READ=reinfer DOT_H_READOUT=tagged DOT_LATE_RERUN=on`）；原型
   默认跑的是被否决的 D-open。
7. （我改，子步骤 5 之前）I1a 的计时要用观察构建的 `S3B_RECHECK_DONE`（覆盖 `done_result` 与推迟重跑成功两个出口），不用参考引擎的；26,226 只算
   `done_result` 出口。
8. （我改）几处过时的状态文字：文档开头、6.11 的开工条件、6.11 里"问题 2 的文本部分仍在我的待办"、6.5 里"I1a 的两个条件"、第 24 条注、第 9 条"用户的
   主要考虑是性能"缺回指（开头加"只转述了 05:57 原话的一句，不全，以本注为准"，不替用户解释本意）。
被删去的部分见报告 §2。开工条件：1、2、4、5、6、8 在第一步之前手工改完；7 在子步骤 5 之前；3 在子步骤 4 之前告诉用户；改完由一个全新 agent 轻查。
状态（2026-11-02）：已向用户汇报。第 3 条：用户不接受"ctrl-click 落到展开后的常量"，提议"记录 checked term，内部处理时 uncheck"；我在 cslh19 上实测
（`probes/markup_fold/`）后，用户接受"最新的缩写胜出"这一代价，定下（§1 第 1 条再修订、6.4、6.6；头部常量 = 折回缩写、eta 收缩后的 `head_of`，取代上面
`beta_eta_contract` 那句）。其余各条用户答"不需要跟我讨论的我不予置评"，我按授权手工改完：第 1 条（6.5.1 D15、D9 注、6.5.3、G3、测试）、第 2 条（§0 模式
类型、第 1 条取代清单、第 16 条注）、第 4 条（6.4 遮蔽、6.12 预期）、第 5 条（第 1 条与 6.4 的 `Variable.polymorphic`、6.4 底层的参数形式）、第 6 条（G1 的
`hrtl` 配置）、第 7 条（第 22 条、6.5.1、G2 的出口说法与 26,226 的限定）、第 8 条（文档开头、开工条件、2.6 状态、6.11 第一段、第 24 条注、第 9 条回指）。
下一步：一个全新 agent 轻查改动是否与 `reviews/round8/short/JUDGE.md` 一致（报告要求，不再起辩论），然后第一步。——轻查 2026-11-02 完成
（`reviews/round8/short/LIGHT_CHECK.md`），指出的五处残留与三条可选补充都已手工改好。

**压缩前的交接（2026-11-03）：** 用户问"现在可以实现吗？前置 feature 包都实现好了吗？"；我查了补丁链现状（6.10 末尾：只发布了 bicompose_rename_fix/1 与
fast_abbrev_printing/1；light_locale 在做、未 push；local_type_abbrev、localized_record、local_datatype 在 2026 上都没有实现），答：第一步不依赖它们、现在就能做；
第二步建议等 light_locale 至少 push 后再问用户；发布要等它们都发布。用户答"建议在 compact 后开始第一步 / 请准备 / 请再次通读计划，确保自洽，详细"。
我于 2026-11-03 通读全文（§3 是过程记录，只核对了改过的部分）并改正了发现的不一致。**压缩后的下一件事：开始第一步**，顺序见 6.12 第一步的子步骤：
① 参考原型移到 Isabelle2026，并写派生脚本；② 参考表；③ 第一次解析与 coercion 引擎无钩子实例的计时；④ 合成代码；⑤ 门槛验收与要报用户的数字。
开工前：读技能 `isabelle-patch-feature`（6.12 第 0 步；2026-11-03 已读过一次，§3.9 第 4 步"在 2026 上从头实现"）。**仍待用户回答：** cslh19 上用户自己的
`Probe_DBM` 构建（`isabelle build -j 2 -o threads=10`，11-02 23:06 cslh19 时间仍在跑）跑着时，第一步能否在那里起进程（`nice -n 10`、
`taskset -c 0-7,10,11,14-23`，计时只用 CPU 8、9、12、13 并排 `TIMING.lock`），还是等它跑完——开始第一步前先问。cslh19 的工作目录用
`~/Current/MLML/ai-artifacts/dot_syntax_timing/<子目录>/`；读 theory 用 `reviews/round7/deep/review-surface/use_thy26.ML`（Isabelle2026 没有
`Thy_Info.use_thy_legacy`）；运行命令形如 `nice -n 10 taskset -c 0-7,10,11,14-23 ~/Isabelle2026/bin/isabelle ML_process -l HOL -f use_thy26.ML -e 'Use_Thy26.use_thy "<绝对路径>"'`
（2026-11-02 的 `probes/markup_fold/` 就是这样跑的）。

**第一步子步骤 1 的结果（2026-11-03 10:20 UTC）：** 用户 11-03 答"开始"；开工时 cslh19 上已无进程（`Probe_DBM` 跑完），上面那个问题不用再问。第一步的
目录是 `ai-artifacts/step1/`（已加进 `.gitignore`，不提交）：`ref/<部件>/` 是各参考原型的 2026 移植、输出、`reference.tsv`（逐例参考）与 `PORT.md`（移植
记录与对 2025-2 的逐例比较），`derive/` 是派生脚本，`probes/` 是我的探针。移植由五个 agent 并行做、一个 agent 扫 AFP（规则：从 2026 原版用原型自己的
diff 或生成器重新派生，不手改 2025-2 副本；只在 cslh19 用 `ML_process`，不计时）。没有一处差别来自 Isabelle2026 对本设计相关代码的改动；各部件：
- **解析**（`ref/parse/`）：`parse_side.diff` 在 2026 原版上原样打上（只挪行号）；`Dot_Parse_User` 91/0、`Dot_Parser_User` 33/0、变异 m1、m3–m6 抓到的数目与
  6 个 MEASURE 都同 2025-2。两个调试 theory 的文案差别来自原型后来换了载荷编码，不进 G1 参考（我定）。只有计时 theory `Dot_Parser_HOL_Cost` 用 HOL 语料，
  未跑；它的计数要不要进参考，到子步骤 2–3 再定。
- **登记与警告**（`ref/regwarn/`）：原型代码都没改；警告原型的两份"原版副本"带 2025-2 的 light_locale 行，已从 2026 原版重新派生。890 项里 886 项逐字节同
  2025-2，其余 4 项是 P06 合并冲突从另一边报出（新 loader 顺序读 A、B，2025-2 并行读，当年就见过翻转）。P12（light-locale 块）照旧在 base 合并时测；
  on_parse 底子用警告原型自己的解析快照即可（我定）。
- **局部变量优先**（`ref/localfirst/`）：设计 D 的 `make_proto.py`、验证者的 `make_v.py` 一处没改；`make_trans_v.py` 改成读 2026 原版，`trans_v.ML` 现在
  编码 2026 的 `case_tr`（`declare_term_names`）。801 个共有用例 781 同、20 不同，全是 2025-2 语料上的计数，因 2026 把 `enumerate` 改名 `indexed_from`；
  41,458 处 0 不一致、开关开关都同原版、J01–J14、D 的 70 探针 69 过、24 个卫生攻击、各变异都同 2025-2。找回了当年抽语料的 13 个 HOL theory（逐字节
  重现旧语料）；2026 语料 10,065 条、41,625 处 0 不一致，开关打开时只有 `auto intro: order.strict_trans` 一条与原版不同（见 6.12 G1 补的允许差别）。
  设计 D 自己那份原型的输出不算 G1 参考；`J_All.thy` 与被否决的 A、B、C 不移植（我定）。
- **第六轮引擎**（`ref/engine6/`，本来就是 2026 代码）：`hrtl` 配置两种 coercion 模式，harness 154、tests 34、探针 6 个任务，66,860 个判定。与第六轮其他
  配置的输出相比，差别都可归到 `DOT_LATE_RERUN`（7,439 例报错改成原版的 `Type error in application`）、`DOT_H_READOUT=tagged`、`DOT_H_READ=reinfer`。
  harness 在同一进程里把 dot 写法与作者写的 E 都交给原版比较，SAME 即与原版对作者的 E 推断 aconv，E 写明了 C，所以逐例比判定标签就比到了 term 与 C，
  不必另记 term（我定）。6 个 DIFF 是成对的对照用例（如 `B1-fint`/`B1-fnat`，没选中的那个按设计 DIFF）；11 例判定与标签不符，第六轮就有，作信息列出。
- **第三轮 s3c 与 stage0 的其余测试**（`ref/engine3/`）：80 个 s3c 测试 theory 移到第六轮引擎与测试层上，另跑 s3c 列表 B 的 37 个额外 fuzz 种子；125 个参考
  任务。8,541 条记录 8,168 同 2025-2，373 条都归了因（2025-2 A/B 的计数重复 19、`dot_late_rerun` 108、第六轮测试层的打印 201、第六轮标准引擎 14、D14
  机制 5、只差 `??'a` 编号的文案 26 条未追到原因，按上面的重编号比较）。接受与否变了的只有 PB_Adhoc 的 2 例（D14，由拒变受）。我定：G1 取参考配置的
  运行；测试层开关 `STEP1_ESR_CTXT`（让 RR 用例按自己的开关跑，68/68 门全过、RR_Mut 16 抓 14，同 2025-2）可以保留，那些运行作信息；stage0 的 6 个
  变异针对已去掉的第 0 级重跑，不进 G3（`no_print_translation` 那一处对应的打印翻译仍在，G3 照它另做）；参考文案里"not determined enough to choose
  among:"后候选列表为空是第六轮标准引擎的缺陷（type_infer_restart.ML:135），新代码不重现，交 6.6 文案过目；s3c 树里没有任何列表跑的 theory 与更早
  几轮的列表不在范围内。
- **AFP 扫描**：0 处（6.3.1）。
- **派生脚本**（`derive/derive.py` 与 `edits.py`）：框架写好、在 scratchpad 自测过（每处编辑恰好匹配一次，否则整个停下；变异装不上单独报告；每个构建
  写 MANIFEST；派生出原版副本、干净构建、观察构建、各变异构建）；编辑清单在子步骤 4 填。
- **合成时要处理**：2026 新增的 legacy 警告"ML string looks like formal name"（`ML_check_strings`，Pure.thy:1642）在原型的 `dot_field.ML` 第 36、68、73 行
  也会报。
- **functor（待用户答）**：计划两处写"改成 functor"（6.3.2 的 Earley、6.5 的 coercion 引擎）。实测（`step1/probes/functor_cost/`，计时 CPU、持锁）：循环体
  大到不能内联时，functor 实例同原版（0.1990 对 0.1998 秒），高阶函数慢 27%，钩子经 ref 慢 59%，所以只有 functor 不加开销。但 Standard ML 的 functor
  只能声明在最外层（实测 Poly/ML 拒绝写在 structure 里），而要共用的代码在 `structure Parser`、`structure Subtyping` 内部。我提议的切法：原版
  `structure Parser: PARSER =` 改名 `structure Parser_Base =`（内容不动），Earley 那一段（`type state` 到 `parse`）包成 `functor Earley (Scan: EARLEY_SCAN)`，
  四个钩子（预测产生式、扫描时输出 token、字面 `.` 的匹配、收尾筛选），文件末尾新写 `structure Parser: PARSER` 做两个实例；`subtyping.ML` 切成
  `Subtyping_Base`（数据、合一、报错函数）、functor（约束生成、求解、插入、local pass；约六个钩子：遇到载体、应用处记操作数类型、宽容地强转运算符、
  求解时两处宽容、learn）、`structure Subtyping`（注册与声明）。代价：多出两个全局可见的内部 structure 与两个 functor 名字。已问用户能否这样切、名字
  是否另取。
- **用户答（2026-11-03）：** "具体实现上的，在不改变设计的前提下，你可以自决"——functor 照上面的切法与名字做（我定）；此后凡不改变设计的实现细节都由我定，
  改变设计的仍先问。G1 补的两项允许差别："你 run Opus agent 检查一下，没有需要我关注的我就不想管了"——已派一个全新的 Opus agent 独立核查（10:40 UTC），
  它报"不需要用户"就定下，否则只把需要用户的那部分拿给用户。——核查报"OWNER NEEDED: no"（两项都由已定设计推出，不改设计、不加开销、不是 R1–R3
  的例外），但原写法太宽、会放过真正的回归；已按它收窄后的写法改进 6.12 G1。

**第一步子步骤 3 的前一半：第一次解析（2026-11-03）。** 干净代码放在 `step1/src/`（Isabelle 树里的路径），现有 `src/Pure/Syntax/lexicon.ML`（解析原型
2026 派生的那份，词法只认 `)` 之后的点）与 `parser.ML`（6.3.2 末的 functor 写法），由 `derive/` 派生出原版副本与干净构建。探针在 `step1/probes/first_parse/`：
同一进程里装原版副本 A、逐字节相同的对照副本 B、干净代码 F（及各变体），在 HOL 的文法上跑 2026 语料（10,065 条，Pure 能解析的 8,963 条）。HOL 的产生式
`Syntax` 不导出，测试里经 `RunCall.unsafeCast` 读它的私有记录（`Unsafe_Cast.thy` 在 `ML_Bootstrap` 环境里把它写进全局名字空间，只在测试里用）；
自检：各副本在全部语料上的解析树与报错都与 Pure 自己的 `Syntax.parse` 逐条相同（0 处不同）。计时在 CPU 8、9、12、13、持 `TIMING.lock`，15 轮轮换
取中位数，负载 2–6。结论（第一次解析相对 A 的中位比）：
- 计划原先的形状（钩子 structure 作 functor 参数，热循环的小函数与输出在 functor 外）：1.09–1.10，超出范围。拆开定位：不用 functor 只改文法 1.01–1.04；
  functor 不带任何钩子 1.09–1.11；同样的代码放进普通 structure 也 1.08——开销来自热循环的小函数与输出操作跨了 structure；两者都挪进 functor 体后 0.97–1.01。
- 最终写法（6.3.2 末）两次独立运行：1.003、0.988（对照 B 1.016、1.014）；tokenize 与 `make_gram` 都在噪声内。**在波动范围内，不用找用户。**
  解析 agent 指出这几次 F 的文法没有 `pure_thy` 的两条 `_dot_field` 产生式（最终的 Pure 文法总带着它们），"`field_dot` 产生式不进 lookahead 表"这条
  构建规则因此没测到；补测（11-03 13:30 UTC 前后，负载约 1.6、没有构建）：带这两条产生式的 Fd 1.004（同一轮 F 0.994、对照 B 1.006），解析结果与 Pure
  逐条相同。第二次运行开始前查到又有构建，没有跑。
- 解析原型的 `Dot_Parser_User`（k ≤ 16、k ≤ 8）在干净代码上：只有 L4、Q6 不同，即 `[…].f`/`{…}.f`（§4 已去掉），其余与 2026 参考逐项相同（含树的形状）。
- 微测（`step1/probes/functor_cost/`）：小循环里 functor 实例同原版、高阶函数慢 27%；但这一条不能外推到真实代码，真实的结论以上面为准。
下一步：子步骤 3 的后一半，coercion 引擎 functor 的无钩子实例（照这次的教训：热路径上的小函数与 functor 体放在一起；钩子不能先求值）。

**第一步子步骤 3 的后一半：coercion 引擎的无钩子实例（2026-11-03）。** `step1/src/src/Tools/subtyping.ML`（由 `step1/tools/edit_subtyping.py` 从原版
派生，原版文本只在下列几处变）：切成 `structure Subtyping_Base`（只有 coercion 数据，加钩子记录的类型与 `no_hooks`）、`functor Coercion_Inference
(val observed: bool val learning: bool)`（从工具函数到整个推断流程，原文顺序不动；只有声明部分也用的 5 个工具函数——`restrict_graph`、`t_of`、
`is_funtype`、`mk_identity`、`maybe_new_node`——经最后的 structure 打开原版实例取得，不复制）、`structure Subtyping: SUBTYPING`（三个实例
`Stock_Coercions`、`Observed_Coercions`、`Learning_Coercions`，原版名字 `coercion_infer_types` 绑原版实例加 `no_hooks`，其后是原版的登记与声明）。
钩子（每次调用传入的记录，开关是 functor 的常量参数、一律惰性测试）：约束生成里遇到载体（learning）、应用处的操作数类型（observed；local pass 的 `inf`
里同一处）、一次应用的约束（learning，拿到原版那一步——为此原版应用那几行提成局部函数 `app`，内容不变）；求解里弱合一失败与"different constructors"两处
宽容（learning）、化简后与求解后各一次 learn（learning）、bound 报错里的显示（learning）。学习钩子的确切类型在子步骤 4 合成时可能再改，改了就重测。
用户空间副本由 `derive/edits.py` 的四处编辑得到（导出 `coercion_infer_types`；不再登记开关、检查、attribute 与命令；`userspace_replay` 把 HOL 的 7 个
coercion、3 个 map 函数、5 条 `coercion_args` 重放进副本自己的数据）。探针 `step1/probes/coercion_first/`：Complex_Main 里同一进程装 A、B、F，输入照
`check_terms` 准备（`prepare_sorts`、`prepare_positions`、追加 `TYPE` 项），2026 语料 8,962 个批次，A 能推断的 8,874 个；B、F 在全部批次上与 A 相同
（term 与类型 aconv，报错文本相同）。计时（CPU 8、9、12、13、持锁，15 轮轮换）两次：F 0.995、1.012（对照 B 0.995、1.001）。**在波动范围内，不用找
用户。** 语料几乎都在 local pass 成功，钩子所在的 global algorithm 路径这里走得少，G6 用引擎的计时行（coercion 打开、走 global algorithm 的例子）补测。
下一步：子步骤 2 的参考表（含把各原型的计时 theory 移到 2026），然后子步骤 4 合成代码。
——用户 11-03 答"继续"。子步骤 2：五个原部件 agent 各自把本部件的计时 theory 移到 2026、冒烟跑一次（计时规则下，数字只作信息）、逐行清点，写进
`step1/ref/<部件>/TIMING.md`；参考表由我据此手写。子步骤 4：先由一个 Opus agent 只读清点各原型的 `Dot_Field` 与每个最终文件的起点代码、§6 要做的改动、
§6 留给第一步定的地方、写作顺序；合成的设计（统一的 `Dot_Field` 签名、部件划分）由我手写进 `step1/MERGE.md`，再动手。
——清点完成（存为 `step1/MERGE_INVENTORY.md`，614 行）；`step1/MERGE.md` 已写（2026-11-03）：文件与读入顺序、`Dot_Field` 各同名冲突的定法、INV D
列出的每项选择的决定（都是不改变设计的实现细节）、写作顺序（11 步，每步写完在用户空间测）、要改计划的地方（已改：G1 补 (iii) 警告对象规则、第二步
`print_checks` 与"报告恰一次"两句、`syntax.ML` 两行）。另：cslh19 上 11-03 发现检查命令漏掉构建（JVM 命令行是 `isabelle.Isabelle_Tool build`），此前
我与各 agent 的运行可能与 `~/locfix/` 下别人的构建重叠，期间的计时只作信息；已通知各 agent 改用 `pgrep -af '[I]sabelle_Tool build|[i]sabelle build'`
并在有构建时暂停。

**第一步子步骤 2 的结果：参考表（2026-11-03）。** 五个部件的计时 theory 都已移到 2026、能读进来跑（各 `step1/ref/<部件>/TIMING.md`：localfirst 33 行、
parse 6 个 theory、regwarn W1–W4 与登记 R1–R3、engine6 181 行（D14 的参考是 C_Timing 55 行）、engine3 s3c 227 行）；冒烟数字只作信息，与别人的构建
重叠的已在各文件标出（engine3 还有 29 个冒烟任务因 cslh19 被占没跑，留到正式计时轮次一并跑）。参考表 `step1/REFERENCE_TABLE.md` 按行组写明：参考原型与配置、
所用规则、有意移动的行与方向、不进 G6 的部分。其中我定的几件（按授权）：原版列一律是同进程的原版读法本身；只在设计 D 自己的原型上测过的行改在被采用
的验证者原型上测（已批数字照旧）；D14 两种配置都跑（COMPARE 的 NEW-observer 与 G1 的 `hrtl` 差读法与 `dot_late_rerun` 两个开关），新代码与机制相同的
那一种比；a04（一个 D14 对象上 10 处访问，2.72–2.76）在已批的 NEW-observer 整列里，不算超出；登记表在真实结构上重测、按已批数字判。
**cslh19 与别人的构建（用户 2026-11-03 答"赞同"）：** 从 13:19 UTC 起 `~/light_mutants/` 下另一个 agent 的变异测试一个构建接一个（约 90 个、每个约 5 分钟）。
用户定：别人构建期间可以跑**正确性测试**（`nice -n 10`、CPU 0–7、10、11、14–23、每个 agent 至多两个进程、仍先查没有 z3/cvc5/veriT，不看负载上限）；
**计时**照旧只在没有构建时跑（起跑前与拿到 `TIMING.lock` 后各查一次 `pgrep -af '[I]sabelle_Tool build|[i]sabelle build'`）。

**第一步子步骤 4 的进展（2026-11-03）：** `MERGE.md` §5 第 1–3 步（`dot_field.ML` 的核心、`term_position.ML`、`dot_field_attrib.ML`、`proof_context.ML` 的
签名一行）已写，测试在 `step1/tests/core/`：14 个 theory 0 FAIL、0 MISMATCH，18 个变异全抓到；与登记原型参考的差别都由设计造成（只登记常量、存读出的
term、遮蔽与细化、不再有命令与合并后的检查）。它留下的问题我按授权定了（文案细节一律进 6.6 的过目）：写出的前缀是常量时的变体由载荷里的标志触发
（`decode_ident` 第 5 行，或第 6 行第一段本身是常量）；括号形式第 3 步作 `"(f k).foo" is not a field of …`；候选按折回缩写后打印的头部常量名排序；报错引用
载荷里所写的文本；字段报错带字段那一段的位置；删除也接受简写 `[[dot_field del c]]`；`remove` 只作用于可见的登记；第 1 级检查注册在 `type_infer_context.ML`
（用那里的 `unify` 与 `prep_output`）。派生脚本的 `Dot_Build` 改为导入 `Complex_Main`（`edits.py` 的 `IMPORTS`）。第 4 步（解析一侧）已交给另一个 agent。
——第 4 步完成（`syntax_phases.ML`、`syntax.ML`、`pure_thy.ML`；测试 `step1/tests/parse/`）：V_Attack 66 行、V_DProto（除下面一类）、V_JAll/V_Fixed 的 2026 语料
（开关关闭 0 处不同、卫生 oracle 5 次运行 0 处不一致）、解析电池都同参考；新探针 Parse_Unit 50/50、括号形式端到端 24/24、原版副本在 10,065 条上与 Pure 0 处
不同。差别：G1 (i)（误拼限定名一例）、§4 的去除（`[…].f`/`{…}.f`、第 2、5 行取代第三轮的拆分）、G1 (iv)（V_DProto 七条 W1 警告按 6.6 不发，已补进
G1）、载体常量名的规范化。我按授权接受它的三个选择（`const_object` 按"对象读出来是常量"设；`decode_free` 带类型；`_dot_ident` 用字面模式），并亲手把它测过的
`Dot_Field.paren_accesses`（括号形式的载体，带标记的常量）加进 `dot_field.ML`。第 5 步（警告）交给同一个 agent；第 6–7 步（标准引擎、Pure 的 D14）
另一个 agent 在做。
——第 6–7 步完成（`type_infer_context.ML`：`prepare_positions` 的重建、标准引擎 `standard_check`、第 1 级 `dot_check`；`dot_field.ML` 加显式形式、选择回传、
第 1 级、D14 四节；测试 `step1/tests/standard/`）：coercion 关闭的参考列表 engine6 33,430 条、engine3 308 条，**判定 0 处变化**，31 处只差文本，其中 29 处
是已定的文案规则（空列表省去、5 条上限、按名排序、引用所写文本、括号形式措辞），2 处因去掉了载体节点上的载荷类型合一（报错里载体类型不对、原版 uncheck
跳过）——我定恢复这两行；G1 (ii) 成立（`hh.simps` 与原版 `fun` 读 E(C) aconv）；**G2 (b) 8,172 个批次 0 DIFF、0 STOCK-ERR**。我另定：`infer` 的四个报错辅助函数
提到外面共用（见 6.5 的注）、`Dot_Field` 里 `printer` 与 `head_constant` 的重复合一、选择由引擎写（学到的也是）、第 1 级只读、出口报告只报本批次的 serial；
两个注册（第 0 级 `"standard"` 的 `term_check'`、第 1 级 `dot_check` 排第一）在第 8 步写进 `syntax_phases.ML`。
——第 5 步（警告）完成：`dot_field.ML` 的警告一节（对象按 6.6 只认常量前缀、经 `candidates` 沿每个候选走、写出的类型与参数要对得上）、`syntax_phases.ML`
在第 4 行读成常量时记下、选定树解码后类型检查前发出；导出的 `decode_term` 不发警告。Warn_Tests_A 40/40、B 19/19、新加 3/3；与参考 671 行里 643 行
相同，其余都是 G1 (iii)（每条按 6.6 写明新期望）与 A08（第二处出现按第 2 行成了字段访问）；V_DProto H26 回到 1 条警告。我定：第三道去重在 6.6 的对象
规则下永远起不了作用，去掉（连同只测它的变异）；对象按前缀的名字找；引用的名字带位置标记（文案过目）。
——第 6–7 步的修改（恢复载体节点的载荷类型合一、`infer` 的四个报错辅助函数提到外面、`printer` 与 `head_constant` 各只一份）完成后重跑：coercion 关闭
判定仍 0 处变化，只差文本的剩 29 处（28 处是已定文案规则，1 处 V_Targets #20 是用户空间替身相对测试自己的 `singleton_fixate` 的次序），G2 (b) 仍 8,172 个
批次 0 DIFF、0 STOCK-ERR。
——第 8、10 步完成（11-04；测试 `step1/tests/parse/`）：`check` 交回上下文（我定用 `perhaps` 本来的 `(xs, ctxt)`）、`check_terms` 出口只就本批次的载荷报告字段
那一段的标记（33/33：与直接写该常量时相同、每个读法恰一次、term 与原版对 E(C) aconv；interpretation 的常量原版就报两条实体标记，字段那一段同样两条）、
两个注册（第 0 级 `"standard"` 为 `term_check'`，第 1 级 `dot_check` 在 HOL 的第 1 级检查之前登记故最先运行）、导出 `simple_check`；`CONST` 打印与载体的打印
翻译（26/26；V_Attack E01–E03 由 FAIL 变 PASS，即补上了参考记下的打印缺口，只剩按设计失败的 A22）；开关关闭时 2026 语料上打印 0 处不同、`check_terms`
的结果与 69,744 条报告逐字节同原版。
——第 9 步（coercion 引擎的 ESR 部分）完成（11-04；`step1/src/src/Tools/subtyping.ML` 2,669 行；测试 `step1/tests/coercion/`）：骨架按 MERGE.md §4 调整（准备好
输入上推断的入口、`carrier` 钩子拿到 `app` 与 `err`、`tolerate` 拆成两个、原版 local pass 的冲突路径提成一个 functor 级函数 `local_clash` 供原版 `inf` 与
ESR 共用），无钩子实例重测：与原版 8,962 批 0 处不同，计时 1.003、1.000（对照 0.997、0.998）。G1 coercion 打开：engine6 33,393 条判定相同、36 只差文本、
1 处判定（D15）；engine3 7,269 相同、749 文本、52 判定；全部归类（637 是 6.6 文案规则，约 140 是 D15 新规则，16 是去掉修法 A/B/C，18 是 RR_AB 读第三轮
计数器的门，1 是 V_Targets #20，6 是参考一侧的超时——由 `standard_check` 在批次没变时也返回 `SOME` 引起，要修）。**失去的接受 36、多出的 0**：15 是 Cargs_Probe
（§1 第 21 条已批的代价，R1 都成立），21 是 D15（D15_Probe P16–P19、L1、L6、L7、L9、F3、S3、U27，LA_Mut M-early 1–8，VC_More `(λf. f.ap0) H`，RR_AB C13）。
D15 测试：L1、L6、L7、L9 按第 3 步文案拒；U17 仍受、U18 仍拒；复合对象按第 3 步拒；`(n::nat) = (i::int) ∧ map (λt. t.ih) [ns] = []` 从不出现 `is decided`；
**带类型标注的 binder `(λt::_ list. t.ih) ns` 在 local pass 里按规则第 4 步决定、被接受为 `hd (map int ns)`**（计划预见的例外，待用户定）。G2：(a) I1a 两个出口
52,107 SAME、0 DIFF；(c) 预测 0 MISMATCH、PRED-AUDIT 0 DIFF；(d) PROP-DUP 0。I1b 测试开关触发 18,578 次、不改判定 term 文案。`dot_object_own_type` 不多余
（关掉时 10 例在对象位置插 coercion 选字段而被接受，参考拒），保留。触发频率：弱合一宽容 4,889、成环规则 1,824、节点修补 1,814（多在 fuzz）、默认路径 1,125。
G3：26 个变异抓到 19；未抓到 7（default_no_cargs、deferred_exit_no_check 两处分支测试集到不了；d13_off；构造子与运算符两处宽容从不触发；no_cycle——成环规则
触发但不改变结果，与放宽提议 4.8 有关；deferral_keep_waiting）。另：§1 第 21 条写的 `coercion_args` 代价比实际窄——Cargs_Probe CV5、CV6、CV8 字段并不等待
也被拒（local pass 在别处失败后，生成时读到载体那空的声明），待报用户。I1a 的去留还差 G6 的计时（观察构建的 `DOT_NO_I1A` 开与关）。
——11-04 已向用户报三件事：D15 失去的 21 例（知情）；`coercion_args` 的代价比 §1 第 21 条宽（CV5、CV6、CV8；我建议接受并写进文档，待用户答）；带类型标注
的 binder（(A) 列为例外 /（B）local pass 照 D15 处理，数据出来后再请用户定）。第 9 步那个 agent 研究 (B) 时上下文用完停下；另派一个新 agent 接着做 (B) 的
确切规则与实测，并在标准引擎修好 `standard_check`（批次没变时返回 `SOME`、致 6 个超时）与导出节点实例的拆解函数后，重跑 coercion 一侧。
——两处修好（`standard_check` 批次没变时返回 `NONE`；`Dot_Field.dest_node_instance`），重跑：coercion 关闭仍 0 处判定变化、G2 (b) 仍 0 DIFF；coercion 打开
6 个超时消失，其余不变（cl3）。(B) 的研究（`step1/tests/coercion/probe-B/B2/`，干净代码未动）：规则——一个选择"细化"对象类型，指对象类型在参数固定时
不是所选登记模式的实例（同规则第 5 步"匹配"的测试）；细化的选择只在最终 typing 上做：local pass 遍历中遇到就等（同第 1、6 步那样阻塞、待参数被绑定时
再决定），遍历结束时在已得的 typing 上对仍在等的字段决定一次，global algorithm 求解前不做、求解后照 D15。实测（全部 coercion 打开的列表）：除已数的 21 个
D15 损失外**再失去 6 个接受**（D15_Probe P14 `(λt. (t.pa, fst t + n)) q2`、C5 `(λt. t.sw.pa) q2`，RR_AB C12、C14、C15、C16），外加带类型标注的 binder 一族
（`(λt::_ list. t.ih) ns` 等），全部是"规则第 4 步先细化、再由周围文本要求的 coercion 改正"的那一类，都改按第 3 步文案拒；2 处只改报错文本；已批的第 4 步
细化（record scheme 的参数、`lt` 的 sort 细化）照旧；R1 在 (B) 接受的每一例都成立（DONE 复算 51,989 SAME、0 DIFF）。三部分里只有"遍历中等待"影响判定与
文案。待用户在 (A)/(B) 间定；若 (B)，三部分都保留（规则处处一样，R2 按构造成立）。
——用户 11-04 问"在 Lean 上是怎么处理的"，我答（据对 Lean 4 elaborator 的了解，未实跑）：Lean 按对象类型最外层的构造子名字选 `C.f`、再靠合一补全类型，
没有 `List Nat`→`List Int` 的自动 coercion，所以两种写法都报类型不匹配；若自定义那样的 `Coe` 实例，Lean 会在对象位置插 coercion 接受两者，正是 D15
不要的；故按已定的 D15，(B) 是一致的选择。**用户 11-04 答"按你建议来"：采用 (B)，三部分都保留；`coercion_args` 更宽的代价接受（§1 第 21 条的注、6.9）。**
6.5.1 D15 的"带类型标注的 binder 可能在 local pass 里就被决定……报用户"一句由此定为：local pass 同样处理——会细化对象类型的选择只在最终 typing 上做。
——下一批（2026-11-04）：同一个 agent 做第 8 步（`check` 交回上下文、出口报告、两个注册、导出 `simple_check`）与第 10 步（`CONST` 打印、载体的打印翻译）；
另一个 agent 做第 9 步（coercion 引擎的 ESR 部分：先调整骨架并重测无钩子实例，再写出口与 I1a、学习、D15 与 D14，测 G1 coercion 打开、G2 (a)(c)(d)、G3、
I1a 与 D15 的数字）。
——(B) 并入干净代码（2026-11-04）：`subtyping.ML` 加 `provisional`、`decide_on`、`late_choices`、`end_decisions`，`local_decide` 带"是否最终 typing"的标志，
约束生成的 `carrier` 与 `decisions` 求解前的分支经 `provisional`；`check_decisions` 里原来那条推迟的例外（`refines`）再也触发不了，删去。代码与实验时逐字节
相同，只差注释。观察编辑 `observe-sub-ab-pred-late` 的锚点改到 `late_choices`（两种重跑的晚决定都记）；新变异 `d15_local_refines`（local pass 遍历中又做
细化的选择）。重跑（`step1/tests/coercion/cmp/cl4*`、`ob4*`、`m_*_v4*`）：coercion 打开 217 个任务与实验时（bB2）逐条 0 处不同——engine6 33,393 相同、
36 只差文本、1 判定；engine3 7,263 相同、753 文本、54 判定；失去的接受 15（`coercion_args`）+ 21（D15）+ 6（(B)：D15_Probe P14、C5，RR_AB C12、C14、C15、
C16）与带类型标注的 binder 一族，**多出的 0**；R1：只有参考里本就有的 CB_ElabS 6、PB_Learn 8 两处 DIFF，EXPL-ERR 0、超时 0。观察构建（ob4）：G2 (a) 51,989
SAME、0 DIFF；(c) PRED-AUDIT 44,330 SAME、AB-PRED 0 MISMATCH；(d) PROP-DUP 0。G3：27 个变异抓到 19——`d15_local_refines` 抓到（20 条，正是 (B) 改变的那
20 条）；未抓到 8：原来 7 个，加 `d15_no_node`。它抓不到是 (B) 的结果：求解前细化的选择一律不做，不细化的选择在类型以后的每个实例上都一样，所以
D15 那条"对象类型的参数还在待解的子类型约束里就先等"（节点上一处、求解前一处）不再能改变任何选择，至多改变报错里点名的类型或学习运行的先后；
`d15_no_presolve` 也由 119 处差别降到 2 处（VT_Probe7 D1 的两条文案）。这条等待是否去掉要用户定（设计 6.5.1 D15 写着它），先补数据再提：
同一个 agent 在草稿副本上把两处都去掉，跑全部 coercion 打开的对照与观察计数，逐条给出差别与文案、能删掉的代码行数、R2 是否仍按构造成立。
G4 的 agent 已得知 (B) 并入完毕，在最终的干净构建上重跑开关关闭同原版的各项。G6 引擎一侧也开了两个 agent：`step1/g6/coercion/`（coercion 引擎 227 行、
I1a 的去留数字、I1b 的 C2 行、无钩子实例）与 `step1/g6/standard/`（标准引擎、D14 两种配置、增长行）；若上面那条等待被去掉，`subtyping.ML` 再变一次，
引擎一侧的计时在最终代码上重跑。
——**G4（2026-11-04，最终的干净构建，`subtyping.ML` 输出 sha256 `23f13b4f…`；`step1/tests/scope/`）通过。** 每处既查开关的值（lemma 陈述里的探针在解析
与检查时各记一次），也用干净副本端到端读 `λp::point. p.xpos` 与 `λf::nat ⇒ point. (f 0).ypos`：该开处与原版读显式写法 aconv，该关处与原版（Pure 本身与原版
副本）的 term 或报错相同；到不了的探针算失败。181 PASS、0 FAIL（除下面 6 条）：import 继承与合并（`imports On Off` 开、`Off On` 关、`Plain On` 开、两层导入、
首个 import 是 `T_Off_On` 的关）；theory 层与嵌在 `context L` 里的 `context notes` 块（块内开、`end` 后关，`interpretation` 之后仍关）；`lemma notes`、`supply`、
`using` 的陈述按关读、证明里开；locale 里的 `declare` 到达之后的 `context foo`、导入它的 locale（同 theory 与导入 theory 里）、sublocale 目标（`sublocale` 之后）
及以它为父的 locale，theory 从 `interpretation` 那条命令起打开、导入者从头打开，locale 里 `declare [[dot_syntax = false]]` 经 interpretation 关掉 theory；
`context L2 begin … end` 里的 `declare` 同 locale；无名块里的 `declare` 块后与导入者都开。另 6 条失败都在"解析时开、检查时关"：干净副本的检查与 Pure 的检查
处处相同，失败的只是我计划 6.2 写的报错文本不准（已按实测改正 6.2 与 6.9）。开关关闭同原版的重跑（最终构建）：V_JAll、V_Fixed 开关关闭 0 处不同；Check_Off
8,962 条、69,744 条报告 0 处不同；开关关闭时打印 8,296 条 0 处不同；coercion 无钩子实例在 2026 语料上与原版 0 处不同。登记的作用范围早由 `tests/core` 的
R01–R12 覆盖（interpretation、sublocale、合并、attribute 收到 morphism、头部与 `rewrites` 里不可见、`context fixes` 块后丢弃、无名块到达 theory）。
——G6 标准引擎一侧（`step1/g6/standard/`）：脚手架与正确性冒烟通过（374 行、两种顺序，新代码的接受与否、打印出的 term、报错首行与参考列逐行相同）；
一个进程里装第六轮原型与干净构建两支，各列交错重复取最小值，倒序时连装载顺序也反过来。它查出两件事，我按授权这样定：
(1) D14 的行与 NEW-observer 比会因**第一步的替身**超出：替身把引擎登记在第 −1、0 级、与 Pure 的 `"standard"` 并存（Pure 不能按名字替换检查），学习运行里
于是每轮多一次原版推断；第二步第 0 级只有一个检查，没有这次推断。它另加了一支 `clean_s2`（同一份编译好的代码，替身在学习运行里把推断交给 Pure 的
`"standard"`、自己只记录，做的事与第二步相同；结果与被判那支相同，耗时约等于 NEW-observer）。**定：D14 的行按 `clean_s2` 判，被判那支的数字一并列出作
信息。** 比的配置是 NEW-observer（新代码的学习运行读法与它相同：每次第 0 级推断后扫一遍记录载体类型，不再推断一次）；`hrtl` 与它只共有晚决定冲突后的
重跑，另加 `NEWobs_late` 一列作信息。无点文本的行（r01–r05、s01–s04）除规则 (1) 外按规则 (2) 与原版比（它测了第二次原版读作波动范围）。
(2) **字段链的增长是真问题**：`(λt. t.left^k.val + k) tr`，k=256 时 coercion 打开新代码 494 ms、参考 102 ms（原版 101 ms），关闭时 23.7 对 5.4 ms，k=16 时
3.4 对 2.4 ms。剖析：coercion 打开时约 75% 的时间在拆字符串（`String.fields`、`space_explode`、`decode_payload`）。原因：载荷带着整个所写的标识符（O(k) 个
字符），热路径上每次都整段解码、`field_name` 每次 `Long_Name.explode`，所以遍历 k 个载体一次要 O(k²)。**改法（实现细节，按授权定，设计不变）**：载荷
记录加 `field`（构造时算一次）；编码时变长的 `name` 放最后、不转义，其余值照旧转义，解码只读前面的短段、`name` 取余下部分。交给一个 agent 先在草稿
副本 `step1/fix_payload/` 上做好并测全部测试集与增长率，等 D15 那条等待的去留定了，两处改动一起并进干净代码、重新派生、统一重跑，再做 G6。6.3.3 与
6.2 里载荷文本的例子到时按新格式改。为此已停掉 cslh19 上排队等空窗的两个计时脚本（局部变量优先一侧与标准引擎一侧，它们测的会是旧代码），解析
与 coercion 两侧的 agent 也已告知先不计时。另：cslh19 上占着计时空窗的构建（`~/light_mutants` 的变异测试，一个接一个、约 6 分钟一个）还剩约 35 个。
——G6 解析一侧（`step1/g6/parse/`）：脚手架与冒烟通过、没有计时（12:15–13:15 UTC 构建一个接一个，没有空窗）。三组：第一次解析（原版 A、对照 B、干净 F、
干净加两条 `_dot_field` 产生式 Fd，Fd/A 按规则 (2)，四份的 token 与树在 8,963 条上同 Pure）；解析原型的 32 行（规则 (2) 21 行、第二次解析与冲突区按规则 (1)
10 行）；打印、`check_terms`（开关打开，规则 (3) 按 (2) 判；另加开关关闭的两行）、`CONST` 打印与字段标记（REPORT 行，交用户）。最终构建派生后一条命令
`go.sh` 重新取件、冒烟、排队计时。**规则 (2) 的波动范围统一定为**：半宽 w 取两次运行里"对照/原版"中位数偏离 1 的量与该中位数 95% 置信区间半宽两者的
较大者；任一次 新/原版 > 1 + w 为不通过（按授权定；局部变量优先与标准引擎两侧的分析到重跑时改用同一定义）。它看到的一个疑点：冒烟（负载 13 以上，
不算数）里字段标记每段约 60–100 µs，远高于计划里估的 2.1–2.6 µs，已交给做载荷修改的 agent 一并查原因（`segment_position` 每段都整段展开所写文本等）。
——载荷修改（草稿 `step1/fix_payload/payload.diff`，干净代码未动）：载荷记录加 `field`，`pos` 改为字段那一段自己的位置（去掉 `segment_position`；可见的位置
与全部报错文本不变），新函数 `carriers` 是从所写 token 取字段与位置的唯一一处（`accesses`、`paren_accesses` 都经它），编码为 `dot_field index=2 field=xpos
line=1 offset=18 end_offset=22 id=1 name=s.start.xpos`（`name` 放最后、不转义），解码只读 ` name=` 之前的短段。`edits.py` 的全部编辑仍恰好匹配一处。测试集
（核心 14 个 theory、解析 15 个、标准引擎 99+98 个任务与 G2 (b)、G4、coercion 全部 217 个任务）结果与修改前相同，只有直接打印原始载荷的文本按新格式变
（G4 `Scope_Switch`、V_Sanity T6/T8、Parse_Unit F1/F2、Core_Codec、LB_Fuzz 两条），另有几个测试里的载荷字面量要加 `field`。增长（有负载，只看比值）：
k=256 时 coercion 打开新代码/参考 1.18（旧 4.59），关闭 1.11（旧 4.30），增长率与参考相同；剩下的差距几乎全是每次解码的固定开销，正在压（更省的解码，
或热路径上按 key 查引擎已有的每批次 access 表，取更简洁的）。另查：LB_Fuzz 两例的 coercion 报错文案里露出原始载体（修改前就有），查原因与第二步是否
同样出现。字段标记的开销（有负载）：约 90–95% 在 `Dot_Field.head_constant` 里原版的 `Proof_Context.contract_abbrevs`（6.6 的折回缩写）；登记为常量的每段
1.7–6 µs，与原估计相符，登记为 λ-term（如 `sym_diff`）的每段 100–310 µs（缩写网在每个 λ 节点取出全部 183 个缩写逐个匹配）。正式数字由 G6 测出后连同
选项报用户（规则 (3)：没有已批数字）：接受；同一批次内按所选 term 记住折回结果（不改设计，只帮重复的字段）；或改设计为登记时记下所写常量、不在当前
上下文折回（会改变 6.6 里 interpretation 之后、最新缩写胜出的行为）。另：它的一个脚本误导入 `tests/parse/mutate_warn.py`，重写了 `tests/parse/mutants/`
（内容只差各自较新的 `compare.tsv`），cslh19 上的副本未动。
——载荷修改第二轮：剩下的固定开销来自解码次数——coercion 打开时 k=256 每读一次解码 34,952 次，其中 33,153 次在 `subtyping.ML` 的 `build`（`exact_object`
为每个字段重建它对象的树，链上每个载体被访问约 k/2 次；参考也有这个遍历，只是每次访问便宜）。更省的解码器只快 1.6–2.5 倍、仍差约 9%，所以改为：
新函数 `Dot_Field.batch_access accs` 与 `dest_access` 一样，但载荷按载体的 key 从引擎每批次已建的 access 表里取，不再解码（key、类型、节点、对象仍从
term 本身读；查不到才解码）；两个引擎在 `collect_accesses` 之后绑定 `val dest_access = Dot_Field.batch_access accs`（`subtyping.ML` 只改 6 行），`explicit`
只读 key。每读一次每个载体只解码两次（进检查阶段一次、建表一次）。增长（有负载、同进程）：新/参考 coercion 打开 0.98–1.05，关闭 0.98–1.03，增长率同
参考；剖析里载荷只占 1%。测试集结果同第一轮。**露出原始载体的原因**：原版 `err_bound` 打印约束时，打印器的 eta 缩约把 `λv2. dot_access p v2` 变成
没有对象的 `dot_access p`，载体的 print translation 只认带对象的形式，于是按普通常量打印；第二步同样会出现。修法（只改打印，按 6.3.3 "报错里载体按
`t.xpos` 显示"，我定）：`access_tr'` 遇到没有对象的载体时还原成 `λx. x.f`（约束变量名取所写的对象，括号形式用 `x`）。两处改动并进干净代码、重新派生、
全部重跑（coercion 一侧记为 cl5、ob5，含 27 个变异）由同一个 agent 做；D15 那条等待按现状（保留）并，若用户定去掉，只再改 `subtyping.ML` 并重跑
coercion 一侧。6.3.3 与 6.2 里载荷文本的例子在并入后按新格式改。
——两处修改并入干净代码（2026-11-04；`dot_field.ML`、`type_infer_context.ML`、`subtyping.ML` 三个文件，构建输出 sha256 `dde68afe…`、`8f9d3551…`、
`2611a628…`；D15 那条等待按现状保留），重新派生、全部重跑（新基线 r5：`tests/standard/cmp/std5.*`、`tests/coercion/cmp/cl5.*`、`ob5.obs.txt`、`m_*_v5.obs.txt`）：
核心 14 个 theory 0 FAIL、0 MISMATCH；解析 15 个 297 PASS / 4 FAIL（4 个早就有）、警告 40/19/3；G4 203 PASS / 6 FAIL（已知的 6 条）；标准引擎 99 + 98 个任务与
上次逐条 0 处不同、G2 (b) 8,172 SAME；coercion 217 个任务判定与 term 同 cl4，只差打印修改要改的 LB_Fuzz 两例文案（现为 `(let v2 = G k in v2.inv)`、
`(λv2. v2.dd)`）及其计数行；观察构建 G2 (a)(c)(d) 各数同 ob4。G3：coercion 27 个抓到同样的 19 个、每个的差别数与上次相同；警告变异 8/8；核心变异 24/24——
其中 `sort_by_stored_full_name` 的锚点自 11-04 03:54 起已对不上（那次把折回缩写提成 `head_constant`），此前一直没有真正装上，我按现在的代码换了锚点
（`tests/core/mutate.py`），单独重跑，T18 失败 1 条，抓到。测试源码为新的载荷记录作了最小的改动（`Core_Codec`、`Core_Select`、`Parse_Unit`、两份
`Restart_Base` 含打印的 eta 情形、两份 `Debug_Loop`）。**过程中的违规**：并入的 agent 两次在 cslh19 上同时跑到 4 个 Isabelle 进程（17:06–17:14、17:44 起约 7 分钟，
上限 2），原因是一个排队步骤等的日志行早被前一次失败的运行写过、于是立刻启动；其间还在变异任务运行中换掉了共享树里的变异构建，污染了 4 个变异
（i1a_no_cargs、late_no_result、no_cycle、no_d14）与 fuzz 任务——已移到 `coercion/out/r5-corrupt/`、在单独重跑的结果上计分。G6：四组都已通知在最终构建上
重新取件、冒烟、排队计时（解析 `go.sh`、局部变量优先一侧 `run_all.sh`、标准引擎 `rerun.sh`、coercion `start.sh r1`），规则 (2) 的波动范围统一用上面的定义；
标准引擎一侧 D14 的行按 `clean_s2` 判、无点行另按规则 (2) 判。若用户定去掉 D15 那条等待，coercion 一侧与标准引擎里 coercion 打开的行要重测。
——G6 四组在最终构建上冒烟都通过、18:12–18:15 UTC 起排队等空窗（`light_mutants` 的构建仍在一个接一个）：解析三组（第一次解析 8,963 条四份同 Pure；
打印 8,296 条、`check_terms` 结果与报告、7 个标记用例都同）；局部变量优先一侧（语料 10,065 条开关关闭 0 处不同，开关打开新代码同原版、原型差 G1 (i) 那 1 处）；
标准引擎一侧（187 行与参考 0 处不同；字段链 k=256 单次预览已跟上参考：关闭 5.4 对 5.3 ms、打开 110 对 100 ms）；coercion 一侧（227 行判定与 term 同参考、
接受处同原版读 E(C)、I1a 118 行复算全 SAME、无钩子实例 0 处不同）。三组的脚手架都不必为新的载荷格式改动。标准引擎一侧指出：它的无点行里"新读法"
与"原版读法"是同一个计算（同一份干净代码、同一个上下文读同一段无点文本），所以那里按规则 (2) 判只量到噪声；无点文本上 dot 代码相对原版的开销由
其他组的部件行（原版副本对功能副本）把关——**我收回对标准引擎一侧"无点行另按规则 (2) 判"的要求，那一项只作信息。** coercion 与标准引擎两组的完成由我
在后台每 9 分钟查一次，另两组各自的 agent 在看。
——**G6 解析一侧的结果（最终构建，11-04 18:38–22:08 UTC，六次运行都有效；`step1/g6/parse/results/ANALYSIS.txt`）。** 41 行里 37 行通过：第一次解析
（Fd/原版 0.995 / 0.992，范围 ±0.009）、tokenize、`make_gram`；解析原型的规则 (2) 行 21 行中 19 行；规则 (1) 的 10 行（第二次解析 0.996–1.010，冲突区
1.001–1.005）；开关关闭的打印与 `check_terms`。**不通过**：`ck.on`（开关打开、无点语料上带报告的 `check_terms`，1.007 / 1.011，范围 ±0.006，每 term 约
1.7–2.6 µs；开关打开时多跑的是 `standard_check` 包装、第 1 级 `dot_check`、遍历每个 term 的 `field_reports`、`prepare_positions` 里的载荷测试，6.8 说这应在
噪声内）；`ps.wide.plain.n16`（只解析、宽文法、无点，1.006 对范围 ±0.005，只在倒序那次、那次对照副本也是 1.005，相邻各行通过，像是噪声，照规则列为
不通过）。**勉强通过**：`pr.on`（开关打开的打印 1.031 / 1.028，对照 1.003，只因倒序那次有三轮大波动把范围撑到 ±0.047；成本在 `CONST` 判断）。**更快**：
`lex.plain.n16/64`（只 tokenize，0.99；干净的 tokenize 与原版逐字相同、对照副本也更快，原因未明，记为待查）。**交用户的 REPORT 行**：`pr.const`（真要打印
`CONST` 的 term 1.07–1.08 倍、每 term 约 0.7 µs）；字段标记每段约 53 µs（`mk.dot`；`field_reports` 单独约 38 µs，远高于原估的 2.1–2.6 µs）。
处理：开关打开时无点文本上的这两处开销（`ck.on`、`pr.on`）属实现可压的部分，交一个 agent 在草稿 `step1/fix_dotfree/` 里查清各机制的份额并压到噪声内
（行为不变：term、报告、文案、打印都不变；最便宜的一次测试让 dot 机制跳过无点的批次，`CONST` 判断对不带点的名字不花钱），同时拆开字段标记的成本；
并入后受影响的计时行重测。其余三组照常跑完。
——**G6 coercion 引擎一侧的结果（r1，11-04 18:12–22:52 UTC；`step1/g6/coercion/runs/r1/analysis.txt`；计时文件全同最终 MANIFEST，与构建重叠的 5 行已重测）。**
227 行判定与 term 全同参考；规则 (1)：127 通过、95 更快、5 不通过。**不通过**：A#17–19（`(n + k, let a1 = k.di in … in ak + k)`，local pass 干净失败、global
algorithm 学一串相依字段、再由原版推断 E(C)；新/参考 1.10/1.07、1.09/1.08、1.06/1.06，每节约多 0.05 ms；新/原版至多 1.09，仍在已批的常见写法倍数内；
I1b 测试开关在这几行几乎不起作用，所以不是去掉 I1b 所致；同形的 λ 链、自由变量链与 `.dn` 的 let 链都通过；原因未明，交给做无点开销修改的 agent 一并
剖析——学习过程反复走检查阶段，可能是同一来源）；A#147、148（被拒 term 里的学习链，只在正序那次超、那次两份原版副本之比也偏 0.93、0.98，像噪声）。
**更快的 95 行**：新/原版平均 1.28，参考 1.53（参考在 2025-2 上是 1.46）；约 0.07 来自 2026 参考的测试层（D-open 包装），其余约 0.18 是新代码在这些形状上
比 s3c 省（具体哪部分省未剖析）。**超出已批倍数的 12 行**（常见 4 行 1.17–1.36、救回 6 行 3.01–3.46、报错 2 行 1.71–1.80）：其中 11 行参考也超，A#138 两方都在
边上（3.03 对 2.95）；指数级嵌套无超出（A#44 19.4–19.9，参考 21.3–22.1）。R3 行：A#69 按规则 (2) 通过；A#70、71 每个限定名常量 2.2–5.3 µs，超 +1.1 µs，
但同文本两套设置相差约 4 µs/个（噪声约 ±2 µs），且用户空间里这一列含测试层的替身（第六轮的长名字解析翻译），以局部变量优先一侧的限定名行为准。
无钩子实例：规则 (2) 通过（1.0015 / 1.0044，w = 0.0082）。**I1a**（§1 第 22 条，规则事先批准）：去掉后常见写法在节点上决定的 98 行中 25 行超过 1.2
（最高 2.12：原版本身指数级、在节点上决定的嵌套；左脊带前缀嵌套 1.63–1.90），这 98 行总时间多 75–77%；晚决定的 4 行 1.14–1.19。**按规则保留 I1a，
交付的测试要加 R1 回归**（放哪个 session 属 (e)）。I1b：C2 的 9 行去掉 I1b 的代价至多约 1%（A#54、55 不走它），不需要提"发布受限的捷径"。
——**G6 局部变量优先、设计 D、警告、登记表一侧的结果（11-04 18:23–11-05 00:22 UTC，14 次运行都有效；`step1/g6/localwarn/results/`）。** 局部变量优先
全部通过（限定名常量每个 −1.7 到 +0.07 µs，已批 +1.1；拆分的标识符每个 +0.07 / +0.16 µs，已批 +0.4；`Config.get` 39–41 ns，已批 40）；警告四行全通过（W3
的文本在 6.6 下仍发警告，不用改）。设计 D 的行：D.T3、T5、T6、J.Q1–Q3 通过；**不通过** D.T1（同一语料、开关关与开，倒序那次 1.0112 对范围 1.0107，
用同一语料的 V.T1、D.T5c 关、D2.U1 都通过，像压在范围边上）、D.T2（+1.1 µs 规则，分母只有 228 个长标识符，按比值 1.0023 / 1.0090 在范围内）、D.T4
（开关打开读显式写法 1.0168 / 1.0127，范围 ±1.23%）、D.T5c 开（1.0047 / 1.0127，范围 ±0.84%，原型同样上升）——后两条可能与解析一侧 `ck.on` 同源，修完重测。
登记表：**插入不通过**，每条 0.90 / 0.94 µs（已批 0.56，同进程替身 0.32 / 0.56）——交给做无点开销修改的同一个 agent（同在 `dot_field.ML`），行为不变地压
（怀疑每条两次成员测试与 aconv 比较）；**合并** 362–370 µs 超已批 340，但同进程替身同样 364–369 µs，超出来自本机与 Isabelle2026，不是真实结构——作信息报
用户。没有"更快"的行。限定名常量的行在这里都通过，所以 coercion 一侧 A#70、71 的超出是测试层替身所致。
——**G6 标准引擎一侧的结果（11-04 18:17–11-05 00:23 UTC；与构建重叠的两次作废重跑；406 行新代码的判定、打印出的 term、报错首行全同参考）。** 规则 (1)：
St0 11 行 0 不通过；C_Timing 关闭对 hrtl 3 不通过；C_Timing 两种模式对 NEW-observer 12 不通过；VT 2 不通过。指数级嵌套（w01–w15，打开）新/原版 1.03–1.19，
远在约 20 倍内。字段链 k=16–256 新/参考 打开 0.999–1.051、关闭 0.958–1.036（k=256：95.2 对 94.4 ms、5.09 对 4.91 ms），原来退化的 v15、v16 现在通过。D14 行按
`clean_s2` 判：接受的 0.91–1.06，替身那支 1.05–1.50 作信息（与 hrtl 相当，印证替身多一次推断）。**不通过的 17 行**都在 1.05–1.12、每读 10–50 µs：只有 j01–j03
（自由变量对象的字段被拒、D14 守卫不开，+15–30 µs，约比第六轮无学习的基线多 15%）像真的开销——疑为 `learn` 在守卫判断前就对整批做 `Type_Infer.finish` 与
`Dot_Field.explicit`，或排序候选时每个都折回缩写求头部常量——交给做无点开销修改的同一个 agent；其余都只在倒序那次超出、至多 1%，落在它测出的列序效应
里（紧跟同一文本的读更快：两份相同的原版读之比 0.83–1.19），**我定：重测时每次重复轮换列序（或每列前插一次无关文本的读），消除列序效应**。更快的行
各有原因：hrtl 的 reinfer 读法每轮多一次原版推断（D14 行）；第六轮在"没有这个字段"的报错路径上打印很贵（j16–j18）；第六轮的 `check_terms` 包装与第 −100
级引擎（无点行、coercion 引擎决定的接受行）。——列序效应的处理：标准引擎一侧改为每次计时的读之前先做一次不计时的"中性读"（原版
`Syntax.read_term` 读一段无关文本），使每列前面都是同一个读；轮换列序在它那里不行（循环轮换保留相邻关系，每读前做 GC 又太贵）。核对：两份相同原版读之比由
正序 0.943 / 倒序 1.059（最偏 0.86、1.19）变为 0.992 / 1.007（最偏 0.95、1.05）；代价是作业时间约长 40%。冒烟 203 行与参考 0 处不同。
——**无点开销等四处的修改（草稿 `step1/fix_dotfree/dotfree.diff`，三个文件）。** 行为不变的部分我接受，交一个新 agent 并入、重新派生、全部重跑（新基线 r6）：
`field_reports` 在没有记下任何选择时直接返回（原先遍历每个 term），并在一次调用内按所选 term 记住 `head_constant`（缓存在调用内新建，同原版 `markup_syntax_cache`
的写法，G5 不受影响）；`Dot_Field.declaration` 一次读写登记数据（一次声明 1,400 条时登记部分每条由 0.54 降到 0.14 µs，已批 0.56；单条声明即 attribute 的路径
不变，约 0.61 µs，底是 `Item_Net.update` 与它内部再测一次成员，`Item_Net.cons` 不导出）；标准引擎的 `learn` 先测学习运行的守卫、再 `Type_Infer.finish`
（`Dot_Field.guard` 改取一个类型函数；j01–j03 coercion 关闭时降到与 hrtl 相当，打开时仍差约 40 µs，其中约 21 µs 是 coercion 引擎在守卫前建学习输入，那里
插入的 coercion 参与守卫判断，没有精确的提前测试）。各机制的份额（旧代码、每批）：`standard_check` 的载体遍历 0.10–0.39 µs、第 1 级 `dot_check` 0.11–0.42、
`field_reports` 0.20–0.45、`prepare_positions` 的载荷测试 0、`Config.get` 0.03；改后合计 0.29–0.89 µs，即每 term 0.12–0.37%，剩下的就是设计里那两次载体遍历；
共用一次测试不省（0.203 对 0.214 µs），完全不遍历要把"有没有载体"的标志放回（第五轮评审 3.1 去掉的），交用户。`ck.on` 在它加锁的运行里仍判不通过，
但同一次运行里走完全相同路径的 `ck.off` 也判不通过——这个测法里每份副本各自编译类型推断代码，本身就差 ±0.5–1%，范围定得比这窄。字段标记每段约
39 µs，其中 36 µs 在 `contract_abbrevs`（`rewrite_term_yoyo`），记住结果只帮重复的字段。A#17–19：不是检查阶段的开销（这组根本不装 `syntax_phases.ML`），
是引擎的工作——local pass、一次学习的约束生成（其中 D15 预测表 `compute_predictions` 每轮重建整批、k−1 轮，O(k²)，k=16 时约占差距的 40%）、出口的最后检查；
其余就是 6.5.1 设计的路径（学习、再由原版推断 E(C)）；改成增量要动引擎算法，未做，交用户。**没并入、交用户的一处**：打印的 `CONST` 判断只对带点的
名字做（`Long_Name.is_qualified`）——打印成本由 1.022 降到 1.0055（同对照），但偏离 6.6 原文"凡是常量准备打印的名字，第一段与变量冲突就打印 `CONST`"：
在 `names_short`（或 `names_long` 下根名字空间的常量）时，不带点的名字与变量同名，旧代码打印 `λmap. map = CONST map`，新代码同原版打印 `λmap. map = map`
（默认设置下原版本来就把与变量同名的常量打印成更长的名字，不会出现）。
——上述修改并入（11-05 01:29–03:04 UTC；构建 `clean/MANIFEST` `bfcaecaf…`，输出 `syntax_phases.ML` `3cc1b236…`、`dot_field.ML` `e4869b8b…`、`type_infer_context.ML`
`ecb450a5…`；打印的 `CONST` 收窄那一处没并），全部重跑记为 r6：所有判定、term、文案、报告、`.results`、退出码、G2 与 G3 各数都与 r5 逐字节相同，唯一不同的
是打印出的签名行 `val guard: (typ -> typ) -> term list -> bool`。G3：coercion 19/27（每个差别数同 v5）、核心 24/24、警告 8/8；核心变异 `defined_ignores_hiding`
的锚点因 `lookup` 改为 `lookup_data` 换了（变异内容不变，我接受）。并入过程中至多 2 个进程（采样核对）。四组 G6 已通知在 r6 构建上重测（coercion 记为 r2）。
——**G6 解析一侧第二轮（r6 构建，11-05 03:14–08:02 UTC，六次都有效；`step1/g6/parse/results/ANALYSIS.run2.txt`）。** 41 行里 33 行通过。上一轮擦边的
`ps.wide.plain.n16` 这次 1.001 / 0.991 通过（解析代码逐字未变，上次是两次运行之间的波动）。`ck.on` 1.009 / 1.002（范围 ±0.008）仍不通过，`ck.off` 1.006 / 1.000
（范围 ±0.004，上一轮通过）也不通过——两行的差别都在这个测法分得开的程度以下（做修改的 agent 剖析出 dot 机制的真实份额是每 term 0.12–0.37%）。`pr.on` 1.019 /
1.015 通过（范围 ±0.071，靠几轮大波动撑宽；打印代码没变，由 3% 到 1.7% 是波动）。`pr.const` 1.056 / 1.063、每 term 约 0.6–0.7 µs；字段标记 `mk.dot` 每段约 53 µs、
`mk.fr` 约 39 µs，与上一轮相同（这 7 例每例一两个字段、各不相同，提前返回与记住结果都用不上）——都是 REPORT。**新的真问题**：`make_gram`（HOL 文法）
Fd/原版 1.037 / 1.035 对范围 ±0.032 不通过，不带两条 `_dot_field` 产生式的干净版本 F 在四次运行里都是 1.02–1.04，即开关关闭也多 2–4%、每次建 HOL 文法约
0.3–0.6 ms——`extend_gram` 在建完产生式后另用 `List.partition` 扫一遍全部新产生式、挑出带字段点终结符的（6.3.2），原版没有这一遍；违反 R3，交一个 agent
在草稿 `step1/fix_gram/` 里改为建产生式时顺手分拣等更省的写法（文法与解析结果不变），实测后并入，并重测解析一侧的第一组与局部变量优先一侧。
`lex.*` 两行更快（tokenize 与原版逐字相同、对照副本也更快，原因未明）。
——**用户 2026-11-05：`make_gram` 开关关闭多 2–4%（每次建 HOL 文法约 0.3–0.6 ms）"完全可以接受"，不修**；修它的 agent 已停，草稿 `step1/fix_gram/`
未并入。用户同时指出：这类幅度很小的偏差，我不该自己一路派 agent 去修（"钻牛角尖"，还可能把代码改得不优雅），拿不准时应先问一声。此后计时里
幅度小的不通过行一律先列给用户，不再自行修。（此项是 R3"开关关闭时开销同原版"的一处例外，写进 6.8。）
——**代码评审（2026-11-09，CLAUDE.md 的流程：5 个评审、每条意见一个辩护、judge；42 个 agent；全文 `step1/review1/`）。** 36 条意见，judge 裁定：修完"实现者可定"
一组并重跑（含 G6）、两处大的重构再评审一次后，可以进第二步。要用户定 3 条：lexer-parser#1 规则部分（只把左递归的字段点产生式挡在 lookahead 表外）、
subtyping-esr#7（把原版 `update_coerce_arg` 拆出 `coerce_arg`，D6 只留取脊的 3 行）、dot-field#7（简写 `[[dot_field c]]` 的字段名取自读出的常量，而非所写文本）。
实现者可定 25 项（其中两处真缺陷：`function_of` 抛出的 `COERCION_GEN_ERROR` 在 ESR 的 local pass 里漏接；被挡在表外的产生式的非终结符没有声明，`print_syntax`
与预测时会 `Graph.UNDEF`；另要实测第二次解析在 HOL 文法上的开销）；剔除 11 条。用户的三条决定见 §1 第 26 条。实施分三批：
`step1/fix_rev1a/`（只在 `subtyping.ML` 里的各项，含 D6 的 B 与删掉走不到的子句）与 `step1/fix_rev1b/`（词法与解析器，含规则收窄、声明非终结符、
第二次解析的实测——只报数、不改）并行在草稿里做；两者交回后由第三个 agent 并入，再做跨文件的各项（共用的等待索引、`selection_check`、dot-field 各项、
phases 各项、attribute 只收长标识符或 `f = c` 及其报错），全部重跑（r8）；之后两处大重构再评审一次；MERGE.md 与本文需改的地方由我手改。
——`fix_rev1b/` 交回（11-09）：规则收窄后 HOL 文法里仍只有 Pure 的两条 `_dot_field` 被挡在表外、表里没有字段点产生式；`Graph.UNDEF` 在旧代码上复现（`print_syntax`
与预测），新代码上消失；`(x).f !` 现在读出一棵树；解析、警告变异、作用范围各测试集同 r7（只差改名后打印的签名一行）；第一次解析在 2026 语料上同 Pure。
**第二次解析的实测（只解析器一层，HOL 文法，加锁计时）：比第一次解析慢 10–16 倍**（`(p).x + a1`：352 对 23 µs；字段访问在最后时 1.6 倍），随长度线性增长；
84% 的时间在过滤 `prefer_fewer_field_accesses`（同一位置的状态两两比较，HOL 文法每个状态集平均 74–92 个、多时约 230 个）。原型那个 1.7–2.1 倍是在 25 条产生式
的小文法上测的；G6 只拿新代码比解析原型（同一套过滤、一样慢），没比第一次解析——这是我设计 G6 时的漏洞。**用户：这么慢不可接受**；评审给的改法（按 `info`
分组一遍扫完，保留的状态与顺序与现在相同）是否安全，交一个 Opus agent 核实（形式论证、在所有调用上并排比对、测速），草稿 `step1/fix_secondparse/`。
——核实结果：**它写的版本安全**——对任何输入列表返回完全相同的列表（元素、顺序、重复都同），证明不依赖解析器的任何性质；评审字面的写法（"只留大小最小的"）
有反例（同组两个都没读字段访问、大小不同的状态会被丢一个），只因解析器的性质才碍不着，它的版本保留"读了字段访问"这一条件而不依赖那个性质。并排比对
3,819,018 次过滤调用（解析测试、插点的 HOL 语料、4 万条随机嵌套与歧义写法），0 处不同；四个故意写错的版本都被比对抓到；解析测试集同前。**收益约 2 倍**：
第二次解析 ÷ 第一次解析由 10.7–16.2 降到 5.6–7.3（字段访问在最后的 1.6 → 1.35）；过滤仍占 59–71%（现在花在建表上）；过滤之外是第一次解析的 1.7–3.2 倍
（第二次解析实例的固定开销约 1.25 倍、`(p).x` 比 `p_x` 多 4 个 token、GC）。它列的继续优化（未做）：先按来源下标分组的精确预检、每个非终结符预先算好
被挡在表外的产生式、在产生状态时去重。
——用户 11-10 追问两次解析的方向，提出另一做法（**待定**）：既然改的是 Isabelle 源码，开关打开时在词法阶段就把"紧贴 `)`、又紧贴标识符的点"标成 `field_dot`，
只解析一次，`field_dot` 只当字段访问、不兼当分隔符；文本里没有这种点时走原版解析。好处：删掉第二次解析的回退、过滤、权重与兼当分隔符那一支；括号形式
的开销估计约为原版读显式写法的 1.0–1.3 倍（未实测）。代价：开关打开时 `).标识符` 不留空格而那个点本是原版分隔符的写法（如 `λ(x, y).x`、`{(a, b).P a b}`）
改读字段访问——多半报错，少数（恰有同名字段登记）会静默改义；这是对 R3 的一处放宽。用户让 Opus agent 先数 Isabelle 库（另附 AFP）里这种写法有多少
（`step1/count_paren_dot/`）。另：我把这种 token 随口叫"字段点"，是造词，以后只用 `field_dot`。
——coercion 引擎那一批（`fix_rev1a`）的全套测试 11-09 06:49 UTC 已跑完（日志 "all done"、至多 2 个进程），我的监视因检查命令匹配到自身而一直误报"在跑"；
对照待 cslh19 恢复（11-09 16:54 UTC 起 "No route to host"）。——11-10 cslh19 恢复，对照完（`fix_rev1a/compare.out.txt`）：coercion 217 个任务、观察构建
217 个、标准引擎 99 + 98 个，与 r7 逐条全同；G2 (a)(c)(d) 与 G2 (b) 各数全同；新探针 4 例通过（旧代码上 4 例失败）；22 个变异的差别数（含补跑的 fuzz 任务）
全同 v7，抓到 17 个。——同日按 §1 第 27 条开原型 `step1/proto_onepass/`（一次解析、`field_dot` 只当字段访问、解析失败时附说明），在 cslh19 上实测性能。
——`fix_rev1a/` 交回（11-09）：`subtyping.ML` 2,603 → 2,628 行（预测提到顶层 `dot_predictions`，`rev1a.diff` +587 −582 多是挪动）；新探针 `Clash_Gen_Probe.thy`
4 例在旧代码上都因 `COERCION_GEN_ERROR` 漏出而失败、新代码上都得原版的报错；无钩子实例同原版 0 处不同；全套对照在 cslh19 上跑（我监视，跑完用它的
`compare_rev1a.sh cl ob std obs mut`，再对没抓到的变异跑 fuzz）。**并入后要手改的文档**（它列的）：MERGE.md:83–84（D6 不再"原版不动"、Base 多了 `observe_hooks`/
`learning_hooks`）；本文 6.5 "原版 `update_coerce_arg` 不改"一句与"原版代码 + 钩子"清单加 `coerce_arg`；6.5 "从不返回 term"现由签名保证；6.5.1"I1a 两个出口"
现为 `after_local` 里一处调用；"一个拒绝判断（`ERROR`、`LAST_CHECK`）"现只剩 `ERROR`；6.12 G3 里单一拒绝判断的变异已撤；§6.11 末"留到评审后删掉"已做。
——**按 §1 第 25 条改完（2026-11-09，r7；`step1/r7/`）。** `subtyping.ML` 2,703 → 2,603 行（+43 −143）；`dot_field.ML` 1,193 → 1,190；`type_infer_context.ML` 回到 r6 之前的
逐字节版本；`syntax_phases.ML` 只改 `CONST` 那一处。全部重跑：coercion 一侧正好失去 286 个接受，与 4.8 数据里节点修补决定的那张清单逐条相同（都是 C4 一族，
现在报最后检查的文案）；弱合一宽容保留，所以它单独决定的 42 个照旧接受；没有多出的接受、接受的 term 与已被拒输入的文案都不变，普通与边缘输入 0 处变化；
G2 各数同 r6；标准引擎、解析、作用范围各测试集同 r6（打印测试新增 C7–C9：`names_short`、`names_long` 下不带点的名字照原版打印）。G3：coercion 23 个变异抓到 17 个
（去掉的 4 个机制的变异随之删去）；`rejected_no_last_check` 变成 0——节点修补删掉后 `rejected (LAST_CHECK _) = true` 这一子句已走不到，留到评审后那一轮删掉（fix_rev1a 已删，r8 已并）。
另两点我按授权定：`Data.map` 让一个什么都没改的声明也写一次数据，`tests/core` 一个输出里 theory 的阶段编号因此变了一位（结果文件全同），接受；成环规则删掉后，
它在 LR_Cycle、LR_Fuzz 上的工作改由 D14 学习运行做（结果不变、多做的学习运行未计时，不修）。
——**放宽提议 4.8 的数据（用户 11-05 要求，Opus agent；`step1/relax48/`，`results/decisive_inputs.tsv` 列出每个起决定作用的输入）。** 217 个任务分别关掉
每个机制、五个全关、以及真把代码删掉各跑一遍（删掉的构建与全关构建在 42,134 条记录上相同）。**普通写法（68 个输入）与"边缘"的（308 个）上五个机制一次
都没运行**，所以 4.8 在这些输入上按构造不改变任何东西。刁难性测试集上，4.8 整体：失去 328 个接受、多出 0、接受的 term 0 处变化、已被拒的输入 247 条文案变化。
分机制：弱合一宽容运行在 966 个输入上，决定 134 个接受、247 条文案（全部是测试用的"变成函数的 coercion" `unwrap :: 'a wrap ⇒ (nat ⇒ 'a)` 一类；HOL-Analysis/Probability
里 `measure`、`emeasure`、`apply_bcontfun`、`Fin_Map.proj` 也声明了这类 coercion，真文本可能碰到，但要同时有字段需要学习）；构造子宽容、运算符宽容从未运行；
成环规则运行在 364 个输入上、从不改变结果；节点修补运行在 355 个上、决定 286 个接受（全是 C4 一族：一个未标类型的变量被一个合取式定为 `nat`、又被传给
`int` 谓词，字段 `dd` 在 nat 与 int 上都有登记）。"接受与否经节点修补依赖不相干的文本"在专测它的 LR_Comp（175 例、84 对拼接）上一例也没有（有无修补都是
0），所以这条好处只是从构造上的论证。关掉后的文案：修补关时是现有的最后检查文案 `Field "dd": chose dbl_i … but the object's final type nat selects dbl_n …`；
弱合一关时是原版文案，其中 40 条以空行开头、不提字段。代码：4.8 删 `subtyping.ML` 净 125 行（弱合一 18、构造子 8、运算符 18、宽容共用 10、成环 7、修补 64），
其他文件无专用行；"请给对象写类型"的新文案与测试约 40–75 行（估计）。计时：普通行都不动（中位 1.000，最多 1.040）；结果改变的 9 行因提前拒绝快 2–5 倍。
——**G6 局部变量优先等一侧第二轮（r6 构建，11-05 03:11–10:05 UTC，14 次有效，与构建重叠的一次自动作废重跑）。** 上一轮不通过的 D.T1 关、D.T4、D.T5c
这次通过。仍不通过 6 行，按规则 (4) 列给用户、不修：V.T1 开（1.0173 / 1.0155，范围 ±1.04%，新出现；不是第二次解析所致，原因未明）；D.T1 开（倒序 1.0079，
范围 ±0.64%）；D.T2（+1.1 µs 规则，分母只 228 个长标识符，按比值 1.004 在范围内，原型与对照副本同样有 +10 µs 级的数）；W2（+0.77 / +1.20 µs 每标识符，
上一轮 −0.9，对照副本本身倒序也 +0.48）；R1 登记表插入 0.82 µs/条（已批 0.56，同进程替身 0.567；它测的一次声明 1,400 条与修改时 agent 测的 0.14 µs 差得远，两边
负载不同，未对齐）；R2 合并 349 / 364 µs（已批 340，替身同样 363–364）。没有"更快"的行。
——**G6 标准引擎一侧第二轮（r6 构建、中性读，11-05 03:10–09:46 UTC；与构建重叠一次已重跑；406 行判定、term、报错首行全同参考）。** 中性读之后两份相同原版读
之比 0.95–1.04（上次 0.83–1.19）。规则 (1) 只剩 2 行不通过：C on j02 `(λt. t.xpos + t.ypos) z`（1.041 / 1.050，约 +20 µs；coercion 引擎的 `learn_d14` 同样在守卫前建学习
输入，那处没改）与 C on a12 `(λv1. v1.ypos) (mk k)`（1.031 / 1.052，只在倒序那次，原因未明；对原版 2.06–2.14 倍，在一个 D14 对象已批的 1.7–2.4 内）。上一轮 17 行
不通过的其余 15 行都通过（j01–j03 coercion 关闭已同参考；其余多因中性读去掉了列序效应）。字段链 k=16–256 新/参考 1.000–1.045（打开）、0.978–1.033（关闭）；
指数级嵌套新/原版 1.04–1.19。这 2 行按规则 (4) 列给用户，不再修。
——**各次改动的独立评判（用户 11-05 要求，Opus agent，只读）。** 判"该改"：(B)（D15 的一致性、用户批准）、载荷第一轮（真正的平方增长，k=256 时 4.8 倍）、
打印丢了对象的载体（用户可见的缺陷）、合并第 6–7 步的几处（`standard_check` 批次未变返回 NONE 致 6 个超时、`dest_node_instance`、恢复载体节点的类型合一、
报错辅助函数提出共用、`printer`/`head_constant` 只留一份）、解析器的惰性 `if`（每次解析 13–15%）。判"两者都有、保留"：载荷第二轮 `batch_access`（效果真实，
但只在 k ≥ 16 的人造长链上，按规则 (4) 本应先报用户）。判"钻牛角尖"：r6 的三处——`field_reports` 提前返回与记住结果（追的是测不出的约 1%，保留，改动只一两行）、
登记表写法（亚微秒，保留；可选把 `pointer_eq` 收尾换成 `Data.map`）、守卫在 `Type_Infer.finish` 前判断（错误路径上 10–20 µs；给导出函数加了只为速度的参数、
守卫通过时跑两次、正确性靠注释里论证的一条事实、两个引擎不对称——**它建议撤回，低优先级**）。总评：这些改动没有实质地把代码弄坏；更该吸取的是过程——
不通过的行应按规则 (4) 先列给用户。撤回与否待用户定。
——**G6 coercion 引擎一侧第二轮（r2，r6 构建，11-05 03:10–08:52 UTC；`runs/r2/analysis.txt`、对照 `runs/r2/compare_r1.txt`；与构建重叠的 11 次测量都已重测）。**
与第一轮同样的图景：判定与 term 全同；规则 (1) 129 通过、92 更快、6 不通过——A#17–20（let 链 `k.di`，新/参考 1.05–1.10，每节约多 0.05 ms，新/原版 1.05–1.09
仍在已批常见倍数内；A#20 这次刚过 1.05；I1b 不是原因；做无点修改的 agent 剖析过：约四成是 D15 预测表 `compute_predictions` 每轮重建整批的 O(k²)，其余是
6.5.1 设计的路径）、A#147、148（只在正序、那次两份原版之比也偏 0.96–0.97，像噪声）。超出已批倍数的仍是那 12 行，参考在 10 行也超；A#138（3.04 对 2.98）与
A#66（报错 1.72 对 1.7，参考这次 1.68–1.69）两方都在边上。R3：A#69 规则 (2) 通过；A#70、71 的每常量数字仍超 +1.1 µs，同上一轮的说明（测试层替身、噪声约
±2 µs/个，以局部变量优先一侧的限定名行为准，那边通过）。I1a：98 行常见写法去掉后 24 行超 1.2（最高 2.15），总时间多 76–78%——保留结论不变；I1b：C2 各行
至多约 1%。无钩子实例规则 (2) 通过（1.0011 / 1.0002，w = 0.0046）。
——G6 coercion 引擎一侧（`step1/g6/coercion/`，`./start.sh <新标签>` 一条命令）：脚手架与正确性通过、没有计时。227 行上参考与新代码的判定与 term 逐行
相同、三份观察副本同新代码，新代码接受处都等于原版读 E(C)；当前代码上没有因 D15 或 (B) 失去接受的行（"不比"的清单为空）；A#216–219 两方都拒、原版接受
E(C)，按设计。无钩子实例在 8,962 条上同原版。I1a 走过的行 118 个（节点上 114：常见写法 98；晚决定 4），复算全 SAME；I1b 测试开关在 53 行上起作用，C2 的
9 行里只在 7 行起作用（A#54、55 的 let 绑定对象不走它，那两行若变慢与 I1b 无关）。一个进程装参考、干净、两份原版，四列逐行交错；参考列是参考理论自己
的读法（经第六轮的 D-open 包装，比原型本身多一次遍历，冒烟里小行的 参考/原版 达 1.97），所以规则 (1) 这一组偏宽，真正把关的是已批倍数（新/原版：常见
≤ 1.2、救回约 3、报错至多约 1.7、指数级至多约 20；R3 的行按规则 (2) 与 +1.1 µs）。我接受它的各项选择；重跑时规则 (2) 的波动范围改用上面统一的定义。
——D15 那条等待的数据（2026-11-04，草稿 `step1/tests/coercion/probe-B/NC/`，干净代码未动）：两处（节点上、求解前）一起去掉，连带删去只为它存在的
`constrained` 与记录字段 `earlier`，`subtyping.ML` 少 18 行（2,702 → 2,684），别的机制（D13 的依赖判断、预测、学习、D14）都不依赖它。217 个任务逐条对照：
**只有 2 条不同，都是报错文案**（VT_Probe7 D1 #3、#4），判定、接受、R1、G2 各项全同；工作量：学习约多 0.3%（159,675 → 160,091 次，多在 VC_Pair4、5），
D14 学习运行少 4 次。那 2 条：`pk` 登记在 `pk1 :: int × nat ⇒ point` 与 `pk2 :: int × int ⇒ other` 上，`(λu. (u.xpos, p) = (k, (k, n))) p.pk`，原版接受显式写法、
dot 写法三方都拒；保留等待时文案是 `Field "xpos" of u cannot be resolved: the type of u is unknown …`（在求解出的类型上做出、点出真正的问题并列出 `xpos`
的候选）；去掉时在求解前的中间类型上报 `"p.pk" is neither a constant nor a field of p :: ??'a × ??'b | Fields of ??'a × ??'b: fs`（类型里是未解的变量，且 `pk1`
其实合 p 的真实类型 `int × nat`，误导）。结论：对选择与判定，(B) 之下这条等待多余（不细化的选择在类型的每个实例上都一样，规则报错在每个实例上也都
是报错）；对文案不多余——它保证求解前报出的错只能来自参数不在任何约束里、类型已是最终的对象，即 D15"规则文案由求解出的类型上的那一次决定给出"。
待用户定（我的建议：保留，不改设计）。
——G5（2026-11-04，在 (B) 并入后的 `step1/src/`，`subtyping.ML` 2,702 行）：逐文件比较干净代码与 stock 树里提到 `Unsynchronized`、`Synchronized.`、`Array.`、
`Lazy.`、`Future.`、`Thread_Data`、`Single_Assignment` 的行。新增的全在单次调用之内：`Dot_Field.learn` 的两个 ref（记下的载体与最后一批；装着它们的
闭包只放进本次调用里的不可见上下文）、`Syntax_Phases.decode_term_warnings` 的一个 ref（要发的警告）、`Subtyping` functor 的 `dot_infer_types` 里五个 ref
与七个 `Lazy`（一个批次内的记忆与学到的选择）；`parser.ML` 只在 `Array.vector` 那行后面多了一个记录字段。**structure 层面没有可变状态，G5 通过。**
G4 交给一个 agent（`step1/tests/scope/`：各作用范围的形状，每处既查开关的值、也用干净副本读一个 dot 写法；(B) 并入后再在最终的干净构建上重跑开关关闭
同原版的各项对照）；G7 的通读交给一个只读 agent，清单由我手写进本节。G6：cslh19 此时有别人的构建，计时不能跑；解析一侧两个 agent 先写计时脚手架、
只做正确性冒烟（`step1/g6/parse/`：第一次解析、解析原型的行、打印与标记与第二次解析；`step1/g6/localwarn/`：局部变量优先、设计 D 自己的行、警告、
真实结构上的登记表），有空窗再按规则计时；引擎一侧等 (B) 的重跑报回后再开。
——G6 局部变量优先、设计 D、警告、登记表一侧（`step1/g6/localwarn/`）：脚手架写好，正确性冒烟通过（2026 语料 10,065 条：两份原版副本互相 0 处不同、
新代码开关关闭同原版 0 处不同、开关打开时新代码同原版 0 处、验证者原型 1 处即 G1 (i) 那例；计时文本上新代码与原型读法相同；W3 在 6.6 的对象规则下仍发
警告，文本不用改；V_Timing T6 给新代码补了名为 `a` 的登记）。规则的算法：(1) 两次都 新/参考 ≤ 1.05；(2) 两次都 新/原版 ≤ 1 + w，w 是两次里两份原版副本
之比偏离 1 的最大值；限定名常量 (新 − 原版)/标识符个数 ≤ 1.1 µs。真实登记表：插入扣掉"每条一次 Generic_Data 读写"的对照，合并取 `join_thys [a, b]`
减 `[a, a]`。冒烟（负载 13–15，只作信息）里插入约 1.0 µs/条（已批 0.56）、合并约 0.44 ms（已批 0.34，替身同样 0.44），正式数字若仍超出就报用户。
计时 11-04 12:24 UTC 起在 cslh19 无人值守地跑（脚本自己查构建、与构建重叠的作废重跑），我每 5 分钟查一次。
——**G7（2026-11-04）：`reviews/round3/tests-texts/TEST_PLAN.md`（下称 TP）里作废与要改的部分。** 一个只读 agent 逐节逐条对照本文给出分类与出处，我核对了
其中的矛盾点后写成下面的清单。TP 留作历史；第二步、第三步若沿用 TP 的条目，先查这里。
- **整节被本文取代**：TP §5.6 第一步验收（由 6.12 的 G1–G7 取代；22 个任务的对照改为"观察构建与干净构建在每个 G2 任务上相同"）；§5.3 前瞻审计（G2 (c)
  预测审计）；§5.1 参考（子步骤 1 的 2026 参考）；§6 的计时门槛（§1 第 24 条与 `step1/REFERENCE_TABLE.md`；§6.3 第二步跨树的标准改为只记录）；§7 的 AFP 计数、
  警告频率与 `isabelle export` 收集（第三步 `parse_term` 里不发布的比对写文件）；§8 第一步的搭法与插桩副本（6.12"一份代码、几个构建"、替身表）；§8 的
  "不用 `Unsynchronized.ref`"（G5）；§9 第 5 个构建的 `dot_warning_rule`；§10 的 Q6、Q7、Q10–Q14（都已定，出处在本文各处）。
- **因设计改变而作废**：
  - `dot_field` / `no_dot_field` 命令、`Dot_Syntax` 组件 session、bundle 块与 `unbundle`（§1 第 14、20 条），连同测试它们的条目与表 36 行的命令关键字；
  - "已有常量优先"的拆分（`Constant_First`、`Pure_Split`、"在 `decode_term` 失败处拆"及其变异），由第 9 条局部变量优先取代；那个变异改按 `decode_ident` 第 4 行重写；
  - TP §3.1 要 FOL、ZF 的理由（词法会重新标记 binder 里的点）与 §4.1 第 1 个未覆盖项（词法碰无点文本）：词法只标 `)` 后紧跟的点，只供第二次解析用（6.3.2）——2026-11-10 起改为只在开关打开时标、只解析一次，理由照旧成立；
  - 前瞻（`Lookahead` theory、审计、10 个变异、3 个计时门槛），由统一的预测取代；
  - D3 的 judge 方案、关系检查与 `nochk_*` 变异，由 option b 加节点修补取代；
  - D6 的跨树部分（D6 现在是 I1a 代码形状论证的前提，M1/M2 应由 G2 (a) 抓到）；
  - 第 0 级重跑一整套（`Stage0` 的前提、stage0 的 6 个变异、D14"照 stage0 方案处理"），由第 18 条与 6.5.3 取代；
  - `[…].f`、`{…}.f`（第 13 条）；
  - "直接调用 `infer_types` 的也要决定或拒绝"：现在它们拿到载体；
  - 去掉的检查与机制：drop test、学习的 A、C、G 与守卫、前缀重放；
  - `Texts_Probe`（改为第一步后用真实渲染的一次过目）；
  - 2025-2 的树名与 `run-tree`（第 17 条；用各树自己的 `bin/isabelle`）；
  - 开着的块里可见（P4）与"只写进背景 theory"的变异，挪到 base 合并时；
  - 登记原型的 A/B 开关、表 25 行（合并后的检查）、表 34 行。
- **仍适用但要改**：
  - TP §0 的三件事对应 R1–R3（R2 加 D15）；
  - 术语按本文 §0。特别注意：TP 的"learning run"是本文的"学习"（global algorithm 里求字段选择），本文的"学习运行"专指 D14 的嵌套运行，沿用 TP 文字时要改；
  - 每个 dot 用例都要打开开关（默认关）；
  - 登记一律用 attribute、只能写常量；报错列表至多 5 条；
  - 晚决定冲突的文案是原版对 E(C) 的报错（6.5.2）；
  - 载体"活过 `prepare_*`"改为测 `check_terms` 入口的重建；
  - 警告用例按 G1 (iii)(iv)，前端标记按 6.6；
  - 不变式：I2 不再是运行时检查；I4 的守护改为 G2 (c)、D15 的两个 `tye0` 变异与 D14 标记；I9 加"D14 学习运行不嵌套、每个载体至多一次"与"D12 至多依赖深度 + 1 轮"；
    I10 的守护是 G4、HOL 语料开对关、G6 规则 (2)、第二步门槛与开关关闭的 AFP 构建；
  - 变异"registry 用 `Sign.the_const_type`"改述为"模式类型去掉 sort 约束"；
  - TP §5.4 的"计时门槛失败也算抓到"不再用：G3 只数变异构建上测试的失败，只影响开销的变异报为未抓到并写明原因；
  - TP §5.4 里本文 6.5.1 没有的机制（等待时重推操作数、约束化简两次、最外层应用重跑、批次重跑）的变异，按 G3"只保留本章仍在的机制"不带过来；
  - 更早几轮的电池（vcases、`LA_*`、`D3A_*`、`LR_*` 等）与 `D6_Equiv` 只在 2026 参考列表跑到时才算（子步骤 1 的范围）。
- **与本文的三处出入，我按授权这样处理**：
  (1) 开关关闭时 `print_syntax` 列出两条 `_dot_field` 产生式、`print_options` 列出开关（6.3.2"仅供知情"）。G4 的"同原版"是指读 term 的结果，不含这两条命令的
  列表；TP §4.5"无点文本的任何差别都是失败"按此收窄。
  (2) TP §6.3 要第二步同进程的 dot 写法计时复现第一步的倍数，本文第二步的门槛没有这一项。第 24 条只在第一步设计时门槛，所以第二步只记录。它与下面两项
  一起并进 (e)，第二步之前问用户。
  (3) 第 22 条规定 I1a 保留时交付的测试要加 R1 回归，但没说放在哪个 session。去留由 G6 定，保留的话放在 feature 的测试 session 里，session 名属于 (e)。
- **并进 (e) 第二步之前问用户的**：要求构建的 session；自己的 golden；是否沿用 Light_Locale_Golden；测试 session 与 theory 的名字；把 light 的
  `with_warnings` 挪到共用位置（TP §10 Q8）；TP §7 那个 AFP 规模的语义检查与第 8 个可选构建；上面 (2)、(3)。make-patches 的"tested record"按技能
  §3.4 在首次发布时定。
- **r8（2026-11-10/11，Opus agent；`step1/r8/`）：三份草稿并入、跨文件评审项、全部重跑。** 源码 = r7 + `fix_rev1a` + `proto_single`（我并），测试由 agent 并进
  `step1/tests/`（`Clash_Gen_Probe` 放 `tests/coercion/probe/`；`Field_Prods` 进 `tests/parse`；`adapt_tests.py` 的改动写进测试源码，不再在暂存时打补丁）。
  检查点（`r8/merged/`）：只做测试框架改动时 parse、scope 的 24 个结果文件与 `proto_single/results` 逐字节相同；其余各组与 r7 全同（cl/ob 217、std 99、obs 98 个任务，
  G2 (b) 248 / 7924；探针 4 例在 rev1a 前全失败、之后全过）。电池改成一次解析后，除第 27 条预料的 P10/P11/P16、Q5/Q10 外，P1–P4 也随之改变（`{(x::n).x > y}`、
  `{(p).x}`、`[(p).x]` 读作字段访问，`λ(a, b).a` 成为语法错误）——都是第 27 条放宽的直接后果，期望照改。
  评审项（"Implementer decides"）：6（`Dot_Field.selection_check` 一处写选择结果，两个检查都调它）、7（等待索引 `waiting_index`/`place`/`take_bound` 只在 Dot_Field
  一份，两引擎共用；`Dot_Field.learn` 一份；参数收集用原版函数）、13（`field_error_msg` 只返回文本）、14（access 记录去掉 `field`；`last_check_field`；
  `Dot_Field.rebuild_payload`）、15（`Dot_Field.fold_carriers`、`carrier_object_type`）、16（`Wait` 不带列表）、17（`prefix_of`、`const_prefix`）、18（删 `decode_free`，
  恢复原版的 Free 分支）、19（原版 if 链不动）。未做的：`encode_payload`、`dest_carrier` 留在签名里（评审以为测试不用它们，实际五六个测试用）；ESR 里"pending"
  一词不改（它在 ESR 学习运行里是另一个概念，23 处一致）；"today's parse" 那句注释随一次解析已不存在。
  第 26 条 (3)：简写与 `del` 只收标识符或长标识符 token、其后必须结束，其余一律报自定的文案（草稿见下，进 6.6 过目）；`[[dot_field "List.list.set"]]`（带引号的名字）
  因此也被拒——按"长标识符"的 token 种类严格读；**用户 11-12 定继续拒绝**（"建议简单一点"；我曾建议接受引号里恰是名字的字符串，以合 `Parse.name` 的惯例）。文案草稿：`Malformed argument of dot_field⌂: <原样的参数>` / `Write the name of a constant, whose last
  segment becomes the field name:` / `  [[dot_field List.length]]` / `or a field name, "=", and a constant, which may carry a type:` / `  [[dot_field len = "length :: nat list ⇒ nat"]]` /
  `"del" in front of either form removes the field instead.`；没有参数时是 `Missing argument of dot_field`。真实渲染在 `r8/attr_render/out/`。
  行数 r7 → r8：`subtyping.ML` 2,603 → 2,585；`dot_field.ML` 1,190 → 1,281；`dot_field_attrib.ML` 48 → 67；`syntax_phases.ML` 1,212 → 1,206；`type_infer_context.ML` 632 → 577。
  r8 对 r7：除批准的三处（一次解析的期望、rev1a 的冲突修正、attribute 的语法收紧与新测试 A07.9–19）外全同——core 只 R07 不同；parse 只 Paren_E2E、Dot_Parser_User；
  scope 全同；cl/ob 217、std 99、obs 98 个任务逐条全同。变异：core 26 个（新增 2 个测 attribute 语法）全抓到；parse 警告 8/8；coercion 22 个抓到 17 个（少的一个随
  rev1a 删去的走不到的子句而删），没抓到的 5 个同 r7。agent 列出的 MERGE.md 与本文过时段落：MERGE.md 24–25、45–50、54、57–63、66、74–77；本文 6.3.1（`decode_free`）、
  6.3.2、6.4（语法收紧与文案）、6.6（加文案）、6.10。
- **两处大重构的再评审（2026-11-11，CLAUDE.md 的两轮对抗流程，9 个 Opus agent；日志在会话的 workflow `wf_a36471ae-9e0` 的 journal）。** 裁定：两处都达到验收标准，
  无 bug、无脏补丁；六条意见都成立（都是 elegance-minor，裁判认定都不是钻牛角尖）。归我定、改完送回再审的五条：(1) `dot_predictions` 导出的 `predicted`/`predicted_gen`
  只收 key，对象、binder 类型、字段名都从 `accs` 读（往下 `predicted_choice`、`build` 也去掉调用者传入的 `bs`）；(2) 顶层的 `opened_unify` 改收一对类型
  `(A, B)`，去掉 `fn [U'', V', T''] => …` 这个不完全匹配，数出现次数的 fold 与 `solve_spine` 共用一个顶层函数；(3) `first`/`reusing` 上的注释是错的（第一轮什么都不记），
  改正；(4) 标准引擎删掉包着共用索引的 `watch` 与本地 `take_bound`（`watch` 用 stamp 反查 key，而调用者手里就有 key）；(5) `Dot_Field.learn` 去掉 `decided` 参数
  （它喂的过滤永远不起作用；这偏离评审第 7 项的原文，要注明）；(6) 注释部分：`waiting_index` 的"等待中字段的 stamp"不实（已决定、已推迟的字段的 stamp 会留下），
  `take_bound` 写明调用者要做的事，ESR 走不到的 `NONE` 分支删掉。**要用户定的一条**：(6) 的代码部分——`Dot_Field.take_bound` 返回一批 stamp 时，把它们从索引其余各处也删掉，
  使"返回过的 stamp 不在索引里"由构造保证；随之删掉标准引擎的 `NONE` 跳过、ESR 的 `deferred` 跳过与走不到的分支。代价：某个参数被绑定时多扫一遍 `inner`；
  不改行为（裁判逐引擎推过），但改了共用函数的语义、偏离评审第 7 项原文，要全部重跑。裁判建议批准。都待用户同意后再改。
  **用户 11-11（听完从头的讲解后）："那么按你建议来吧"——批准 `take_bound` 的改法**；其余五条是我给了明确改法、说过"你同意后改"的，我理解一并在内（回复里写明，
  用户可否决）。带引号的名字一题用户 11-12 定继续拒绝，代码不动。裁判全文存 `step1/review2/judgment.md`，辩论记录 `debate.json`。
- **r9（2026-11-12，Opus agent；`step1/r9/`，源码差 `r9/src.9.diff`，r8 源码备份 `step1/src_r8/`）：六条全按裁定改完。** `take_bound` 交出的 stamp 同时从其余
  `inner` 条目删去；标准引擎的跳过改为 `the`，ESR 的 `deferred` 跳过与走不到的分支删去（`end_decisions` 那个跳过另一回事，留着）；预测只按 key 读（`build` 去掉
  `bs`）；`opened_unify ctxt (A, B) …`，数出现次数的 fold 与 `solve_spine` 共用新函数 `occurrences_of`；`first`/`reusing` 的注释改正；标准引擎删掉 `watch` 与本地
  `take_bound`；`Dot_Field.learn` 去掉 `decided` 参数（偏离评审第 7 项原文，已注明）；索引的注释按新语义改写。行数 r8 → r9：`dot_field.ML` 1,281 → 1,288，
  `type_infer_context.ML` 577 → 570，`subtyping.ML` 2,585 → 2,582。**r9 与 r8 全同**：core、parse、scope 的输出与 `.results`，cl/ob 217、std 99、obs 98 个任务，
  ob 的审计各数，G2 (b) 248 / 7924，探针，变异（core 26、parse 警告 8/8、coercion 22 个抓到 17 个、没抓到的同样 5 个，每个变异的输出与 r8 逐条相同）。
  重新锚定的变异 `blocked_freeze_all`、`d15_no_node` 与三处观察编辑，做的改动与 r8 相同；没有退役的变异。另：core 的 26 个变异里 24 个由检查失败抓到，
  `no_short_delete`、`short_form_whole_name` 两个由测试 theory 在被改坏的声明处报错而停下（r7 起一直如此）。它另指出 ESR `check_decisions` 里 `decidable` 的
  `NONE => false` 同样走不到（裁定之外，未动）。
- **r9 送回再审（2026-11-12，workflow `wf_287f98f0-251`，3 个 Opus agent；裁判全文 `step1/review2/recheck_judgment.md`）：六条都按裁定改好，验收通过；没有新意见，
  不需要再一轮。** 裁判只附带提到 `decidable` 的 `NONE => false` 走不到（`undecided` 与 `fields` 一起填、一起回滚），说是否改成 `the` 由用户定。我按实现细节的授权定：
  改（与 `take_bound` 那条同一道理，留着会让人以为有这种情形），随最后一轮之前的 r10 一起做；r10 要求与 r9 全同。
- **r10（2026-11-12）：`decidable` 改为直接取（`the`），全部重跑与 r9 全同**（`step1/r10/compare.10.*.txt`；r9 源码备份 `step1/src_r9/`）。`step1/src/` 现为 r10。
- **第三轮 G6（2026-11-12/13，r10 代码；`step1/g6r3/`，汇总 `step1/g6r3/round3/TABLES.txt`；第一个 agent 因 API 断线中止三次，按用户"继续派遣 the agents"另派一个
  接手分析）。** 计时的是 r10 的干净构建（四组的 MANIFEST 都是 `93c96df8…`，11 个输入与 `step1/src` 逐字节相同）。正确性的附带检查都成立（标准引擎 406 条
  结果 0 处不同；解析 `CHECKS: ok`、第一次解析的树同 Pure；coercion 检查运行 `failed=0`；局部变量优先 `D.changed` 0）。门禁新加的"计时 CPU 上没有别人的
  忙线程"生效：局部变量优先一组 1 次运行被系统进程打扰而重跑，coercion 一组按自己的框架重测了 32 个单次测量；coercion g1 两次运行因另一用户的 PyTorch
  作业占着计时 CPU 分别等了约 4 小时、9 小时（实际测量各约 45 分钟，同第二轮）。
  - **要紧的行都通过**：开关关闭的第一次解析 1.002 / 1.001（范围 ±0.006）；coercion 引擎无钩子实例 0.9995 / 1.0020（±0.0057）；标准引擎 242 行规则 (1) 全过。
  - **不通过的行（都按第 28 条接受）**：解析一组 `G6_Parser_Rows` 9 行（人造的小文法与加 300 条中缀产生式的宽文法上单测解析器，慢 0.2–3.7%，宽文法上最多；
    第二轮这些行测的是带 functor 版本里逐字原版的实例，这次是去掉 functor 后的解析器，也可能与运行时机器刚卸下重负载有关，未分清，按第 28 条不再追）；
    局部变量优先一侧 11 行（新出现 5 行，超出 0.1–0.9%；第二轮已接受的 6 行照旧，其中 D.T2 每个长标识符 +20–22 µs、W.W2 每个常量 +1.9–3.3 µs 比第二轮大，
    换算成整段输入只慢 0.6–0.7%、1.6–2.7%）；coercion 一侧规则 (1) 不通过的仍是 let 链 4 行（对参考原型 1.05–1.10），超出已批倍数的由第二轮 14 行降到 8 行。
  - 第二轮不通过、这一轮通过：`make_gram`、开关关闭与打开的检查 `ck.off`/`ck.on`；标准引擎 2/on/a12、2/on/j02。
  - 没测的：解析一组第二轮的第二次解析与冲突区各行（代码已不存在）；coercion 一侧 C4 一族 9 行无法比较（参考接受、新代码拒绝，即第 25 条 (3) 删掉节点修补的预期后果）。

（`reviews/round3/tests-texts/TEST_PLAN.md` §8，按本章更新）

0. **开工前**：先读技能 `isabelle-patch-feature`（升级是 §3.9，从第 4 步"在 2026 上从头实现"开始；commit 与 push 都要用户下令）。
1. **第一步：用户空间，不构建，在 Isabelle2026 上。** 一份干净的最终代码，由脚本派生出带插桩的观察构建与各变异构建（见下面"一份代码、几个构建"），
   代码放在本仓库 `ai-artifacts/` 下的一个新目录（不提交；第二步把干净代码搬进私有树；开工时确认 `.gitignore`），在 cslh19 上用 Isabelle2026
   的 `ML_process -l HOL` 测（cslh19 上 `~/Isabelle2026` 有官方发行版与 HOL heap；或用私有树自己的 `bin/isabelle`，在没有 `ISABELLE_*` 变量的 shell 里；
   资源规则照旧）。Pure 与 HOL 被改的文件各做"原版副本"与"功能副本"两份，都取自 stock 树 `worktrees/Isabelle2026-dot_syntax-stock`（记下其提交），
   交付的补丁就是两者之差。要合成的是 §4 列出的各部分参考原型（多在 2025-2 上），按本章改写。
   - **子步骤，按顺序**（第七轮深度复审 §6 第 5 步）：
     1. **参考原型移到 Isabelle2026**（问题 6），在任何计时之前。引擎用第六轮的 2026 移植（`reviews/round6/d14/verify/proto/subtyping_esr3_restart.ML`、
        `type_infer_restart.ML`、`Loader.ML`）；解析、登记、警告的参考从 2026 原版重新生成，用原型自己的 diff 或生成器（如 `make_trans_v.py`、
        `parse_side.diff`），不手改 2025-2 的副本，去掉其中 2025-2 的 light_locale 行，用第六轮的 loader（2025-2 的驱动用的 `Thy_Info.use_thy_legacy`
        在 2026 里已删）。在 cslh19 上跑各自的测试列表，2026 的输出作为 G1 的参考，与 2025-2 的差别作为信息报告。同时写下面的派生脚本（问题 7），
        并做 6.3.1 要求的扫描：AFP 里检查 schematic 变量的 parse translation 会不会看到记下完整名字的 `Var`（估计 0 处）。
     2. **参考表**（问题 9）：每组计时行对应哪个参考原型与配置（引擎行：s3c 的 2026 移植；D14 行：`compare/COMPARE.md` 的 NEW-observer），列出本章有意
        移动的行与预期方向（I1b 去掉使 C2 行变慢；第二步 coercion 关闭的行少一次原型模拟的原版推断而变快；D15 的新规则）。参考与新代码在同一轮计时里、
        在 2026 上按 `compare/COMPARE.md` §2 的方法重测。
     3. **最先测**：开关关闭时第一次解析（Earley functor 第一个实例）与 coercion 引擎无钩子实例的开销（§1 第 23 条）；超出波动范围就先找用户。
     4. 合成代码。
     5. 按下面的门槛验收；同时测出 §1 第 22 条（I1a 的去留）与 6.5.1 D15（失去的接受数）所需的数字，报用户。
   - **一份代码、几个构建**（问题 7）：干净的最终代码是唯一来源。一个脚本从它派生出：用户空间可加载的副本；G2 用的一个观察构建（开关、计数器、审计）；
     G3 每个变异一个构建。脚本的每处编辑都必须恰好匹配一处，否则停下（仿第四轮 `make_v.py:20-23`）；锚点过期就停；装不上或载入失败的变异单独报告，
     不算抓到。门槛各行写明在哪个构建上跑：G1、G4、G5、G6 在干净构建上，G2 在观察构建上，G3 在变异构建上。TEST_PLAN §5.6 的 22 个任务对照改为
     "观察构建与干净构建在每个 G2 任务上判定、term、文案都相同"。不把计数器做成 functor 的额外钩子实例（会把测试接缝放进交付的引擎）。观察构建另带
     I1b 捷径作测试开关（受 I1a 的 `coercion_args` 条件限制），C2 那组行带与不带各测一次；不通过时按规则 (4) 连同"发布受限的捷径"这个选项报用户；
     交付的代码不预先带它（问题 9）。
   - **测试方法**（第五轮评审 3.13）：复制出来的 `syntax_phases.ML` 不能装成 Isar 命令用的解析器，所以用副本解析、再调用各命令底下真正的函数
     （`Specification.check_multi_specs`、`Function.add_function`、`BNF_LFP_Rec_Sugar.primrec`、`Inductive.add_inductive`、`Expression.cert_statement`）；
     `fix`、`obtain`、locale 参数在真实的证明或 context 里用 `ML_val` 调副本。HOL 中调用 `Term_Position` 的翻译（`case_tr`、列表推导、`_lam_pats_syntax`、
     `update_name_tr`）编译在补过的 `Term_Position` 副本上；coercion 副本重放 HOL 全部 `coercion`、`coercion_map`、`coercion_args` 声明。
   - **第一步的替身与第二步的直接测试**（问题 8）：用户空间装不上内层语法操作（syntax.ML:158-168），也跑不了真正的检查表（`syntax_phases.ML:899` 的私有
     Generic_Data；adhoc_overloading 不导出它的检查），所以第一步调用真正的 `Syntax.check_terms`，并用替身模拟改在它里面的部分：

     | 最终代码 | 第一步的替身 | 第二步的直接测试 |
     |---|---|---|
     | `check_terms` 入口重建载荷 | 把最终的重建函数注册为第 −100 级之前的检查（不用第六轮那个被 Isar 命令绕过的包装），于是 class specification（class_declaration.ML:354）在第一步就到得了，class target 的 D14 路径成为第一步的测试 | coercion 打开时 0 个 `Bad name binding` |
     | 出口报告字段那一段的标记（`check` 交回上下文） | 级别最高的 `term_check'` | 每个字段那一段在批量构建与 PIDE 里、每个被接受的读法各报告恰一次（歧义输入的每棵通过检查的树同原版的类型报告一样各报一次；2026-11-03 改） |
     | 替换第 0 级的 `"standard"` | 引擎注册在第 −1、0 级 | coercion 关闭的测试集逐例对照 |
     | 第 1 级的 dot 检查排第一 | 第六轮的观察者 | dot 检查在第 1 级最先运行（`print_checks` 每一级新的在前，所以它显示在第 1 级那一行的最后；2026-11-03 改正）；D14 例子与 adhoc_overloading、`case` 的第 1 级检查并存 |
     | 打印 | 直接调用 | 真实的 `term` 与目标输出；fast_abbrev_printing 的 golden（它要构建好的 session，所以挪到第二步） |
     | 词法改动、真正的 record 钩子、`Term_Position` 被 HOL 自己的翻译调用、`dot_field.ML` 在真实位置编译、Isar 命令直接读 dot 写法 | 用户空间副本 | 扩展后的 `Dot_Parse_Tree.thy`，与第一步逐例对照 |

   - **验收门槛**（取代 TEST_PLAN §5.6；第五轮评审 3.8；第七轮深度复审问题 2、3、6、7、9、10、16 改述）：
     - **G1**（干净构建）：每个例子比较判定、被接受的 term（aconv）与选择 C，以原版 2026 对 E(C) 的推断为准，对照子步骤 1 得到的 2026 参考；参考的开关
       取本章的值：引擎参考 `dot_object_own_type` 开、`dot_late_rerun` 开；D14 的参考取第六轮验证的 `hrtl` 配置（`DOT_H=on DOPEN_LEARN=off
       DOT_H_READ=reinfer DOT_H_READOUT=tagged DOT_LATE_RERUN=on`，`reviews/round6/d14/verify/proto/lists/v4.txt`；`dot_object_own_type` 经 `Restart_Shipped`
       默认开，`Restart_Base.thy:658`），原型不设开关时跑的是被否决的 D-open，不是本章的机制（第八轮短评审第 6 条）。允许的差别在第一步之前写成清单：I1b 去掉、修法 B/C 去掉、第 0 级重跑去掉、§4 列出的
       解析与登记部分的去除、6.5.1 D15 的新规则、Isabelle2026 自己的改动（各追到 diff 行）。子步骤 1 之后补两项（2026-11-03；用户要 Opus agent 核查，
       它报"不需要用户"，按它收窄后的写法定）：
       (i) 6.3.1 第 6 行误拼限定名交给原版（第五轮评审 3.10；参考原型早于它）：**只限下列各例**，且每例新代码的结果须与原版对同一文本的结果相同（解析时的
       `Undefined constant`，含位置与补全）——2026 语料开关打开时的 `auto intro: order.strict_trans`（V_JAll 两次、V_Fixed 三次运行里"option on ≠ stock"
       由 1 变 0）；engine6 `VT_Probe5` M1 的 `z.foo`、`Lisst.map f ys`（两种模式）；engine3 `rr/RR_AB` 第 58 例（E21 `z.nosuchfield`；另加一个固定对象的
       变体 `r.nosuchfield` 保住"没有选择的字段"这一测试）；parse 族的 H（第三轮的 `check_const` 退路，由下面"另加"里误拼限定名的端到端比较取代）。
       局部变量优先与解析的参考原型没有登记表，别的例子因第 6 行变成原版报错**不算**允许的差别：在测试上下文里补上名为第二段的登记（`DOT`、`f`、`a`、
       `foo` 与 record 字段；V_Attack A01–A09、A22、A23、B08，V_Sanity T8，V_JAll/V_Fixed 的语料卫生 oracle，parse G；V_DProto H10/H15/H23、parse E1/F/G
       要第一步用户空间的 record 钩子或显式 `[[dot_field]]`），按原参考比；V_Sanity T8 的文本 `w.a.b.c.d.e.f.g` 也是计时行 V_Timing T6 的文本，重测时同样要有名为
       `a` 的登记（没有已批数字依于它；"拆分的标识符 +0.4 µs"是 V_Timing2 的 T8，第一段被绑定，不需要登记——11-03 局部变量优先的 agent 更正）。(ii) `St0_CloseForm` 第 24 行（D14 的 `fun hh` 方程，两种模式；参考记的是 theory 在此中止，因第六轮的 `check_terms` 包装被 Isar 命令绕过、
       载荷没有 serial；本节替身表第一行）：改为被接受，C 选 `point.xpos`，`hh.simps` 与原版 2026 用 `fun` 命令读 E(C) `hh i = (λt. point.xpos t) (mk i)`
       得到的 `hh.simps` aconv，theory 读完；同一 theory 第 14、17、20 行的三条 CLOSEFORM 仍须同参考。只此一例。(iii)（2026-11-03 补，由已批的 6.6
       推出）警告的对象规则按 6.6（最长的、本身是常量的真前缀），警告原型里按第三轮旧对象规则的测试（`step1/MERGE_INVENTORY.md` D.2 第 13 项列出：
       Warn_Tests_A 的 A04、A30–A39、A50–A53、A60–A62，Warn_Tests_B 的 B01–B05、B08、B20–B23、B30、B40–B43，变异 `no_refinement`、`outermost_binder`）
       改为按 6.6 预期，逐例写明。(iv)（2026-11-03 补，由已批的 6.6"选了字段访问、遮住常量不发警告"推出）V_DProto 的 H01、H05、H22、H29、C01、
       C02、C04 原型报 1 条警告（原型的 W1），新代码报 0 条；H26（原型的 W2）在警告写成后仍须报 1 条。比较时载体常量的名字（原型的替身 `V_Base.dot_access`
       与真正的 `Pure.dot_access`）规范化。（核查报告另指出：`VT_Probe5` #8
       `(λt. t.foo) z` 的引擎文案以空的 `Fields named "foo" exist for:` 结尾，交 6.6 文案过目。）
       报错文案只与 2026 上记录的参考比，其余文案差别交 6.6 的文案过目（复审放宽 4，我按授权定）；比较文案时 `??'a` 后的编号按出现顺序重编、载荷里的
       serial 换成占位（引擎原型的 26 条文案只差 `??'a` 编号，2 条带 serial；我按授权定）。卫生 oracle 与开关关闭的语料检查不需要参考，在 2026 上对同版本原版重跑。这也是检验各部件衔接处的标准。
     - **G2**（观察构建）：(a) 每个 Done 重新推断对照——I1a 的两个出口（`done_result` 与推迟重跑成功的出口）返回的 term，都由原版代码在 E(C) 上复算并
       aconv（观察构建的 `S3B_RECHECK_DONE`，经单一出口函数，所以一个开关管两个出口；§1 第 22 条的计时也用它）；
       (b) 第一轮审计（问题 3）——标准引擎决定过字段（节点、晚决定、学到）的每个批次，把它第一轮的输出与原版 `infer_types` 加 `expand_abbrevs` 在 E(C)
       上的结果比较，aconv 含类型与 sort，要求 0 个 DIFF、0 个 STOCK-ERR（移植 `reviews/round6/d14/verify/proto/type_infer_restart.ML:471-524` 的
       `DOT_V_R1AUDIT`）；(c) 预测审计（参考引擎的 `S3B_AB_PRED` 与 `S3C_PRED_AUDIT`：预测做出的选择与不预测时的 late choice 比较，0 处不一致）；
       (d) PROP-DUP（`dot_propagate` 决定的字段从不是预测表已覆盖的字段，0 次）。原来的"I2 布尔量回退 0 次"去掉：I2 恒为假，这条检查不可能触发（6.5.1）。
     - **G3**（变异构建）：只保留本章仍在的机制，每个衔接处一个变异；另加第五轮评审 3.2（载荷在检查入口重建）、3.4（去掉 I1b）、3.6（单一出口函数与
       单一拒绝判断；后者的变异 `rejected_no_last_check` 随走不到的子句在 fix_rev1a 撤去）各自的变异、打印的变异、去掉 `coercion_args` 条件检查的变异、`late_no_result`（第六轮 VERIFY §2.1：67 个攻击批次里错 51 个却只改变
       1 个判定，所以按 G2 (b) 计分）、恢复 D15 `tye0` 读法的变异两个（`chosen` 先试 `tye0`；`d` 与规则文案读 `tye0`，6.5.1）。
     - **G4**（干净构建）：开关关闭时在第四轮语料上同原版；作用范围——继承、import 合并、在解析与检查之间改开关，以及复审探针的全部形状：`context notes`
       块（theory 层、嵌在 locale 里）、`lemma notes` 只作用于证明、locale 里 `declare` 到达导入它的 locale、sublocale 目标与 interpret 它的 theory、无名块里的
       `declare`（light-locale 块的在 base 合并时测）。
     - **G5**：I11 改述为"结构层面没有可变状态"。
     - **G6**（干净构建）：计时按 §1 第 24 条（规则 (1) 单侧；规则 (2) 的已批例外见 6.8；开关关闭的部件行用同进程的原版副本对功能副本测）。
     - **G7**：列出 TEST_PLAN 里作废的部分（2026-11-04 已列，见 §6.11 末"G7"）。
     - **另加**：第五轮评审 verification-6 的四个逐字节解析例子；误拼限定名的端到端比较（`List.fil`、`List ∧ List.fil`、`True + List.fil x`、
       `xs ≠ [] ⟹ xs.lenght > 0`、`NM a.b` 文法；第五轮评审 3.10）；括号形式的 S1–S15 与第 6 行被翻译变形的对象（3.4）；HOL 语料开关开对关（检查层面，
       `aconv` 与报错文本）；括号形式在仿 `mk_lift_expr` 翻译里的探针；有歧义文法（K7）的探针；`fun`、`definition` 方程里变量与 record 同名、带与不带
       `for`（覆盖 6.3.1 第 4、5 行；问题 5）；6.5.1 D15 列出的测试；6.4 的 locale 登记（interpretation、有自己 `bar` 的 sublocale、`locale two = a: foo 1`、
       同类型两个 interpretation、theory 层另写 `[[dot_field a.bar]]`——预期在 theory 层只有一个候选 `foo.bar 3`，在 `context foo` 与导入它的 locale 里只有一个候选
       `foo.bar n`（6.4 的遮蔽规则）——、`context fixes c begin` 里的常量；light-locale 块在 base 合并时）；字段那一段的前端标记（6.6：`length` 折回成
       `length`、`[[dot_field sym_diff]]` 下 `A.sym_diff B` 与原版 `sym_diff A B` aconv 且标记为 `sym_diff`、locale 带参数的 `abbreviation` 在 interpretation
       之后、之后再定义第二个缩写时最新的胜出、一个 `is` 模式记录 pattern 模式不做 β 归约的情形；参照 `probes/markup_fold/`）。
   - 完成后把用户可见文案连同真实渲染一次性请用户过目（6.6 的清单）；统计宽容学习、成环规则、节点修补在非对抗测试集上的触发频率，再向用户提
     第五轮评审放宽提议 4.8。
2. **第二步：私有树 `contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax`（分支 `Isabelle2026/dot_syntax`，base `Isabelle2026/local_datatype`），每批构建
   由用户下令。** Pure 批、HOL 批、发行版回归；构建与流程的问题（TEST_PLAN §9–§10，其中计时门槛已由 §1 第 24 条定——第二步跨 heap 的计时只记录、
   不设门槛——`dot_warning_rule` 已不需要）在这一步之前问用户。base 移动时按 §3.4 的步骤合并（含 6.4 的 record 钩子块路径与块测试）。何时开始也要问：
   下面四个 feature 的进度见 6.10 末尾（2026-11-03：light_locale 未 push，另三个未实现），我的建议是至少等 light_locale push 之后。
   **第二步的门槛**（第七轮深度复审问题 8）：G1、G4 的测试集与 Isar 命令、class 的例子在私有树上重跑，与第一步逐例对照；加上 6.12 第一步那张表的
   第二步一栏；fast_abbrev_printing 的 golden 打印不变；交付补丁的 hunk 就是干净代码的 hunk（TEST_PLAN §8，`:835-837`）。
3. **第三步：AFP**（第五轮评审 3.14）。开关不能用 `-o` 打开（`Config.declare_bool`），全开会让约 9,900 处报错、theory 中断，所以：AFP 构建用默认的
   关闭状态，作为"开关关闭同原版"的回归；另在同一次探针构建里，在 `parse_term` 加一个不发布的比对（由一个探针选项控制，取代 TEST_PLAN 的
   `dot_warning_rule`）：在不可见的上下文里开着开关再解析一次、比较、按 6.7 的分类计数并写进文件。构建都要用户下令。§3.1 里"开着开关的 AFP 构建做
   精确统计"的说法作废。
4. **第四步：首次提交与发布**（新增文件逐个批准；实验输出不提交；commit 与 push 都要用户下令）。首次发布前按技能 §3.4 第 4 步写 `tools/release_build.sh`
   （至少构建 `tools/required_sessions.txt` 的 session，相对路径），新文件要用户批准。
