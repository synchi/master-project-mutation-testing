#!/bin/bash

#SBATCH -t 01:00:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G

proj_name="commons-functor"
exp_name="base-comp"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/Pitest-1.5.2 "$TMPDIR"
cd "$TMPDIR"/Pitest-1.5.2
mvn clean install -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -gs "$TMPDIR"/settings.xml

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Mutation testing
mvn org.pitest:pitest-maven:mutationCoverage -Dmutators=AOR,INCREMENTS,UOI,AOD,ROR,CONDITIONALS_BOUNDARY,INVERT_NEGS,ABS,MATH,OBBN,CRCR > ${output_filename}.txt

# Make output file dir
mkdir -p $HOME/output/pitest/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/pitest/$proj_name/$exp_name/$result_dir