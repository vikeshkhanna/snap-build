#!/bin/bash
# Script to build (make and test) snap. 
# Assumes all root directories are created.
# @arg $1 : TARGET_ROOT : Root directory for targets.
# @arg $2 : LOG_ROOT : Root directory for logs
# @arg $3 : DB_FILE : Full path to the build db

if [ "$#" -ne 3 ]
then 
	echo "Illegal number of parameters. TARGET_ROOT, LOG_ROOT and DB_FILE are mandatory parameters."
	exit 1
fi

TARGET_ROOT=${1%/}
LOG_ROOT=${2%/}
DB_FILE=${3%/}

PWD=`dirname "$0"`
# Include the utils directory
source "$PWD/utils.sh"

SNAP_TBL_NAME=$PROJECT_NAME_CONST_SNAP
set_vars $SNAP_TBL_NAME $TARGET_ROOT $LOG_ROOT
SNAP_DIR="$TARGET_DIR/$SNAP_TBL_NAME"

create_dir_if_not_exists $TARGET_DIR
create_dir_if_not_exists $LOG_DIR

# Insert into the snap table. Build in progress, test queued. 
do_sql "BEGIN; INSERT INTO $SNAP_TBL_NAME VALUES(NULL, $TSTART, 0, $STATUS_PROGRESS, $STATUS_QUEUED, '$LOG_FILE_NAME'); COMMIT;" $DB_FILE

# Clone the repository into the 
echo "======================= CLONING SNAP REPOSITORY =======================" | tee -a $LOG_FILE
git clone $SNAP_GIT $SNAP_DIR | tee -a $LOG_FILE

process_common $SNAP_DIR $TSTART $DB_FILE $LOG_FILE $SNAP_TBL_NAME
