#!/bin/bash
set -x
echo Start  `date`
echo Site:${GLIDEIN_ResourceName}
echo "the worker node is " `hostname` "OS: "  `uname -a`
whoami
id

cd $_CONDOR_SCRATCH_DIR

IFDH_OPTION=""

if [ -z $GROUP ]; then

# try to figure out what group the user is in
GROUP=`id -gn`

fi

export IFDH_DEBUG=1

case $GROUP in

lar1nd)
SCRATCH_DIR="/pnfs/lar1nd/scratch/users"
;;
esac

voms-proxy-info --all


source /grid/fermiapp/products/common/etc/setups.sh
source /cvmfs/oasis.opensciencegrid.org/fermilab/products/larsoft/setup

setup ifdhc

echo "Here is the your environment in this job: " > job_output_${CLUSTER}.${PROCESS}.log
env >> job_output_${CLUSTER}.${PROCESS}.log

echo "group = $GROUP"

if [ -z ${GRID_USER} ]; then
GRID_USER=`basename $X509_USER_PROXY | cut -d "_" -f 2`
fi

echo "GRID_USER = `echo $GRID_USER`"

sleep $[ ( $RANDOM % 10 )  + 1 ]m

umask 002

cd $_CONDOR_SCRATCH_DIR


####################################
###### setup your needed products here, e.g. geant4 etc...
####################################

# source /grid/fermiapp/products/larsoft/setup
# setup geant4 v4_9_6_p03e -q debug:e6 
# setup geant4 v4_9_6_p03e -q e6:prof    #no debug information, faster. 



####################################
###### setup LArSoft
####################################
version=v03_03_00
source /grid/fermiapp/larsoft/products/setup 
setup git
setup gitflow 
setup mrb 
export MRB_PROJECT=larsoft 
setup larsoft ${version} -q debug:e6  
cd /lar1nd/app/users/andrzejs/  
cd lar1ndDe${version}/ 
source localProducts_larsoft_${version}_debug_e6/setup  
mrbslp 


####################################
#### This is where you copy all of your necessary files to the worker node 
#### ( If applicable )
####################################

# ifdh cp /pnfs/lar1nd/scratch/users/andrzejs/hello.out .


 
#######
####### launch executable
#######

cd $_CONDOR_SCRATCH_DIR

lar -c prodsingle_lar1nd.fcl -n 5 -o test.root -T test_hist.root &> output_${CLUSTER}.${PROCESS}.log



#######
####### Copy results back 
#######

ifdh mkdir ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}

ifdh cp test.root ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}/
ifdh cp test_hist.root ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}/


ifdh cp output*log ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}/


#ifdh cp debug*log ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}/

#######
####### The rest is some copying info, that is not necessarily relevant.
#######


if [ -z "$SCRATCH_DIR" ]; then
    echo "Invalid dCache scratch directory, not copying back"
else

#export IFDH_DEBUG=1

    

    # first do lfdh ls to check if directory exists
    ifdh ls ${SCRATCH_DIR}/$GRID_USER
    # A non-zero exit value probably means it doesn't, so create it
    if [ $? -ne 0 && -z "$IFDH_OPTION" ]; then
	
	echo "Unable to read ${SCRATCH_DIR}/$GRID_USER. Make sure that you have created this directory and given it group write permission (chmod g+w ${SCRATCH_DIR}/$GRID_USER)."
	exit 74
#	ifdh mkdir ${SCRATCH_DIR}/$GRID_USER
#	if [ "$?" -ne "0" ]; then
#	    echo "Unable to make ${SCRATCH_DIR}/$GRID_USER directory"
#	else
#	    ifdh cp -D --force=gridftp job_output_${CLUSTER}.${PROCESS}.log ${SCRATCH_DIR}/${GRID_USER}/
#	    if [ "$?" -ne "0" ]; then
#		echo "Error $? when copying to dCache scratch area!!!"
#	    fi
#    fi
    else
        # directory already exists, so let's copy
	ifdh cp -D $IFDH_OPTION job_output_${CLUSTER}.${PROCESS}.log ${SCRATCH_DIR}/${GRID_USER}/output_${CLUSTER}.${PROCESS}/
	if [ $? -ne 0 ]; then
	    echo "Error $? when copying to dCache scratch area!\n If you created ${SCRATCH_DIR}/${GRID_USER} yourself,\n make sure that it has group write permission."
	    exit 73
	fi
    fi
fi

echo "End `date`"

exit 0
