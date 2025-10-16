# Run this script using salloc  
# salloc -A dune -q interactive -C gpu -t 30

# Configure your test ----------------------------------

# Declare it to your own output dirdctory
OUT_DIR="/global/cfs/cdirs/dune/users/lmlepin/2x2_neutron_prod/PNS_tests"
OUT_NAME="DTG_P385_test"
OUTPUT_H5="${OUT_DIR}/${OUT_NAME}.EDEPSIM.hdf5"
N_EVENTS=20

#------------------------------------------------------

echo "==========================================="
# Run larnd-sim step:
echo "Running larnd-sim..."

cd $NEUTRON_TOP_DIR/run-larnd-sim
echo "Current dir: ${PWD}"
OUTPUT_LARNDSIM="${OUT_DIR}/${OUT_NAME}.LARNDSIM.hdf5"
./run_larnd_sim.sh $OUTPUT_H5 $OUTPUT_LARNDSIM $N_EVENTS


echo "============================================="
echo "Running flow..."
FLOW_TOP_DIR="${NEUTRON_TOP_DIR}/run-ndlar-flow"
echo $FLOW_TOP_DIR
cd $FLOW_TOP_DIR
echo "Current dir: ${PWD}"
OUT_FILE_FLOW="${OUT_DIR}/${OUT_NAME}.FLOW.hdf5"
./run_ndlar_flow.sh $OUTPUT_LARNDSIM $OUT_FILE_FLOW
