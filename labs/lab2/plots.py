# Kompiluje main.cpp, uruchamia ./lab2 n dla wybranych n (-> results.csv) i rysuje wykresy log-log.
import os, subprocess
import numpy as np
import matplotlib.pyplot as plt

if not os.path.exists("results.csv"):
    subprocess.run(["g++-15", "-O2", "-std=c++20", "main.cpp", "-o", "lab2"], check=True)
    with open("results.csv", "w") as f:
        f.write("n,method,time_ms,flops,error\n")
        for n in sorted(set(np.round(np.geomspace(1, 1000, 50)).astype(int))):
            f.write(subprocess.run(["./lab2", str(n)], capture_output=True, text=True, check=True).stdout)
            f.flush()
            print(n, flush=True)

d = np.genfromtxt("results.csv", delimiter=",", names=True, dtype=None, encoding=None)
for col, label, file in [("time_ms", "Czas działania [ms]", "time.png"),
                         ("flops", "Liczba operacji zmiennoprzecinkowych", "flops.png")]:
    fig, ax = plt.subplots(figsize=(8, 5))
    for m in dict.fromkeys(d["method"]):
        s = d[(d["method"] == m) & (d[col] > 0)]  # log nie pokaze zera
        ax.loglog(s["n"], s[col], marker="o", ms=3, label=m)
    ax.set_xlabel("Rozmiar macierzy n")
    ax.set_ylabel(label)
    ax.grid(alpha=0.3)
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(file, dpi=200)
