#!/bin/bash
###################################################################
# 
# The script processes a single RAW file creating a PPM using 
# darktable-cli and calculates the average time provided 
# by the darktable log file. Different sidecar files could be defined 
# reflecting different image developments. Optional OpenCL parametres 
# could be set. As default OpenCL true/false will be passed to darktable-cli. 
#
# There is no error handling or checking if OpenCL works or not.
#
#
####################################################################

# set RAW file
RAWFILE="bench.DNG"

# take different developments of the same RAW file
# test profiled denoise on/off
declare -A XMPFILE
XMPFILE["profiled denoise=on"]="bench.DNG.xmp"
XMPFILE["profiled denoise=off"]="bench_01.DNG.xmp"

# set number of cylces
NOCYCLES=1


# OpenCL parametes in darktablerc
# array with possible parameters
declare -A oclbin

oclbin["opencl0"]="opencl=true"
oclbin["opencl1"]="opencl=false"


# Outputfilename
OUTFILE="opencltest.ppm"
LOGFILE="dt_benchmark.log"
TEMPFILE=`mktemp`
OPENCLCONFIG=""


#####################################

>$LOGFILE

#function to run darktable-cli with specific parameters
dt_cli_cycle()
{
  for ((i=0 ; i < NOCYCLES ; i++)) do
    darktable-cli $RAWFILE  $XMP $OUTFILE --width 0 --height 0 --hq 1 --core -d opencl -d perf --conf $OPENCLCONFIG &> $LOGFILE;
    rm $OUTFILE;
    PTIME[$i]=$(awk '/dev_process_export/ { print $6 }' $LOGFILE);
    echo $PTIME[$i]
    done;
}

# cycle over given parameter list and run darktable-cli
echo "Starting benchmarking - processing time in sec"
for k in "${!XMPFILE[@]}"; do
	
	XMP=${XMPFILE[$k]}
	echo "sidecarfile: "$k
	
	for i in "${!oclbin[@]}"; do

		OPENCLCONFIG=${oclbin[$i]}
		echo -n $OPENCLCONFIG":" 

		dt_cli_cycle
        
	done
done
