#!/bin/bash

WORKSHOP_ID=104691717
dir="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
gma_location=$(readlink -f "$dir")/..∕__TEMP.gma

cd ../../../bin

./gmad_linux create -folder "$dir/" -out "$gma_location"
./gmpublish_linux update -addon "$gma_location" -id "$WORKSHOP_ID" -icon "$dir/icon.jpg"

rm $gma_location
