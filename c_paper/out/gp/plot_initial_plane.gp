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
fixed_tmp = tmp_base . "_fixed_points.tmp"
params_tmp = tmp_base . "_params.gp"

plotdir = "c_paper/out/plots/initial_plane"
if (exists("infile")) {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Infile \"%s\" -Points \"%s\" -Fixed \"%s\" -Params \"%s\" -PlotDir \"%s\"", infile, points_tmp, fixed_tmp, params_tmp, plotdir)
} else {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Indir \"%s\" -Points \"%s\" -Fixed \"%s\" -Params \"%s\" -PlotDir \"%s\"", indir, points_tmp, fixed_tmp, params_tmp, plotdir)
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

set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#dddddd" lw 1

set palette defined (0 "#313695", 0.25 "#74add1", 0.5 "#ffffbf", 0.75 "#f46d43", 1 "#a50026")

set key outside bottom center horizontal maxrows 1 samplen 1.5

plot \
    points_tmp using 3:4 with points pt 7 ps 0.35 lc rgb "#bbbbbb" title "initial", \
    points_tmp using 6:7:($10/tmax) with points pt 7 ps 0.70 palette title "final, color=time", \
    fixed_tmp using 2:3 with points pt 6 ps 2.2 lw 2 lc rgb "black" title "analytic fixed points", \
    fixed_tmp using 2:3:1 with labels offset char 0.8,0.8 font "Times New Roman,18" tc rgb "black" notitle
