if (!exists("outfile")) outfile='c_paper/out/experiments/04_copy_probability/plots/copy_probability_fig4_pp.png'

set terminal pngcairo size 1600,850 enhanced font 'Times New Roman,22'
set output outfile

set datafile separator whitespace
set multiplot layout 1,2 margins 0.07,0.965,0.13,0.86 spacing 0.07,0.03

set border lw 1.4
set tics out nomirror
set grid xtics ytics lw 0.5 lc rgb '#dddddd'
set xrange [1:3]
set yrange [0:1.02]
set xlabel 'b'
set ylabel 'x_1'
set key opaque box at graph 0.98, graph 0.98 samplen 1.5 spacing 1.05 title 'p_{12}'

set style line 1 lc rgb '#222222' lw 3.0
set style line 2 lc rgb '#1f77b4' lw 3.0
set style line 3 lc rgb '#1b8a5a' lw 3.0
set style line 4 lc rgb '#d95f02' lw 3.0
set style line 5 lc rgb '#7b3294' lw 3.0

fermi='c_paper/out/experiments/04_copy_probability/fermi/sweep_b_fig4/sweep_b_fig4_fermi_beta_5_full_2026-05-07_run2/raw/'
degree='c_paper/out/experiments/04_copy_probability/degree_linear/raw/'

set title 'Fermi, {/Symbol b}=5  |  N_1=1000, N_2=100, k=6' font ',21'
plot \
  fermi.'fig4_fermi_beta_5_p12_0.tsv' using 1:2 with lines ls 1 title '0', \
  fermi.'fig4_fermi_beta_5_p12_0p005.tsv' using 1:2 with lines ls 2 title '0.005', \
  fermi.'fig4_fermi_beta_5_p12_0p02.tsv' using 1:2 with lines ls 3 title '0.02', \
  fermi.'fig4_fermi_beta_5_p12_0p04.tsv' using 1:2 with lines ls 4 title '0.04'

unset ylabel
set title 'Lineal en grado, {/Symbol a}=1  |  N_1=1000, N_2=100, k=6' font ',21'
plot \
  degree.'fig4_degree_paper_p_alpha_1_p12_0.tsv' using 1:2 with lines ls 1 title '0', \
  degree.'fig4_degree_paper_p_alpha_1_p12_0p005.tsv' using 1:2 with lines ls 2 title '0.005', \
  degree.'fig4_degree_paper_p_alpha_1_p12_0p02.tsv' using 1:2 with lines ls 3 title '0.02', \
  degree.'fig4_degree_paper_p_alpha_1_p12_0p04.tsv' using 1:2 with lines ls 4 title '0.04'

unset multiplot
