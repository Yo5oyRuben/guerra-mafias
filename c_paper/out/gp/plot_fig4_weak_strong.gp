# Paper Fig. 4 reconstruction with weak and stronger inter-network coupling.
#
# Uses paper-baseline weak-coupling files and strong-coupling files, plotted
# together up to b=3 for presentation slides.
#
# Usage:
# gnuplot c_paper/out/gp/plot_fig4_weak_strong.gp

if (!exists("expdir")) {
    expdir = "c_paper/out/experiments/01_paper_baselines"
}
if (!exists("outfile")) {
    outfile = expdir . "/plots/fig4_weak_strong_x1_bmax3.png"
}

rawdir = expdir . "/raw"
plotdir = expdir . "/plots"
system(sprintf("powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path '%s' | Out-Null\"", plotdir))

f0001 = rawdir . "/fig4_paper_p12_0p001.tsv"
f0002 = rawdir . "/fig4_paper_p12_0p002.tsv"
f0005 = rawdir . "/fig4_paper_p12_0p005.tsv"
f001  = rawdir . "/fig4_paper_p12_0p01.tsv"
f002  = rawdir . "/fig4_paper_p12_0p02.tsv"
f004  = rawdir . "/fig4_paper_p12_0p04.tsv"
f006  = rawdir . "/fig4_strong_coupling_p12_0p06.tsv"
f008  = rawdir . "/fig4_strong_coupling_p12_0p08.tsv"
f010  = rawdir . "/fig4_strong_coupling_p12_0p1.tsv"

set terminal pngcairo size 1650,900 noenhanced font "Verdana,18"
set output outfile
set datafile commentschars "#"

set xlabel "b"
set ylabel "x1"
set xrange [1:3]
set yrange [0:1.04]
set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#e8e8e8" lw 1
set title "Reconstruccion de la Fig. 4: acoplos debiles y fuertes" font "Verdana,21"

set style line 1 lc rgb "#313695" lw 3.2 dt 1
set style line 2 lc rgb "#4575b4" lw 3.2 dt 1
set style line 3 lc rgb "#74add1" lw 3.2 dt 1
set style line 4 lc rgb "#abd9e9" lw 3.2 dt 1
set style line 5 lc rgb "#fdae61" lw 3.2 dt 1
set style line 6 lc rgb "#f46d43" lw 3.2 dt 1
set style line 7 lc rgb "#d73027" lw 3.4 dt 1
set style line 8 lc rgb "#b2182b" lw 3.4 dt 1
set style line 9 lc rgb "#7f0000" lw 3.6 dt 1

set style fill transparent solid 0.10 noborder
set key at screen 0.965,0.815 right top title "p12" font "Verdana,16" spacing 1.15 samplen 2.4 box lw 1.4 lc rgb "black" opaque
set rmargin at screen 0.815
set lmargin at screen 0.090
set tmargin at screen 0.900
set bmargin at screen 0.120

plot \
    f0001 using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 1 notitle, \
    f0002 using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 2 notitle, \
    f0005 using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 3 notitle, \
    f001  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 4 notitle, \
    f002  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 5 notitle, \
    f004  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 6 notitle, \
    f006  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 7 notitle, \
    f008  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 8 notitle, \
    f010  using 1:($2-$3):($2+$3) every ::0::100 with filledcurves ls 9 notitle, \
    f0001 using 1:2 every ::0::100 with lines ls 1 title "0.001", \
    f0002 using 1:2 every ::0::100 with lines ls 2 title "0.002", \
    f0005 using 1:2 every ::0::100 with lines ls 3 title "0.005", \
    f001  using 1:2 every ::0::100 with lines ls 4 title "0.01", \
    f002  using 1:2 every ::0::100 with lines ls 5 title "0.02", \
    f004  using 1:2 every ::0::100 with lines ls 6 title "0.04", \
    f006  using 1:2 every ::0::100 with lines ls 7 title "0.06", \
    f008  using 1:2 every ::0::100 with lines ls 8 title "0.08", \
    f010  using 1:2 every ::0::100 with lines ls 9 title "0.10"
