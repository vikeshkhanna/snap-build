#!/bin/bash
# Script to build (make and test) ringo. 
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

SNAPR_TBL_NAME=$PROJECT_NAME_CONST_SNAPR
SNAP_TBL_NAME=$PROJECT_NAME_CONST_SNAP
RINGO_TBL_NAME=$PROJECT_NAME_CONST_RINGO
set_vars $RINGO_TBL_NAME $TARGET_ROOT $LOG_ROOT
SNAP_DIR="$TARGET_DIR/$SNAP_TBL_NAME"
SNAPR_DIR="$TARGET_DIR/$SNAPR_TBL_NAME"
RINGO_DIR="$TARGET_DIR/$RINGO_TBL_NAME"

create_dir_if_not_exists $TARGET_DIR
create_dir_if_not_exists $LOG_DIR

# Insert into the snapr table. Build in progress, test queued. 
do_sql "BEGIN; INSERT INTO $RINGO_TBL_NAME VALUES(NULL, $TSTART, 0, $STATUS_PROGRESS, $STATUS_QUEUED, '$LOG_FILE_NAME'); COMMIT;" $DB_FILE

# Clone the repositories into their respective directories.
echo "======================= CLONING REPOSITORIES =======================" | tee -a $LOG_FILE
git clone $SNAPR_GIT $SNAPR_DIR | tee -a $LOG_FILE
git clone $RINGO_GIT $RINGO_DIR | tee -a $LOG_FILE
git clone $SNAP_GIT $SNAP_DIR | tee -a $LOG_FILE

process_common $RINGO_DIR $TSTART $DB_FILE $LOG_FILE $RINGO_TBL_NAME
