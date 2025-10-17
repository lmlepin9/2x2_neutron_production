#!/bin/bash

# Check that the top directory has been set

if [ -z "${NEUTRON_TOP_DIR}" ]; then
    echo "Error: NEUTRON_TOP_DIR is not set. Please source setup_production.sh in the top directory"
    exit 1
fi

echo "NEUTRON_TOP_DIR is set to: ${NEUTRON_TOP_DIR}"


# Create scratch output dir
MY_SCRATCH_OUTDIR="$SCRATCH/grid_output"
mkdir -p $MY_SCRATCH_OUTDIR



# export variables to configure your job 
export NEVENTS=100000
export PS_LIST='MyQGSP_BERT_ArHP'
export PROJECT_NAME='AmBe_top_mod0_test_10-16'
export MAC_FILE="${NEUTRON_TOP_DIR}/macros/2x2_AmBe_out_top_mod0.mac"
export WORK_TOP_DIR="$SCRATCH/grid_workdir/${PROJECT_NAME}"

# Create workdir if it does not exist
mkdir -p $WORK_TOP_DIR
echo "Working top dir: ${WORK_TOP_DIR}"

export OUT_DIR_EDEPSIM="$SCRATCH/grid_output/${PROJECT_NAME}/EDEPSIM"
# Create output dir if it does not exist
mkdir -p $OUT_DIR_EDEPSIM 
echo "edepsim output dir: ${OUT_DIR_EDEPSIM}"

# set the number of jobs to submit 
for i in {0..5}
do
  
  echo "Submitting job $i for AmBe source"
  export JOB=$i
  sbatch shifter_run.slurm 

done

