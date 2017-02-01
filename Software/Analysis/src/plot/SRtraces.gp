clkmult = 1000000
clkzero = 0
sdizero = 4.5
sdozero = 9
rstzero = -1
sdoshift = 1.28 #us

set output "SRTrace.eps"
set terminal postscript eps enhanced color solid size 17,11 "Helvetica" 32

set multiplot
set size 1,0.5
set origin 0,0.5
set xlabel "Time[{/Symbol m}s]"
set xrange [480:680]
set xtics autofreq
set ylabel "U[V]"
set yrange [-1.5:14]
set ytics autofreq

unset arrow
unset label
set arrow 1 from 499.356,13.3 to 499.356,-0.5 nohead
set label 1 "stored bit#0 out from TM" at 500,13 left
set arrow 2 from 500.009,8.5 to 500.009,-0.5 nohead
set label 2 "bit#0 registered by TM" at 501,8.4 left
set label 8 "bit#0 is MSB in the chip" at 630,13.3 left

unset key
plot 'SRtraces.dat' u ($1*clkmult):($2+clkzero) w step lw 0.1 t 'CLK', '' u ($1*clkmult):($3+sdizero) w step lw 0.1 t 'SDI (data into TM)', '' u ($1*clkmult+sdoshift):($4+sdozero) w step lw 0.1 t 'SDO (data out from TM)', '' u ($1*clkmult):($5+rstzero) w step lw 0.1 t 'LOAD (RST)'

set size 1,0.5
set origin 0,0
set xrange[660:670]
set yrange [-1.5:14]

set arrow 3 from (661.918+sdoshift),13.5 to (661.918+sdoshift),-0.5 nohead
set label 3 "stored bit#128 out from TM" at (661.95+sdoshift),13.2 left
set arrow 4 from 663.835,8.5 to 663.835,-0.5 nohead 
set label 4 "bit#128 registered by TM" at 663.90,8.3 left
set arrow 5 from (663.199+sdoshift),12.5 to (663.199+sdoshift),-0.5 nohead
set label 5 "stored bit#129 out from TM" at (663.25+sdoshift),11.5 left
set arrow 6 from 665.129,4.8 to 665.129,-0.5 nohead
set label 6 "bit#129 registered by TM" at 665.2,5.1 left
set arrow 7 from 665.765,2.5 to 665.765,-1.2 nohead
set label 7 "LOAD (RST)" at 665.85,1.8 left
set label 9 "f1c1aa1c710a2d7893cf2deb157808b1c582376c" at screen 0.99,0.01 right font ",20"

set key
plot 'SRtraces.dat' u ($1*clkmult):($2+clkzero) w step lw 0.1 t 'CLK', '' u ($1*clkmult):($3+sdizero) w step lw 0.1 t 'SDI (data into TM)', '' u ($1*clkmult+sdoshift):($4+sdozero) w step lw 0.1 t 'SDO (data out from TM)', '' u ($1*clkmult):($5+rstzero) w step lw 0.1 t 'LOAD (RST)'

unset multiplot
unset output
