reset

sampleSize(x, a, b) = a*exp(-b*(x - 1000)**0.9)  + 10;


set samples 1000

set term qt size 1000, 500 font "Sans, 14"

#set key inside Left bottom  width -3
set grid lw 2
set logscale x

#set tics font ", 16"

unset label

set xlabel "Clock ticks"
set xrange [ 1000 : 1.9e8 ] noreverse writeback
set x2range [ * : * ] noreverse writeback

#set ylabel "Iteration estimate"
set yrange [ 0 : 500 ] noreverse writeback
set y2range [ * : * ] noreverse writeback


plot 'sample_size.dat' using 1:2 with line lw 3 lt 2 lc '#0000FFFF' title 'averaged over' at 0.3, 0.85, \
     'sample_size.dat' using 1:2 lw 3 lt 6 lc '#0000BBBB' title ' ' at 0.3, 0.85 ,\
     'sample_size.dat' using 1:3 with lines lw 3 lt 2 lc '#00FF8800' title 'sample size' at 0.3, 0.77,\
     'sample_size.dat' using 1:3 lw 3 lt 6 lc '#00991100' title ' ' at 0.3, 0.77, \
     'sample_size.dat' using 1:4 with lines lw 3 lt 2 lc '#0000C77E' title 'run time [ms]' at 0.3, 0.69,\
     'sample_size.dat' using 1:4 lw 3 lt 6 lc '#0000974e' title ' ' at 0.3, 0.69