#!/usr/bin/env python3
"""Push figures/captions.json into the \\caption{} blocks of drafts/paper.tex.

Each figure in paper.tex is matched to a caption by its \\includegraphics filename
(fig_<id>.png  ->  captions.json key "fig_<id>"). Run this whenever you edit
captions.json, then recompile paper.tex. Only \\caption lines are touched; all
other edits to paper.tex are preserved.
"""
import json, os, re

root = os.path.dirname(os.path.abspath(__file__))
caps = json.load(open(os.path.join(root, "figures", "captions.json")))
tex_path = os.path.join(root, "drafts", "paper.tex")

def italicize(t):
    t = t.replace("Escherichia coli", r"\textit{Escherichia coli}")
    t = re.sub(r"(?<!\{)\bE\. coli\b", r"\\textit{E. coli}", t)  # standalone, not already wrapped
    return t

lines = open(tex_path).read().split("\n")
cur, out, n = None, [], 0
for ln in lines:
    m = re.search(r"\{(fig_[a-z0-9_]+)\.png\}", ln)
    if m:
        cur = m.group(1)
    if re.match(r"^\s*\\caption\{", ln) and cur in caps:
        out.append(r"\caption{" + italicize(caps[cur]) + "}")
        n += 1
        cur = None
    else:
        out.append(ln)

open(tex_path, "w").write("\n".join(out))
print(f"synced {n} captions into {os.path.relpath(tex_path, root)}")
