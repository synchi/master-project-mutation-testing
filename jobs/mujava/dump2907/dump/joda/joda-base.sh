#!/bin/bash

# Take (NOW 48H BECAUSE MAINT) 96h (4d, just in case), evaluate after initial runs.
# Require one dedicated node; Ran performance tests as suggested by SURFsara technical staff,
# to determine impact of using shared processes. Found high impact, therefore -N 1 required.
# Part of my research will involve a parallelized version, and requires this baseline.

# Secondary performance evaluations revealed consistent variations in experiment durations.
# I require accurate and comparable time measurements, therefore I define additional constraints.

#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G


proj_name="joda"
exp_name="baseline"

# Copy dir (-r) MuJava workspace to node's scratch memory
cp -r $HOME/MuJavaRoot/$proj_name/MuJava "$TMPDIR"

# Copy Java 8 to node's scratch memory
cp -r $HOME/jdk1.8.0_251 "$TMPDIR"

# Set env variables
export JAVA_HOME="$TMPDIR"/jdk1.8.0_251
export PATH="$TMPDIR"/jdk1.8.0_251/bin:$PATH
export CLASSPATH=$CLASSPATH:"$TMPDIR"/MuJava/*:

# Go to MuJava workspace on node
cd "$TMPDIR"/MuJava

# Set config file
echo "MuJava_HOME=$TMPDIR/MuJava" > mujavaCLI.config

# Experiment setup
first_run=true
start_time=`date +"%Y-%m-%d_%H-%M-%S-%3N"`
output_filename="${proj_name}_${exp_name}_${start_time}_output"
result_dir="${start_time}_result"

# Make output file dir
mkdir -p $HOME/output/mujava/$proj_name/$exp_name/$result_dir

# Generate and run mutants
java mujava.cli.genmutes $proj_name -timed > ${output_filename}.txt

# Before maintenance might not make it so copy mutants
mkdir $HOME/output/mujava/jodabeforemaint
cp -r joda/result $HOME/output/mujava/jodabeforemaint

echo -e "\n" >> ${output_filename}.txt
java mujava.cli.runmutes $proj_name -timed >> ${output_filename}.txt

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
fi

# Copy output to home system and reset result folder
cd "$TMPDIR"/MuJava
cp ${output_filename}.txt $HOME/output/mujava/$proj_name/$exp_name/$result_dir

# Reset result folder 
rm -rfv $proj_name/result && mkdir $proj_name/result


