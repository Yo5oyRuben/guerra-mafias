if (!exists("summary")) {
    summary = "c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling/plots/symmetric_N_scaling_distance_summary.tsv"
}
if (!exists("outfile")) {
    outfile = "c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling/plots/symmetric_N_scaling_distance.png"
}

set terminal pngcairo size 1500,720 enhanced font "Times New Roman,21"
set output outfile

set multiplot layout 1,2 margins 0.075,0.985,0.155,0.865 spacing 0.07,0

set style line 1 lc rgb "#1f77b4" lw 2.4 pt 7 ps 1.25
set style line 2 lc rgb "#d95f02" lw 2.4 pt 5 ps 1.35
set style line 3 lc rgb "#1f77b4" lw 1.1
set style line 4 lc rgb "#d95f02" lw 1.1

set grid xtics ytics lc rgb "#dddddd" lw 1
set border lw 1.3
set tics in
set mxtics 2
set mytics 2
set xrange [0:0.011]
set yrange [0:*]
set xlabel "1/N   (N=N_1=N_2)"
set ylabel "<d_{min}> al punto fijo analitico"
set key top left box opaque samplen 1.8 width -1 font "Times New Roman,17"

set title "b=1.174, P_{11}=P_{22}=0.9" font "Times New Roman,20"
plot \
    summary using ($5==1.174 && $6==0.1 ? $4 : 1/0):9:10 with yerrorlines ls 1 title "P_{12}=0.1", \
    summary using ($5==1.174 && $6==0.3 ? $4 : 1/0):9:10 with yerrorlines ls 2 title "P_{12}=0.3"

unset ylabel
set title "b=1.3, P_{11}=P_{22}=0.9" font "Times New Roman,20"
plot \
    summary using ($5==1.3 && $6==0.1 ? $4 : 1/0):9:10 with yerrorlines ls 1 title "P_{12}=0.1", \
    summary using ($5==1.3 && $6==0.3 ? $4 : 1/0):9:10 with yerrorlines ls 2 title "P_{12}=0.3"

unset multiplot
