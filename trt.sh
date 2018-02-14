#!/bin/bash

# Turret - Workspace management tool designed to create, version, and combine projects
# https://github.com/moonbench/turret
# MIT License

# Defaults
PROJECT_NAME='.project'
DEV_DIR='dev'
STABLE_DIR='stable'
VERSIONS_DIR='versions'

# Colors
HIGHLIGHT_COLOR='\e[36m'
TITLE_COLOR='\e[4m\e[1m'
DONE_COLOR='\e[1;32m'
ERROR_COLOR='\e[41m'
NO_COLOR='\e[0m'

# Constants
declare ROOT_DIR="$(dirname $(readlink -f $0))"
declare VERSION="0.4.1"
declare USAGE="usage: $(basename "$0") [-h][-v]
              [-P <name>][-D <path>][-S <path>][-A <path>]
              [-i][-s][-a][-u][-f]

Creates and manipulates project workspaces

Help:
  -h                Show help and usage information
  -v                Display the current version

Initialize:
  -i                Initialize. Create a new workspace in the current directory

Versioning:
  -s                Synchronize. Pull changes into ./stable/ from ./dev/
  -a                Archive. Create a copy in ./versions/{date}/ from ./stable/

Upgrading:
  -u                Upgrade. Copy modified files from the sources in ./.trt/repos
  -f                Full upgrade. Same as -u but without respecting ./.trt/ignores

Optional:
  -P                Project repo. Default: \"${PROJECT_NAME}\"
  -D                Dev directory. Default: \"${DEV_DIR}\"
  -S                Stable directory. Default: \"${STABLE_DIR}\"
  -A                Archive directory. Default: \"${VERSIONS_DIR}\""

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
  debug "Creating /${VERSIONS_DIR} directory..."
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

download_dependencies(){
  debug "Downloading dependencies into development environment..."
  DONE=false
  until $DONE ;do
    read repo || DONE=true
    IFS='>' read repo dest <<< "$repo"
    ignores=()
    if [ ! $1 ]; then
      debug "Loading in ignores file"
      IGNORE_DONE=false
      until $IGNORE_DONE ;do
        read ignore || IGNORE_DONE=true
	if [ ! -z "${ignore}" ] && [[ "${ignore}" == $dest* ]]; then
	  ignores+="--exclude ${ignore#$dest/} "
	fi
      done < "$ROOT_DIR/.trt/ignores"
    fi
    ignores="${ignores[@]}"
    if [ ${#dest} == 0 ]; then
      dest='.'
    fi
    repo="$(echo -e "${repo}" | tr -d '[:space:]')"
    dest="$(echo -e "${dest}" | tr -d '[:space:]')"
    download_repo_into "$repo" "$dest" "$ignores"
  done < "$ROOT_DIR/.trt/repos"
  say_done
}

download_repo_into(){
  repo="${1}"
  dest="${2}"
  if [ -n "$repo" ]; then
    echo -e "\t${HIGHLIGHT_COLOR}Repo:${NO_COLOR} ${repo}"
    echo -e "\t${HIGHLIGHT_COLOR}Into:${NO_COLOR} ${dest}"
    if [ -z "$3" ]; then
      rsync -rltvSzhc --delay-updates --progress --exclude=".*" "$repo/" "$dest"
    else
      ignores="${3}"
      echo -e "\t${HIGHLIGHT_COLOR}Excluding:${NO_COLOR} ${ignores}"
      rsync -rltvSzhc --delay-updates --progress --exclude=".*" $ignores "$repo/" "$dest"
    fi
  fi
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
  download_dependencies true
  success "Hard upgrade finished."
}

# Check for missing arguments
if [[ $# -eq 0 ]] ; then
  echo "${USAGE}">&2
  exit 1
fi

# Parse arguments
while getopts ':hvisafuP:D:S:A:' flag; do
  case "${flag}" in
    h) echo "${USAGE}">&2
      exit
      ;;
    v) echo "Turret version ${VERSION}"
      exit
      ;;
    i) init ;;
    s) synchronize ;;
    a) archive ;;
    u) soft_upgrade ;;
    f) hard_upgrade ;;
    P) PROJECT_NAME="$OPTARG" ;;
    D) DEV_DIR="$OPTARG" ;;
    S) STABLE_DIR="$OPTARG" ;;
    A) VERSIONS_DIR="$OPTARG" ;;
    *) echo "Unknown option: -${OPTARG}">&2
       echo "${USAGE}">&2
       exit 1;;
  esac
done
