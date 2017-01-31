dfname = 'dacscan.dat'
f(x) = a*x + b

fit [0:57000] f(x) dfname u 1:2 via a,b

set output "1.eps"
set terminal postscript eps enhanced monochrome "Helvetica" 14

unset zeroaxis
unset xlabel
set xrange [-1:65536]
set format x ""
set yrange [-0.1:3.0]
set ylabel 'Output [V]'

set multiplot layout 2,1 title 'DAC3 in Topmetal-S 1mm version #5 \@LBNL' margins screen 0.1,0.99,0.95,0.1 spacing screen 0

set key top left Left reverse

plot dfname u 1:2 w step t 'Scan data', f(x) t sprintf("f(x) = %g * x + %g", a, b)

set zeroaxis
set format x "%h"
set xlabel 'DAC code (16 bit)'
set yrange[-7:8.5]
set ylabel 'Residual [mV]'

set key bottom left reverse

plot dfname u 1:(($2 - f($1))*1000.0) w step t 'Data - fit'

unset multiplot
unset output
