if (!exists("infile")) infile='c_paper/out/experiments/03_critical_transition/summary_plots/critical_phase_transition_summary.tsv'
if (!exists("outfile")) outfile='c_paper/out/experiments/03_critical_transition/summary_plots/critical_phase_transition.png'

set terminal pngcairo size 1500,850 enhanced font 'Times New Roman,24'
set output outfile

set datafile separator '\t'
set key opaque box samplen 1.6 spacing 1.15 width 0.5 at graph 0.985, graph 0.965
set border lw 1.5
set tics out nomirror scale 0.8
set grid xtics ytics lw 0.5 lc rgb '#d8d8d8'

set xlabel 'p_{11}=p_{22}'
set ylabel '<d(E)>'
set y2label '<t_{relax}>/T_{MAX}'
set y2tics 0,0.2,1
set ytics nomirror
set yrange [0.2:0.6]
set y2range [0:0.5]
set xrange [0.64:0.91]

set title 'Transicion hacia el limite analitico  |  N_1=N_2=500, p_{12}=0.20, b=1.15, r=0, e=-0.4' font ',22'

set style line 1 lc rgb '#1f4e8c' lw 2.6 dt 2 pt 7 ps 1.25
set style line 2 lc rgb '#d05a1f' lw 2.4 dt 2 pt 5 ps 1.15
set style line 3 lc rgb '#8c8c8c' lw 1.8 dt 2
set style line 4 lc rgb '#111111' lw 1.2 pt 13 ps 0.8

set object 1 rect from graph 0,0 to graph 1,1 behind fc rgb '#ffffff' fs solid 1.0 noborder

plot \
  infile every ::1 using 1:13:14 with yerrorlines ls 1 title '<d(E)>', \
  infile every ::1 using 1:15:16 axes x1y2 with yerrorlines ls 2 title '<t_{relax}>/T_{MAX}', \
  infile every ::1 using 1:17 axes x1y2 with lines ls 3 title 'fraccion saturada'
