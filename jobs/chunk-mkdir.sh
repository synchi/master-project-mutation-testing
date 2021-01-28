#!/bin/bash

start=$(gdate +%s%N) 

# Number of mutants
N_mutants=`find . -mindepth 4 -maxdepth 4 -type d | wc -l`
# echo "N_mutants: $N_mutants"

# The mutants (directories)
declare -a mutant_dirs
while IFS= read -r -u3 -d $'\0' dir; do
    mutant_dirs+=( "$dir" )     
done 3< <(find . -mindepth 4 -maxdepth 4 -type d -print0)

# Number of chunks
N_chunks=4

# Number of mutants per chunk
((chunk_size=(N_mutants + N_chunks - 1) / N_chunks))
# echo "Chunk size: $chunk_size"

index=0
count=0

# Chunking process
while (($index < $N_chunks))
do 
    ((pos=$index * $chunk_size))
    # echo "Creating chunk $index / $N_chunks"

    # Last chunk check to include remainder
    if (($index == $N_chunks - 1)) 
    then
        # Entire tail from position
        chunk_list=${mutant_dirs[@]:pos} 
    else 
        # Just the chunk from position
        chunk_list=${mutant_dirs[@]:pos:chunk_size}
    fi

    # Prepare destination directories
    for D in $chunk_list
    do 
        if [[ ! " ${method_dirs[@]} " =~ " `dirname ${D}` " ]]; then
            mkdir -p "../chunk${index}/`dirname ${D}`"
        fi
    done
    
    # Copy mutant directories
    for D in $chunk_list
    do
        ((count++))
        # echo "Copying mutant $count / $N_mutants"
        cp -r $D "../chunk${index}/`dirname ${D}`"
    done       

    # Add required original files and method_list files to the chunk 
    while IFS= read -r -u3 -d $'\0' dir; do
        cp -r "`basename ${dir}`/original" "$dir"
        (cd "${dir}/traditional_mutants" && ls -d * >> method_list)
    done 3< <(find "../chunk${index}/" -mindepth 1 -maxdepth 1 -type d -print0)

    ((index++))
done

# echo "Finished chunking $count mutants"
ms=$((($(gdate +%s%N) - $start)/1000000))

echo "Chunking finished $ms ms"