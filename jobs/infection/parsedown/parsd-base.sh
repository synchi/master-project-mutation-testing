#!/bin/bash

#SBATCH -t 1:30:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G

proj_name="parsedown"
exp_name="base"

# Copy container to node's scratch memory
cp $HOME/ubu.sif "$TMPDIR"

# Copy Infection to node's scratch memory
cp -r $HOME/infection "$TMPDIR"
mv "$TMPDIR"/infection "$TMPDIR"/phpmutator 

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
singularity exec --pwd $PWD ../ubu.sif "$TMPDIR"/phpmutator/bin/infection --no-progress > ${output_filename}.txt

# Make output file dir
mkdir -p $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp infection.log $HOME/output/infection/$proj_name/$exp_name/$result_dir