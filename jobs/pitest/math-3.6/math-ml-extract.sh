#!/bin/bash

#SBATCH -t 120:00:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G

proj_name="commons-math"
exp_name="ml-extract"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/pitest-ml "$TMPDIR"
cd "$TMPDIR"/pitest-ml
mvn clean install -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -gs "$TMPDIR"/settings.xml

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Mutation testing
mvn org.pitest:pitest-maven:mutationCoverage -Dmutators=ALL > rawout.txt
awk '/MutOperator/,/\[INFO/' rawout.txt | head -n -1 > ${output_filename}.csv

# Make output file dir
mkdir -p $HOME/output/pitest/$proj_name/$exp_name/$result_dir
cp ${output_filename}.csv $HOME/output/pitest/$proj_name/$exp_name/$result_dir