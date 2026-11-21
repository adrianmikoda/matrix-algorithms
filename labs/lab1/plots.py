# Uruchamia ./mm (skompilowany main.cpp) dla wybranych n, zapisuje results.csv,
# szacuje wykladnik zlozonosci (regresja ln T ~ alfa * ln n) i rysuje wykresy log-log.
import os, re, subprocess
import numpy as np
import matplotlib.pyplot as plt

METHODS = {"Classical": ("klasyczna", "#52514e"), "Binet": ("Binét", "#2a78d6"),
           "Strassen": ("Strassen", "#eb6834"), "Laderman": ("Laderman", "#1baf7a")}
LINE = re.compile(r"^(\w+)\s*\| time: ([\d.]+)\s+ms \| mults: (\d+)\s+\| adds: (\d+)", re.M)
FIT_FROM = 100  # dopasowanie wykladnika na wszystkich zmierzonych n >= FIT_FROM

ns = set(np.round(np.geomspace(1, 1000, 60)).astype(int))
for b in (2, 3):  # punkty tuz przed i tuz za potegami podzialu - widac skoki
    ns |= {b**k for k in range(11) if b**k <= 1000} | {b**k + 1 for k in range(1, 11) if b**k < 1000}
ns = sorted(ns)

if not os.path.exists("results.csv"):
    subprocess.run(["g++", "-O2", "-std=c++17", "main.cpp", "-o", "mm"], check=True)
    with open("results.csv", "w") as f:
        f.write("n,method,time_ms,mults,adds\n")
        for n in ns:
            best = {}
            for _ in range(3 if n <= 100 else 1):  # male n: minimum z 3 pomiarow
                out = subprocess.run(["./mm"], input=f"{n}\n", capture_output=True, text=True, check=True).stdout
                for name, t, mu, ad in LINE.findall(out):
                    if name not in best or float(t) < best[name][0]:
                        best[name] = (float(t), int(mu), int(ad))
            for name, (t, mu, ad) in best.items():
                f.write(f"{n},{name},{t},{mu},{ad}\n")
            f.flush()
            print(n, flush=True)

raw = np.genfromtxt("results.csv", delimiter=",", names=True, dtype=None, encoding=None)
data = {m: raw[raw["method"] == m] for m in METHODS}
ops = lambda d: d["mults"] + d["adds"].astype(float)

def alpha(n, y):
    ok = (n >= FIT_FROM) & (y > 0)
    return np.polyfit(np.log(n[ok]), np.log(y[ok]), 1)[0]

print(f"\nwykladnik alfa (n >= {FIT_FROM}):\nmetoda      operacje  czas")
for m, d in data.items():
    print(f"{m:10s}  {alpha(d['n'], ops(d)):.3f}     {alpha(d['n'], d['time_ms']):.3f}")

plt.rcParams.update({"font.size": 11, "axes.grid": True, "grid.alpha": 0.3,
                     "axes.spines.top": False, "axes.spines.right": False})

def plot(file, ylabel, y, loglog=True, skip_classical=False):
    fig, ax = plt.subplots(figsize=(8, 5))
    for m, (label, color) in METHODS.items():
        if skip_classical and m == "Classical":
            continue
        d = data[m]
        v = y(d)
        ok = v > 0
        style = dict(ls="--", lw=1.5, zorder=3) if m == "Classical" else dict(lw=2 if m != "Binet" else 4, marker="o", ms=3)
        a = f" ($\\alpha \\approx {alpha(d['n'], v):.2f}$)" if loglog else ""
        ax.plot(d["n"][ok], v[ok], color=color, label=label + a, **style)
    ax.set_xscale("log")
    if loglog:
        ax.set_yscale("log")
    ax.set_xlabel("Rozmiar macierzy n")
    ax.set_ylabel(ylabel)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(file, dpi=200)
    plt.close(fig)

plot("execution_time.png", "Czas działania [ms]", lambda d: d["time_ms"])
plot("flops.png", "Liczba operacji", ops)
plot("multiplications.png", "Liczba mnożeń", lambda d: d["mults"].astype(float))
plot("additions_and_subtractions.png", "Liczba dodawań i odejmowań", lambda d: d["adds"].astype(float))
plot("flops_ratio.png", "Operacje / operacje metody klasycznej",
     lambda d: ops(d) / ops(data["Classical"]), loglog=False, skip_classical=True)
