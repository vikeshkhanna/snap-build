#!/bin/bash
# SNAP build script.
# @arg ROOT : Root director to place target, logs and db

if [ "$#" -ne 1 ]
then 
	echo "Illegal number of parameters. ROOT directory is a mandatory parameter."
	exit 1
fi

# Root directory. Remove trailing slash, if present.
ROOT=${1%/}
PWD=`dirname "$0"`

# Check if ROOT directory exists.
if [ ! -d "$ROOT" ]
then
	echo "ROOT directory must be a valid, existing direcotry"
	exit 1
fi

# All projects will be built in TARGET_ROOT/<project_prefix>.<timestamp>/
# See utils for project_prefix
TARGET_ROOT="$ROOT/snap-build-target"
# All project logs will be stoered in LOG_ROOT/<project_prefix>/<project_prefix>.<timestamp>.log
# See utils for pr
LOG_ROOT="$ROOT/snap-build-logs"
# Database file is in this folder.
DB_ROOT="$ROOT/snap-build-db"

# All tables in this DB.
BUILD_DB="$DB_ROOT/build.db"

# git endpoints of various repositories
SNAPR_GIT="https://github.com/snap-stanford/snapr.git"
SNAP_GIT="https://github.com/snap-stanford/snap.git"
SNAPPY_GIT="https://github.com/snap-stanford/snap-python.git"

# Start time
TSTART=`date +%s`
LOG_FILE="build.$TSTART.log"
BUILD_LOG="$LOGBASE_DIR""$LOG_FILE"

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

# Check if various root directories are not present.
create_dir_if_not_exists $TARGET_ROOT
create_dir_if_not_exists $LOG_ROOT
create_dir_if_not_exists $DB_ROOT

# Check if BUILD_DB is not present. Create it using create.sql from the source..
if [ ! -f $BUILD_DB ]
then
	sqlite3 $BUILD_DB < $PWD/db/create.sql
fi
exit 0

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
# build
# GTest
# gtest

# Update tend
TEND=`date +%s`
echo "UPDATE status SET tend=$TEND WHERE tstart = $TSTART;" | sqlite3 $BUILD_DB
