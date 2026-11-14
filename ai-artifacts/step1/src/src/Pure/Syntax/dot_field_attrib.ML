(*  Title:      Pure/Syntax/dot_field_attrib.ML

The attribute dot_field: register a constant for field access "x.f" (dot syntax).
*)

structure Dot_Field_Attrib: sig end =
struct

local

(*the registration is read, checked and given its serial once, when the argument is parsed; c is
  a token of atom that ends the argument*)
fun registration atom add opt_field context =
  Scan.ahead (atom -- Parse.eof) |--
  Args.embedded_declaration (fn source =>
    let
      val ctxt = Context.proof_of context;
      val field =
        (case opt_field of
          SOME field => field
        | NONE => Long_Name.base_name (Input.string_of source));
      val reg =
        Dot_Field.check_registration ctxt
          (field, Dot_Field.read_registration ctxt (field, source));
      val _ = if add then Dot_Field.report_conflicts ctxt reg else ();
    in Morphism.entity (Dot_Field.declaration {add = add, pos = Input.pos_of source} [reg]) end);

val field_eq = Args.name --| Args.$$$ "=";

(*the short form's constant, as written: its last segment is the field*)
val const_name = Parse.short_ident || Parse.long_ident;

fun malformed ((_, toks), _) () =
  cat_lines
   [(case filter Token.not_eof toks of
      [] => "Missing argument of dot_field"
    | args as arg :: _ =>
        "Malformed argument of dot_field" ^ Position.here (Token.pos_of arg) ^ ": " ^
          implode_space (map Token.print args)),
    "Write the name of a constant, whose last segment becomes the field name:",
    "  [[dot_field List.length]]",
    "or a field name, \"=\", and a constant, which may carry a type:",
    "  [[dot_field len = \"length :: nat list \<Rightarrow> nat\"]]",
    "\"del\" in front of either form removes the field instead."];

(*del f = c, del c, f = c, c (f is the last segment of c)*)
val dot_field =
  Scan.!! malformed
   (Scan.state :|-- (fn context =>
      let fun reg atom add opt_field = Scan.lift (registration atom add opt_field context) in
        Scan.lift (Args.del |-- field_eq) :|-- (reg Parse.embedded false o SOME) ||
        Scan.lift Args.del |-- reg const_name false NONE ||
        Scan.lift field_eq :|-- (reg Parse.embedded true o SOME) ||
        reg const_name true NONE
      end))
  >> (fn decl => Thm.declaration_attribute (K (Morphism.form decl)));

in

val _ =
  Theory.setup
    (Attrib.setup \<^binding>\<open>dot_field\<close> dot_field
      "register a constant for field access x.f");

end;

end;
