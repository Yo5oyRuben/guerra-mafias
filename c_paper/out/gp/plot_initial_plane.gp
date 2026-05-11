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
nullcline1_tmp = tmp_base . "_nullcline_x1.tmp"
nullcline2_tmp = tmp_base . "_nullcline_x2.tmp"
fixed_tmp = tmp_base . "_fixed_points.tmp"
fixed_stable_tmp = tmp_base . "_fixed_points_stability.tmp"
params_tmp = tmp_base . "_params.gp"

plotdir = "c_paper/out/plots/initial_plane"
if (exists("infile")) {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Infile \"%s\" -Points \"%s\" -InitialAvg \"%s\" -Nullcline1 \"%s\" -Nullcline2 \"%s\" -Fixed \"%s\" -FixedStable \"%s\" -Params \"%s\" -PlotDir \"%s\"", infile, points_tmp, initial_avg_tmp, nullcline1_tmp, nullcline2_tmp, fixed_tmp, fixed_stable_tmp, params_tmp, plotdir)
} else {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Indir \"%s\" -Points \"%s\" -InitialAvg \"%s\" -Nullcline1 \"%s\" -Nullcline2 \"%s\" -Fixed \"%s\" -FixedStable \"%s\" -Params \"%s\" -PlotDir \"%s\"", indir, points_tmp, initial_avg_tmp, nullcline1_tmp, nullcline2_tmp, fixed_tmp, fixed_stable_tmp, params_tmp, plotdir)
}
if (exists("tmax")) {
    prepare_cmd = prepare_cmd . sprintf(" -TmaxLabel \"%g\"", tmax)
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
stats points_tmp using 10 nooutput
avg_relax = STATS_mean / tmax
avg_relax_marker = avg_relax < 0 ? 0 : (avg_relax > 1 ? 1 : avg_relax)

set xrange [-0.03:1.03]
set yrange [-0.03:1.03]
set cbrange [0:1]
set size ratio -1
set lmargin at screen 0.140
set rmargin at screen 0.780
set bmargin at screen 0.170
set tmargin at screen 0.875
arrow_len = 0.035
cb_x = 0.810
cb_y = 0.170
cb_w = 0.026
cb_h = 0.705
avg_relax_y = cb_y + cb_h * avg_relax_marker

set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#dddddd" lw 1

set palette defined (0 "#313695", 0.25 "#74add1", 0.5 "#ffffbf", 0.75 "#f46d43", 1 "#a50026")
set colorbox user origin screen cb_x, cb_y size screen cb_w, cb_h

unset key

set label 91 "inicial, color {/Symbol \\265} t_{relax}" at screen 0.275,0.066 right font "Times New Roman,18" tc rgb "black" front
set label 92 "final, color {/Symbol \\265} t_{relax}" at screen 0.275,0.035 right font "Times New Roman,18" tc rgb "black" front
set label 93 "x" at screen 0.296,0.035 center font "Times New Roman,15" tc rgb "black" front
set object 91 circle at screen 0.296,0.068 size screen 0.003 front fillstyle solid 1.0 border lc rgb "black" fc rgb "black"

set label 101 "puntos fijos:" at screen 0.465,0.051 center font "Times New Roman,19" tc rgb "black" front
set label 103 "estable" at screen 0.580,0.066 left font "Times New Roman,18" tc rgb "black" front
set label 104 "silla" at screen 0.580,0.035 left font "Times New Roman,18" tc rgb "black" front
set label 105 "inestable" at screen 0.735,0.066 left font "Times New Roman,18" tc rgb "black" front
set label 106 "marginal" at screen 0.735,0.035 left font "Times New Roman,18" tc rgb "black" front

set object 101 circle at screen 0.560,0.068 size screen 0.0058 front fillstyle empty border lc rgb "#1b7837" lw 2.1
set object 102 circle at screen 0.560,0.037 size screen 0.0058 front fillstyle empty border lc rgb "#d95f02" lw 2.1
set object 103 circle at screen 0.715,0.068 size screen 0.0058 front fillstyle empty border lc rgb "#b2182b" lw 2.1
set object 104 circle at screen 0.715,0.037 size screen 0.0058 front fillstyle empty border lc rgb "#636363" lw 2.1

set arrow 120 from screen cb_x-0.008,avg_relax_y to screen cb_x+cb_w+0.008,avg_relax_y nohead front lw 2.2 lc rgb "#111111"
set label 120 "<t_{relax}>" at screen cb_x+cb_w+0.014,avg_relax_y left font "Times New Roman,14" tc rgb "#111111" front

plot \
    nullcline1_tmp using 1:2 with lines dt 2 lw 1.15 lc rgb "#616161" notitle, \
    nullcline2_tmp using 1:2 with lines dt 3 lw 1.15 lc rgb "#616161" notitle, \
    initial_avg_tmp using 1:2:($3/tmax) with points pt 7 ps 0.66 palette notitle, \
    initial_avg_tmp using 1:2:(sqrt($4*$4+$5*$5) > 1e-12 ? arrow_len*$4/sqrt($4*$4+$5*$5) : 1/0):(arrow_len*$5/sqrt($4*$4+$5*$5)):($3/tmax) with vectors head filled size screen 0.010,15,45 lw 0.65 lc palette notitle, \
    points_tmp using 6:7:($10/tmax) with points pt 2 ps 1.32 lw 0.55 palette notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "stable" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#1b7837" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "saddle" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#d95f02" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "unstable" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#b2182b" notitle, \
    fixed_stable_tmp using 2:(strcol(4) eq "marginal" ? $3 : 1/0) with points pt 6 ps 2.05 lw 2.1 lc rgb "#636363" notitle, \
    fixed_tmp using 2:(strcol(1) eq "A" ? $3 : 1/0):1 with labels offset char 0.9,0 font "Times New Roman,18" tc rgb "black" notitle, \
    fixed_tmp using 2:(strcol(1) eq "C" ? $3 : 1/0):1 with labels offset char -0.9,0 font "Times New Roman,18" tc rgb "black" notitle, \
    fixed_tmp using 2:(strcol(1) ne "A" && strcol(1) ne "C" ? $3 : 1/0):1 with labels offset char 0.8,0.8 font "Times New Roman,18" tc rgb "black" notitle
