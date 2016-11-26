#!/bin/bash

export GRASS_FONT="DejaVu Sans:Book"

eval `g.region -g`

DESIRED_WIDTH=500
DESIRED_HEIGHT=`python -c "print $DESIRED_WIDTH / float($cols) * $rows"`

# Palettable CB Paired_10 (not printable, not blind)
C1=#A6CEE3
C2=#1F78B4
C3=#B2DF8A
C4=#33A02C
C5=#FB9A99
C6=#E31A1C
C7=#FDBF6F
C8=#FF7F00
C9=#CAB2D6
C10=#6A3D9A

LINE_WIDTH=3
YTICS="0.0,0.1,0.2,0.3,0.4,0.5"

CATS=`v.category zones -g op=print | sort -g | uniq`

# zone colors according to category (max 10 categories)
ZONE_COLORS=""
> legend.txt  # ensures empty existing file
for C in ${COLORS//,/ }; do echo "1|legend/line|5|ps|$C|$C|$LINE_WIDTH|line|1"; done
for CAT in $CATS
do
    eval "COLOR=\$C$CAT"
    ZONE_COLORS+="$COLOR,"
    echo "$CAT|legend/line|5|ps|$COLOR|$COLOR|$LINE_WIDTH|line|1" >> legend.txt
done
ZONE_COLORS=${ZONE_COLORS%?}

seq 1 1 46 > x.txt

COMMON_OPTIONS="width=$LINE_WIDTH ytics=$YTICS" # y_range=0,0.6

for F in 0 1 2 3 4 5
do
    MAP=ff_${F}_slice
    for CAT in ${CATS}
    do
        v.db.select zones sep="\n" \
            col=`g.list rast p="${MAP}_*" sep=_average,`_average \
            -c where="cat = ${CAT}" > file_${MAP}_cat_${CAT}.txt
        d.mon start=cairo output=zonal_plot_${MAP}_${CAT}.png \
            width=$DESIRED_WIDTH height=$DESIRED_HEIGHT
        d.erase  # previous image is not cleaned
        d.linegraph x_file=x.txt y_file=file_${MAP}_cat_${CAT}.txt $COMMON_OPTIONS
        d.mon stop=cairo
    done
    d.mon start=cairo output=zonal_plot_${MAP}.png \
        width=$DESIRED_WIDTH height=$DESIRED_HEIGHT
    d.erase  # previous image is not cleaned
    d.linegraph x_file=x.txt \
        y_file=`ls file_${MAP}_cat_*.txt -1v | tr '\n' ',' | sed 's/\(.*\),/\1/'` \
        $COMMON_OPTIONS y_color=$ZONE_COLORS
    d.legend.vect at=85,98 input=legend.txt
    d.mon stop=cairo
done
