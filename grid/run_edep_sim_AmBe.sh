#!/bin/bash

# Check that the top directory has been set

if [ -z "${NEUTRON_TOP_DIR}" ]; then
    echo "Error: NEUTRON_TOP_DIR is not set. Please source setup_production.sh in the top directory"
    exit 1
fi

echo "Running edep-sim, this are the variables used:"
echo "NEVENTS: ${NEVENTS}"
echo "PHYSLIST: ${PS_LIST}"
echo "SOURCE: ${TYPE}"
echo "JOB NUM: ${JOB}"
echo "MAC FILE: ${MAC_FILE}"

timestamp=$(date +%s)

source $SCRATCH/setup_2x2_container.sh 

# Where to look for the geometry
export ARCUBE_GEOM="${NEUTRON_TOP_DIR}/Merged2x2MINERvA_v4_noRock_2x2_only_sense.gdml"


# edep-sim output file
export OUT_FILE_ROOT="2x2_${PS_LIST}_${TYPE}_${timestamp}_${JOB}.root"
# spill-formatted and capture filtered file
export OUT_FILE_SPILL="2x2_${PS_LIST}_${TYPE}_${timestamp}_${JOB}_spill.root"
# convert2hdf5 file
export OUT_FILE_HDF5="2x2_${PS_LIST}_${TYPE}_${timestamp}_${JOB}.EDEPSIM.hdf5"
# Time modified hdf5 file 
export OUT_FILE_MOD_HDF5="2x2_${PS_LIST}_${TYPE}_${timestamp}_${JOB}_TIME_MOD.EDEPSIM.hdf5"
# Set to 1 if spill format is desired
export IS_SPILL=1
# Set the starting time for your captures 
export OFFSET_TIME=5

# Create working directory
export WORK_DIR="${WORK_TOP_DIR}/${TYPE}_${timestamp}_${JOB}"
mkdir -p $WORK_DIR

cd $WORK_DIR 
echo $PWD 

echo "The following edep-sim command will be executed..."
echo "edep-sim -g ${ARCUBE_GEOM} -o ${OUT_FILE_ROOT} -p ${PS_LIST} -u -e ${NEVENTS} ${MAC_FILE}"
edep-sim -C -g "$ARCUBE_GEOM" -o "$OUT_FILE_ROOT" -p "$PS_LIST" -e "$NEVENTS" "$MAC_FILE"

# Filter for captures 
echo "Runnning neutron capture filter..."
root -l -b -q "${NEUTRON_TOP_DIR}/util/filter_capture_events.C(\"${OUT_FILE_ROOT}\",\"${OUT_FILE_SPILL}\", ${IS_SPILL}, ${JOB})"


# Here we perform the conversion from .root to hdf5 
echo "Running convert2h5 now..."

# After going from ROOT 6.14.06 to 6.28.06, apparently we need to point CPATH to
# the edepsim-io headers. Otherwise convert2h5 fails. (This "should" be set in
# the container already.)
export CPATH=$EDEPSIM/include/EDepSim:$CPATH

python3 ${NEUTRON_TOP_DIR}/run-convert2h5/convert_edepsim_roottoh5.py --input_file "$OUT_FILE_SPILL" --output_file "$OUT_FILE_HDF5" --gps True 


echo "Running time mod..."
python3 ${NEUTRON_TOP_DIR}/util/force_capture_time.py "$OUT_FILE_HDF5" "$OUT_FILE_MOD_HDF5" $OFFSET_TIME 


# Move edepsim outputs to output dir 
mv $OUT_FILE_ROOT $OUT_FILE_SPILL $OUT_FILE_HDF5 $OUT_FILE_MOD_HDF5 $OUT_DIR_EDEPSIM
