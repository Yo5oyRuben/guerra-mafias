# Horizontal reconstruction of paper Fig. 3 with an extra coupling-effect panel.
#
# Usage from repository root:
# gnuplot c_paper/out/gp/plot_fig3_horizontal.gp
#
# Optional:
# gnuplot -e "expdir='c_paper/out/experiments/01_paper_baselines'; outfile='.../fig3_horizontal.png'" c_paper/out/gp/plot_fig3_horizontal.gp

if (!exists("expdir")) {
    expdir = "c_paper/out/experiments/01_paper_baselines"
}
if (!exists("outfile")) {
    outfile = expdir . "/plots/fig3_horizontal_curves_x1.png"
}

rawdir = expdir . "/raw"
plotdir = expdir . "/plots"
combined = expdir . "/plots/_fig3_horizontal_combined.tmp"
system(sprintf("powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path '%s' | Out-Null\"", plotdir))
system(sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_fig3_horizontal.ps1 -ExpDir \"%s\" -Combined \"%s\"", expdir, combined))

f0    = rawdir . "/fig3_paper_p12_0.tsv"
f0001 = rawdir . "/fig3_paper_p12_0p001.tsv"
f0002 = rawdir . "/fig3_paper_p12_0p002.tsv"
f0005 = rawdir . "/fig3_paper_p12_0p005.tsv"
f001  = rawdir . "/fig3_paper_p12_0p01.tsv"
f002  = rawdir . "/fig3_paper_p12_0p02.tsv"
f004  = rawdir . "/fig3_paper_p12_0p04.tsv"

set terminal pngcairo size 1700,950 enhanced font "Arial,20"
set output outfile
set datafile commentschars "#"

set encoding utf8
set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#dddddd" lw 1

set style line 1 lc rgb "#111111" lw 3.8 dt 1
set style line 2 lc rgb "#313695" lw 3.0 dt 1
set style line 3 lc rgb "#4575b4" lw 3.0 dt 1
set style line 4 lc rgb "#74add1" lw 3.0 dt 1
set style line 5 lc rgb "#fdae61" lw 3.0 dt 1
set style line 6 lc rgb "#f46d43" lw 3.0 dt 1
set style line 7 lc rgb "#a50026" lw 3.0 dt 1

set style fill transparent solid 0.13 noborder

set multiplot layout 2,1 margins screen 0.085,0.815,0.120,0.925 spacing screen 0.035

set xrange [1:3]
set yrange [0:1.04]
set format x ""
set ylabel "c"
set key at screen 0.965,0.805 right top title "p12" font "Arial,18" spacing 1.18 samplen 2.4 box lw 1.4 lc rgb "black" opaque
set title "Reconstruccion de la Fig. 3: cooperacion global y cooperacion en la red 1" font "Arial,21"

plot \
    f0    using 1:($6-$7):($6+$7) with filledcurves ls 1 notitle, \
    f0001 using 1:($6-$7):($6+$7) with filledcurves ls 2 notitle, \
    f0002 using 1:($6-$7):($6+$7) with filledcurves ls 3 notitle, \
    f0005 using 1:($6-$7):($6+$7) with filledcurves ls 4 notitle, \
    f001  using 1:($6-$7):($6+$7) with filledcurves ls 5 notitle, \
    f002  using 1:($6-$7):($6+$7) with filledcurves ls 6 notitle, \
    f004  using 1:($6-$7):($6+$7) with filledcurves ls 7 notitle, \
    f0    using 1:6 with lines ls 1 title "0", \
    f0001 using 1:6 with lines ls 2 title "0.001", \
    f0002 using 1:6 with lines ls 3 title "0.002", \
    f0005 using 1:6 with lines ls 4 title "0.005", \
    f001  using 1:6 with lines ls 5 title "0.01", \
    f002  using 1:6 with lines ls 6 title "0.02", \
    f004  using 1:6 with lines ls 7 title "0.04"

unset title
unset key
set format x "%g"
set xlabel "b"
set ylabel "x_1"
set yrange [0:1.04]
unset yzeroaxis

plot \
    f0    using 1:2 with lines ls 1 notitle, \
    f0001 using 1:2 with lines ls 2 notitle, \
    f0002 using 1:2 with lines ls 3 notitle, \
    f0005 using 1:2 with lines ls 4 notitle, \
    f001  using 1:2 with lines ls 5 notitle, \
    f002  using 1:2 with lines ls 6 notitle, \
    f004  using 1:2 with lines ls 7 notitle

unset multiplot
