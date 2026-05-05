# Plot the independent sweep_b experiment TSV files.
#
# Usage from the repository root:
# gnuplot c_paper/out/gp/plot_sweep_b_experiment.gp
#
# Optional:
# gnuplot -e "expdir='c_paper/out/experiments/sweep_b_2026-05-04_escalated_parallel_independent'" c_paper/out/gp/plot_sweep_b_experiment.gp
#
# Input TSV columns:
# b  x1_mean  x1_sem  x2_mean  x2_sem  c_mean  c_sem

if (!exists("expdir")) {
    expdir = "c_paper/out/experiments/sweep_b_2026-05-04_escalated_parallel_independent"
}

rawdir = expdir . "/raw"
plotdir = expdir . "/plots_gnuplot"
system(sprintf("powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path '%s' | Out-Null\"", plotdir))

set terminal pngcairo size 1200,850 enhanced font "Times New Roman,24"
set datafile commentschars "#"

set xlabel "b"
set yrange [0:1]
set tics in
set mxtics 2
set mytics 2
set border linewidth 1.5
set key outside right title "p_{12}"
set grid xtics ytics lc rgb "#dddddd" lw 1

set style line 1 lc rgb "black"   lw 4 dt 1
set style line 2 lc rgb "#3155b7" lw 3 dt 1
set style line 3 lc rgb "#ff4b4b" lw 3 dt 1
set style line 4 lc rgb "#009e54" lw 3 dt 2
set style line 5 lc rgb "#c44eaa" lw 3 dt 4
set style line 6 lc rgb "#7a174f" lw 3 dt 5
set style line 7 lc rgb "#7b55c7" lw 3 dt 3
set style line 8 lc rgb "#e68613" lw 3 dt 1
set style line 9 lc rgb "#00a6a6" lw 3 dt 2

set style fill transparent solid 0.14 noborder

f3_0     = rawdir . "/fig3_paper_p12_0.tsv"
f3_0001  = rawdir . "/fig3_paper_p12_0p001.tsv"
f3_0002  = rawdir . "/fig3_paper_p12_0p002.tsv"
f3_0005  = rawdir . "/fig3_paper_p12_0p005.tsv"
f3_001   = rawdir . "/fig3_paper_p12_0p01.tsv"
f3_002   = rawdir . "/fig3_paper_p12_0p02.tsv"
f3_004   = rawdir . "/fig3_paper_p12_0p04.tsv"

f4_0     = rawdir . "/fig4_paper_p12_0.tsv"
f4_0001  = rawdir . "/fig4_paper_p12_0p001.tsv"
f4_0002  = rawdir . "/fig4_paper_p12_0p002.tsv"
f4_0005  = rawdir . "/fig4_paper_p12_0p005.tsv"
f4_001   = rawdir . "/fig4_paper_p12_0p01.tsv"
f4_002   = rawdir . "/fig4_paper_p12_0p02.tsv"
f4_004   = rawdir . "/fig4_paper_p12_0p04.tsv"

fs_004   = rawdir . "/fig4_strong_coupling_p12_0p04.tsv"
fs_006   = rawdir . "/fig4_strong_coupling_p12_0p06.tsv"
fs_008   = rawdir . "/fig4_strong_coupling_p12_0p08.tsv"
fs_010   = rawdir . "/fig4_strong_coupling_p12_0p1.tsv"
fs_015   = rawdir . "/fig4_strong_coupling_p12_0p15.tsv"

set output plotdir . "/fig3_paper_c_mean.png"
set title "Fig. 3 parameters: global cooperation"
set ylabel "c"
set xrange [1:3]
plot \
f3_0    using 1:($6-$7):($6+$7) with filledcurves ls 1 notitle, \
f3_0001 using 1:($6-$7):($6+$7) with filledcurves ls 2 notitle, \
f3_0002 using 1:($6-$7):($6+$7) with filledcurves ls 3 notitle, \
f3_0005 using 1:($6-$7):($6+$7) with filledcurves ls 4 notitle, \
f3_001  using 1:($6-$7):($6+$7) with filledcurves ls 5 notitle, \
f3_002  using 1:($6-$7):($6+$7) with filledcurves ls 6 notitle, \
f3_004  using 1:($6-$7):($6+$7) with filledcurves ls 7 notitle, \
f3_0    using 1:6 with lines ls 1 title "0", \
f3_0001 using 1:6 with lines ls 2 title "0.001", \
f3_0002 using 1:6 with lines ls 3 title "0.002", \
f3_0005 using 1:6 with lines ls 4 title "0.005", \
f3_001  using 1:6 with lines ls 5 title "0.01", \
f3_002  using 1:6 with lines ls 6 title "0.02", \
f3_004  using 1:6 with lines ls 7 title "0.04"

set output plotdir . "/fig4_paper_x1_mean.png"
set title "Fig. 4 parameters: population 1 cooperation"
set ylabel "c_1"
set xrange [1:4]
plot \
f4_0    using 1:($2-$3):($2+$3) with filledcurves ls 1 notitle, \
f4_0001 using 1:($2-$3):($2+$3) with filledcurves ls 2 notitle, \
f4_0002 using 1:($2-$3):($2+$3) with filledcurves ls 3 notitle, \
f4_0005 using 1:($2-$3):($2+$3) with filledcurves ls 4 notitle, \
f4_001  using 1:($2-$3):($2+$3) with filledcurves ls 5 notitle, \
f4_002  using 1:($2-$3):($2+$3) with filledcurves ls 6 notitle, \
f4_004  using 1:($2-$3):($2+$3) with filledcurves ls 7 notitle, \
f4_0    using 1:2 with lines ls 1 title "0", \
f4_0001 using 1:2 with lines ls 2 title "0.001", \
f4_0002 using 1:2 with lines ls 3 title "0.002", \
f4_0005 using 1:2 with lines ls 4 title "0.005", \
f4_001  using 1:2 with lines ls 5 title "0.01", \
f4_002  using 1:2 with lines ls 6 title "0.02", \
f4_004  using 1:2 with lines ls 7 title "0.04"

set output plotdir . "/fig4_strong_coupling_x1_mean.png"
set title "Fig. 4 geometry with stronger coupling"
set ylabel "c_1"
set xrange [1:5]
plot \
fs_004 using 1:($2-$3):($2+$3) with filledcurves ls 1 notitle, \
fs_006 using 1:($2-$3):($2+$3) with filledcurves ls 2 notitle, \
fs_008 using 1:($2-$3):($2+$3) with filledcurves ls 3 notitle, \
fs_010 using 1:($2-$3):($2+$3) with filledcurves ls 4 notitle, \
fs_015 using 1:($2-$3):($2+$3) with filledcurves ls 5 notitle, \
fs_004 using 1:2 with lines ls 1 title "0.04", \
fs_006 using 1:2 with lines ls 2 title "0.06", \
fs_008 using 1:2 with lines ls 3 title "0.08", \
fs_010 using 1:2 with lines ls 4 title "0.10", \
fs_015 using 1:2 with lines ls 5 title "0.15"

set output plotdir . "/fig4_paper_vs_strong_x1_mean.png"
set title "Fig. 4: paper coupling and stronger coupling"
set ylabel "c_1"
set xrange [1:5]
set key outside right title "family, p_{12}"
plot \
f4_0    using 1:2 with lines ls 1 title "paper 0", \
f4_0001 using 1:2 with lines ls 2 title "paper 0.001", \
f4_0002 using 1:2 with lines ls 3 title "paper 0.002", \
f4_0005 using 1:2 with lines ls 4 title "paper 0.005", \
f4_001  using 1:2 with lines ls 5 title "paper 0.01", \
f4_002  using 1:2 with lines ls 6 title "paper 0.02", \
f4_004  using 1:2 with lines ls 7 title "paper 0.04", \
fs_004  using 1:2 with lines ls 1 dt 2 title "strong 0.04", \
fs_006  using 1:2 with lines ls 2 dt 2 title "strong 0.06", \
fs_008  using 1:2 with lines ls 3 dt 2 title "strong 0.08", \
fs_010  using 1:2 with lines ls 4 dt 2 title "strong 0.10", \
fs_015  using 1:2 with lines ls 5 dt 2 title "strong 0.15"
