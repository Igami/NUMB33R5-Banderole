#!/bin/bash

file=${1:-Banderole}
front=.$file.pdf.front.pdf
back=.$file.pdf.back.pdf

rm -f $file.pdf

libreoffice --convert-to pdf $file.ods
while [ ! -f $file.pdf ]; do sleep 0.1; done

count=$(pdfgrep -om1 \
      '[0-9][0-9] [0-9][0-9] [0-9][0-9] [0-9][0-9][ ]+([0-9][0-9])' $file.pdf)
count=${count:(-2)}

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
pdftk $file.pdf cat 7-$(($count+6)) output - | \
pdftk - background $file.pdf output - | \
pdftk A=- B=$file.pdf cat $cat_front output - | \
pdfjam -q --nup 1x11 --outfile $front

echo "assemble back"
pdftk $file.pdf cat $cat_back output - | \
pdfjam -q --nup 1x11 --outfile $back

echo "shuffle pdf"
pdftk A=$front B=$back shuffle A B output $file.pdf

rm -f $front $back
xdg-open $file.pdf
