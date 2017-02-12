fname = 'TMS1mmSingleCSAOut1_1hist.dat'
set palette model RGB defined (0.0 1.0 1.0 1.0, 1/256. 1.0 1.0 1.0, 1/255. 0.0 0.0 0.51, 0.34 0.0 0.81 1.0, 0.61 0.87 1.0 0.12, 0.84 1.0 0.2 0.0, 1.0 0.51 0.0 0.0) positive

set output "1.eps"
set terminal postscript eps enhanced solid color "Helvetica"

set multiplot layout 2,1 margins screen 0.12,0.88,0.95,0.1 spacing screen 0

unset xlabel
set format x ""
set xrange [0:1]
set ylabel '[V]'
set yrange [0.97:1.005]

set key bottom right

set label 1 "Response to 100mV tail-pulse" at first 0.52,1.0 front

plot fname index 0 u ($1*1000):3:5 w image t '', '' index 2 u ($2*1e-4):1 w step t 'Baseline {/Symbol m}=976.913mV, {/Symbol s}=0.988mV'

set format x "%h"
set xlabel 't [ms]'
set yrange [-0.01:0.03]

set key top right

set label 2 "ENC = 28.7e^{-}, C_{inj}=1.186fF (741.25e^{-})" at first 0.52,0.023 front
set label 3 "Trapezoidal filtered pulse" at first 0.52,0.005 front

plot fname index 1 u ($1*1000):3:5 w image t '', '' index 3 u ($2*1.8e-4):1 w step t 'Peak {/Symbol m}=19.390mV, {/Symbol s}=0.750mV'

unset multiplot
unset output
set term x11
