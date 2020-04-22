set -euxo pipefail

bash its.sh ../ref/unite7-99.qza ../reads ./output/q2-v7-noITSx
bash its.sh ../ref/unite7-99.qza ../reads ./output/q2-v7-ITSx    ITSxpress


bash its.sh ../ref/unite8-99.qza ../reads ./output/q2-v8-noITSx
bash its.sh ../ref/unite8-99.qza ../reads ./output/q2-v8-ITSx    ITSxpress

