#!/bin/bash
# Run texcount for a given range of commits,
# then plots the word count against 
# Assumes, texcount and gnuplot are available.
# Execute e. g. with
#   plot_texcount.sh master "all.tex my.tex files.tex with_wildcard/*.tex"

PLOT_DATA_FILE=plot_data_crop.txt
OUTFILE=plot.png
rm -f ${PLOT_DATA_FILE}

if [[ -n $(git status --porcelain) ]]; then echo "Repo is dirty, clean up first"; exit 1; fi

while read -r rev; do
  git checkout ${rev}
  TOTAL_WORD_COUNT=$(texcount ${@:2} | grep "Words in text: [0-9]*" | tail -n 1 | grep -o "[0-9]*")
  DATE_OF_COMMIT=$(git show -s --format=%ci)
  echo "${DATE_OF_COMMIT},${TOTAL_WORD_COUNT}" >> ${PLOT_DATA_FILE}
done < <(git rev-list "$1")

# Reverse order to get it ascendingly by date.
tac ${PLOT_DATA_FILE} > "sorted_${PLOT_DATA_FILE}"

# Plot the sorted data.
gnuplot << EOF
set timefmt '%Y-%m-%d %H:%M:%S '
set xdata time
set datafile sep ','
set term png
set output "${OUTFILE}"
plot "sorted_${PLOT_DATA_FILE}" using 1:2 title "Word count" with lines
EOF
