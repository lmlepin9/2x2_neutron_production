#!/usr/bin/env bash


pushd run-larnd-sim
./install_larnd_sim.sh
popd

pushd run-ndlar-flow
./install_ndlar_flow.sh
popd


# HACK because we forgot to include GNU time in some of the containers
TMP_BIN="tmp_bin"
mkdir -p $TMP_BIN

# If you have it on your host system (/usr/bin/time), copy it into tmp_bin directory
# otherwise, download it from the link provided by Matt
if [ -f /usr/bin/time ]; then
  cp /usr/bin/time $TMP_BIN/
else
  # download the container-compatible version of GNU time into the right path
  TIME_LINK="https://portal.nersc.gov/project/dune/data/2x2/people/mkramer/bin/time"
  wget -q -O "$TMP_BIN/time" ${TIME_LINK} || {
    echo "Download failed"
    exit 1
    } 
    timeProg=$TMP_BIN/time
    # check if "time" is executable
    if [ ! -x $timeProg ]; then
      chmod +x "$timeProg"
    fi
fi