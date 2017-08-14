#!/usr/bin/awk -f
#
# Check if a tested chip is bad due to failed DACs and print for a wiki table entry.
#

BEGIN {
    # at which DAC code to check for voltage
    dacCode2Check = 0
    # voltage threshold to declare as bad channel
    badVth = 0.2
    veryBadVth = 1.5
    # having >= these number of bad channels will be declared as bad chip
    nBadChTh = 3
    # column id of begin and end channel data in data file
    chColBegin = 3
    chColEnd = 8
#    print("==== Characteristics of Topmetal-S chips of wafer ====")
}

/^#/ {
    printf("| %2d | %2d |", $3, $4)
}

{
    if($1 == dacCode2Check) {
        nBad = 0
        nVeryBad = 0
        for(i=chColBegin; i<=chColEnd; i++) {
            if($i > veryBadVth) { nVeryBad++ }
            if($i > badVth || $i == 0.0) {
                printf(" **%g** |", $i)
                nBad++
            } else {
                printf(" %g |", $i)
            }
        }
        if(nBad >= nBadChTh || nVeryBad > 0) {
            printf(" %d/%d | **Y** |  |  |\n", nBad, nVeryBad)
        } else {
            printf(" %d/%d | N |  |  |\n", nBad, nVeryBad)
        }
    }
}
