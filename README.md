# turret
This is a workspace management tool with the ability to create, version, and combine projects.


## Feature overview
This tool sets up directories in your project with a standardized format of:
- `dev/` a workspace to house active development.
- `stable/` a space to hold the latest complete version.
- `versions/` a directory of historical versions.

It provides tools to synchronize files between those directories:
- `-s` Synchronizes the active versions by pulling `dev/` into `stable/`.
- `-a` Archives the current `stable/` version into a date-stamped directory under `versions/`.

It also provides tools to compose projects together:
- `-u` Upgrades the project by downloading dependencies into the `dev/` directory (without overwriting sensitive files).
- `-f` Full upgrade which acts like `-u` but overwrites _all_ files with the versions from the dependency source.


## Getting started
### Installation
Copy the `trt.sh` script into your empty project directory.

### Making a new workspace
Run `./trt.sh -i` to initialize the workspace.

This will create the empty directories, initialize git repositories, and create default configuration files.

After the project workspace has been initialized you can enter the `dev/` folder and begin development. An empty git repository is provided here which you can commit changes to as you work.

### Synchronize `dev/` into `stable/`
When the code is in a working state, use `./trt.sh -s` to synchronize the folders.

This will push the `dev/` repository to the project's shared repository, then pull it down into `stable/`.

After this, the `stable/` code can be shared or linked against, while development continues in the `dev/` workspace.

### Archive the current version
If you wish to save the current working version for future reference, run `trt.sh -a` to create an archive.

This will create a new directory under `versions/` for the current date (ex: `versions/20180108/`) and then copy the contents of `stable/` into the new versioned directory.

This can be useful if you want to have a specific version to be used as a component of another project, or to be referenced externally (such as in a blog post or article).

### Combining projects
First, add paths for the dependencies to the `.trt/repos` file. This file is automatically created during initialization.

Then, run `./trt.sh -u` to upgrade the project. This will download files from the dependencies into the `dev/` directory.

An example `repos` file might look like:
```
/home/username/workshop/php_framework/stable
/home/username/workshop/upload_tool/versions/20171215
/home/username/workshop/shopping_card/stable
```

If you want to prevent a file from being overwritten during future upgrades, add the relative path to the file to the `.trt/ignores` file.

An example `ignores` file might look like:
```
index.html
config/database.ini
```

Optionally, you can run `./trt.sh -f` to execute a "Full Upgrade" which will overwrite all files with the versions from the dependencies. Effectively ignoring the `ignores` list. This is intended to be used during major version upgrades in dependencies which require manual intervention to repair. The git history can be used to restore specific files.


## Motivation
This tool was built to help manage workspaces while developing software projects.

There were two goals:

1) Provide the ability to establish versions of a project to share with clients and contributors.
By establishing versions, it is possible to have a `dev/` workspace where projects can be continuously developed without affecting the `stable/` or named versions linked elsewhere. This makes it possible to use, or get feedback on, a known version of the project without requiring the developer to pause their work.

2) Provide the ability to compose projects into larger projects.
By combining projects, it is possible to build smaller isolated projects and then reuse them in other projects. As the individual components change over time the composition can be upgraded to pull in the latest versions. This can be used, for example, to combine existing components such as a web framework, modules, and custom code into a complete website.


## Additional information
You can find additional details on http://moonbench.xyz/projects/turret
