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

if (!exists("infile") && !exists("indir")) {
    print "ERROR: define infile with the joined scan file, or indir with the folder containing part_*.txt files."
    print "Example:"
    print "gnuplot -e \"infile='c_paper/out/raw/initial_plane/initial_plane__N1_500__...txt'; outfile='c_paper/out/plots/initial_plane/test.png'\" c_paper/out/gp/plot_initial_plane.gp"
    exit
}

if (!exists("outfile")) {
    outfile = "c_paper/out/plots/initial_plane/initial_plane.png"
}

if (exists("infile")) {
    points_tmp = infile . "._points.tmp"
    fixed_tmp = infile . "._fixed_points.tmp"
} else {
    points_tmp = indir . "/_initial_plane_points.tmp"
    fixed_tmp = indir . "/_initial_plane_fixed_points.tmp"
}

plotdir = "c_paper/out/plots/initial_plane"
if (exists("infile")) {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Infile \"%s\" -Points \"%s\" -Fixed \"%s\" -PlotDir \"%s\"", infile, points_tmp, fixed_tmp, plotdir)
} else {
    prepare_cmd = sprintf("powershell -NoProfile -ExecutionPolicy Bypass -File c_paper/out/gp/prepare_initial_plane_plot.ps1 -Indir \"%s\" -Points \"%s\" -Fixed \"%s\" -PlotDir \"%s\"", indir, points_tmp, fixed_tmp, plotdir)
}
system(prepare_cmd)

set terminal pngcairo size 1100,1000 enhanced font "Times New Roman,22"
set output outfile

set xlabel "x_1(0)"
set ylabel "x_2(0)"
set cblabel "x_1(\\305)"

set xrange [-0.03:1.03]
set yrange [-0.03:1.03]
set cbrange [0:1]
set size square

set tics in
set mxtics 2
set mytics 2
set border linewidth 1.4
set grid xtics ytics lc rgb "#dddddd" lw 1

set palette defined (0 "#313695", 0.25 "#74add1", 0.5 "#ffffbf", 0.75 "#f46d43", 1 "#a50026")

set key outside top center horizontal maxrows 1 samplen 1.5

plot \
    points_tmp using 3:4 with points pt 7 ps 0.35 lc rgb "#bbbbbb" title "initial", \
    points_tmp using 6:7:6 with points pt 7 ps 0.65 palette title "final", \
    fixed_tmp using 2:3 with points pt 6 ps 2.2 lw 2 lc rgb "black" title "analytic fixed points", \
    fixed_tmp using 2:3:1 with labels offset char 0.8,0.8 font "Times New Roman,18" tc rgb "black" notitle
