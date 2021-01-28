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
proj_name="wire-1.3.0"
exp_name="debug"

first_run=true
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

# Handler function
save_files()
{
    echo "Job ending soon, saving files." >&2 
    echo "Reached time limit, saving output." >> ${output_filename}.txt
    echo `date +"%Y-%m-%d_%H-%M-%S"` >> ${output_filename}.txt
    cp ${output_filename}.txt $HOME/output/mujava/$proj_name/$exp_name/$result_dir
    cp -r $proj_name/result $HOME/output/mujava/$proj_name/$exp_name/$result_dir
    exit -1
}

# Call handler on receiving SIGTERM
trap 'save_files' SIGTERM

# Copy dir (-r) MuJava workspace to node's scratch memory
cp -r $HOME/MuJavaRoot/$proj_name/MuJava "$TMPDIR"

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

# Generate and run mutants
java mujava.cli.genmutes $proj_name -debug > ${output_filename}.txt
echo -e "\n" >> ${output_filename}.txt
java mujava.cli.runmutes $proj_name -debug >> ${output_filename}.txt

# Save mutant files on the first run, but always save log files
if [ "$first_run" = true ] ; then
    cp -r $proj_name/result $HOME/output/mujava/$proj_name/$exp_name/$result_dir
    first_run=false
else
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
    cd "$TMPDIR"/MuJava
fi

# Copy output to home system and reset result folder
cp ${output_filename}.txt $HOME/output/mujava/$proj_name/$exp_name/$result_dir
