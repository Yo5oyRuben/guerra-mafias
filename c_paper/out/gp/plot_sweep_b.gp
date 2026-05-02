# Plot one sweep_b family written by print_c_p12.
#
# Usage from the repository root:
# gnuplot -e "infile='c_paper/out/raw/sweep_b/sweep_b_E_-4_R_0_k11_6_k22_6_N_1100.txt'; outfile='c_paper/out/plots/sweep_b/sweep_b_E_-4_R_0_k11_6_k22_6_N_1100.png'" c_paper/out/gp/plot_sweep_b.gp
#
# Example input format:
# p12
# b    <c>    error
# ...
# blank line
# next p12 block

if (!exists("infile")) {
    infile = "c_paper/out/raw/sweep_b/sweep_b_E_-0.4_R_0_k11_6_k22_6_N_2000.txt"
}

if (!exists("outfile")) {
    outfile = "c_paper/out/plots/sweep_b/sweep_b.png"
}

set terminal pngcairo size 1200,850 enhanced font "Times New Roman,24"
set output outfile

set xlabel "b"
set ylabel "c1"

set xrange [1:3]
set yrange [0:1]

set key outside right title "p_{12}"
set tics in
set mxtics 2
set mytics 2
set border linewidth 1.5

set style line 1 lc rgb "black"   lw 4 dt 1
set style line 2 lc rgb "#3155b7" lw 2 dt 1
set style line 3 lc rgb "#ff4b4b" lw 2 dt 1
set style line 4 lc rgb "#009e54" lw 2 dt 2
set style line 5 lc rgb "#c44eaa" lw 2 dt 4
set style line 6 lc rgb "#7a174f" lw 2 dt 5
set style line 7 lc rgb "#7b55c7" lw 2 dt 3

plot \
infile every :::0::0 using 1:2 with lines ls 1 title "0", \
infile every :::1::1 using 1:2 with lines ls 2 title "0.001", \
infile every :::2::2 using 1:2 with lines ls 3 title "0.002", \
infile every :::3::3 using 1:2 with lines ls 4 title "0.005", \
infile every :::4::4 using 1:2 with lines ls 5 title "0.01", \
infile every :::5::5 using 1:2 with lines ls 6 title "0.02", \
infile every :::6::6 using 1:2 with lines ls 7 title "0.04"
