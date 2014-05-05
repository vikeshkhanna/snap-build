# Utility script. This script has several re-usable functions used by the build system.
# Recommended usage is to source this script in other build scripts. source ./utils.sh

# ===== Configurable parameters ======= #
# Mail address(es) in case of error. Space separated.
MAIL_ADDRESS="vikesh@stanford.edu"

# PROJECT_NAME_CONST_* uniquely identifies each project. These variables are used in several ways -
# Project name MUST match the tables in build.db created using create.sql
# Project names are used as prefixes to create directories for target and logging.
# Build scripts for each project MUST match the build_<project_name>.sh naming convention.
# Common prefixes to be used by the build scripts for logs and target : 
# Logs - LOG_ROOT/<prefix>/<prefix>.<timestamp>.log
# Target - TARGET_ROOT/<prefix>.<timestamp>/<git repos>
PROJECT_NAME_CONST_SNAP="snap"
PROJECT_NAME_CONST_SNAPR="snapr"
PROJECT_NAME_CONST_SNAPPY="snappy"

# ===== ENDS Configurable parameters ======= #

# Status constants will be available to all build scripts after sourcing. 
STATUS_QUEUED=-1
STATUS_SUCCESS=0
STATUS_FAILED=1
STATUS_PROGRESS=2

# git endpoints of various repositories
SNAPR_GIT="https://github.com/snap-stanford/snapr.git"
SNAP_GIT="https://github.com/snap-stanford/snap.git"
SNAPPY_GIT="https://github.com/snap-stanford/snap-python.git"


# Send mail to the given address.
# @arg $1 : Recipient Address
# @arg $2 : Subject.
# @arg $3 : Body.
# @arg $4 : Full path of the file to attach.
function send_mail() {
	echo "$3" | mutt -a "$4" -s "$2" -- $1
	return $?
}

# Execute SQL statement. 
# Handles sqlite's database locking in case of multiple writers effectively by waiting.
# @args $1 : STATEMENT to execute. 
# @args $2 : DB_FILE
function do_sql() {
	local STATEMENT=$1
	local DB_FILE=$2
	local MAX_WAIT=5
	local WAIT=0

	while [ "$WAIT" -le "$MAX_WAIT" ]
	do
		echo $STATEMENT | sqlite3 $DB_FILE 2>/dev/null && break
		sleep 1
		((WAIT++))
	done;

	if [ "$WAIT" -le "$MAX_WAIT" ]
	then
		echo "EXECUTED SQL: $STATEMENT"
		return 0;
	else
		echo "FAILED SQL: $STATEMENT"
		return 1;
	fi;
}

# $1: Tablename, $2: Full path to DB, $3: TSTART, $4: STATUS
function update_build_status() {
	do_sql "UPDATE $1 SET build_status = $4 WHERE tstart = $3;" $2
}

# $1: Tablename, $2: Full path to DB, $3: TSTART, $4: STATUS
function update_test_status() {
	do_sql "UPDATE $1 SET test_status = $4 WHERE tstart = $3;" $2
}

# $1: Tablename, $2: Full path to DB, $3: TSTART
function update_tend() {
	local TEND=`date +%s`
	do_sql "UPDATE $1 SET tend = $TEND WHERE tstart = $3;" $2
}

# Checks if a directory does not exist and creates it.
# Note that it uses the -p switch to create any non-existent directories on the way.
# @args $1 : DIRECTORY : Directory path.
function create_dir_if_not_exists() {
	local DIRECTORY=$1
	if [ ! -e "$DIRECTORY" ]
	then
		mkdir -p $DIRECTORY
	fi
}

# Sets the required variables for project build scripts - TSTART, TARGET_DIR, LOG_FILE_NAME and LOG_FILE
# @arg $1 : PROJECT_TBL_NAME
# @arg $2 : TARGET_ROOT
# @arg $3 : LOG_ROOT
function set_vars() {
	local PROJECT_TBL_NAME=$1
	local TARGET_ROOT=$2
	local LOG_ROOT=$3

	TSTART=`date +%s`
	# Following the Target path naming convention mentioned in utils.sh - TARGET_ROOT/snap.<timestamp>/snap/.git
	TARGET_DIR="$TARGET_ROOT/$PROJECT_TBL_NAME.$TSTART"
	LOG_DIR="$LOG_ROOT/$PROJECT_TBL_NAME"
	LOG_FILE_NAME="$PROJECT_TBL_NAME.$TSTART.log"
	LOG_FILE="$LOG_DIR/$LOG_FILE_NAME"

	echo "LOGGING in $LOG_FILE"
}

# ************* COMMON BUILD ************** #
# Builds SNAPR/SNAP/SNAPPY. Does SOURCE_DIR/make and SOURCE_DIR/test/make
# @arg $1 - SOURCE_DIR - Directory of the source.
# @arg $2 - TSTART (Start time used to identify this build)
# @arg $3 - DB_FILE - Full File Path to the DB file
# @arg $4 - LOG_FILE - Full path to the log file.
# @arg $5 - TBL_NAME - Name of the table to be updated.
function build_common() {
	local SOURCE_DIR=$1
	local TSTART=$2
	local DB_FILE=$3
	local LOG_FILE=$4
	local TBL_NAME=$5

	# ========================= MAKE BEGINS ====================================== 
	update_build_status $TBL_NAME $DB_FILE $TSTART $STATUS_PROGRESS
	cd $SOURCE_DIR
	echo "======================= MAKING $TBL_NAME. START TIME = `date` =======================" | tee -a $LOG_FILE
	make >> $LOG_FILE 2>&1
	local RESULT=$?
	echo "======================= MAKE FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Build failed. Update DB entry.
		echo "======================= MAKE $TBL_NAME FAILED =======================" | tee -a $LOG_FILE
		update_build_status $TBL_NAME $DB_FILE $TSTART $STATUS_FAILED 
	else
		# Build succeeded. Update DB entry.
		echo "======================= MAKE $TBL_NAME SUCCEEDED =======================" | tee -a $LOG_FILE
		update_build_status $TBL_NAME $DB_FILE $TSTART $STATUS_SUCCESS
	fi
	return $RESULT;
}

# Tests SNAPR/SNAP/SNAPPY. Does SOURCE_DIR/make and SOURCE_DIR/test/make
# @arg $1 - SOURCE_DIR - Directory of the source.
# @arg $2 - TSTART (Start time used to identify this build)
# @arg $3 - DB_FILE - Full File Path to the DB file
# @arg $4 - LOG_FILE - Full path to the log file.
# @arg $5 - TBL_NAME - Name of the table to be updated.
function test_common() {
	local SOURCE_DIR=$1
	local TSTART=$2
	local DB_FILE=$3
	local LOG_FILE=$4
	local TBL_NAME=$5

	# ================================== TEST BEGINS =======================* 
	cd "$SOURCE_DIR/test"
	echo "======================= TEST $TBL_NAME BEGINS. START TIME = `date` =======================" | tee -a $LOG_FILE
	update_test_status $TBL_NAME $DB_FILE $TSTART $STATUS_PROGRESS

	make >> $LOG_FILE 2>&1
	local RESULT=$?

	# make run is not required for snappy.
	if [ ! "$TBL_NAME" == "$SNAPPY_TBL_NAME" ] 
	then 
		make run >> $LOG_FILE 2>&1
		local RESULT=$?
	fi

	echo "======================= TEST $TBL_NAME FINISH. TIME = `date` =======================" | tee -a $LOG_FILE

	# Check exit status and take appropriate action $?
	if [ $RESULT -ne 0 ]
	then
		# Test failed. Update DB entry.
		echo "======================= TEST $TBL_NAME FAILED =======================" | tee -a $LOG_FILE
		update_test_status $TBL_NAME $DB_FILE $TSTART $STATUS_FAILED
	else
		# Test succeeded. Update DB entry.
		echo "======================= TEST $TBL_NAME SUCCEEDED =======================" | tee -a $LOG_FILE
		update_test_status $TBL_NAME $DB_FILE $TSTART $STATUS_SUCCESS
	fi
	return $RESULT;
}

# Build, Test, Update tend and send mail on failure.
# @arg $1 - SOURCE_DIR - Directory of the source.
# @arg $2 - TSTART (Start time used to identify this build)
# @arg $3 - DB_FILE - Full File Path to the DB file
# @arg $4 - LOG_FILE - Full path to the log file.
# @arg $5 - TBL_NAME - Name of the table to be updated.
function process_common() {
	local SOURCE_DIR="$1"
	local TSTART="$2"
	local DB_FILE="$3"
	local LOG_FILE="$4"
	local TBL_NAME="$5"

	build_common $SOURCE_DIR $TSTART $DB_FILE $LOG_FILE $TBL_NAME
	local BUILD_RESULT=$?
	test_common $SOURCE_DIR $TSTART $DB_FILE $LOG_FILE $TBL_NAME
	local TEST_RESULT=$?
	update_tend $TBL_NAME $DB_FILE $TSTART

	if [ "$BUILD_RESULT" -ne 0 ] || [ "$TEST_RESULT" -ne 0 ] 
	then
		send_mail "$MAIL_ADDRESS" "Project $TBL_NAME build is unhealthy" "Please see the log file at $LOG_FILE (also attached) and take corrective action." $LOG_FILE
	else
		return 0
	fi
}
# ************* ENDS COMMON BUILD ************** #
