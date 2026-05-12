if (!exists("outfile")) outfile='c_paper/out/experiments/04_copy_probability/plots/degree_alpha_sweep_fig4_pp.png'

set terminal pngcairo size 1100,800 enhanced font 'Times New Roman,22'
set output outfile

set datafile separator whitespace
set border lw 1.4
set tics out nomirror
set grid xtics ytics lw 0.5 lc rgb '#dddddd'
set xrange [1:3]
set yrange [0:1.02]
set xlabel 'b'
set ylabel 'x_1'
set key opaque box at graph 0.98, graph 0.98 samplen 1.5 spacing 1.05 title '{/Symbol a}'
set title 'Lineal en grado: barrido de {/Symbol a}  |  p_{12}=0.1, N_1=1000, N_2=100, k=6' font ',20'

set style line 1 lc rgb '#1f77b4' lw 3.0
set style line 2 lc rgb '#1b8a5a' lw 3.0
set style line 3 lc rgb '#d95f02' lw 3.0
set style line 4 lc rgb '#7b3294' lw 3.0

raw='c_paper/out/experiments/04_copy_probability/degree_linear/raw/'

plot \
  raw.'fig4_degree_alpha_sweep_p0p1_alpha_1_p12_0p1.tsv' using 1:2 with lines ls 1 title '1', \
  raw.'fig4_degree_alpha_sweep_p0p1_alpha_2_p12_0p1.tsv' using 1:2 with lines ls 2 title '2', \
  raw.'fig4_degree_alpha_sweep_p0p1_alpha_5_p12_0p1.tsv' using 1:2 with lines ls 3 title '5', \
  raw.'fig4_degree_alpha_sweep_p0p1_alpha_10_p12_0p1.tsv' using 1:2 with lines ls 4 title '10'
