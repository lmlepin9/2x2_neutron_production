 #!/user/bin/bash

# Check that the top directory has been set

if [ -z "${NEUTRON_TOP_DIR}" ]; then
    echo "Error: NEUTRON_TOP_DIR is not set. Please source setup_production.sh in the top directory"
    exit 1
fi

echo "NEUTRON_TOP_DIR is set to: ${NEUTRON_TOP_DIR}"


# Setup dependencies
source /pscratch/sd/l/lmlepin/setup_2x2_container.sh


# --------------------- Configure your test here--------------------------------------------
ARCUBE_GEOM="${NEUTRON_TOP_DIR}/geometry/Merged2x2MINERvA_v4_noRock_2x2_only_sense.gdml"
NEVENTS='100000'
OUT_DIR='/global/cfs/cdirs/dune/users/lmlepin/2x2_neutron_prod/AmBe_tests'
MAC_FILE="${NEUTRON_TOP_DIR}/macros/2x2_AmBe_in_mod2.mac"
PS_LIST="MyQGSP_BERT_ArHP"
OUT_NAME="2x2_AmBe_in_mod2_prompt_window_test_11-19-2025"
CHANGE_TIME=1 # Pick 1 if forcing specific time for your captures 


# --------------------- edep-sim --------------------------------------------
mkdir -p $OUT_DIR
edep-sim -C -g "$ARCUBE_GEOM" -o "${OUT_DIR}/${OUT_NAME}.root" -p "$PS_LIST" -e "$NEVENTS" "$MAC_FILE"



# --------------------- Run capture filter --------------------------------------------
IS_SPILL=1
FILE_ID=1
PULSE_PERIOD=1.2 # in s
OUT_FILE_SPILL="${OUT_DIR}/${OUT_NAME}_filtered.root"
root -l -b -q "${NEUTRON_TOP_DIR}/util/filter_capture_events.cpp(\"${OUT_DIR}/${OUT_NAME}.root\",\"${OUT_FILE_SPILL}\", ${IS_SPILL}, ${FILE_ID})"


# ---------------------Run convert2h5 --------------------------------------------
# Run convert2h5 
echo "Running convert2h5..."
export OUTPUT_H5="${OUT_DIR}/${OUT_NAME}.EDEPSIM.hdf5"
rm -f $OUTPUT_H5
# After going from ROOT 6.14.06 to 6.28.06, apparently we need to point CPATH to
# the edepsim-io headers. Otherwise convert2h5 fails. (This "should" be set in
# the container already.)
export CPATH=$EDEPSIM/include/EDepSim:$CPATH
if [ $IS_SPILL == 0 ]; then
    python3 ${NEUTRON_TOP_DIR}/run-larnd-sim/larnd-sim/cli/dumpTree.py --input_file $OUT_FILE_SPILL --output_file "$OUTPUT_H5"
else 
    python3 ${NEUTRON_TOP_DIR}/run-convert2h5/convert_edepsim_roottoh5.py --input_file "$OUT_FILE_SPILL" --output_file "$OUTPUT_H5" "$keepAllDets" --gps True
fi


# --------------------- Force capture time  --------------------------------------------
if [ $CHANGE_TIME == 1 ]; then
    OUTPUT_MOD_FILE="${OUT_DIR}/${OUT_NAME}_MOD.EDEPSIM.hdf5"
    rm -r $OUTPUT_MOD_FILE
    echo "You have selected to force the capture time"
    python3 ${NEUTRON_TOP_DIR}/util/prompt_captures_filter.py "$OUTPUT_H5" "$OUTPUT_MOD_FILE"
fi 
