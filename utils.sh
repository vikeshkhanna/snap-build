# Utility script. This script has several re-usable functions used by the build system.
# Recommended usage is to source this script in other build scripts. source ./utils.sh
#
# @author:
# Vikesh Khanna (vikesh@stanford.edu)

# Status constants will be available to all build scripts after sourcing. 
STATUS_QUEUED=-1
STATUS_SUCCESS=0
STATUS_FAILED=1
STATUS_PROGRESS=2

# Send mail to the given address.
# @arg $1 : Recipient Address
# @arg $2 : Subject.
# @arg $3 : Body.
# @arg $4 : Full path of the file to attach.
function send_mail() {
	echo "$3" | mail -s "$2" -a "$4" "$1"
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

# $1: Project name, $2: Full path to DB, $3: TSTART, $4: STATUS
function update_build_status() {
	do_sql "UPDATE status SET build_status = $4 WHERE name = '$1' and tstart = $3;" $2
}

# $1: Project name, $2: Full path to DB, $3: TSTART, $4: STATUS
function update_test_status() {
	do_sql "UPDATE status SET test_status = $4 WHERE name = '$1' and tstart = $3;" $2
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
