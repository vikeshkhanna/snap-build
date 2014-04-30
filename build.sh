#!/bin/bash

SNAPBUILD_ROOT=$HOME'/snap-build'
SNAPR_DIR=$SNAPBUILD_ROOT'/snapr'
SNAPR_GIT='https://github.com/snap-stanford/snapr.git'
BUILD_DB=`pwd`'/build.db'

# Start time
TSTART=`date +%s`
LOGBASE_DIR=`pwd`"/logs/"
LOG_FILE="build.$TSTART.log"
BUILD_LOG="$LOGBASE_DIR""$LOG_FILE"

STATUS_SUCCESS=0
STATUS_FAILED=1
STATUS_PROGRESS=2

# $1: TSTART, $2: TEND, $3: STATUS
function updatedb() {
	echo "UPDATE status SET status = $3, tend = $2 WHERE tstart = $1;" | sqlite3 $BUILD_DB
}

# Check if snap-build is not present.
if [ ! -e "$SNAPBUILD_ROOT" ]
then
	mkdir $SNAPBUILD_ROOT	
fi

# Check if base log dir is not present.
if [ ! -e "$LOGBASE_DIR" ]
then
	mkdir $LOGBASE_DIR
fi

# If snapr directory is already present, remove it and clone again.
if [ -e "$SNAPR_DIR" ]
then
	rm -rf $SNAPR_DIR
fi

# Delete build log
echo "** CLONING SNAPR REPOSITORYY **" | tee -a $BUILD_LOG

# Clone the repository into the 
git clone $SNAPR_GIT $SNAPR_DIR | tee -a $BUILD_LOG

# Make

# Insert into the status table.
echo "INSERT INTO status VALUES(NULL, $TSTART, 0, $STATUS_PROGRESS, '$LOG_FILE');" | sqlite3 $BUILD_DB
echo "** MAKING. START TIME = `date` **" | tee -a $BUILD_LOG
cd $SNAPR_DIR
make 2>&1 | tee -a $BUILD_LOG
RESULT=$?
TEND=`date +%s`
echo "** MAKE FINISH. TIME = `date` **" | tee -a $BUILD_LOG

# Check exit status and take appropriate action $?
if [ "$RESULT" -ne 0 ]
then
	# Build failed. Update DB entry.
	echo "** MAKE FAILED **" | tee -a $BUILD_LOG
	updatedb $TSTART $TEND $STATUS_FAILED 
else
	# Build succeeded. Update DB entry.
	echo "** MAKE SUCCEEDED **" | tee -a $BUILD_LOG
	updatedb $TSTART $TEND $STATUS_SUCCESS 
fi
