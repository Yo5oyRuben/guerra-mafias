import re
import subprocess
from pathlib import Path
base = Path(r'c:\Users\rbndz\Movistar Cloud\Ruben\3_FISICA\2_Cuatrimestre\Caos_y_SDNL\guerra-mafias')
manifest = base / Path('c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling/plots/initial_plane_new_style_plots.tsv')
plots = base / Path('c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling/plots')
script = base / Path('c_paper/out/gp/plot_initial_plane.gp')

lines = manifest.read_text(encoding='utf-8').strip().splitlines()
entries = []
for line in lines[1:]:
    if not line.strip():
        continue
    cols = line.split('\t')
    if len(cols) < 2:
        continue
    plot_rel = cols[0].strip()
    data_rel = cols[1].strip()
    tmax = None
    if len(cols) >= 3 and cols[2].strip():
        try:
            tmax = int(cols[2].strip())
        except ValueError:
            pass
    entries.append((plot_rel, data_rel, tmax))

missing = []
for plot_rel, data_rel, tmax in entries:
    raw_path = base / Path(data_rel)
    expected_plot = base / Path(plot_rel)
    raw_plot = raw_path.with_suffix('.png')
    if expected_plot.exists() or raw_plot.exists():
        continue
    missing.append((expected_plot, raw_path, tmax))

print('missing_from_manifest', len(missing))
for expected_plot, raw_path, tmax in missing:
    infile = Path(raw_path).relative_to(base).as_posix()
    outfile = expected_plot.relative_to(base).as_posix()
    if tmax is None:
        # try to read from header if missing in manifest
        with raw_path.open('r', encoding='utf-8', errors='ignore') as f:
            for line in f:
                m = re.match(r'^#\s*T_MAX\s+(\d+)', line)
                if m:
                    tmax = int(m.group(1))
                    break
    if tmax is None:
        m = re.search(r'TMAX_([0-9]+)', raw_path.name)
        if m:
            tmax = int(m.group(1))
    if tmax is None:
        expr = f"infile='{infile}'; outfile='{outfile}'"
    else:
        expr = f"tmax={tmax}; infile='{infile}'; outfile='{outfile}'"
    print('generating', raw_path.name, '->', expected_plot.name, 'tmax', tmax)
    subprocess.run(['gnuplot', '-e', expr, str(script)], check=True)
print('done')
