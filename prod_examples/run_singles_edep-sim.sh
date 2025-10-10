 #!/user/bin/env bash

# Check that the top directory has been set

if [ -z "${NEUTRON_TOP_DIR}" ]; then
    echo "Error: NEUTRON_TOP_DIR is not set. Please source setup_production.sh in the top directory"
    exit 1
fi

echo "NEUTRON_TOP_DIR is set to: ${NEUTRON_TOP_DIR}"


# Setup dependencies
# Hard-coded for now... 
# Its better to modify mjkramer image and add yaml-cpp and DLPGenerator to make my edep-sim version to work out of the box 
source /pscratch/sd/l/lmlepin/setup_2x2_container.sh

export ARCUBE_GEOM="${NEUTRON_TOP_DIR}/geometry/Merged2x2MINERvA_v4_noRock_2x2_only_sense.gdml"
export NEVENTS='10000'
export SIM_DIR='/pscratch/sd/l/lmlepin/2x2_sim_develop/2x2_sim'
export OUT_DIR='/global/cfs/cdirs/dune/users/lmlepin/2x2_neutron_prod/singles_tests'
export MAC_FILE="${NEUTRON_TOP_DIR}/macros/2x2_DTG_P385_single_no_pulse.mac"
export PS_LIST='MyQGSP_BERT_ArHP'

# Output files
export OUT_NAME="DTG_P385_singles_test"
export OUT_FILE="${OUT_DIR}/${OUT_NAME}_edep_sim.root"
export OUT_FILE_SPILL="${OUT_DIR}/${OUT_NAME}.root"
export OUTPUT_H5="${OUT_DIR}/${OUT_NAME}.EDEPSIM.hdf5"

# After going from ROOT 6.14.06 to 6.28.06, apparently we need to point CPATH to
# the edepsim-io headers. Otherwise convert2h5 fails. (This "should" be set in
# the container already.)
export CPATH=$EDEPSIM/include/EDepSim:$CPATH
export keepAllDets=False

# Run edep-sim 
edep-sim -C -g "$ARCUBE_GEOM" -o "$OUT_FILE" -p "$PS_LIST" -e "$NEVENTS" "$MAC_FILE"


# Force spill-like event time 
#root -l -b -q -e "gSystem->Load(\"$LIBTG4EVENT_DIR/libTG4Event.so\")" \
#                 "${NEUTRON_TOP_DIR}/utils/force_spill_like_4_singles.cpp(\"${OUT_FILE}\", \"${OUT_FILE_SPILL}\")"
root -l -b -q "${NEUTRON_TOP_DIR}/utils/force_spill_like_4_singles.cpp(\"${OUT_FILE}\", \"${OUT_FILE_SPILL}\")"


# Run convert2h5 
echo "Running convert2h5..."
rm -f $OUTPUT_H5
echo "Keep all dets? ${keepAllDets}"
python3 ${SIM_DIR}/run-convert2h5/convert_edepsim_roottoh5.py --input_file "$OUT_FILE_SPILL" --output_file "$OUTPUT_H5" --gps True
