if (!exists("curves")) curves='c_paper/out/experiments/03_critical_transition/summary_plots/critical_frontier_curves.tsv'
if (!exists("frontier")) frontier='c_paper/out/experiments/03_critical_transition/summary_plots/critical_frontier_pc.tsv'
if (!exists("outfile")) outfile='c_paper/out/experiments/03_critical_transition/summary_plots/critical_frontier_curves.png'

set terminal pngcairo size 1700,900 enhanced font 'Times New Roman,22'
set output outfile
set datafile separator '\t'

set multiplot layout 1,2 margins 0.07,0.94,0.13,0.86 spacing 0.085,0.04

set border lw 1.4
set tics out nomirror
set grid xtics ytics lw 0.5 lc rgb '#dddddd'
set style line 1 lc rgb '#264f9e' lw 2.2 dt 2 pt 7 ps 1.05
set style line 2 lc rgb '#1b8a5a' lw 2.2 dt 2 pt 5 ps 1.05
set style line 3 lc rgb '#d05a1f' lw 2.2 dt 2 pt 9 ps 1.05
set style line 4 lc rgb '#7b3294' lw 2.2 dt 2 pt 13 ps 1.05
set style line 5 lc rgb '#111111' lw 1.7 dt 2 pt 11 ps 0.9
set style line 6 lc rgb '#a63603' lw 2.0 dt 2 pt 3 ps 1.0

set label 100 'N_1=N_2=500, b=1.15, r=0, e=-0.4' at screen 0.5,0.94 center font ',22'

set title 'Distancia al punto fijo E' font ',21'
set xlabel 'p_{11} = p_{22}'
set ylabel '<d(E)>'
set xrange [0.63:0.91]
set yrange [0.2:0.7]
set key opaque box at graph 0.98, graph 0.98 samplen 1.5 spacing 1.05 title 'p_{12}'

plot \
  curves every ::1 using (($2==0.16)?$1:1/0):3:4 with yerrorlines ls 1 title '0.16', \
  curves every ::1 using (($2==0.20)?$1:1/0):3:4 with yerrorlines ls 2 title '0.20', \
  curves every ::1 using (($2==0.21)?$1:1/0):3:4 with yerrorlines ls 3 title '0.21', \
  curves every ::1 using (($2==0.22)?$1:1/0):3:4 with yerrorlines ls 4 title '0.22', \
  curves every ::1 using (($2==0.23)?$1:1/0):3:4 with yerrorlines ls 5 title '0.23', \
  curves every ::1 using (($2==0.24)?$1:1/0):3:4 with yerrorlines ls 6 title '0.24'

unset label 100
set title 'Tiempo de relajacion' font ',21'
set xlabel 'p_{11} = p_{22}'
set ylabel '<t_{relax}>/T_{MAX}'
unset y2label
unset y2tics
set xrange [0.63:0.91]
set yrange [0:0.5]
set ytics nomirror
set key opaque box at graph 0.98, graph 0.98 samplen 1.5 spacing 1.05 title 'p_{12}'

plot \
  curves every ::1 using (($2==0.16)?$1:1/0):5:6 with yerrorlines ls 1 title '0.16', \
  curves every ::1 using (($2==0.20)?$1:1/0):5:6 with yerrorlines ls 2 title '0.20', \
  curves every ::1 using (($2==0.21)?$1:1/0):5:6 with yerrorlines ls 3 title '0.21', \
  curves every ::1 using (($2==0.22)?$1:1/0):5:6 with yerrorlines ls 4 title '0.22', \
  curves every ::1 using (($2==0.23)?$1:1/0):5:6 with yerrorlines ls 5 title '0.23', \
  curves every ::1 using (($2==0.24)?$1:1/0):5:6 with yerrorlines ls 6 title '0.24'

unset multiplot
