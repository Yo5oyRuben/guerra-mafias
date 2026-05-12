# Side-by-side presentation figure: reconstructed Fig. 3 and Fig. 4.
#
# Usage:
# gnuplot c_paper/out/gp/plot_fig3_fig4_side_by_side.gp

if (!exists("expdir")) {
    expdir = "c_paper/out/experiments/01_paper_baselines"
}
if (!exists("outfile")) {
    outfile = expdir . "/plots/fig3_fig4_side_by_side.png"
}

rawdir = expdir . "/raw"
plotdir = expdir . "/plots"
system(sprintf("powershell -NoProfile -Command \"New-Item -ItemType Directory -Force -Path '%s' | Out-Null\"", plotdir))

f3_0    = rawdir . "/fig3_paper_p12_0.tsv"
f3_0001 = rawdir . "/fig3_paper_p12_0p001.tsv"
f3_0002 = rawdir . "/fig3_paper_p12_0p002.tsv"
f3_0005 = rawdir . "/fig3_paper_p12_0p005.tsv"
f3_001  = rawdir . "/fig3_paper_p12_0p01.tsv"
f3_002  = rawdir . "/fig3_paper_p12_0p02.tsv"
f3_004  = rawdir . "/fig3_paper_p12_0p04.tsv"

f4_0001 = rawdir . "/fig4_paper_p12_0p001.tsv"
f4_0002 = rawdir . "/fig4_paper_p12_0p002.tsv"
f4_0005 = rawdir . "/fig4_paper_p12_0p005.tsv"
f4_001  = rawdir . "/fig4_paper_p12_0p01.tsv"
f4_002  = rawdir . "/fig4_paper_p12_0p02.tsv"
f4_004  = rawdir . "/fig4_paper_p12_0p04.tsv"
f4_006  = rawdir . "/fig4_strong_coupling_p12_0p06.tsv"
f4_008  = rawdir . "/fig4_strong_coupling_p12_0p08.tsv"
f4_010  = rawdir . "/fig4_strong_coupling_p12_0p1.tsv"

set terminal pngcairo size 1750,850 noenhanced font "Verdana,17"
set output outfile
set datafile commentschars "#"

set tics in
set mxtics 4
set mytics 2
set border linewidth 1.35
set grid xtics ytics lc rgb "#ececec" lw 1

set style line 1  lc rgb "#111111" lw 3.2 dt 1
set style line 2  lc rgb "#313695" lw 2.8 dt 1
set style line 3  lc rgb "#4575b4" lw 2.8 dt 1
set style line 4  lc rgb "#74add1" lw 2.8 dt 1
set style line 5  lc rgb "#abd9e9" lw 2.8 dt 1
set style line 6  lc rgb "#fdae61" lw 2.8 dt 1
set style line 7  lc rgb "#f46d43" lw 2.8 dt 1
set style line 8  lc rgb "#d73027" lw 2.9 dt 1
set style line 9  lc rgb "#b2182b" lw 3.0 dt 1
set style line 10 lc rgb "#7f0000" lw 3.1 dt 1

set multiplot

# Panel headers.
set label 101 "Fig. 3\nN1=N2=1000; k11=k22=6; x1(0)=x2(0)=0.5\nreps=30; TMAX=50000" at screen 0.265,0.970 center font "Verdana,12" front
set label 102 "Fig. 4\nN1=1000; N2=100; k11=k22=6; x1(0)=0.5; x2(0)=0\nreps=30; TMAX=50000" at screen 0.705,0.970 center font "Verdana,12" front

# Left panel: Fig. 3, global cooperation.
set lmargin at screen 0.075
set rmargin at screen 0.445
set bmargin at screen 0.135
set tmargin at screen 0.835
set xrange [1:3]
set yrange [0:1.04]
set xlabel "b"
set ylabel "c"
unset key

plot \
    f3_0    using 1:6 with lines ls 1 notitle, \
    f3_0001 using 1:6 with lines ls 2 notitle, \
    f3_0002 using 1:6 with lines ls 3 notitle, \
    f3_0005 using 1:6 with lines ls 4 notitle, \
    f3_001  using 1:6 with lines ls 5 notitle, \
    f3_002  using 1:6 with lines ls 6 notitle, \
    f3_004  using 1:6 with lines ls 7 notitle

# Right panel: Fig. 4, cooperation in network 1.
set lmargin at screen 0.525
set rmargin at screen 0.885
set bmargin at screen 0.135
set tmargin at screen 0.835
set xlabel "b"
set ylabel "x1"
set key at screen 0.985,0.815 right top title "p12" font "Verdana,15" spacing 1.08 samplen 2.0 box lw 1.3 lc rgb "black" opaque

plot \
    1/0 with lines ls 1 title "0", \
    f4_0001 using 1:2 every ::0::100 with lines ls 2 title "0.001", \
    f4_0002 using 1:2 every ::0::100 with lines ls 3 title "0.002", \
    f4_0005 using 1:2 every ::0::100 with lines ls 4 title "0.005", \
    f4_001  using 1:2 every ::0::100 with lines ls 5 title "0.01", \
    f4_002  using 1:2 every ::0::100 with lines ls 6 title "0.02", \
    f4_004  using 1:2 every ::0::100 with lines ls 7 title "0.04", \
    f4_006  using 1:2 every ::0::100 with lines ls 8 title "0.06", \
    f4_008  using 1:2 every ::0::100 with lines ls 9 title "0.08", \
    f4_010  using 1:2 every ::0::100 with lines ls 10 title "0.10"

unset multiplot
