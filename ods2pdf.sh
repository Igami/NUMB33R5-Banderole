#!/bin/bash

input=${1:-Banderole}
front=.$input.front.pdf
back=.$input.back.pdf

libreoffice --convert-to csv $input.ods
libreoffice --convert-to pdf $input.ods
while [ ! -f $input.pdf ]; do sleep 0.1; done

count=$(head -n 5 $input.csv | tail -1 | cut -d, -f11 -)

for ((i=1;i<=$count;i+=9)); do
  max=$(($i+8))
  blanks=1
  if (("$max" > "$count")); then
    blanks=$((max-count+blanks))
    max=$count
  fi

  cat_front+="B4 A$i-$max B4 "
  cat_back+="4 $(printf '3 %.0s' $(seq $((10-blanks)))) \
            $(printf '6 %.0s' $(seq $blanks))"
done

echo "assemble front"
pdftk $input.pdf cat 7-$((count+6)) output - | \
pdftk - background $input.pdf output - | \
pdftk A=- B=$input.pdf cat $cat_front output - | \
pdfjam -q --nup 1x11 --outfile $front

echo "assemble back"
pdftk $input.pdf cat $cat_back output - | \
pdfjam -q --nup 1x11 --outfile $back

output="./output/"$(head -n 2 $input.csv | tail -1 | cut -d, -f4 -)

echo "shuffle pdf"
pdftk A=$front B=$back shuffle A B output $output.pdf

rm -f $input.pdf $input.csv $front $back
xdg-open $output.pdf
