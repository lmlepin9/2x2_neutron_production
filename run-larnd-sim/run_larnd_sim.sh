#!/usr/bin/env bash

# By default (i.e. if ND_PRODUCTION_RUNTIME isn't set), run on the host's venv
source ../util/reload_in_container.inc.sh
source ../util/init.inc.sh


source "$NEUTRON_TOP_DIR/run-larnd-sim/larnd.venv/bin/activate"


inFile=$1
outFile=$2
nEvents=$3

rm -f "$outFile"

# Should I compress? 
compression="None"
if [[ "$ND_PRODUCTION_COMPRESS" != "" ]]; then
    echo "Enabling compression of HDF5 datasets with $ND_PRODUCTION_COMPRESS"
    compression="$ND_PRODUCTION_COMPRESS"
fi


if [[ -n "$ND_PRODUCTION_LARNDSIM_CONFIG" ]]; then
    run simulate_pixels.py "$ND_PRODUCTION_LARNDSIM_CONFIG" \
        --input_filename "$inFile" \
        --output_filename "$outFile" \
        --rand_seed "$seed" \
        --compression "$compression"
else
    [ -z "$ND_PRODUCTION_LARNDSIM_DETECTOR_PROPERTIES" ] && export ND_PRODUCTION_LARNDSIM_DETECTOR_PROPERTIES="larnd-sim/larndsim/detector_properties/2x2.yaml"
    [ -z "$ND_PRODUCTION_LARNDSIM_PIXEL_LAYOUT" ] && export ND_PRODUCTION_LARNDSIM_PIXEL_LAYOUT="larnd-sim/larndsim/pixel_layouts/multi_tile_layout-2.4.16.yaml"
    [ -z "$ND_PRODUCTION_LARNDSIM_RESPONSE_FILE" ] && export ND_PRODUCTION_LARNDSIM_RESPONSE_FILE="larnd-sim/larndsim/bin/response_44.npy"
    [ -z "$ND_PRODUCTION_LARNDSIM_LUT_FILENAME" ] && export ND_PRODUCTION_LARNDSIM_LUT_FILENAME="/global/cfs/cdirs/dune/www/data/2x2/simulation/larndsim_data/light_LUT_M123_v1/lightLUT_M123.npz"
    [ -z "$ND_PRODUCTION_LARNDSIM_LIGHT_DET_NOISE_FILENAME" ] && export ND_PRODUCTION_LARNDSIM_LIGHT_DET_NOISE_FILENAME="larnd-sim/larndsim/bin/light_noise_2x2_4mod_July2023.npy"
    [ -z "$ND_PRODUCTION_LARNDSIM_SIMULATION_PROPERTIES" ] && export ND_PRODUCTION_LARNDSIM_SIMULATION_PROPERTIES="larnd-sim/larndsim/simulation_properties/2x2_NuMI_sim.yaml"

    run simulate_pixels.py --input_filename "$inFile" \
        --n_events $nEvents \
        --output_filename "$outFile" \
        --rand_seed "$seed" \
        --compression "$compression"
fi

