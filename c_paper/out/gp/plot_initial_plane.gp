# Plot an initial-plane scan from the joined file, or from a folder containing
# part_*.txt files.
#
# Usage from the repository root:
# gnuplot -e "infile='c_paper/out/raw/initial_plane/initial_plane__N1_100__N2_100__P11_0p9__P12_0p3__P22_0p9__B_1p2__R_0__E_m0p4__ndiv_10__reps_5.txt'; outfile='c_paper/out/plots/initial_plane/initial_plane.png'" c_paper/out/gp/plot_initial_plane.gp
#
# Alternative, reading the part files directly:
# gnuplot -e "indir='c_paper/out/raw/initial_plane/parts/N1_500__N2_500__P11_0p9__P12_0p3__P22_0p9__B_1p2__R_0__E_m0p4__ndiv_10__reps_5'; outfile='c_paper/out/plots/initial_plane/initial_plane.png'" c_paper/out/gp/plot_initial_plane.gp
#
# If outfile is omitted, the plot is written inside c_paper/out/plots/initial_plane/.
# The script creates two temporary files next to the input:
#   _initial_plane_points.tmp
#   _initial_plane_fixed_points.tmp
#
# Optional:
#   tmax=<integer> fixes the color scale as t_relax/T_MAX. If omitted,
#   the maximum observed t_relax in the input is used.

if (!exists("infile") && !exists("indir")) {
    print "ERROR: define infile with the joined scan file, or indir with the folder containing part_*.txt files."
    print "Example:"
    print "gnuplot -e \"infile='c_paper/out/raw/initial_plane/initial_plane__N1_500__...txt'; outfile='c_paper/out/plots/initial_plane/test.png'\" c_paper/out/gp/plot_initial_plane.gp"
    exit
}

if (!exists("outfile")) {
    outfile = "c_paper/out/plots/initial_plane/initial_plane.png"
}

tmp_base = "c_paper/out/gp/_initial_plane_plot"
points_tmp = tmp_base . "_points.tmp"
initial_avg_tmp = tmp_base . "_initial_avg.tmp"
fixed_tmp = tmp_base . "_fixed_points.tmp"
fixed_stable_tmp = tmp_base . "_fixed_points_stability.tmp"
params_tmp = tmp_base . "_params.gp"

plotdir = "c_paper/out/plots/initial_plane"
if (exists("infile")) {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Infile \"%s\" -Points \"%s\" -InitialAvg \"%s\" -Fixed \"%s\" -FixedStable \"%s\" -Params \"%s\" -PlotDir \"%s\"", infile, points_tmp, initial_avg_tmp, fixed_tmp, fixed_stable_tmp, params_tmp, plotdir)
} else {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Indir \"%s\" -Points \"%s\" -InitialAvg \"%s\" -Fixed \"%s\" -FixedStable \"%s\" -Params \"%s\" -PlotDir \"%s\"", indir, points_tmp, initial_avg_tmp, fixed_tmp, fixed_stable_tmp, params_tmp, plotdir)
}
system(prepare_cmd)

set terminal pngcairo size 1100,1000 enhanced font "Times New Roman,22"
set output outfile

if (exists("params_tmp")) {
    load params_tmp
}

set xlabel "x_1(0)"
set ylabel "x_2(0)"
set cblabel "t_{relax}/T_{MAX}"

if (!exists("tmax")) {
    stats points_tmp using 10 nooutput
    tmax = STATS_max
}

set xrange [-0.03:1.03]
set yrange [-0.03:1.12]
set cbrange [0:1]
set size square
set bmargin 7.5

set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#dddddd" lw 1

set palette defined (0 "#313695", 0.25 "#74add1", 0.5 "#ffffbf", 0.75 "#f46d43", 1 "#a50026")

unset key

set label 91 "initial avg. time" at screen 0.235,0.064 right font "Times New Roman,20" tc rgb "black" front
set label 92 "final, color=time" at screen 0.235,0.035 right font "Times New Roman,20" tc rgb "black" front
set label 93 "x" at screen 0.257,0.035 center font "Times New Roman,16" tc rgb "#496ab3" front
set object 91 circle at screen 0.257,0.066 size screen 0.003 front fillstyle solid 1.0 border lc rgb "#d95f02" fc rgb "#d95f02"

set label 101 "fixed points" at screen 0.425,0.050 center font "Times New Roman,21" tc rgb "black" front
set label 103 "stable" at screen 0.575,0.064 left font "Times New Roman,20" tc rgb "black" front
set label 104 "saddle" at screen 0.575,0.035 left font "Times New Roman,20" tc rgb "black" front
set label 105 "unstable" at screen 0.750,0.064 left font "Times New Roman,20" tc rgb "black" front
set label 106 "marginal" at screen 0.750,0.035 left font "Times New Roman,20" tc rgb "black" front

set arrow 101 from screen 0.525,0.071 to screen 0.512,0.071 nohead front lw 1.8 lc rgb "black"
set arrow 102 from screen 0.512,0.071 to screen 0.512,0.056 nohead front lw 1.8 lc rgb "black"
set arrow 103 from screen 0.512,0.056 to screen 0.502,0.050 nohead front lw 1.8 lc rgb "black"
set arrow 104 from screen 0.502,0.050 to screen 0.512,0.044 nohead front lw 1.8 lc rgb "black"
set arrow 105 from screen 0.512,0.044 to screen 0.512,0.029 nohead front lw 1.8 lc rgb "black"
set arrow 106 from screen 0.512,0.029 to screen 0.525,0.029 nohead front lw 1.8 lc rgb "black"

set object 101 circle at screen 0.555,0.066 size screen 0.006 front fillstyle empty border lc rgb "#1b7837" lw 2.1
set object 102 circle at screen 0.555,0.037 size screen 0.006 front fillstyle empty border lc rgb "#d95f02" lw 2.1
set object 103 circle at screen 0.730,0.066 size screen 0.006 front fillstyle empty border lc rgb "#b2182b" lw 2.1
set object 104 circle at screen 0.730,0.037 size screen 0.006 front fillstyle empty border lc rgb "#636363" lw 2.1

plot \
    initial_avg_tmp using 1:2:($3/tmax) with points pt 7 ps 0.66 palette notitle, \
    points_tmp using 6:7:($10/tmax) with points pt 2 ps 1.32 lw 0.55 palette notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "stable" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#1b7837" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "saddle" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#d95f02" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "unstable" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#b2182b" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "marginal" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#636363" notitle, \
    fixed_tmp using 2:3:1 with labels offset char 0.8,0.8 font "Times New Roman,18" tc rgb "black" notitle
