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
	DIRECTORY=$1
	if [ ! -e "$DIRECTORY" ]
	then
		mkdir -p $DIRECTORY
	fi
}
