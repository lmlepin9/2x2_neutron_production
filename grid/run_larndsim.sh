#!/bin/bash

echo "Printing gpu details..."
nvidia-smi 


extract_name() {
    local filepath="$1"
    local filename="${filepath##*/}"         # remove everything before last /
    local core="${filename%%.EDEPSIM*}"      # remove everything after first ".EDEPSIM"
    echo "$core"
}


FILE_PREFIX_NAME="$(extract_name "$OUT_FILE_HDF5")"
echo "Processing file: ${FILE_PREFIX_NAME}"


export SIM_DIR='/pscratch/sd/l/lmlepin/2x2_sim_main/ND_Production'
export OUT_FILE_LARNDSIM="${OUT_DIR_LARNDSIM}/${FILE_PREFIX_NAME}.LARNDSIM.hdf5"
export OUT_FILE_FLOW="${OUT_DIR_FLOW}/${FILE_PREFIX_NAME}.FLOW.hdf5"
N_EVENTS=200


echo "==========================================="
# Run larnd-sim step:
echo "Running larnd-sim..."

cd $SIM_DIR/run-larnd-sim
./run_larnd_sim.sh $OUT_FILE_HDF5 $OUT_FILE_LARNDSIM $N_EVENTS


echo "============================================="
echo "Running flow..."
export FLOW_TOP_DIR="${SIM_DIR}/run-ndlar-flow"
cd $FLOW_TOP_DIR
echo "Current dir: ${PWD}"
./run_ndlar_flow.sh $OUT_FILE_LARNDSIM $OUT_FILE_FLOW