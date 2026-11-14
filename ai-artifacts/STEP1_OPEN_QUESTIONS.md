# 第一步收尾：文案过目与 record 同名字段——思路与待用户回答的问题

2026-11-14 压缩前写。设计以 `DOT_SYNTAX_PLAN.md` 为准（§1 第 28、29 条是这几天的决定）；这里记的是正在讨论、还没定的东西，
以及我打算怎么做。压缩后先读这一份，再读计划开头的"位置"一段。

## 0. 现在在哪里

- 代码：`step1/src/` 是 r10（r10 对 r9 只删了 ESR `decidable` 里一个走不到的分支，全部测试与 r9 全同）。各版源码备份
  `step1/src_r7/`、`src_r8/`、`src_r9/`。补丁量（对 Isabelle2026 原版）：加 3,489 行、删 169 行；其中 `Tools/subtyping.ML`
  +1,529 / −71（1,121 → 2,582 行），新文件 `Pure/Syntax/dot_field.ML` 1,288 行、`dot_field_attrib.ML` 67 行；`attrib.ML`、
  `ROOT.ML`、`record.ML` 的几行留到第二步。
- 第三轮 G6（最终代码 r10）已跑完，不通过的行按 §1 第 28 条（超标不到 10% 一律接受）全部接受（§6.11 末"第三轮 G6"）。
- 文案过目（计划开头清单第 7 项）进行中：62 条文案连同真实渲染在 `step1/texts/TEXTS_REVIEW.md`（条目号 A1…L 指这个文件；
  渲染原始输出 `step1/texts/out/all.out`、`reg.out`；探针 theory 与 `run.sh` 也在 `step1/texts/`）。
- 已定（§1 第 29 条）：A14 的写法；凡让用户照抄的写法一律加双引号，含已批的警告文案。
- 用户这几天定的做法：派 agent 去做，不自己动手；只改代码不算成本，用户看功能与性能的损失；计时超标不到 10% 一律接受；与文档、
  测试相关、不改变设计的事我自决（含改计划里的记录），改变设计、用户看得到的文案仍先问。

## 1. 正在讨论：record 的同名字段（"子 record 的赢"）

**背景。** `record cpoint2 = point + xpos :: nat`：子 record 重新声明了父 record 的字段名，一个 `cpoint2` 的值里同时有
`point.xpos`（int）与 `cpoint2.xpos`（nat）。现在的规则（§1 第 3 条第 5 步）：同名候选里有两个以上确定适用就报歧义，所以
`c.xpos`（`c :: cpoint2`）报 "Ambiguous field"。§1 第 3 条当初删掉了"子 record 覆盖父 record 时选子的"旧规则，理由是覆盖只是名字
遮蔽、两份数据都在。**用户 11-14："赞同改回来"**，并问清了下面几点。

**"更具体"的定义（用户的说法，正确）：** a 比 b 更具体 iff b 的模式类型经实例化能 match a 的模式类型（a 是 b 的特例），反过来不行。
模式类型 = 登记常量的第一个参数类型（`point.xpos :: 'z point_scheme ⇒ int`）。对 record，子 record 的字段总比祖先 record 的
同名字段更具体，所以"最具体的赢"在 record 上恰是"子 record 的赢"。

**已讲给用户的几点：**
- 只有一个候选适用时（`p :: point` 上只有 `point.xpos`），直接选，不比较；新规则只在至少两个同时适用时出场。
- 两个互相 match 不上（`p` 登记在 `nat × 'a` 与 `'a × nat` 上）：在 `nat × nat` 上谁也不比谁具体，照旧报歧义；登记时 F9 已警告。
  record 不会出现这种情况：两个 record 的字段都适用于同一个对象类型，它们必在同一条祖先链上，可比。
- 今天的登记限制（用户问"本质上是限制同一个类型和它的实例化下不能有两个同名字段吗"——是）：同名、一个模式是另一个的特例，
  登记时就拒（F7 "could never be chosen"、F8 "would make the existing field … impossible to choose"）；模式相同 F6 拒；有交集但
  不可比的允许、F9 警告。**record 例外**：record 钩子登记不做冲突检查（§6.4），所以子 record 重名只在用的时候报歧义。
- 不能选得太早（R2：选择只由不看这个字段就能定的类型决定）。例：`point`、`cpoint2 = point + xpos`、`cpoint3 = cpoint2 + xpos`，
  对象类型此刻是"某种 cpoint2 或其扩展"：`point.xpos`、`cpoint2.xpos` 已确定适用，但不能马上选 `cpoint2.xpos`——对象以后可能定成
  `cpoint3`。所以规则要写成：某候选已确定适用、且比 U（所有仍可能适用的同名候选）里每个其他候选都具体，才选它；否则若细化后可能
  出现更具体的赢家就等；只有已确定适用的几个永远分不出谁更具体（U 里没有一个是它们全体的特例）才报歧义。最后一级对象类型定死，
  自然选得出。要配一组测试：三层 record 链、对象类型在不同时刻才定。
- 计算量：很少。不含字段访问、对象类型完全未知（`decide` 第一步就返回 Wait、不取候选）、候选只有 0 或 1 个时一点不多；只有对象
  类型部分已知、又有两三个同名候选都可能适用时，多做几次两两的类型 match（微秒级，约占这个 term 读入加检查的 1–2%）。整体估计
  1% 以下（估算，未测；改完可在计时里加一行）。今天能接受的输入什么都不变；"先等"只会在今天直接报歧义的输入上变多。
- 代码量：两种改法都会变多，不会更简单——
  - **只管 record**（子 record 的字段赢过祖先 record 的同名字段；其余一律照旧）：登记表的字段要带"是 record 字段"的记号（record
    钩子登记时写上），`decide` 里加上面那段判断（只在都是 record 字段的候选间比）；登记冲突那块不动。估计 `dot_field.ML` 净多 30–50 行，
    另加测试。
  - **一律最具体的赢**：`decide` 里加同样判断，不要记号；F7、F8 两类冲突（分类与文案）删掉，特化成为合法用法（`sz` 登记在 `'a list`
    与 `nat list` 上，`nat list` 上静默选后者），F6、F9 保留。估计净多 10–20 行。代价：特化成为默认、静默生效。
  - **不改**：最简单；代价是子 record 重名时用户要写全名（`cpoint2.xpos c`）。真实库里靠扩展重名的情形我估计不多（未数）。
- 我的建议：只管 record。

**待用户回答：**
1. 选哪一种：不改 / 只管 record / 一律最具体的赢？（用户已说"赞同改回来"，又问了代码会不会更简单——答：不会，并给了上面的行数。）
2. 要不要先派 Opus agent 数一数：Isabelle 自带库与 AFP 里有多少 record 扩展重新声明了祖先 record 的字段名（数字小则"不改"或许最划算）。

**定了之后：** 先把新规则写成计划 §1 的一条（改写第 3 条第 5 步、§6.4/6.5 的规则文字；若选"一律"，还有 §6.4 的冲突分类与 F7/F8），
给用户过目（这是设计改动）；再派 agent 改代码与测试；用到 `cpoint2` 歧义的测试与文案例子（A1、A2、A15、H2、A14 歧义一种）要换例子。

## 2. 文案过目：待用户回答的

我给用户定的顺序：(1) 先定三处"代码没做到设计承诺"的；(2) 再把看不出毛病的那批一次给用户看、一并批；(3) 最后逐组讲有毛病的，
每条附我的改法。

**(1) 三处没做到的，用户的答复：**
- **A14**（第一段是局部变量、整个标识符又是常量）：第 3 步（字段不存在）已定，§1 第 29 条 (1)。**第 5 步（歧义）那一种待用户答**，我的提案：
  ```
  Ambiguous field "xpos" of the local variable point :: cpoint2⌂
  cpoint2 has 2 fields named "xpos":
    cpoint2.xpos point :: nat
    CONST point.xpos point :: int
  Write one of these terms instead.
  If you meant the constant "point.xpos", write "CONST point.xpos".
  ```
  （第二个候选的 `CONST` 是第二步的打印器加的；去掉了假的 `"point.xpos" is not a constant, and` 半句。按引号规则，候选行本身是否也要加引号——
  它们是"照抄的式子"——要一并问用户。）若 record 同名字段改成"子 record 的赢"，这个例子本身就不再报歧义，要换一个例子（如 attribute 登记的
  两个不可比的同名字段）。
- **E2**（`{(x::nat).x > 0}` 解析成字段访问后选字段失败，不提"点后要留空格"）：**待用户答**。提案：凡括号形式的字段访问选字段失败，报错末尾加一行
  `A dot directly after ")" is read as a field access. If it belongs to a binder or another notation, write a blank before or after it, as in "λ(x, y). x".`
  代价：真心写 `(f k).foo` 而写错字段的人也会多看到这一行。另：引号里的 `"(x).x"` 不是原文（原文 `(x::nat).x`），归到第 (3) 步的 A10。
- **I5**（开 coercion、本地那一步结束时字段还在等，报错开头两个空行、缺原版的前半段、约束行重复三次）：**待用户答**。提案：这种情况去掉空的前半段与
  "Now trying to infer coercions globally." 一行，直接从 "Coercion inference failed:" 开始；查清重复的约束行是否我们的引擎造成，是就去重；
  改完附真实渲染再给用户看。

**(2) 看不出毛病、待一并批的草稿**（还没给用户看）：A2、A4、A6、A7、A9、A11、F3、G3、I1、I2、I4、K3、K4、K5、K6、K7（J2、K8 无文案）。
给用户看时每条附渲染（从 `TEXTS_REVIEW.md` 抄），按引号规则先标出要加引号的地方。

**(3) 有毛病的草稿**（还没讲；`TEXTS_REVIEW.md` 各条的 "Looks wrong"）：A10 与 E2（引号里的括号形式由打印的对象重建，不是原文）；A12（同一常量两种
叫法 `start` / `CONST seg.start`；类型里有 `??'a`；第一段是 theory 名时劝人把 `Texts_Setup` 变成局部变量）；A13（同是常量对象，有无同名字段时文案
性质不同）；A15（省略号不说藏了几个；"??'a m6_scheme has 5 fields"；警告的读法列表没有 5 条上限）；A16（按打印的短名排序，不同 theory 顺序可能不同）；
A19（批量构建日志里没有位置——原版内层语法报错也一样，大概不改）；A21（引的是所写的 `"t.xpos"`，对象却是 beta 化简后的 `mkc n`）；B1–B3（最后检查：
"chose"、"the choice" 是引擎用语，不提对象；B3 两个标题行、位置标记在第二行、"final" 类型里还有 `??'a`）；C1（"internal error" 不给办法，而起因是
别的工具的检查）；D2（第一行全名、读法行短名；无上限）；E1（一长行三句；例子只在点后留空；两个点只显示一个位置）；F1（未定义的名字只说 "is not a constant"）；
F2（`"a b"` 也说 "without dots"）；F6–F9（F6 不显示新登记的 term；"dot_field del" 不是完整写法；不说已有字段在哪登记；"Field "sz" of len_n" 的 "of"
与 A 组"of 对象"用法相冲）；G1（带引号的名字被拒却不说是引号的问题，下面的例子又带引号）；G2（没有位置）；H2（随 A14 解决）；I3（常量对象按打印的短名、
括号链按标识符形式打印）。另：引号规则要套到 D1–D3（已批的警告）与 A12、A13 的 `CONST …`。

**落地方式：** 用户定完 (1)–(3) 与第 1 节后，派一个 Opus agent 一次改完（文案、record 规则、测试），全部重跑（r11）、重新渲染 `TEXTS_REVIEW.md`，
再请用户看一遍改后的渲染；record 规则是设计改动，改完按 CLAUDE.md 的流程评审。之后问用户第二步何时开始（建议 light_locale push 后）。

## 3. 其他留着的

- 当初决定去掉解析器 functor 时没测 `G6_Parser_Rows` 那组人造文法的行；第三轮里慢 0.2–3.7%，已按第 28 条接受（§1 第 27 条末的补记）。
- 发布前要在私有树上跑 fast_abbrev_printing 的两个 golden session（§3.4 第 5 条，构建要用户下令）。
- 第二步（搬进私有树、构建）还没开始；`attrib.ML`、`ROOT.ML`、`record.ML` 的几行到那时写。
