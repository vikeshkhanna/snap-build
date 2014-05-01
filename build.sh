#!/bin/bash

# If Home env is not set, use AFS path (for cron job)
HOME="/afs/.ir/users/v/i/vikesh"

PWD=$HOME/cgi-bin/snap-build
SNAPBUILD_ROOT=$HOME'/snap-build'
SNAPR_DIR=$SNAPBUILD_ROOT'/snapr'
SNAPR_GIT='https://github.com/snap-stanford/snapr.git'
BUILD_DB=$PWD"/build.db"

# Start time
TSTART=`date +%s`
LOGBASE_DIR=$PWD"/logs/"
LOG_FILE="build.$TSTART.log"
BUILD_LOG="$LOGBASE_DIR""$LOG_FILE"

STATUS_QUEUED=-1
STATUS_SUCCESS=0
STATUS_FAILED=1
STATUS_PROGRESS=2

# $1: TSTART, $2: STATUS
function update_build_status() {
	echo "UPDATE status SET build_status = $2 WHERE tstart = $1;" | sqlite3 $BUILD_DB
}

# $1: TSTART, $2: STATUS
function update_test_status() {
	echo "UPDATE status SET test_status = $2 WHERE tstart = $1;" | sqlite3 $BUILD_DB
}

function build() {
	update_build_status $TSTART $STATUS_PROGRESS
	# ========================= MAKE BEGINS ====================================== 
	cd $SNAPR_DIR
	echo "======================= MAKING. START TIME = `date` =======================" | tee -a $BUILD_LOG
	make >> $BUILD_LOG 2>&1
	RESULT=$?
	echo "======================= MAKE FINISH. TIME = `date` =======================" | tee -a $BUILD_LOG

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Build failed. Update DB entry.
		echo "======================= MAKE FAILED =======================" | tee -a $BUILD_LOG
		update_build_status $TSTART $TEND $STATUS_FAILED 
	else
		# Build succeeded. Update DB entry.
		echo "======================= MAKE SUCCEEDED =======================" | tee -a $BUILD_LOG
		update_build_status $TSTART $TEND $STATUS_SUCCESS 
	fi
}

function gtest() {
	update_test_status $TSTART $STATUS_PROGRESS
	# ================================== GTEST BEGINS =======================* 
	cd $SNAPR_DIR/test
	make >> $BUILD_LOG 2>&1
	make run >> $BUILD_LOG 2>&1
	RESULT=$?
	echo "======================= GTEST FINISH. TIME = `date` =======================" | tee -a $BUILD_LOG

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Build failed. Update DB entry.
		echo "======================= GTEST FAILED =======================" | tee -a $BUILD_LOG
		update_test_status $TSTART $STATUS_FAILED 
	else
		# Build succeeded. Update DB entry.
		echo "======================= GTEST SUCCEEDED =======================" | tee -a $BUILD_LOG
		update_test_status $TSTART $TEND $STATUS_SUCCESS 
	fi
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

# Insert into the status table. Build in progress, test queued. 
echo "INSERT INTO status VALUES(NULL, $TSTART, 0, $STATUS_PROGRESS, $STATUS_QUEUED, '$LOG_FILE');" | sqlite3 $BUILD_DB

# Clone the repository into the 
echo "======================= CLONING SNAPR REPOSITORYY =======================" | tee -a $BUILD_LOG
git clone $SNAPR_GIT $SNAPR_DIR | tee -a $BUILD_LOG

# Make
build
# GTest
gtest

# Update tend
TEND=`date +%s`
echo "UPDATE status SET tend=$TEND WHERE tstart = $TSTART;" | sqlite3 $BUILD_DB
