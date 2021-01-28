#!/bin/bash

#SBATCH -t 01:00:00

proj_name="mime4j"
exp_name="ml-score"

module load 2019
module load 2020
module load Python/3.8.2-GCCcore-9.3.0

pip install --user sklearn
pip install --user pandas

# Make work dir
mkdir "$TMPDIR"/$proj_name

# Copy dataset
cp -r $HOME/rq1ml/ml-features "$TMPDIR"/$proj_name

# Copy python script
cp $HOME/rq1ml/"$proj_name"_gbclf.py "$TMPDIR"/$proj_name

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Build and evaluate cross-project mutation classifier
cd "$TMPDIR"/$proj_name
python3 "$proj_name"_gbclf.py > ${output_filename}.txt

# Make output file dir
mkdir -p $HOME/rq1ml/output/java/$proj_name/$exp_name/$result_dir

# Save results
cp ${output_filename}.txt $HOME/rq1ml/output/java/$proj_name/$exp_name/$result_dir
cp "$proj_name"_model.pkl $HOME/rq1ml/output/java/$proj_name/$exp_name/$result_dir




