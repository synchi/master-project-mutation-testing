#!/bin/bash

#SBATCH -t 00:05:00
#SBATCH -p short

# S#BATCH --constraint=avx512
# S#BATCH --mem=90G

proj_name="gittestwire"
exp_name="inc-test"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/Pitest-1.5.2 "$TMPDIR"
cd "$TMPDIR"/Pitest-1.5.2
mvn clean install -DskipTests -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -gs "$TMPDIR"/settings.xml

cd wire-runtime

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

index=0
increments=1

# Perform incremental tests
while (($index < $increments))
do
  git stash >> ${output_filename}.txt
  git checkout `git log --reverse --ancestry-path HEAD..master | head -n 1 | cut -d \  -f 2` >> ${output_filename}.txt
  git stash apply >> ${output_filename}.txt

  mvn install -DskipTests
  mvn org.pitest:pitest-maven:mutationCoverage -DwithHistory -Dmutators=ALL >> ${output_filename}.txt

  echo $index"/"$increments >> ${output_filename}.txt
  printf "\n\n" >> ${output_filename}.txt
  ((index++))
done

# Make output file dir
mkdir -p $HOME/output/pitest/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/pitest/$proj_name/$exp_name/$result_dir
