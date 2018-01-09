#!/bin/bash

# Turret
#
# Workspace management tool designed to create, version, and combine projects
#
# Licensed under the MIT License.
#
# More information: https://github.com/moonbench/turret


# Workspace options
PROJECT_NAME='.project'

HIGHLIGHT_COLOR='\e[36m'
TITLE_COLOR='\e[4m\e[1m'
DONE_COLOR='\e[1;32m'
NO_COLOR='\e[0m'


# Tool variables
ROOT_DIR="$(dirname $(readlink -f $0))"
VERSION="0.2.2"


# Shared functions
debug(){
  echo -e "${HIGHLIGHT_COLOR}${1}${NO_COLOR}"
}
title(){
  echo -e "${TITLE_COLOR}${1}${NO_COLOR}\n"
}
success(){
  echo -e "${DONE_COLOR}${TITLE_COLOR}${1}${NO_COLOR}"
}
say_done(){
  echo -e "${DONE_COLOR}Done.${NO_COLOR}\n"
}
usage(){
  echo "usage: $(basename "$0") [-i][-s][-a][-u][-f][-h][-v]

These are the turret commands:

Create a new workshop
   -i     Initialize      Create a workshop in the current directory

Versioning workshops
   -s     Synchronize     Copy the /dev directory into the /stable one
   -a     Archive         Copy the /stable directory into a new directory in the /versions direcotry

Upgrade source code from dependencies
   -u     Upgrade         Upgrade dependencies in the dev environment while skipping ignored files 
   -f     Full upgrade    Upgrade all dependencies in the dev environment

Other commands
   -h     Help            Show this usage information
   -v     Version         Print the current version of this tool


Sources to download from can be added to: '.trt/repos'.
Files to not be overwritten during normal updgrades can be specified in: '.trt/ignores'." >&2
}


# Initialization functions
create_config_folder(){
  debug "Creating config folder..."
  mkdir .trt
  say_done
}

create_parent_repo(){
  debug "Creating project repository..."
  cd "$ROOT_DIR"
  git init --bare ${PROJECT_NAME}.git
  say_done
}

create_repo(){
  git init
  git remote add origin ../${PROJECT_NAME}.git
}

create_stable_folder(){
  debug "Creating stable folder..."
  cd "$ROOT_DIR"
  mkdir stable
  cd "$ROOT_DIR/stable"
  create_repo
  say_done
}

create_dev_folder(){
  debug "Creating dev folder..."
  cd "$ROOT_DIR"
  mkdir dev
  cd "$ROOT_DIR/dev"
  create_repo
  say_done
}

create_versions_folder(){
  debug "Creating versions folder..."
  cd "$ROOT_DIR"
  mkdir versions
  cd "$ROOT_DIR/versions"
  say_done
}

create_standard_config_files(){
  debug "Creating config files..."
  cd "$ROOT_DIR/.trt/"
  touch repos
  touch ignores
  say_done
}


# Synchronization functions
push_to_origin(){
  debug "Pushing from /dev to parent"
  git push origin master
  say_done
}

pull_from_origin(){
  debug "Pulling from parent to /stable"
  git pull origin master
  say_done
}

copy_to_new_archive(){
  datename=$(date +%Y%m%d)
  debug "Copying files from /stable to /versions/${datename}"
  rsync -rltvSzhc --delay-updates --progress --exclude=".*" "$ROOT_DIR/stable/" "$ROOT_DIR/versions/${datename}"
  say_done
}


# Upgrade functions
commit_dev_folder(){
  debug "Saving working state prior to upgrade..."
  cd "$ROOT_DIR/dev"
  git commit -a -m "Commit prior to upgrade"
  say_done
}

download_dependencies_with_overwrite(){
  debug "Downloading dependencies into development environment... (no ignores)"
  DONE=false
  until $DONE ;do
    read repo || DONE=true
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHLIGHT_COLOR}Repo:${NO_COLOR} ${repo}"
      rsync -rltvSzhc --delay-updates --progress --exclude=".*" "$repo/" .
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}

download_dependencies(){
  debug "Downloading dependencies into development environment..."
  DONE=false
  until $DONE ;do
    read repo || DONE=true
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHC}Repo:${NC} ${repo}"
      rsync -rltvSzhc --delay-updates --progress --exclude-from "$ROOT_DIR/.trt/ignores" --exclude=".*" "$repo/" .
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}



# Mode methods
init(){
  title "Initializing new workspace..."
  create_config_folder
  create_parent_repo
  create_dev_folder
  create_stable_folder
  create_versions_folder
  create_standard_config_files
  success "Workspace ready."
}

synchronize(){
  title "Synchronizing /dev with /stable..."
  cd "$ROOT_DIR/dev"
  push_to_origin
  cd "$ROOT_DIR/stable"
  pull_from_origin
  success "Synchronized."
}

archive(){
  title "Creating archive of /stable..."
  copy_to_new_archive
  success "Archive version created."
}

soft_upgrade(){
  title "Running a soft upgrade..."
  commit_dev_folder
  download_dependencies
  success "Soft upgrade finished."
}

hard_upgrade(){
  title "Running a hard upgrade..."
  commit_dev_folder
  download_dependencies_with_overwrite
  success "Hard upgrade finished."
}

print_version(){
  echo "Turret version ${VERSION}"
}



# Run script
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

while getopts ':isafuhv' flag; do
  case "${flag}" in
    i) init ;;
    s) synchronize ;;
    a) archive ;;
    u) soft_upgrade ;;
    f) hard_upgrade ;;
    h) usage ;;
    v) print_version ;;
    *) printf "Unknown option: -%s\n" "$OPTARG" >&2
       usage 
       exit 1;;
  esac
done

exit 0
