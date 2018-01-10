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
DEV_DIR='dev'
STABLE_DIR='stable'
VERSIONS_DIR='versions'

HIGHLIGHT_COLOR='\e[36m'
TITLE_COLOR='\e[4m\e[1m'
DONE_COLOR='\e[1;32m'
ERROR_COLOR='\e[41m'
NO_COLOR='\e[0m'


# Tool variables
ROOT_DIR="$(dirname $(readlink -f $0))"
VERSION="0.3.0"


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
error(){
  echo -e "${ERROR_COLOR}Failure: ${1}${NO_COLOR}\n"
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
  debug "Creating /.trt config directory..."
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

create_workspace(){
  debug "Creating /${1} workspace..."
  cd "$ROOT_DIR"
  mkdir "${1}"
  cd "$ROOT_DIR/${1}"
  create_repo
  say_done
}

create_versions_folder(){
  debug "Creating /versions directory..."
  cd "$ROOT_DIR"
  mkdir "${VERSIONS_DIR}"
  cd "$ROOT_DIR/${VERSIONS_DIR}"
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
  debug "Pushing from /${DEV_DIR} to parent"
  empty_check=$(find .git/objects -type f | wc -l)
  if [ "$empty_check" -eq "0" ]; then
    error ".git repository is empty"
    return
  fi
  git push origin master
  say_done
}

pull_from_origin(){
  debug "Pulling from parent to /${STABLE_DIR}"
  git pull origin master
  say_done
}

copy_to_new_archive(){
  datename=$(date +%Y%m%d)
  debug "Copying files from /${STABLE_DIR} to /${VERSIONS_DIR}/${datename}"
  stable_path="$ROOT_DIR/${STABLE_DIR}/"
  versions_path="$ROOT_DIR/${VERSIONS_DIR}/${datename}"
  rsync -rltvSzhc --delay-updates --progress --exclude=".*" "${stable_path}" "${versions_path}"
  say_done
}


# Upgrade functions
commit_dev_folder(){
  debug "Saving working state prior to upgrade..."
  cd "$ROOT_DIR/${DEV_DIR}"
  git commit -a -m "Commit prior to upgrade"
  say_done
}

download_dependencies_with_overwrite(){
  debug "Downloading dependencies into development environment... (no ignores)"
  DONE=false
  until $DONE ;do
    IFS='>' read repo dest <<< "$repo"
    if [ ${#dest} == 0 ]; then
	dest='.'
    fi
    repo="$(echo -e "${repo}" | tr -d '[:space:]')"
    dest="$(echo -e "${dest}" | tr -d '[:space:]')"
    echo ${#dest}
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHC}Repo:${NC} '${repo}' '${dest}'"
      rsync -rltvSzhc --delay-updates --progress --exclude=".*" "$repo/" "$dest"
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}

download_dependencies(){
  debug "Downloading dependencies into development environment..."
  DONE=false
  until $DONE ;do
    read repo || DONE=true
    IFS='>' read repo dest <<< "$repo"
    if [ ${#dest} == 0 ]; then
	dest='.'
    fi
    repo="$(echo -e "${repo}" | tr -d '[:space:]')"
    dest="$(echo -e "${dest}" | tr -d '[:space:]')"
    echo ${#dest}
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHC}Repo:${NC} '${repo}' '${dest}'"
      rsync -rltvSzhc --delay-updates --progress --exclude-from "$ROOT_DIR/.trt/ignores" --exclude=".*" "$repo/" "$dest"
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}



# Mode methods
init(){
  title "Initializing new workspace..."
  if [ -d ".trt" ]; then
    error "Already initialized. (.trt/ exists)"
    return
  fi
  create_config_folder
  create_standard_config_files
  create_parent_repo
  create_workspace "${DEV_DIR}"
  create_workspace "${STABLE_DIR}"
  create_versions_folder
  success "Workspace ready."
}

synchronize(){
  title "Synchronizing /${DEV_DIR} with /${STABLE_DIR}..."
  if [ ! -d "$ROOT_DIR/$DEV_DIR" ] || [ ! -d "$ROOT_DIR/$STABLE_DIR" ]; then
    error "Unable to find both /$DEV_DIR and /$STABLE_DIR directories"
    return
  fi
  cd "$ROOT_DIR/${DEV_DIR}"
  push_to_origin
  cd "$ROOT_DIR/${STABLE_DIR}"
  pull_from_origin
  success "Synchronized."
}

archive(){
  title "Creating archive of /${STABLE_DIR}..."
  if [ ! -d "$ROOT_DIR/$STABLE_DIR" ]; then
    error "Unable to find /$STABLE_DIR directory"
    return
  fi
  copy_to_new_archive
  success "Archive version created."
}

soft_upgrade(){
  title "Running a soft upgrade..."
  if [ ! -d "$ROOT_DIR/$DEV_DIR" ]; then
    error "Unable to find /$DEV_DIR directory"
    return
  fi
  commit_dev_folder
  download_dependencies
  success "Soft upgrade finished."
}

hard_upgrade(){
  title "Running a hard upgrade..."
  if [ ! -d "$ROOT_DIR/$DEV_DIR" ]; then
    error "Unable to find /$DEV_DIR directory"
    return
  fi
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
