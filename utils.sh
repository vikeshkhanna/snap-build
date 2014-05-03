# Utility script. This script has several re-usable functions used by the build system.
# Recommended usage is to source this script in other build scripts. source ./utils.sh

# Status constants will be available to all build scripts after sourcing. 
STATUS_QUEUED=-1
STATUS_SUCCESS=0
STATUS_FAILED=1
STATUS_PROGRESS=2

# Common prefixes to be used by the build scripts for logs and target : 
# Logs - LOG_ROOT/<prefix>/<prefix>.<timestamp>.log
# Target - TARGET_ROOT/<prefix>.<timestamp>/<git repos>
SNAP_PREFIX="snap"
SNAPR_PREFIX="snapr"
SNAPPY_PREFIX="snappy"

# Tablenames as used in create.sql
SNAP_TBL_NAME="snap"
SNAPR_TBL_NAME="snapr"
SNAPPY_TBL_NAME="snapppy"

# git endpoints of various repositories
SNAPR_GIT="https://github.com/snap-stanford/snapr.git"
SNAP_GIT="https://github.com/snap-stanford/snap.git"
SNAPPY_GIT="https://github.com/snap-stanford/snap-python.git"

# $1: Tablename, $2: Full path to DB, $3: TSTART, $4: STATUS
function update_build_status() {
	echo "UPDATE $1 SET build_status = $4 WHERE tstart = $3;" | sqlite3 $2
}

# $1: Tablename, $2: Full path to DB, $3: TSTART, $3: STATUS
function update_test_status() {
	echo "UPDATE $1 SET test_status = $4 WHERE tstart = $3;" | sqlite3 $2
}

# Checks if a directory does not exist and creates it.
# Note that it uses the -p switch to create any non-existent directories on the way.
# @params $1 - Directory path.
function create_dir_if_not_exists() {
	local DIRECTORY=$1
	if [ ! -e "$DIRECTORY" ]
	then
		mkdir -p $DIRECTORY
	fi
}

# Builds SNAPR.
# @arg $1 - SNAPR_DIR - Directory of the snapr source.
# @arg $1 - TSTART (Start time used to identify this build)
# @arg $2 - DB_FILE - Full File Path to the DB file
# @arg $3 - LOG_FILE - Full path to the log file.
function build_snapr() {
	local SNAPR_DIR=$1
	local TSTART=$2
	local DB_FILE=$3
	local LOG_FILE=$4

	# ========================= MAKE BEGINS ====================================== 
	update_build_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_PROGRESS
	cd $SNAPR_DIR
	echo "======================= MAKING. START TIME = `date` =======================" | tee -a $LOG_FILE
	make >> $LOG_FILE 2>&1
	local RESULT=$?
	echo "======================= MAKE FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Build failed. Update DB entry.
		echo "======================= MAKE FAILED =======================" | tee -a $LOG_FILE
		update_build_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_FAILED 
	else
		# Build succeeded. Update DB entry.
		echo "======================= MAKE SUCCEEDED =======================" | tee -a $LOG_FILE
		update_build_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_SUCCESS
	fi
}

# Tests SNAPR.
# @arg $1 - SNAPR_DIR - Directory of the snapr source.
# @arg $1 - TSTART (Start time used to identify this build)
# @arg $2 - DB_FILE - Full File Path to the DB file
# @arg $3 - LOG_FILE - Full path to the log file.
function test_snapr() {
	local SNAPR_DIR=$1
	local TSTART=$2
	local DB_FILE=$3
	local LOG_FILE=$4

	# ================================== GTEST BEGINS =======================* 
	cd "$SNAPR_DIR/test"
	echo "======================= GTEST BEGINS. START TIME = `date` =======================" | tee -a $LOG_FILE
	update_test_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_PROGRESS

	make >> $LOG_FILE 2>&1
	make run >> $DB_FILE 2>&1
	local RESULT=$?
	echo "======================= GTEST FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Test failed. Update DB entry.
		echo "======================= GTEST FAILED =======================" | tee -a $LOG_FILE
		update_test_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_FAILED
	else
		# Test succeeded. Update DB entry.
		echo "======================= GTEST SUCCEEDED =======================" | tee -a $LOG_FILE
		update_test_status $SNAPR_TBL_NAME $DB_FILE $TSTART $STATUS_SUCCESS
	fi
}
