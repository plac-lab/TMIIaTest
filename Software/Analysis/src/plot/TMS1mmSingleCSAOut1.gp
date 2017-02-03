dfname = 'TMS1mmSingleCSAOut1.dat'
paraNames = 'VBIASN VBIASP VCASN VCASP VDIS VREF VREF1.2'
paraVals = '1.38 1.7 2.315 0.388 1.45 2.68 1.21'

paraLabel = ""
do for [i=1:words(paraNames)] {paraLabel = paraLabel.sprintf("%s=%sV ", word(paraNames, i), word(paraVals, i))}

set output "1.eps"
set terminal postscript eps enhanced monochrome size 7,3 "Helvetica" 14

set multiplot

set origin 0,0
set size 1,1
set xlabel 't [ms]'
set ylabel 'U [V]'

plot dfname every 20 u ($1*1000):2 w step t paraLabel

set origin 0.35,0.27
set size 0.62,0.65
set xlabel 't [{/Symbol m}s]'
set xrange [980:1500]
set ylabel 'U [V]'

plot dfname u ($1*1e6):2 w step t ''

unset multiplot
unset output
