#!/bin/bash

BASE_PATH="/cluster/work/lawecon/Data/lexis-data/rawdata"
TARGET_PATH="/cluster/work/lawecon/Work/sischaef/data/us_statue/raw"

DOCUMENTS=(7262 4867 4313 3817 10780 11005 10630 10650 10816 10837 11012 10989 10849 7849 7835 7805 7711 138377
           3829 7701 7693 7244 6809 6752 3829 6718 6611 4900 6258 6306 4931 5080 7864 7876 8577 9077 7883 9562
           9088 9101 9277 9290 9311 9114 9258 9125 9576 9589
           )
EXTENSION=".zip"

mkdir ${TARGET_PATH}
for fname in "${DOCUMENTS[@]}"
do
    doc_base=${BASE_PATH}/${fname}${EXTENSION}
    echo "Processing file ${doc_base}"
    doc_target=${TARGET_PATH}/${fname}${EXTENSION}
    cp ${doc_base} ${doc_target}
done
