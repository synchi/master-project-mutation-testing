#!/bin/bash

declare -a projects=("asj" "cli" "csv" "func" "hika" "io" "jopt" "mime" "retro" "text" "wire" "codec" "lang" "math")

for proj in "${projects[@]}"; do
    cp x-ml-score.sh "$proj"-ml-score.sh
done
