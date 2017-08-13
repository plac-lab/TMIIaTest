if (!exists("fname")) fname='x0000y0000.dat'

set key bottom right
set xlabel 'DAC code'
set ylabel '[V]'

set title fname

plot fname u 1:3 w step t 'DAC1', '' u 1:4 w step t 'DAC2', '' u 1:5 w step t 'DAC3', '' u 1:6 w step t 'DAC4', '' u 1:7 w step t 'DAC5', '' u 1:8 w step t 'DAC6'

