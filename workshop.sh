#!/bin/bash

WORKSHOP_ID=104691717

if [[ "$OSTYPE" == "darwin"* ]]; then
    gmad='../../../bin/gmad'
    gmpublish='../../../gmpublish'
else
    gmad='../../../bin/linux64/gmad'
    gmpublish='../../../bin/linux64/gmpublish'
fi

export LD_LIBRARY_PATH="../../../bin/linux64/"

$gmad create -folder "./" -out "_TEMP.gma"
$gmpublish update -addon "_TEMP.gma" -id "$WORKSHOP_ID" -icon "icon.jpg"

rm ./_TEMP.gma