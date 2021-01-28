#!/bin/bash

#SBATCH -t 01:00:00

proj_name="phpdotenv"
exp_name="ml-extract"

# Copy container to node's scratch memory
cp $HOME/ubu.sif "$TMPDIR"

# Copy Infection to node's scratch memory
cp -r $HOME/inf-ml "$TMPDIR"
mv "$TMPDIR"/inf-ml "$TMPDIR"/phpmutator 

# Copy project
cp -r $HOME/Codesources/PHP/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Install env vars
export LD_PRELOAD=""
export PATH="/root/.composer/vendor/bin":$PATH
export PATH="/home/saraoonk/.config/composer/vendor/bin":$PATH

# Mutation testing
singularity exec --pwd $PWD ../ubu.sif "$TMPDIR"/phpmutator/bin/infection --no-progress > rawout.txt
awk '/Location,/,/\Time:/' rawout.txt | head -n -1 > ${output_filename}.csv

# Make output file dir
mkdir -p $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp infection.log $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp ${output_filename}.csv $HOME/output/infection/$proj_name/$exp_name/$result_dir