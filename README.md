SNAP-BUILD
==========

snap-build is the integrated build system for Stanford [SNAP](http://snap.stanford.edu) projects. Currently supported projects are - snap, snapr, snap-python and ringo.

### Prerequisistes
The build system has the same pre-requisites as the various SNAP projects it supports. Please read the prerequisites of each SNAP project supported to ensure make and test work. Google Test setup is usually the one that requires some time. `snap-build` also requires an **SMTP configured server** (to send mails on build failure) and **sqlite3** installed.

### Configuration
`MAIL_ADDRESS` : Set as the recipient of the build failure mails.

### Usage
`./build.sh <ROOT>`
Build script creates three directories in the ROOT folder - **snap-build-target** (TARGET_ROOT), **snap-build-logs** (LOG_ROOT) and **snap-build-db** (DB_ROOT). Each build creates a new folder `<project_name>.<timestamp>` and stores under TARGET_ROOT. Logs are similarly stored under `LOG_ROOT/<project_name>/<project_name>.<timestamp>.log`. DB_ROOT has build.db, which stores the build status of each project.

### Extend
To incorporate more projects into the framework, do the following steps - 

1. Decide on a project name. This project name will be used as the table name in the DB and as a prefix for creating directories and files. Edit `utils.sh` and add an entry for your project as `PROJECT_NAME_CONST_<project_name>=<project_name>`
2. Edit create.sql and drop.sql with a table named `<project_name>`. The table may have the same schema as the others or a different schema. If it has a different schema, the subsequent build files will require significant coding.
3. Create `build_<project_name>.sh` in the root folder of the repository. Note that the file name MUST match `build_<project_name>.sh` naming convention.
4. Follow the conventions in build_snap.sh to set required variables and call the common utility functions in `utils.sh`. If the build process for the project differs significantly from the `*_common` methods in `utils.sh`, implement the new build methods in `utils.sh` with maximum code reusability. The master build script (`build.sh`) will automatically call your project since you followed the `PROJECT_NAME_CONST_*` naming convention.
5. [Optional] Appropriately edit the front end (`index.php`) to show the status of the new project, or use the DB in any other way.


### Sample commands
`./build.sh /lfs/local/0`
`./build_snap.sh /lfs/local/0/snap-build-target /lfs/local/0/snap-build-logs /lfs/local/0/snap-build-db/build.db`

