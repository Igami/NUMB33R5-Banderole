#!/bin/bash

input=${1:-Banderole.ods}
file=${input##*/}
file=${file%.ods}
front=.$file.front.pdf
back=.$file.back.pdf

libreoffice --convert-to csv --outdir . --infilter='CSV:44,,76,1,,1031,true' $input
libreoffice --convert-to pdf --outdir . $input
while [ ! -f $file.pdf ]; do sleep 0.1; done

output="./output/$(head -n 1 $file.csv | tail -1 | cut -d, -f1 -)"
start=$(head -n 1 $file.csv | tail -1 | cut -d, -f114 -)
count=$(head -n 1 $file.csv | tail -1 | cut -d, -f122 -)

for ((i=$start;i<=$count;i+=9)); do
  max=$(($i+8))
  blanks=1
  if ((max > count)); then
    blanks=$((max-count+blanks))
    max=$count
  fi

  cat_front+="B4 A$i-$max B4 "
  cat_back+="4 $(printf '3 %.0s' $(seq $((10-blanks)))) $(printf '6 %.0s' $(seq $blanks))"
done

echo "assemble front"
pdftk $file.pdf cat 7-$((count+6)) output - | \
pdftk - background $file.pdf output - | \
pdftk A=- B=$file.pdf cat $cat_front output - | \
pdfjam -q --nup 1x11 --outfile $front

echo "assemble back"
pdftk $file.pdf cat $cat_back output - | \
pdfjam -q --nup 1x11 --outfile $back

echo "shuffle pdf"
pdftk A=$front B=$back shuffle A B output $output.pdf

cp $input $output.ods &> /dev/null
rm -f $file.pdf $file.csv $front $back
xdg-open $output.pdf
