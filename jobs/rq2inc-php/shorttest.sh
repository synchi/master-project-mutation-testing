#!/bin/bash

#SBATCH -t 00:05:00
#SBATCH -N 1
#SBATCH -p short

#  S#BATCH --constraint=avx512
#  S#BATCH --mem=90G

proj_name="phpdotenv"
exp_name="incshorttest"

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

index=0
increments=100

# Save infection config
git add infection*  >> ${output_filename}.txt
git checkout master  >> ${output_filename}.txt

# Get commit ids CHANGE BASE
raw=$(git rev-list 1bdf24f^..HEAD --reverse | head -n 101)
commit_ids=($raw)

while (($index < $increments))
do
  previous=$((index++))
  git checkout ${commit_ids[$index]}  >> ${output_filename}.txt
  
  # Install / update
  singularity exec --pwd $PWD ../ubu.sif composer install >> ${output_filename}.txt
  singularity exec --pwd $PWD ../ubu.sif composer update >> ${output_filename}.txt
  
  # Mutation based on diff prev
  singularity exec --pwd $PWD ../ubu.sif "$TMPDIR"/phpmutator/bin/infection --git-diff-base=${commit_ids[$previous]} --git-diff-filter=AM  --no-progress >> ${output_filename}.txt
done

# Make output file dir
mkdir -p $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp infection.log $HOME/output/infection/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/infection/$proj_name/$exp_name/$result_dir



