SNAP-BUILD
==========

snap-build is the integrated build system for Stanford [SNAP](http://snap.stanford.edu) projects. Currently supported projects are - snap, snapr, snap-python and ringo. But it can easily be used as build system for any SNAP (or even external) project. 

### Prerequisites
The build system has the same pre-requisites as the various SNAP projects it supports. Please read the prerequisites of each SNAP project supported to ensure make and test work. Google Test setup is usually the one that requires some time. `snap-build` also requires an **SMTP configured server** (to send notification mails), **sqlite3** and **pyYaml** installed.

### Configuration
Please see conf.yaml for a sample configuration file and more details.

### Usage
`./build.sh <ROOT>`
Build script creates three directories in the ROOT folder - **snap-build-target** (TARGET_ROOT), **snap-build-logs** (LOG_ROOT) and **snap-build-db** (DB_ROOT). Each build creates a new folder `<project_name>.<timestamp>` and stores under TARGET_ROOT. Logs are similarly stored under `LOG_ROOT/<project_name>/<project_name>.<timestamp>.log`. DB_ROOT has build.db, which stores the build status of each project.

### Extend
To incorporate more projects into the framework, do the following steps - 

1. Decide on a project name. This project name will be inserted into the 'name' column of the **status** table each time a build is triggered.
2. Add an entry for your project in the dictionary that maintains project name and label mapping (config.php).

### Sample commands
`./build.sh /lfs/local/0`
`./build.child.sh /lfs/local/0/snap-build-target /lfs/local/0/snap-build-logs /lfs/local/0/snap-build-db/build.db`

