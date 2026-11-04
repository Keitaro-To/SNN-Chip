"""直列 LIF 版 (rtl/) と並列 IF 版 (rtl_ref_parallel_if/) の等価性チェック (iverilog)。
直列版は k=15 で回す (WIDTH=16 では漏れが常に 0 になり、IF と一致するはず)。
並列版の 4 ファイルは module 名に _ref を付けた写しを一時フォルダに置いて使う (元ファイルは触らない)。
使い方: python scripts/run_equiv.py [--steps N] [seed ...]   (省略時は seed 1、20000 ステップ)
iverilog / vvp は PATH から探す。見つからなければ環境変数 IVERILOG_BIN のフォルダを使う。
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent   # wta_lif_array/
RTL = ROOT / "rtl"
REF = ROOT / "rtl_ref_parallel_if"
TB = ROOT / "tb"
MODS = ("membrane", "neuron_tile", "neuron_array", "wta_rail")


def tool(name):
    found = shutil.which(name)
    if found:
        return found
    bindir = os.environ.get("IVERILOG_BIN")
    if bindir:
        return str(Path(bindir) / name)
    sys.exit(f"{name} が見つかりません。PATH に入れるか IVERILOG_BIN を設定してください")


wd = Path(tempfile.mkdtemp(prefix="equiv_lif_"))
ref_srcs = []
for m in MODS:
    txt = (REF / f"{m}.sv").read_text(encoding="utf-8")
    for name in MODS:  # 宣言もインスタンス化も同じ語なのでまとめて置換 (コメント内も変わるが無害)
        txt = re.sub(rf"\b{name}\b", f"{name}_ref", txt)
    p = wd / f"{m}_ref.sv"
    p.write_text(txt, encoding="utf-8")
    ref_srcs.append(str(p))

dut_srcs = [str(RTL / f) for f in ("membrane.sv", "step_ctrl.sv", "neuron_tile.sv", "neuron_array.sv", "wta_rail.sv")]
out = wd / "equiv.out"
p = subprocess.run([tool("iverilog"), "-g2012", "-s", "equiv_tb", "-o", str(out)]
                   + dut_srcs + ref_srcs + [str(TB / "equiv_tb.sv")],
                   capture_output=True, text=True, encoding="utf-8", errors="replace")
if p.returncode != 0:
    sys.exit(f"iverilog 失敗:\n{p.stdout}\n{p.stderr}")

args = sys.argv[1:]
extra = []
if "--steps" in args:
    i = args.index("--steps")
    extra = [f"+steps={args[i+1]}"]
    del args[i:i+2]
seeds = [int(a) for a in args] or [1]
ok = True
for seed in seeds:
    p = subprocess.run([tool("vvp"), str(out), f"+seed={seed}"] + extra, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    lines = [l for l in p.stdout.splitlines() if not l.startswith("VCD")]
    print(f"seed={seed}: " + "\n".join(lines))
    ok &= "EQUIV PASS" in p.stdout
sys.exit(0 if ok else 1)
