#!/bin/bash
#SBATCH --job-name=myjob               # create a short name for your job
#SBATCH --nodes=1                      # node count
#SBATCH --ntasks=1                     # total number of tasks across all nodes
#SBATCH --cpus-per-task=1              # cpu-cores per task (>1 if multi-threaded tasks)
#SBATCH --mem-per-cpu=32G              # memory per cpu-core (4G is default)
#SBATCH --time=01:03:00                # total run time limit (HH:MM:SS)
#SBATCH --mail-type=begin              # send email when job begins
#SBATCH --mail-type=end                # send email when job ends
#SBATCH --mail-user=example@email.edu  # replace with your email
#SBATCH -o NAME.log                    # log file output

# write commands to run your program below
module purge
module load anaconda3/2022.5
conda activate ENVNAME
