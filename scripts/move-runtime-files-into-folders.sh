#!/bin/sh
#
# Originally all files in GP runtime were in a single lib folder.
# To simplify further steps, files are splited into specific folders (like stdlib, morphic etc)
# This script simplifies the transition, keep the already defined subdirs structure as a template.
# NOTE: files from SRC_LIB_DIR will be removed!


if [ $# -eq 0 ] 
then
    echo "Usage: path/to/runtime/lib/that/will/be/moved/info/folders"
    exit -1
fi

SRC_LIB_DIR="$1"
DST_LIB_DIR=runtimes/anamorphic/runtime/lib

for dir in ${DST_LIB_DIR}/*   
do
    dir=${dir%*/}      # remove the trailing "/"
    echo "Processing >${dir##*/}<"
    for file in "${dir}"/*
    do
        fileName=${file##*/}
        # echo "mv ${SRC_LIB_DIR}/$fileName $dir"        
        mv ${SRC_LIB_DIR}/$fileName $dir
    done
done
