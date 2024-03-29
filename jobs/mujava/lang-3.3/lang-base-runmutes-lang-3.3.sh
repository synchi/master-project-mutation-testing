#!/bin/bash


# Require one dedicated node; Ran performance tests as suggested by SURFsara technical staff,
# to determine impact of using shared processes. Found high impact, therefore -N 1 required.
# Part of my research will involve a parallelized version, and requires this baseline.

# Secondary performance evaluations revealed consistent variations in experiment durations.
# I require accurate and comparable time measurements, therefore I define additional constraints.

#SBATCH -t 120:00:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G


# Experiment setup
chunk="0"
proj_name="lang-3.3"
exp_name="base-runmutes-chunk$chunk"

start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Handler function
save_files()
{
    echo "Job ending soon, saving output." >&2 
    echo "Reached time limit, saving output." >> ${output_filename}.txt
    echo `date +"%Y-%m-%d_%H-%M-%S"` >> ${output_filename}.txt
    cp ${output_filename}.txt $HOME/output/mujava/$proj_name/$exp_name/$result_dir
    exit -1
}

# Call handler on receiving SIGTERM
trap 'save_files' SIGTERM

# Copy dir (-r) MuJava workspace to node's scratch memory
cp -r $HOME/MuJavaRoot/$proj_name/MuJava "$TMPDIR"

# Copy chunk of mutants 
cp -r $HOME/chunk4/$proj_name/chunk$chunk "$TMPDIR"/MuJava/$proj_name
rm -r "$TMPDIR"/MuJava/$proj_name/result
mv "$TMPDIR"/MuJava/$proj_name/chunk$chunk "$TMPDIR"/MuJava/$proj_name/result

# Copy Java 8 to node's scratch memory
cp -r $HOME/jdk1.8.0_251 "$TMPDIR"

# Set env variables
export JAVA_HOME="$TMPDIR"/jdk1.8.0_251
export PATH="$TMPDIR"/jdk1.8.0_251/bin:$PATH
export CLASSPATH=$CLASSPATH:"$TMPDIR"/MuJava/*:"$TMPDIR"/MuJava/$proj_name/lib/*:

# Go to MuJava workspace on node
cd "$TMPDIR"/MuJava

# Set config file
echo "MuJava_HOME=$TMPDIR/MuJava" > mujavaCLI.config

# Make output file dir
mkdir -p $HOME/output/mujava/$proj_name/$exp_name/$result_dir

# Run mutants
java mujava.cli.runmutes $proj_name -timed >> ${output_filename}.txt

# Save log files
cd $proj_name/result
for D in `find . -mindepth 1 -maxdepth 1 -type d `
do
    mv $D/traditional_mutants/method_list $D
    mv $D/traditional_mutants/mutant_list $D
    mv $D/traditional_mutants/mutation_log $D
    mv $D/traditional_mutants/result_list.csv $D
    rm -r $D/traditional_mutants
    rm -r $D/class_mutants
    cp -r $D $HOME/output/mujava/$proj_name/$exp_name/$result_dir
done  

# Copy output to home system 
cd "$TMPDIR"/MuJava
cp ${output_filename}.txt $HOME/output/mujava/$proj_name/$exp_name/$result_dir
