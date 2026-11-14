"""Derive the step-1 builds of dot_syntax from the clean code (plan §6.12, "一份代码、几个构建").

  ../src/               the clean code: every file the feature changes or adds, at its path in the
                        Isabelle tree (src/Pure/..., src/HOL/..., src/Tools/...); the bytes step 2
                        puts into the private tree
  builds/stock/         stock's version of the changed files (from the stock tree) under the
                        user-space edits: the stock copy of the in-process pairs (G4, G6)
  builds/clean/         the clean code under the user-space edits: G1, G4, G6
  builds/observe/       clean + the observation edits (switches, counters, audits): G2
  builds/mutant-<m>/    observe + the edits of mutant m: G3

Every edit replaces text that occurs exactly once in its file, otherwise the script stops; for a
mutant the mutant is reported as not applied (never counted as caught) and the others go on.
Each build directory gets a MANIFEST: the stock commit, the edits applied, the sha256 of every
input and output file.  The edit lists live in edits.py.  Text processing only.

Usage: python3 -I derive.py [stock|clean|observe|mutants|mutant-<m> ...]   (default: all)
"""
import hashlib
import importlib.util
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "src"
BUILDS = HERE / "builds"
STOCK = Path("/home/qiyuan/Current/MLML/contrib/dot_syntax/worktrees/Isabelle2026-dot_syntax-stock")
STOCK_COMMIT = "7d475f7"


class StaleAnchor(Exception):
    pass


def load_edits():
    spec = importlib.util.spec_from_file_location("edits", HERE / "edits.py")
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def sha(data):
    return hashlib.sha256(data).hexdigest()


def stock_commit():
    head = subprocess.run(["git", "-C", str(STOCK), "rev-parse", "--short=7", "HEAD"],
                          capture_output=True, text=True, check=True).stdout.strip()
    if head != STOCK_COMMIT:
        sys.exit(f"stock tree is at {head}, expected {STOCK_COMMIT}")
    if subprocess.run(["git", "-C", str(STOCK), "status", "--porcelain", "--untracked-files=no"],
                      capture_output=True, text=True, check=True).stdout:
        sys.exit("stock tree has local changes")
    return head


def apply(files, edits):
    """Apply edits in order to {path: text}; each old text must occur exactly once."""
    for e in edits:
        if e.path not in files:
            raise StaleAnchor(f"{e.name}: no file {e.path}")
        n = files[e.path].count(e.old)
        if n != 1:
            raise StaleAnchor(f"{e.name}: {n} matches in {e.path} for {e.old[:120]!r}")
        files[e.path] = files[e.path].replace(e.old, e.new)


def write_build(name, files, inputs, applied, commit, load, imports="Main"):
    out = BUILDS / name
    if out.exists():
        shutil.rmtree(out)
    lines = [f"build {name}", f"stock {commit}", "inputs:"]
    lines += [f"  {sha(data)}  {p}" for p, data in sorted(inputs.items())]
    lines += ["edits:"] + [f"  {e}" for e in applied] + ["outputs:"]
    for p, text in sorted(files.items()):
        f = out / p
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(text)
        lines.append(f"  {sha(text.encode())}  {p}")
    if load:
        thy = f"theory Dot_Build\n  imports {imports}\nbegin\n\n" + "".join(
            f"ML_file \\<open>{p}\\<close>\n" for p in load) + "\nend\n"
        (out / "Dot_Build.thy").write_text(thy)
        lines.append(f"  {sha(thy.encode())}  Dot_Build.thy")
    (out / "MANIFEST").write_text("\n".join(lines) + "\n")
    return out


def main(argv):
    ed = load_edits()
    commit = stock_commit()
    stock_in = {p: (STOCK / p).read_bytes() for p in ed.CHANGED_FILES}
    src_paths = list(ed.CHANGED_FILES) + list(ed.NEW_FILES)
    missing = [p for p in src_paths if not (SRC / p).is_file()]
    if missing:
        sys.exit(f"missing in src/: {missing}")
    extra = sorted(str(f.relative_to(SRC)) for f in SRC.rglob("*")
                   if f.is_file() and str(f.relative_to(SRC)) not in src_paths)
    if extra:
        sys.exit(f"files in src/ that edits.py does not list: {extra}")
    src_in = {p: (SRC / p).read_bytes() for p in src_paths}

    wanted = set(argv) or {"stock", "clean", "observe", "mutants"}
    if "mutants" in wanted:
        wanted |= {f"mutant-{m}" for m in ed.MUTANTS}
    bad = {w for w in wanted if w not in {"stock", "clean", "observe", "mutants"}
           and not (w.startswith("mutant-") and w[7:] in ed.MUTANTS)}
    if bad:
        sys.exit(f"unknown builds: {sorted(bad)}")

    def text(inputs):
        return {p: data.decode() for p, data in inputs.items()}

    def named(edits):
        return [e.name for e in edits]

    if "stock" in wanted:
        files = text(stock_in)
        us = [e for e in ed.USERSPACE if e.path in files]
        apply(files, us)
        write_build("stock", files, stock_in, named(us), commit, ed.STOCK_LOAD, ed.IMPORTS)
        print(f"stock: {len(files)} files, {len(us)} edits")
    clean = text(src_in)
    apply(clean, ed.USERSPACE)
    if "clean" in wanted:
        write_build("clean", clean, src_in, named(ed.USERSPACE), commit, ed.LOAD, ed.IMPORTS)
        print(f"clean: {len(clean)} files, {len(ed.USERSPACE)} edits")
    observe = dict(clean)
    apply(observe, ed.OBSERVE)
    if "observe" in wanted:
        write_build("observe", observe, src_in, named(ed.USERSPACE + ed.OBSERVE), commit, ed.LOAD, ed.IMPORTS)
        print(f"observe: {len(ed.OBSERVE)} observation edits")
    report = []
    if "mutants" in wanted and BUILDS.exists():
        for d in BUILDS.glob("mutant-*"):
            if d.name[7:] not in ed.MUTANTS:
                shutil.rmtree(d)
    for m, edits in ed.MUTANTS.items():
        if f"mutant-{m}" not in wanted:
            continue
        shutil.rmtree(BUILDS / f"mutant-{m}", ignore_errors=True)
        files = dict(observe)
        try:
            apply(files, edits)
        except StaleAnchor as exc:
            report.append(f"NOT APPLIED {m}: {exc}")
            continue
        write_build(f"mutant-{m}", files, src_in,
                    named(ed.USERSPACE + ed.OBSERVE + edits), commit, ed.LOAD, ed.IMPORTS)
        report.append(f"applied {m}: {len(edits)} edits")
    if report:
        (BUILDS / "MUTANTS").write_text("\n".join(report) + "\n")
        print("\n".join(report))


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except StaleAnchor as exc:
        sys.exit(f"STALE ANCHOR {exc}")
