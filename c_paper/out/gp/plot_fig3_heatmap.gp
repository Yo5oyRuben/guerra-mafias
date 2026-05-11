# Heatmap view of paper Fig. 3 reconstruction.
#
# Usage:
# gnuplot c_paper/out/gp/plot_fig3_heatmap.gp

if (!exists("expdir")) {
    expdir = "c_paper/out/experiments/01_paper_baselines"
}
if (!exists("outfile")) {
    outfile = expdir . "/plots/fig3_horizontal_heatmap.png"
}

plotdir = expdir . "/plots"
combined = expdir . "/plots/_fig3_horizontal_combined.tmp"
system(sprintf("powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path '%s' | Out-Null\"", plotdir))
system(sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_fig3_horizontal.ps1 -ExpDir \"%s\" -Combined \"%s\"", expdir, combined))

set terminal pngcairo size 1650,720 enhanced font "Arial,20"
set output outfile
set datafile commentschars "#"

set xlabel "b"
set ylabel "p12"
set cblabel "c"
set xrange [1:3]
set yrange [-0.001:0.041]
set cbrange [0:1]
set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#eeeeee" lw 1
set size ratio 0.32
set title "Reconstruccion de la Fig. 3 como mapa de cooperacion" font "Arial,22"

set palette defined (0 "#313695", 0.25 "#74add1", 0.5 "#ffffbf", 0.75 "#f46d43", 1 "#a50026")
set colorbox user origin screen 0.875,0.190 size screen 0.030,0.650

plot combined using 1:2:3 with image notitle
