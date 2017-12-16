# turret
A tiny tool for initializing and combining workspaces.

This is a bash script used to set up workspaces with familiar structure, and to combine workspaces together.

It uses git to track the versions of the project, and it uses rsync to combine the dependencies into the current project.

Unlike other deployment tools, this doesn't allow developers to push changes onto client sites, but instead allows them to pull down changes when they desire.

## Usage
```
Create a new workshop
   -i     Initialize      Create a workshop in the current directory

Synchronize environments
   -s     Synchronize     Clone the current committed dev environment into the stable one

Upgrade source code from dependencies
   -u     Upgrade         Upgrade dependencies in the dev environment while skipping ignored files
   -f     Full upgrade    Upgrade all dependencies in the dev environment

Other commands
   -h     Help            Show this usage information
```

## Setting up a new workspace
A project starts from some empty folder. From there the `trt.sh` script is added.

We can then run `./trt.sh -i`. This creates the following files and directories:
```
.project.git
/dev
    .git
/stable
    .git
/.trt
    repos
    ignores
```
![Example project with new directories](http://moonbench.xyz/images/projects/turret/new_project/3.png)

The `.project.git` repository is a shared repository that acts as the parent for the `/dev/.git` and `/stable/.git` repositories.
The `/dev` and `/stable` folders house the development and production code, respectively.
The `/.trt` folder holds configuration files.

## Synchronizing /stable with /dev
After building and testing in the `/dev` folder, we can commit the code to the this folder's repository. Then we run `./trt.sh -s` to execute the synchronization. The `/dev` folder is first pushed to the shared project repository.

![Pushing the dev repo to the parent](http://moonbench.xyz/images/projects/turret/adding_files/2.png)

Then the `/stable` folder pulls the changes down.

![Pulling the parent into the stable repo](http://moonbench.xyz/images/projects/turret/adding_files/3.png)

This puts the changes live into production.

## Combining projects together
This makes it possible to build complex projects that combine simple, well-tested building blocks.

We can edit the `.trt/repos` file with the locations of code we want to copy into the current workspace. These are the dependency sources.

An example repository file may look like:
```
/home/username/workshop/baz_project/stable
/home/username/workshop/qux_project/stable
/home/username/workshop/foobar_project/dev

```
Please note the new line at the end.

Once dependencies are added, we can upgrade the `/dev` folder by downloading the dependencies.

Calling `./trt.sh -u` triggers a soft upgrade. This causes the Turret to commit the current state of the /dev folder, then copy the dependencies into the `/dev` folder. It will skip any files listed in the `.trt/ignores` file.

Calling `./trt.sh -f` triggers a full upgrade. This causes the turret to commit the current state of the `/dev` folder, then copy the dependencies into the `/dev` folder. It will overwrite all local files with files from the dependencies. This is intended for major version changes, and local files may need to be repaired after.

![Pulling changes from dependencies into the /dev folder](http://moonbench.xyz/images/projects/turret/combine/2.png)

## Deploying to client sites
Again, we can call `./trt.sh -u` to upgrade the `/dev` folder by downloading updates of dependencies. Once tested it can be published to their `/stable` public site with `./trt.sh -s`.

![Pulling in changes from dependencies to client site](http://moonbench.xyz/images/projects/turret/client.png)

## Additional information
You can find additional details on http://moonbench.xyz/projects/turret
