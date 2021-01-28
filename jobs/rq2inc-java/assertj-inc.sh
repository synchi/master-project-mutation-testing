#!/bin/bash

#SBATCH -t 24:00:00
#SBATCH -p normal

#SBATCH --constraint=avx512
#SBATCH --mem=90G

proj_name="assertj-core"
exp_name="inc"

# Configure isolated Maven repo
cp $HOME/settings.xml "$TMPDIR"
mkdir "$TMPDIR"/repo

# Install Pitest to node's scratch memory
cp -r $HOME/Pitest-1.5.2 "$TMPDIR"
cd "$TMPDIR"/Pitest-1.5.2
mvn clean install -DskipTests -gs $TMPDIR/settings.xml

cp -r $HOME/Codesources/Java/$proj_name "$TMPDIR"
cd "$TMPDIR"/$proj_name
mvn clean install -DskipTests -Dlicense.skip  -gs "$TMPDIR"/settings.xml

# CUSTOMIZE
# cd wire-runtime

# Experiment setup
start_time=`date +"%Y-%m-%d_%H-%M-%S"`
output_filename="${SLURM_JOBID}_${proj_name}_${exp_name}_${start_time}_output"
result_dir="${SLURM_JOBID}_${start_time}_result"

index=0
increments=100

git reset --hard  >> ${output_filename}.txt
git checkout main  >> ${output_filename}.txt

# Get commit ids
raw=$(git rev-list 5f9b021c3^..HEAD --reverse | head -n 101)
commit_ids=($raw)

# First run
git checkout ${commit_ids[$index]}  >> ${output_filename}.txt

sed -i -e 's@<plugins>@<plugins><plugin><groupId>org.pitest</groupId><artifactId>pitest-maven</artifactId><version>1.5.2</version></plugin>@g' pom.xml  >> ${output_filename}.txt

sed -i -e 's@-SNAPSHOT</version>@</version>@g' pom.xml >> ${output_filename}.txt

mvn clean install -DskipTests -Dlicense.skip -gs "$TMPDIR"/settings.xml  >> ${output_filename}.txt

mvn org.pitest:pitest-maven:mutationCoverage -DwithHistory -Dmutators=ALL -DexcludedTestClasses=org.assertj.core.util.Files_newFolder_Test -Dlicense.skip >> ${output_filename}.txt
echo $index"/"$increments >> ${output_filename}.txt
printf "\n\n" >> ${output_filename}.txt
((index++))

# Perform incremental tests
while (($index < $increments))
do
  git reset --hard  >> ${output_filename}.txt
  git checkout ${commit_ids[$index]}  >> ${output_filename}.txt

  sed -i -e 's@<plugins>@<plugins><plugin><groupId>org.pitest</groupId><artifactId>pitest-maven</artifactId><version>1.5.2</version></plugin>@g' pom.xml  >> ${output_filename}.txt

  sed -i -e 's@-SNAPSHOT</version>@</version>@g' pom.xml >> ${output_filename}.txt

  mvn clean install -DskipTests -Dlicense.skip -gs "$TMPDIR"/settings.xml  >> ${output_filename}.txt

  mvn org.pitest:pitest-maven:mutationCoverage -DwithHistory -Dmutators=ALL -DexcludedTestClasses=org.assertj.core.util.Files_newFolder_Test -Dlicense.skip >> ${output_filename}.txt

  echo $index"/"$increments >> ${output_filename}.txt
  printf "\n\n" >> ${output_filename}.txt
  ((index++))
done

# Make output file dir
mkdir -p $HOME/output/pitest/$proj_name/$exp_name/$result_dir
cp ${output_filename}.txt $HOME/output/pitest/$proj_name/$exp_name/$result_dir

