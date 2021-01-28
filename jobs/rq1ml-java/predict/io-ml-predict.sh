#!/bin/bash

#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G

proj_name="commons-io"
exp_name="ml-predict"
mod_name="io"

module load 2019
module load 2020
module load Python/3.8.2-GCCcore-9.3.0

pip install --user sklearn
pip install --user pandas

# Make work dir
mkdir "$TMPDIR"/py
mkdir "$TMPDIR"/predictionfiles

# Copy required files
cp $HOME/rq1ml-java/head.csv "$TMPDIR"/py

# Copy python script
cp $HOME/rq1ml-java/predict.py "$TMPDIR"/py

# Execute predictor
cd "$TMPDIR"/py
python3 predict.py $mod_name &

##### Config + Run Pitest-predict
cd "$TMPDIR"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/pitest-predict "$TMPDIR"
cd "$TMPDIR"/pitest-predict
mvn clean install -DskipTests -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -gs "$TMPDIR"/settings.xml

 

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Mutation testing
mvn org.pitest:pitest-maven:mutationCoverage -Dmutators=ALL > ${output_filename}.txt

# Make output file dir
mkdir -p $HOME/rq1ml-java/output/java-predict/$proj_name/$exp_name/$result_dir

# Save results
cp ${output_filename}.txt $HOME/rq1ml-java/output/java-predict/$proj_name/$exp_name/$result_dir
cp "$TMPDIR"/predictionfiles/eval.csv $HOME/rq1ml-java/output/java-predict/$proj_name/$exp_name/$result_dir



