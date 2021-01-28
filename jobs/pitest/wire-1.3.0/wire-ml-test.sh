#!/bin/bash

#SBATCH -t 00:05:00
#SBATCH -p short

proj_name="wire"
exp_name="ml-test-predictionfeats"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/pitest-predict "$TMPDIR"
cd "$TMPDIR"/pitest-predict
mvn clean install -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -gs "$TMPDIR"/settings.xml

cd wire-runtime

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Mutation testing
mvn org.pitest:pitest-maven:mutationCoverage -Dmutators=AOR > ${output_filename}.txt

# Make output file dir
mkdir -p $HOME/output/pitest/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/pitest/$proj_name/$exp_name/$result_dir

sleep 5m
