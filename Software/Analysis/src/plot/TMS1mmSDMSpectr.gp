set output "1.eps"
set terminal postscript eps enhanced color size 10,7 "Helvetica,24"

#set log x
set xrange [0:1e6]
set format x "%.1s%c"
set xlabel 'Frequency [Hz]'

set log y
set yrange [1e-7:1.0]
set format y "%h"
set ylabel 'RMS Voltage [V]'

set grid
set key bottom right

set label 1 'f_{SDM}=25MHz, RBW=385Hz' at screen 0.7,0.95

plot 'SigmaDeltaSimulated/sdmSpectr.dat' index 1 u 3:5 w step lw 0.1 t 'Simulation', \
     'SpectrSDM25MHz0Vin.dat' u 3:5 w step lw 0.5 t '0V input', \
     'SpectrSDM25MHzSin1.0Vpp1.2VDC200kHz.dat' u 3:5 w step t 'Sine wave input: 200kHz, 1.0Vpp, 1.2Vdc', \

unset output
