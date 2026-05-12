if (!exists("summary")) {
    summary = "c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/asymmetry/summary_plots/asymmetry_distance_summary.tsv"
}
if (!exists("outfile")) {
    outfile = "c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/asymmetry/summary_plots/asymmetry_distance_summary.png"
}

set terminal pngcairo size 1400,760 enhanced font "Times New Roman,21"
set output outfile

set multiplot layout 1,2 margins 0.075,0.975,0.145,0.875 spacing 0.075,0.02

set style line 1 lc rgb "#1f77b4" pt 7 ps 1.35 lw 1.4
set style line 2 lc rgb "#d95f02" pt 5 ps 1.45 lw 1.4
set style line 3 lc rgb "#2ca02c" pt 9 ps 1.45 lw 1.4
set style line 4 lc rgb "#4d4d4d" pt 6 ps 1.0 lw 1.0

set grid xtics ytics lc rgb "#dddddd" lw 1
set border lw 1.3
set tics in
set mxtics 2
set mytics 2
set key top left box opaque samplen 1.4 width -1 font "Times New Roman,16"

set xlabel "|log(N_1/N_2)|"
set ylabel "<d_{min}> al punto fijo analitico"
set yrange [0:*]
set title "Robustez frente a asimetria de tamanos" font "Times New Roman,20"

plot \
    summary using (strcol(1) eq "lowN_asymmetry" ? $6 : 1/0):12:13 with yerrorbars ls 1 title "low N", \
    summary using (strcol(1) eq "highN_asymmetry" ? $6 : 1/0):12:13 with yerrorbars ls 2 title "alta conectividad", \
    summary using (strcol(1) eq "critical_asymmetry" ? $6 : 1/0):12:13 with yerrorbars ls 3 title "zona critica"

unset ylabel
set xlabel "conectividad media intra <k>"
set title "Distancia a la teoria vs conectividad" font "Times New Roman,20"
set key top right box opaque samplen 1.4 width -1 font "Times New Roman,16"

plot \
    summary using (strcol(1) eq "lowN_asymmetry" ? $11 : 1/0):12:13 with yerrorbars ls 1 title "low N", \
    summary using (strcol(1) eq "highN_asymmetry" ? $11 : 1/0):12:13 with yerrorbars ls 2 title "alta conectividad", \
    summary using (strcol(1) eq "critical_asymmetry" ? $11 : 1/0):12:13 with yerrorbars ls 3 title "zona critica"

unset multiplot
